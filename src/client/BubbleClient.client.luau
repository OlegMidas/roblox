--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

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

		local light = Instance.new("PointLight")
		light.Name = "BubbleGlow"
		light.Brightness = 0.65
		light.Range = 10
		light.Parent = part

		local attachment = Instance.new("Attachment")
		attachment.Name = "SparkleAttachment"
		attachment.Parent = part
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "BubbleSparkles"
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Rate = 2
		sparkles.Lifetime = NumberRange.new(0.35, 0.7)
		sparkles.Speed = NumberRange.new(0.25, 0.8)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.LightEmission = 0.8
		sparkles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.16),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparkles.Parent = attachment

		bubblesByUser[userId] = part
	end

	local radius = math.clamp(1 + math.log10(amount + 1) * 3.5, 1, 16)
	part.Color = color
	local glow = part:FindFirstChild("BubbleGlow")
	if glow and glow:IsA("PointLight") then
		glow.Color = color
		glow.Range = math.clamp(radius * 2.2, 8, 28)
	end
	local sparkles = part:FindFirstChild("SparkleAttachment")
	local emitter = sparkles and sparkles:FindFirstChild("BubbleSparkles")
	if emitter and emitter:IsA("ParticleEmitter") then
		emitter:Emit(3)
	end
	TweenService:Create(part, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.one * radius,
	}):Play()

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
	local shouldBeInside = false

	if root and root:IsA("BasePart") then
		local margin = insideShop and 1.5 or 0
		for _, zone in CollectionService:GetTagged("GumShopZone") do
			if zone:IsA("BasePart") and zone:IsDescendantOf(workspace) then
				local position = zone.CFrame:PointToObjectSpace(root.Position)
				local half = zone.Size * 0.5
				if math.abs(position.X) <= half.X + margin
					and math.abs(position.Z) <= half.Z + margin
					and math.abs(position.Y) <= half.Y then
					shouldBeInside = true
					break
				end
			end
		end
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
