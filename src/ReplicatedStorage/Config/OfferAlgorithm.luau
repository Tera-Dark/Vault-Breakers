--!strict
local OfferAlgorithm = {}
local FACTORS = { 0.45, 0.70, 0.90 }

function OfferAlgorithm.calculateEV(values: { number }): number
	local sum = 0
	for _, value in values do sum += value end
	return if #values > 0 then sum / #values else 0
end

function OfferAlgorithm.calculateOffer(round: number, values: { number }, random: ((number, number) -> number)?): (number, number)
	if #values == 0 then return 0, 0 end
	local rng = random or math.random
	local ev = OfferAlgorithm.calculateEV(values)
	local factor = FACTORS[round] or (rng(84, 96) / 100)
	local variation = rng(970, 1030) / 1000
	local maximum = 1
	for _, value in values do maximum = math.max(maximum, value) end
	return math.clamp(math.floor(ev * factor * variation + 0.5), 1, maximum), ev
end

return OfferAlgorithm
