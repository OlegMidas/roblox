--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Hub = {}
local grass = Color3.fromRGB(109, 205, 113)
local stone = Color3.fromRGB(111, 87, 119)
local cream = Color3.fromRGB(255, 220, 176)
local ink = Color3.fromRGB(38, 29, 56)

local function part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, collides: boolean): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = frame
	item.Color = color
	item.Anchored = true
	item.CanCollide = collides
	item.CanTouch = false
	item.CanQuery = collides
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function sign(anchor: BasePart, title: string, detail: string, color: Color3)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HubSign"
	gui.Size = UDim2.fromOffset(184, 53)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.MaxDistance = 90
	gui.AlwaysOnTop = true
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Name = "Title"
	label.Size = UDim2.new(1, 0, 0, 29)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 21
	label.TextColor3 = color
	label.TextStrokeColor3 = ink
	label.TextStrokeTransparency = 0.15
	label.Text = title
	label.Parent = gui

	local status = label:Clone()
	status.Name = "Status"
	status.Position = UDim2.fromOffset(0, 28)
	status.Size = UDim2.new(1, 0, 0, 22)
	status.TextColor3 = Color3.new(1, 1, 1)
	status.TextSize = 14
	status.Text = detail
	status.Parent = gui
end

local function prompt(anchor: BasePart, name: string, title: string, action: string, distance: number): ProximityPrompt
	local input = Instance.new("ProximityPrompt")
	input.Name = name
	input.ObjectText = title
	input.ActionText = action
	input.MaxActivationDistance = distance
	input.RequiresLineOfSight = false
	input.Parent = anchor
	return input
end

local function npc(parent: Instance, title: string, job: string, origin: CFrame, color: Color3): BasePart
	local model = Instance.new("Model")
	model.Name = title
	model.Parent = parent
	part(model, "Podium", Vector3.new(5, 0.6, 4), origin * CFrame.new(0, 0.3, 0), color, true)
	local torso = part(model, "Jacket", Vector3.new(2.5, 2.15, 1.3), origin * CFrame.new(0, 3, 0), color, false)
	local head = part(model, "Head", Vector3.new(2.45, 2.4, 2.25), origin * CFrame.new(0, 5.15, 0), cream, false)
	head.Shape = Enum.PartType.Ball
	part(model, "Hat", Vector3.new(2.8, 0.45, 2.5), origin * CFrame.new(0, 6.15, 0), color, false)
	for _, side in ipairs({-1, 1}) do
		part(model, "Boot", Vector3.new(0.92, 1.7, 1.15), origin * CFrame.new(side * 0.63, 1.43, 0), ink, false)
		part(model, "Sleeve", Vector3.new(0.72, 1.7, 0.87), origin * CFrame.new(side * 1.66, 3.04, 0), color, false)
		local eye = part(model, "Eye", Vector3.new(0.22, 0.3, 0.14), origin * CFrame.new(side * 0.42, 5.32, 1.03), ink, false)
		eye.Shape = Enum.PartType.Ball
	end
	part(model, "Smile", Vector3.new(0.52, 0.13, 0.13), origin * CFrame.new(0, 4.9, 1.11), ink, false)
	sign(head, title, job, color:Lerp(Color3.new(1, 1, 1), 0.4))
	return torso
end

