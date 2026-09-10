--!nonstrict
local ProximityPromptService=game:GetService("ProximityPromptService")
local PromptController={}
PromptController.__index=PromptController
local function arenaOf(instance)
	local object=instance
	while object and object~=workspace do
		local id=object:GetAttribute("ArenaId")
		if id then return id end
		object=object.Parent
	end
	return nil
end
function PromptController.new(userId)
	local self=setmetatable({userId=userId,snapshot=nil,prompts={},refreshAt=0},PromptController)
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if self.prompts[prompt] and not self:allows(prompt) then prompt.Enabled=false end
	end)
	return self
end
function PromptController:allows(prompt)
	if self.blocked then return false end
	local s=self.snapshot
	local id=arenaOf(prompt)
	if not id then return not (s and s.breakerId==self.userId) end
	if not s or s.breakerId~=self.userId or s.arenaId~=id or workspace:GetServerTimeNow()>=s.deadline then return false end
	if prompt.Name=="VaultPrompt" then
		local parent=prompt.Parent
		local vaultModel=parent and parent.Parent
		local vaultId=vaultModel and vaultModel:GetAttribute("VaultId")
		local vault=vaultId and s.vaults[vaultId]
		if s.state=="FINAL_CHOICE"then return vaultId==s.claimId or vaultId==s.finalId end
		return (s.state=="CLAIM" or s.state=="BREACH") and vault and not vault.opened and not vault.claimed
	elseif prompt.Name=="LifelinePrompt" then return s.lifelineAvailable==true
	elseif prompt.Name:find("DecisionPrompt") then return s.state=="OFFER" or s.state=="FINAL_CHOICE" end
	return false
end
function PromptController:watch(world)
	if self.world==world then return end
	if self.added then self.added:Disconnect();self.removed:Disconnect()end
	self.world=world;self.prompts={};self.key=nil
	if not world then return end
	local function add(object)
		if object:IsA("ProximityPrompt") then self.prompts[object]=true;self.key=nil;object.Enabled=self:allows(object)==true end
	end
	self.added=world.DescendantAdded:Connect(add)
	self.removed=world.DescendantRemoving:Connect(function(object)self.prompts[object]=nil end)
	for _,object in world:GetDescendants()do add(object)end
end
function PromptController:update(snapshot,language,blocked)
	self.snapshot=snapshot;self.blocked=blocked==true
	self:watch(workspace:FindFirstChild("VaultWorld"))
	if not self.world then return end
	local key=(if snapshot then snapshot.arenaId..":"..snapshot.runId..":"..snapshot.phaseId..":"..tostring(snapshot.breakerId) else "LOBBY")..":"..language..":"..tostring(self.blocked)
	-- Only visit the small prompt set, not all 2,652 set parts. The periodic refresh
	-- also handles attributes/properties arriving after DescendantAdded.
	if self.key==key and os.clock()<self.refreshAt then return end
	self.key=key;self.refreshAt=os.clock()+1
	for prompt in self.prompts do
		prompt.Enabled=self:allows(prompt)==true
		if prompt.Name=="VaultPrompt" then
			local claim=snapshot and snapshot.state=="CLAIM"
			if snapshot and snapshot.state=="FINAL_CHOICE"then
				local keep=prompt.Parent.Parent:GetAttribute("VaultId")==snapshot.claimId
				prompt.ActionText=if language=="zh"then(if keep then "保留底牌"else "交换金库")else(if keep then "Keep claim"else "Swap vault")
				continue
			end
			prompt.ActionText=if language=="zh" then (if claim then "锁定底牌" else "开启并排除") else (if claim then "Claim vault" else "Breach vault")
		end
	end
end
return PromptController
