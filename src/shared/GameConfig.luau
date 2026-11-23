--!strict
local GameConfig = {}

GameConfig.Worlds = {
	{ Name = "Grassland", CoinMultiplier = 1, BlowXP = 1, FullSaleXP = 10, RouteGum = 4 },
	{ Name = "Frozen World", CoinMultiplier = 1.2, BlowXP = 2, FullSaleXP = 16, RouteGum = 9 },
	{ Name = "Candy World", CoinMultiplier = 1.45, BlowXP = 3, FullSaleXP = 23, RouteGum = 14 },
	{ Name = "Galaxy World", CoinMultiplier = 1.7, BlowXP = 4, FullSaleXP = 30, RouteGum = 0 },
}

GameConfig.Gums = {
	{ Id = 1, Name = "Mint", Price = 0, Power = 1, MaxBubble = 25, SellMultiplier = 1, JumpPower = 74, Color = Color3.fromRGB(255, 110, 180), World = 1 },
	{ Id = 2, Name = "Berry", Price = 100, Power = 3, MaxBubble = 60, SellMultiplier = 1.3, JumpPower = 125, Color = Color3.fromRGB(255, 60, 80), World = 1 },
	{ Id = 3, Name = "Lime", Price = 650, Power = 8, MaxBubble = 150, SellMultiplier = 1.6, JumpPower = 183, Color = Color3.fromRGB(80, 230, 90), World = 1 },
	{ Id = 4, Name = "Clover", Price = 3300, Power = 20, MaxBubble = 400, SellMultiplier = 2, JumpPower = 235, Color = Color3.fromRGB(60, 200, 120), World = 1 },
	{ Id = 5, Name = "Gold", Price = 13000, Power = 50, MaxBubble = 1000, SellMultiplier = 2.5, JumpPower = 258, Color = Color3.fromRGB(255, 210, 40), World = 1 },
	{ Id = 6, Name = "Frost", Price = 28000, Power = 120, MaxBubble = 2500, SellMultiplier = 3, JumpPower = 280, Color = Color3.fromRGB(140, 230, 255), World = 2 },
	{ Id = 7, Name = "Snow", Price = 135000, Power = 280, MaxBubble = 6000, SellMultiplier = 3.5, JumpPower = 313, Color = Color3.fromRGB(220, 245, 255), World = 2 },
	{ Id = 8, Name = "Glacier", Price = 340000, Power = 650, MaxBubble = 15000, SellMultiplier = 4, JumpPower = 345, Color = Color3.fromRGB(110, 200, 240), World = 2 },
	{ Id = 9, Name = "Blizzard", Price = 820000, Power = 1500, MaxBubble = 40000, SellMultiplier = 4.5, JumpPower = 402, Color = Color3.fromRGB(90, 170, 235), World = 2 },
	{ Id = 10, Name = "Aurora", Price = 2300000, Power = 3500, MaxBubble = 100000, SellMultiplier = 5, JumpPower = 424, Color = Color3.fromRGB(150, 255, 220), World = 2 },
	{ Id = 11, Name = "Candy Pop", Price = 1650000, Power = 8000, MaxBubble = 250000, SellMultiplier = 5.5, JumpPower = 430, Color = Color3.fromRGB(255, 170, 220), World = 3 },
	{ Id = 12, Name = "Bubblegum", Price = 10000000, Power = 18000, MaxBubble = 600000, SellMultiplier = 6, JumpPower = 437, Color = Color3.fromRGB(255, 105, 180), World = 3 },
	{ Id = 13, Name = "Taffy", Price = 25000000, Power = 40000, MaxBubble = 1500000, SellMultiplier = 6.5, JumpPower = 443, Color = Color3.fromRGB(250, 200, 120), World = 3 },
	{ Id = 14, Name = "Lollipop", Price = 58000000, Power = 90000, MaxBubble = 3500000, SellMultiplier = 7, JumpPower = 505, Color = Color3.fromRGB(200, 120, 255), World = 3 },
	{ Id = 15, Name = "Jawbreaker", Price = 165000000, Power = 200000, MaxBubble = 8000000, SellMultiplier = 7.5, JumpPower = 525, Color = Color3.fromRGB(170, 90, 200), World = 3 },
	{ Id = 16, Name = "Cosmic", Price = 105000000, Power = 450000, MaxBubble = 20000000, SellMultiplier = 8, JumpPower = 530, Color = Color3.fromRGB(170, 140, 255), World = 4 },
	{ Id = 17, Name = "Nebula", Price = 720000000, Power = 1000000, MaxBubble = 50000000, SellMultiplier = 8.5, JumpPower = 535, Color = Color3.fromRGB(120, 90, 255), World = 4 },
	{ Id = 18, Name = "Starlight", Price = 1900000000, Power = 2200000, MaxBubble = 120000000, SellMultiplier = 9, JumpPower = 540, Color = Color3.fromRGB(255, 255, 200), World = 4 },
	{ Id = 19, Name = "Void", Price = 4800000000, Power = 5000000, MaxBubble = 300000000, SellMultiplier = 9.5, JumpPower = 545, Color = Color3.fromRGB(90, 60, 160), World = 4 },
	{ Id = 20, Name = "Supernova", Price = 12500000000, Power = 12000000, MaxBubble = 750000000, SellMultiplier = 10, JumpPower = 550, Color = Color3.fromRGB(255, 140, 60), World = 4 },
}

GameConfig.BlowCooldown = 0.26
GameConfig.RebirthLevel = 20
GameConfig.RebirthCoins = 250000
GameConfig.MaxCoins = 9000000000000000
GameConfig.MaxLevel = 1000

function GameConfig.xpRequired(level: number): number
	local steps = level - 1
	return 145 + steps * 34 + steps * steps
end

function GameConfig.shopPrerequisite(gumId: number): number?
	local previous = GameConfig.Gums[gumId - 1]
	return if previous and previous.World == GameConfig.Gums[gumId].World then previous.Id else nil
end

function GameConfig.hasId(ids: string?, id: number): boolean
	for token in string.gmatch(ids or "1", "[^,]+") do
		if tonumber(token) == id then return true end
	end
	return false
end

return GameConfig
