--!strict
-- Современный HUD: верхняя панель со статистикой, прогресс-бар пузыря и индикатор мира.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("TopStatsHUD")
if previous then previous:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TopStatsHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = playerGui

-- ── Верхняя панель ──
local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Size = UDim2.new(1, -24, 0, 58)
bar.Position = UDim2.new(0.5, 0, 0, 10)
bar.BackgroundColor3 = Color3.fromRGB(43, 30, 69)
bar.BackgroundTransparency = 0.05
bar.BorderSizePixel = 0
bar.Parent = gui
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(270, 58)
sizeLimit.MaxSize = Vector2.new(640, 58)
sizeLimit.Parent = bar
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 16)
local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(190, 149, 255)
barStroke.Transparency = 0.25
barStroke.Thickness = 1.5
barStroke.Parent = bar
local barGrad = Instance.new("UIGradient")
barGrad.Rotation = 90
barGrad.Color = ColorSequence.new(Color3.fromRGB(75, 47, 115), Color3.fromRGB(40, 26, 65))
barGrad.Parent = bar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingBottom = UDim.new(0, 6)
pad.Parent = bar

-- ── Фабрика чипов статистики ──
local function makeChip(name: string, icon: string, accent: Color3, order: number)
	local chip = Instance.new("Frame")
	chip.Name = name .. "Chip"
	chip.LayoutOrder = order
	chip.Size = UDim2.new(0.32, -6, 1, 0)
	chip.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
	chip.BackgroundTransparency = 0.2
	chip.BorderSizePixel = 0
	chip.Parent = bar
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 12)
	local chipStroke = Instance.new("UIStroke")
	chipStroke.Color = accent
	chipStroke.Transparency = 0.65
	chipStroke.Thickness = 1.5
	chipStroke.Parent = chip

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.AnchorPoint = Vector2.new(0, 0.5)
	iconLabel.Position = UDim2.new(0, 8, 0.5, 0)
	iconLabel.Size = UDim2.new(0, 26, 0, 26)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.FredokaOne
	iconLabel.TextSize = 18
	iconLabel.Text = icon
	iconLabel.TextColor3 = accent
	iconLabel.Parent = chip

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.Position = UDim2.new(1, -10, 0.5, 0)
	value.Size = UDim2.new(1, -48, 0, 20)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.FredokaOne
	value.TextScaled = true
	local valueLimit = Instance.new("UITextSizeConstraint")
	valueLimit.MaxTextSize = 16
	valueLimit.Parent = value
	value.Text = "0"
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.TextColor3 = Color3.fromRGB(240, 243, 250)
	value.Parent = chip
	return chip, value
end

local _, coinsValue = makeChip("Coins", "🪙", Color3.fromRGB(255, 215, 90), 1)
local bubbleChip, bubblesValue = makeChip("Bubbles", "🫧", Color3.fromRGB(120, 215, 255), 2)
local _, gumValue = makeChip("Gum", "🍬", Color3.fromRGB(255, 145, 205), 3)

-- Мини-прогрессбар внутри чипа пузыря
local progressBack = Instance.new("Frame")
progressBack.Name = "ProgressBack"
progressBack.AnchorPoint = Vector2.new(1, 0)
progressBack.Position = UDim2.new(1, -10, 1, -10)
progressBack.Size = UDim2.new(1, -48, 0, 4)
progressBack.BackgroundColor3 = Color3.fromRGB(20, 22, 31)
progressBack.BorderSizePixel = 0
progressBack.Parent = bubbleChip
Instance.new("UICorner", progressBack).CornerRadius = UDim.new(1, 0)
local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.BackgroundColor3 = Color3.fromRGB(120, 215, 255)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBack
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

-- ── Индикатор текущего мира ──
local worldChip = Instance.new("Frame")
worldChip.Name = "WorldChip"
worldChip.AnchorPoint = Vector2.new(0.5, 0)
worldChip.Position = UDim2.new(0.5, 0, 0, 74)
worldChip.Size = UDim2.new(0, 200, 0, 30)
worldChip.BackgroundColor3 = Color3.fromRGB(43, 30, 69)
worldChip.BackgroundTransparency = 0.1
worldChip.BorderSizePixel = 0
worldChip.Parent = gui
Instance.new("UICorner", worldChip).CornerRadius = UDim.new(0, 10)
local worldStroke = Instance.new("UIStroke")
worldStroke.Color = Color3.fromRGB(120, 215, 255)
worldStroke.Transparency = 0.7
worldStroke.Thickness = 1.2
worldStroke.Parent = worldChip
local worldLabel = Instance.new("TextLabel")
worldLabel.Size = UDim2.fromScale(1, 1)
worldLabel.BackgroundTransparency = 1
worldLabel.Font = Enum.Font.FredokaOne
worldLabel.TextSize = 13
worldLabel.TextColor3 = Color3.fromRGB(200, 230, 255)
worldLabel.Text = "🌍 Grassland"
worldLabel.Parent = worldChip

-- ── Логика обновления ──
local function compactNumber(value: number): string
	if value >= 1e9 then return string.format("%.1fB", value / 1e9) end
	if value >= 1e6 then return string.format("%.1fM", value / 1e6) end
	if value >= 1e3 then return string.format("%.1fK", value / 1e3) end
	return tostring(math.floor(value))
end

local function updateHUD()
	local coins = player:GetAttribute("Coins") or 0
	local bubbleSize = player:GetAttribute("BubbleSize") or 0
	local maxBubble = player:GetAttribute("MaxBubble") or 25
	local gumName = player:GetAttribute("GumName") or config.Gums[1].Name
	local worldId = player:GetAttribute("CurrentWorldId") or 1

	coinsValue.Text = compactNumber(coins)
	bubblesValue.Text = compactNumber(bubbleSize) .. " / " .. compactNumber(maxBubble)
	gumValue.Text = gumName

	local ratio = if maxBubble > 0 then math.clamp(bubbleSize / maxBubble, 0, 1) else 0
	progressFill.Size = UDim2.fromScale(ratio, 1)
	local nearFull = ratio >= 0.9
	progressFill.BackgroundColor3 = nearFull and Color3.fromRGB(255, 125, 125) or Color3.fromRGB(120, 215, 255)
	bubblesValue.TextColor3 = nearFull and Color3.fromRGB(255, 125, 125) or Color3.fromRGB(240, 243, 250)

	worldLabel.Text = "📍 " .. config.Worlds[worldId].Name
end

for _, attribute in ipairs({"Coins", "BubbleSize", "MaxBubble", "GumName", "CurrentWorldId"}) do
	player:GetAttributeChangedSignal(attribute):Connect(updateHUD)
end
updateHUD()
