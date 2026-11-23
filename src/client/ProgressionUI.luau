--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local worldAction = remotes:WaitForChild("WorldAction") :: RemoteEvent
local openRebirthShop = remotes:WaitForChild("OpenRebirthShop") :: RemoteEvent
local rebirthAction = remotes:WaitForChild("RebirthAction") :: RemoteEvent

local config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local old = playerGui:FindFirstChild("ProgressionGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ProgressionGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.Parent = playerGui

local surface = Color3.fromRGB(43, 30, 69)
local purple = Color3.fromRGB(139, 70, 219)
local turquoise = Color3.fromRGB(32, 164, 203)
local faded = Color3.fromRGB(70, 63, 88)
local worldIcons = {"🌿", "❄", "🍬", "✦"}

local function round(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function outline(item: GuiObject, color: Color3, width: number)
	local line = Instance.new("UIStroke")
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Color = color
	line.Thickness = width
	line.Parent = item
end

local function makeLabel(parent: Instance, name: string, size: UDim2, position: UDim2, text: string, textSize: number)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(245, 247, 255)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

-- Minimal XP widget on the left side, clear of the center gameplay view.
local xpPanel = Instance.new("Frame")
xpPanel.Name = "XPPanel"
xpPanel.AnchorPoint = Vector2.new(0, 0)
xpPanel.Position = UDim2.fromOffset(12, 110)
xpPanel.Size = UDim2.fromOffset(176, 58)
xpPanel.BackgroundColor3 = surface
xpPanel.BackgroundTransparency = 0.16
xpPanel.BorderSizePixel = 0
xpPanel.Parent = gui
round(xpPanel, 12)

local levelLabel = makeLabel(xpPanel, "LevelLabel", UDim2.new(0.55, -12, 0, 22), UDim2.fromOffset(12, 5), "LEVEL 1", 13)
local rebirthLabel = makeLabel(xpPanel, "RebirthLabel", UDim2.new(0.45, -12, 0, 22), UDim2.new(0.55, 0, 0, 5), "REBIRTH 0", 10)
rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right

local track = Instance.new("Frame")
track.Name = "XPTrack"
track.Position = UDim2.fromOffset(12, 34)
track.Size = UDim2.new(1, -24, 0, 13)
track.BackgroundColor3 = Color3.fromRGB(52, 58, 75)
track.BorderSizePixel = 0
track.Parent = xpPanel
round(track, 8)

local fill = Instance.new("Frame")
fill.Name = "XPFill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(95, 220, 145)
fill.BorderSizePixel = 0
fill.Parent = track
round(fill, 8)

local xpText = Instance.new("TextLabel")
xpText.Name = "XPText"
xpText.Size = UDim2.fromScale(1, 1)
xpText.BackgroundTransparency = 1
xpText.Text = "0 / " .. config.xpRequired(1) .. " XP"
xpText.TextColor3 = Color3.fromRGB(255, 255, 255)
xpText.TextStrokeTransparency = 0.65
xpText.Font = Enum.Font.FredokaOne
xpText.TextSize = 9
xpText.Parent = track

-- World selector.
local worldToggle = Instance.new("TextButton")
worldToggle.Name = "WorldToggle"
worldToggle.AnchorPoint = Vector2.new(1, 1)
worldToggle.Position = UDim2.new(1, -12, 0.49, 0)
worldToggle.Size = UDim2.fromOffset(77, 56)
worldToggle.BackgroundColor3 = Color3.fromRGB(62, 103, 190)
worldToggle.TextColor3 = Color3.new(1, 1, 1)
worldToggle.Font = Enum.Font.FredokaOne
worldToggle.TextSize = 13
worldToggle.Text = "🗺\nISLANDS"
worldToggle.Parent = gui
round(worldToggle, 13)
outline(worldToggle, turquoise, 3)

local worldPanel = Instance.new("Frame")
worldPanel.Name = "WorldPanel"
worldPanel.AnchorPoint = Vector2.new(0.5, 0.5)
worldPanel.Position = UDim2.fromScale(0.5, 0.5)
worldPanel.Size = UDim2.new(0.87, 0, 0, 266)
worldPanel.BackgroundColor3 = surface
worldPanel.BorderSizePixel = 0
worldPanel.Visible = false
worldPanel.Parent = gui
round(worldPanel, 18)
outline(worldPanel, turquoise, 3)
local worldLimit = Instance.new("UISizeConstraint")
worldLimit.MaxSize = Vector2.new(375, 266)
worldLimit.Parent = worldPanel

makeLabel(worldPanel, "Title", UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 4), "🗺  ISLANDS", 19)
local worldList = Instance.new("Frame")
worldList.Name = "WorldList"
worldList.Position = UDim2.fromOffset(10, 40)
worldList.Size = UDim2.new(1, -20, 1, -50)
worldList.BackgroundTransparency = 1
worldList.Parent = worldPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = worldList

local worldButtons = {}
for id, world in ipairs(config.Worlds) do
	local button = Instance.new("TextButton")
	button.Name = "World" .. tostring(id)
	button.Size = UDim2.new(1, 0, 0, 47)
	button.BackgroundColor3 = Color3.fromRGB(47, 53, 70)
	button.TextColor3 = Color3.fromRGB(245, 247, 255)
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 14
	button.Text = world.Name
	button.Parent = worldList
	round(button, 9)
	button.LayoutOrder = id
	button.Activated:Connect(function()
		if button.Interactable then
			worldAction:FireServer(id)
			worldPanel.Visible = false
		end
	end)
	worldButtons[id] = button
end

local function closeButton(panel: Frame)
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -8, 0, 7)
	close.Size = UDim2.fromOffset(32, 30)
	close.Text = "×"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.FredokaOne
	close.TextSize = 23
	close.BackgroundColor3 = faded
	close.Parent = panel
	round(close, 8)
	close.Activated:Connect(function() panel.Visible = false end)
