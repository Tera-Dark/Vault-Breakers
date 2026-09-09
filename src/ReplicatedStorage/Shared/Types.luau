--!strict
local MatchState = require(script.Parent.MatchState)

export type VaultData = {
	id: number,
	rewardValue: number,
	isClaimed: boolean,
	isBreached: boolean,
}

export type PlayerDecisionType = "EXTRACT" | "PUSH"
export type FinalDecisionType = "KEEP" | "SWAP"

export type DecisionQualityGrade = 
	"ELITE_EXTRACT"
	| "SOUND_EXTRACT"
	| "CAUTIOUS_EXTRACT"
	| "REASONABLE_PUSH"
	| "DARING_PUSH"
	| "GREEDY_BLUNDER"

export type DecisionEvaluation = {
	decision: PlayerDecisionType,
	grade: DecisionQualityGrade,
	offer: number,
	ev: number,
	spread: number,
	explanation: string,
}

export type MatchSummary = {
	breakerUserId: number,
	breakerName: string,
	finalEarnings: number,
	isExtracted: boolean,
	extractionRound: number?,
	claimVaultValue: number,
	finalVaultValue: number?,
	heatMultiplier: number,
	decisions: { DecisionEvaluation },
}

return {}
