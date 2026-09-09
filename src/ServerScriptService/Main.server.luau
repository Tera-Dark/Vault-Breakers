--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("VaultBreakers")
local Config = require(Shared.Config.GameConfig)
local Remotes = require(Shared.Network.Remotes)
local Engine = require(script.Parent.Core.RunEngine)
local Stage = require(script.Parent.Core.StageBuilder)
local Data = require(script.Parent.Services.PlayerDataService)
local Board = require(script.Parent.Services.LeaderboardService)
local Queue = require(script.Parent.Services.QueueService)
local RateLimiter = require(script.Parent.Services.RateLimiter)
local world = Stage.build()
local queue, limiter = Queue.new(), RateLimiter.new()
local engines, assignment, views, ready = {}, {}, {}, {}
local directoryDirty, directorySequence = true, 0
local shuttingDown = false
local clock = function() return Workspace:GetServerTimeNow() end
local dependencies = {
	config = Config, rewards = require(Shared.Config.RewardPool).VALUES,
	offers = require(Shared.Config.OfferAlgorithm), quality = require(Shared.Shared.DecisionQuality),
}
for _, definition in Config.ARENAS do engines[definition.id] = Engine.new(definition, dependencies) end

local function notice(player, key, arguments)
	if player.Parent == Players then Remotes.getEvent("Notice"):FireClient(player, key, arguments or {}) end
end
local function move(player, cf)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid then humanoid.Sit = false end
	if root then root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end
	character:PivotTo(cf)
end
local function sendSnapshot(player)
	local id = assignment[player.UserId] or views[player.UserId]
	if id and engines[id] then Remotes.getEvent("Snapshot"):FireClient(player, engines[id]:snapshot(player.UserId)) end
end
local function sendDirectory(player)
	local rows = {}
	for _, definition in Config.ARENAS do
		local engine = engines[definition.id]
		table.insert(rows, { id = definition.id, state = engine.state, name = engine.breakerName, round = engine.round, available = engine.state == "IDLE", runId = engine.runId, phaseId = engine.phaseId })
	end
	directorySequence += 1
	Remotes.getEvent("Directory"):FireClient(player, {
		sequence = directorySequence,
		arenas = rows, playerCount = #Players:GetPlayers(), board = Board.rows(),
		queuePosition = queue:position(player.UserId), queueCount = #queue.tickets,
		myArena = assignment[player.UserId], view = views[player.UserId] or "LOBBY",
	})
end

local flush
local function setView(player, id)
	local previous = views[player.UserId]
	views[player.UserId] = id
	if previous and previous ~= id and engines[previous] then
		engines[previous]:step(clock())
		engines[previous]:withdrawVote(player.UserId)
		flush(previous)
	end
end

flush = function(id)
	local engine, stage = engines[id], world.arenas[id]
	for _, event in engine:drainEvents() do
		stage:effect(event)
		if event.kind == "START" then
			local player = Players:GetPlayerByUserId(event.playerId)
			if player then
				assignment[player.UserId] = id
				setView(player, id)
				move(player, stage.spawn)
			end
		elseif event.kind == "SETTLE" then
			local player = Players:GetPlayerByUserId(event.result.breakerId)
			if player then
				local entry = Data.get(player)
				if entry and not entry.leaving then
					event.result.reputationGain = Data.record(player, event.result, id == "MAIN")
					event.result.nextHeat = entry.data.heat
					Board.record(player, event.result, Data.public(player))
				end
			end
		elseif event.kind == "RELEASE" then
			local player = if event.playerId then Players:GetPlayerByUserId(event.playerId) else nil
			if event.playerId then assignment[event.playerId] = nil; views[event.playerId] = "LOBBY" end
			if player then
				move(player, world.lobby.spawn)
				if event.reason ~= "complete" and event.reason ~= "player_left" then notice(player, "run_" .. event.reason) end
			end
		end
	end
	if engine.dirty then
		stage:update(engine:snapshot())
		for _, player in Players:GetPlayers() do
			if ready[player.UserId] and (assignment[player.UserId] or views[player.UserId]) == id then sendSnapshot(player) end
		end
		engine.dirty = false
		directoryDirty = true
	end
end

