--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.VaultBreakers.Network.Remotes)
local Types = require(ReplicatedStorage.VaultBreakers.Shared.Types)

local LeaderboardService = {}

export type LeaderboardEntry = {
	rank: number,
	playerName: string,
	userId: number,
	earnings: number,
	heatMultiplier: number,
	grade: string,
	dateStr: string,
}

local topEarnings: { LeaderboardEntry } = {
	{ rank = 1, playerName = "ApexBreaker", userId = 101, earnings = 10000, heatMultiplier = 2.0, grade = "神级提现 ELITE", dateStr = "今日" },
	{ rank = 2, playerName = "Viper_09", userId = 102, earnings = 7200, heatMultiplier = 1.5, grade = "稳健离场 SOUND", dateStr = "今日" },
	{ rank = 3, playerName = "ShadowKey", userId = 103, earnings = 5000, heatMultiplier = 1.2, grade = "勇敢博弈 DARING", dateStr = "昨日" },
	{ rank = 4, playerName = "GoldHunter_X", userId = 104, earnings = 3600, heatMultiplier = 1.2, grade = "稳健离场 SOUND", dateStr = "昨日" },
	{ rank = 5, playerName = "CyberPhantom", userId = 105, earnings = 2500, heatMultiplier = 1.0, grade = "谨慎提现", dateStr = "本周" },
}

local topHeat: { LeaderboardEntry } = {
	{ rank = 1, playerName = "ApexBreaker", userId = 101, earnings = 10000, heatMultiplier = 2.0, grade = "5 连胜决断", dateStr = "今日" },
	{ rank = 2, playerName = "GhostTrader", userId = 106, earnings = 4500, heatMultiplier = 2.0, grade = "4 连胜决断", dateStr = "今日" },
	{ rank = 3, playerName = "Viper_09", userId = 102, earnings = 7200, heatMultiplier = 1.5, grade = "3 连胜决断", dateStr = "今日" },
	{ rank = 4, playerName = "ZeroHesitation", userId = 107, earnings = 3000, heatMultiplier = 1.5, grade = "2 连胜决断", dateStr = "本周" },
}

function LeaderboardService.init()
	Remotes.getEvent("RequestLeaderboard").OnServerEvent:Connect(function(player: Player)
		Remotes.getEvent("LeaderboardData"):FireClient(player, topEarnings, topHeat)
	end)
end

function LeaderboardService.recordMatchResult(summary: Types.MatchSummary)
	if summary.finalEarnings <= 0 then return end

	local entry: LeaderboardEntry = {
		rank = #topEarnings + 1,
		playerName = summary.breakerName,
		userId = summary.breakerUserId,
		earnings = summary.finalEarnings,
		heatMultiplier = summary.heatMultiplier,
		grade = if summary.isExtracted then "提现离场" else "开箱揭晓",
		dateStr = "刚刚",
	}

	table.insert(topEarnings, entry)
	table.sort(topEarnings, function(a, b)
		return a.earnings > b.earnings
	end)

	for i, item in ipairs(topEarnings) do
		item.rank = i
	end
	if #topEarnings > 20 then
		table.remove(topEarnings, #topEarnings)
	end

	-- Check heat rank
	if summary.heatMultiplier > 1.0 then
		table.insert(topHeat, entry)
		table.sort(topHeat, function(a, b)
			return a.heatMultiplier > b.heatMultiplier
		end)
		for i, item in ipairs(topHeat) do
			item.rank = i
		end
		if #topHeat > 20 then
			table.remove(topHeat, #topHeat)
		end
	end
end

return LeaderboardService
