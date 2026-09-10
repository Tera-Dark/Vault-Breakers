--!strict
export type PublicVault = { id: number, claimed: boolean, opened: boolean, value: number? }
export type Decision = { decision: string, grade: string, score: number, offer: number, ev: number, spread: number, certaintyEquivalent: number, explanation: string, automatic: boolean }
export type Result = {
	breakerId: number, breakerName: string, extracted: boolean, baseCredits: number,
	credits: number, heat: number, claimValue: number, chosenValue: number,
	otherValue: number?, choice: string?, round: number, decisions: { Decision },
	reputationGain: number?, nextHeat: number?, arenaId: string?, runId: number?, unlockedTitles: {string}?,
}
export type Snapshot = {
	arenaId: string, runId: number, phaseId: number, revision: number, state: string, breakerId: number?,
	breakerName: string, round: number, claimId: number?, quota: number, breached: number,
	remaining: { number }, vaults: { PublicVault }, offer: number, deadline: number, phaseStartedAt: number, cosmeticId: string?, titleId: string?,
	heat: number, audience: boolean, lifelineAvailable: boolean, lifelineUsed: boolean,
	poll: { left: number, right: number, total: number, kind: string, myVote: string? },
	consensus: string?, lastBreach: { id: number, value: number, at: number }?, result: Result?,
	finalId: number?, revealId: number?, automatic: boolean,
}
return {}
