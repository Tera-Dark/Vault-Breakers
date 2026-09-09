--!strict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local REMOTE_EVENT_NAMES = {
	"StateChanged",              -- Server -> All: (newState, extraData)
	"VaultClaimed",              -- Server -> All: (vaultId, breakerUserId)
	"VaultBreached",             -- Server -> All: (vaultId, revealedValue, remainingVaultsCount)
	"OfferPresented",            -- Server -> All: (roundIndex, offerAmount, pressureSeconds)
	"PlayerDecision",            -- Client -> Server: (decision: "EXTRACT" | "PUSH")
	"AudienceVote",              -- Client -> Server: (vote: "EXTRACT" | "PUSH")
	"AudiencePollUpdated",       -- Server -> All: (extractCount, pushCount, extractPct, pushPct)
	"AudienceLifelineTriggered", -- Server -> All: (secondsLeft)
	"TriggerLifeline",           -- Client -> Server: ()
	"FinalSwapDecision",         -- Client -> Server: (choice: "KEEP" | "SWAP")
	"MatchEnded",                -- Server -> All: (summaryTable)
	"RequestStartMatch",         -- Client -> Server: ()
	"RequestLeaderboard",        -- Client -> Server: ()
	"LeaderboardData",           -- Server -> Client: (topEarningsList, topHeatList)
	"PlayerDataSync",            -- Server -> Client: (playerData)
	"BuyShopItem",               -- Client -> Server: (itemId)
	"ShopPurchaseResult",        -- Server -> Client: (success, message, newCash)
	"UseInventoryItem",          -- Client -> Server: (itemId)
}

local remotesFolder: Folder

if RunService:IsServer() then
	remotesFolder = ReplicatedStorage:FindFirstChild("VaultRemotes") :: Folder
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "VaultRemotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	for _, name in ipairs(REMOTE_EVENT_NAMES) do
		if not remotesFolder:FindFirstChild(name) then
			local event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = remotesFolder
		end
	end
else
	remotesFolder = ReplicatedStorage:WaitForChild("VaultRemotes") :: Folder
end

function Remotes.getEvent(name: string): RemoteEvent
	local remote = remotesFolder:WaitForChild(name) :: RemoteEvent
	return remote
end

return Remotes
