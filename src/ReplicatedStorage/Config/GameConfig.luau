--!strict
local GameConfig = {}

-- PRD 12: Vault count
GameConfig.TOTAL_VAULTS = 12

-- PRD 14: Round Structure
-- Round 1: Open 4 (8 remaining) -> Offer #1
-- Round 2: Open 3 (5 remaining) -> Offer #2
-- Round 3: Open 2 (3 remaining) -> Offer #3
-- Final Phase: 2 remaining (Claim + 1 Final Vault) -> Final Offer -> Keep/Swap -> Final Reveal
GameConfig.ROUNDS = {
	[1] = { vaultsToBreach = 4, targetRemaining = 8 },
	[2] = { vaultsToBreach = 3, targetRemaining = 5 },
	[3] = { vaultsToBreach = 2, targetRemaining = 3 },
}

-- PRD 19: Pressure Clock Duration
GameConfig.PRESSURE_CLOCK_SECONDS = 18
GameConfig.CRITICAL_PRESSURE_SECONDS = 5

-- PRD 20: Timeout Policy
GameConfig.TIMEOUT_POLICY = "AUTO_PUSH"

-- PRD 22: Audience Lifeline
GameConfig.LIFELINE_POLL_DURATION = 10
GameConfig.MAX_LIFELINES_PER_RUN = 1

-- PRD 15: Single Opening Animation Target Duration
GameConfig.VAULT_OPENING_DURATION = 1.5

return GameConfig
