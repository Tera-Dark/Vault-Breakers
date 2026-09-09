--!strict
local DecisionService = {}
local TIERS = { { points = 0, heat = 1.0 }, { points = 3, heat = 1.2 }, { points = 7, heat = 1.5 }, { points = 12, heat = 2.0 } }
function DecisionService.heatFor(points: number): number
	local heat = 1
	for _, tier in TIERS do if points >= tier.points then heat = tier.heat end end
	return heat
end
function DecisionService.apply(profile: any, decisions: { any }): number
	local reputation = 2 -- completion, not a prediction stake
	for _, decision in decisions do
		profile.qualityPoints = math.max(0, profile.qualityPoints + decision.score)
		if decision.score > 0 then
			profile.decisionStreak += 1
			reputation += 2
		elseif decision.score < 0 then
			profile.decisionStreak = math.max(0, profile.decisionStreak - 1)
		end
		if not decision.automatic then
			profile.decisionsMade += 1
			if decision.score > 0 then profile.soundDecisions += 1 end
		end
	end
	profile.heat = DecisionService.heatFor(profile.qualityPoints)
	profile.highestHeat = math.max(profile.highestHeat, profile.heat)
	profile.longestStreak = math.max(profile.longestStreak, profile.decisionStreak)
	profile.reputation += reputation
	return reputation
end
return DecisionService
