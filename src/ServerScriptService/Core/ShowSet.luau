--!nonstrict
-- Presentation sockets and social fixtures. No hidden values or local camera state.
local G=require(script.Parent.Geometry)
local C=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.VisualConfig)
local Set={}
local function spotlight(parent,name,position,target,angle,brightness)
	local rig=G.hidden(parent,name,CFrame.lookAt(position,target))
	local light=Instance.new("SpotLight");light.Name="Focus";light.Face=Enum.NormalId.Front
	light.Angle=angle;light.Range=70;light.Brightness=brightness;light.Color=C.Ivory
	light.Shadows=false;light.Enabled=false;light.Parent=rig
	return rig
end
function Set.attach(world)
	for id,arena in world.arenas do
		local root,origin=arena.root,arena.origin
		local show=Instance.new("Folder");show.Name="ShowRig";show.Parent=root
		local houseCount=0
		for _,object in root:GetDescendants()do
			if object:IsA("Light")then object:SetAttribute("HouseLight",true);houseCount+=1 end
			if object:IsA("BasePart")and object.Name=="Diffuser"then object:SetAttribute("HouseDiffuser",true)end
		end
		show:SetAttribute("HouseCount",houseCount)
		spotlight(show,"FocusA",origin+Vector3.new(-12,24,2),origin+Vector3.new(0,4,0),21,7)
		spotlight(show,"FocusB",origin+Vector3.new(12,24,2),origin+Vector3.new(0,4,0),21,7)
		spotlight(show,"ContestantFill",origin+Vector3.new(0,18,5),origin+Vector3.new(0,4,10),36,1.8)
		G.hidden(show,"ReactionAnchor",CFrame.new(origin+Vector3.new(0,18,0)))
		for index,vault in arena.vaults do
			local floorCF=CFrame.new(vault.anchor.Position.X,origin.Y+1.06,vault.anchor.Position.Z)*CFrame.Angles(math.pi/2,0,0)
			local glyph=G.disk(vault.model,"FloorGlyph",floorCF,4.4,.035,C.Teal,Enum.Material.Neon)
			glyph.Transparency=1;glyph.CanQuery=false
			local inner=G.disk(vault.model,"GlyphInset",floorCF*CFrame.new(0,0,-.018),3.9,.035,C.Raised,Enum.Material.SmoothPlastic)
			inner.Transparency=1;inner.CanQuery=false
			for _,part in vault.wheel:GetDescendants()do if part:IsA("BasePart")then part:SetAttribute("OriginalTone",part.Color);part:SetAttribute("CosmeticWheel",true)end end
		end
		if id=="MAIN"then
			local z=arena.radius+7
			arena.entranceSpawn=CFrame.lookAt(origin+Vector3.new(0,4.4,z-2),origin+Vector3.new(0,4.4,0))
			G.block(show,"EntryCarpet",Vector3.new(7.5,.04,23),CFrame.new(origin+Vector3.new(0,1.075,z-11)),Color3.fromRGB(117,44,53),Enum.Material.Fabric)
			for _,x in {-5,5}do G.block(show,"EntryPost",Vector3.new(.65,10,.65),CFrame.new(origin+Vector3.new(x,6,z)),C.Silver)end
			G.block(show,"EntryHeader",Vector3.new(11,1,.7),CFrame.new(origin+Vector3.new(0,11,z)),C.Ink)
			local board=G.block(show,"ContestantScreen",Vector3.new(11,4,.18),CFrame.new(origin+Vector3.new(0,8.3,z-.45)),C.Ink)
			local entryText=G.label(board,"CONTESTANT ON AIR",C.Amber,700,250)
			entryText.Size=UDim2.fromScale(.70,.86);entryText.Position=UDim2.fromScale(.28,.07)
			local portrait=Instance.new("ImageLabel");portrait.Name="Portrait";portrait.BackgroundTransparency=1;portrait.Size=UDim2.fromScale(.22,.80);portrait.Position=UDim2.fromScale(.03,.10);portrait.Parent=entryText.Parent
			spotlight(show,"EntryFocus",origin+Vector3.new(0,22,z-4),origin+Vector3.new(0,4,z-2),26,6)
			G.hidden(world.cameras,"MAINIntro",CFrame.lookAt(origin+Vector3.new(8,7,z-10),origin+Vector3.new(0,4,z-2)))
		end
	end
	local lounge=world.lobby.spawnLocation.Parent
	local cf=CFrame.new(28,12,34)
	local welcome=lounge:FindFirstChild("WelcomeSign");if welcome then welcome:Destroy()end
	G.block(lounge,"BroadcastBezel",Vector3.new(33,14.8,.7),cf*CFrame.new(-2,10,26),C.Steel)
	local television=G.block(lounge,"LiveTelevision",Vector3.new(32,14,.16),cf*CFrame.new(-2,10,25.57),C.Ink)
	G.label(television,"VAULT BREAKERS / LIVE\n\nWAITING FOR THE NEXT CONTESTANT",C.Ivory,1280,560)
	television:SetAttribute("BroadcastSurface",true)
	world.television=television
	world.seats={}
	for _,seat in lounge:GetChildren()do
		if seat:IsA("Seat")then
			seat:SetAttribute("LoungeSeat",true)
			seat:SetAttribute("SeatIndex",#world.seats+1)
			local prompt=G.prompt(seat,"SeatPrompt","SIT & WATCH / 入座观赛","GREEN ROOM",.25)
			table.insert(world.seats,{seat=seat,prompt=prompt})
		end
	end
	local hall=Instance.new("Model");hall.Name="HallOfFame";hall.Parent=lounge
	local title=G.block(hall,"HallTitle",Vector3.new(29,2.4,.12),cf*CFrame.new(-61,11.5,23.7),C.Ink)
	G.label(title,"THIS SERVER / HIGHLIGHTS\nTOP 3 BASE REWARDS",C.Amber,1000,130)
	for rank,x in {-61,-73,-49}do
		local podium=Instance.new("Model");podium.Name="Podium"..rank;podium.Parent=hall
		local height=if rank==1 then 2.1 elseif rank==2 then 1.6 else 1.2
		local platform=G.block(podium,"Platform",Vector3.new(8,height,6.5),cf*CFrame.new(x,height/2,19),C.Ink,Enum.Material.SmoothPlastic,true)
		G.block(podium,"Trim",Vector3.new(8.15,.12,6.65),platform.CFrame*CFrame.new(0,height/2,0),if rank==1 then C.Amber else C.Silver)
		local plaque=G.block(podium,"Plaque",Vector3.new(7,1.5,.12),cf*CFrame.new(x,height+.95,15.6),C.Panel)
		G.label(plaque,string.format("%02d / WAITING FOR A HIGHLIGHT",rank),C.Muted,500,105)
		G.hidden(podium,"AvatarMount",cf*CFrame.new(x,height+.15,19))
	end
	world.hall=hall
end
return Set
