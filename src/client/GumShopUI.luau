--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shopActionEvent = remotes:WaitForChild("ShopAction") :: RemoteEvent
local sellBubblesEvent = remotes:WaitForChild("SellBubbles") :: RemoteEvent

local config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local oldGui = playerGui:FindFirstChild("GumShopGui")
if oldGui then oldGui:Destroy() end

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
sellButton.Font = Enum.Font.FredokaOne
sellButton.TextSize = 15
sellButton.Text = "🪙 SELL  •  0"
sellButton.Visible = false
sellButton.Parent = screenGui
local sellCorner = Instance.new("UICorner")
sellCorner.CornerRadius = UDim.new(0, 12)
sellCorner.Parent = sellButton

sellButton.Activated:Connect(function()
	sellBubblesEvent:FireServer()
end)

local shopButton = Instance.new("TextButton")
shopButton.Name = "OpenShop"
shopButton.AnchorPoint = Vector2.new(0, 1)
shopButton.Position = UDim2.new(0, 16, 1, -18)
shopButton.Size = UDim2.fromOffset(132, 44)
shopButton.BackgroundColor3 = Color3.fromRGB(62, 103, 190)
shopButton.TextColor3 = Color3.new(1, 1, 1)
shopButton.Font = Enum.Font.FredokaOne
shopButton.TextSize = 14
shopButton.Text = "🍬 GUM SHOP"
shopButton.Visible = false
shopButton.Parent = screenGui
Instance.new("UICorner", shopButton).CornerRadius = UDim.new(0, 12)

local window = Instance.new("Frame")
window.Name = "ShopWindow"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Size = UDim2.new(0.9, 0, 0, 350)
window.Position = UDim2.fromScale(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(43, 30, 69)
window.BorderSizePixel = 0
window.Visible = false
window.Parent = screenGui

local windowLimit = Instance.new("UISizeConstraint")
windowLimit.MinSize = Vector2.new(280, 300)
windowLimit.MaxSize = Vector2.new(440, 420)
windowLimit.Parent = window

local windowCorner = Instance.new("UICorner")
windowCorner.CornerRadius = UDim.new(0, 16)
windowCorner.Parent = window
local windowStroke = Instance.new("UIStroke")
windowStroke.Color = Color3.fromRGB(190, 149, 255)
windowStroke.Transparency = 0.12
windowStroke.Thickness = 2
windowStroke.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -150, 0, 44)
title.Position = UDim2.fromOffset(16, 0)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.FredokaOne
title.TextSize = 20
title.Text = "🍬 GUM SHOP"
title.Parent = window

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -32, 0, 18)
subtitle.Position = UDim2.fromOffset(16, 34)
subtitle.BackgroundTransparency = 1
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = Color3.fromRGB(160, 170, 195)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.Text = "Upgrade bubble power, capacity and jump height"
subtitle.Parent = window

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromOffset(112, 40)
coinsLabel.Position = UDim2.new(1, -152, 0, 2)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
coinsLabel.Font = Enum.Font.FredokaOne
coinsLabel.TextSize = 13
coinsLabel.Text = "0 Coins"
coinsLabel.Parent = window

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(30, 30)
closeButton.Position = UDim2.new(1, -38, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(80, 42, 52)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.FredokaOne
closeButton.TextSize = 15
closeButton.Text = "×"
closeButton.Parent = window
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 9)
closeCorner.Parent = closeButton
local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "GumList"
listFrame.Size = UDim2.new(1, -20, 1, -72)
listFrame.Position = UDim2.fromOffset(10, 66)
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

