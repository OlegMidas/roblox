--!strict
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("TopStatsHUD")
if previous then previous:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TopStatsHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 5
gui.Parent = playerGui

local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Size = UDim2.new(1, -24, 0, 48)
bar.Position = UDim2.new(0.5, 0, 0, 10)
bar.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
bar.BackgroundTransparency = 0.08
bar.BorderSizePixel = 0
bar.Parent = gui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(280, 48)
sizeLimit.MaxSize = Vector2.new(520, 48)
sizeLimit.Parent = bar

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = bar

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 100, 130)
stroke.Transparency = 0.55
stroke.Thickness = 1
stroke.Parent = bar

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = bar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar

local function makeStat(name: string, color: Color3, order: number)
	local holder = Instance.new("Frame")
	holder.Name = name .. "Stat"
	holder.LayoutOrder = order
	holder.Size = UDim2.new(1/3, -4, 1, -8)
	holder.BackgroundColor3 = Color3.fromRGB(38, 42, 56)
	holder.BackgroundTransparency = 0.15
	holder.BorderSizePixel = 0
	holder.Parent = bar

	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 10)
	holderCorner.Parent = holder

	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = name .. ": 0"
	label.Parent = holder

	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MinTextSize = 10
	textLimit.MaxTextSize = 15
	textLimit.Parent = label
	return label
end

local coinsLabel = makeStat("COINS", Color3.fromRGB(255, 215, 90), 1)
local bubblesLabel = makeStat("BUBBLES", Color3.fromRGB(120, 215, 255), 2)
local gumLabel = makeStat("GUM", Color3.fromRGB(255, 145, 205), 3)

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
	local gumLevel = player:GetAttribute("GumLevel") or 1

	coinsLabel.Text = "🪙 " .. compactNumber(coins)
	bubblesLabel.Text = "🫧 " .. compactNumber(bubbleSize) .. "/" .. compactNumber(maxBubble)
	gumLabel.Text = "GUM " .. tostring(gumLevel)
end

for _, attribute in ipairs({"Coins", "BubbleSize", "MaxBubble", "GumLevel"}) do
	player:GetAttributeChangedSignal(attribute):Connect(updateHUD)
end

updateHUD()