end
closeButton(worldPanel)

local rebirthPanel = Instance.new("Frame")
rebirthPanel.Name = "RebirthShop"
rebirthPanel.AnchorPoint = Vector2.new(0.5, 0.5)
rebirthPanel.Position = UDim2.fromScale(0.5, 0.5)
rebirthPanel.Size = UDim2.new(0.88, 0, 0, 249)
rebirthPanel.BackgroundColor3 = surface
rebirthPanel.Visible = false
rebirthPanel.Parent = gui
round(rebirthPanel, 18)
outline(rebirthPanel, purple, 3)
local rebirthLimit = Instance.new("UISizeConstraint")
rebirthLimit.MaxSize = Vector2.new(385, 249)
rebirthLimit.Parent = rebirthPanel
makeLabel(rebirthPanel, "Title", UDim2.new(1, -53, 0, 40), UDim2.fromOffset(16, 3), "⟳  REBIRTH SHOP", 19)
closeButton(rebirthPanel)

local bonus = makeLabel(rebirthPanel, "Bonus", UDim2.new(1, -32, 0, 38), UDim2.fromOffset(16, 47),
	"+50% COINS PER REBIRTH", 19)
bonus.TextColor3 = Color3.fromRGB(247, 199, 255)
local requirements = makeLabel(rebirthPanel, "Requirements", UDim2.new(1, -32, 0, 41), UDim2.fromOffset(16, 94), "", 14)
local resetText = makeLabel(rebirthPanel, "Reset", UDim2.new(1, -32, 0, 42), UDim2.fromOffset(16, 140),
	"Resets coins, level, XP, bubbles and gums. Discovered islands stay open.", 13)
resetText.TextWrapped = true

local buy = Instance.new("TextButton")
buy.Name = "BuyRebirth"
buy.Position = UDim2.fromOffset(16, 192)
buy.Size = UDim2.new(1, -32, 0, 43)
buy.Font = Enum.Font.FredokaOne
buy.TextSize = 16
buy.TextColor3 = Color3.new(1, 1, 1)
buy.Parent = rebirthPanel
round(buy, 10)

local confirm = false
worldToggle.Activated:Connect(function()
	rebirthPanel.Visible = false
	worldPanel.Visible = not worldPanel.Visible
end)

