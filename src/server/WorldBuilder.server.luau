--!strict
-- Four themed low-poly islands plus the starter gum shop. Run from ServerScriptService.
local Workspace = game:GetService("Workspace")
local old = Workspace:FindFirstChild("BubbleWorld")
if old then old:Destroy() end
local root = Instance.new("Folder")
root.Name = "BubbleWorld"
root.Parent = Workspace

local WORLDS = {
	{Id=1, Name="Grassland", Center=Vector3.new(0,0,0), Top=Color3.fromRGB(106,196,105), Rock=Color3.fromRGB(91,83,76), Accent=Color3.fromRGB(255,190,80), Material=Enum.Material.Grass, Path=Color3.fromRGB(220,196,145)},
	{Id=2, Name="Frozen World", Center=Vector3.new(270,18,0), Top=Color3.fromRGB(160,220,245), Rock=Color3.fromRGB(105,145,170), Accent=Color3.fromRGB(100,220,255), Material=Enum.Material.Ice, Path=Color3.fromRGB(220,245,255)},
	{Id=3, Name="Candy World", Center=Vector3.new(540,42,0), Top=Color3.fromRGB(255,160,205), Rock=Color3.fromRGB(175,95,150), Accent=Color3.fromRGB(255,225,110), Material=Enum.Material.SmoothPlastic, Path=Color3.fromRGB(255,225,238)},
	{Id=4, Name="Galaxy World", Center=Vector3.new(810,72,0), Top=Color3.fromRGB(90,70,155), Rock=Color3.fromRGB(42,35,85), Accent=Color3.fromRGB(90,220,255), Material=Enum.Material.SmoothPlastic, Path=Color3.fromRGB(130,115,195)},
}

local function make(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p=Instance.new("Part")
	p.Name=name p.Anchored=true p.Size=size p.CFrame=cf p.Color=color p.Material=material
	p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Shape=shape or Enum.PartType.Block p.Parent=parent
	return p
end
local function orb(parent: Instance, name: string, diameter: number, pos: Vector3, color: Color3, material: Enum.Material): Part
	return make(parent,name,Vector3.one*diameter,CFrame.new(pos),color,material,Enum.PartType.Ball)
end
local function makeLamp(parent: Instance, pos: Vector3, color: Color3)
	make(parent,"LampPost",Vector3.new(1,9,1),CFrame.new(pos+Vector3.new(0,4.5,0)),Color3.fromRGB(65,70,80),Enum.Material.Metal)
	local glow=orb(parent,"LampGlow",3.5,pos+Vector3.new(0,9.5,0),color,Enum.Material.Neon)
	glow.CanCollide=false
	local light=Instance.new("PointLight") light.Color=color light.Brightness=1 light.Range=18 light.Parent=glow
end
local function makeTree(parent: Instance, pos: Vector3, world, index: number)
	make(parent,"TreeTrunk",Vector3.new(2.5,10,2.5),CFrame.new(pos+Vector3.new(0,5,0)),Color3.fromRGB(111,78,52),Enum.Material.Wood)
	local crownColor=world.Id==3 and (index%2==0 and world.Accent or Color3.fromRGB(255,115,185)) or world.Accent
	orb(parent,"TreeCrown",world.Id==2 and 10 or 12,pos+Vector3.new(0,12,0),crownColor,world.Id==3 and Enum.Material.SmoothPlastic or Enum.Material.Grass)
	if world.Id==1 then orb(parent,"Fruit",2.2,pos+Vector3.new(4,11,0),Color3.fromRGB(255,100,95),Enum.Material.SmoothPlastic) end
end
local function makeSign(parent: Instance, text: string, pos: Vector3, color: Color3, width: number)
	make(parent,"SignPost",Vector3.new(1.2,8,1.2),CFrame.new(pos+Vector3.new(0,4,0)),Color3.fromRGB(105,76,53),Enum.Material.Wood)
	local board=make(parent,"SignBoard",Vector3.new(width,5,0.8),CFrame.new(pos+Vector3.new(0,8,0)),color,Enum.Material.SmoothPlastic)
	local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(600,220) gui.Parent=board
	local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text=text label.TextColor3=Color3.fromRGB(40,42,55) label.Font=Enum.Font.GothamBlack label.TextScaled=true label.Parent=gui
end
local function makePortal(parent: Instance, world, pos: Vector3, targetId: number, action: string)
	local pad=make(parent,"Portal_"..targetId,Vector3.new(1.2,15,15),CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90)),world.Accent,Enum.Material.Neon,Enum.PartType.Cylinder)
	pad:SetAttribute("TargetWorldId",targetId)
	for _,x in ipairs({-6,6}) do make(parent,"PortalPost",Vector3.new(2,12,2),CFrame.new(pos+Vector3.new(x,7,0)),world.Accent,Enum.Material.Neon).CanCollide=false end
	make(parent,"PortalTop",Vector3.new(14,2,2),CFrame.new(pos+Vector3.new(0,13,0)),world.Accent,Enum.Material.Neon).CanCollide=false
	local prompt=Instance.new("ProximityPrompt") prompt.Name="WorldPrompt" prompt.ActionText=action prompt.ObjectText=WORLDS[targetId].Name prompt.HoldDuration=0.35 prompt.MaxActivationDistance=14 prompt.RequiresLineOfSight=false prompt.Parent=pad
