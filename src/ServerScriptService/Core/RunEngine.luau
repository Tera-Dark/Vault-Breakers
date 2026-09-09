--!strict
-- Deterministic, server-authoritative match state machine. No Instances, remotes or tasks.
-- The adapter supplies time/randomness and drains effects; old timers cannot mutate a new run.
local RunEngine = {}
RunEngine.__index = RunEngine

type AnyMap = { [string]: any }

function RunEngine.new(arena: AnyMap, dependencies: AnyMap): any
	local self: any = setmetatable({}, RunEngine)
	self.config = dependencies.config
	self.rewards = dependencies.rewards
	self.offers = dependencies.offers
	self.quality = dependencies.quality
	self.random = dependencies.random or math.random
	self.arena = arena
	self.runId, self.phaseId, self.revision = 0, 0, 0
	self.state, self.breakerName = "IDLE", ""
	self.breakerId, self.claimId = nil, nil
	self.round, self.breached, self.offer, self.ev = 0, 0, 0, 0
	self.deadline, self.heat = 0, 1
	self.vaults, self.decisions, self.votes, self.events = {}, {}, {}, {}
	self.lifelineUsed, self.dirty = false, true
	return self
end

function RunEngine._emit(self: any, kind: string, data: AnyMap?)
	local event = data or {}
	event.kind = kind
	event.runId = self.runId
	table.insert(self.events, event)
	self.dirty = true
	self.revision += 1
end

function RunEngine._state(self: any, state: string, now: number, seconds: number?)
	self.state = state
	self.phaseId += 1
	self.deadline = if seconds then now + seconds else 0
	self:_emit("STATE", { state = state })
end

function RunEngine.drainEvents(self: any): { AnyMap }
	local result = self.events
	self.events = {}
	return result
end

function RunEngine._remaining(self: any): { number }
	local values = {}
	for _, vault in self.vaults do
		if not vault.opened then table.insert(values, vault.value) end
	end
	table.sort(values)
	return values
end

function RunEngine.matches(self: any, runId: any, phaseId: any): boolean
	return type(runId) == "number" and type(phaseId) == "number"
		and self.runId == runId and self.phaseId == phaseId
end

