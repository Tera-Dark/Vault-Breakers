--!strict
local CuratorService = {}

local DIALOGUE = {
	INTRO = {
		"Welcome to the Vault stage. 12 Vaults. 1 Decision Maker.",
		"Inside these 12 vaults lies your fortune... or your regret.",
	},
	CLAIM_PICKED = {
		"Your Claim Vault is sealed. Its secret belongs only to the end.",
		"Locked. The only way to know what you hold is to eliminate the rest.",
	},
	OFFER_ANNOUNCED = {
		"I have evaluated your board. The Curator offers certainty.",
		"A bird in the hand, Breaker. Will you take it, or chase the ghost?",
	},
	CRITICAL_TIME = {
		"Clock is bleeding out. Five seconds.",
		"The audience is waiting. Decide now.",
	},
	AUTO_PUSH = {
		"Hesitation is a decision. You push forward.",
		"Time expired. Silence chose your fate: you continue.",
	},
	EXTRACT = {
		"A calculated extraction. You leave with guaranteed credits.",
		"The briefcase is closed. You take the money and walk.",
	},
	FINAL_OFFER = {
		"Two vaults remain. Your Claim, and the Final. This is your last safe exit.",
	},
	FINAL_SWAP = {
		"Do you trust your initial instinct, or do you trade fate at the finish line?",
	},
	FINAL_REVEAL = {
		"Lights down. Let us see what you held from the very beginning...",
	},
}

function CuratorService.getDialogue(category: string): string
	local pool = DIALOGUE[category]
	if pool and #pool > 0 then
		return pool[math.random(1, #pool)]
	end
	return "..."
end

return CuratorService
