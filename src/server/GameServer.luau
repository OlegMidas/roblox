--!strict
-- Bubble Gum Simulator - authoritative server gameplay and persistence.
-- Keep all currency, bubble, and ownership changes on the server.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DATASTORE_NAME = "BubbleGumSim_Save_v1"
local AUTOSAVE_INTERVAL = 120
local BLOW_COOLDOWN = 0.08
local SELL_COOLDOWN = 0.5
local SHOP_COOLDOWN = 0.25

local GUMS_BY_ID = {
	[1] = { Id = 1, Name = "Mint", Price = 0, Power = 1, MaxBubble = 25, SellMultiplier = 1, Color = Color3.fromRGB(255, 110, 180) },
	[2] = { Id = 2, Name = "Berry", Price = 50, Power = 4, MaxBubble = 80, SellMultiplier = 1.5, Color = Color3.fromRGB(255, 60, 80) },
	[3] = { Id = 3, Name = "Lime", Price = 250, Power = 12, MaxBubble = 220, SellMultiplier = 2.5, Color = Color3.fromRGB(80, 230, 90) },
	[4] = { Id = 4, Name = "Galaxy", Price = 1000, Power = 35, MaxBubble = 600, SellMultiplier = 4, Color = Color3.fromRGB(145, 70, 255) },
	[5] = { Id = 5, Name = "Gold", Price = 5000, Power = 120, MaxBubble = 2000, SellMultiplier = 7, Color = Color3.fromRGB(255, 210, 40) },
}

local DEFAULT_DATA = {
	Coins = 0,
	BubbleSize = 0,
	GumLevel = 1,
	OwnedGums = { [1] = true },
}

local playerStore
local storeOk, storeResult = pcall(function()
	return DataStoreService:GetDataStore(DATASTORE_NAME)
end)
if storeOk then
	playerStore = storeResult
else
	warn("[GameServer] DataStore unavailable; progress will not persist:", storeResult)
end

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if remotesFolder and not remotesFolder:IsA("Folder") then
	remotesFolder:Destroy()
	remotesFolder = nil
end
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name: string): RemoteEvent
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local blowEvent = getOrCreateRemote("BlowBubble")
local syncBubbleEvent = getOrCreateRemote("SyncBubble")
local sellBubblesEvent = getOrCreateRemote("SellBubbles")
local shopActionEvent = getOrCreateRemote("ShopAction")

local sessionData: {[Player]: any} = {}
local lastActionAt: {[Player]: {[string]: number}} = {}
local saveInProgress: {[Player]: boolean} = {}

local function copyTable(source)
	local result = {}
	for key, value in pairs(source) do
		result[key] = if type(value) == "table" then copyTable(value) else value
	end
	return result
end

local function sanitizeData(raw)
	local clean = copyTable(DEFAULT_DATA)
	if type(raw) ~= "table" then
		return clean
	end

	if type(raw.Coins) == "number" and raw.Coins >= 0 and raw.Coins < 1e12 then
		clean.Coins = math.floor(raw.Coins)
	end
	if type(raw.BubbleSize) == "number" and raw.BubbleSize >= 0 and raw.BubbleSize < 1e9 then
		clean.BubbleSize = math.floor(raw.BubbleSize)
	end
	if type(raw.OwnedGums) == "table" then
		for key, owned in pairs(raw.OwnedGums) do
			local gumId = tonumber(key)
			if owned == true and gumId and GUMS_BY_ID[gumId] then
				clean.OwnedGums[gumId] = true
			end
		end
	end

	local level = tonumber(raw.GumLevel)
	if level and GUMS_BY_ID[level] and clean.OwnedGums[level] then
		clean.GumLevel = level
	end

	local equippedGum = GUMS_BY_ID[clean.GumLevel]
	clean.BubbleSize = math.min(clean.BubbleSize, equippedGum.MaxBubble)
	clean.OwnedGums[1] = true
	return clean
end

local function canPerform(player: Player, action: string, cooldown: number): boolean
	local now = os.clock()
	local actions = lastActionAt[player]
	if not actions then
		actions = {}
		lastActionAt[player] = actions
	end
	local previous = actions[action] or 0
	if now - previous < cooldown then
		return false
	end
	actions[action] = now
	return true
end

local function getGum(data)
	return GUMS_BY_ID[data.GumLevel] or GUMS_BY_ID[1]
end

local function formatOwnedGums(ownedMap): string
	local ids = {}
	for id in pairs(GUMS_BY_ID) do
		if ownedMap[id] then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	local strings = {}
	for _, id in ipairs(ids) do
		table.insert(strings, tostring(id))
	end
	return table.concat(strings, ",")
end

local function broadcastBubbleVisual(player: Player)
	local data = sessionData[player]
	if data then
		syncBubbleEvent:FireAllClients(player, data.BubbleSize, getGum(data).Color)
	end
end

local function syncPlayerState(player: Player)
	local data = sessionData[player]
	if not data then
		return
	end

	local gum = getGum(data)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("BubbleSize", data.BubbleSize)
	player:SetAttribute("MaxBubble", gum.MaxBubble)
	player:SetAttribute("GumLevel", data.GumLevel)
	player:SetAttribute("OwnedGums", formatOwnedGums(data.OwnedGums))

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local coins = stats:FindFirstChild("Coins")
		local bubbles = stats:FindFirstChild("Bubbles")
		local level = stats:FindFirstChild("Level")
		if coins and coins:IsA("IntValue") then coins.Value = data.Coins end
		if bubbles and bubbles:IsA("IntValue") then bubbles.Value = data.BubbleSize end
		if level and level:IsA("IntValue") then level.Value = data.GumLevel end
	end

	broadcastBubbleVisual(player)