function RunEngine.start(self: any, player: AnyMap, now: number): (boolean, string?)
	if self.state ~= "IDLE" then return false, "arena_busy" end
	self.runId += 1
	self.breakerId, self.breakerName = player.id, player.name
	self.heat = math.clamp(player.heat or 1, 1, 2) -- locked for this entire run
	self.claimId, self.result, self.lastBreach, self.finalId = nil, nil, nil, nil
	self.lifelineUsed, self.consensus, self.automatic = false, nil, false
	self.votes, self.decisions, self.vaults = {}, {}, {}
	self.round, self.breached, self.offer, self.ev = 0, 0, 0, 0
	local pool = table.clone(self.rewards)
	assert(#pool == self.config.TOTAL_VAULTS, "Reward count must match vault count")
	for index = #pool, 2, -1 do
		local other = self.random(1, index)
		pool[index], pool[other] = pool[other], pool[index]
	end
	for index, value in pool do
		table.insert(self.vaults, { id = index, value = value, opened = false, claimed = false })
	end
	self:_emit("START", { playerId = player.id })
	self:_state("CLAIM", now, self.config.CLAIM_SECONDS)
	return true
end

function RunEngine._validVault(self: any, id: any): boolean
	return type(id) == "number" and id == math.floor(id) and id >= 1 and id <= #self.vaults
end

-- Input receipt never extends an already expired phase. Heartbeat is not a lock:
-- an input callback can run before the next server tick at the same deadline.
function RunEngine._inputExpired(self: any, now: number): boolean
	if self.deadline > 0 and now >= self.deadline then self:step(now); return true end
	return false
end

function RunEngine.claim(self: any, playerId: number, id: any, now: number): (boolean, string?)
	if playerId ~= self.breakerId or self.state ~= "CLAIM" then return false, "not_your_turn" end
	if self:_inputExpired(now) then return false, "stale_action" end
	if not self:_validVault(id) then return false, "invalid_vault" end
	self.claimId = id
	self.vaults[id].claimed = true
	self.round, self.breached = 1, 0
	self:_emit("CLAIM", { vaultId = id })
	self:_state("BREACH", now, self.config.BREACH_SECONDS)
	return true
end

function RunEngine.breach(self: any, playerId: number, id: any, now: number): (boolean, string?)
	if playerId ~= self.breakerId or self.state ~= "BREACH" then return false, "not_your_turn" end
	if self:_inputExpired(now) then return false, "stale_action" end
	if not self:_validVault(id) then return false, "invalid_vault" end
	local vault = self.vaults[id]
	if vault.claimed or vault.opened then return false, "vault_unavailable" end
	-- Lock input BEFORE any animation, withhold the reward until it finishes.
	self.pendingId = id
	self:_state("OPENING", now, self.config.VAULT_OPENING_DURATION)
	self:_emit("OPEN", { vaultId = id })
	return true
end

function RunEngine._presentOffer(self: any, now: number)
	self.offer, self.ev = self.offers.calculateOffer(self.round, self:_remaining(), self.random)
	self.votes, self.consensus, self.automatic = {}, nil, false
	self:_state("OFFER", now, self.config.PRESSURE_CLOCK_SECONDS)
	self:_emit("OFFER", { amount = self.offer })
end

function RunEngine._recordDecision(self: any, decision: string, automatic: boolean)
	local assessment = self.quality.evaluate(decision, self.offer, self.ev, self:_remaining(), automatic)
	table.insert(self.decisions, assessment)
end

function RunEngine.decide(self: any, playerId: number, decision: any, now: number, automatic: boolean?): (boolean, string?)
	if playerId ~= self.breakerId or self.state ~= "OFFER" then return false, "not_your_turn" end
	if not automatic and self:_inputExpired(now) then return false, "stale_action" end
	if decision ~= "EXTRACT" and decision ~= "PUSH" then return false, "invalid_action" end
	self.automatic = automatic == true
	self:_recordDecision(decision, self.automatic)
	self.votes = {}
	if decision == "EXTRACT" then
		self.extracted, self.baseCredits, self.choice = true, self.offer, nil
		self.chosenId = self.claimId
		self:_state("REVEAL", now, self.config.REVEAL_SECONDS)
		self:_emit("REVEAL", { vaultId = self.claimId, extracted = true })
	else
		self:_state("TRANSITION", now, self.config.TRANSITION_SECONDS)
	end
	return true
end

function RunEngine.chooseFinal(self: any, playerId: number, choice: any, now: number, automatic: boolean?): (boolean, string?)
	if playerId ~= self.breakerId or self.state ~= "FINAL_CHOICE" then return false, "not_your_turn" end
	if not automatic and self:_inputExpired(now) then return false, "stale_action" end
	if choice ~= "KEEP" and choice ~= "SWAP" then return false, "invalid_action" end
	assert(self.finalId, "Final phase must contain exactly one non-claim vault")
	self.choice, self.extracted, self.automatic = choice, false, automatic == true
	self.chosenId = if choice == "KEEP" then self.claimId else self.finalId
	self.baseCredits = self.vaults[self.chosenId].value
	self.votes = {}
	self:_state("REVEAL", now, self.config.REVEAL_SECONDS)
	self:_emit("REVEAL", { vaultId = self.chosenId, otherId = if choice == "KEEP" then self.finalId else self.claimId })
	return true
end

function RunEngine.canLifeline(self: any): boolean
	return self.arena.audience and self.state == "OFFER" and not self.lifelineUsed
		and self.round >= self.config.LIFELINE_FIRST_ROUND
end

function RunEngine.lifeline(self: any, playerId: number, now: number): (boolean, string?)
	if playerId ~= self.breakerId or not self:canLifeline() then return false, "lifeline_unavailable" end
	if self:_inputExpired(now) then return false, "stale_action" end
	self.lifelineUsed = true
	self.resumeSeconds = math.max(self.deadline - now, self.config.LIFELINE_MIN_RESUME_SECONDS)
	self.votes = {}
	self:_state("LIFELINE", now, self.config.LIFELINE_POLL_DURATION)
	self:_emit("LIFELINE")
	return true
end

function RunEngine.vote(self: any, playerId: number, choice: any, now: number): (boolean, string?)
	if not self.arena.audience or playerId == self.breakerId then return false, "spectators_only" end
	if self:_inputExpired(now) then return false, "poll_closed" end
	local isFinal = self.state == "FINAL_CHOICE"
	if not isFinal and self.state ~= "OFFER" and self.state ~= "LIFELINE" then return false, "poll_closed" end
	local valid = if isFinal then (choice == "KEEP" or choice == "SWAP") else (choice == "EXTRACT" or choice == "PUSH")
	if not valid then return false, "invalid_action" end
	if self.votes[playerId] == choice then return true end
	self.revision += 1
	self.votes[playerId] = choice -- one vote per real participant; switching does not add votes
	self.dirty = true
	return true
end

function RunEngine._poll(self: any, viewerId: number?): AnyMap
	local left, right = 0, 0
	for _, vote in self.votes do
		if vote == "EXTRACT" or vote == "KEEP" then left += 1 else right += 1 end
	end
	return {
		left = left, right = right, total = left + right,
		kind = if self.state == "FINAL_CHOICE" then "FINAL" else "OFFER",
		myVote = if viewerId then self.votes[viewerId] else nil,
	}
end

function RunEngine._settle(self: any, now: number)
	self.result = {
		breakerId = self.breakerId, breakerName = self.breakerName,
		extracted = self.extracted, baseCredits = self.baseCredits,
		credits = math.floor(self.baseCredits * self.heat + 0.5), heat = self.heat,
		claimValue = self.vaults[self.claimId].value,
		chosenValue = self.vaults[self.chosenId].value,
		otherValue = if self.finalId then self.vaults[if self.chosenId == self.claimId then self.finalId else self.claimId].value else nil,
		choice = self.choice, round = self.round, decisions = self.decisions,
	}
	self:_state("RESULT", now, self.config.RESULT_SECONDS)
	-- Exactly one settlement event; RESULT cannot be decided again.
	self:_emit("SETTLE", { result = self.result, chosenId = self.chosenId })
end

function RunEngine.release(self: any, now: number, reason: string?)
	local playerId = self.breakerId
	self:_emit("RELEASE", { playerId = playerId, reason = reason or "complete" })
	self.breakerId, self.breakerName, self.claimId, self.result = nil, "", nil, nil
	self.vaults, self.votes, self.decisions = {}, {}, {}
	self.round, self.breached, self.offer = 0, 0, 0
	self.lastBreach, self.consensus, self.finalId = nil, nil, nil
	self:_state("IDLE", now)
end

function RunEngine.withdrawVote(self: any, playerId: number): boolean
	if not self.votes[playerId] then return false end
	self.votes[playerId] = nil
	self.dirty = true
	self.revision += 1
	return true
end

function RunEngine.playerLeft(self: any, playerId: number, now: number)
	if self.breakerId == playerId then
		self:release(now, "player_left")
	else
		self:withdrawVote(playerId)
	end
end

function RunEngine.step(self: any, now: number)
	if self.deadline == 0 or now < self.deadline then return end
	if self.state == "CLAIM" or self.state == "BREACH" then
		self:release(now, "inactive") -- never let an AFK player occupy an arena forever
	elseif self.state == "OPENING" then
		local vault = self.vaults[self.pendingId]
		vault.opened = true
		self.breached += 1
		self.lastBreach = { id = vault.id, value = vault.value }
		self:_emit("BREACHED", { vaultId = vault.id, value = vault.value })
		if self.breached == self.config.ROUNDS[self.round].vaultsToBreach then
			assert(#self:_remaining() == self.config.ROUNDS[self.round].targetRemaining)
			self:_presentOffer(now)
		else
			self:_state("BREACH", now, self.config.BREACH_SECONDS)
		end
	elseif self.state == "OFFER" then
		self:decide(self.breakerId, "PUSH", now, true)
	elseif self.state == "TRANSITION" then
		if self.round < #self.config.ROUNDS then
			self.round += 1
			self.breached = 0
			self:_state("BREACH", now, self.config.BREACH_SECONDS)
		else
			local count = 0
			for _, vault in self.vaults do
				if not vault.opened and not vault.claimed then self.finalId = vault.id; count += 1 end
			end
			assert(count == 1 and #self:_remaining() == 2, "Invalid final board")
			self.votes = {}
			self:_state("FINAL_CHOICE", now, self.config.FINAL_CHOICE_SECONDS)
		end
	elseif self.state == "LIFELINE" then
		local poll = self:_poll()
		self.consensus = if poll.total == 0 then "NONE" elseif poll.left == poll.right then "TIE"
			elseif poll.left > poll.right then "EXTRACT" else "PUSH"
		self:_state("OFFER", now, self.resumeSeconds)
	elseif self.state == "FINAL_CHOICE" then
		self:chooseFinal(self.breakerId, "KEEP", now, true)
	elseif self.state == "REVEAL" then
		self:_settle(now)
	elseif self.state == "RESULT" then
		self:release(now)
	end
end

function RunEngine.snapshot(self: any, viewerId: number?): AnyMap
	local vaults = {}
	for _, vault in self.vaults do
		table.insert(vaults, {
			id = vault.id, claimed = vault.claimed, opened = vault.opened,
			-- Never replicate the mapping of unopened rewards, even during the reveal animation.
			value = if vault.opened or self.state == "RESULT" then vault.value else nil,
		})
	end
	return {
		arenaId = self.arena.id, runId = self.runId, phaseId = self.phaseId, revision = self.revision,
		state = self.state, breakerId = self.breakerId, breakerName = self.breakerName,
		round = self.round, claimId = self.claimId, breached = self.breached,
		quota = if self.round > 0 then self.config.ROUNDS[self.round].vaultsToBreach else 0,
		remaining = self:_remaining(), vaults = vaults, offer = self.offer,
		deadline = self.deadline, heat = self.heat, audience = self.arena.audience,
		lifelineAvailable = self:canLifeline(), lifelineUsed = self.lifelineUsed,
		poll = self:_poll(viewerId), consensus = self.consensus,
		lastBreach = self.lastBreach, result = self.result, finalId = self.finalId,
		automatic = self.automatic == true,
		revealId = if self.state == "REVEAL" or self.state == "RESULT" then self.chosenId else nil,
	}
end

return RunEngine
