--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local worldAction = remotes:WaitForChild("WorldAction") :: RemoteEvent
local rebirthAction = remotes:WaitForChild("RebirthAction") :: RemoteEvent

local WORLDS = {
	{Id = 1, Name = "Grassland", Cost = 0, RequiredLevel = 1},
	{Id = 2, Name = "Frozen World", Cost = 5000, RequiredLevel = 5},
	{Id = 3, Name = "Candy World", Cost = 50000, RequiredLevel = 12},
	{Id = 4, Name = "Galaxy World", Cost = 500000, RequiredLevel = 20},
}
local REBIRTH_LEVEL = 20
local REBIRTH_COINS = 250000

local old = playerGui:FindFirstChild("ProgressionGui")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ProgressionGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.Parent = playerGui

local function round(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function makeLabel(parent: Instance, name: string, size: UDim2, position: UDim2, text: string, textSize: number)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(245, 247, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

-- Minimal XP widget on the left side, clear of the center gameplay view.
local xpPanel = Instance.new("Frame")
xpPanel.Name = "XPPanel"
xpPanel.AnchorPoint = Vector2.new(0, 0)
xpPanel.Position = UDim2.fromOffset(16, 92)
xpPanel.Size = UDim2.fromOffset(214, 58)
xpPanel.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
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
xpText.Text = "0 / 100 XP"
xpText.TextColor3 = Color3.fromRGB(255, 255, 255)
xpText.TextStrokeTransparency = 0.65
xpText.Font = Enum.Font.GothamBold
xpText.TextSize = 9
xpText.Parent = track

-- World selector.
local worldToggle = Instance.new("TextButton")
worldToggle.Name = "WorldToggle"
worldToggle.AnchorPoint = Vector2.new(1, 1)
worldToggle.Position = UDim2.new(1, -16, 1, -74)
worldToggle.Size = UDim2.fromOffset(142, 42)
worldToggle.BackgroundColor3 = Color3.fromRGB(62, 103, 190)
worldToggle.TextColor3 = Color3.new(1, 1, 1)
worldToggle.Font = Enum.Font.GothamBold
worldToggle.TextSize = 13
worldToggle.Text = "WORLDS  ▾"
worldToggle.Parent = gui
round(worldToggle, 12)

local worldPanel = Instance.new("Frame")
worldPanel.Name = "WorldPanel"
worldPanel.AnchorPoint = Vector2.new(1, 1)
worldPanel.Position = UDim2.new(1, -16, 1, -124)
worldPanel.Size = UDim2.fromOffset(230, 228)
worldPanel.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
worldPanel.BorderSizePixel = 0
worldPanel.Visible = false
worldPanel.Parent = gui
round(worldPanel, 14)

local worldTitle = makeLabel(worldPanel, "Title", UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 4), "EXPLORE WORLDS", 13)
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
for _, world in ipairs(WORLDS) do
	local button = Instance.new("TextButton")
	button.Name = "World" .. tostring(world.Id)
	button.Size = UDim2.new(1, 0, 0, 38)
	button.BackgroundColor3 = Color3.fromRGB(47, 53, 70)
	button.TextColor3 = Color3.fromRGB(245, 247, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 11
	button.Text = world.Name
	button.Parent = worldList
	round(button, 9)
	button.Activated:Connect(function()
		worldAction:FireServer(world.Id)
	end)
	worldButtons[world.Id] = button
end

worldToggle.Activated:Connect(function()
	worldPanel.Visible = not worldPanel.Visible
end)

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.AnchorPoint = Vector2.new(1, 1)
rebirthButton.Position = UDim2.new(1, -16, 1, -18)
rebirthButton.Size = UDim2.fromOffset(142, 44)
rebirthButton.BackgroundColor3 = Color3.fromRGB(145, 75, 190)
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.TextSize = 12
rebirthButton.Text = "REBIRTH"
rebirthButton.Parent = gui
round(rebirthButton, 12)
rebirthButton.Activated:Connect(function()
	rebirthAction:FireServer()
end)

local function isUnlocked(id: number): boolean
	local unlocked = player:GetAttribute("UnlockedWorlds") or "1"
	for token in string.gmatch(unlocked, "[^,]+") do
		if tonumber(token) == id then return true end
	end
	return false
end

local function update()
	local level = player:GetAttribute("PlayerLevel") or 1
	local xp = player:GetAttribute("XP") or 0
	local needed = player:GetAttribute("XPToNext") or 100
	local rebirths = player:GetAttribute("Rebirths") or 0
	local coins = player:GetAttribute("Coins") or 0
	local currentWorld = player:GetAttribute("CurrentWorldId") or 1

	levelLabel.Text = "LEVEL " .. tostring(level)
	rebirthLabel.Text = "REBIRTH " .. tostring(rebirths)
	xpText.Text = tostring(xp) .. " / " .. tostring(needed) .. " XP"
	fill.Size = UDim2.fromScale(math.clamp(xp / math.max(needed, 1), 0, 1), 1)

	for _, world in ipairs(WORLDS) do
		local button = worldButtons[world.Id]
		if isUnlocked(world.Id) then
			button.Text = (currentWorld == world.Id and "✓  " or "GO  ") .. world.Name
			button.BackgroundColor3 = currentWorld == world.Id and Color3.fromRGB(45, 135, 90) or Color3.fromRGB(55, 105, 155)
			button.Active = currentWorld ~= world.Id
		elseif isUnlocked(world.Id - 1) then
			button.Text = string.format("UNLOCK %s  •  LV.%d", world.Cost >= 1000 and (tostring(world.Cost / 1000) .. "K") or tostring(world.Cost), world.RequiredLevel)
			button.BackgroundColor3 = (coins >= world.Cost and level >= world.RequiredLevel) and Color3.fromRGB(55, 130, 85) or Color3.fromRGB(90, 65, 72)
			button.Active = coins >= world.Cost and level >= world.RequiredLevel
		else
			button.Text = "LOCKED  •  " .. world.Name
			button.BackgroundColor3 = Color3.fromRGB(55, 58, 68)
			button.Active = false
		end
	end

	if level >= REBIRTH_LEVEL and coins >= REBIRTH_COINS then
		rebirthButton.Text = "REBIRTH  •  READY"
		rebirthButton.Active = true
		rebirthButton.BackgroundColor3 = Color3.fromRGB(165, 85, 220)
	else
		rebirthButton.Text = string.format("REBIRTH  •  LV.%d / %dK", REBIRTH_LEVEL, REBIRTH_COINS / 1000)
		rebirthButton.Active = false
		rebirthButton.BackgroundColor3 = Color3.fromRGB(90, 65, 110)
	end
end

for _, attribute in ipairs({"PlayerLevel", "XP", "XPToNext", "Rebirths", "Coins", "UnlockedWorlds", "CurrentWorldId"}) do
	player:GetAttributeChangedSignal(attribute):Connect(update)
end
update()