local function canStart(player)
	if shuttingDown or Data.closing or player.Parent ~= Players then return false end
	local entry = Data.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return entry and not entry.leaving and entry.status ~= "LOADING" and humanoid and humanoid.Health > 0
		and character:FindFirstChild("HumanoidRootPart") and not assignment[player.UserId]
end

local function drainQueue()
	if shuttingDown then return end
	for _, definition in Config.ARENAS do
		local engine = engines[definition.id]
		while engine.state == "IDLE" do
			local userId = queue:popFor(definition.id)
			if not userId then break end
			local player = Players:GetPlayerByUserId(userId)
			if player and canStart(player) then
				engine:start({ id = player.UserId, name = player.DisplayName, heat = Data.get(player).data.heat }, clock())
				flush(definition.id)
			elseif player then notice(player, "character_wait") end
		end
	end
end

local function play(player, target)
	if target ~= "AUTO" and not engines[target] then return end
	if not canStart(player) then notice(player, if assignment[player.UserId] then "already_playing" else "profile_wait"); return end
	queue:add(player.UserId, target)
	drainQueue()
	if queue:position(player.UserId) > 0 then notice(player, "queued") end
	directoryDirty = true
end
local function watch(player, id)
	if not engines[id] or assignment[player.UserId] then return end
	setView(player, id)
	sendDirectory(player)
	sendSnapshot(player)
end

local function inReach(player, part)
	if shuttingDown or Data.closing then return false end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return humanoid and humanoid.Health > 0 and root and (root.Position - part.Position).Magnitude <= 12.5
end
local function preparePhysical(id)
	local engine = engines[id]
	local previous = engine.phaseId
	engine:step(clock()); flush(id)
	return previous == engine.phaseId
end
for id, stage in world.arenas do
	local engine = engines[id]
	for vaultId, vault in stage.vaults do
		vault.prompt.Triggered:Connect(function(player)
			if not limiter:allow(player.UserId, clock()) or not inReach(player, vault.anchor) then return end
			if not preparePhysical(id) then return end
			if engine.state == "CLAIM" then engine:claim(player.UserId, vaultId, clock())
			else engine:breach(player.UserId, vaultId, clock()) end
			flush(id)
		end)
	end
	for index, button in stage.buttons do
		button.prompt.Triggered:Connect(function(player)
			if not limiter:allow(player.UserId, clock()) or not inReach(player, button.part) then return end
			if not preparePhysical(id) then return end
			if engine.state == "FINAL_CHOICE" then engine:chooseFinal(player.UserId, if index == 1 then "KEEP" else "SWAP", clock())
			else engine:decide(player.UserId, if index == 1 then "EXTRACT" else "PUSH", clock()) end
			flush(id)
		end)
	end
	stage.leverPrompt.Triggered:Connect(function(player)
		if not limiter:allow(player.UserId, clock()) or not inReach(player, stage.leverPrompt.Parent) then return end
		if not preparePhysical(id) then return end
		local ok, reason = engine:lifeline(player.UserId, clock())
		if not ok then notice(player, reason) end
		flush(id)
	end)
	local entry = world.lobby.entries[id]
	entry.prompt.Triggered:Connect(function(player)
		if not limiter:allow(player.UserId, clock()) or not inReach(player, entry.part) then return end
		if id == "MAIN" and engine.state ~= "IDLE" then watch(player, id) else play(player, id) end
	end)
end

