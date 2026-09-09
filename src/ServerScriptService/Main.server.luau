--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MatchState = require(ReplicatedStorage.VaultBreakers.Shared.MatchState)
local Remotes = require(ReplicatedStorage.VaultBreakers.Network.Remotes)
local RewardPool = require(ReplicatedStorage.VaultBreakers.Config.RewardPool)
local StageBuilder = require(script.Parent.Core.StageBuilder)
local MatchManager = require(script.Parent.Core.MatchManager)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)

print("[Vault Breakers] Initializing Server Systems...")

-- Initialize Player Data & Persistence
PlayerDataService.init()

-- Build Stage
local vaultModels = StageBuilder.buildStage()

-- Create Match Manager instance
local matchManager = MatchManager.new()

-- Bind ProximityPrompts for all 12 vaults
for vaultId, vModel in pairs(vaultModels) do
	vModel.prompt.Triggered:Connect(function(player: Player)
		if matchManager.currentState == MatchState.SELECT_CLAIM then
			if matchManager.currentBreaker == player then
				local success = matchManager:playerClaimVault(player, vaultId)
				if success then
					StageBuilder.setVaultClaimed(vaultId)
				end
			end
		elseif matchManager.currentState == MatchState.ROUND_BREACH then
			if matchManager.currentBreaker == player then
				local success = matchManager:playerBreachVault(player, vaultId)
				if success then
					-- Door will open upon receiving VaultBreached event or direct call
				end
			end
		end
	end)
end

-- Bind Emergency Lifeline Lever (PRD Section 22)
if StageBuilder.leverPrompt then
	StageBuilder.leverPrompt.Triggered:Connect(function(player: Player)
		matchManager:triggerLifeline(player)
	end)
end

local AudienceService = require(script.Parent.Services.AudienceService)
AudienceService.init()

-- Listen to network events to update physical stage
Remotes.getEvent("VaultBreached").OnServerEvent:Connect(function()
	-- Handled via internal state
end)

Remotes.getEvent("StateChanged").OnServerEvent:Connect(function() end)

-- Hook client updates for 3D stage effects
local screenPart = Workspace:WaitForChild("VaultArena"):WaitForChild("CuratorScreen")
local screenLabel = screenPart:FindFirstChild("SurfaceGui"):FindFirstChild("CuratorText") :: TextLabel

local function updateCuratorScreen(text: string)
	if screenLabel then
		screenLabel.Text = text
	end
end

-- Connect local stage effects with remotes broadcast
local StateChangedEvent = Remotes.getEvent("StateChanged")
StateChangedEvent.OnServerEvent:Connect(function() end) -- dummy to ensure existence

Remotes.getEvent("VaultBreached").OnServerEvent:Connect(function() end)

-- Update screen and prompts on state change
local originalChangeState = matchManager._changeState
matchManager._changeState = function(self: any, newState: any, extraData: any?)
	originalChangeState(self, newState, extraData)

	if newState == MatchState.SELECT_CLAIM then
		StageBuilder.updatePromptAction("Select Claim")
	elseif newState == MatchState.ROUND_BREACH then
		StageBuilder.updatePromptAction("Breach Vault")
	end

	if extraData and extraData.dialogue then
		updateCuratorScreen(string.format("[%s]\n%s", newState, extraData.dialogue))
	else
		updateCuratorScreen(string.format("[%s]", newState))
	end
end

local originalBreach = matchManager.playerBreachVault
matchManager.playerBreachVault = function(self: any, breaker: Player, vaultId: number): boolean
	local vault = self.vaults[vaultId]
	local rewardVal = vault and vault.rewardValue or 0
	local success = originalBreach(self, breaker, vaultId)
	if success then
		StageBuilder.openVaultDoor(vaultId, rewardVal)
	end
	return success
end

local LeaderboardService = require(script.Parent.Services.LeaderboardService)
LeaderboardService.init()

-- Hook Match Ended to record in leaderboard
local originalConclude = matchManager._concludeMatch
matchManager._concludeMatch = function(self: any, isExtracted: boolean, earnedCredits: number, finalOtherValue: number?)
	originalConclude(self, isExtracted, earnedCredits, finalOtherValue)
	local breaker = self.currentBreaker
	if breaker then
		local heat = DecisionService.getPlayerHeat(breaker.UserId)
		local finalEarnings = math.round(earnedCredits * heat)
		LeaderboardService.recordMatchResult({
			breakerUserId = breaker.UserId,
			breakerName = breaker.DisplayName,
			finalEarnings = finalEarnings,
			isExtracted = isExtracted,
			extractionRound = if isExtracted then self.currentRound else nil,
			claimVaultValue = self.vaults[self.claimVaultId :: number].rewardValue,
			finalVaultValue = finalOtherValue,
			heatMultiplier = heat,
			decisions = self.decisionsHistory,
		})
	end
end

-- Handle Player Manual Start from Lobby Hub or Lounge Gate
local function handleMatchStartRequest(player: Player)
	if matchManager.currentState == MatchState.IDLE then
		print(string.format("[Main] Player %s requested to enter the stage.", player.DisplayName))
		matchManager:startMatch(player)
	end
end

Remotes.getEvent("RequestStartMatch").OnServerEvent:Connect(handleMatchStartRequest)

if StageBuilder.portalPrompt then
	StageBuilder.portalPrompt.Triggered:Connect(handleMatchStartRequest)
end

-- Handle Player Join
local function onPlayerAdded(player: Player)
	print(string.format("[Vault Breakers] Player joined: %s (%d). Waiting in Lobby.", player.Name, player.UserId))
	-- Player remains in IDLE (Lobby mode) until they click "进入金库"
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	if matchManager.currentBreaker == player then
		print("[Vault Breakers] Current breaker left. Resetting match.")
		matchManager:_changeState(MatchState.IDLE)
		matchManager.currentBreaker = nil
		StageBuilder.buildStage() -- rebuild fresh stage
	end
end)

print("[Vault Breakers] Server fully ready!")
