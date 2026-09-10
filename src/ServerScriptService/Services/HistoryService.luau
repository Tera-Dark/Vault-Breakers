--!nonstrict
local DataStoreService=game:GetService("DataStoreService")
local Players=game:GetService("Players")
local Config=require(game:GetService("ReplicatedStorage").VaultBreakers.Config.HistoryConfig)
local History={};History.__index=History
function History.new(enabled,onChanged)
	local self=setmetatable({enabled=enabled,pending={},rows={},status=if enabled then"LOADING"else"DISABLED",nextWrite=0,nextRead=0,onChanged=onChanged or function()end},History)
	if enabled then local ok,store=pcall(function()return DataStoreService:GetOrderedDataStore(Config.StoreName)end);if ok then self.store=store else self.status="UNAVAILABLE"end end
	return self
end
function History:enqueue(result)
	if not self.enabled or self.closing or not result.breakerId or type(result.baseCredits)~="number"or result.baseCredits<1 or result.baseCredits~=result.baseCredits then return end
	self.pending[result.breakerId]=math.max(self.pending[result.breakerId]or 0,math.clamp(math.floor(result.baseCredits),1,1e12))
end
function History:flush()
	if self.writing or not self.store then return false end
	self.writing=true
	local batch=self.pending;self.pending={};local success=true
	for userId,best in batch do
		local ok=pcall(function()self.store:UpdateAsync(tostring(userId),function(old)
			return math.max(if type(old)=="number"and old==old then old else 0,best)
		end)end)
		if not ok then self.pending[userId]=math.max(self.pending[userId]or 0,best);success=false end
	end
	self.writing=false;return success
end
function History:refresh()
	if self.reading or not self.store then return false end
	self.reading=true
	local ok,result=pcall(function()
		local page=self.store:GetSortedAsync(false,3):GetCurrentPage();local rows={}
		for _,item in page do
			local id=tonumber(item.key)
			if id and id>0 and id==math.floor(id)and type(item.value)=="number"and item.value>0 then
				local named,name=pcall(function()return Players:GetNameFromUserIdAsync(id)end)
				table.insert(rows,{userId=id,name=if named then name else"Player #"..id,best=item.value})
			end
		end
		return rows
	end)
	self.reading=false
	if ok then self.rows=result;self.updatedAt=os.time();self.status="READY"else self.status=if #self.rows>0 then"STALE"else"UNAVAILABLE"end
	self.onChanged();return ok
end
function History:step(now)
	if not self.enabled or self.closing then return end
	if now>=self.nextWrite then self.nextWrite=now+Config.WriteSeconds;task.spawn(function()self:flush()end)end
	if now>=self.nextRead then self.nextRead=now+Config.RefreshSeconds;task.spawn(function()self:refresh()end)end
end
function History:display(serverRows)
	if self.enabled and #self.rows>0 then return {scope="HISTORY",rows=self.rows,cached=self.status=="STALE",updatedAt=self.updatedAt}end
	return {scope="SERVER",rows=serverRows}
end
function History:close()self.closing=true;if self.enabled then self:flush()end end
return History
