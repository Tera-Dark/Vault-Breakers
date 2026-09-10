--!nonstrict
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local ContentProvider=game:GetService("ContentProvider")
local TweenService=game:GetService("TweenService")
local Shared=game:GetService("ReplicatedStorage").VaultBreakers
local AssetConfig=require(Shared.Config.AssetConfig)
local Show=require(Shared.Shared.ShowRules)
local Pool=require(Shared.Config.RewardPool)
local UI=require(script.Parent.Parent.UI.Components)
local C=UI.colors
local Effects={};Effects.__index=Effects
local function bus(name)
	return if name=="Music"or name=="Reveal"or name=="Showtime"then"MUSIC"elseif name=="Cheer"or name=="Gasp"then"CROWD"elseif name=="Click"then"UI"else"SFX"
end
function Effects.new(parent)
	local self=setmetatable({sounds={},groups={},tokens={},key="",scope="",critical=false,settings={sound=true},alive=true},Effects)
	self.folder=Instance.new("Folder");self.folder.Name="VaultAudio";self.folder.Parent=SoundService
	for _,name in {"UI","SFX","CROWD","MUSIC"}do local group=Instance.new("SoundGroup");group.Name=name;group.Parent=self.folder;self.groups[name]=group end
	self.correction=Instance.new("ColorCorrectionEffect");self.correction.Name="VaultClientGrade";self.correction.Contrast=.06;self.correction.Saturation=-.04;self.correction.Parent=Lighting
	self.border=UI.frame(parent,"PressureBorder",C.Red);self.border.Size=UDim2.fromScale(1,1);self.border.BackgroundTransparency=1;self.border.ZIndex=45;self.border.Visible=false
	self.stroke=UI.stroke(self.border,C.Red,.5);self.stroke.Thickness=3
	local preload={}
	for name,defaultId in AssetConfig.Sounds do
		local override=AssetConfig.OriginalUploads[name]
		local id=if override and override~=""then override else defaultId
		if id==""then continue end
		local sound=Instance.new("Sound");sound.Name="Vault"..name;sound.SoundId=id;sound.Volume=AssetConfig.Volume
		sound.SoundGroup=self.groups[bus(name)];sound.Looped=name=="Music"or name=="Heartbeat"
		sound.RollOffMinDistance=6;sound.RollOffMaxDistance=35
		sound:SetAttribute("VaultAudioCue",name);sound:SetAttribute("ConfiguredId",id);sound:SetAttribute("DefaultId",defaultId);sound:SetAttribute("OriginalOverride",override~=nil and override~="");sound:SetAttribute("LoadState","PENDING")
		if name=="Tick"then sound.Volume=.20;sound.PlaybackSpeed=1.3 end
		if name=="Heartbeat"then sound.Volume=.26 end
		sound.Parent=self.folder;self.sounds[name]=sound;table.insert(preload,sound)
		sound.Loaded:Connect(function()if self.alive then sound:SetAttribute("LoadState","LOADED")end end)
	end
	task.spawn(function()
		local ok,err=pcall(function()ContentProvider:PreloadAsync(preload)end)
		if not ok and self.alive then warn("[Vault audio] Preload incomplete: "..tostring(err))end
	end)
	task.delay(10,function()
		if not self.alive then return end
		for name,sound in self.sounds do
			local loaded=sound.IsLoaded
			sound:SetAttribute("LoadState",if loaded then"LOADED"else"UNAVAILABLE")
			if not loaded then
				warn("[Vault audio] Validate experience permission/playback for "..name.." / "..sound.SoundId)
				if sound:GetAttribute("OriginalOverride")then
					sound.SoundId=sound:GetAttribute("DefaultId");sound:SetAttribute("LoadState","FALLBACK_LIBRARY")
					task.spawn(function()pcall(function()ContentProvider:PreloadAsync({sound})end)end)
				end
			end
		end
	end)
	return self
end
function Effects:allowed(name)
	return self.settings.sound~=false and not(bus(name)=="MUSIC"and self.settings.music==false)and not(bus(name)=="CROWD"and self.settings.crowd==false)
end
function Effects:play(name)
	if not self.alive or not self:allowed(name)then return end
	local sound=self.sounds[name]
	if not sound then return end
	if not sound.IsLoaded then
		-- Do not queue an emotional one-shot to play late in a different phase.
		if bus(name)=="SFX"and self.sounds.Click then self.sounds.Click:Play()end
		return
	end
	self.tokens[name]=(self.tokens[name]or 0)+1;local token=self.tokens[name]
	sound.TimePosition=0;sound:Play()
	local seconds=AssetConfig.ClipSeconds[name]
	if seconds then task.delay(seconds,function()if self.alive and self.tokens[name]==token then sound:Stop()end end)end
end
function Effects:stop(name)
	self.tokens[name]=(self.tokens[name]or 0)+1
	if self.sounds[name]then self.sounds[name]:Stop()end
