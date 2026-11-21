local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local blowEvent = Instance.new("RemoteEvent")
blowEvent.Name = "BlowBubble"
blowEvent.Parent = remotes

local syncBubbleEvent = Instance.new("RemoteEvent")
syncBubbleEvent.Name = "SyncBubble"
syncBubbleEvent.Parent = remotes

local sellBubblesEvent = Instance.new("RemoteEvent")
sellBubblesEvent.Name = "SellBubbles"
sellBubblesEvent.Parent = remotes

local shopActionEvent = Instance.new("RemoteEvent")
shopActionEvent.Name = "ShopAction"
shopActionEvent.Parent = remotes

-- {Id, Name, Price, Power, MaxBubble, Color}
local GUMS = {
	{Id = 1, Name = "Mint", Price = 0, Power = 1, MaxBubble = 25, Color = Color3.fromRGB(255, 110, 180)},
	{Id = 2, Name = "Berry", Price = 50, Power = 4, MaxBubble = 80, Color = Color3.fromRGB(255, 60, 80)},
	{Id = 3, Name = "Lime", Price = 250, Power = 12, MaxBubble = 220, Color = Color3.fromRGB(80, 230, 90)},
	{Id = 4, Name = "Galaxy", Price = 1000, Power = 35, MaxBubble = 600, Color = Color3.fromRGB(145, 70, 255)},
	{Id = 5, Name = "Gold", Price = 5000, Power = 120, MaxBubble = 2000, Color = Color3.fromRGB(255, 210, 40)},
}

-- Уровни платформ в небе: {Name, Height, Size, Color, OffsetX, OffsetZ}
local SKY_LEVELS = {
	{Name = "Level 1: Clouds", Height = 45, Size = Vector3.new(26, 3, 26), Color = Color3.fromRGB(235, 245, 255), OffsetX = 0, OffsetZ = 25},
	{Name = "Level 2: Berry Sky", Height = 110, Size = Vector3.new(24, 3, 24), Color = Color3.fromRGB(255, 165, 180), OffsetX = 18, OffsetZ = 45},
	{Name = "Level 3: Mint Float", Height = 200, Size = Vector3.new(22, 3, 22), Color = Color3.fromRGB(150, 245, 185), OffsetX = -16, OffsetZ = 65},
	{Name = "Level 4: Violet Drift", Height = 320, Size = Vector3.new(20, 3, 20), Color = Color3.fromRGB(185, 145, 255), OffsetX = 14, OffsetZ = 85},
	{Name = "Level 5: Golden Peak", Height = 470, Size = Vector3.new(24, 4, 24), Color = Color3.fromRGB(255, 215, 95), OffsetX = 0, OffsetZ = 105},
}

local function getGumById(id)
	for _, g in ipairs(GUMS) do
		if g.Id == id then return g end
	end
	return GUMS[1]
end

local function getCurrentGum(player)
	local level = player:GetAttribute("GumLevel") or 1
	return getGumById(level), level
end

local function hasGum(player, gumId)
	if gumId == 1 then return true end
	local owned = player:GetAttribute("OwnedGums") or "1"
	for token in string.gmatch(owned, "[^,]+") do
		if tonumber(token) == gumId then
			return true
		end
	end
	return false
end

local function addOwnedGum(player, gumId)
	if hasGum(player, gumId) then return end
	local owned = player:GetAttribute("OwnedGums") or "1"
	player:SetAttribute("OwnedGums", owned .. "," .. tostring(gumId))
end

local sellCooldown = {}
local function doSellBubbles(player)
	if sellCooldown[player.UserId] then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local bubbles = leaderstats.Bubbles
	if bubbles.Value > 0 then
		sellCooldown[player.UserId] = true
		leaderstats.Coins.Value += bubbles.Value
		bubbles.Value = 0
		task.wait(0.25)
		sellCooldown[player.UserId] = nil
	end
end

