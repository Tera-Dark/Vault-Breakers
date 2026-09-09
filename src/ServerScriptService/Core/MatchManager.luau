--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.VaultBreakers.Config.GameConfig)
local RewardPool = require(ReplicatedStorage.VaultBreakers.Config.RewardPool)
local OfferAlgorithm = require(ReplicatedStorage.VaultBreakers.Config.OfferAlgorithm)
local MatchState = require(ReplicatedStorage.VaultBreakers.Shared.MatchState)
local Types = require(ReplicatedStorage.VaultBreakers.Shared.Types)
local Remotes = require(ReplicatedStorage.VaultBreakers.Network.Remotes)
local CuratorService = require(script.Parent.Parent.Services.CuratorService)
local DecisionService = require(script.Parent.Parent.Services.DecisionService)
local AudienceService = require(script.Parent.Parent.Services.AudienceService)
local StageBuilder = require(script.Parent.StageBuilder)
local PlayerDataService = require(script.Parent.Parent.Services.PlayerDataService)

local MatchManager = {}
MatchManager.__index = MatchManager

export type MatchManagerType = typeof(setmetatable({} :: {
	currentState: Types.MatchStateType,
	currentBreaker: Player?,
	vaults: { Types.VaultData },
	claimVaultId: number?,
	currentRound: number,
	vaultsBreachedThisRound: number,
	currentOffer: number,
	currentEV: number,
	activeTimerThread: thread?,
	decisionsHistory: { Types.DecisionEvaluation },
	hasUsedLifeline: boolean,
}, MatchManager))

function MatchManager.new()
	local self = setmetatable({
		currentState = MatchState.IDLE,
		currentBreaker = nil,
		vaults = {},
		claimVaultId = nil,
		currentRound = 1,
		vaultsBreachedThisRound = 0,
		currentOffer = 0,
		currentEV = 0,
		activeTimerThread = nil,
		decisionsHistory = {},
		hasUsedLifeline = false,
	}, MatchManager)

	self:_setupRemotes()
	return self
end

function MatchManager:_cancelTimer()
	if self.activeTimerThread then
		task.cancel(self.activeTimerThread)
		self.activeTimerThread = nil
	end
end

function MatchManager:_changeState(newState: Types.MatchStateType, extraData: any?)
	self.currentState = newState
	print(string.format("[MatchManager] State changed to: %s", newState))
	Remotes.getEvent("StateChanged"):FireAllClients(newState, extraData)
end

function MatchManager:_getRemainingRewards(): { number }
	local remaining = {}
	for _, v in ipairs(self.vaults) do
		if not v.isBreached then
			table.insert(remaining, v.rewardValue)
		end
	end
	return remaining
end

function MatchManager:_setupRemotes()
	Remotes.getEvent("PlayerDecision").OnServerEvent:Connect(function(player: Player, decision: any)
		if self.currentBreaker ~= player then return end
		if self.currentState ~= MatchState.PRESSURE_COUNTDOWN and self.currentState ~= MatchState.FINAL_PHASE then
			return
		end

		if decision == "EXTRACT" or decision == "PUSH" then
			self:_handleDecision(decision)
		end
	end)

	Remotes.getEvent("FinalSwapDecision").OnServerEvent:Connect(function(player: Player, choice: any)
		if self.currentBreaker ~= player then return end
		if self.currentState ~= MatchState.FINAL_SWAP_DECISION then return end

		if choice == "KEEP" or choice == "SWAP" then
			self:_handleFinalSwap(choice)
		end
	end)

	Remotes.getEvent("TriggerLifeline").OnServerEvent:Connect(function(player: Player)
		if self.currentBreaker ~= player then return end
		self:triggerLifeline(player)
	end)
end

function MatchManager:triggerLifeline(breaker: Player)
	if self.currentBreaker ~= breaker then return end
	if self.hasUsedLifeline then return end
	if self.currentState ~= MatchState.PRESSURE_COUNTDOWN and self.currentState ~= MatchState.FINAL_PHASE then
		return
	end

	self.hasUsedLifeline = true
	self:_cancelTimer()
	StageBuilder.animateLeverPull()

	self:_changeState(self.currentState, {
		roundIndex = self.currentRound,
		offer = self.currentOffer,
		dialogue = "AUDIENCE LIFELINE PULLED! 10 Seconds Emergency Vote!",
	})

	AudienceService.startLifelineEmergency(
		breaker.UserId,
		GameConfig.LIFELINE_POLL_DURATION,
		function(consensus: "EXTRACT" | "PUSH", extPct: number, pPct: number)
			local consensusText = string.format("AUDIENCE CONSENSUS: %s (%d%%)", consensus, if consensus == "EXTRACT" then extPct else pPct)
			print(string.format("[MatchManager] %s", consensusText))

			self:_changeState(self.currentState, {
				roundIndex = self.currentRound,
				offer = self.currentOffer,
				dialogue = consensusText,
			})

			-- Resume Pressure Timer for 10 extra seconds to decide
			self:_cancelTimer()
			Remotes.getEvent("OfferPresented"):FireAllClients(self.currentRound, self.currentOffer, 10)
			self.activeTimerThread = task.spawn(function()
				task.wait(10)
				if self.currentState == MatchState.PRESSURE_COUNTDOWN or self.currentState == MatchState.FINAL_PHASE then
					self:_handleDecision("PUSH", true)
				end
			end)
		end
	)
