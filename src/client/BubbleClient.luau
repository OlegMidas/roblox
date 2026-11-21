local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local blowEvent = remotes:WaitForChild("BlowBubble")
local syncBubbleEvent = remotes:WaitForChild("SyncBubble")

local bubblesByUser = {}
local baseJumpPower = 50
local boundHumanoids = {}

local function setVisualBubble(targetPlayer, amount, color)
	local char = targetPlayer.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return end

	local part = bubblesByUser[targetPlayer.UserId]

	if amount <= 0 then
		if part then
			part:Destroy()
			bubblesByUser[targetPlayer.UserId] = nil
		end
		return
	end

	if not part then
		part = Instance.new("Part")
		part.Name = "BubbleVisual"
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = 0.25
		part.CanCollide = false
		part.Massless = true
		part.Parent = char

		local weld = Instance.new("Weld")
		weld.Name = "BubbleWeld"
		weld.Part0 = head
		weld.Part1 = part
		weld.Parent = part

		bubblesByUser[targetPlayer.UserId] = part
	end

	local radius = math.clamp(1 + math.log10(amount + 1) * 3.5, 1, 16)
	part.Size = Vector3.new(radius, radius, radius)
	part.Color = color

	local weld = part:FindFirstChild("BubbleWeld")
	if weld then
		weld.C0 = CFrame.new(0, 0.2, -(radius * 0.5 + 0.6))
	end
end

syncBubbleEvent.OnClientEvent:Connect(setVisualBubble)

local function hookHumanoid(humanoid)
	if boundHumanoids[humanoid] then return end
	boundHumanoids[humanoid] = true
	humanoid.UseJumpPower = true
	baseJumpPower = humanoid.JumpPower
end

if player.Character then
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hookHumanoid(hum) end
end
player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChildOfClass("Humanoid", 5)
	if hum then hookHumanoid(hum) end
end)

-- Надувание по ЛКМ или тапу
local clickCooldown = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or clickCooldown then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		clickCooldown = true
		blowEvent:FireServer()
		task.wait(0.08)
		clickCooldown = false
	end
end)

local function calcProgressiveJump(amount)
	if amount < 5 then return 0 end
	local raw = (amount ^ 1.25) * 0.45
	return math.clamp(raw, 0, 420)
end

-- Оповещение UI о входе/выходе из ShopZone
local shopZone = workspace:FindFirstChild("ShopZone")
local insideShop = false

RunService.Heartbeat:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local leaderstats = player:FindFirstChild("leaderstats")
	local bubblesVal = leaderstats and leaderstats:FindFirstChild("Bubbles")

	if hum and bubblesVal then
		hookHumanoid(hum)
		hum.UseJumpPower = true
		hum.JumpPower = baseJumpPower + calcProgressiveJump(bubblesVal.Value)
	end

	if not shopZone or not shopZone.Parent then
		shopZone = workspace:FindFirstChild("ShopZone")
	end

	if root and shopZone and shopZone:IsA("BasePart") then
		local maxExtent = math.max(shopZone.Size.X, shopZone.Size.Z) * 0.5
		local enterRadius = maxExtent + 3.5
		local exitRadius = maxExtent + 6.5

		local flatPos = Vector3.new(root.Position.X, shopZone.Position.Y, root.Position.Z)
		local dist = (flatPos - shopZone.Position).Magnitude
		local heightDiff = math.abs(root.Position.Y - shopZone.Position.Y)

		if not insideShop and dist <= enterRadius and heightDiff <= 10 then
			insideShop = true
			player:SetAttribute("NearShopZone", true)
		elseif insideShop and (dist > exitRadius or heightDiff > 14) then
			insideShop = false
			player:SetAttribute("NearShopZone", false)
		end
	elseif insideShop then
		insideShop = false
		player:SetAttribute("NearShopZone", false)
	end
end)