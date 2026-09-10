--!nonstrict
-- Read-only probes for a running Studio session. Never starts a run, acts as a player,
-- writes a DataStore, uploads an asset, or claims that physics/input have been tested.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local Checks={}
local function finite(n)return n==n and math.abs(n)<math.huge end
local function shown(object,root)
	local current=object
	while current and current~=root do
		if current:IsA("GuiObject") and not current.Visible then return false end
		current=current.Parent
	end
	return root.Enabled
end
local function scrolling(object,root)
	local current=object.Parent
	while current and current~=root do
		if current:IsA("ScrollingFrame") then return true end
		current=current.Parent
	end
	return false
end
function Checks.run(quiet)
	assert(RunService:IsStudio(),"StudioChecks is only available in Roblox Studio.")
	local report={context=if RunService:IsServer() then "server" else "client",findings={},stats={parts=0,seats=0,lights=0,textMeasured=0}}
	local function note(level,code,object,message)
		table.insert(report.findings,{level=level,code=code,path=if object then object:GetFullName() else "",message=message})
	end
	local world=workspace:FindFirstChild("VaultWorld")
	if not world then
		note("ERROR","NO_SCENE",nil,"Start Play / Server & Clients first. The set is generated at runtime.")
	else
		for _,object in world:GetDescendants() do
			if object:IsA("BasePart") then
				report.stats.parts+=1
				local p,s=object.Position,object.Size
				if not (finite(p.X) and finite(p.Y) and finite(p.Z) and finite(s.X) and finite(s.Y) and finite(s.Z) and s.X>0 and s.Y>0 and s.Z>0) then
					note("ERROR","INVALID_GEOMETRY",object,"Non-finite position or non-positive size.")
				end
			elseif object:IsA("Light") then report.stats.lights+=1 end
			if object:IsA("Seat") then report.stats.seats+=1 end
		end
		for _,id in {"MAIN","QUICK"} do
			local arena=world:FindFirstChild(id)
			if not arena then note("ERROR","MISSING_ARENA",world,id.." is missing; check replication / Streaming settings.")
			else
				local floor=arena:FindFirstChild("StudioFloor")
				if not floor or not floor.CanCollide or not floor.Anchored then note("ERROR","FLOOR",arena,"StudioFloor must be anchored and collidable.") end
				for i=1,12 do
					local vault=arena:FindFirstChild(string.format("Vault_%02d",i))
					if not vault or not vault:FindFirstChild("DoorAssembly") or not vault:FindFirstChild("Interaction") then
						note("ERROR","VAULT_ASSEMBLY",arena,"Missing vault, door or interaction anchor: "..i)
					end
				end
			end
		end
		if report.stats.parts>3000 then note("WARN","PART_BUDGET",world,"More than 3,000 set parts. Profile on target devices.") end
	end
	if not RunService:IsServer() then
		report.audio={};report.stats.audioReady=0
		for _,container in {game:GetService("SoundService"),workspace}do
			for _,sound in container:GetDescendants()do
				if sound:IsA("Sound")and sound:GetAttribute("VaultAudioCue")then
					table.insert(report.audio,{cue=sound:GetAttribute("VaultAudioCue"),id=sound.SoundId,loaded=sound.IsLoaded,seconds=sound.TimeLength})
					if sound.IsLoaded then report.stats.audioReady+=1 else note("WARN","AUDIO_NOT_LOADED",sound,"Check experience permissions / network / asset availability. A configured ID is not proof of playback.")end
				end
			end
		end
		local player=Players.LocalPlayer
		local gui=player and player:FindFirstChildOfClass("PlayerGui")
		local root=gui and gui:FindFirstChild("VaultBreakersUI")
		if not root then note("ERROR","NO_UI",gui,"Wait for Client ready, then run again in the CLIENT command bar.")
		else
			local safe=root:FindFirstChild("SafeArea")
			if safe then report.viewport={width=safe.AbsoluteSize.X,height=safe.AbsoluteSize.Y} end
			local input=UserInputService:GetLastInputType()
			report.input=if input==Enum.UserInputType.Touch then "touch" else tostring(input)
			for _,object in root:GetDescendants() do
				if object:IsA("GuiObject") and shown(object,root) then
					if object:IsA("TextLabel") or object:IsA("TextButton") then
						local bounds,size=object.TextBounds,object.AbsoluteSize
						if object.Text~="" and bounds.X>0 and bounds.Y>0 then
							report.stats.textMeasured+=1
							if bounds.X>size.X+2 or bounds.Y>size.Y+2 then note("WARN","TEXT_OVERFLOW",object,"Native TextBounds exceeds its rectangle; check language, font and device.") end
						end
					end
					if object:IsA("GuiButton") and object.Active then
						if object.AbsoluteSize.Y<44 then note("WARN","SMALL_TARGET",object,"Interactive target is less than 44 px high.") end
						if safe and not scrolling(object,root) then
							local p,s,origin,area=object.AbsolutePosition,object.AbsoluteSize,safe.AbsolutePosition,safe.AbsoluteSize
							if p.X<origin.X-1 or p.Y<origin.Y-1 or p.X+s.X>origin.X+area.X+1 or p.Y+s.Y>origin.Y+area.Y+1 then
								note("WARN","OUTSIDE_SAFE_AREA",object,"A fixed button extends outside the GUI safe area.")
							end
						end
					end
				end
			end
			if report.stats.textMeasured==0 then note("INFO","NO_TEXT_MEASUREMENTS",root,"No rendered text bounds yet. Wait a frame and run again.") end
		end
	end
	if not quiet then
		print(string.format("[Vault Studio] %s: %d set parts, %d seats, %d lights; %d native text measurements; %d findings.",report.context,report.stats.parts,report.stats.seats,report.stats.lights,report.stats.textMeasured,#report.findings))
		for _,finding in report.findings do warn(finding.level.." / "..finding.code.." / "..finding.path.." — "..finding.message) end
		print("[Vault Studio] Read-only scan only. Complete the movement, input, networking, audio and persistence checklist separately.")
	end
	return report
end
return Checks
