--!strict
-- Fixed phrases only. No free text, stakes, prediction rewards, or decision authority.
local Reactions={ORDER={"CASH","PUSH","WOW","GASP"},COOLDOWN=4,LIFETIME=2.6,MAX_VISIBLE=3}
local VALID={CASH=true,PUSH=true,WOW=true,GASP=true}
function Reactions.new(): any return setmetatable({players={},recent={},serial=0},{__index=Reactions})end
function Reactions.accept(self:any,userId:number,key:any,now:number):(any,string?)
	if type(key)~="string"or not VALID[key]then return nil,"invalid_action"end
	if now<(self.players[userId]or 0)then return nil,"reaction_wait"end
	for i=#self.recent,1,-1 do if now-self.recent[i]>=Reactions.LIFETIME then table.remove(self.recent,i)end end
	if #self.recent>=Reactions.MAX_VISIBLE then return nil,"reaction_room_busy"end
	self.players[userId]=now+Reactions.COOLDOWN;table.insert(self.recent,now);self.serial+=1
	return {id=self.serial,key=key,createdAt=now,expiresAt=now+Reactions.LIFETIME}
end
function Reactions.forget(self:any,userId:number)self.players[userId]=nil end
return Reactions