-- Создаём или настраиваем полноценную зону продажи в мире
local function setupSellZone()
	local sellZone = workspace:FindFirstChild("SellZone")
	if not sellZone then
		sellZone = Instance.new("Part")
		sellZone.Name = "SellZone"
		sellZone.Shape = Enum.PartType.Cylinder
		sellZone.Size = Vector3.new(1.5, 16, 16)
		sellZone.Orientation = Vector3.new(0, 0, 90)
		sellZone.Position = Vector3.new(-22, 0.75, 0)
		sellZone.Parent = workspace
	end

	sellZone.Anchored = true
	sellZone.CanCollide = false
	sellZone.Material = Enum.Material.Neon
	sellZone.Color = Color3.fromRGB(45, 215, 115)
	sellZone.Transparency = 0.25

	if not sellZone:FindFirstChild("SellLabel") then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "SellLabel"
		billboard.Size = UDim2.fromOffset(170, 44)
		billboard.StudsOffset = Vector3.new(0, 6, 0)
		billboard.AlwaysOnTop = false
		billboard.MaxDistance = 90
		billboard.Parent = sellZone

		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundColor3 = Color3.fromRGB(20, 32, 26)
		text.BackgroundTransparency = 0.2
		text.TextColor3 = Color3.fromRGB(130, 255, 175)
		text.Font = Enum.Font.GothamBold
		text.TextSize = 15
		text.Text = "SELL BUBBLES"
		text.Parent = billboard
	end

	sellZone.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			doSellBubbles(player)
		end
	end)
end

-- Создаём уровни платформ в небе
local function setupSkyPlatforms()
	local oldFolder = workspace:FindFirstChild("SkyPlatforms")
	if oldFolder then
		oldFolder:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "SkyPlatforms"
	folder.Parent = workspace

	for _, lvl in ipairs(SKY_LEVELS) do
		local platform = Instance.new("Part")
		platform.Name = lvl.Name
		platform.Anchored = true
		platform.CanCollide = true
		platform.Material = Enum.Material.SmoothPlastic
		platform.Color = lvl.Color
		platform.Size = lvl.Size
		platform.Position = Vector3.new(lvl.OffsetX, lvl.Height, lvl.OffsetZ)
		platform.Parent = folder

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(180, 38)
		billboard.StudsOffset = Vector3.new(0, 4.5, 0)
		billboard.MaxDistance = 160
		billboard.Parent = platform

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
		label.BackgroundTransparency = 0.25
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.Text = string.format("%s (%d studs)", lvl.Name, lvl.Height)
		label.Parent = billboard
	end
end

setupSellZone()
setupSkyPlatforms()

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	local bubbles = Instance.new("IntValue")
	bubbles.Name = "Bubbles"
	bubbles.Value = 0
	bubbles.Parent = leaderstats

	player:SetAttribute("GumLevel", 1)
	player:SetAttribute("GumName", GUMS[1].Name)
	player:SetAttribute("OwnedGums", "1")

	bubbles.Changed:Connect(function(newVal)
		local gum = getCurrentGum(player)
		syncBubbleEvent:FireAllClients(player, newVal, gum.Color)
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		local gum = getCurrentGum(player)
		syncBubbleEvent:FireAllClients(player, bubbles.Value, gum.Color)
	end)
end)

-- Надувание пузыря
blowEvent.OnServerEvent:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local bubbles = leaderstats.Bubbles
	local gum = getCurrentGum(player)

	if bubbles.Value < gum.MaxBubble then
		bubbles.Value = math.min(bubbles.Value + gum.Power, gum.MaxBubble)
	end
end)

-- Продажа пузырей по кнопке из UI
sellBubblesEvent.OnServerEvent:Connect(function(player)
	doSellBubbles(player)
end)

-- Покупка или экипировка жвачки
shopActionEvent.OnServerEvent:Connect(function(player, gumId)
	if type(gumId) ~= "number" then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local gum = getGumById(gumId)

	if hasGum(player, gum.Id) then
		player:SetAttribute("GumLevel", gum.Id)
		player:SetAttribute("GumName", gum.Name)
		if leaderstats.Bubbles.Value > gum.MaxBubble then
			leaderstats.Bubbles.Value = gum.MaxBubble
		end
		return
	end

	if leaderstats.Coins.Value >= gum.Price then
		leaderstats.Coins.Value -= gum.Price
		addOwnedGum(player, gum.Id)
		player:SetAttribute("GumLevel", gum.Id)
		player:SetAttribute("GumName", gum.Name)
		if leaderstats.Bubbles.Value > gum.MaxBubble then
			leaderstats.Bubbles.Value = gum.MaxBubble
		end
	end
end)