--!strict
-- Builds the islands and places the original market stalls.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local assets = ServerStorage:WaitForChild("WorldAssets")

-- Bright, readable simulator lighting. Replace named effects so Studio reruns stay clean.
Lighting.ClockTime = 14
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(115, 125, 155)
Lighting.OutdoorAmbient = Color3.fromRGB(145, 155, 180)
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.4
Lighting.EnvironmentSpecularScale = 0.65
for _, effectName in ipairs({"BubbleAtmosphere", "BubbleBloom", "BubbleColor", "BubbleSunRays"}) do
	local previousEffect = Lighting:FindFirstChild(effectName)
	if previousEffect then previousEffect:Destroy() end
end
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "BubbleAtmosphere"
atmosphere.Density = 0.22
atmosphere.Offset = 0.12
atmosphere.Color = Color3.fromRGB(205, 225, 255)
atmosphere.Decay = Color3.fromRGB(105, 125, 175)
atmosphere.Glare = 0.25
atmosphere.Haze = 1.2
atmosphere.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Name = "BubbleBloom"
bloom.Intensity = 0.32
bloom.Size = 24
bloom.Threshold = 1.15
bloom.Parent = Lighting
local colorGrade = Instance.new("ColorCorrectionEffect")
colorGrade.Name = "BubbleColor"
colorGrade.Brightness = 0.025
colorGrade.Contrast = 0.08
colorGrade.Saturation = 0.16
colorGrade.TintColor = Color3.fromRGB(255, 248, 242)
colorGrade.Parent = Lighting
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "BubbleSunRays"
sunRays.Intensity = 0.035
sunRays.Spread = 0.8
sunRays.Parent = Lighting
local old = Workspace:FindFirstChild("BubbleWorld")
if old then old:Destroy() end
local root = Instance.new("Folder")
root.Name = "BubbleWorld"
root.Parent = Workspace

type World = {
	Id: number,
	Name: string,
	Center: Vector3,
	Ground: Color3,
	Rock: Color3,
	Trim: Color3,
	Accent: Color3,
	Path: Color3,
	Material: Enum.Material,
}

local rgb = Color3.fromRGB
local white = rgb(255, 255, 255)
local timber = rgb(109, 80, 57)
local cream = rgb(255, 237, 198)
local dark = rgb(40, 33, 29)
local smooth = Enum.Material.SmoothPlastic
local worlds: {World} = {
	{Id = 1, Name = "Grassland", Center = Vector3.new(0, 35, 0), Ground = rgb(99, 157, 67), Rock = rgb(148, 91, 51), Trim = rgb(146, 182, 89), Accent = rgb(135, 219, 83), Path = rgb(222, 187, 132), Material = Enum.Material.Grass},
	{Id = 2, Name = "Frozen World", Center = Vector3.new(280, 56, 0), Ground = rgb(202, 234, 248), Rock = rgb(79, 122, 161), Trim = rgb(239, 250, 255), Accent = rgb(114, 229, 255), Path = rgb(159, 207, 226), Material = Enum.Material.Snow},
	{Id = 3, Name = "Candy World", Center = Vector3.new(560, 80, 0), Ground = rgb(243, 150, 177), Rock = rgb(142, 80, 111), Trim = rgb(255, 208, 195), Accent = rgb(255, 126, 189), Path = rgb(255, 229, 185), Material = smooth},
	{Id = 4, Name = "Galaxy World", Center = Vector3.new(840, 110, 0), Ground = rgb(91, 83, 154), Rock = rgb(51, 45, 93), Trim = rgb(143, 123, 204), Accent = rgb(138, 230, 255), Path = rgb(184, 167, 226), Material = Enum.Material.Slate},
}

local function part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material, solid: boolean, shape: Enum.PartType?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored = true
	item.Shape = shape or Enum.PartType.Block
	item.Size = size
	item.CFrame = frame
	item.Color = color
	item.Material = material
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.CanCollide = solid
	item.CanTouch = false
	item.CanQuery = solid
	item.Parent = parent
	return item
