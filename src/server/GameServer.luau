--!strict
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ProfileStore = require(script.Parent:WaitForChild("ProfileStore"))
local AUTOSAVE_INTERVAL = 60
local SELL_COOLDOWN = 0.5
local SHOP_COOLDOWN = 0.25
local WORLD_COOLDOWN = 1
local REBIRTH_COOLDOWN = 2

type Session = {
	Profile: ProfileStore.Profile,
	Cooldowns: {[string]: number},
	CloudStep: number,
	InSellZone: boolean,
}
type Island = { Spawn: BasePart, Shop: BasePart, Sell: BasePart }
type Cloud = { World: number, Step: number }

local sessions: {[Player]: Session} = {}
local worldFolder = workspace:WaitForChild("BubbleWorld")
local islands: {[number]: Island} = {}
local islandIds: {[Instance]: number} = {}
local clouds: {[BasePart]: Cloud} = {}
local routeLengths: {[number]: number} = {}

local function findPart(parent: Instance, name: string): BasePart
	local part = parent:FindFirstChild(name, true)
	assert(part and part:IsA("BasePart"), ("Missing %s in %s"):format(name, parent:GetFullName()))
	return part
end

for _, model in ipairs(worldFolder:GetChildren()) do
	local id = model:GetAttribute("WorldId")
	if model:IsA("Model") and type(id) == "number" and config.Worlds[id] then
		assert(not islands[id], "Duplicate WorldId in BubbleWorld")
		islands[id] = {
			Spawn = findPart(model, "WorldSpawn_" .. id),
			Shop = findPart(model, "ShopZone"),
			Sell = findPart(model, "SellZone"),
		}
		islandIds[model] = id
	end
end

for id = 1, #config.Worlds do
	assert(islands[id], "Missing island " .. id)
	if id == #config.Worlds then break end
	local chains = worldFolder:WaitForChild("CloudChains")
	local chain = chains:FindFirstChild(("Chain_%d_%d"):format(id, id + 1))
	assert(chain, "Missing cloud chain for island " .. id)
	local count = 0
	for _, model in ipairs(chain:GetChildren()) do
		local step = tonumber(model.Name:match("^Cloud_(%d+)$"))
		if step then
			clouds[findPart(model, "CloudPlatform")] = { World = id, Step = step }
			count += 1
		end
	end
	assert(count > 0, "Empty cloud chain for island " .. id)
	for step = 1, count do
		assert(chain:FindFirstChild("Cloud_" .. step), "Missing cloud " .. step)
	end
	routeLengths[id] = count
end

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end
assert(remotesFolder:IsA("Folder"), "ReplicatedStorage.Remotes must be a Folder")
local remotes = remotesFolder

local function getOrCreateRemote(name: string): RemoteEvent
	local existing = remotes:FindFirstChild(name)
	if existing then
		assert(existing:IsA("RemoteEvent"), name .. " must be a RemoteEvent")
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local blowEvent = getOrCreateRemote("BlowBubble")
local sellBubblesEvent = getOrCreateRemote("SellBubbles")
local shopActionEvent = getOrCreateRemote("ShopAction")
local worldActionEvent = getOrCreateRemote("WorldAction")
local rebirthActionEvent = getOrCreateRemote("RebirthAction")
local toastEvent = getOrCreateRemote("Toast")

local green = Color3.fromRGB(105, 235, 155)
local blue = Color3.fromRGB(115, 205, 255)
local orange = Color3.fromRGB(255, 170, 90)

local function notify(player: Player, title: string, message: string, color: Color3)
	toastEvent:FireClient(player, title, message, color)
end

local function activeSession(player: Player): Session?
	local session = sessions[player]
	if not session or session.Profile.Closing then return nil end
	local expires = session.Profile.Expires
	return if not expires or expires > os.time() then session else nil
end

local function canPerform(session: Session, action: string, cooldown: number): boolean
	local now = os.clock()
	local previous = session.Cooldowns[action]
	if previous and now - previous < cooldown then return false end
	session.Cooldowns[action] = now
	return true
end

local function getCharacter(player: Player): (Model?, BasePart?, Humanoid?)
	local character = player.Character
	if not character then return nil, nil, nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return nil, nil, nil
	end
	return character, root, humanoid
end

local function getCoinMultiplier(data: ProfileStore.Data): number
	return config.Worlds[data.CurrentWorldId].CoinMultiplier * (1 + data.Rebirths * 0.5)
