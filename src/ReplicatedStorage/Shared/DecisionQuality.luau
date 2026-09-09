--!strict
-- A transparent heuristic, not an objective judgement of a player's risk preference.
-- ONLY information available at the time of the decision is accepted here.
local DecisionQuality = {}

export type Evaluation = {
	decision: string, grade: string, score: number, offer: number, ev: number,
	spread: number, certaintyEquivalent: number, explanation: string, automatic: boolean,
}

function DecisionQuality.evaluate(decision: string, offer: number, ev: number, values: { number }, automatic: boolean?): Evaluation
	local low, high, utility = math.huge, 0, 0
	for _, value in values do
		low = math.min(low, value)
		high = math.max(high, value)
		utility += math.sqrt(value)
	end
	if #values == 0 then low = 0 end
	local ce = if #values > 0 then (utility / #values) ^ 2 else 0
	local ratio = if ev > 0 then offer / ev else 1
	local grade, score, explanation = "DARING_PUSH", 0, "risk_preference"
	if automatic then
		grade, score, explanation = "AUTO_PUSH", 0, "automatic_neutral"
	elseif decision == "EXTRACT" then
		if ratio >= 0.85 and high - low >= 4000 then
			grade, score, explanation = "ELITE_EXTRACT", 1, "certainty_high_spread"
		elseif offer >= ce * 0.9 then
			grade, score, explanation = "SOUND_EXTRACT", 1, "certainty_fair"
		else
			grade, score, explanation = "CAUTIOUS_EXTRACT", 0, "early_certainty"
		end
	elseif ratio <= 0.65 or offer < ce * 0.8 then
		grade, score, explanation = "REASONABLE_PUSH", 1, "room_to_continue"
	elseif ratio >= 0.88 and high > 0 and (high - offer) / high < 0.12 then
		grade, score, explanation = "THIN_UPSIDE", -1, "limited_upside"
	end
	return {
		decision = decision, grade = grade, score = score, offer = offer, ev = ev,
		spread = high - low, certaintyEquivalent = ce, explanation = explanation,
		automatic = automatic == true,
	}
end

return DecisionQuality
