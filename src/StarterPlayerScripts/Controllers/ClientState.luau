--!nonstrict
-- Pure transport/view reducer. Cross-remote ordering must not select an old board,
-- clear another arena's pending action, or repeatedly reopen a dismissed result.
local State = {}
State.__index = State
function State.new(model)
	return setmetatable({model=model,cache={},shown={},dismissed={},pending=nil},State)
end
function State:view()
	local d=self.model.directory
	return (d and (d.myArena or d.view)) or "LOBBY"
end
function State:clearPending()
	self.pending=nil;self.model.pending=false
end
function State:hideRecap()
	local recap=self.model.recap
	if recap then self.dismissed[recap.arenaId]=recap.runId end
	self.model.showRecap=false
end
function State:select()
	local model=self.model
	local view=self:view()
	local snapshot=self.cache[view]
	local d=model.directory
	if snapshot and d then
		for _,arena in d.arenas or {} do
			if arena.id==view and arena.runId then
				if snapshot.runId<arena.runId or (snapshot.runId==arena.runId and arena.phaseId and snapshot.phaseId<arena.phaseId) then snapshot=nil end
				break
			end
		end
		if snapshot and d.myArena and snapshot.breakerId~=model.userId then snapshot=nil end
	end
	model.snapshot=snapshot
	model.syncing=view~="LOBBY" and snapshot==nil
	if snapshot and snapshot.state=="RESULT" and snapshot.breakerId==model.userId and d and d.myArena==view then
		if self.shown[view]~=snapshot.runId and self.dismissed[view]~=snapshot.runId then
			self.shown[view]=snapshot.runId;model.recap=snapshot;model.showRecap=true
		end
	end
end
function State:directory(data)
	local previous=self.model.directory
	if previous and data.sequence and previous.sequence and data.sequence<previous.sequence then return false,false end
	local changed=previous and previous.myArena~=data.myArena or not previous and data.myArena~=nil
	self.model.directory=data
	if changed then
		self:clearPending()
		if data.myArena then self.model.showRecap=false end
	end
	self:select()
	return true,changed
end
function State:snapshot(data)
	local previous=self.cache[data.arenaId]
	if previous then
		if data.runId<previous.runId or (data.runId==previous.runId and data.phaseId<previous.phaseId) then return false end
		if data.runId==previous.runId and data.phaseId==previous.phaseId and (data.revision or 0)<(previous.revision or 0) then return false end
	end
	self.cache[data.arenaId]=data
	if data.state=="RESULT" and data.breakerId==self.model.userId and data.result then
		if not self.model.recap or data.deadline>=self.model.recap.deadline then self.model.recap=data end
	end
	local pending=self.pending
	if pending and pending.arenaId==data.arenaId and (pending.runId~=data.runId or pending.phaseId~=data.phaseId) then self:clearPending() end
	self:select()
	return true
end
function State:beginAction(command,choice,now)
	local s=self.model.snapshot
	if not s or (command~="VOTE" and self.pending) then return nil end
	local payload={arenaId=s.arenaId,runId=s.runId,phaseId=s.phaseId,choice=choice}
	if command~="VOTE" then
		self.pending={arenaId=s.arenaId,runId=s.runId,phaseId=s.phaseId,expires=now+2}
		self.model.pending=true
	end
	return payload
end
function State:expirePending(now)
	if self.pending and now>=self.pending.expires then self:clearPending();return true end
	return false
end
return State
