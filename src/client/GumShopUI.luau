--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shopActionEvent = remotes:WaitForChild("ShopAction") :: RemoteEvent
local sellBubblesEvent = remotes:WaitForChild("SellBubbles") :: RemoteEvent

local GUMS = {
	{Id = 1, Name = "Mint", Price = 0, Power = 1, MaxBubble = 25, Color = Color3.fromRGB(255, 110, 180)},
	{Id = 2, Name = "Berry", Price = 50, Power = 4, MaxBubble = 80, Color = Color3.fromRGB(255, 60, 80)},
	{Id = 3, Name = "Lime", Price = 250, Power = 12, MaxBubble = 220, Color = Color3.fromRGB(80, 230, 90)},
	{Id = 4, Name = "Galaxy", Price = 1000, Power = 35, MaxBubble = 600, Color = Color3.fromRGB(145, 70, 255)},
	{Id = 5, Name = "Gold", Price = 5000, Power = 120, MaxBubble = 2000, Color = Color3.fromRGB(255, 210, 40)},
}

local oldGui = playerGui:FindFirstChild("GumShopGui")
if oldGui then oldGui:Destroy() end

local function hasGumLocal(gumId: number): boolean
	if gumId == 1 then return true end
	local owned = player:GetAttribute("OwnedGums") or "1"
	for token in string.gmatch(owned, "[^,]+") do
		if tonumber(token) == gumId then return true end
	end
	return false
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GumShopGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

local sellButton = Instance.new("TextButton")
sellButton.Name = "SellButton"
sellButton.AnchorPoint = Vector2.new(0, 1)
sellButton.Size = UDim2.fromOffset(132, 44)
sellButton.Position = UDim2.new(0, 16, 1, -18)
sellButton.BackgroundColor3 = Color3.fromRGB(45, 155, 95)
sellButton.TextColor3 = Color3.new(1, 1, 1)
sellButton.Font = Enum.Font.GothamBold
sellButton.TextSize = 15
sellButton.Text = "SELL  •  0"
sellButton.AutoButtonColor = true
sellButton.Parent = screenGui
local sellCorner = Instance.new("UICorner")
sellCorner.CornerRadius = UDim.new(0, 12)
sellCorner.Parent = sellButton

sellButton.Activated:Connect(function()
	sellBubblesEvent:FireServer()
end)

local window = Instance.new("Frame")
window.Name = "ShopWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Size = UDim2.new(0.9, 0, 0, 310)
window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
window.BorderSizePixel = 0
window.Visible = false
window.Parent = screenGui

local windowLimit = Instance.new("UISizeConstraint")
windowLimit.MinSize = Vector2.new(280, 260)
windowLimit.MaxSize = Vector2.new(420, 380)
windowLimit.Parent = window

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 16)
windowCorner.Parent = window
local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Color3.fromRGB(95, 105, 135)
windowStroke.Transparency = 0.45
windowStroke.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -150, 0, 44)
title.Position = UDim2.fromOffset(16, 0)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Text = "GUM SHOP"
title.Parent = window

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromOffset(112, 40)
coinsLabel.Position = UDim2.new(1, -152, 0, 2)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 13
coinsLabel.Text = "0 Coins"
coinsLabel.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(30, 30)
closeButton.Position = UDim2.new(1, -38, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(80, 42, 52)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 15
closeButton.Text = "×"
closeButton.Parent = window
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 9)
closeCorner.Parent = closeButton
closeButton.Activated:Connect(function()
	window.Visible = false
end)

local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "GumList"
listFrame.Size = UDim2.new(1, -20, 1, -54)
listFrame.Position = UDim2.fromOffset(10, 48)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.CanvasSize = UDim2.new()
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = window

local listPadding = Instance.new("UIPadding")
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 2)
listPadding.PaddingRight = UDim.new(0, 2)
listPadding.Parent = listFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = listFrame

local rowButtons = {}

for _, gum in ipairs(GUMS) do
	local row = Instance.new("Frame")
	row.Name = gum.Name .. "Row"
	row.Size = UDim2.new(1, -4, 0, 50)
	row.BackgroundColor3 = Color3.fromRGB(39, 43, 58)
	row.BorderSizePixel = 0
	row.Parent = listFrame
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 10)
	rowCorner.Parent = row

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.fromOffset(7, 32)
	swatch.Position = UDim2.fromOffset(9, 9)
	swatch.BackgroundColor3 = gum.Color
	swatch.BorderSizePixel = 0
	swatch.Parent = row
	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(1, 0)
	swatchCorner.Parent = swatch

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -150, 1, 0)
	label.Position = UDim2.fromOffset(25, 0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(242, 244, 250)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.Text = string.format("%s  •  +%d/click\nMax bubble: %d", gum.Name, gum.Power, gum.MaxBubble)
	label.Parent = row

	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.fromOffset(112, 34)
	actionButton.AnchorPoint = Vector2.new(1, 0.5)
	actionButton.Position = UDim2.new(1, -8, 0.5, 0)
	actionButton.BackgroundColor3 = Color3.fromRGB(65, 130, 220)
	actionButton.TextColor3 = Color3.new(1, 1, 1)
	actionButton.Font = Enum.Font.GothamBold
	actionButton.TextSize = 12
	actionButton.Text = "..."
	actionButton.Parent = row
	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 9)
	actionCorner.Parent = actionButton

	actionButton.Activated:Connect(function()
		if player:GetAttribute("NearShopZone") == true then
			shopActionEvent:FireServer(gum.Id)
		end
	end)

	rowButtons[gum.Id] = {Gum = gum, Button = actionButton}
end

local function refreshUI()
	local currentLevel = player:GetAttribute("GumLevel") or 1
	local coins = player:GetAttribute("Coins") or 0
	local bubbles = player:GetAttribute("BubbleSize") or 0

	coinsLabel.Text = tostring(coins) .. " Coins"
	sellButton.Text = "SELL  •  " .. tostring(bubbles)

	for id, item in pairs(rowButtons) do
		local gum = item.Gum
		local button = item.Button
		local owned = hasGumLocal(id)

		if id == currentLevel then
			button.Text = "EQUIPPED"
			button.BackgroundColor3 = Color3.fromRGB(45, 145, 95)
			button.Active = false
		elseif owned then
			button.Text = "EQUIP"
			button.BackgroundColor3 = Color3.fromRGB(65, 115, 200)
			button.Active = true
		elseif coins >= gum.Price then
			button.Text = "BUY " .. tostring(gum.Price)
			button.BackgroundColor3 = Color3.fromRGB(45, 155, 95)
			button.Active = true
		else
			button.Text = tostring(gum.Price) .. " COINS"
			button.BackgroundColor3 = Color3.fromRGB(83, 54, 62)
			button.Active = false
		end
	end
end

local function syncShopVisibility()
	local nearShop = player:GetAttribute("NearShopZone") == true
	window.Visible = nearShop
	if nearShop then refreshUI() end
end

for _, attribute in ipairs({"NearShopZone", "Coins", "BubbleSize", "GumLevel", "OwnedGums"}) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if attribute == "NearShopZone" then
			syncShopVisibility()
		else
			refreshUI()
		end
	end)
end

syncShopVisibility()
refreshUI()
