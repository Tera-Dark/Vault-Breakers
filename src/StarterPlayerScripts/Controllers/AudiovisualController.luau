--!nonstrict
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local TweenService=game:GetService("TweenService")
local AssetConfig=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.AssetConfig)
local UI=require(script.Parent.Parent.UI.Components)
local C=UI.colors
local Effects={}
Effects.__index=Effects
function Effects.new(parent)
	local self=setmetatable({sounds={},key="",critical=false,settings={sound=true,reducedMotion=false}},Effects)
	self.correction=Instance.new("ColorCorrectionEffect")
	self.correction.Name="VaultClientGrade";self.correction.Contrast=0.06;self.correction.Saturation=-0.04;self.correction.Parent=Lighting
	self.border=UI.frame(parent,"PressureBorder",C.Red);self.border.Size=UDim2.fromScale(1,1);self.border.BackgroundTransparency=1;self.border.ZIndex=45;self.border.Visible=false
	self.stroke=UI.stroke(self.border,C.Red,0.5);self.stroke.Thickness=3
	for name,id in AssetConfig.Sounds do
		if id=="" and (name=="Offer" or name=="Claim" or name=="Breach" or name=="Tick") then id=AssetConfig.Sounds.Click end
		if id~="" then
			local sound=Instance.new("Sound");sound.Name="Vault"..name;sound.SoundId=id;sound.Volume=AssetConfig.Volume;sound.Looped=name=="Heartbeat";sound.Parent=SoundService
			if name=="Tick" then sound.Volume=0.13;sound.PlaybackSpeed=1.3 end
			if name=="Breach" then sound.PlaybackSpeed=0.72 end
			self.sounds[name]=sound
		end
	end
	return self
end
function Effects:play(name)
	if not self.settings.sound then return end
	local sound=self.sounds[name]
	if not sound and (name=="Claim" or name=="Offer") then sound=self.sounds.Click end
	if sound then sound:Play() end
end
function Effects:stopPressure()
	self.border.Visible=false;self.critical=false
	local heartbeat=self.sounds.Heartbeat
	if heartbeat then heartbeat:Stop() end
end
function Effects:update(snapshot,settings)
	self.settings=settings
	if self.lastSoundSetting~=settings.sound then self.critical=false;self.lastSoundSetting=settings.sound end
	if settings.reducedMotion and self.tween then self.tween:Cancel();self.tween=nil;self.correction.Brightness=0 end
	if not settings.sound then for _,sound in self.sounds do sound:Stop() end end
	local key=if snapshot then snapshot.arenaId..":"..snapshot.runId..":"..snapshot.phaseId else "LOBBY"
	if key==self.key then return end
	self.key=key;self:stopPressure()
	if self.tween then self.tween:Cancel();self.tween=nil end
	self.correction.Brightness=0
	if not snapshot then return end
	local state=snapshot.state
	if state=="OFFER" then self:play("Offer")
	elseif state=="OPENING" then self:play("Breach")
	elseif state=="BREACH" and snapshot.round==1 and snapshot.breached==0 then self:play("Claim")
	elseif state=="REVEAL" and not settings.reducedMotion then
		self.tween=TweenService:Create(self.correction,TweenInfo.new(0.8),{Brightness=-0.10});self.tween:Play()
	elseif state=="RESULT" then self:play("Reveal") end
end
function Effects:tick(snapshot,now)
	local isDecision=snapshot and (snapshot.state=="OFFER" or snapshot.state=="FINAL_CHOICE")
	local remaining=if isDecision then snapshot.deadline-now else 99
	if isDecision and remaining<=5 and remaining>0 then
		self.border.Visible=not self.settings.reducedMotion
		-- A gentle sub-1Hz border pulse, not a full-screen strobe.
		self.stroke.Transparency=0.55+0.15*math.sin(now*math.pi*1.2)
		if not self.critical then
			self.critical=true
			self:play("Heartbeat")
		end
		local second=math.ceil(remaining)
		if self.lastSecond~=second then self.lastSecond=second;self:play("Tick") end
	else self:stopPressure();self.lastSecond=nil end
	if self.settings.reducedMotion then self.correction.Brightness=0 end
end
return Effects
