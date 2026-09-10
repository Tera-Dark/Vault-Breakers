--!nonstrict
-- Player-instance ownership + a unique lock per load, not just per server.
-- Retired async callbacks operate on their captured entry and cannot erase a reconnect.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Schema = require(ReplicatedStorage.VaultBreakers.Shared.ProfileSchema)
local Decisions = require(script.Parent.DecisionService)
local Progression=require(ReplicatedStorage.VaultBreakers.Shared.ProgressionRules)
local Catalog=require(ReplicatedStorage.VaultBreakers.Config.CosmeticCatalog)
local Service = { entries = {}, onChanged = function() end, closing = false }
local store
pcall(function() store = DataStoreService:GetDataStore("VaultBreakers_UserData_v1") end)
local serverId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
local LOCK_TTL = 180
local closeEntry
local function writable(entry)
	return entry.status == "READY" or entry.status == "SAVE_DELAYED"
end
local function isCurrent(entry)
	return Service.entries[entry.owner.UserId] == entry and entry.owner.Parent == Players and not entry.leaving
end
local function changed(entry)
	if isCurrent(entry) then Service.onChanged(entry.owner) end
end
local function forget(userId, entry)
	entry.closed = true
	if Service.entries[userId] == entry then Service.entries[userId] = nil end
end
function Service.get(player)
	local entry = Service.entries[player.UserId]
	return if entry and entry.owner == player and not entry.closed then entry else nil
end
function Service.public(player)
	local entry = Service.get(player)
	if not entry then return { status = "LOADING" } end
	local data = Schema.copy(entry.data)
	data.status = entry.status
	return data
end

function Service.save(userId, release, expectedEntry)
	local entry = expectedEntry or Service.entries[userId]
	if not entry or entry.closed or not writable(entry) or entry.saving then return false end
	entry.saving = true
	local copy = Schema.copy(entry.data)
	local previousStatus, lostLock = entry.status, false
	local ok, failure = pcall(function()
		return store:UpdateAsync("User_" .. userId, function(old)
			if type(old) ~= "table" or type(old.session) ~= "table" or old.session.id ~= entry.lockId then
				lostLock = true
				return nil
			end
			local updated = table.clone(old) -- preserve legacy / unknown root fields
			updated.profile = copy
			updated.session = if release then nil else { id = entry.lockId, time = os.time() }
			return updated
		end)
	end)
	entry.saving = false
	if lostLock then
		entry.status = "SESSION_ONLY"
		warn("[Vault] Session lock lost; stopped saving user " .. userId)
	elseif not ok then
		entry.status = "SAVE_DELAYED"
		warn("[Vault] Save failed for " .. userId .. ": " .. tostring(failure))
	else entry.status = "READY" end
	if previousStatus ~= entry.status then changed(entry) end
	-- A leave worker may have timed out while this request was in flight.
	if entry.leaving and not entry.closing and not release then task.defer(closeEntry, userId, entry) end
	return ok and not lostLock
end

closeEntry = function(userId, entry)
	entry.leaving = true
	if entry.loading or entry.closing or entry.closed then return end
	entry.closing = true
	local deadline = os.clock() + 20
	while entry.saving and os.clock() < deadline do task.wait(0.1) end
	if entry.saving then
		entry.closing = false -- the in-flight save schedules another close when it finishes
		return
	end
	for attempt = 1, 3 do
		if Service.save(userId, true, entry) or not writable(entry) then break end
		task.wait(attempt)
	end
	forget(userId, entry)
end