end

function MatchManager:startMatch(breaker: Player)
	if self.currentState ~= MatchState.IDLE then
		warn("[MatchManager] Cannot start match: not IDLE")
		return false
	end

	self:_cancelTimer()
	self.currentBreaker = breaker
	self.claimVaultId = nil
	self.currentRound = 1
	self.vaultsBreachedThisRound = 0
	self.decisionsHistory = {}
	self.hasUsedLifeline = false
	StageBuilder.resetLever()

	-- Shuffle rewards into 12 vaults
	local rewards = table.clone(RewardPool.VALUES)
	for i = #rewards, 2, -1 do
		local j = math.random(1, i)
		rewards[i], rewards[j] = rewards[j], rewards[i]
	end

	self.vaults = {}
	for i = 1, GameConfig.TOTAL_VAULTS do
		table.insert(self.vaults, {
			id = i,
			rewardValue = rewards[i],
			isClaimed = false,
			isBreached = false,
		})
	end

	if breaker.Character then
		breaker.Character:PivotTo(CFrame.lookAt(Vector3.new(0, 3.2, 0), Vector3.new(0, 3.2, -20)))
	end

	self:_changeState(MatchState.SELECT_CLAIM, {
		breakerUserId = breaker.UserId,
		breakerName = breaker.DisplayName,
		dialogue = CuratorService.getDialogue("INTRO"),
	})
	return true
end

function MatchManager:playerClaimVault(breaker: Player, vaultId: number)
	if self.currentBreaker ~= breaker then return false end
	if self.currentState ~= MatchState.SELECT_CLAIM then return false end
	if vaultId < 1 or vaultId > GameConfig.TOTAL_VAULTS then return false end

	self.claimVaultId = vaultId
	self.vaults[vaultId].isClaimed = true

	Remotes.getEvent("VaultClaimed"):FireAllClients(vaultId, breaker.UserId)

	-- Transition to Round 1 Breach
	self.currentRound = 1
	self.vaultsBreachedThisRound = 0

	local roundInfo = GameConfig.ROUNDS[self.currentRound]
	self:_changeState(MatchState.ROUND_BREACH, {
		roundIndex = self.currentRound,
		vaultsNeeded = roundInfo.vaultsToBreach,
		vaultsBreached = 0,
		dialogue = CuratorService.getDialogue("CLAIM_PICKED"),
	})
	return true
end

