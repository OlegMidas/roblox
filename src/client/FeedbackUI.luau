--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local toastEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Toast") :: RemoteEvent

local oldGui = playerGui:FindFirstChild("FeedbackGui")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FeedbackGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Name = "Toast"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, -100)
card.Size = UDim2.new(0.82, 0, 0, 68)
card.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
card.BackgroundTransparency = 0.04
card.BorderSizePixel = 0
card.Parent = gui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(260, 68)
sizeLimit.MaxSize = Vector2.new(420, 68)
sizeLimit.Parent = card

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Name = "Accent"
stroke.Color = Color3.fromRGB(100, 210, 255)
stroke.Thickness = 2
stroke.Transparency = 0.12
stroke.Parent = card

local accent = Instance.new("Frame")
accent.Size = UDim2.new(0, 5, 1, -18)
accent.Position = UDim2.fromOffset(9, 9)
accent.BackgroundColor3 = stroke.Color
accent.BorderSizePixel = 0
accent.Parent = card
local accentCorner = Instance.new("UICorner")
accentCorner.CornerRadius = UDim.new(1, 0)
accentCorner.Parent = accent

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(25, 9)
title.Size = UDim2.new(1, -38, 0, 23)
title.BackgroundTransparency = 1
title.Text = "NICE!"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.Parent = card

local message = Instance.new("TextLabel")
message.Name = "Message"
message.Position = UDim2.fromOffset(25, 33)
message.Size = UDim2.new(1, -38, 0, 23)
message.BackgroundTransparency = 1
message.Text = "Progress saved."
message.TextColor3 = Color3.fromRGB(190, 200, 220)
message.TextXAlignment = Enum.TextXAlignment.Left
message.Font = Enum.Font.GothamMedium
message.TextSize = 12
message.TextTruncate = Enum.TextTruncate.AtEnd
message.Parent = card

local toastVersion = 0
local visiblePosition = UDim2.new(0.5, 0, 0, 18)
local hiddenPosition = UDim2.new(0.5, 0, 0, -100)

toastEvent.OnClientEvent:Connect(function(titleText: string, messageText: string, accentColor: Color3?)
	toastVersion += 1
	local version = toastVersion
	local color = if typeof(accentColor) == "Color3" then accentColor else Color3.fromRGB(100, 210, 255)
	title.Text = titleText
	message.Text = messageText
	stroke.Color = color
	accent.BackgroundColor3 = color
	card.Position = hiddenPosition
	TweenService:Create(card, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = visiblePosition,
	}):Play()
	task.delay(2.6, function()
		if version ~= toastVersion then return end
		TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = hiddenPosition,
		}):Play()
	end)
end)
