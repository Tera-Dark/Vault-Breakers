--!nonstrict
-- Local, per-arena presentation. Never dims global Lighting or touches outcome/interaction authority.
local Shared=game:GetService("ReplicatedStorage").VaultBreakers
local Show=require(Shared.Shared.ShowRules)
local Pool=require(Shared.Config.RewardPool)
local Catalog=require(Shared.Config.CosmeticCatalog)
local C=require(Shared.Config.VisualConfig)
local Controller={};Controller.__index=Controller
function Controller.new()return setmetatable({arenas={},confetti={},settings={}},Controller)end
function Controller:bind(id)
	local world=workspace:FindFirstChild("VaultWorld");local model=world and world:FindFirstChild(id)
	local rig=model and model:FindFirstChild("ShowRig")
	if not rig or not rig:GetAttribute("HouseCount")then return nil end
	for _,name in {"FocusA","FocusB","ContestantFill"}do local node=rig:FindFirstChild(name);if not node or not node:FindFirstChild("Focus")then return nil end end
	for i=1,12 do
		local v=model:FindFirstChild(string.format("Vault_%02d",i))
		if not v or not v:FindFirstChild("Interaction")or not v:FindFirstChild("FloorGlyph")or not v:FindFirstChild("GlyphInset")or not v:FindFirstChild("HandWheel",true)then return nil end
	end
	local old=self.arenas[id]
	if old and old.model==model then return old end
	local entry={model=model,rig=rig,lights={},diffusers={},vaults={},key="",breachKey=""}
	for _,o in model:GetDescendants()do
		if o:IsA("Light")and o:GetAttribute("HouseLight")then table.insert(entry.lights,{object=o,color=o.Color,brightness=o.Brightness,enabled=o.Enabled})end
		if o:IsA("BasePart")and o:GetAttribute("HouseDiffuser")then table.insert(entry.diffusers,{object=o,color=o.Color})end
	end
	for i=1,12 do
		local v=model:FindFirstChild(string.format("Vault_%02d",i))
		if v then entry.vaults[i]={model=v,anchor=v:FindFirstChild("Interaction"),glyph=v:FindFirstChild("FloorGlyph"),inset=v:FindFirstChild("GlyphInset"),wheel=v:FindFirstChild("HandWheel",true)}end
	end
	if #entry.lights~=rig:GetAttribute("HouseCount")then return nil end
	local h=Instance.new("Highlight");h.Name="NearbyChoice";h.FillTransparency=1;h.OutlineTransparency=.2;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Enabled=false;h.Parent=rig;entry.highlight=h
	self.arenas[id]=entry;return entry
end
function Controller:clearConfetti(arena)
	for i=#self.confetti,1,-1 do local c=self.confetti[i];if not arena or c.arena==arena then c.part:Destroy();table.remove(self.confetti,i)end end
end
function Controller:celebrate(entry,s,now)
	if self.settings.reducedMotion then return end
	local v=entry.vaults[s.lastBreach.id];if not v or not v.anchor then return end
	self:clearConfetti(s.arenaId)
	local seed=s.runId*131+s.lastBreach.id*8191
	local function random(a,b)seed=(seed*48271)%2147483647;return a+(b-a)*seed/2147483647 end
	for i=1,14 do
		local part=Instance.new("Part");part.Name="GoldConfetti";part.Size=Vector3.new(.12,.025,.36)
		part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
		part.Material=Enum.Material.SmoothPlastic;part.Color=if i%3==0 then C.Ivory else C.Amber
		part.CFrame=CFrame.new(v.anchor.Position+Vector3.new(0,2,0));part.Parent=entry.rig
		table.insert(self.confetti,{part=part,arena=s.arenaId,at=now,origin=part.Position,velocity=Vector3.new(random(-5,5),random(3,7),random(-5,5)),spin=random(-8,8)})
	end
end
function Controller:update(feeds,settings,player,blocked)
	self.settings=settings;self.player=player;self.blocked=blocked
	local now=workspace:GetServerTimeNow()
	for _,id in {"MAIN","QUICK"}do
		local s=feeds and feeds[id];local e=self:bind(id)
		if not e then continue end
		if not s then s={arenaId=id,runId=0,phaseId=0,state="IDLE",vaults={}}end
		if s.state=="IDLE"or(e.snapshot and e.snapshot.runId~=s.runId)then self:clearConfetti(id)end
		e.snapshot=s
		local skin=Catalog.ITEMS[s.cosmeticId or"CLASSIC"]or Catalog.ITEMS.CLASSIC
		if e.skin~=skin or now>=(e.skinRefreshAt or 0)then
			e.skin=skin;e.skinRefreshAt=now+1
			for _,v in e.vaults do if v.wheel then for _,part in v.wheel:GetDescendants()do
				if part:IsA("BasePart")and part:GetAttribute("CosmeticWheel")then part.Color=if skin.rgb then Color3.fromRGB(table.unpack(skin.rgb))else part:GetAttribute("OriginalTone")end
			end end end
		end
		local breach=s.lastBreach
		local key=if breach then s.runId..":"..breach.id else ""
		if e.breachKey~=key then
			e.breachKey=key
			if Show.freshBreach(s,now)and Show.band(breach.value,Pool.VALUES)=="SMALL"then self:celebrate(e,s,now)end
		end
	end
	if settings.reducedMotion then self:clearConfetti()end
	self:tick(now)