end
function Effects:stopPressure()self.border.Visible=false;self.critical=false;self:stop("Heartbeat")end
function Effects:update(snapshot,settings,feeds,context)
	if self.lastSoundSetting~=settings.sound then self.critical=false;self.lastSoundSetting=settings.sound end
	self.settings=settings;self.context=context or{}
	local focus=snapshot
	if not focus and(self.context.seatView or self.context.tvNear)then focus=feeds and feeds.MAIN end
	self.focus=focus
	local scope=if focus and focus.state~="IDLE"then focus.arenaId..":"..focus.runId else"LOBBY"
	if self.scope~=scope then
		self.scope=scope;self.scopeToken=(self.scopeToken or 0)+1;self.breachKey="";self.duckUntil=0
		for name in self.sounds do if name~="Click"then self:stop(name)end end
	end
	local spatial=not snapshot and self.context.tvNear and not self.context.seatView
	for name,sound in self.sounds do if name~="Click"then sound.Parent=if spatial and self.context.television then self.context.television else self.folder end end
	self.correction.Enabled=focus~=nil and not spatial
	if settings.reducedMotion and self.tween then self.tween:Cancel();self.tween=nil;self.correction.Brightness=0 end
	for name in self.sounds do if not self:allowed(name)then self:stop(name)end end
	local now=workspace:GetServerTimeNow()
	local key=if focus then scope..":"..focus.phaseId else "LOBBY"
	if self.key~=key then
		self.key=key;self:stopPressure();self.lastSecond=nil;self.nextRollTick=now
		if self.tween then self.tween:Cancel();self.tween=nil end
		self.correction.Brightness=0
		if focus and now-(focus.phaseStartedAt or 0)<.65 then
			if focus.state=="OFFER"and not focus.consensus then self:play("Offer");self.duckUntil=now+.7
			elseif focus.state=="OPENING"then self:play("Breach")
			elseif focus.state=="BREACH"and focus.round==1 and focus.breached==0 then self:play("Claim")
			elseif focus.state=="SHOWTIME"then self:play("Showtime")
			elseif focus.state=="REVEAL"and not settings.reducedMotion and not spatial then
				self.tween=TweenService:Create(self.correction,TweenInfo.new(.8),{Brightness=-.08});self.tween:Play()
			elseif focus.state=="RESULT"then self:play("Reveal")end
		end
	end
	if focus and focus.lastBreach then
		local breachKey=scope..":"..focus.lastBreach.id
		if breachKey~=self.breachKey then
			self.breachKey=breachKey
			if Show.freshBreach(focus,now)then
				local band=Show.band(focus.lastBreach.value,Pool.VALUES)
				if band=="SMALL"then self:play("Cheer");self.duckUntil=now+1.1
				elseif band=="JACKPOT"or band=="LARGE"then
					self.duckUntil=now+1.1
					local token,at=self.scopeToken,focus.lastBreach.at
					task.delay(.22,function()if self.alive and self.scopeToken==token and self.focus and self.focus.state=="BREACH_REACT"and self.focus.lastBreach and self.focus.lastBreach.at==at then self:play("Gasp");self:play("Impact")end end)
				end
			end
		end
	end
	self:tick(snapshot,now)
end
function Effects:tick(snapshot,now)
	if not self.alive then return end
	local focus=self.focus
	for name,group in self.groups do
		local enabled=self.settings.sound~=false and not(name=="MUSIC"and self.settings.music==false)and not(name=="CROWD"and self.settings.crowd==false)
		group.Volume=if enabled then AssetConfig.Mix[name]else 0
	end
	local music=self.sounds.Music
	local active=focus and focus.state~="IDLE"and focus.state~="RESULT"
	if music then
		local quiet=(self.duckUntil or 0)>now
		music.Volume=AssetConfig.Volume*(if quiet then .05 elseif focus and focus.state=="FINAL_CHOICE"then .55 else 1)
		if active and self:allowed("Music")and music.IsLoaded then if not music.IsPlaying then music:Play()end else music:Stop()end
	end
	if focus and focus.state=="OFFER_ROLL"and now<focus.deadline and now>=(self.nextRollTick or 0)then
		local progress=Show.progress(focus.phaseStartedAt,focus.deadline,now)
		self.nextRollTick=now+.14-.08*progress;self:play("Tick")
	end
	local decision=focus and(focus.state=="OFFER"or focus.state=="FINAL_CHOICE")
	local remaining=if decision then focus.deadline-now else 99
	if decision and remaining<=5 and remaining>0 then
		self.border.Visible=snapshot~=nil and not self.settings.reducedMotion
		self.stroke.Transparency=.55+.15*math.sin(now*math.pi*1.2)
		if not self.critical then self.critical=true;self:play("Heartbeat")end
		if self.sounds.Heartbeat then self.sounds.Heartbeat.PlaybackSpeed=1+(5-remaining)*.12 end
		local second=math.ceil(remaining)
		if second~=self.lastSecond then self.lastSecond=second;self:play("Tick")end
	else self:stopPressure();self.lastSecond=nil end
	if self.settings.reducedMotion then self.correction.Brightness=0 end
end
function Effects:destroy()
	self.alive=false
	if self.tween then self.tween:Cancel()end
	for _,sound in self.sounds do sound:Destroy()end
	self.folder:Destroy();self.correction:Destroy();self.border:Destroy()
end
return Effects
