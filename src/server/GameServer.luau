local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DATASTORE_NAME = "BubbleGumSim_Save_v1"
local AUTOSAVE_INTERVAL = 120

local dsOk, playerStore = pcall(function()
	return DataStoreService:GetDataStore(DATASTORE_NAME)
end)

if not dsOk then
	warn("[GameServer] DataStore недоступен (опубликуй плейс и включи API Services). Режим без сохранения.")
	playerStore = nil
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
}

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = remotesFolder
	return ev
end

local blowEvent = getOrCreateRemote("BlowBubble")
local syncBubbleEvent = getOrCreateRemote("SyncBubble")
local sellBubblesEvent = getOrCreateRemote("SellBubbles")
local shopActionEvent = getOrCreateRemote("ShopAction")

local sessionData = {}
local lastBlowTime = {}
local sellCooldown = {}

local function deepCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function formatOwnedGumsString(ownedMap)
	local list = {}
	for id = 1, #GUMS_BY_ID do
		if ownedMap[id] then
			table.insert(list, tostring(id))
		end
	end
	return #list > 0 and table.concat(list, ",") or "1"
end

local function sanitizeData(raw)
	local clean = deepCopy(DEFAULT_DATA)
	if type(raw) ~= "table" then
		return clean
	end
	if type(raw.Coins) == "number" and raw.Coins >= 0 then
		clean.Coins = math.floor(raw.Coins)
	end
	if type(raw.BubbleSize) == "number" and raw.BubbleSize >= 0 then
		clean.BubbleSize = math.floor(raw.BubbleSize)
	end
	if type(raw.OwnedGums) == "table" then
		for k, owned in pairs(raw.OwnedGums) do
			local numId = tonumber(k)
			if owned == true and numId and GUMS_BY_ID[numId] then
				clean.OwnedGums[numId] = true
			end
		end
	end
	local lvl = tonumber(raw.GumLevel)
	if lvl and GUMS_BY_ID[lvl] and clean.OwnedGums[lvl] then
		clean.GumLevel = lvl
	end
	local gumCfg = GUMS_BY_ID[clean.GumLevel] or GUMS_BY_ID[1]
	if clean.BubbleSize > gumCfg.MaxBubble then
		clean.BubbleSize = gumCfg.MaxBubble
	end
	return clean
end

local function broadcastBubbleVisual(player)
	local data = sessionData[player]
	if not data then
		return
	end
	local gumCfg = GUMS_BY_ID[data.GumLevel] or GUMS_BY_ID[1]
	syncBubbleEvent:FireAllClients(player, data.BubbleSize, gumCfg.Color)
end

local function syncPlayerState(player)
	local data = sessionData[player]
	if not data then
		return
	end
	local gumCfg = GUMS_BY_ID[data.GumLevel] or GUMS_BY_ID[1]

	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("BubbleSize", data.BubbleSize)
	player:SetAttribute("MaxBubble", gumCfg.MaxBubble)
	player:SetAttribute("GumLevel", data.GumLevel)
	player:SetAttribute("OwnedGums", formatOwnedGumsString(data.OwnedGums))

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsStat = leaderstats:FindFirstChild("Coins")
		local bubblesStat = leaderstats:FindFirstChild("Bubbles")
		local levelStat = leaderstats:FindFirstChild("Level")
		if levelStat then
			levelStat.Value = data.GumLevel
		end
		if coinsStat then
			coinsStat.Value = data.Coins
		end
		if bubblesStat then
			bubblesStat.Value = data.BubbleSize
		end
	end

	broadcastBubbleVisual(player)
end

local function loadPlayerData(player)
	if not playerStore then
		return deepCopy(DEFAULT_DATA)
	end
	local key = "Player_" .. player.UserId
	local ok, result = pcall(function()
		return playerStore:GetAsync(key)
	end)
	if ok then
		return sanitizeData(result)
	end
	warn("[GameServer] Ошибка загрузки DataStore для " .. player.Name .. ": " .. tostring(result))
	return nil
end

