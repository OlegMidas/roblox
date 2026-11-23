--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local blowEvent = remotes:WaitForChild("BlowBubble") :: RemoteEvent
local syncBubbleEvent = remotes:WaitForChild("SyncBubble") :: RemoteEvent

local bubblesByUser: {[number]: BasePart} = {}
local baseJumpPower = 50
local currentHumanoid: Humanoid? = nil
local clickReady = true
local insideShop = false

local function setVisualBubble(targetPlayer: Player, amount: number, color: Color3)
	local character = targetPlayer.Character
	local head = character and character:FindFirstChild("Head")
	local userId = targetPlayer.UserId
	local part = bubblesByUser[userId]

	if part and (not part.Parent or part.Parent ~= character) then
		part:Destroy()
		part = nil
		bubblesByUser[userId] = nil
	end

	if amount <= 0 or not head or not head:IsA("BasePart") then
		if part then part:Destroy() end
		bubblesByUser[userId] = nil
		return
	end

	if not part then
		part = Instance.new("Part")
		part.Name = "BubbleVisual"
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = 0.25
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CastShadow = false
		part.Anchored = false
		part.Parent = character

		local weld = Instance.new("Weld")
		weld.Name = "BubbleWeld"
		weld.Part0 = head
		weld.Part1 = part
		weld.C0 = CFrame.new(0, 0.2, -1.1)
		weld.Parent = part

		bubblesByUser[userId] = part
	end

	local radius = math.clamp(1 + math.log10(amount + 1) * 3.5, 1, 16)
	part.Size = Vector3.one * radius
	part.Color = color

	local weld = part:FindFirstChild("BubbleWeld")
	if weld and weld:IsA("Weld") then
		weld.Part0 = head
		weld.C0 = CFrame.new(0, 0.2, -(radius * 0.5 + 0.6))
	end
end

syncBubbleEvent.OnClientEvent:Connect(setVisualBubble)

local function updateJumpPower()
	local humanoid = currentHumanoid
	local stats = player:FindFirstChild("leaderstats")
	local bubbles = stats and stats:FindFirstChild("Bubbles")
	if not humanoid or not humanoid.Parent or not bubbles or not bubbles:IsA("IntValue") then
		return
	end

	local amount = bubbles.Value
	local bonus = 0
	if amount >= 5 then
		bonus = math.clamp((amount ^ 1.25) * 0.45, 0, 420)
	end
	local targetPower = baseJumpPower + bonus
	if math.abs(humanoid.JumpPower - targetPower) > 0.1 then
		humanoid.JumpPower = targetPower
	end
end

local function hookCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then return end

	currentHumanoid = humanoid
	humanoid.UseJumpPower = true
	baseJumpPower = humanoid.JumpPower
	updateJumpPower()

	local stats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 10)
	local bubbles = stats and stats:FindFirstChild("Bubbles")
	if bubbles and bubbles:IsA("IntValue") then
		bubbles:GetPropertyChangedSignal("Value"):Connect(updateJumpPower)
	end
end

if player.Character then
	task.spawn(hookCharacter, player.Character)
end
player.CharacterAdded:Connect(hookCharacter)
player.CharacterRemoving:Connect(function()
	currentHumanoid = nil
	local part = bubblesByUser[player.UserId]
	if part then part:Destroy() end
	bubblesByUser[player.UserId] = nil
end)

local function requestBlow()
	if not clickReady then return end
	clickReady = false
	blowEvent:FireServer()
	task.delay(0.08, function()
		clickReady = true
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		requestBlow()
	end
end)

local function updateShopProximity()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local zone = workspace:FindFirstChild("ShopZone")
	local shouldBeInside = false

	if root and root:IsA("BasePart") and zone and zone:IsA("BasePart") then
		local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
		local half = zone.Size * 0.5
		local margin = insideShop and 6.5 or 3.5
		shouldBeInside = math.abs(localPosition.X) <= half.X + margin
			and math.abs(localPosition.Z) <= half.Z + margin
			and math.abs(localPosition.Y) <= half.Y + (insideShop and 14 or 10)
	end

	if shouldBeInside ~= insideShop then
		insideShop = shouldBeInside
		player:SetAttribute("NearShopZone", insideShop)
	end
end

-- A small fixed interval is cheaper than doing the same work every rendered frame.
task.spawn(function()
	while player.Parent do
		updateShopProximity()
		updateJumpPower()
		task.wait(0.15)
	end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	local part = bubblesByUser[leavingPlayer.UserId]
	if part then part:Destroy() end
	bubblesByUser[leavingPlayer.UserId] = nil
end)
