--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.VaultBreakers.Shared.Types)
local DecisionQuality = require(ReplicatedStorage.VaultBreakers.Shared.DecisionQuality)

local DecisionService = {}

-- PRD 31-32: Heat Multipliers based on decision streaks
local HEAT_TIERS = { 1.0, 1.2, 1.5, 2.0 }

local playerHeats: { [number]: { streak: number, heatIndex: number } } = {}

function DecisionService.getPlayerHeat(userId: number): number
	local data = playerHeats[userId]
	if not data then
		return 1.0
	end
	return HEAT_TIERS[data.heatIndex] or 1.0
end

function DecisionService.recordDecision(
	userId: number,
	decision: Types.PlayerDecisionType,
	offer: number,
	ev: number,
	remainingRewards: { number }
): Types.DecisionEvaluation
	local evalResult = DecisionQuality.evaluate(decision, offer, ev, remainingRewards)
	
	if not playerHeats[userId] then
		playerHeats[userId] = { streak = 0, heatIndex = 1 }
	end

	local pHeat = playerHeats[userId]
	if evalResult.grade == "ELITE_EXTRACT" or evalResult.grade == "SOUND_EXTRACT" or evalResult.grade == "REASONABLE_PUSH" then
		pHeat.streak += 1
		if pHeat.streak >= 2 and pHeat.heatIndex < #HEAT_TIERS then
			pHeat.heatIndex += 1
		end
	elseif evalResult.grade == "GREEDY_BLUNDER" then
		pHeat.streak = math.max(0, pHeat.streak - 1)
		if pHeat.heatIndex > 1 then
			pHeat.heatIndex -= 1
		end
	end

	return evalResult
end

return DecisionService