end

local function makeGumShop(model: Model, center: Vector3, world)
	local shop=Instance.new("Model") shop.Name="GumShopStall" shop.Parent=model
	local base=center+Vector3.new(-42,2,24)
	make(shop,"ShopFloor",Vector3.new(25,1,17),CFrame.new(base+Vector3.new(0,0.5,0)),Color3.fromRGB(151,105,67),Enum.Material.WoodPlanks)
	make(shop,"Counter",Vector3.new(21,4,5),CFrame.new(base+Vector3.new(0,2.5,3)),Color3.fromRGB(125,79,52),Enum.Material.Wood)
	make(shop,"CounterTop",Vector3.new(22,0.7,5.8),CFrame.new(base+Vector3.new(0,4.8,3)),Color3.fromRGB(244,220,170),Enum.Material.SmoothPlastic)
	for _,x in ipairs({-10,10}) do make(shop,"CanopyPost",Vector3.new(1,9,1),CFrame.new(base+Vector3.new(x,5,-5)),Color3.fromRGB(116,78,53),Enum.Material.Wood) end
	make(shop,"Canopy",Vector3.new(25,1.4,18),CFrame.new(base+Vector3.new(0,10,-1)),Color3.fromRGB(255,242,225),Enum.Material.SmoothPlastic)
	for i=1,5 do make(shop,"CanopyStripe",Vector3.new(4.7,0.12,18.2),CFrame.new(base+Vector3.new(-10+(i-1)*5,10.8,-1)),i%2==0 and world.Accent or Color3.new(1,1,1),Enum.Material.SmoothPlastic).CanCollide=false end
	local board=make(shop,"GumShopSign",Vector3.new(17,4,0.8),CFrame.new(base+Vector3.new(0,7.2,7.2)),world.Accent,Enum.Material.SmoothPlastic)
	local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(700,180) gui.Parent=board
	local title=Instance.new("TextLabel") title.Size=UDim2.fromScale(1,1) title.BackgroundTransparency=1 title.Text="G U M   S H O P" title.TextColor3=Color3.fromRGB(45,48,62) title.Font=Enum.Font.GothamBlack title.TextScaled=true title.Parent=gui
	local gumColors={Color3.fromRGB(255,110,180),Color3.fromRGB(110,220,130),Color3.fromRGB(120,170,255)}
	for i,color in ipairs(gumColors) do
		local x=-6+(i-1)*6
		local jar=make(shop,"GumJar",Vector3.new(3.4,3.2,3.4),CFrame.new(base+Vector3.new(x,7,3)),color,Enum.Material.Glass,Enum.PartType.Cylinder)
		jar.Transparency=0.12 jar.CanCollide=false
		orb(shop,"GumDisplay",1.8,base+Vector3.new(x,8.8,3),color,Enum.Material.Neon).CanCollide=false
	end
end