local function savePlayerData(player)
	if not playerStore then
		return false
	end
	local data = sessionData[player]
	if not data then
		return false
	end
	local key = "Player_" .. player.UserId
	local ok, err = pcall(function()
		playerStore:SetAsync(key, data)
	end)
	if not ok then
		warn("[GameServer] Ошибка сохранения DataStore для " .. player.Name .. ": " .. tostring(err))
		return false
	end
	return true
end

local function inflateBubble(player)
	local data = sessionData[player]
	if not data then
		return
	end
	local gumCfg = GUMS_BY_ID[data.GumLevel] or GUMS_BY_ID[1]
	if data.BubbleSize >= gumCfg.MaxBubble then
		return
	end
	data.BubbleSize = math.min(gumCfg.MaxBubble, data.BubbleSize + gumCfg.Power)
	syncPlayerState(player)
end

local function sellBubble(player)
	local data = sessionData[player]
	if not data or data.BubbleSize <= 0 then
		return
	end
	local gumCfg = GUMS_BY_ID[data.GumLevel] or GUMS_BY_ID[1]
	data.Coins += math.floor(data.BubbleSize * gumCfg.SellMultiplier)
	data.BubbleSize = 0
	syncPlayerState(player)
end

local function handleShopAction(player, gumIdRaw)
	local data = sessionData[player]
	if not data then
		return
	end
	local gumId = tonumber(gumIdRaw)
	local cfg = gumId and GUMS_BY_ID[gumId]
	if not cfg then
		return
	end
	if data.OwnedGums[gumId] then
		data.GumLevel = gumId
		if data.BubbleSize > cfg.MaxBubble then
			data.BubbleSize = cfg.MaxBubble
		end
		syncPlayerState(player)
		return
	end
	if data.Coins < cfg.Price then
		return
	end
	data.Coins -= cfg.Price
	data.OwnedGums[gumId] = true
	data.GumLevel = gumId
	if data.BubbleSize > cfg.MaxBubble then
		data.BubbleSize = cfg.MaxBubble
	end
	syncPlayerState(player)
end

blowEvent.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if lastBlowTime[player] and (now - lastBlowTime[player]) < 0.06 then
		return
	end
	lastBlowTime[player] = now
	inflateBubble(player)
end)

sellBubblesEvent.OnServerEvent:Connect(function(player)
	sellBubble(player)
end)

shopActionEvent.OnServerEvent:Connect(function(player, gumId)
	handleShopAction(player, gumId)
end)

local function hookSellZone(part)
	if not part or not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		local char = hit and hit.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if not player then
			return
		end
		local now = os.clock()
		if sellCooldown[player] and (now - sellCooldown[player]) < 0.4 then
			return
		end
		sellCooldown[player] = now
		sellBubble(player)
	end)
end

local sellZone = workspace:FindFirstChild("SellZone")
if sellZone then
	hookSellZone(sellZone)
end
workspace.ChildAdded:Connect(function(child)
	if child.Name == "SellZone" then
		hookSellZone(child)
	end
end)

Players.PlayerAdded:Connect(function(player)
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local levelValue = Instance.new("IntValue")
	levelValue.Name = "Level"
	levelValue.Value = 1
	levelValue.Parent = leaderstats
	
	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = 0
	coinsValue.Parent = leaderstats

	local bubblesValue = Instance.new("IntValue")
	bubblesValue.Name = "Bubbles"
	bubblesValue.Value = 0
	bubblesValue.Parent = leaderstats

	local loaded = loadPlayerData(player)
	if loaded then
		sessionData[player] = loaded
	else
		sessionData[player] = deepCopy(DEFAULT_DATA)
		player:SetAttribute("DataLoadFailed", true)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		broadcastBubbleVisual(player)
	end)

	syncPlayerState(player)
end)

Players.PlayerRemoving:Connect(function(player)
	if not player:GetAttribute("DataLoadFailed") then
		savePlayerData(player)
	end
	sessionData[player] = nil
	lastBlowTime[player] = nil
	sellCooldown[player] = nil
end)

game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(1)
	end
	for player in pairs(sessionData) do
		if not player:GetAttribute("DataLoadFailed") then
			savePlayerData(player)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player in pairs(sessionData) do
			if not player:GetAttribute("DataLoadFailed") then
				savePlayerData(player)
			end
		end
	end
end)