--!nonstrict
-- Three bounded, sanitized avatar displays; a failed/late request cannot replace a newer winner.
local Players=game:GetService("Players")
local UI=require(script.Parent.Parent.UI.Components)
local Locale=require(script.Parent.Parent.UI.Locale)
local Pool=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.RewardPool)
local Catalog=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.CosmeticCatalog)
local C=UI.colors
local Hall={};Hall.__index=Hall
function Hall.new(playerGui)return setmetatable({parent=playerGui,slots={},titles={},alive=true},Hall)end
function Hall:destroySlot(slot)
	slot.token+=1
	if slot.avatar then slot.avatar:Destroy();slot.avatar=nil end
end
function Hall:load(slot,userId)
	self:destroySlot(slot);slot.failed=false
	local token=slot.token
	local function placeholder()
		local part=Instance.new("Part");part.Name="PortraitLoading";part.Shape=Enum.PartType.Ball;part.Size=Vector3.new(1.6,1.6,1.6);part.Color=C.Amber
		part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.CFrame=slot.mount.CFrame*CFrame.new(0,2,0);part.Parent=slot.podium;slot.avatar=part
	end
	placeholder()
	task.spawn(function()
		local ok,model=pcall(function()return Players:CreateHumanoidModelFromUserIdAsync(userId)end)
		if not self.alive or token~=slot.token or not slot.podium.Parent or not slot.mount.Parent then if ok and model then model:Destroy()end;return end
		if not ok or not model then slot.failed=true;return end
		local parts=0
		for _,object in model:GetDescendants()do
			if object:IsA("BasePart")then
				parts+=1;object.Anchored=true;object.CanCollide=false;object.CanTouch=false;object.CanQuery=false
			elseif object:IsA("LuaSourceContainer")or object:IsA("Tool")or object:IsA("Sound")or object:IsA("ParticleEmitter")or object:IsA("ProximityPrompt")then object:Destroy()end
		end
		local _,size=model:GetBoundingBox()
		if parts>55 or size.Y<=0 or size.Y~=size.Y or size.Magnitude>150 then model:Destroy();slot.failed=true;return end
		local factor=math.min(1,6.5/size.Y,6.6/math.max(1,size.X),5.8/math.max(1,size.Z))
		model:ScaleTo(model:GetScale()*factor)
		local box,resized=model:GetBoundingBox()
		local target=slot.mount.CFrame*CFrame.new(0,resized.Y/2,0)
		model:PivotTo(target*box:Inverse()*model:GetPivot())
		local humanoid=model:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
		model.Name="WinnerAvatar";model.Parent=slot.podium
		if slot.avatar then slot.avatar:Destroy()end
		slot.avatar=model;slot.failed=false
	end)
end
function Hall:update(data,language)
	local world=workspace:FindFirstChild("VaultWorld");local hall=world and world:FindFirstChild("HallOfFame",true)
	if not hall then return end
	local t=function(key,args)return Locale.text(language,key,args)end
	local title=hall:FindFirstChild("HallTitle");local titleText=title and title:FindFirstChild("Copy",true)
	if titleText then titleText.Text=t(if data and data.scope=="HISTORY"then"hall_history"else"hall_server")..(if data and data.cached then " / "..t("hall_cached")else "").."\n"..t("hall_basis")end
	for i=1,3 do
		local podium=hall:FindFirstChild("Podium"..i);if not podium or not podium:FindFirstChild("AvatarMount")or not podium:FindFirstChild("Plaque")or not podium.Plaque:FindFirstChild("Copy",true)then continue end
		local slot=self.slots[i]
		if not slot or slot.podium~=podium then
			if slot then self:destroySlot(slot)end
			slot={podium=podium,mount=podium:FindFirstChild("AvatarMount"),token=0};self.slots[i]=slot
		end
		local row=data and data.rows and data.rows[i]
		if slot.userId~=(row and row.userId)then
			slot.userId=row and row.userId
			if row then self:load(slot,row.userId)else self:destroySlot(slot)end
		end
		local label=podium.Plaque:FindFirstChild("Copy",true)
		if label then label.Text=if row then string.format("%02d / %s\n%s CR%s",i,row.name,Pool.formatNumber(row.best),if slot.failed then " · "..t("avatar_unavailable")else"")else t("hall_empty")end
	end
	local live={}
	for _,player in Players:GetPlayers()do
		local key=player:GetAttribute("VaultTitle")
		local head=player.Character and(player.Character:FindFirstChild("Head")or player.Character:FindFirstChild("HumanoidRootPart"))
		if head and table.find(Catalog.TITLES,key)then
			live[player.UserId]=true
			local badge=self.titles[player.UserId]
			if not badge then
				local gui=UI.new("BillboardGui",self.parent,{Name="VaultTitle",Size=UDim2.fromOffset(210,26),StudsOffsetWorldSpace=Vector3.new(0,2.3,0),AlwaysOnTop=false,MaxDistance=55})
				local text=UI.gameText(gui,"Title","",13,C.Amber);text.Size=UDim2.fromScale(1,1);text.TextXAlignment=Enum.TextXAlignment.Center
				badge={gui=gui,text=text};self.titles[player.UserId]=badge
			end
			badge.gui.Adornee=head;badge.text.Text=t("title_"..key)
		end
	end
	for id,badge in self.titles do if not live[id]then badge.gui:Destroy();self.titles[id]=nil end end
end
function Hall:destroy()
	self.alive=false
	for _,s in self.slots do self:destroySlot(s)end
	for _,b in self.titles do b.gui:Destroy()end
	self.slots={};self.titles={}
end
return Hall