Remotes.getEvent("Action").OnServerEvent:Connect(function(player, command, payload)
	if shuttingDown or type(command) ~= "string" or #command > 24 or not limiter:allow(player.UserId, clock()) then return end
	payload = if type(payload) == "table" then payload else {}
	if command == "SYNC" then
		ready[player.UserId] = true
		Remotes.getEvent("Profile"):FireClient(player, Data.public(player))
		sendDirectory(player)
		sendSnapshot(player)
	elseif command == "PLAY" then play(player, payload.target or "AUTO")
	elseif command == "WATCH" then watch(player, payload.target)
	elseif command == "CANCEL_QUEUE" then queue:remove(player.UserId); directoryDirty = true
	elseif command == "LOBBY" then
		if not assignment[player.UserId] then setView(player, "LOBBY"); sendDirectory(player) end
	else
		local id = assignment[player.UserId] or views[player.UserId]
		local engine = id and engines[id]
		if engine then engine:step(clock()); flush(id) end
		if not engine or payload.arenaId ~= id or not engine:matches(payload.runId, payload.phaseId) then
			notice(player, "stale_action"); sendSnapshot(player); return
		end
		local ok, reason = false, "invalid_action"
		if command == "DECIDE" then
			ok, reason = engine:decide(player.UserId, payload.choice, clock())
		elseif command == "FINAL" then
			ok, reason = engine:chooseFinal(player.UserId, payload.choice, clock())
		elseif command == "VOTE" then
			if not assignment[player.UserId] then ok, reason = engine:vote(player.UserId, payload.choice, clock()) end
		elseif command == "LEAVE_RUN" or command == "REPLAY" then
			if engine.breakerId == player.UserId and (command ~= "REPLAY" or engine.state == "RESULT") then
				ok = true
				engine:release(clock(), if engine.state == "RESULT" then "complete" else "cancelled")
				flush(id)
				drainQueue() -- existing tickets always precede a replay
				if command == "REPLAY" then play(player, "AUTO") end
			end
		end
		if not ok then notice(player, reason) end
		flush(id)
	end
end)

Data.onChanged = function(player)
	Board.update(player, Data.public(player))
	if ready[player.UserId] then Remotes.getEvent("Profile"):FireClient(player, Data.public(player)) end
	directoryDirty = true
end
Data.init()

local characterConnections = {}
local function disconnectCharacter(player)
	local connection = characterConnections[player]
	if connection then connection:Disconnect(); characterConnections[player] = nil end
end
local function characterLeft(player, character)
	if player.Character ~= character then return end
	local id = assignment[player.UserId]
	if id then engines[id]:release(clock(), "character_lost"); flush(id) end
end
local function onPlayer(player)
	views[player.UserId] = "LOBBY"
	player.RespawnLocation = world.lobby.spawnLocation
	local function characterAdded(character)
		disconnectCharacter(player)
		local id = assignment[player.UserId]
		if id then engines[id]:release(clock(), "respawned"); flush(id) end
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if not humanoid or player.Character ~= character or player.Parent ~= Players then return end
			characterConnections[player] = humanoid.Died:Connect(function() characterLeft(player, character) end)
			local root = character:WaitForChild("HumanoidRootPart", 10)
			if root and player.Character == character and player.Parent == Players then
				local active = assignment[player.UserId]
				move(player, if active then world.arenas[active].spawn else world.lobby.spawn)
			end
		end)
	end
	player.CharacterAdded:Connect(characterAdded)
	player.CharacterRemoving:Connect(function(character) characterLeft(player, character); disconnectCharacter(player) end)
	if player.Character then characterAdded(player.Character) end
	directoryDirty = true
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do onPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
	disconnectCharacter(player)
	queue:remove(player.UserId)
	for id, engine in engines do engine:playerLeft(player.UserId, clock()); flush(id) end
	assignment[player.UserId], views[player.UserId], ready[player.UserId] = nil, nil, nil
	limiter:forget(player.UserId)
	directoryDirty = true
end)

local elapsed, refresh = 0, 0
RunService.Heartbeat:Connect(function(dt)
	if shuttingDown then return end
	elapsed += dt; refresh += dt
	if elapsed < Config.NETWORK_INTERVAL then return end
	elapsed = 0
	for id, engine in engines do engine:step(clock()); flush(id) end
	drainQueue()
	if directoryDirty or refresh > 2 then
		for id, entry in world.lobby.entries do
			local engine = engines[id]
			entry.label.Text = entry.title .. "\n" .. (if engine.state == "IDLE" then "AVAILABLE / ENTER" else "ON AIR / " .. engine.breakerName)
			entry.prompt.ActionText = if id == "MAIN" and engine.state ~= "IDLE" then "WATCH / 观赛" else "PLAY / 参赛"
		end
		for _, player in Players:GetPlayers() do if ready[player.UserId] then sendDirectory(player) end end
		directoryDirty, refresh = false, 0
	end
end)
game:BindToClose(function() shuttingDown = true end)
print("[Vault Breakers] Two independent studios ready. Credits are virtual; polls are free.")
