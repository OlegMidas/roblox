local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "TopStatsHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.Size = UDim2.fromOffset(430, 42)
bar.Position = UDim2.new(0.5, -215, 0, 12)
bar.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
bar.BackgroundTransparency = 0.15
bar.BorderSizePixel = 0
bar.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = bar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 18)
layout.Parent = bar

local function makeLabel(name, color)
	local lbl = Instance.new("TextLabel")
	lbl.Name = name
	lbl.Size = UDim2.fromOffset(125, 30)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextColor3 = color
	lbl.Text = name .. ": 0"
	lbl.Parent = bar
	return lbl
end

local coinsLbl = makeLabel("Coins", Color3.fromRGB(255, 215, 70))
local bubblesLbl = makeLabel("Bubbles", Color3.fromRGB(120, 210, 255))
local levelLbl = makeLabel("Level", Color3.fromRGB(255, 130, 190))

local function updateHUD()
	local coins = player:GetAttribute("Coins") or 0
	local bubbleSize = player:GetAttribute("BubbleSize") or 0
	local maxBubble = player:GetAttribute("MaxBubble") or 25
	local gumLevel = player:GetAttribute("GumLevel") or 1

	coinsLbl.Text = string.format("Coins: %d", coins)
	bubblesLbl.Text = string.format("Bubble: %d/%d", bubbleSize, maxBubble)
	levelLbl.Text = string.format("Gum Lv.%d", gumLevel)
end

for _, attr in ipairs({ "Coins", "BubbleSize", "MaxBubble", "GumLevel" }) do
	player:GetAttributeChangedSignal(attr):Connect(updateHUD)
end

updateHUD()