function Hub.build(island: Model, spawn: BasePart): (BasePart, {[ProximityPrompt]: string})
	local hub = Instance.new("Folder")
	hub.Name = "GrasslandHub"
	hub.Parent = island
	local origin = CFrame.new(spawn.Position - Vector3.new(0, 0.5, 0))
	local function build(name: string, size: Vector3, x: number, y: number, z: number, color: Color3, collision: boolean): Part
		return part(hub, name, size, origin * CFrame.new(x, y, z), color, collision)
	end

	-- The existing cloud route takes off toward positive Z. The expansion stays behind the spawn.
	for _, child in ipairs(island:GetChildren()) do
		if child:IsA("BasePart") then
			local localZ = child.Position.Z - spawn.Position.Z
			if (localZ < -37 and (child.Name == "RailWall" or child.Name == "InvisibleWall" or child.Name == "RailPost"))
				or child.Name == "Portal_2" or child.Name == "PortalPost" then
				child:Destroy()
			elseif child.Name == "SignPost" or child.Name == "SignBoard" then
				child.CFrame += Vector3.new(29, 0, 0)
			end
		end
	end

	build("Meadow", Vector3.new(286, 6, 224), 0, -3.12, -156, grass, true)
	build("FloatingCliff", Vector3.new(274, 20, 211), 0, -16, -157, stone, true)
	build("MainWalk", Vector3.new(24, 0.35, 215), 0, 0.12, -121, cream, true)
	build("PortalPlaza", Vector3.new(181, 0.35, 43), 0, 0.12, -166, cream, true)
	build("RebirthWalk", Vector3.new(105, 0.35, 15), -51, 0.12, -101, cream, true)
	for _, side in ipairs({-1, 1}) do
		for _, z in ipairs({-67, -130, -197, -242}) do
			local x = 113 * side
			build("Trunk", Vector3.new(3, 9, 3), x, 4.5, z, stone, true)
			local crown = build("Treetop", Vector3.new(13, 11, 13), x, 11.5, z, Color3.fromRGB(69, 170, 109), false)
			crown.Shape = Enum.PartType.Ball
		end
		build("SideRim", Vector3.new(2, 4, 223), 142 * side, 1.75, -156, stone, true)
	end
	build("BackRim", Vector3.new(286, 4, 2), 0, 1.75, -267, stone, true)
	for _, x in ipairs({-103, 103}) do
		build("FrontRim", Vector3.new(78, 4, 2), x, 1.75, -45, stone, true)
	end

	local dialogs: {[ProximityPrompt]: string} = {}
	local pip = npc(hub, "Pip", "Island Guide", origin * CFrame.new(9, 0.29, -25), Color3.fromRGB(245, 159, 66))
	dialogs[prompt(pip, "HubTalk", "Pip", "Talk", 12)] =
		"Sell bubbles at the green stand. Look behind the spawn for the cloud route."

	local nova = npc(hub, "Nova", "Portal Keeper", origin * CFrame.new(0, 0.29, -135), Color3.fromRGB(75, 186, 223))
	dialogs[prompt(nova, "HubTalk", "Nova", "Talk", 12)] =
		"Discover an island by climbing its clouds. Then you can use its portal here."

	local candy = npc(hub, "Mallow", "Gum Specialist", origin * CFrame.new(-49, 0, 14), Color3.fromRGB(240, 104, 163))
	dialogs[prompt(candy, "HubTalk", "Mallow", "Talk", 10)] = "Step into the gum shop to see what you can buy or equip."
	local seller = npc(hub, "Bix", "Bubble Cashier", origin * CFrame.new(49, 0, 37), Color3.fromRGB(71, 185, 112))
	dialogs[prompt(seller, "HubTalk", "Bix", "Talk", 10)] = "Stand on the green platform to sell your bubbles."

	local fountain = build("FountainBasin", Vector3.new(1.8, 26, 26), 71, 0.8, -99, cream, true)
	fountain.Shape = Enum.PartType.Cylinder
	fountain.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	local water = build("FountainWater", Vector3.new(0.7, 22, 22), 71, 1.6, -99, Color3.fromRGB(90, 206, 254), false)
	water.Shape = Enum.PartType.Cylinder
	water.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	water.Material = Enum.Material.Glass
	local sculpture = build("FountainBubble", Vector3.new(9, 9, 9), 71, 6.4, -99, Color3.fromRGB(241, 126, 221), false)
	sculpture.Shape = Enum.PartType.Ball
	sculpture.Material = Enum.Material.Glass
	sculpture.Transparency = 0.2

	local purple = Color3.fromRGB(171, 83, 229)
	build("RebirthDeck", Vector3.new(43, 0.5, 29), -77, 0.2, -101, Color3.fromRGB(241, 199, 255), true)
	build("RebirthRoof", Vector3.new(43, 2, 21), -77, 11, -105, purple, true)
	for _, x in ipairs({-95, -59}) do
		build("RebirthPillar", Vector3.new(1.8, 11, 2), x, 5.5, -105, Color3.fromRGB(120, 67, 181), true)
	end
	local merchant = npc(hub, "Rumi", "Rebirth Shop", origin * CFrame.new(-77, 0.46, -101), purple)
	prompt(merchant, "HubRebirth", "Rebirth Shop", "Shop", 12)

	local colors = { Color3.fromRGB(113, 221, 255), Color3.fromRGB(255, 118, 171), Color3.fromRGB(175, 131, 255) }
	for id = 2, #config.Worlds do
		local x = (id - 3) * 58
		local z = -170
		local tint = colors[id - 1]
		local floor = build("PortalPad" .. id, Vector3.new(24, 0.7, 14), x, 0.72, z, tint, true)
		floor.Material = Enum.Material.SmoothPlastic
		for _, offset in ipairs({-8, 8}) do
			build("PortalPillar", Vector3.new(2, 13, 3), x + offset, 7, z, tint, true)
		end
		build("PortalLintel", Vector3.new(18, 2, 3), x, 14, z, tint, true)
		local gate = build("Portal" .. id, Vector3.new(14, 11, 0.45), x, 7.35, z, tint, false)
		gate.Material = Enum.Material.Neon
		gate.Transparency = 0.68
		gate:SetAttribute("TargetWorldId", id)
		sign(gate, config.Worlds[id].Name, "Visit to unlock", tint)
		prompt(gate, "WorldPrompt", config.Worlds[id].Name, "Visit to unlock", 15)
	end
	return merchant, dialogs
end

return Hub
