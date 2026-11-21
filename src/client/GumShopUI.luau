local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shopActionEvent = remotes:WaitForChild("ShopAction")
local sellBubblesEvent = remotes:WaitForChild("SellBubbles")

local GUMS = {
	{Id = 1, Name = "Mint", Price = 0, Power = 1, MaxBubble = 25, Color = Color3.fromRGB(255, 110, 180)},
	{Id = 2, Name = "Berry", Price = 50, Power = 4, MaxBubble = 80, Color = Color3.fromRGB(255, 60, 80)},
	{Id = 3, Name = "Lime", Price = 250, Power = 12, MaxBubble = 220, Color = Color3.fromRGB(80, 230, 90)},
	{Id = 4, Name = "Galaxy", Price = 1000, Power = 35, MaxBubble = 600, Color = Color3.fromRGB(145, 70, 255)},
	{Id = 5, Name = "Gold", Price = 5000, Power = 120, MaxBubble = 2000, Color = Color3.fromRGB(255, 210, 40)},
}

local function hasGumLocal(gumId)
	if gumId == 1 then return true end
	local owned = player:GetAttribute("OwnedGums") or "1"
	for token in string.gmatch(owned, "[^,]+") do
		if tonumber(token) == gumId then
			return true
		end
	end
	return false
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GumShopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local sellBtn = Instance.new("TextButton")
sellBtn.Name = "SellButton"
sellBtn.Size = UDim2.fromOffset(110, 38)
sellBtn.Position = UDim2.new(0, 16, 1, -54)
sellBtn.BackgroundColor3 = Color3.fromRGB(45, 145, 85)
sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellBtn.Font = Enum.Font.GothamBold
sellBtn.TextSize = 15
sellBtn.Text = "Sell (0)"
sellBtn.Parent = screenGui

sellBtn.MouseButton1Click:Connect(function()
	sellBubblesEvent:FireServer()
end)

local window = Instance.new("Frame")
window.Name = "ShopWindow"
window.Size = UDim2.fromOffset(360, 290)
window.Position = UDim2.new(0.5, -180, 0.5, -145)
window.BackgroundColor3 = Color3.fromRGB(24, 26, 33)
window.BorderSizePixel = 0
window.Visible = false
window.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 36)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.Text = "Gum Shop"
title.Parent = window

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(0, 110, 0, 36)
coinsLabel.Position = UDim2.new(1, -148, 0, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 70)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 14
coinsLabel.Text = "0 Coins"
coinsLabel.Parent = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 35)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Text = "X"
closeBtn.Parent = window

closeBtn.MouseButton1Click:Connect(function()
	window.Visible = false
end)

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 1, -48)
listFrame.Position = UDim2.fromOffset(10, 40)
listFrame.BackgroundTransparency = 1
listFrame.ScrollBarThickness = 4
listFrame.Parent = window

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = listFrame

local rowButtons = {}

for _, gum in ipairs(GUMS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundColor3 = Color3.fromRGB(36, 40, 50)
	row.BorderSizePixel = 0
	row.Parent = listFrame

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.fromOffset(8, 28)
	swatch.Position = UDim2.fromOffset(8, 7)
	swatch.BackgroundColor3 = gum.Color
	swatch.BorderSizePixel = 0
	swatch.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, -24, 1, 0)
	label.Position = UDim2.fromOffset(22, 0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.Text = string.format("%s\n+%d/click | max %d", gum.Name, gum.Power, gum.MaxBubble)
	label.Parent = row

	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.fromOffset(112, 30)
	actionBtn.Position = UDim2.new(1, -120, 0.5, -15)
	actionBtn.BackgroundColor3 = Color3.fromRGB(65, 130, 245)
	actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.TextSize = 12
	actionBtn.Parent = row

	actionBtn.MouseButton1Click:Connect(function()
		shopActionEvent:FireServer(gum.Id)
	end)

	rowButtons[gum.Id] = {Gum = gum, Button = actionBtn}
end

listFrame.CanvasSize = UDim2.fromOffset(0, #GUMS * 48)

local function refreshUI()
	local currentLevel = player:GetAttribute("GumLevel") or 1
	local leaderstats = player:FindFirstChild("leaderstats")
	local coinsVal = leaderstats and leaderstats:FindFirstChild("Coins")
	local bubblesVal = leaderstats and leaderstats:FindFirstChild("Bubbles")

	local coins = coinsVal and coinsVal.Value or 0
	local bubbles = bubblesVal and bubblesVal.Value or 0

	coinsLabel.Text = coins .. " Coins"
	sellBtn.Text = "Sell (" .. bubbles .. ")"

	for id, item in pairs(rowButtons) do
		local gum = item.Gum
		local btn = item.Button
		local owned = hasGumLocal(id)

		if id == currentLevel then
			btn.Text = "Equipped"
			btn.BackgroundColor3 = Color3.fromRGB(55, 145, 95)
		elseif owned then
			btn.Text = "Equip"
			btn.BackgroundColor3 = Color3.fromRGB(65, 115, 200)
		elseif coins >= gum.Price then
			btn.Text = "Buy (" .. gum.Price .. ")"
			btn.BackgroundColor3 = Color3.fromRGB(55, 175, 95)
		else
			btn.Text = gum.Price .. " Coins"
			btn.BackgroundColor3 = Color3.fromRGB(85, 48, 54)
		end
	end
end

local function syncShopVisibility()
	local near = player:GetAttribute("NearShopZone") == true
	window.Visible = near
	if near then
		refreshUI()
	end
end

player:GetAttributeChangedSignal("NearShopZone"):Connect(syncShopVisibility)
player:GetAttributeChangedSignal("GumLevel"):Connect(refreshUI)
player:GetAttributeChangedSignal("OwnedGums"):Connect(refreshUI)

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then return end
	local coinsVal = leaderstats:WaitForChild("Coins", 10)
	local bubblesVal = leaderstats:WaitForChild("Bubbles", 10)
	if coinsVal then coinsVal.Changed:Connect(refreshUI) end
	if bubblesVal then bubblesVal.Changed:Connect(refreshUI) end
	refreshUI()
end)