end

local function formatIds(ids: {[number]: boolean}, total: number): string
	local selected = {}
	for id = 1, total do
		if ids[id] then table.insert(selected, tostring(id)) end
	end
	return table.concat(selected, ",")
end

local function syncPlayerState(player: Player, data: ProfileStore.Data)
	local gum = config.Gums[data.GumLevel]
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("BubbleSize", data.BubbleSize)
	player:SetAttribute("MaxBubble", gum.MaxBubble)
	player:SetAttribute("GumSellMultiplier", gum.SellMultiplier)
	player:SetAttribute("GumName", gum.Name)
	player:SetAttribute("GumLevel", data.GumLevel)
	player:SetAttribute("GumJumpPower", gum.JumpPower)
	player:SetAttribute("OwnedGums", formatIds(data.OwnedGums, #config.Gums))
	player:SetAttribute("PlayerLevel", data.PlayerLevel)
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("XPToNext", config.xpRequired(data.PlayerLevel))
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("CoinMultiplier", getCoinMultiplier(data))
	player:SetAttribute("UnlockedWorlds", formatIds(data.UnlockedWorlds, #config.Worlds))
	player:SetAttribute("CurrentWorldId", data.CurrentWorldId)

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		for name, amount in pairs({ Level = data.PlayerLevel, Coins = data.Coins, Bubbles = data.BubbleSize, Rebirths = data.Rebirths }) do
			local value = stats:FindFirstChild(name)
			if value and value:IsA("IntValue") then value.Value = amount end
		end
	end
end

local function applyJumpPower(humanoid: Humanoid, data: ProfileStore.Data)
	humanoid.UseJumpPower = true
	humanoid.JumpPower = config.Gums[data.GumLevel].JumpPower
end

local function updateXP(data: ProfileStore.Data, amount: number): boolean
	local previousLevel = data.PlayerLevel
	data.XP += amount
	while data.PlayerLevel < config.MaxLevel do
		local needed = config.xpRequired(data.PlayerLevel)
		if data.XP < needed then break end
		data.XP -= needed
		data.PlayerLevel += 1
	end
	data.XP = math.min(data.XP, config.xpRequired(data.PlayerLevel) - 1)
	return data.PlayerLevel > previousLevel
end

local function syncXPReward(player: Player, data: ProfileStore.Data, amount: number)
	local leveledUp = updateXP(data, amount)
	syncPlayerState(player, data)
	if leveledUp then notify(player, "LEVEL UP!", "You reached level " .. data.PlayerLevel, green) end
end

local function addCoins(data: ProfileStore.Data, amount: number)
	data.Coins = math.min(data.Coins + amount, config.MaxCoins)
end

local function isInZone(root: BasePart, zone: BasePart): boolean
	local position = zone.CFrame:PointToObjectSpace(root.Position)
	local half = zone.Size * 0.5
	return math.abs(position.X) <= half.X and math.abs(position.Z) <= half.Z
		and math.abs(position.Y) <= half.Y + 2
end

local function sellBubble(player: Player, session: Session, root: BasePart)
	local data = session.Profile.Data
	if data.BubbleSize <= 0 or not isInZone(root, islands[data.CurrentWorldId].Sell)
		or not canPerform(session, "Sell", SELL_COOLDOWN) then
		return
	end
	local gum = config.Gums[data.GumLevel]
	local world = config.Worlds[data.CurrentWorldId]
	local reward = math.floor(data.BubbleSize * gum.SellMultiplier * getCoinMultiplier(data))
	local xp = math.floor(world.FullSaleXP * data.BubbleSize / gum.MaxBubble)
	addCoins(data, reward)
	data.BubbleSize = 0
	notify(player, "BUBBLES SOLD!", "+" .. reward .. " Coins", green)
	syncXPReward(player, data, xp)
end

blowEvent.OnServerEvent:Connect(function(player)
	local session = activeSession(player)
	local _, root = getCharacter(player)
	if not session or not root or not canPerform(session, "Blow", config.BlowCooldown) then return end
	local data = session.Profile.Data
	local gum = config.Gums[data.GumLevel]
	if data.BubbleSize >= gum.MaxBubble then return end
	data.BubbleSize = math.min(gum.MaxBubble, data.BubbleSize + gum.Power)
	if data.BubbleSize == gum.MaxBubble and canPerform(session, "FullHint", 8) then
		notify(player, "BUBBLE FULL!", "Head to the sell platform to cash in!", orange)
	end
	syncXPReward(player, data, config.Worlds[data.CurrentWorldId].BlowXP)
end)

sellBubblesEvent.OnServerEvent:Connect(function(player)
	local session = activeSession(player)
	local _, root = getCharacter(player)
	if session and root then sellBubble(player, session, root) end
end)

shopActionEvent.OnServerEvent:Connect(function(player, gumId)
	local session = activeSession(player)
	if not session or type(gumId) ~= "number" or gumId % 1 ~= 0 then return end
	local gum = config.Gums[gumId]
	local _, root, humanoid = getCharacter(player)
	if not gum or not root or not humanoid then return end
	local data = session.Profile.Data
	if not isInZone(root, islands[data.CurrentWorldId].Shop)
		or not canPerform(session, "Shop", SHOP_COOLDOWN) or data.GumLevel == gumId then
		return
	end

	if not data.OwnedGums[gumId] then
		if gum.World ~= data.CurrentWorldId or not data.UnlockedWorlds[gum.World] then return end
		local prerequisite = config.shopPrerequisite(gumId)
		if prerequisite and not data.OwnedGums[prerequisite] then
			notify(player, "GUM LOCKED", "Buy " .. config.Gums[prerequisite].Name .. " first.", orange)
			return
		end
		if data.Coins < gum.Price then
			notify(player, "NEED MORE COINS", gum.Name .. " costs " .. gum.Price .. " Coins.", orange)
			return
		end
		data.Coins -= gum.Price
		data.OwnedGums[gumId] = true
	end

	data.GumLevel = gumId
	session.CloudStep = 0
	data.BubbleSize = math.min(data.BubbleSize, gum.MaxBubble)
	applyJumpPower(humanoid, data)
	syncPlayerState(player, data)
	notify(player, "GUM EQUIPPED!", gum.Name .. " equipped • +" .. gum.Power .. " power", gum.Color)
end)

local function clearPositionState(player: Player, session: Session)
	session.CloudStep = 0
	session.InSellZone = false
	player:SetAttribute("NearShopZone", false)
	player:SetAttribute("NearSellZone", false)
end

local function teleportToWorld(player: Player, session: Session, worldId: number): boolean
	local character, root = getCharacter(player)
	if not character or not root then return false end
	local spawn = islands[worldId].Spawn
	clearPositionState(player, session)
	character:PivotTo(spawn.CFrame + Vector3.new(0, 5, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	session.Profile.Data.CurrentWorldId = worldId
	syncPlayerState(player, session.Profile.Data)
	return true
end

local function getIslandId(instance: Instance): number?
	local node: Instance? = instance
	while node and node ~= worldFolder do
		local id = islandIds[node]
		if id then return id end
		node = node.Parent
	end
	return nil
end

local function travel(player: Player, session: Session, targetId: number)
	local data = session.Profile.Data
	if data.CurrentWorldId == targetId or not canPerform(session, "World", WORLD_COOLDOWN) then return end
	if not data.UnlockedWorlds[targetId] then
		local needed = config.Worlds[targetId - 1].RouteGum
		notify(player, "FOLLOW THE CLOUDS", "Climb from " .. config.Worlds[targetId - 1].Name
			.. " with " .. config.Gums[needed].Name .. " or " .. config.Gums[needed + 1].Name .. ".", blue)
		return
	end
	teleportToWorld(player, session, targetId)
end

worldActionEvent.OnServerEvent:Connect(function(player, worldId)
	local session = activeSession(player)
	if not session or type(worldId) ~= "number" or worldId % 1 ~= 0 or not islands[worldId] then return end
	travel(player, session, worldId)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	local portal = prompt.Parent
	if prompt.Name ~= "WorldPrompt" or not prompt.Enabled or not portal or not portal:IsA("BasePart") then return end
	local session = activeSession(player)
	local _, root = getCharacter(player)
	if not session or not root or getIslandId(portal) ~= session.Profile.Data.CurrentWorldId
		or (root.Position - portal.Position).Magnitude > prompt.MaxActivationDistance + 2 then
		return
	end
	local targetId = portal:GetAttribute("TargetWorldId")
	if type(targetId) == "number" and islands[targetId] then travel(player, session, targetId) end
end)

rebirthActionEvent.OnServerEvent:Connect(function(player)
	local session = activeSession(player)
	local _, root, humanoid = getCharacter(player)
	if not session or not root or not humanoid or not canPerform(session, "Rebirth", REBIRTH_COOLDOWN) then return end
	local data = session.Profile.Data
	if data.PlayerLevel < config.RebirthLevel or data.Coins < config.RebirthCoins then return end
	data.Rebirths += 1
	data.Coins = 0
	data.BubbleSize = 0
	data.GumLevel = 1
	data.OwnedGums = { [1] = true }
	data.XP = 0
	data.PlayerLevel = 1
	applyJumpPower(humanoid, data)
	teleportToWorld(player, session, 1)
	notify(player, "REBIRTH COMPLETE!", "Permanent coin multiplier increased!", Color3.fromRGB(210, 135, 255))
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { worldFolder }
rayParams.RespectCanCollide = true

local function getGround(root: BasePart, humanoid: Humanoid): RaycastResult?
	if root.AssemblyLinearVelocity.Y > 5 then return nil end
	local feetDistance = root.Size.Y * 0.5 + humanoid.HipHeight
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = root.Parent and root.Parent:FindFirstChild("Left Leg")
		if leg and leg:IsA("BasePart") then feetDistance += leg.Size.Y end
	end
	return workspace:Raycast(root.Position, Vector3.new(0, -(feetDistance + 1.0), 0), rayParams)
end

local function canClimb(data: ProfileStore.Data): boolean
	local gum = config.Gums[data.GumLevel]
	return gum.World == data.CurrentWorldId and gum.Id >= config.Worlds[data.CurrentWorldId].RouteGum
end

local function updateLanding(player: Player, session: Session, ground: RaycastResult)
	local data = session.Profile.Data
	local currentId = data.CurrentWorldId
	local cloud = clouds[ground.Instance]
	if cloud then
		if cloud.World == currentId and cloud.Step == session.CloudStep + 1 and canClimb(data) then
			session.CloudStep = cloud.Step
		end
		return
	end

	local landedId = getIslandId(ground.Instance)
	if not landedId or ground.Position.Y < islands[landedId].Spawn.Position.Y - 3 then return end
	if landedId == currentId then
		session.CloudStep = 0
		return
	end

	if not data.UnlockedWorlds[landedId] then
		if landedId ~= currentId + 1 or not canClimb(data) or session.CloudStep ~= routeLengths[currentId] then
			teleportToWorld(player, session, currentId)
			return
		end
		data.UnlockedWorlds[landedId] = true
		notify(player, "NEW WORLD REACHED!", "Welcome to " .. config.Worlds[landedId].Name .. "!", blue)
	end
	clearPositionState(player, session)
	data.CurrentWorldId = landedId
	syncPlayerState(player, data)
end

local function updatePosition(player: Player, session: Session)
	local _, root, humanoid = getCharacter(player)
	if not root or not humanoid then return end
	local data = session.Profile.Data
	local island = islands[data.CurrentWorldId]
	if root.Position.Y < island.Spawn.Position.Y - 80 then
		if teleportToWorld(player, session, data.CurrentWorldId) then
			notify(player, "BACK TO THE ISLAND", "You fell between the islands.", orange)
		end
		return
	end

	local ground = getGround(root, humanoid)
	if ground then
		updateLanding(player, session, ground)
		island = islands[data.CurrentWorldId]
	end
	local nearShop = isInZone(root, island.Shop)
	local nearSell = isInZone(root, island.Sell)
	player:SetAttribute("NearShopZone", nearShop)
	player:SetAttribute("NearSellZone", nearSell)
	if nearSell and not session.InSellZone then sellBubble(player, session, root) end
	session.InSellZone = nearSell
end

local function createLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({ "Level", "Coins", "Bubbles", "Rebirths" }) do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
end

local shuttingDown = false
local loadsInProgress = 0
local loadingPlayers: {[Player]: boolean} = {}

local function closeSession(player: Player, session: Session)
	if not ProfileStore.save(player.UserId, session.Profile, true) then
		warn("[GameServer] Final save failed for", player.UserId)
	end
	if sessions[player] == session then sessions[player] = nil end
end

local function onPlayerAdded(player: Player)
	if shuttingDown or loadingPlayers[player] or sessions[player] then return end
	loadingPlayers[player] = true
	loadsInProgress += 1
	local profile, reason = ProfileStore.open(player.UserId)
	if not profile and reason == "unavailable" and RunService:IsStudio() then
		profile = ProfileStore.temporary()
		player:SetAttribute("DataWarning", "Studio test session. Progress will not be saved.")
	end
	if profile and (player.Parent ~= Players or shuttingDown) then
		ProfileStore.save(player.UserId, profile, true)
		loadsInProgress -= 1
		loadingPlayers[player] = nil
		return
	end
	loadsInProgress -= 1
	loadingPlayers[player] = nil
	if not profile then
		if player.Parent == Players then
			player:Kick(if reason == "in use" then "Your progress is open on another server. Please rejoin shortly."
				else "Your progress could not be loaded. Please rejoin shortly.")
		end
		return
	end

	local session: Session = { Profile = profile, Cooldowns = {}, CloudStep = 0, InSellZone = false }
	sessions[player] = session
	createLeaderstats(player)
	clearPositionState(player, session)
	syncPlayerState(player, profile.Data)
	local function onCharacterAdded(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if humanoid and humanoid:IsA("Humanoid") and root and player.Character == character
			and activeSession(player) == session then
			applyJumpPower(humanoid, session.Profile.Data)
			teleportToWorld(player, session, session.Profile.Data.CurrentWorldId)
		end
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(function()
		clearPositionState(player, session)
	end)
	if player.Character then task.spawn(onCharacterAdded, player.Character) end

	task.delay(3, function()
		if activeSession(player) == session and player.Parent == Players then
			notify(player, "WELCOME!", "Blow bubbles, sell them at the green platform, then visit the gum shop.", blue)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayerAdded, player) end

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session then closeSession(player, session) end
end)

task.spawn(function()
	while not shuttingDown do
		for player, session in pairs(sessions) do
			if not session.Profile.Closing then
				local expires = session.Profile.Expires
				if expires and expires <= os.time() then
					player:Kick("Your progress connection expired. Please rejoin.")
				else
					updatePosition(player, session)
				end
			end
		end
		task.wait(0.1)
	end
end)

task.spawn(function()
	while not shuttingDown do
		task.wait(AUTOSAVE_INTERVAL)
		if shuttingDown then break end
		for player, session in pairs(sessions) do
			task.spawn(ProfileStore.save, player.UserId, session.Profile, false)
		end
	end
end)

local function spawnCoinEvent()
	local spawn = islands[1].Spawn.Position
	for player in pairs(sessions) do
		if activeSession(player) then
			notify(player, "BUBBLE RAIN!", "Bonus coins are floating over Grassland for 45 seconds!", orange)
		end
	end
	for index = 1, 12 do
		local angle = math.rad(index * 30 + math.random(0, 20))
		local radius = math.random(10, 34)
		local position = spawn + Vector3.new(math.cos(angle) * radius, 3.5, math.sin(angle) * radius)
		local coin = Instance.new("Part")
		coin.Name = "BonusCoin"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.5, 3.2, 3.2)
		coin.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
		coin.Color = Color3.fromRGB(255, 210, 40)
		coin.Material = Enum.Material.Neon
		coin.Anchored = true
		coin.CanCollide = false
		coin.CanQuery = false
		coin.Parent = workspace
		TweenService:Create(coin, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Position = position + Vector3.new(0, 1.4, 0),
		}):Play()

		local collected = false
		coin.Touched:Connect(function(hit)
			if collected then return end
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then return end
			local session = activeSession(player)
			local _, root = getCharacter(player)
			if not session or not root or (root.Position - coin.Position).Magnitude > 8 then return end
			local data = session.Profile.Data
			if data.CurrentWorldId ~= 1 then return end
			collected = true
			addCoins(data, 8 + math.min(data.PlayerLevel, 12))
			syncXPReward(player, data, 3)
			coin:Destroy()
		end)
		task.delay(45, function()
			if coin.Parent then coin:Destroy() end
		end)
	end
end

task.spawn(function()
	task.wait(45)
	while not shuttingDown do
		spawnCoinEvent()
		task.wait(180)
	end
end)

game:BindToClose(function()
	shuttingDown = true
	for player, session in pairs(sessions) do
		task.spawn(closeSession, player, session)
	end
	local deadline = os.clock() + 25
	while (next(sessions) or loadsInProgress > 0) and os.clock() < deadline do
		task.wait(0.1)
	end
end)