function Service.load(player)
	if Service.closing or player.Parent ~= Players then return end
	local previous = Service.entries[player.UserId]
	if previous and previous.owner == player then return end
	local entry = {
		owner = player, lockId = serverId .. ":" .. HttpService:GenerateGUID(false),
		data = Schema.normalize(nil), status = "LOADING", revision = 0,
		loading = true, saving = false, leaving = false, closed = false, settled={},
	}
	Service.entries[player.UserId] = entry
	if previous then
		previous.leaving = true
		task.spawn(closeEntry, player.UserId, previous)
		-- Give the former connection a bounded opportunity to finish its write/release.
		local deadline = os.clock() + 8
		while not previous.closed and isCurrent(entry) and os.clock() < deadline do task.wait(0.1) end
	end
	local loaded, failure
	for attempt = 1, 2 do
		if not isCurrent(entry) or Service.closing then break end
		if not store then failure = "experience is not published / DataStore unavailable"; break end
		local blocked,unsupported = false,false
		local ok, result = pcall(function()
			return store:UpdateAsync("User_" .. player.UserId, function(old)
				if not isCurrent(entry) or Service.closing then return nil end
				old = if type(old) == "table" then old else {}
				if not Schema.supported(old)then unsupported=true;return nil end
				local lock = old.session
				if type(lock) == "table" and lock.id ~= entry.lockId and type(lock.time) == "number" and os.time() - lock.time < LOCK_TTL then
					blocked = true
					return nil
				end
				local updated = table.clone(old)
				updated.profile = Schema.normalize(old)
				updated.session = { id = entry.lockId, time = os.time() }
				return updated
			end)
		end)
		if ok and result and not blocked and not unsupported then loaded = result; break end
		failure = if unsupported then "unsupported/newer profile version; no writes" elseif blocked then "profile is active in another server" else tostring(result)
		if attempt < 2 and isCurrent(entry) then task.wait(1) end
	end
	entry.loading = false
	if loaded then entry.data, entry.status = Schema.normalize(loaded), "READY"
	else
		entry.status = "SESSION_ONLY"
		if isCurrent(entry) then warn("[Vault] Persistent data unavailable; session-only play, no writes: " .. tostring(failure)) end
	end
	if not isCurrent(entry) or Service.closing then closeEntry(player.UserId, entry); return end
	changed(entry)
end

function Service.record(player, result, isMain)
	local entry = Service.get(player)
	if not entry or not isCurrent(entry) or entry.loading or Service.closing then return end
	if result.arenaId and result.runId then
		if (entry.settled[result.arenaId]or 0)>=result.runId then return nil end
		entry.settled[result.arenaId]=result.runId
	end
	local data = entry.data
	data.credits += result.credits
	data.totalEarnings += result.credits
	data.runs += 1
	if isMain then data.mainAppearances += 1 end
	if result.extracted then data.bestExtract = math.max(data.bestExtract, result.baseCredits)
	else data.bestFinal = math.max(data.bestFinal, result.baseCredits) end
	local gain = Decisions.apply(data, result.decisions)
	result.unlockedTitles=Progression.apply(data,result)
	entry.revision += 1
	changed(entry)
	return gain
end
function Service.style(player,operation,id)
	local entry=Service.get(player)
	if not entry or not isCurrent(entry)or entry.loading or Service.closing then return false,"profile_wait"end
	if type(id)~="string"or #id>24 then return false,"invalid_action"end
	local data=entry.data
	if operation=="BUY_STYLE"then
		local item=Catalog.ITEMS[id]
		if not item then return false,"invalid_action"end
		if data.ownedCosmetics[id]then return true,"style_owned"end
		if not writable(entry)then return false,"style_requires_save"end
		if data.credits<item.price then return false,"style_funds"end
		-- No yields between validation, debit and unlock. Duplicate purchases are no-ops.
		data.credits-=item.price;data.ownedCosmetics[id]=true
	elseif operation=="EQUIP_STYLE"then
		if not data.ownedCosmetics[id]then return false,"style_locked"end
		data.equippedCosmetic=id
	elseif operation=="EQUIP_TITLE"then
		if id~=""and not data.achievements[id]then return false,"style_locked"end
		data.equippedTitle=id
	else return false,"invalid_action"end
	entry.revision+=1;changed(entry)
	return true,if operation=="BUY_STYLE"then"style_unlocked"else"style_equipped"
end
function Service.remove(player)
	local entry = Service.get(player)
	if entry then closeEntry(player.UserId, entry) end
end
function Service.init()
	Players.PlayerAdded:Connect(function(player) task.spawn(Service.load, player) end)
	Players.PlayerRemoving:Connect(function(player) task.spawn(Service.remove, player) end)
	for _, player in Players:GetPlayers() do task.spawn(Service.load, player) end
	task.spawn(function()
		while not Service.closing do
			task.wait(60)
			if Service.closing then break end
			for userId, entry in Service.entries do
				if not entry.leaving then task.spawn(Service.save, userId, false, entry) end
			end
		end
	end)
	game:BindToClose(function()
		Service.closing = true
		local pending = 0
		for userId, entry in Service.entries do
			pending += 1
			task.spawn(function()
				closeEntry(userId, entry)
				local deadline = os.clock() + 24
				while not entry.closed and os.clock() < deadline do task.wait(0.1) end
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do task.wait(0.1) end
	end)
end
return Service
