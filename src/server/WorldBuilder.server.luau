--!strict
-- Procedural low-poly world builder. Creates the four island zones and portal prompts.
-- Run as a Script in ServerScriptService. Safe to re-run: generated folder is replaced.

local Workspace = game:GetService("Workspace")

local ROOT_NAME = "BubbleWorld"
local oldWorld = Workspace:FindFirstChild(ROOT_NAME)
if oldWorld then oldWorld:Destroy() end

local root = Instance.new("Folder")
root.Name = ROOT_NAME
root.Parent = Workspace

local WORLDS = {
	{Id = 1, Name = "Grassland", Center = Vector3.new(0, 0, 0), Top = Color3.fromRGB(92, 190, 92), Rock = Color3.fromRGB(91, 83, 76), Accent = Color3.fromRGB(255, 190, 80), Material = Enum.Material.Grass},
	{Id = 2, Name = "Frozen World", Center = Vector3.new(270, 18, 0), Top = Color3.fromRGB(160, 220, 245), Rock = Color3.fromRGB(105, 145, 170), Accent = Color3.fromRGB(100, 220, 255), Material = Enum.Material.Ice},
	{Id = 3, Name = "Candy World", Center = Vector3.new(540, 42, 0), Top = Color3.fromRGB(255, 160, 205), Rock = Color3.fromRGB(175, 95, 150), Accent = Color3.fromRGB(255, 225, 110), Material = Enum.Material.SmoothPlastic},
	{Id = 4, Name = "Galaxy World", Center = Vector3.new(810, 72, 0), Top = Color3.fromRGB(90, 70, 155), Rock = Color3.fromRGB(42, 35, 85), Accent = Color3.fromRGB(90, 220, 255), Material = Enum.Material.Neon},
}

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Shape = shape or Enum.PartType.Block
	part.Parent = parent
	return part
end

local function makeTree(parent: Instance, position: Vector3, palette, style: number)
	local trunk = makePart(parent, "TreeTrunk", Vector3.new(3, 12, 3), CFrame.new(position + Vector3.new(0, 6, 0)), Color3.fromRGB(105, 73, 48), Enum.Material.Wood)
	trunk.CanCollide = true
	if style == 2 then
		local crown = makePart(parent, "CandyCrown", Vector3.new(12, 12, 12), CFrame.new(position + Vector3.new(0, 15, 0)), palette.Accent, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		crown.CanCollide = true
	else
		local crown = makePart(parent, "TreeCrown", Vector3.new(13, 13, 13), CFrame.new(position + Vector3.new(0, 15, 0)), palette.Accent, Enum.Material.Grass, Enum.PartType.Ball)
		crown.CanCollide = true
	end
end

local function makePortal(parent: Instance, world, position: Vector3, destinationId: number, actionText: string)
	local pad = makePart(parent, "Portal_" .. tostring(destinationId), Vector3.new(15, 1.2, 15), CFrame.new(position), world.Accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	pad.CanCollide = true
	pad:SetAttribute("TargetWorldId", destinationId)

	local ring = makePart(parent, "PortalRing", Vector3.new(2, 13, 13), CFrame.new(position + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90)), world.Accent, Enum.Material.Neon, Enum.PartType.Cylinder)
	ring.CanCollide = false
	ring.Transparency = 0.18

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WorldPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = WORLDS[destinationId].Name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
end

for _, world in ipairs(WORLDS) do
	local model = Instance.new("Model")
	model.Name = "World_" .. tostring(world.Id) .. "_" .. world.Name:gsub("%W", "")
	model:SetAttribute("WorldId", world.Id)
	model.Parent = root

	local center = world.Center
	local rock = makePart(model, "FloatingRock", Vector3.new(170, 34, 170), CFrame.new(center + Vector3.new(0, -15, 0)) * CFrame.Angles(0, 0, math.rad(90)), world.Rock, Enum.Material.Slate, Enum.PartType.Cylinder)
	rock.CanCollide = true
	local grass = makePart(model, "IslandSurface", Vector3.new(158, 8, 158), CFrame.new(center - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), world.Top, world.Material, Enum.PartType.Cylinder)
	grass.CanCollide = true

	-- A simple raised spawn plaza and landmark make each island easy to read.
	local plaza = makePart(model, "SpawnPlaza", Vector3.new(44, 1.5, 44), CFrame.new(center + Vector3.new(0, 3, 0)), world.Accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	plaza.CanCollide = true
	plaza.Transparency = 0.08

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "WorldSpawn_" .. tostring(world.Id)
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(center + Vector3.new(0, 5, 0))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = model
	spawn:SetAttribute("WorldId", world.Id)

	-- Decorative props are anchored and deliberately low-part-count.
	local offsets = {
		Vector3.new(-48, 3, -38), Vector3.new(48, 3, -38),
		Vector3.new(-48, 3, 38), Vector3.new(48, 3, 38),
		Vector3.new(-62, 3, 0), Vector3.new(62, 3, 0),
	}
	for index, offset in ipairs(offsets) do
		if world.Id == 3 then
			makeTree(model, center + offset, world, 2)
		elseif world.Id ~= 4 then
			makeTree(model, center + offset, world, 1)
		else
			local crystal = makePart(model, "Crystal", Vector3.new(7, 18 + (index % 3) * 4, 7), CFrame.new(center + offset + Vector3.new(0, 10, 0)) * CFrame.Angles(0, math.rad(index * 25), math.rad(8)), world.Accent, Enum.Material.Neon)
			crystal.CanCollide = true
		end
	end

	-- Portal to the next world. Earlier worlds receive a return portal on the far side.
	if world.Id < #WORLDS then
		makePortal(model, world, center + Vector3.new(52, 4, 0), world.Id + 1, "Unlock / Travel")
	end
	if world.Id > 1 then
		makePortal(model, world, center + Vector3.new(-52, 4, 0), world.Id - 1, "Travel Back")
	end

	local sign = makePart(model, "WorldSign", Vector3.new(2, 18, 2), CFrame.new(center + Vector3.new(0, 12, -58)), world.Accent, Enum.Material.SmoothPlastic)
	sign.CanCollide = false
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(240, 54)
	billboard.StudsOffset = Vector3.new(0, 12, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = world.Name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = billboard
end

-- Bridges connect the islands visually; locked portal prompts remain the progression gate.
for index = 1, #WORLDS - 1 do
	local a = WORLDS[index].Center
	local b = WORLDS[index + 1].Center
	local midpoint = (a + b) / 2
	local bridge = makePart(root, "Bridge_" .. tostring(index), Vector3.new(26, 3, (b - a).Magnitude - 105), CFrame.lookAt(midpoint + Vector3.new(0, -2, 0), b), WORLDS[index].Accent, Enum.Material.SmoothPlastic)
	bridge.CanCollide = true
end

-- Starter island interaction zones used by the shop and sell scripts.
local starter = WORLDS[1].Center
local shopZone = makePart(root, "ShopZone", Vector3.new(34, 12, 28), CFrame.new(starter + Vector3.new(-42, 6, 24)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
shopZone.Transparency = 1
shopZone.CanCollide = false
shopZone.CanTouch = false

local sellZone = makePart(root, "SellZone", Vector3.new(26, 8, 24), CFrame.new(starter + Vector3.new(42, 4, 24)), Color3.fromRGB(70, 255, 150), Enum.Material.Neon)
sellZone.Transparency = 0.45
sellZone.CanCollide = false
sellZone.CanTouch = true

print("[BubbleWorld] Generated four islands, bridges, portals, and starter zones.")