end
function Controller:tick(now)
	local root=self.player and self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart")
	for _,e in self.arenas do
		local s=e.snapshot;if not s or not e.model.Parent then continue end
		local final=s.state=="FINAL_CHOICE"or(s.state=="REVEAL"and s.finalId~=nil)
		local reaction=s.state=="BREACH_REACT"and Show.freshBreach(s,now)
		local band=if reaction then Show.band(s.lastBreach.value,Pool.VALUES)else"NEUTRAL"
		local pulse=if self.settings.reducedMotion then 0 else (if reaction then math.sin(math.pi*Show.progress(s.phaseStartedAt,s.deadline,now))else 0)
		for _,light in e.lights do
			local color=if band=="SMALL"then C.Amber elseif band=="LARGE"or band=="JACKPOT"then C.Red else light.color
			light.object.Color=light.color:Lerp(color,pulse*.8)
			light.object.Brightness=light.brightness*(if final then .08 elseif band=="JACKPOT"then 1-.65*pulse else 1+.28*pulse)
			light.object.Enabled=light.enabled
		end
		for _,p in e.diffusers do p.object.Color=if final then p.color:Lerp(C.Ink,.85)else p.color end
		local a,b,fill=e.rig:FindFirstChild("FocusA"),e.rig:FindFirstChild("FocusB"),e.rig:FindFirstChild("ContestantFill")
		for i,rig in {a,b}do
			if rig then
				local v=e.vaults[if i==1 then s.claimId or 0 else s.finalId or 0]
				rig.Focus.Enabled=final and v~=nil and v.anchor~=nil
				if rig.Focus.Enabled then rig.CFrame=CFrame.lookAt(rig.Position,v.anchor.Position+Vector3.new(0,.7,0))end
			end
		end
		if fill then fill.Focus.Enabled=final end
		local intro=e.rig:FindFirstChild("EntryFocus");if intro then intro.Focus.Enabled=s.state=="SHOWTIME"end
		local nearest,nearestDistance=nil,13
		for id,v in e.vaults do
			local data=s.vaults[id]
			local eligible=((s.state=="CLAIM"or s.state=="BREACH")and data and not data.opened and not data.claimed)or(s.state=="FINAL_CHOICE"and(id==s.claimId or id==s.finalId))
			local guides=eligible and self.settings.floorGuides~=false
			if v.glyph then v.glyph.Transparency=if guides then (if self.settings.reducedMotion then .42 else .4+.1*math.sin(now*3))else 1;v.glyph.Color=if id==s.claimId then C.Amber else C.Teal end
			if v.inset then v.inset.Transparency=if guides then 0 else 1 end
			if guides and root and s.breakerId==self.player.UserId and not self.blocked and v.anchor then
				local distance=(root.Position-v.anchor.Position).Magnitude
				if distance<nearestDistance then nearest=v.model:FindFirstChild("DoorAssembly");nearestDistance=distance end
			end
		end
		e.highlight.Adornee=nearest;e.highlight.Enabled=nearest~=nil;e.highlight.OutlineColor=C.Teal
		if s.state=="OFFER_ROLL"then
			local screen=e.model:FindFirstChild("CuratorScreen");local text=screen and screen:FindFirstChild("Copy",true)
			if text then text.Text="THE CURATOR OFFERS\n\n"..Pool.formatNumber(Show.counter(s.offer,s.phaseStartedAt,s.deadline,now,self.settings.reducedMotion)).." CR"end
		end
	end
	for i=#self.confetti,1,-1 do
		local c=self.confetti[i];local age=now-c.at
		if age>=1.4 or not c.part.Parent then c.part:Destroy();table.remove(self.confetti,i)
		else c.part.CFrame=CFrame.new(c.origin+c.velocity*age+Vector3.new(0,-7*age*age,0))*CFrame.Angles(age*c.spin,age*c.spin*.3,age*c.spin*.7);c.part.Transparency=math.max(0,(age-.9)/.5)end
	end
end
function Controller:destroy()
	self:clearConfetti()
	for _,e in self.arenas do
		for _,l in e.lights do l.object.Color=l.color;l.object.Brightness=l.brightness;l.object.Enabled=l.enabled end
		for _,p in e.diffusers do p.object.Color=p.color end
		e.highlight:Destroy()
	end
	self.arenas={}
end
return Controller
