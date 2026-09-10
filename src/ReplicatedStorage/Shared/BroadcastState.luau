--!strict
-- Explicit allowlist for the Green Room feed. Input must be an Engine public snapshot,
-- never the engine itself. No private reward mapping or per-viewer ballot is broadcast.
local Broadcast={}
function Broadcast.fromSnapshot(s: any): any
	local vaults={}
	for _,v in s.vaults do table.insert(vaults,{id=v.id,claimed=v.claimed,opened=v.opened,value=if v.opened or s.state=="RESULT"then v.value else nil})end
	return {
		arenaId=s.arenaId,runId=s.runId,phaseId=s.phaseId,revision=s.revision,state=s.state,
		breakerId=s.breakerId,breakerName=s.breakerName,round=s.round,breached=s.breached,quota=s.quota,
		phaseStartedAt=s.phaseStartedAt,deadline=s.deadline,offer=s.offer,claimId=s.claimId,finalId=s.finalId,revealId=s.revealId,
		remaining=table.clone(s.remaining),vaults=vaults,
		lastBreach=if s.lastBreach then table.clone(s.lastBreach)else nil,
		result=if s.result then {baseCredits=s.result.baseCredits,credits=s.result.credits,extracted=s.result.extracted}else nil,
		cosmeticId=s.cosmeticId,titleId=s.titleId,consensus=s.consensus,
	}
end
return Broadcast
