--!strict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.VaultBreakers.Network.Remotes)

local PlayerDataService = {}

export type PlayerData = {
	cash: number,
	careerEarnings: number,
	careerWins: number,
	careerMatches: number,
	inventory: { [string]: number },
	hasPass: boolean,
}

local playerDataCache: { [number]: PlayerData } = {}
local dataStore: GlobalDataStore? = nil

pcall(function()
	dataStore = DataStoreService:GetDataStore("VaultBreakers_UserData_v1")
end)

local DEFAULT_DATA: PlayerData = {
	cash = 100000,
	careerEarnings = 0,
	careerWins = 0,
	careerMatches = 0,
	inventory = {
		["PEEK_CARD"] = 3,
		["EXTEND_TIME"] = 2,
		["INSURANCE"] = 1,
	},
	hasPass = false,
}

local SHOP_CATALOG = {
	["VIP_PASS"] = { price = 88000, itemType = "PASS", name = "第三季 VIP 黄金通行证" },
	["VAULT_SKIN"] = { price = 50000, itemType = "SKIN", name = "黑曜石镀金防盗门皮肤" },
	["TACTICAL_PACK"] = { price = 30000, itemType = "BUNDLE", name = "挑战者战术急救礼包" },
}

function PlayerDataService.init()
	Players.PlayerAdded:Connect(function(player: Player)
		PlayerDataService.loadData(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		PlayerDataService.saveData(player)
		playerDataCache[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerDataService.loadData, player)
	end

	-- Handle Shop Purchases
	Remotes.getEvent("BuyShopItem").OnServerEvent:Connect(function(player: Player, itemId: any)
		if typeof(itemId) ~= "string" then return end
		local catalogItem = SHOP_CATALOG[itemId]
		if not catalogItem then
			Remotes.getEvent("ShopPurchaseResult"):FireClient(player, false, "商品不存在", 0)
			return
		end

		local data = PlayerDataService.getData(player.UserId)
		if data.cash < catalogItem.price then
			Remotes.getEvent("ShopPurchaseResult"):FireClient(player, false, "筹码不足", data.cash)
			return
		end

		data.cash -= catalogItem.price
		if itemId == "VIP_PASS" then
			data.hasPass = true
		elseif itemId == "TACTICAL_PACK" then
			data.inventory["PEEK_CARD"] = (data.inventory["PEEK_CARD"] or 0) + 3
			data.inventory["EXTEND_TIME"] = (data.inventory["EXTEND_TIME"] or 0) + 2
			data.inventory["INSURANCE"] = (data.inventory["INSURANCE"] or 0) + 1
		else
			data.inventory[itemId] = (data.inventory[itemId] or 0) + 1
		end

		PlayerDataService.syncClient(player)
		Remotes.getEvent("ShopPurchaseResult"):FireClient(player, true, "购买成功: " .. catalogItem.name, data.cash)
		print(string.format("[PlayerDataService] Player %s purchased %s for ¥%d", player.Name, catalogItem.name, catalogItem.price))
	end)

	print("[PlayerDataService] Initialized with Shop & Inventory support.")
end

function PlayerDataService.loadData(player: Player): PlayerData
	local userId = player.UserId
	local loadedData: PlayerData = table.clone(DEFAULT_DATA)
	loadedData.inventory = table.clone(DEFAULT_DATA.inventory)

	if dataStore then
		local success, saved = pcall(function()
			return dataStore:GetAsync("User_" .. userId)
		end)
		if success and saved and typeof(saved) == "table" then
			for k, v in pairs(saved) do
				(loadedData :: any)[k] = v
			end
		end
	end

	playerDataCache[userId] = loadedData
	PlayerDataService.syncClient(player)
	return loadedData
end

function PlayerDataService.saveData(player: Player)
	local userId = player.UserId
	local data = playerDataCache[userId]
	if not data or not dataStore then return end

	pcall(function()
		dataStore:SetAsync("User_" .. userId, data)
	end)
end

function PlayerDataService.getData(userId: number): PlayerData
	if not playerDataCache[userId] then
		playerDataCache[userId] = table.clone(DEFAULT_DATA)
		playerDataCache[userId].inventory = table.clone(DEFAULT_DATA.inventory)
	end
	return playerDataCache[userId]
end

function PlayerDataService.addEarnings(player: Player, earnings: number)
	local data = PlayerDataService.getData(player.UserId)
	data.cash += earnings
	data.careerMatches += 1
	if earnings > 0 then
		data.careerWins += 1
	end
	if earnings > data.careerEarnings then
		data.careerEarnings = earnings
	end
	PlayerDataService.syncClient(player)
	PlayerDataService.saveData(player)
end

function PlayerDataService.syncClient(player: Player)
	local data = PlayerDataService.getData(player.UserId)
	Remotes.getEvent("PlayerDataSync"):FireClient(player, data)
end

return PlayerDataService