end

local function loadPlayerData(player: Player)
	if not playerStore then
		return copyTable(DEFAULT_DATA), false
	end

	local key = "Player_" .. player.UserId
	local ok, result = pcall(function()
		return playerStore:GetAsync(key)
	end)
	if not ok then
		warn("[GameServer] Failed to load data for " .. player.Name .. ":", result)
		return copyTable(DEFAULT_DATA), false
	end
	return sanitizeData(result), true
end

local function savePlayerData(player: Player): boolean
	if not playerStore or not sessionData[player] or saveInProgress[player] then
		return false
	end

	saveInProgress[player] = true
	local snapshot = copyTable(sessionData[player])
	local key = "Player_" .. player.UserId
	local ok, err = pcall(function()
		playerStore:UpdateAsync(key, function()
			return snapshot
		end)
	end)
	saveInProgress[player] = nil

	if not ok then
		warn("[GameServer] Failed to save data for " .. player.Name .. ":", err)
	end
	return ok
end

local function inflateBubble(player: Player)
	local data = sessionData[player]
	if not data then return end

	local gum = getGum(data)
	if data.BubbleSize >= gum.MaxBubble then return end

	data.BubbleSize = math.min(gum.MaxBubble, data.BubbleSize + gum.Power)
	syncPlayerState(player)
end

local function sellBubble(player: Player)
	local data = sessionData[player]
	if not data or data.BubbleSize <= 0 then return end

	local gum = getGum(data)
	local reward = math.floor(data.BubbleSize * gum.SellMultiplier)
	if reward <= 0 then return end

	data.Coins += reward
	data.BubbleSize = 0
	syncPlayerState(player)
end

local function isPlayerAtShop(player: Player): boolean
	local zone = workspace:FindFirstChild("ShopZone")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not zone or not zone:IsA("BasePart") or not root then
		return false
	end

	local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
	local half = zone.Size * 0.5
	return math.abs(localPosition.X) <= half.X + 5
		and math.abs(localPosition.Z) <= half.Z + 5
		and math.abs(localPosition.Y) <= half.Y + 10
end

local function handleShopAction(player: Player, gumIdRaw)
	local data = sessionData[player]
	if not data or not canPerform(player, "Shop", SHOP_COOLDOWN) then return end
	if not isPlayerAtShop(player) then return end

	local gumId = tonumber(gumIdRaw)
	if not gumId or gumId % 1 ~= 0 then return end
	local gum = GUMS_BY_ID[gumId]
	if not gum then return end

	if data.OwnedGums[gumId] then
		data.GumLevel = gumId
	else
		if data.Coins < gum.Price then return end
		data.Coins -= gum.Price
		data.OwnedGums[gumId] = true
		data.GumLevel = gumId
	end

	data.BubbleSize = math.min(data.BubbleSize, gum.MaxBubble)
	syncPlayerState(player)
end

blowEvent.OnServerEvent:Connect(function(player)
	if canPerform(player, "Blow", BLOW_COOLDOWN) then
		inflateBubble(player)
	end
end)

sellBubblesEvent.OnServerEvent:Connect(function(player)
	if canPerform(player, "Sell", SELL_COOLDOWN) then
		sellBubble(player)
	end
end)

shopActionEvent.OnServerEvent:Connect(handleShopAction)

local function hookSellZone(instance: Instance)
	if not instance:IsA("BasePart") then return end
	instance.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and canPerform(player, "SellZone", SELL_COOLDOWN) then
			sellBubble(player)
		end
	end)
end

local sellZone = workspace:FindFirstChild("SellZone")
if sellZone then hookSellZone(sellZone) end
workspace.ChildAdded:Connect(function(child)
	if child.Name == "SellZone" then hookSellZone(child) end
end)

local function createLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	for _, statName in ipairs({"Level", "Coins", "Bubbles"}) do
		local value = Instance.new("IntValue")
		value.Name = statName
		value.Parent = stats
	end
end

local function onPlayerAdded(player: Player)
	createLeaderstats(player)

	local data, loadedSuccessfully = loadPlayerData(player)
	sessionData[player] = data
	if not loadedSuccessfully then
		player:SetAttribute("DataLoadFailed", true)
		player:SetAttribute("DataWarning", "Progress could not be loaded; this session will not overwrite saved data.")
	end

	player.CharacterAdded:Connect(function()
		task.delay(0.25, function()
			if player.Parent then
				broadcastBubbleVisual(player)
			end
		end)
	end)

	syncPlayerState(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	if not player:GetAttribute("DataLoadFailed") then
		savePlayerData(player)
	end
	sessionData[player] = nil
	lastActionAt[player] = nil
	saveInProgress[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player in pairs(sessionData) do
			if player.Parent and not player:GetAttribute("DataLoadFailed") then
				task.spawn(savePlayerData, player)
			end
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in pairs(sessionData) do
		if not player:GetAttribute("DataLoadFailed") then
			pending += 1
			task.spawn(function()
				savePlayerData(player)
				pending -= 1
			end)
		end
	end

	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