for _, gum in ipairs(config.Gums) do
	local row = Instance.new("Frame")
	row.Name = gum.Name .. "Row"
	row.Size = UDim2.new(1, -4, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(67, 48, 95)
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
	label.TextSize = 11
	label.TextWrapped = true
	local tier = (gum.Id - 1) % 5 + 1
	label.Text = string.format("%s • Tier %d\n+%d per blow / %d max\nJump %d", gum.Name, tier, gum.Power, gum.MaxBubble, gum.JumpPower)
	label.Parent = row

	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.fromOffset(116, 36)
	actionButton.AnchorPoint = Vector2.new(1, 0.5)
	actionButton.Position = UDim2.new(1, -8, 0.5, 0)
	actionButton.BackgroundColor3 = Color3.fromRGB(65, 130, 220)
	actionButton.TextColor3 = Color3.new(1, 1, 1)
	actionButton.Font = Enum.Font.FredokaOne
	actionButton.TextSize = 12
	actionButton.Text = "..."
	actionButton.Parent = row
	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 9)
	actionCorner.Parent = actionButton

	actionButton.Activated:Connect(function()
		if actionButton.Interactable and player:GetAttribute("NearShopZone") == true then
			shopActionEvent:FireServer(gum.Id)
		end
	end)

	rowButtons[gum.Id] = { Gum = gum, Row = row, Button = actionButton }
end

local shopClosed = false
local function refreshUI()
	local currentLevel = player:GetAttribute("GumLevel") or 1
	local currentWorld = player:GetAttribute("CurrentWorldId") or 1
	local coins = player:GetAttribute("Coins") or 0
	local bubbles = player:GetAttribute("BubbleSize") or 0
	local ownedIds = player:GetAttribute("OwnedGums")
	local nearShop = player:GetAttribute("NearShopZone") == true

	coinsLabel.Text = tostring(coins) .. " Coins"
	subtitle.Text = config.Worlds[currentWorld].Name .. " • Local gums and your collection"
	sellButton.Visible = player:GetAttribute("NearSellZone") == true
	sellButton.Interactable = bubbles > 0
	sellButton.Text = "🪙 SELL  •  " .. tostring(bubbles)
	window.Visible = nearShop and not shopClosed
	shopButton.Visible = nearShop and shopClosed
	if not nearShop then shopClosed = false end

	for id, item in pairs(rowButtons) do
		local gum, row, button = item.Gum, item.Row, item.Button
		local owned = config.hasId(ownedIds, id)
		local prerequisite = config.shopPrerequisite(id)
		local localGum = gum.World == currentWorld
		row.Visible = localGum or owned
		row.LayoutOrder = if localGum then id else #config.Gums + id

		button.Interactable = false
		if id == currentLevel then
			button.Text = "EQUIPPED"
			button.BackgroundColor3 = Color3.fromRGB(45, 145, 95)
		elseif owned then
			button.Text = "EQUIP"
			button.BackgroundColor3 = Color3.fromRGB(65, 115, 200)
			button.Interactable = true
		elseif prerequisite and not config.hasId(ownedIds, prerequisite) then
			button.Text = "PREVIOUS GUM"
			button.BackgroundColor3 = Color3.fromRGB(70, 72, 88)
		elseif coins >= gum.Price then
			button.Text = "BUY " .. tostring(gum.Price)
			button.BackgroundColor3 = Color3.fromRGB(45, 155, 95)
			button.Interactable = true
		else
			button.Text = tostring(gum.Price) .. " COINS"
			button.BackgroundColor3 = Color3.fromRGB(83, 54, 62)
		end
	end
end

closeButton.Activated:Connect(function()
	shopClosed = true
	refreshUI()
end)
shopButton.Activated:Connect(function()
	shopClosed = false
	refreshUI()
end)

for _, attribute in ipairs({ "NearShopZone", "NearSellZone", "Coins", "BubbleSize", "GumLevel", "OwnedGums", "CurrentWorldId" }) do
	player:GetAttributeChangedSignal(attribute):Connect(refreshUI)
end
player:GetAttributeChangedSignal("CurrentWorldId"):Connect(function()
	listFrame.CanvasPosition = Vector2.zero
end)
refreshUI()
