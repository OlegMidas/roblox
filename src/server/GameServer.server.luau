--!strict
-- Bubble Gum Simulator - authoritative server gameplay and persistence.
-- Keep all currency, bubble, and ownership changes on the server.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local DATASTORE_NAME = "BubbleGumSim_Save_v1"
local AUTOSAVE_INTERVAL = 120
local BLOW_COOLDOWN = 0.08
local SELL_COOLDOWN = 0.5
local SHOP_COOLDOWN = 0.25
local WORLD_COOLDOWN = 1
local REBIRTH_COOLDOWN = 2

local WORLDS = {
	[1] = {Name = "Grassland", Cost = 0, RequiredLevel = 1, CoinMultiplier = 1, XPMultiplier = 1},
	[2] = {Name = "Frozen World", Cost = 5000, RequiredLevel = 5, CoinMultiplier = 1.5, XPMultiplier = 1.25},
	[3] = {Name = "Candy World", Cost = 50000, RequiredLevel = 12, CoinMultiplier = 2.5, XPMultiplier = 1.6},
	[4] = {Name = "Galaxy World", Cost = 500000, RequiredLevel = 20, CoinMultiplier = 4, XPMultiplier = 2.2},
}
local REBIRTH_REQUIRED_LEVEL = 20
local REBIRTH_REQUIRED_COINS = 250000

local function xpRequired(level: number): number
	return 100 + math.max(0, level - 1) * 75
end

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
	XP = 0,
	PlayerLevel = 1,
	Rebirths = 0,
	UnlockedWorlds = { [1] = true },
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
local worldActionEvent = getOrCreateRemote("WorldAction")
local rebirthActionEvent = getOrCreateRemote("RebirthAction")
local toastEvent = getOrCreateRemote("Toast")

local function notifyPlayer(player: Player, title: string, message: string, color: Color3?)
	toastEvent:FireClient(player, title, message, color or Color3.fromRGB(100, 210, 255))
end

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
	if type(raw.XP) == "number" and raw.XP >= 0 and raw.XP < 1e12 then
		clean.XP = math.floor(raw.XP)
	end
	if type(raw.PlayerLevel) == "number" then
		clean.PlayerLevel = math.clamp(math.floor(raw.PlayerLevel), 1, 1000)
	end
	if type(raw.Rebirths) == "number" and raw.Rebirths >= 0 then
		clean.Rebirths = math.clamp(math.floor(raw.Rebirths), 0, 10000)
	end
	if type(raw.UnlockedWorlds) == "table" then
		for key, unlocked in pairs(raw.UnlockedWorlds) do
			local worldId = tonumber(key)
			if unlocked == true and worldId and WORLDS[worldId] then
				clean.UnlockedWorlds[worldId] = true
			end
		end
	end
	clean.UnlockedWorlds[1] = true

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
	player:SetAttribute("PlayerLevel", data.PlayerLevel)
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("XPToNext", xpRequired(data.PlayerLevel))
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("CoinMultiplier", (1 + data.Rebirths * 0.5) * (WORLDS[player:GetAttribute("CurrentWorldId") or 1] or WORLDS[1]).CoinMultiplier)
	player:SetAttribute("UnlockedWorlds", formatOwnedGums(data.UnlockedWorlds))

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local coins = stats:FindFirstChild("Coins")
		local bubbles = stats:FindFirstChild("Bubbles")
		local level = stats:FindFirstChild("Level")
		local rebirths = stats:FindFirstChild("Rebirths")
		if coins and coins:IsA("IntValue") then coins.Value = data.Coins end
		if bubbles and bubbles:IsA("IntValue") then bubbles.Value = data.BubbleSize end
		if level and level:IsA("IntValue") then level.Value = data.PlayerLevel end
		if rebirths and rebirths:IsA("IntValue") then rebirths.Value = data.Rebirths end
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

local function awardXP(player: Player, amount: number)
	local data = sessionData[player]
	if not data or amount <= 0 then return end
	local previousLevel = data.PlayerLevel
	data.XP += math.floor(amount)
	while data.PlayerLevel < 1000 do
		local needed = xpRequired(data.PlayerLevel)
		if data.XP < needed then break end
		data.XP -= needed
		data.PlayerLevel += 1
	end
	syncPlayerState(player)
	if data.PlayerLevel > previousLevel then
		notifyPlayer(player, "LEVEL UP!", "You reached level " .. tostring(data.PlayerLevel), Color3.fromRGB(105, 235, 155))
	end
end

local function getWorldMultiplier(player: Player): number
	local worldId = player:GetAttribute("CurrentWorldId") or 1
	local world = WORLDS[worldId] or WORLDS[1]
	return world.CoinMultiplier * (1 + (sessionData[player] and sessionData[player].Rebirths or 0) * 0.5)
end

local function inflateBubble(player: Player)
	local data = sessionData[player]
	if not data then return end

	local gum = getGum(data)
	if data.BubbleSize >= gum.MaxBubble then return end

	data.BubbleSize = math.min(gum.MaxBubble, data.BubbleSize + gum.Power)
	syncPlayerState(player)
	local worldId = player:GetAttribute("CurrentWorldId") or 1
	local world = WORLDS[worldId] or WORLDS[1]
	awardXP(player, math.max(1, math.floor(gum.Power * 0.5 * world.XPMultiplier)))
end

