--!strict
-- Engine configuration is deliberately Roblox-independent so it can be tested headlessly.
return table.freeze({
	TOTAL_VAULTS = 12,
	-- The fourth breach is essential: 12 - 4 - 3 - 2 - 1 = 2, including the claim.
	ROUNDS = {
		{ vaultsToBreach = 4, targetRemaining = 8 },
		{ vaultsToBreach = 3, targetRemaining = 5 },
		{ vaultsToBreach = 2, targetRemaining = 3 },
		{ vaultsToBreach = 1, targetRemaining = 2 },
	},
	PRESSURE_CLOCK_SECONDS = 18,
	CRITICAL_PRESSURE_SECONDS = 5,
	CLAIM_SECONDS = 45,
	BREACH_SECONDS = 40,
	VAULT_OPENING_DURATION = 1.35,
	TRANSITION_SECONDS = 0.8,
	FINAL_CHOICE_SECONDS = 15,
	REVEAL_SECONDS = 3.6,
	RESULT_SECONDS = 14,
	LIFELINE_POLL_DURATION = 10,
	LIFELINE_MIN_RESUME_SECONDS = 6,
	LIFELINE_FIRST_ROUND = 3,
	RECOMMENDED_MAX_PLAYERS = 8,
	NETWORK_INTERVAL = 0.1,
	ARENAS = {
		{ id = "MAIN", name = "STUDIO 01", audience = true },
		{ id = "QUICK", name = "STUDIO 02", audience = false },
	},
})
