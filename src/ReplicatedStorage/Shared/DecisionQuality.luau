--!strict
local Types = require(script.Parent.Types)

local DecisionQuality = {}

-- PRD 23-30: Risk-Adjusted Decision Evaluation
function DecisionQuality.evaluate(
	decision: Types.PlayerDecisionType,
	offer: number,
	ev: number,
	remainingRewards: { number }
): Types.DecisionEvaluation
	local minVal = math.huge
	local maxVal = -math.huge
	for _, val in ipairs(remainingRewards) do
		if val < minVal then minVal = val end
		if val > maxVal then maxVal = val end
	end
	if minVal == math.huge then minVal = 0 end
	if maxVal == -math.huge then maxVal = 0 end

	local spread = maxVal - minVal
	local ratio = if ev > 0 then (offer / ev) else 1.0

	local grade: Types.DecisionQualityGrade
	local explanation: string

	if decision == "EXTRACT" then
		-- Accepting the sure thing
		if ratio >= 0.85 and spread >= 4000 then
			grade = "ELITE_EXTRACT"
			explanation = "Secured high guaranteed value against massive downside risk."
		elseif ratio >= 0.65 then
			grade = "SOUND_EXTRACT"
			explanation = "Solid risk-adjusted extraction with favorable certainty."
		else
			grade = "CAUTIOUS_EXTRACT"
			explanation = "Extracted early under a conservative valuation."
		end
	else -- PUSH
		-- Rejecting the offer for higher variance
		if ratio <= 0.65 then
			grade = "REASONABLE_PUSH"
			explanation = "Low offer relative to potential. Push was mathematically justified."
		elseif maxVal >= 5000 or (maxVal - offer >= 1500) then
			grade = "DARING_PUSH"
			explanation = "Bold push into high volatility targeting the top-tier prize."
		elseif ratio >= 0.88 and spread < 2000 then
			grade = "GREEDY_BLUNDER"
			explanation = "High-risk rejection of a near-optimal certainty offer with little upside."
		else
			grade = "DARING_PUSH"
			explanation = "Aggressive push into uncertainty against a competitive offer."
		end
	end

	return {
		decision = decision,
		grade = grade,
		offer = offer,
		ev = ev,
		spread = spread,
		explanation = explanation,
	}
end

return DecisionQuality