end

local function disc(parent: Instance, name: string, pos: Vector3, diameter: number, height: number, color: Color3, material: Enum.Material, solid: boolean): Part
	return part(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color, material, solid, Enum.PartType.Cylinder)
end

local function orb(parent: Instance, name: string, pos: Vector3, size: Vector3, color: Color3, material: Enum.Material): Part
	return part(parent, name, size, CFrame.new(pos), color, material, false, Enum.PartType.Ball)
end

local function beam(parent: Instance, name: string, from: Vector3, to: Vector3, width: number, height: number, color: Color3, material: Enum.Material): Part
	return part(parent, name, Vector3.new(width, height, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material, false)
end

local function sign(parent: Instance, name: string, text: string, frame: CFrame, width: number, color: Color3)
	local board = part(parent, name, Vector3.new(width, 3.5, 0.7), frame, timber, Enum.Material.WoodPlanks, false)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(640, 144)
	surface.LightInfluence = 0.15
	surface.Parent = board

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromScale(0.045, 0.12)
	label.Size = UDim2.fromScale(0.91, 0.76)
	label.BackgroundColor3 = dark
	label.BorderSizePixel = 0
	label.TextColor3 = color
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = surface

	local border = Instance.new("UIStroke")
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Color = color
	border.Thickness = 3
	border.Parent = label
end

local function lantern(parent: Instance, pos: Vector3, color: Color3)
	part(parent, "LanternPost", Vector3.new(0.8, 6, 0.8), CFrame.new(pos + Vector3.new(0, 3, 0)), timber, Enum.Material.Wood, true)
	local lamp = orb(parent, "LanternGlass", pos + Vector3.new(0, 6.4, 0), Vector3.new(1.5, 1.8, 1.5), color, Enum.Material.Neon)
	disc(parent, "LanternCap", pos + Vector3.new(0, 7.35, 0), 1.9, 0.4, timber, Enum.Material.Metal, false)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 0.55
	light.Range = 13
	light.Parent = lamp
end

local function makeIsland(parent: Model, world: World, random: Random)
	local center = world.Center
	disc(parent, "IslandFloor", center - Vector3.new(0, 2, 0), 170, 4, world.Ground, world.Material, true)
	disc(parent, "RockShoulder", center - Vector3.new(0, 8, 0), 163, 12, world.Rock, Enum.Material.Slate, false)
	disc(parent, "LowerRock", center - Vector3.new(0, 20, 0), 128, 17, world.Rock:Lerp(dark, 0.23), Enum.Material.Slate, false)
	disc(parent, "IslandRoot", center - Vector3.new(0, 33, 0), 76, 16, world.Rock:Lerp(dark, 0.38), Enum.Material.Slate, false)
	for index = 0, 23 do
		local angle = index * math.pi / 12
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local position = center + direction * random:NextNumber(72, 76)
		local drop = random:NextNumber(13, 27)
		local orientation = CFrame.Angles(0, -angle, random:NextNumber(-0.32, -0.15))
		local color = world.Rock:Lerp(dark, random:NextNumber(0.03, 0.25))
		part(parent, "CliffFace", Vector3.new(18, drop, 25),
			CFrame.new(position - Vector3.new(0, drop / 2 + 1, 0)) * orientation, color, Enum.Material.Slate, false)
		part(parent, "CliffLip", Vector3.new(18, 0.8, 25),
			CFrame.new(position - Vector3.new(0, 0.45, 0)) * CFrame.Angles(0, -angle, 0), world.Trim, world.Material, false)
	end

	for index = 0, 8 do
		local angle = math.rad(21 + index * 17)
		local height = random:NextNumber(9, 21)
		local radius = random:NextNumber(68, 73)
		local pos = center + Vector3.new(math.cos(angle) * radius, 0, -math.sin(angle) * radius)
		local rotation = CFrame.Angles(0, angle, 0)
		local width = random:NextNumber(10, 15)
		part(parent, "Ridge", Vector3.new(width, height, width), CFrame.new(pos + Vector3.new(0, height / 2, 0)) * rotation,
			world.Rock:Lerp(world.Ground, random:NextNumber(0, 0.22)), Enum.Material.Slate, true)
		part(parent, "RidgeCap", Vector3.new(width + 0.3, 1.05, width + 0.3), CFrame.new(pos + Vector3.new(0, height, 0)) * rotation,
			world.Trim, world.Material, false)
	end
end

local function foliage(parent: Model, world: World, position: Vector3, size: number, random: Random)
	local color = world.Trim
	local height = size * 1.15
	local trunk = if world.Id == 3 then rgb(188, 102, 122) else timber
	part(parent, "Trunk", Vector3.new(size * 0.27, height, size * 0.27), CFrame.new(position + Vector3.new(0, height / 2, 0)), trunk, Enum.Material.Wood, true)
	for index = 1, 5 do
		local angle = index * math.pi * 0.4
		local offset = Vector3.new(math.cos(angle) * size * 0.25, height + random:NextNumber(-0.14, 0.25) * size, math.sin(angle) * size * 0.25)
		local tint = random:NextNumber(0.15, 0.65)
		local leaf = if world.Id == 1 then rgb(41, 118, 65):Lerp(color, tint) else color:Lerp(world.Accent, tint)
		orb(parent, "Canopy", position + offset, Vector3.new(0.82, 0.63, 0.78) * size, leaf, world.Material)
	end
	orb(parent, "Crown", position + Vector3.new(0, height + size * 0.35, 0), Vector3.new(0.79, 0.57, 0.79) * size, color, world.Material)
end

local function makeLandmark(parent: Model, world: World)
	local pos = world.Center + Vector3.new(0, 0, -36)
	if world.Id == 1 then
		disc(parent, "FountainBase", pos + Vector3.new(0, 0.43, 0), 25, 0.85, world.Path, Enum.Material.Cobblestone, true)
		disc(parent, "FountainBasin", pos + Vector3.new(0, 0.95, 0), 20, 0.5, timber, Enum.Material.Slate, true)
		disc(parent, "FountainWater", pos + Vector3.new(0, 1.24, 0), 18.8, 0.13, rgb(80, 195, 216), Enum.Material.Glass, false)
		disc(parent, "FountainColumn", pos + Vector3.new(0, 3, 0), 3.3, 4.8, cream, Enum.Material.Slate, true)
		disc(parent, "FountainCrown", pos + Vector3.new(0, 5.45, 0), 7, 0.55, cream, Enum.Material.Slate, false)
		orb(parent, "FountainBubble", pos + Vector3.new(0, 8.1, 0), Vector3.one * 4.5, rgb(255, 149, 204), Enum.Material.Glass)
		for index = 0, 7 do
			local angle = index * math.pi / 4
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			for drop = 1, 4 do
				local lift = math.sin(drop * math.pi / 5) * 3.2
				orb(parent, "WaterDroplet", pos + direction * (drop * 1.75) + Vector3.new(0, 1.5 + lift, 0),
					Vector3.one * (0.52 - drop * 0.055), rgb(128, 233, 242), Enum.Material.Glass)
			end
		end
	elseif world.Id == 2 then
		disc(parent, "GlacierPool", pos + Vector3.new(0, 0.16, 0), 29, 0.3, rgb(111, 204, 243), Enum.Material.Ice, true)
		for index = -3, 3 do
			local height = 16 + (3 - math.abs(index)) * 3.3
			local frame = CFrame.new(pos + Vector3.new(index * 3.7, height / 2, -3 + math.abs(index)))
				* CFrame.Angles(0, index * 0.32, index * 0.1)
			part(parent, "GlacierSpire", Vector3.new(4.2, height, 5.1), frame,
				world.Accent:Lerp(world.Trim, math.abs(index) * 0.19), Enum.Material.Ice, true)
			orb(parent, "SnowDrift", pos + Vector3.new(index * 3.9, 0.9, 5), Vector3.new(7, 2.8, 7), world.Trim, Enum.Material.Snow)
		end
	elseif world.Id == 3 then
		for tier = 0, 2 do
			local diameter = 25 - tier * 6
			local height = 1.9 + tier * 4.1
			disc(parent, "CakeTier", pos + Vector3.new(0, height, 0), diameter, 3.8, world.Ground, smooth, true)
			disc(parent, "CakeIcing", pos + Vector3.new(0, height + 1.9, 0), diameter + 0.55, 0.8, world.Trim, smooth, false)
		end
		for _, x in {-17, 0, 17} do
			local base = pos + Vector3.new(x, if x == 0 then 12 else 0, -1)
			part(parent, "LollipopStick", Vector3.new(1.1, 9, 1.1), CFrame.new(base + Vector3.new(0, 4.5, 0)), cream, smooth, false)
			part(parent, "Lollipop", Vector3.new(1.3, 7, 7),
				CFrame.new(base + Vector3.new(0, 10.5, 0)) * CFrame.Angles(0, math.pi / 2, 0), world.Accent, smooth, false, Enum.PartType.Cylinder)
			for index = 0, 9 do
				local angle = index * math.pi * 0.2
				orb(parent, "SugarPearl", base + Vector3.new(math.cos(angle) * 2.55, 10.5 + math.sin(angle) * 2.55, 0.72),
					Vector3.one * 0.7, cream, smooth)
			end
		end
	else
		disc(parent, "ObservatoryBase", pos + Vector3.new(0, 0.55, 0), 30, 1.1, world.Trim, Enum.Material.Metal, true)
		disc(parent, "ObservatoryLens", pos + Vector3.new(0, 1.15, 0), 21, 0.3, world.Rock, Enum.Material.Glass, false)
		local orbit = CFrame.new(pos + Vector3.new(0, 14, 0)) * CFrame.Angles(0.35, 0, 0.52)
		orb(parent, "Planet", orbit.Position, Vector3.one * 14, rgb(145, 115, 245), smooth)
		for index = 0, 23 do
			local angle = index * math.pi / 12
			local a = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 11
			local b = Vector3.new(math.cos(angle + math.pi / 12), 0, math.sin(angle + math.pi / 12)) * 11
			beam(parent, "PlanetOrbit", orbit:PointToWorldSpace(a), orbit:PointToWorldSpace(b), 0.65, 0.65, world.Accent, Enum.Material.Neon)
		end
		for _, offset in {Vector3.new(-16, 19, 3), Vector3.new(15, 9, -8), Vector3.new(18, 23, 4)} do
			orb(parent, "Moon", pos + offset, Vector3.one * 3.2, cream, Enum.Material.Neon)
		end
	end
end

local function makeMarketStall(parent: Model, world: World, buying: boolean)
	local templateName = if buying then "GumStall" else "SellStall"
	local template = assets:FindFirstChild(templateName)
	assert(template and template:IsA("Model"), "Missing market model: " .. templateName)
	local stall = template:Clone()
	stall.Name = if buying then "GumShopStall" else "SellStation"
	local origin = world.Center + Vector3.new(if buying then -32 else 32, 0.24, 29)
	local frame = CFrame.new(origin)
	local zoneColor = if buying then rgb(92, 174, 255) else rgb(70, 225, 179)

	for _, item in stall:GetDescendants() do
		if item:IsA("BasePart") then
			item.CFrame = frame * item.CFrame
			local shade = item:GetAttribute("RoofShade")
			if world.Id ~= 1 and shade == "Light" then
				item.Color = world.Trim
			elseif world.Id ~= 1 and shade == "Dark" then
				item.Color = world.Accent:Lerp(world.Rock, 0.45)
			end
		end
	end

	part(stall, "MarketFooting", Vector3.new(26, 0.4, 26), frame * CFrame.new(0, -0.04, -2), world.Path, Enum.Material.Cobblestone, true)
	sign(stall, if buying then "GumShopSign" else "SellSign", if buying then "GUM SHOP" else "SELL BUBBLES",
		frame * CFrame.new(0, 15.4, -11.8), 18.2, zoneColor)

	local entrance = origin + Vector3.new(0, 0, -13.7)
	disc(stall, "MarketEntrance", entrance + Vector3.new(0, 0.03, 0), 17, 0.26, zoneColor, smooth, true)
	disc(stall, "MarketInlay", entrance + Vector3.new(0, 0.18, 0), 13, 0.11, zoneColor:Lerp(white, 0.47), smooth, false)
	for _, x in {-8.7, 8.7} do
		lantern(stall, entrance + Vector3.new(x, 0, -2.3), if buying then cream else zoneColor)
	end

	local zone = part(stall, if buying then "ShopZone" else "SellZone", Vector3.new(22, 8, 12),
		CFrame.new(entrance + Vector3.new(0, 3.1, 0)), white, smooth, false)
	zone.Transparency = 1
	zone.CastShadow = false
	zone.CanTouch = not buying
	stall.Parent = parent
	if buying then CollectionService:AddTag(zone, "GumShopZone") end
end

local function makePortal(parent: Model, pos: Vector3, destination: World, direction: number)
	local base = disc(parent, "Portal_" .. destination.Id, pos + Vector3.new(0, 0.52, 0), 15, 0.62, destination.Accent, smooth, true)
	base:SetAttribute("TargetWorldId", destination.Id)
	local face = CFrame.lookAt(pos, pos + Vector3.new(direction, 0, 0))
	for _, side in {-1, 1} do
		local foot = face:PointToWorldSpace(Vector3.new(side * 6.7, 2.1, 0))
		local pier = face:PointToWorldSpace(Vector3.new(side * 6.7, 5.9, 0))
		part(parent, "PortalFoot", Vector3.new(3.3, 4.2, 3.8), CFrame.new(foot) * face.Rotation, destination.Rock, Enum.Material.Slate, false)
		part(parent, "PortalPier", Vector3.new(2.4, 6.5, 2.9), CFrame.new(pier) * face.Rotation, destination.Trim, Enum.Material.Slate, false)
	end
	for index = 0, 7 do
		local a = index * math.pi / 8
		local b = (index + 1) * math.pi / 8
		local from = face:PointToWorldSpace(Vector3.new(math.cos(a) * 6.7, 8.6 + math.sin(a) * 6.7, 0))
		local to = face:PointToWorldSpace(Vector3.new(math.cos(b) * 6.7, 8.6 + math.sin(b) * 6.7, 0))
		beam(parent, "PortalArch", from, to, 2.3, 2.4, destination.Trim, Enum.Material.Slate)
		local glow = (from + to) / 2 + face.LookVector * 1.25
		orb(parent, "PortalGem", glow, Vector3.one, destination.Accent, Enum.Material.Neon)
	end
	sign(parent, "PortalSign", destination.Name, face * CFrame.new(0, 16.8, -0.25), 16.5, destination.Accent)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WorldPrompt"
	prompt.ActionText = if direction == -1 then "Unlock / Travel" else "Travel Back"
	prompt.ObjectText = destination.Name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
end

local sceneryPositions = {
	Vector3.new(-54, 0, -33), Vector3.new(-40, 0, -46), Vector3.new(42, 0, -45),
	Vector3.new(55, 0, -31), Vector3.new(-43, 0, 52), Vector3.new(42, 0, 52),
	Vector3.new(-19, 0, 61), Vector3.new(19, 0, 61),
}

for _, world in worlds do
	local center = world.Center
	local random = Random.new(1284 + world.Id)
	local island = Instance.new("Model")
	island.Name = "World_" .. world.Id .. "_" .. world.Name:gsub("%W", "")
	island:SetAttribute("WorldId", world.Id)
	island.Parent = root

	makeIsland(island, world, random)
	disc(island, "PlazaBorder", center + Vector3.new(0, 0.25, 0), 32, 0.5, timber, Enum.Material.WoodPlanks, true)
	disc(island, "SpawnPlaza", center + Vector3.new(0, 0.44, 0), 28, 0.25, world.Path, Enum.Material.Cobblestone, true)
	local spawn = part(island, "WorldSpawn_" .. world.Id, Vector3.new(8, 1, 8), CFrame.new(center + Vector3.new(0, 1.1, 0)),
		world.Ground, smooth, false)
	spawn.Transparency = 1
	spawn:SetAttribute("WorldId", world.Id)
	if world.Id == 1 then
		local main = Instance.new("SpawnLocation")
		main.Name = "MainSpawn"
		main.Size = spawn.Size
		main.CFrame = spawn.CFrame
		main.Anchored = true
		main.Neutral = true
		main.Duration = 0
		main.Transparency = 1
		main.CanCollide = false
		main.Parent = island
	end

	for _, stop in {Vector3.new(-32, 0, 15), Vector3.new(32, 0, 15), Vector3.new(0, 0, -24)} do
		local floor = center + Vector3.new(0, 0.05, 0)
		beam(island, "PlazaPath", floor, floor + stop, 8, 0.1, world.Path, Enum.Material.Cobblestone)
	end
	for _, side in {-1, 1} do
		local destination = worlds[world.Id + side]
		if destination then
			local floor = center + Vector3.new(0, 0.05, 0)
			beam(island, "PortalPath", floor, floor + Vector3.new(side * 59, 0, 0), 8, 0.1, world.Path, Enum.Material.Cobblestone)
			makePortal(island, center + Vector3.new(side * 59, 0, 0), destination, -side)
		end
		lantern(island, center + Vector3.new(side * 13, 0, -12), cream)
	end

	makeLandmark(island, world)
	for _, offset in sceneryPositions do
		local pos = center + offset
		local size = random:NextNumber(5.6, 9.2)
		if world.Id == 4 then
			part(island, "MeteorCrystal", Vector3.new(size * 0.63, size * 1.6, size * 0.64),
				CFrame.new(pos + Vector3.new(0, size * 0.7, 0)) * CFrame.Angles(0.16, size, 0.22), world.Trim, Enum.Material.Glass, true)
			orb(island, "MeteorGlow", pos + Vector3.new(0, size * 1.68, 0), Vector3.one * 1.75, world.Accent, Enum.Material.Neon)
		else
			foliage(island, world, pos, size, random)
		end
		for index = 1, 4 do
			local spread = Vector3.new(random:NextNumber(-6, 6), 0.6, random:NextNumber(-5, 5))
			orb(island, "GroundCover", pos + spread, Vector3.new(2, 1.1, 1.8),
				if index % 2 == 0 then world.Trim else world.Accent, world.Material)
		end
	end

	sign(island, "IslandSign", world.Name, CFrame.lookAt(center + Vector3.new(0, 6.5, -22), center + Vector3.new(0, 6.5, 0)),
		19, world.Trim:Lerp(white, 0.3))
	local groundY = center.Y
	for _, x in {-7.8, 7.8} do
		part(island, "IslandSignPost", Vector3.new(0.6, 6.3, 0.7),
			CFrame.new(center.X + x, groundY + 3.15, center.Z - 22.4), timber, Enum.Material.Wood, false)
	end

	makeMarketStall(island, world, true)
	makeMarketStall(island, world, false)

	for index = 1, 5 do
		local cloud = center + Vector3.new(random:NextNumber(-96, 96), random:NextNumber(-37, -29), random:NextNumber(-82, 82))
		for cluster = -1, 1 do
			local fluff = orb(island, "Cloud", cloud + Vector3.new(cluster * 8, random:NextNumber(-1, 2), 0),
				Vector3.new(21, 5.8, 12) * random:NextNumber(0.7, 1.1), white:Lerp(world.Trim, 0.22), smooth)
			fluff.Transparency = 0.26 + index * 0.035
			fluff.CastShadow = false
		end
	end
end
