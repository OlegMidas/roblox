--!strict
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local LEASE_SECONDS = 180
local RETRY_ATTEMPTS = 4

export type Data = {
	Coins: number,
	BubbleSize: number,
	GumLevel: number,
	OwnedGums: {[number]: boolean},
	XP: number,
	PlayerLevel: number,
	Rebirths: number,
	UnlockedWorlds: {[number]: boolean},
	CurrentWorldId: number,
}
export type Profile = {
	Data: Data,
	Token: string?,
	Expires: number?,
	Busy: boolean,
	Closing: boolean,
	Closed: boolean,
}

local store: GlobalDataStore? = nil
local ready, storeResult = pcall(function()
	return DataStoreService:GetDataStore("BubbleGumSim_Save_v1")
end)
if ready then
	store = storeResult
else
	warn("[ProfileStore] DataStore unavailable:", storeResult)
end

local ProfileStore = {}

local function integer(value: any, default: number, maximum: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value < 0 then
		return default
	end
	return math.min(math.floor(value), maximum)
end

local function readId(value: any, maximum: number): number
	local id = if type(value) == "string" or type(value) == "number" then tonumber(value) else nil
	return if id and id % 1 == 0 and id >= 1 and id <= maximum then id else 1
end

local function readIds(raw: any, maxId: number): {[number]: boolean}
	local result = { [1] = true }
	if type(raw) == "table" then
		-- Old saves stored boolean maps. New saves use string keys for sparse IDs.
		for key, value in pairs(raw) do
			local id = if type(key) == "string" or type(key) == "number" then tonumber(key) else nil
			if value == true and id and id % 1 == 0 and id >= 1 and id <= maxId then
				result[id] = true
			end
		end
	end
	return result
end

local function readData(raw: any): Data
	if type(raw) ~= "table" then raw = {} end
	local owned = readIds(raw.OwnedGums, #config.Gums)
	local worlds = readIds(raw.UnlockedWorlds, #config.Worlds)
	-- Older servers only sold a gum after its world had been unlocked.
	for id in pairs(owned) do
		worlds[config.Gums[id].World] = true
	end
	local equipped = readId(raw.GumLevel, #config.Gums)
	if not owned[equipped] then equipped = 1 end
	local world = readId(raw.CurrentWorldId, #config.Worlds)
	if not worlds[world] then world = 1 end
	local level = math.max(1, integer(raw.PlayerLevel, 1, config.MaxLevel))
	return {
		Coins = integer(raw.Coins, 0, config.MaxCoins),
		BubbleSize = integer(raw.BubbleSize, 0, config.Gums[equipped].MaxBubble),
		GumLevel = equipped,
		OwnedGums = owned,
		XP = integer(raw.XP, 0, config.xpRequired(level) - 1),
		PlayerLevel = level,
		Rebirths = integer(raw.Rebirths, 0, 10000),
		UnlockedWorlds = worlds,
		CurrentWorldId = world,
	}
end

local function writeIds(ids: {[number]: boolean}): {[string]: boolean}
	local result = {}
	for id, included in pairs(ids) do
		if included then result[tostring(id)] = true end
	end
	return result
end

local function encodeData(data: Data)
	local record = table.clone(data) :: any
	record.OwnedGums = writeIds(data.OwnedGums)
	record.UnlockedWorlds = writeIds(data.UnlockedWorlds)
	return record
end

function ProfileStore.temporary(): Profile
	return { Data = readData(nil), Token = nil, Expires = nil, Busy = false, Closing = false, Closed = false }
end

function ProfileStore.open(userId: number): (Profile?, string?)
	local dataStore = store
	if not dataStore then return nil, "unavailable" end
	local key = "Player_" .. userId
	local token = HttpService:GenerateGUID(false)
	local locked = false
	local profileExpires = 0
	for attempt = 1, RETRY_ATTEMPTS do
		local ok, raw = pcall(function()
			return dataStore:UpdateAsync(key, function(value)
				local lease = if type(value) == "table" then value.Session else nil
				locked = type(lease) == "table" and lease.Token ~= token
					and type(lease.Until) == "number" and lease.Until > os.time()
				if locked then return nil end
				local record = encodeData(readData(value))
				profileExpires = os.time() + LEASE_SECONDS
				record.Session = { Token = token, Until = profileExpires }
				return record
			end)
		end)
		if ok and raw then
			return { Data = readData(raw), Token = token, Expires = profileExpires, Busy = false, Closing = false, Closed = false }, nil
		end
		if not ok then
			warn("[ProfileStore] Load failed for", userId, raw)
		end
		if attempt < RETRY_ATTEMPTS then task.wait(attempt) end
	end
	return nil, if locked then "in use" else "unavailable"
end

function ProfileStore.save(userId: number, profile: Profile, closing: boolean): boolean
	local dataStore = store
	local token = profile.Token
	if not dataStore or not token then return true end
	if not closing and (profile.Busy or profile.Closing) then return true end
	if closing then
		if profile.Closing then
			while not profile.Closed do task.wait() end
			return true
		end
		profile.Closing = true
		while profile.Busy do task.wait() end
	end
	profile.Busy = true
	local snapshot = encodeData(profile.Data)
	local key = "Player_" .. userId
	local saved = false
	local expires = 0
	for attempt = 1, RETRY_ATTEMPTS do
		local ok, result = pcall(function()
			return dataStore:UpdateAsync(key, function(current)
				local lease = if type(current) == "table" then current.Session else nil
				if type(lease) ~= "table" or lease.Token ~= token then return nil end
				expires = os.time() + LEASE_SECONDS
				snapshot.Session = if closing then nil else { Token = token, Until = expires }
				return snapshot
			end)
		end)
		if ok then
			saved = result ~= nil
			profile.Expires = if saved and not closing then expires else 0
			break
		end
		warn("[ProfileStore] Save failed for", userId, result)
		if attempt < RETRY_ATTEMPTS then task.wait(attempt) end
	end
	profile.Busy = false
	if closing then profile.Closed = true end
	return saved
end

return ProfileStore