for _,world in ipairs(WORLDS) do
	local model=Instance.new("Model") model.Name="World_"..world.Id.."_"..world.Name:gsub("%W","") model:SetAttribute("WorldId",world.Id) model.Parent=root
	local center=world.Center
	make(model,"FloatingRock",Vector3.new(34,170,170),CFrame.new(center+Vector3.new(0,-15,0))*CFrame.Angles(0,0,math.rad(90)),world.Rock,Enum.Material.Slate,Enum.PartType.Cylinder)
	make(model,"IslandSurface",Vector3.new(8,158,158),CFrame.new(center-Vector3.new(0,2,0))*CFrame.Angles(0,0,math.rad(90)),world.Top,world.Material,Enum.PartType.Cylinder)
	make(model,"IslandRim",Vector3.new(3,161,161),CFrame.new(center-Vector3.new(0,4.5,0))*CFrame.Angles(0,0,math.rad(90)),world.Accent,Enum.Material.Slate,Enum.PartType.Cylinder).CanCollide=false
	local plaza=make(model,"SpawnPlaza",Vector3.new(1.5,44,44),CFrame.new(center+Vector3.new(0,3,0))*CFrame.Angles(0,0,math.rad(90)),world.Accent,Enum.Material.SmoothPlastic,Enum.PartType.Cylinder)
	plaza.Transparency=0.08
	local spawn=make(model,"WorldSpawn_"..world.Id,Vector3.new(8,1,8),CFrame.new(center+Vector3.new(0,5,0)),world.Top,Enum.Material.SmoothPlastic)
	spawn.Transparency=1 spawn.CanCollide=false spawn:SetAttribute("WorldId",world.Id)
	if world.Id==1 then
		local main=Instance.new("SpawnLocation") main.Name="MainSpawn" main.Size=Vector3.new(8,1,8) main.CFrame=CFrame.new(center+Vector3.new(0,5,0)) main.Anchored=true main.Neutral=true main.Duration=0 main.Transparency=1 main.CanCollide=false main.Parent=model
	end

	for _,entry in ipairs({
		{"MainPath",Vector3.new(-24,2.12,13),Vector3.new(36,0.25,9)},
		{"SellPath",Vector3.new(25,2.12,13),Vector3.new(36,0.25,9)},
		{"PortalPath",Vector3.new(36,2.12,-18),Vector3.new(9,0.25,38)},
	}) do make(model,entry[1],entry[3],CFrame.new(center+entry[2]),world.Path,Enum.Material.Cobblestone) end

	for i,offset in ipairs({Vector3.new(-60,3,-42),Vector3.new(60,3,-42),Vector3.new(-60,3,42),Vector3.new(60,3,42),Vector3.new(-67,3,0),Vector3.new(67,3,0)}) do
		if world.Id==4 then
			make(model,"Crystal",Vector3.new(7,20+(i%3)*4,7),CFrame.new(center+offset+Vector3.new(0,10,0))*CFrame.Angles(0,math.rad(i*25),math.rad(8)),world.Accent,Enum.Material.Neon)
			orb(model,"Star",3,center+offset+Vector3.new(5,17,3),Color3.new(1,1,1),Enum.Material.Neon).CanCollide=false
		else makeTree(model,center+offset,world,i) end
	end
	makeLamp(model,center+Vector3.new(-22,3,-26),world.Accent)
	makeLamp(model,center+Vector3.new(22,3,-26),world.Accent)
	makeSign(model,world.Name,center+Vector3.new(0,3,-57),world.Accent,26)

	if world.Id==1 then
		makeGumShop(model,center,world)
		local zone=make(model,"ShopZone",Vector3.new(34,12,28),CFrame.new(center+Vector3.new(-42,6,24)),Color3.new(1,1,1),Enum.Material.SmoothPlastic)
		zone.Transparency=1 zone.CanCollide=false zone.CanTouch=false
		local sell=make(model,"SellPlatform",Vector3.new(1.5,26,22),CFrame.new(center+Vector3.new(42,2.8,24))*CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(65,225,140),Enum.Material.Neon,Enum.PartType.Cylinder)
		sell.Transparency=0.2
		local sign=make(model,"SellSign",Vector3.new(15,4,0.8),CFrame.new(center+Vector3.new(42,8,35)),Color3.fromRGB(100,245,165),Enum.Material.SmoothPlastic)
		local sg=Instance.new("SurfaceGui") sg.Face=Enum.NormalId.Front sg.CanvasSize=Vector2.new(500,160) sg.Parent=sign
		local txt=Instance.new("TextLabel") txt.Size=UDim2.fromScale(1,1) txt.BackgroundTransparency=1 txt.Text="SELL BUBBLES" txt.TextColor3=Color3.fromRGB(25,60,45) txt.Font=Enum.Font.GothamBlack txt.TextScaled=true txt.Parent=sg
		local sellZone=make(model,"SellZone",Vector3.new(26,8,24),CFrame.new(center+Vector3.new(42,4,24)),Color3.fromRGB(70,255,150),Enum.Material.Neon)
		sellZone.Transparency=1 sellZone.CanCollide=false sellZone.CanTouch=true
	end
	if world.Id<#WORLDS then makePortal(model,world,center+Vector3.new(52,4,0),world.Id+1,"Unlock / Travel") end
	if world.Id>1 then makePortal(model,world,center+Vector3.new(-52,4,0),world.Id-1,"Travel Back") end
end

for i=1,#WORLDS-1 do
	local a,b=WORLDS[i].Center,WORLDS[i+1].Center
	local bridge=make(root,"Bridge_"..i,Vector3.new(26,3,(b-a).Magnitude-105),CFrame.lookAt((a+b)/2+Vector3.new(0,-2,0),b),WORLDS[i].Accent,Enum.Material.SmoothPlastic)
	bridge.CanCollide=false
end
print("[BubbleWorld] Built four themed islands, paths, lamps, portals, starter gum shop, and sell platform.")
