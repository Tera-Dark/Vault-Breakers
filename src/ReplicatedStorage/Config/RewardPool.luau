--!strict
local RewardPool = {}

-- PRD 13: Reward Pool (MVP: 12 Values)
RewardPool.VALUES = {
	1,
	5,
	10,
	25,
	50,
	100,
	250,
	500,
	1000,
	2500,
	5000,
	10000,
}

export type RewardPoolType = typeof(RewardPool.VALUES)

function RewardPool.formatCredits(amount: number): string
	local formatted = tostring(math.floor(amount))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted .. " Credits"
end

function RewardPool.formatNumber(amount: number): string
	local formatted = tostring(math.floor(amount))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

return RewardPool
