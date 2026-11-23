--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local blowEvent = remotes:WaitForChild("BlowBubble") :: RemoteEvent
local config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local SoundService = game:GetService("SoundService")

-- Lightweight feedback sounds using built-in assets (no uploads needed).
local soundFolder = Instance.new("Folder")
soundFolder.Name = "BubbleSounds"
soundFolder.Parent = SoundService
local function makeSound(name: string, id: string, volume: number): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = volume
	sound.Parent = soundFolder
	return sound
end
local blowSound = makeSound("Blow", "rbxasset://sounds/electronicpingshort.wav", 0.18)
local popSound = makeSound("Pop", "rbxasset://sounds/impact_water.mp3", 0.45)

local bubblesByUser: {[number]: Part} = {}
local playerConnections: {[Player]: {RBXScriptConnection}} = {}
local headConnections: {[Player]: RBXScriptConnection} = {}
local pendingRefresh: {[Player]: boolean} = {}

local function createVisualBubble(head: BasePart, character: Model): Part
	local part = Instance.new("Part")
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
	return part
end

local function setVisualBubble(targetPlayer: Player, amount: number, color: Color3)
	local character = targetPlayer.Character
	local head = character and character:FindFirstChild("Head")
	local userId = targetPlayer.UserId
	local part: Part? = bubblesByUser[userId]

	if part and (not part.Parent or part.Parent ~= character) then
		part:Destroy()
		part = nil
		bubblesByUser[userId] = nil
	end

	if not character or not head or not head:IsA("BasePart") then return end
	if amount <= 0 then
		if part then
			-- Pop effect: burst of sparkles, quick expand, then remove.
			popSound.PlaybackSpeed = 0.85 + math.random() * 0.4
			popSound:Play()
			local sparkleHolder = part:FindFirstChild("SparkleAttachment")
			local emitter = sparkleHolder and sparkleHolder:FindFirstChild("BubbleSparkles")
			if emitter and emitter:IsA("ParticleEmitter") then
				emitter:Emit(14)
			end
			local weld = part:FindFirstChild("BubbleWeld")
			if weld and weld:IsA("Weld") then
				weld:Destroy()
			end
			part.Anchored = true
			TweenService:Create(part, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = part.Size * 1.5,
				Transparency = 1,
			}):Play()
			local popped = part
			task.delay(0.3, function()
				popped:Destroy()
			end)
		end
		bubblesByUser[userId] = nil
		return
	end

	local visual = part or createVisualBubble(head, character)
	bubblesByUser[userId] = visual

	local radius = math.clamp(1 + math.log10(amount + 1) * 3.5, 1, 16)
	visual.Color = color
	local glow = visual:FindFirstChild("BubbleGlow")
	if glow and glow:IsA("PointLight") then
		glow.Color = color
		glow.Range = math.clamp(radius * 2.2, 8, 28)
	end
	local sparkles = visual:FindFirstChild("SparkleAttachment")
	local emitter = sparkles and sparkles:FindFirstChild("BubbleSparkles")
	if emitter and emitter:IsA("ParticleEmitter") then
		emitter:Emit(3)
	end
	TweenService:Create(visual, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.one * radius,
	}):Play()

	local weld = visual:FindFirstChild("BubbleWeld")
	if weld and weld:IsA("Weld") then
		weld.Part0 = head
		weld.C0 = CFrame.new(0, 0.2, -(radius * 0.5 + 0.6))
	end
end

local function clearBubble(target: Player)
	local part = bubblesByUser[target.UserId]
	if part then part:Destroy() end
	bubblesByUser[target.UserId] = nil
end

local function refreshBubble(target: Player)
	if pendingRefresh[target] then return end
	pendingRefresh[target] = true
	task.defer(function()
		pendingRefresh[target] = nil
		if not playerConnections[target] then return end
		local size = target:GetAttribute("BubbleSize")
		local amount = if type(size) == "number" then size else 0
		local level = target:GetAttribute("GumLevel")
		local gum = if type(level) == "number" then config.Gums[level] else config.Gums[1]
		setVisualBubble(target, amount, gum.Color)
	end)
end

local function onPlayerAdded(target: Player)
	if playerConnections[target] then return end
	local function hookCharacter(character: Model)
		local previous = headConnections[target]
		if previous then previous:Disconnect() end
		headConnections[target] = character.ChildAdded:Connect(function(child)
			if child.Name == "Head" then refreshBubble(target) end
		end)
		refreshBubble(target)
	end
	playerConnections[target] = {
		target:GetAttributeChangedSignal("BubbleSize"):Connect(function()
			refreshBubble(target)
		end),
		target:GetAttributeChangedSignal("GumLevel"):Connect(function()
			refreshBubble(target)
		end),
		target.CharacterAdded:Connect(hookCharacter),
		target.CharacterRemoving:Connect(function()
			local connection = headConnections[target]
			if connection then connection:Disconnect() end
			headConnections[target] = nil
			clearBubble(target)
		end),
	}
	if target.Character then hookCharacter(target.Character) end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, target in ipairs(Players:GetPlayers()) do onPlayerAdded(target) end
Players.PlayerRemoving:Connect(function(target)
	for _, connection in ipairs(playerConnections[target] or {}) do connection:Disconnect() end
	local headConnection = headConnections[target]
	if headConnection then headConnection:Disconnect() end
	headConnections[target] = nil
	playerConnections[target] = nil
	clearBubble(target)
end)

local lastBlow = -math.huge
local function requestBlow()
	local amount = player:GetAttribute("BubbleSize") or 0
	local capacity = player:GetAttribute("MaxBubble")
	local now = os.clock()
	if not capacity or amount >= capacity or now - lastBlow < config.BlowCooldown then return end
	lastBlow = now
	blowSound.PlaybackSpeed = 0.85 + math.random() * 0.3
	blowSound:Play()
	blowEvent:FireServer()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		requestBlow()
	end
end)
UserInputService.TouchTap:Connect(function(_, gameProcessed)
	if not gameProcessed then requestBlow() end
end)
