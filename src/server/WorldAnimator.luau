--!strict
local RunService = game:GetService("RunService")
local world = workspace:WaitForChild("BubbleWorld")

type Animation = {
	Base: CFrame,
	Mode: string,
	Amp: number,
	Speed: number,
	Phase: number,
	Radius: number,
	Height: number,
	Center: Vector3,
}
local items: {[BasePart]: Animation} = {}
local nextPhase = 0

local function attributeNumber(instance: BasePart, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" and math.abs(value) < math.huge then value else default
end

local function track(instance: Instance)
	if not instance:IsA("BasePart") or not instance.Anchored then return end
	local mode = instance:GetAttribute("Anim")
	if mode ~= "Bob" and mode ~= "Spin" and mode ~= "Orbit" then return end

	nextPhase += 0.7
	-- Keep the cap and gem aligned with their floating rock.
	local group = instance.Name:match("^FloatRock(%d+)$") or instance.Name:match("^FloatCap(%d+)$")
		or instance.Name:match("^FloatGem(%d+)$")
	items[instance] = {
		Base = instance.CFrame,
		Mode = mode,
		Amp = attributeNumber(instance, "BobAmp", 1),
		Speed = attributeNumber(instance, mode .. "Speed", 1),
		Phase = if group then (tonumber(group) or 0) * 0.7 else nextPhase,
		Radius = attributeNumber(instance, "OrbitRadius", 10),
		Height = attributeNumber(instance, "OrbitHeight", 0),
		Center = Vector3.new(
			attributeNumber(instance, "OrbitCenterX", 0),
			attributeNumber(instance, "OrbitCenterY", 0),
			attributeNumber(instance, "OrbitCenterZ", 0)
		),
	}
end

for _, instance in ipairs(world:GetDescendants()) do track(instance) end
world.DescendantAdded:Connect(track)
world.DescendantRemoving:Connect(function(instance)
	if instance:IsA("BasePart") then items[instance] = nil end
end)

local clockStart = os.clock()
RunService.Heartbeat:Connect(function()
	local elapsed = os.clock() - clockStart
	for part, item in pairs(items) do
		local angle = elapsed * item.Speed + item.Phase
		if item.Mode == "Bob" then
			part.CFrame = item.Base + Vector3.new(0, math.sin(angle) * item.Amp, 0)
		elseif item.Mode == "Spin" then
			part.CFrame = item.Base * CFrame.Angles(0, elapsed * item.Speed, 0)
		elseif item.Mode == "Orbit" then
			local position = item.Center + Vector3.new(math.cos(angle) * item.Radius, item.Height, math.sin(angle) * item.Radius)
			part.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, 0)
		end
	end
end)