local function update()
	local level = player:GetAttribute("PlayerLevel") or 1
	local xp = player:GetAttribute("XP") or 0
	local needed = player:GetAttribute("XPToNext") or config.xpRequired(1)
	local rebirths = player:GetAttribute("Rebirths") or 0
	local coins = player:GetAttribute("Coins") or 0
	local currentWorld = player:GetAttribute("CurrentWorldId") or 1

	levelLabel.Text = "LEVEL " .. tostring(level)
	rebirthLabel.Text = "⟳ " .. tostring(rebirths)
	xpText.Text = tostring(xp) .. " / " .. tostring(needed) .. " XP"
	fill.Size = UDim2.fromScale(math.clamp(xp / math.max(needed, 1), 0, 1), 1)

	local unlockedIds = player:GetAttribute("UnlockedWorlds")
	for id, world in ipairs(config.Worlds) do
		local button = worldButtons[id]
		if config.hasId(unlockedIds, id) then
			local here = currentWorld == id
			button.Text = worldIcons[id] .. "  " .. world.Name .. (here and "  •  Here" or "  →")
			button.BackgroundColor3 = here and Color3.fromRGB(45, 135, 90) or Color3.fromRGB(55, 105, 155)
			button.Interactable = not here
		else
			local routeGum = config.Worlds[id - 1].RouteGum
			button.Text = "🔒  " .. world.Name .. "\nClouds • " .. config.Gums[routeGum].Name .. " / " .. config.Gums[routeGum + 1].Name
			button.BackgroundColor3 = Color3.fromRGB(55, 58, 68)
			button.Interactable = false
		end
	end

	local ready = level >= config.RebirthLevel and coins >= config.RebirthCoins
	requirements.Text = ("Level %d / %d   •   🪙 %d / %d"):format(math.min(level, config.RebirthLevel), config.RebirthLevel, math.min(coins, config.RebirthCoins), config.RebirthCoins)
	if not ready then confirm = false end
	buy.Interactable = ready
	buy.BackgroundColor3 = if ready then purple else faded
	buy.Text = if not ready then "REQUIREMENTS INCOMPLETE" elseif confirm then "CONFIRM RESET" else "BUY REBIRTH"
end

buy.Activated:Connect(function()
	if not buy.Interactable then return end
	if confirm then
		confirm = false
		rebirthPanel.Visible = false
		rebirthAction:FireServer()
	else
		confirm = true
		update()
	end
end)

openRebirthShop.OnClientEvent:Connect(function()
	confirm = false
	worldPanel.Visible = false
	rebirthPanel.Visible = true
	update()
end)
player:GetAttributeChangedSignal("NearRebirthShop"):Connect(function()
	if not player:GetAttribute("NearRebirthShop") then rebirthPanel.Visible = false end
end)

local function updatePortals()
	local world = workspace:FindFirstChild("BubbleWorld")
	local grassland = world and world:FindFirstChild("World_1_Grassland")
	local hub = grassland and grassland:FindFirstChild("GrasslandHub")
	if not hub then return end
	local unlocked = player:GetAttribute("UnlockedWorlds")
	for id = 2, #config.Worlds do
		local gate = hub:FindFirstChild("Portal" .. id)
		if gate and gate:IsA("BasePart") then
			local open = config.hasId(unlocked, id)
			gate.Transparency = if open then 0.36 else 0.78
			local prompt = gate:FindFirstChildOfClass("ProximityPrompt")
			if prompt then prompt.ActionText = if open then "Travel" else "Visit to unlock" end
			local sign = gate:FindFirstChild("HubSign")
			local status = sign and sign:FindFirstChild("Status")
			if status and status:IsA("TextLabel") then status.Text = if open then "Ready to travel" else "🔒 Visit to unlock" end
		end
	end
end

workspace.DescendantAdded:Connect(function(instance)
	if instance.Name == "GrasslandHub" or instance.Name == "WorldPrompt" or instance.Name == "Status" then
		task.defer(updatePortals)
	end
end)
player:GetAttributeChangedSignal("UnlockedWorlds"):Connect(updatePortals)
for _, attribute in ipairs({"PlayerLevel", "XP", "XPToNext", "Rebirths", "Coins", "UnlockedWorlds", "CurrentWorldId"}) do
	player:GetAttributeChangedSignal(attribute):Connect(update)
end
updatePortals()
update()
