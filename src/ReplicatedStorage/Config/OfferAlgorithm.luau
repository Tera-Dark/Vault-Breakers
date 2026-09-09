--!strict
local OfferAlgorithm = {}

-- PRD 17: Round Factors
local ROUND_FACTORS: { [number]: number } = {
	[1] = 0.45,
	[2] = 0.70,
	[3] = 0.90,
}

-- PRD 17: Calculate Remaining Expected Value (EV)
function OfferAlgorithm.calculateEV(remainingRewards: { number }): number
	if #remainingRewards == 0 then
		return 0
	end
	local sum = 0
	for _, val in ipairs(remainingRewards) do
		sum += val
	end
	return sum / #remainingRewards
end

-- PRD 17: Calculate Offer for the given round
function OfferAlgorithm.calculateOffer(roundIndex: number, remainingRewards: { number }): (number, number)
	local ev = OfferAlgorithm.calculateEV(remainingRewards)
	local factor: number

	if roundIndex >= 1 and roundIndex <= 3 then
		factor = ROUND_FACTORS[roundIndex]
	else
		-- Final round factor: 0.84 - 0.96 based on variance/randomness
		factor = math.random(84, 96) / 100
	end

	-- Variation: Random(0.97 - 1.03)
	local variation = math.random(970, 1030) / 1000
	local rawOffer = ev * factor * variation

	-- Clamp offer within reasonable boundaries (at least 1, below highest remaining)
	local maxReward = 0
	for _, val in ipairs(remainingRewards) do
		if val > maxReward then
			maxReward = val
		end
	end

	local finalOffer = math.clamp(math.round(rawOffer), 1, maxReward)
	return finalOffer, ev
end

return OfferAlgorithm
