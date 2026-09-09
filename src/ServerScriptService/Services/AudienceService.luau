--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.VaultBreakers.Network.Remotes)

local AudienceService = {}

type PollType = "OFFER_POLL" | "LIFELINE_EMERGENCY"

local isPollActive = false
local currentPollType: PollType = "OFFER_POLL"
local currentBreakerUserId: number? = nil

local votes: { [number]: "EXTRACT" | "PUSH" } = {}
local activePollThread: thread? = nil

local function calculateStats(): (number, number, number, number)
	local extractCount = 0
	local pushCount = 0
	for _, v in pairs(votes) do
		if v == "EXTRACT" then
			extractCount += 1
		elseif v == "PUSH" then
			pushCount += 1
		end
	end

	local total = extractCount + pushCount
	local extractPct = 50
	local pushPct = 50

	if total > 0 then
		extractPct = math.round((extractCount / total) * 100)
		pushPct = 100 - extractPct
	end

	return extractCount, pushCount, extractPct, pushPct
end

local function broadcastStats()
	local extCount, pCount, extPct, pPct = calculateStats()
	Remotes.getEvent("AudiencePollUpdated"):FireAllClients(extCount, pCount, extPct, pPct)
end

function AudienceService.init()
	Remotes.getEvent("AudienceVote").OnServerEvent:Connect(function(player: Player, vote: any)
		if not isPollActive then return end
		-- Breaker cannot vote on their own run
		if player.UserId == currentBreakerUserId then return end

		if vote == "EXTRACT" or vote == "PUSH" then
			votes[player.UserId] = vote
			broadcastStats()
		end
	end)
end

function AudienceService.startOfferPoll(breakerUserId: number, durationSeconds: number)
	AudienceService.cancelPoll()

	isPollActive = true
	currentPollType = "OFFER_POLL"
	currentBreakerUserId = breakerUserId
	table.clear(votes)

	broadcastStats()

	activePollThread = task.spawn(function()
		task.wait(durationSeconds)
		if isPollActive and currentPollType == "OFFER_POLL" then
			isPollActive = false
		end
	end)
end

function AudienceService.startLifelineEmergency(
	breakerUserId: number,
	durationSeconds: number,
	onFinished: (consensus: "EXTRACT" | "PUSH", extractPct: number, pushPct: number) -> ()
)
	AudienceService.cancelPoll()

	isPollActive = true
	currentPollType = "LIFELINE_EMERGENCY"
	currentBreakerUserId = breakerUserId
	table.clear(votes)

	Remotes.getEvent("AudienceLifelineTriggered"):FireAllClients(durationSeconds)
	broadcastStats()

	activePollThread = task.spawn(function()
		task.wait(durationSeconds)
		if isPollActive and currentPollType == "LIFELINE_EMERGENCY" then
			isPollActive = false
			local _, _, extPct, pPct = calculateStats()
			local consensus: "EXTRACT" | "PUSH" = if extPct >= pPct then "EXTRACT" else "PUSH"
			onFinished(consensus, extPct, pPct)
		end
	end)
end

function AudienceService.cancelPoll()
	if activePollThread then
		task.cancel(activePollThread)
		activePollThread = nil
	end
	isPollActive = false
	table.clear(votes)
	currentBreakerUserId = nil
end

function AudienceService.getStats()
	return calculateStats()
end

return AudienceService