function MatchManager:playerBreachVault(breaker: Player, vaultId: number)
	if self.currentBreaker ~= breaker then return false end
	if self.currentState ~= MatchState.ROUND_BREACH then return false end

	local vault = self.vaults[vaultId]
	if not vault or vault.isClaimed or vault.isBreached then
		return false
	end

	vault.isBreached = true
	self.vaultsBreachedThisRound += 1

	local remainingRewards = self:_getRemainingRewards()
	Remotes.getEvent("VaultBreached"):FireAllClients(vaultId, vault.rewardValue, #remainingRewards)

	local roundInfo = GameConfig.ROUNDS[self.currentRound]
	if self.vaultsBreachedThisRound >= roundInfo.vaultsToBreach then
		-- Round quota met: transition to Offer Phase
		task.delay(GameConfig.VAULT_OPENING_DURATION, function()
			self:_presentOffer()
		end)
	else
		self:_changeState(MatchState.ROUND_BREACH, {
			roundIndex = self.currentRound,
			vaultsNeeded = roundInfo.vaultsToBreach,
			vaultsBreached = self.vaultsBreachedThisRound,
		})
	end
	return true
end

function MatchManager:_presentOffer()
	local remainingRewards = self:_getRemainingRewards()
	local offer, ev = OfferAlgorithm.calculateOffer(self.currentRound, remainingRewards)
	self.currentOffer = offer
	self.currentEV = ev

	local stateToSet = if self.currentRound <= 3 
		then MatchState.PRESSURE_COUNTDOWN 
		else MatchState.FINAL_PHASE

	local dialogueCat = if self.currentRound <= 3 
		then "OFFER_ANNOUNCED" 
		else "FINAL_OFFER"

	self:_changeState(stateToSet, {
		breakerUserId = if self.currentBreaker then self.currentBreaker.UserId else nil,
		roundIndex = self.currentRound,
		offer = offer,
		ev = ev,
		remainingCount = #remainingRewards,
		duration = GameConfig.PRESSURE_CLOCK_SECONDS,
		dialogue = CuratorService.getDialogue(dialogueCat),
	})

	Remotes.getEvent("OfferPresented"):FireAllClients(self.currentRound, offer, GameConfig.PRESSURE_CLOCK_SECONDS)

	-- Start Audience Poll (PRD Section 21)
	if self.currentBreaker then
		AudienceService.startOfferPoll(self.currentBreaker.UserId, GameConfig.PRESSURE_CLOCK_SECONDS)
	end

	-- Enable Emergency Lever if not used yet (PRD Section 22)
	if not self.hasUsedLifeline then
		StageBuilder.setLeverEnabled(true)
	end

	-- Start Pressure Clock Timer (18s)
	self:_cancelTimer()
	self.activeTimerThread = task.spawn(function()
		task.wait(GameConfig.PRESSURE_CLOCK_SECONDS - GameConfig.CRITICAL_PRESSURE_SECONDS)
		-- Critical 5s warning
		if self.currentState == stateToSet then
			print("[MatchManager] Critical 5 seconds remaining!")
		end
		task.wait(GameConfig.CRITICAL_PRESSURE_SECONDS)

		-- Auto Push on timeout
		if self.currentState == stateToSet then
			print("[MatchManager] Timeout reached: Auto Push triggered!")
			self:_handleDecision("PUSH", true)
		end
	end)
end

function MatchManager:_handleDecision(decision: Types.PlayerDecisionType, isAutoPush: boolean?)
	self:_cancelTimer()
	AudienceService.cancelPoll()
	StageBuilder.setLeverEnabled(false)

	local remainingRewards = self:_getRemainingRewards()
	local evalResult = DecisionService.recordDecision(
		self.currentBreaker.UserId,
		decision,
		self.currentOffer,
		self.currentEV,
		remainingRewards
	)
	table.insert(self.decisionsHistory, evalResult)

	if decision == "EXTRACT" then
		self:_handleExtraction()
	else -- PUSH
		if isAutoPush then
			self:_changeState(MatchState.DECISION_PUSH, {
				dialogue = CuratorService.getDialogue("AUTO_PUSH"),
				isAutoPush = true,
			})
		else
			self:_changeState(MatchState.DECISION_PUSH, {
				dialogue = "Push accepted. The hunt continues.",
				isAutoPush = false,
			})
		end

		task.wait(2.0)
		self.currentRound += 1
		self.vaultsBreachedThisRound = 0

		if self.currentRound <= 3 then
			local roundInfo = GameConfig.ROUNDS[self.currentRound]
			self:_changeState(MatchState.ROUND_BREACH, {
				roundIndex = self.currentRound,
				vaultsNeeded = roundInfo.vaultsToBreach,
				vaultsBreached = 0,
			})
		else
			-- Final Phase: Only Claim + 1 other vault remain
			self:_presentOffer()
		end
	end
end

function MatchManager:_handleExtraction()
	self:_changeState(MatchState.DECISION_EXTRACT, {
		earnings = self.currentOffer,
		dialogue = CuratorService.getDialogue("EXTRACT"),
	})

	task.wait(2.5)
	self:_concludeMatch(true, self.currentOffer)
end

function MatchManager:_handleFinalSwap(choice: Types.FinalDecisionType)
	self:_changeState(MatchState.FINAL_REVEAL, {
		choice = choice,
		dialogue = CuratorService.getDialogue("FINAL_REVEAL"),
	})

	-- Find the final remaining unbreached vault
	local finalOtherVault: Types.VaultData? = nil
	for _, v in ipairs(self.vaults) do
		if not v.isBreached and not v.isClaimed then
			finalOtherVault = v
			break
		end
	end

	local claimVault = self.vaults[self.claimVaultId :: number]
	local earnedAmount = if choice == "KEEP" 
		then claimVault.rewardValue 
		else (if finalOtherVault then finalOtherVault.rewardValue else claimVault.rewardValue)

	task.wait(3.0) -- Dramatic Pause
	self:_concludeMatch(false, earnedAmount, finalOtherVault and finalOtherVault.rewardValue)
end

function MatchManager:_concludeMatch(isExtracted: boolean, earnedCredits: number, finalOtherValue: number?)
	local breaker = self.currentBreaker
	if not breaker then return end

	local claimVal = self.vaults[self.claimVaultId :: number].rewardValue
	local heat = DecisionService.getPlayerHeat(breaker.UserId)
	local finalEarnings = math.round(earnedCredits * heat)

	local summary: Types.MatchSummary = {
		breakerUserId = breaker.UserId,
		breakerName = breaker.DisplayName,
		finalEarnings = finalEarnings,
		isExtracted = isExtracted,
		extractionRound = if isExtracted then self.currentRound else nil,
		claimVaultValue = claimVal,
		finalVaultValue = finalOtherValue,
		heatMultiplier = heat,
		decisions = self.decisionsHistory,
	}

	PlayerDataService.addEarnings(breaker, finalEarnings)

	self:_changeState(MatchState.SETTLEMENT, summary)
	Remotes.getEvent("MatchEnded"):FireAllClients(summary)

	task.wait(5.0)
	if breaker.Character then
		breaker.Character:PivotTo(CFrame.lookAt(StageBuilder.LOUNGE_SPAWN, StageBuilder.LOUNGE_SPAWN + Vector3.new(0, 0, -10)))
	end
	self:_changeState(MatchState.IDLE)
	self.currentBreaker = nil
end

return MatchManager