local function sellBubble(player: Player)
	local data = sessionData[player]
	if not data or data.BubbleSize <= 0 then return end

	local gum = getGum(data)
	local reward = math.floor(data.BubbleSize * gum.SellMultiplier * getWorldMultiplier(player))
	if reward <= 0 then return end

	data.Coins += reward
	notifyPlayer(player, "BUBBLES SOLD!", "+" .. tostring(reward) .. " Coins", Color3.fromRGB(105, 235, 155))
	local soldSize = data.BubbleSize
	data.BubbleSize = 0
	syncPlayerState(player)
	local worldId = player:GetAttribute("CurrentWorldId") or 1
	local world = WORLDS[worldId] or WORLDS[1]
	awardXP(player, math.max(5, math.floor(soldSize * 0.35 * world.XPMultiplier)))
end

local function isPlayerAtShop(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end

	for _, zone in CollectionService:GetTagged("GumShopZone") do
		if zone:IsA("BasePart") and zone:IsDescendantOf(workspace) then
			local position = zone.CFrame:PointToObjectSpace(root.Position)
			local half = zone.Size * 0.5
			if math.abs(position.X) <= half.X + 2
				and math.abs(position.Z) <= half.Z + 2
				and math.abs(position.Y) <= half.Y then
				return true
			end
		end
	end
	return false
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
	notifyPlayer(player, "GUM UPGRADED!", gum.Name .. " equipped • +" .. tostring(gum.Power) .. " power", gum.Color)
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

local function getWorldSpawn(worldId: number): BasePart?
	local worldFolder = workspace:FindFirstChild("BubbleWorld")
	if not worldFolder then return nil end
	for _, descendant in ipairs(worldFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "WorldSpawn_" .. tostring(worldId) and descendant:GetAttribute("WorldId") == worldId then
			return descendant
		end
	end
	return nil
end

local function teleportToWorld(player: Player, worldId: number)
	local spawn = getWorldSpawn(worldId)
	local character = player.Character
	if not spawn or not character then return end
	character:PivotTo(spawn.CFrame + Vector3.new(0, 5, 0))
	player:SetAttribute("CurrentWorldId", worldId)
	syncPlayerState(player)
end

local function handleWorldPrompt(player: Player, prompt: ProximityPrompt)
	if not canPerform(player, "World", WORLD_COOLDOWN) then return end
	local portal = prompt.Parent
	if not portal or not portal:IsA("BasePart") then return end
	local targetId = portal:GetAttribute("TargetWorldId")
	if type(targetId) ~= "number" or not WORLDS[targetId] then return end
	local data = sessionData[player]
	if not data then return end

	if not data.UnlockedWorlds[targetId] then
		local world = WORLDS[targetId]
		if targetId ~= 1 and not data.UnlockedWorlds[targetId - 1] then return end
		if data.PlayerLevel < world.RequiredLevel or data.Coins < world.Cost then return end
		data.Coins -= world.Cost
		data.UnlockedWorlds[targetId] = true
		syncPlayerState(player)
		notifyPlayer(player, "WORLD UNLOCKED!", "Welcome to " .. world.Name .. "!", Color3.fromRGB(115, 205, 255))
	end

	teleportToWorld(player, targetId)
end

local function bindWorldPrompt(instance: Instance)
	if not instance:IsA("ProximityPrompt") or instance.Name ~= "WorldPrompt" then return end
	if instance:GetAttribute("ServerBound") then return end
	instance:SetAttribute("ServerBound", true)
	instance.Triggered:Connect(function(player)
		handleWorldPrompt(player, instance)
	end)
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	bindWorldPrompt(descendant)
end
workspace.DescendantAdded:Connect(bindWorldPrompt)

worldActionEvent.OnServerEvent:Connect(function(player, worldIdRaw)
	if not canPerform(player, "World", WORLD_COOLDOWN) then return end
	local worldId = tonumber(worldIdRaw)
	if not worldId or worldId % 1 ~= 0 or not WORLDS[worldId] then return end
	local data = sessionData[player]
	if not data or not getWorldSpawn(worldId) then return end

	if not data.UnlockedWorlds[worldId] then
		local world = WORLDS[worldId]
		if worldId <= 1 or not data.UnlockedWorlds[worldId - 1] then return end
		if data.PlayerLevel < world.RequiredLevel or data.Coins < world.Cost then return end
		data.Coins -= world.Cost
		data.UnlockedWorlds[worldId] = true
		syncPlayerState(player)
		notifyPlayer(player, "WORLD UNLOCKED!", "Welcome to " .. world.Name .. "!", Color3.fromRGB(115, 205, 255))
	end

	teleportToWorld(player, worldId)
end)

rebirthActionEvent.OnServerEvent:Connect(function(player)
	if not canPerform(player, "Rebirth", REBIRTH_COOLDOWN) then return end
	local data = sessionData[player]
	if not data or data.PlayerLevel < REBIRTH_REQUIRED_LEVEL or data.Coins < REBIRTH_REQUIRED_COINS then return end

	data.Rebirths += 1
	data.Coins = 0
	data.BubbleSize = 0
	data.GumLevel = 1
	data.OwnedGums = { [1] = true }
	data.XP = 0
	data.PlayerLevel = 1
	syncPlayerState(player)
	notifyPlayer(player, "REBIRTH COMPLETE!", "Permanent coin multiplier increased!", Color3.fromRGB(210, 135, 255))
end)

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

for _, descendant in ipairs(workspace:GetDescendants()) do
	if descendant.Name == "SellZone" then hookSellZone(descendant) end
end
workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "SellZone" then hookSellZone(descendant) end
end)

local function createLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	for _, statName in ipairs({"Level", "Coins", "Bubbles", "Rebirths"}) do
		local value = Instance.new("IntValue")
		value.Name = statName
		value.Parent = stats
	end
end

local function onPlayerAdded(player: Player)
	createLeaderstats(player)

	local data, loadedSuccessfully = loadPlayerData(player)
	sessionData[player] = data
	player:SetAttribute("CurrentWorldId", 1)
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
