--!strict
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.VaultBreakers.Config.GameConfig)
local RewardPool = require(ReplicatedStorage.VaultBreakers.Config.RewardPool)

local StageBuilder = {}

export type VaultModel = {
	model: Model,
	vaultId: number,
	doorAssembly: Model,
	mainDoor: BasePart,
	spokeWheel: BasePart,
	lockBolts: { BasePart },
	prompt: ProximityPrompt,
	displayGui: BillboardGui,
	displayLabel: TextLabel,
	indicatorLight: PointLight,
}

local vaultModels: { [number]: VaultModel } = {}
local stageFolder: Folder

-- Lounge and Stage Coordinates
StageBuilder.LOUNGE_SPAWN = Vector3.new(0, 18.0, 95)
StageBuilder.STAGE_CENTER = Vector3.new(0, 3.0, 0)

function StageBuilder.setupAtmosphericLighting()
	pcall(function()
		Lighting.ClockTime = 14.0 -- Pleasant studio daylight setting
		Lighting.Brightness = 1.8
		Lighting.GlobalShadows = true
		Lighting.Ambient = Color3.fromRGB(115, 120, 130) -- Crisp, bright ambient light! No pitch-black darkness!
		Lighting.OutdoorAmbient = Color3.fromRGB(85, 90, 100)
		Lighting.ExposureCompensation = 0.2

		local bloom = Lighting:FindFirstChild("VaultBloom") :: BloomEffect
		if not bloom then
			bloom = Instance.new("BloomEffect")
			bloom.Name = "VaultBloom"
			bloom.Parent = Lighting
		end
		bloom.Intensity = 0.04
		bloom.Size = 10
		bloom.Threshold = 2.2
	end)
end

function StageBuilder.buildStage(): { [number]: VaultModel }
	StageBuilder.setupAtmosphericLighting()

	stageFolder = Workspace:FindFirstChild("VaultArena") :: Folder
	if stageFolder then
		stageFolder:Destroy()
	end

	stageFolder = Instance.new("Folder")
	stageFolder.Name = "VaultArena"
	stageFolder.Parent = Workspace

	----------------------------------------------------------------------------
	-- SECTION A: GRAND AMERICAN GAME SHOW LOUNGE (CONTESTANT HOLDING HALL)
	----------------------------------------------------------------------------
	local loungeFolder = Instance.new("Folder")
	loungeFolder.Name = "ContestantLounge"
	loungeFolder.Parent = stageFolder

	local LOUNGE_ORIGIN = Vector3.new(0, 16.0, 105)

	-- 1. Grand Lounge Floor (120 x 80 studs, High-End Polished Terrazzo Tiles)
	local lFloor = Instance.new("Part")
	lFloor.Name = "LoungeFloor"
	lFloor.Size = Vector3.new(120, 2.0, 80)
	lFloor.Position = LOUNGE_ORIGIN - Vector3.new(0, 1.0, 0)
	lFloor.Anchored = true
	lFloor.Material = Enum.Material.SmoothPlastic
	lFloor.Color = Color3.fromRGB(55, 60, 70)
	lFloor.Parent = loungeFolder

	-- Central Luxury Geometric Carpet (Under social seating)
	local lCarpet = Instance.new("Part")
	lCarpet.Name = "CentralCarpet"
	lCarpet.Size = Vector3.new(80, 0.2, 52)
	lCarpet.Position = LOUNGE_ORIGIN + Vector3.new(0, 0.1, 0)
	lCarpet.Anchored = true
	lCarpet.Material = Enum.Material.Fabric
	lCarpet.Color = Color3.fromRGB(28, 32, 40)
	lCarpet.Parent = loungeFolder

	-- 2. Studio Soundproof Walls (120 x 80 with 24 studs height)
	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Size = Vector3.new(120, 24, 2.0)
	backWall.Position = LOUNGE_ORIGIN + Vector3.new(0, 12, 40)
	backWall.Anchored = true
	backWall.Material = Enum.Material.SmoothPlastic
	backWall.Color = Color3.fromRGB(24, 27, 34)
	backWall.Parent = loungeFolder

	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(2.0, 24, 80)
	leftWall.Position = LOUNGE_ORIGIN + Vector3.new(-60, 12, 0)
	leftWall.Anchored = true
	leftWall.Material = Enum.Material.SmoothPlastic
	leftWall.Color = Color3.fromRGB(24, 27, 34)
	leftWall.Parent = loungeFolder

	local rightWall = Instance.new("Part")
	rightWall.Name = "RightWall"
	rightWall.Size = Vector3.new(2.0, 24, 80)
	rightWall.Position = LOUNGE_ORIGIN + Vector3.new(60, 12, 0)
	rightWall.Anchored = true
	rightWall.Material = Enum.Material.SmoothPlastic
	rightWall.Color = Color3.fromRGB(24, 27, 34)
	rightWall.Parent = loungeFolder

	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Size = Vector3.new(120, 1.6, 80)
	ceiling.Position = LOUNGE_ORIGIN + Vector3.new(0, 24.8, 0)
	ceiling.Anchored = true
	ceiling.Material = Enum.Material.SmoothPlastic
	ceiling.Color = Color3.fromRGB(18, 20, 26)
	ceiling.Parent = loungeFolder

	-- 3. BRIGHT CEILING LIGHT MATRIX (4x4 = 16 Grand LED Troffers - 彻底告别昏暗!)
	local xOffsets = { -42, -14, 14, 42 }
	local zOffsets = { -26, -9, 9, 26 }

	for _, xOff in ipairs(xOffsets) do
		for _, zOff in ipairs(zOffsets) do
			local troffer = Instance.new("Part")
			troffer.Name = "CeilingLightPanel"
			troffer.Size = Vector3.new(8.0, 0.4, 8.0)
			troffer.Position = LOUNGE_ORIGIN + Vector3.new(xOff, 23.8, zOff)
			troffer.Anchored = true
			troffer.Material = Enum.Material.Neon
			troffer.Color = Color3.fromRGB(255, 252, 245)
			troffer.Parent = loungeFolder

			-- Downward Studio Broadcast Flood SurfaceLight
			local sLight = Instance.new("SurfaceLight")
			sLight.Face = Enum.NormalId.Bottom
			sLight.Brightness = 2.4
			sLight.Range = 40
			sLight.Angle = 120
			sLight.Color = Color3.fromRGB(255, 250, 238)
			sLight.Shadows = false
			sLight.Parent = troffer

			-- Diffuse PointLight for Room Ambience
			local pLight = Instance.new("PointLight")
			pLight.Brightness = 1.6
			pLight.Range = 36
			pLight.Color = Color3.fromRGB(255, 248, 235)
			pLight.Shadows = true
			pLight.Parent = troffer
		end
	end

	-- 4. Front Panoramic Observation Glass (Looking over the Vault Stage)
	local windowBase = Instance.new("Part")
	windowBase.Name = "WindowBase"
	windowBase.Size = Vector3.new(120, 2.6, 2.0)
	windowBase.Position = LOUNGE_ORIGIN + Vector3.new(0, 1.3, -40)
	windowBase.Anchored = true
	windowBase.Material = Enum.Material.Metal
	windowBase.Color = Color3.fromRGB(28, 32, 40)
	windowBase.Parent = loungeFolder

	local frontGlass = Instance.new("Part")
	frontGlass.Name = "ObservationGlass"
	frontGlass.Size = Vector3.new(120, 18, 0.8)
	frontGlass.Position = LOUNGE_ORIGIN + Vector3.new(0, 11.6, -40)
	frontGlass.Anchored = true
	frontGlass.Material = Enum.Material.Glass
	frontGlass.Color = Color3.fromRGB(60, 75, 95)
	frontGlass.Transparency = 0.65
	frontGlass.Parent = loungeFolder

	-- Full-Length Observation Viewing Bar Counter along the glass
	local viewCounter = Instance.new("Part")
	viewCounter.Name = "ViewingCounter"
	viewCounter.Size = Vector3.new(90, 3.4, 2.6)
	viewCounter.Position = LOUNGE_ORIGIN + Vector3.new(0, 1.7, -37.5)
	viewCounter.Anchored = true
	viewCounter.Material = Enum.Material.SmoothPlastic
	viewCounter.Color = Color3.fromRGB(36, 40, 50)
	viewCounter.Parent = loungeFolder

	local viewTrim = Instance.new("Part")
	viewTrim.Size = Vector3.new(90.2, 0.2, 2.8)
	viewTrim.Position = LOUNGE_ORIGIN + Vector3.new(0, 3.5, -37.5)
	viewTrim.Anchored = true
	viewTrim.Material = Enum.Material.Metal
	viewTrim.Color = Color3.fromRGB(245, 184, 0)
	viewTrim.CanCollide = false
	viewTrim.Parent = loungeFolder

	-- 8 High Barstools along observation bar
	for b = 1, 8 do
		local bx = -36 + (b - 1) * 10
		local stoolBase = Instance.new("Part")
		stoolBase.Name = "BarStool"
		stoolBase.Shape = Enum.PartType.Cylinder
		stoolBase.Size = Vector3.new(0.4, 2.2, 2.2)
		stoolBase.CFrame = CFrame.new(LOUNGE_ORIGIN + Vector3.new(bx, 2.4, -34.5)) * CFrame.Angles(0, 0, math.rad(90))
		stoolBase.Anchored = true
		stoolBase.Material = Enum.Material.SmoothPlastic
		stoolBase.Color = Color3.fromRGB(22, 25, 32)
		stoolBase.Parent = loungeFolder
	end

	-- 5. Grand Stage Access Archway (Center of Front Wall)
	local portalArch = Instance.new("Part")
	portalArch.Name = "StageEntranceFrame"
	portalArch.Size = Vector3.new(18, 14, 3.0)
	portalArch.Position = LOUNGE_ORIGIN + Vector3.new(0, 7.0, -40)
	portalArch.Anchored = true
	portalArch.Material = Enum.Material.Metal
	portalArch.Color = Color3.fromRGB(26, 30, 38)
	portalArch.Parent = loungeFolder

	local portalSign = Instance.new("Part")
	portalSign.Name = "PortalSign"
	portalSign.Size = Vector3.new(16, 2.2, 0.3)
	portalSign.Position = LOUNGE_ORIGIN + Vector3.new(0, 12.6, -38.4)
	portalSign.Anchored = true
	portalSign.Material = Enum.Material.SmoothPlastic
	portalSign.Color = Color3.fromRGB(15, 18, 24)
	portalSign.Parent = loungeFolder

	local pGui = Instance.new("SurfaceGui")
	pGui.Face = Enum.NormalId.Front
	pGui.Parent = portalSign
	local pText = Instance.new("TextLabel")
	pText.Size = UDim2.new(1, 0, 1, 0)
	pText.BackgroundTransparency = 1
	pText.TextColor3 = Color3.fromRGB(255, 200, 30)
	pText.Font = Enum.Font.GothamBold
	pText.TextSize = 32
	pText.Text = "★ STAGE 1 ENTRANCE // 演播舞台通道 ★"
	pText.Parent = pGui

	-- Red Carpet Runner leading to Portal
	local redCarpet = Instance.new("Part")
	redCarpet.Name = "RedCarpet"
	redCarpet.Size = Vector3.new(10, 0.25, 26)
	redCarpet.Position = LOUNGE_ORIGIN + Vector3.new(0, 0.15, -28)
	redCarpet.Anchored = true
	redCarpet.Material = Enum.Material.Fabric
	redCarpet.Color = Color3.fromRGB(155, 22, 30) -- Velvet Red
	redCarpet.Parent = loungeFolder

	local portalPrompt = Instance.new("ProximityPrompt")
	portalPrompt.ActionText = "登台参赛 (Step onto Stage)"
	portalPrompt.ObjectText = "演播厅通道"
	portalPrompt.HoldDuration = 0.5
	portalPrompt.MaxActivationDistance = 14
	portalPrompt.RequiresLineOfSight = false
	portalPrompt.Parent = portalArch
	StageBuilder.portalPrompt = portalPrompt

	-- 6. 4 MASSIVE VIP LEATHER LOUNGE SUITES (容纳大几十人)
	local suiteConfigs = {
		{ name = "Suite1", pos = LOUNGE_ORIGIN + Vector3.new(-34, 0, -14) },
		{ name = "Suite2", pos = LOUNGE_ORIGIN + Vector3.new(-34, 0, 18) },
		{ name = "Suite3", pos = LOUNGE_ORIGIN + Vector3.new(34, 0, -14) },
		{ name = "Suite4", pos = LOUNGE_ORIGIN + Vector3.new(34, 0, 18) },
	}

	for _, sc in ipairs(suiteConfigs) do
		-- Main Long Sectional Bench
		local mainSofa = Instance.new("Part")
		mainSofa.Name = sc.name .. "_Main"
		mainSofa.Size = Vector3.new(18, 1.8, 4.5)
		mainSofa.Position = sc.pos + Vector3.new(0, 0.9, 0)
		mainSofa.Anchored = true
		mainSofa.Material = Enum.Material.SmoothPlastic
		mainSofa.Color = Color3.fromRGB(22, 25, 32) -- Deep Obsidian Leather
		mainSofa.Parent = loungeFolder

		local sofaBack = Instance.new("Part")
		sofaBack.Size = Vector3.new(18, 2.6, 1.2)
		sofaBack.Position = sc.pos + Vector3.new(0, 2.6, 2.2)
		sofaBack.Anchored = true
		sofaBack.Material = Enum.Material.SmoothPlastic
		sofaBack.Color = Color3.fromRGB(30, 34, 44)
		sofaBack.Parent = loungeFolder

		-- Side Wing Bench
		local sideSofa = Instance.new("Part")
		sideSofa.Size = Vector3.new(4.5, 1.8, 10)
		sideSofa.Position = sc.pos + Vector3.new(if sc.pos.X < 0 then -8 else 8, 0.9, -4.5)
		sideSofa.Anchored = true
		sideSofa.Material = Enum.Material.SmoothPlastic
		sideSofa.Color = Color3.fromRGB(22, 25, 32)
		sideSofa.Parent = loungeFolder

		-- Marble Coffee Table
		local tableTop = Instance.new("Part")
		tableTop.Name = sc.name .. "_Table"
		tableTop.Size = Vector3.new(10, 1.3, 4.5)
		tableTop.Position = sc.pos + Vector3.new(0, 0.65, -5.5)
		tableTop.Anchored = true
		tableTop.Material = Enum.Material.Glass
		tableTop.Color = Color3.fromRGB(35, 40, 52)
		tableTop.Transparency = 0.15
		tableTop.Parent = loungeFolder
	end

	-- Central Circular Social Island
	local centerTable = Instance.new("Part")
	centerTable.Name = "CenterSocialIsland"
	centerTable.Shape = Enum.PartType.Cylinder
	centerTable.Size = Vector3.new(1.4, 7, 7)
	centerTable.CFrame = CFrame.new(LOUNGE_ORIGIN + Vector3.new(0, 0.7, 2)) * CFrame.Angles(0, 0, math.rad(90))
	centerTable.Anchored = true
	centerTable.Material = Enum.Material.SmoothPlastic
	centerTable.Color = Color3.fromRGB(28, 32, 42)
	centerTable.Parent = loungeFolder

	-- 7. AMERICAN CRAFT SERVICE & REFRESHMENT BAR (Right Wall)
	local barCounter = Instance.new("Part")
	barCounter.Name = "CraftServiceBar"
	barCounter.Size = Vector3.new(4.0, 3.6, 38)
	barCounter.Position = LOUNGE_ORIGIN + Vector3.new(57, 1.8, 2)
	barCounter.Anchored = true
	barCounter.Material = Enum.Material.SmoothPlastic
	barCounter.Color = Color3.fromRGB(32, 36, 46)
	barCounter.Parent = loungeFolder

	local barTop = Instance.new("Part")
	barTop.Size = Vector3.new(4.6, 0.3, 38.4)
	barTop.Position = LOUNGE_ORIGIN + Vector3.new(57, 3.7, 2)
	barTop.Anchored = true
	barTop.Material = Enum.Material.Metal
	barTop.Color = Color3.fromRGB(245, 184, 0)
	barTop.Parent = loungeFolder

	local barSign = Instance.new("Part")
	barSign.Size = Vector3.new(0.3, 2.0, 24)
	barSign.Position = LOUNGE_ORIGIN + Vector3.new(58.5, 9.5, 2)
	barSign.Anchored = true
	barSign.Material = Enum.Material.SmoothPlastic
	barSign.Color = Color3.fromRGB(15, 18, 24)
	barSign.Parent = loungeFolder

	local bsGui = Instance.new("SurfaceGui")
	bsGui.Face = Enum.NormalId.Left
	bsGui.Parent = barSign
	local bsText = Instance.new("TextLabel")
	bsText.Size = UDim2.new(1, 0, 1, 0)
	bsText.BackgroundTransparency = 1
	bsText.TextColor3 = Color3.fromRGB(255, 205, 80)
	bsText.Font = Enum.Font.GothamBold
	bsText.TextSize = 26
	bsText.Text = "★ CRAFT SERVICE // 选手茶歇吧台 ★"
	bsText.Parent = bsGui

	-- 8. WALL OF FAME & BROADCAST VIDEO WALL (Back Wall)
	local mainTV = Instance.new("Part")
	mainTV.Name = "CenterStudioTV"
	mainTV.Size = Vector3.new(28, 12, 0.4)
	mainTV.Position = LOUNGE_ORIGIN + Vector3.new(0, 13, 38.6)
	mainTV.Anchored = true
	mainTV.Material = Enum.Material.SmoothPlastic
	mainTV.Color = Color3.fromRGB(12, 14, 18)
	mainTV.Parent = loungeFolder

	local tvGui = Instance.new("SurfaceGui")
	tvGui.Face = Enum.NormalId.Front
	tvGui.Parent = mainTV
	local tvText = Instance.new("TextLabel")
	tvText.Size = UDim2.new(1, 0, 1, 0)
	tvText.BackgroundTransparency = 1
	tvText.TextColor3 = Color3.fromRGB(255, 215, 60)
	tvText.Font = Enum.Font.GothamBold
	tvText.TextSize = 34
	tvText.Text = "★ 金 库 之 夜 · THE VAULT ★\n[ 美国娱乐真人秀 · 第三季 ]\n\n超级奖池总额：¥ 12,000,000\n十秒决断 · 极限博弈 · 选手备战中"
	tvText.Parent = tvGui

	local sideTVLeft = Instance.new("Part")
	sideTVLeft.Size = Vector3.new(16, 9, 0.4)
	sideTVLeft.Position = LOUNGE_ORIGIN + Vector3.new(-28, 13, 38.6)
	sideTVLeft.Anchored = true
	sideTVLeft.Material = Enum.Material.SmoothPlastic
	sideTVLeft.Color = Color3.fromRGB(12, 14, 18)
	sideTVLeft.Parent = loungeFolder

	local stv1Gui = Instance.new("SurfaceGui"); stv1Gui.Face = Enum.NormalId.Front; stv1Gui.Parent = sideTVLeft
	local stv1Text = Instance.new("TextLabel"); stv1Text.Size = UDim2.new(1, 0, 1, 0); stv1Text.BackgroundTransparency = 1
	stv1Text.TextColor3 = Color3.fromRGB(220, 230, 245); stv1Text.Font = Enum.Font.GothamMedium; stv1Text.TextSize = 24
	stv1Text.Text = "● LIVE FEED\n演播舞台 1 号机位\n[ 状态：等待挑战者登台 ]"; stv1Text.Parent = stv1Gui

	local sideTVRight = Instance.new("Part")
	sideTVRight.Size = Vector3.new(16, 9, 0.4)
	sideTVRight.Position = LOUNGE_ORIGIN + Vector3.new(28, 13, 38.6)
	sideTVRight.Anchored = true
	sideTVRight.Material = Enum.Material.SmoothPlastic
	sideTVRight.Color = Color3.fromRGB(12, 14, 18)
	sideTVRight.Parent = loungeFolder

	local stv2Gui = Instance.new("SurfaceGui"); stv2Gui.Face = Enum.NormalId.Front; stv2Gui.Parent = sideTVRight
	local stv2Text = Instance.new("TextLabel"); stv2Text.Size = UDim2.new(1, 0, 1, 0); stv2Text.BackgroundTransparency = 1
	stv2Text.TextColor3 = Color3.fromRGB(245, 184, 0); stv2Text.Font = Enum.Font.GothamMedium; stv2Text.TextSize = 24
	stv2Text.Text = "🏆 荣耀殿堂\n#1 CyberBreaker ¥12,000,000\n#2 VaultKing ¥8,500,000"; stv2Text.Parent = stv2Gui

	-- 9. 8 DISTRIBUTED SPAWN LOCATIONS (分散在大厅各个沙发区与地毯，容纳几十人)
	local spawnCoords = {
		Vector3.new(0, 0, 0),
		Vector3.new(-34, 0, -14),
		Vector3.new(-34, 0, 18),
		Vector3.new(34, 0, -14),
		Vector3.new(34, 0, 18),
		Vector3.new(0, 0, -18),
		Vector3.new(-18, 0, 4),
		Vector3.new(18, 0, 4),
	}

	local primarySpawn: SpawnLocation? = nil
	for idx, sOffset in ipairs(spawnCoords) do
		local sLoc = Instance.new("SpawnLocation")
		sLoc.Name = "LoungeSpawn_" .. idx
		sLoc.Size = Vector3.new(4.5, 0.3, 4.5)
		sLoc.Position = LOUNGE_ORIGIN + sOffset + Vector3.new(0, 0.2, 0)
		sLoc.Anchored = true
		sLoc.Material = Enum.Material.Fabric
		sLoc.Color = Color3.fromRGB(35, 40, 52)
		sLoc.CanCollide = true
		sLoc.Parent = loungeFolder
		if idx == 1 then primarySpawn = sLoc end
	end

	-- Ensure any external default SpawnLocation is relocated here
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("SpawnLocation") and not desc.Name:find("LoungeSpawn") and primarySpawn then
			desc.CFrame = primarySpawn.CFrame
			desc.Transparency = 1
			desc.CanCollide = false
		end
	end

	----------------------------------------------------------------------------
	-- SECTION B: GAME SHOW MAIN STAGE ARENA (THE VAULT STAGE // 演播厅舞台)
	----------------------------------------------------------------------------
	local arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "ShowArena"
	arenaFolder.Parent = stageFolder

	-- 1. Heavy Stage Platform (Industrial Cold-Rolled Steel & DiamondPlate)
	local stageFloor = Instance.new("Part")
	stageFloor.Name = "HeavyStageFloor"
	stageFloor.Shape = Enum.PartType.Cylinder
	stageFloor.Size = Vector3.new(1.6, 56, 56)
	stageFloor.CFrame = CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90))
	stageFloor.Anchored = true
	stageFloor.Material = Enum.Material.Metal
	stageFloor.Color = Color3.fromRGB(20, 22, 26) -- Stealth Gunmetal Grey
	stageFloor.Parent = arenaFolder

	-- Subtle Dark Steel Inset Circle (No eye-blinding neon yellow!)
	local innerStageFloor = Instance.new("Part")
	innerStageFloor.Name = "InnerStageFloor"
	innerStageFloor.Shape = Enum.PartType.Cylinder
	innerStageFloor.Size = Vector3.new(1.65, 48, 48)
	innerStageFloor.CFrame = CFrame.new(0, 0.82, 0) * CFrame.Angles(0, 0, math.rad(90))
	innerStageFloor.Anchored = true
	innerStageFloor.Material = Enum.Material.DiamondPlate
	innerStageFloor.Color = Color3.fromRGB(28, 30, 36)
	innerStageFloor.Parent = arenaFolder

	-- 2. Central Breaker Pedestal (Player Deciding Podium)
	local centerPlatform = Instance.new("Part")
	centerPlatform.Name = "CenterPlatform"
	centerPlatform.Shape = Enum.PartType.Cylinder
	centerPlatform.Size = Vector3.new(1.3, 9.5, 9.5)
	centerPlatform.CFrame = CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90))
	centerPlatform.Anchored = true
	centerPlatform.Material = Enum.Material.DiamondPlate
	centerPlatform.Color = Color3.fromRGB(18, 20, 24)
	centerPlatform.Parent = arenaFolder

	-- 3. Overhead Lighting Truss Rig (Real TV Studio Overhead Rig)
	local trussHolder = Instance.new("Model")
	trussHolder.Name = "LightingTrussRig"
	trussHolder.Parent = arenaFolder

	local trussBeam1 = Instance.new("Part")
	trussBeam1.Size = Vector3.new(38, 1.2, 1.2)
	trussBeam1.Position = Vector3.new(0, 25, 0)
	trussBeam1.Anchored = true
	trussBeam1.Material = Enum.Material.Metal
	trussBeam1.Color = Color3.fromRGB(25, 27, 32)
	trussBeam1.Parent = trussHolder

	local trussBeam2 = Instance.new("Part")
	trussBeam2.Size = Vector3.new(1.2, 1.2, 38)
	trussBeam2.Position = Vector3.new(0, 25, 0)
	trussBeam2.Anchored = true
	trussBeam2.Material = Enum.Material.Metal
	trussBeam2.Color = Color3.fromRGB(25, 27, 32)
	trussBeam2.Parent = trussHolder

	-- 4 Directional Studio Spotlights targeting Central Podium
	local spotPositions = {
		Vector3.new(14, 24.5, 14),
		Vector3.new(-14, 24.5, 14),
		Vector3.new(14, 24.5, -14),
		Vector3.new(-14, 24.5, -14),
	}

	for _, pos in ipairs(spotPositions) do
		local spotHead = Instance.new("Part")
		spotHead.Size = Vector3.new(1.2, 1.8, 1.2)
		spotHead.CFrame = CFrame.lookAt(pos, Vector3.new(0, 2, 0))
		spotHead.Anchored = true
		spotHead.Material = Enum.Material.Metal
		spotHead.Color = Color3.fromRGB(15, 16, 20)
		spotHead.Parent = trussHolder

		local studioSpot = Instance.new("SpotLight")
		studioSpot.Brightness = 1.6
		studioSpot.Range = 36
		studioSpot.Angle = 48
		studioSpot.Color = Color3.fromRGB(255, 245, 230) -- Clean warm studio key light
		studioSpot.Shadows = true
		studioSpot.Face = Enum.NormalId.Front
		studioSpot.Parent = spotHead
	end

	-- 4. Central Emergency Lever Console (Lifeline)
	local consoleBase = Instance.new("Part")
	consoleBase.Name = "ConsoleBase"
	consoleBase.Size = Vector3.new(2.4, 1.8, 1.8)
	consoleBase.Position = Vector3.new(0, 2.3, 2.5)
	consoleBase.Anchored = true
	consoleBase.Material = Enum.Material.Metal
	consoleBase.Color = Color3.fromRGB(26, 29, 36)
	consoleBase.Parent = arenaFolder

	local leverHandle = Instance.new("Part")
	leverHandle.Name = "LeverHandle"
	leverHandle.Size = Vector3.new(0.35, 2.0, 0.35)
	leverHandle.CFrame = CFrame.new(0, 3.8, 2.5) * CFrame.Angles(math.rad(28), 0, 0)
	leverHandle.Anchored = true
	leverHandle.Material = Enum.Material.SmoothPlastic
	leverHandle.Color = Color3.fromRGB(220, 45, 45) -- Industrial Emergency Red
	leverHandle.Parent = arenaFolder

	local leverPrompt = Instance.new("ProximityPrompt")
	leverPrompt.ActionText = "拉下求助操纵杆 (Audience Lifeline)"
	leverPrompt.ObjectText = "中央控制台"
	leverPrompt.HoldDuration = 0.5
	leverPrompt.MaxActivationDistance = 9
	leverPrompt.RequiresLineOfSight = false
	leverPrompt.Enabled = false
	leverPrompt.Parent = consoleBase

	StageBuilder.leverPrompt = leverPrompt
	StageBuilder.leverHandle = leverHandle

	-- 5. Curator Screen (TV Show Giant Studio Display)
	local screenFrame = Instance.new("Part")
	screenFrame.Name = "CuratorScreenFrame"
	screenFrame.Size = Vector3.new(22, 11, 1.2)
	screenFrame.Position = Vector3.new(0, 9.5, -24)
	screenFrame.Anchored = true
	screenFrame.Material = Enum.Material.Metal
	screenFrame.Color = Color3.fromRGB(15, 17, 22)
	screenFrame.Parent = arenaFolder

	local screenGui = Instance.new("SurfaceGui")
	screenGui.Face = Enum.NormalId.Front
	screenGui.CanvasSize = Vector2.new(1400, 700)
	screenGui.Parent = screenFrame

	local headerText = Instance.new("TextLabel")
	headerText.Size = UDim2.new(1, 0, 0, 90)
	headerText.Position = UDim2.new(0, 0, 0, 20)
	headerText.BackgroundTransparency = 1
	headerText.TextColor3 = Color3.fromRGB(255, 195, 30)
	headerText.Font = Enum.Font.GothamBold
	headerText.TextSize = 40
	headerText.Text = "★ 金 库 之 夜 · THE VAULT ★"
	headerText.Parent = screenGui

	local screenText = Instance.new("TextLabel")
	screenText.Name = "CuratorText"
	screenText.Size = UDim2.new(1, -60, 1, -140)
	screenText.Position = UDim2.new(0, 30, 0, 110)
	screenText.BackgroundTransparency = 1
	screenText.TextColor3 = Color3.fromRGB(240, 245, 255)
	screenText.TextScaled = true
	screenText.Font = Enum.Font.GothamMedium
	screenText.Text = "十秒读秒，两个按钮。\n拿钱走人，还是赌上一切翻倍？"
	screenText.Parent = screenGui

	-- 6. Generate 12 Realistic Heavy Gunmetal Circular Vaults (NO BLINDING YELLOW!)
	local radius = 22
	local totalVaults = GameConfig.TOTAL_VAULTS

	for i = 1, totalVaults do
		local angle = math.rad((i - 1) * (360 / totalVaults))
		local x = math.sin(angle) * radius
		local z = math.cos(angle) * radius
		local vaultCenter = Vector3.new(x, 4.2, z)
		local lookCenter = Vector3.new(0, 4.2, 0)

		local vaultModel = Instance.new("Model")
		vaultModel.Name = "Vault_" .. i
		vaultModel.Parent = arenaFolder

		-- Heavy Base Pedestal (Dark Industrial Iron)
		local pedestal = Instance.new("Part")
		pedestal.Name = "Pedestal"
		pedestal.Size = Vector3.new(5.0, 1.4, 4.2)
		pedestal.CFrame = CFrame.lookAt(Vector3.new(x, 1.4, z), Vector3.new(0, 1.4, 0))
		pedestal.Anchored = true
		pedestal.Material = Enum.Material.Metal
		pedestal.Color = Color3.fromRGB(25, 28, 34)
		pedestal.Parent = vaultModel

		-- Outer Vault Heavy Frame (Cast Iron / Brushed Steel)
		local outerFrame = Instance.new("Part")
		outerFrame.Name = "OuterFrame"
		outerFrame.Size = Vector3.new(4.6, 5.6, 2.2)
		outerFrame.CFrame = CFrame.lookAt(vaultCenter, lookCenter)
		outerFrame.Anchored = true
		outerFrame.Material = Enum.Material.Metal
		outerFrame.Color = Color3.fromRGB(28, 31, 38)
		outerFrame.Parent = vaultModel

		-- Door Assembly
		local doorAssembly = Instance.new("Model")
		doorAssembly.Name = "DoorAssembly"
		doorAssembly.Parent = vaultModel

		-- Circular Heavy Bank Vault Door (Matte DiamondPlate Gunmetal)
		local circularDoor = Instance.new("Part")
		circularDoor.Name = "CircularDoor"
		circularDoor.Shape = Enum.PartType.Cylinder
		circularDoor.Size = Vector3.new(0.8, 4.0, 4.0)
		circularDoor.CFrame = outerFrame.CFrame * CFrame.new(0, 0, -1.0) * CFrame.Angles(0, math.rad(90), 0)
		circularDoor.Anchored = true
		circularDoor.Material = Enum.Material.DiamondPlate
		circularDoor.Color = Color3.fromRGB(36, 40, 48)
		circularDoor.Parent = doorAssembly

		-- Central Spoke Wheel (Brushed Silver Chrome with dark hub)
		local spokeWheel = Instance.new("Part")
		spokeWheel.Name = "SpokeWheel"
		spokeWheel.Shape = Enum.PartType.Cylinder
		spokeWheel.Size = Vector3.new(0.5, 1.8, 1.8)
		spokeWheel.CFrame = circularDoor.CFrame * CFrame.new(0.48, 0, 0)
		spokeWheel.Anchored = true
		spokeWheel.Material = Enum.Material.Metal
		spokeWheel.Color = Color3.fromRGB(155, 162, 172) -- Real Chrome Steel
		spokeWheel.Parent = doorAssembly

		-- Spoke handles (Cross bars - Chrome Steel)
		local spokeBar1 = Instance.new("Part")
		spokeBar1.Size = Vector3.new(0.2, 2.5, 0.2)
		spokeBar1.CFrame = spokeWheel.CFrame * CFrame.Angles(0, 0, math.rad(90))
		spokeBar1.Anchored = true
		spokeBar1.Material = Enum.Material.Metal
		spokeBar1.Color = Color3.fromRGB(180, 186, 196)
		spokeBar1.Parent = doorAssembly

		local spokeBar2 = Instance.new("Part")
		spokeBar2.Size = Vector3.new(0.2, 2.5, 0.2)
		spokeBar2.CFrame = spokeWheel.CFrame * CFrame.Angles(math.rad(90), 0, 0)
		spokeBar2.Anchored = true
		spokeBar2.Material = Enum.Material.Metal
		spokeBar2.Color = Color3.fromRGB(180, 186, 196)
		spokeBar2.Parent = doorAssembly

		-- 4 Heavy Mechanical Lock Bolts (Stainless Steel)
		local bolts: { BasePart } = {}
		for b = 1, 4 do
			local boltAngle = math.rad((b - 1) * 90)
			local bolt = Instance.new("Part")
			bolt.Name = "Bolt_" .. b
			bolt.Size = Vector3.new(0.4, 0.4, 0.7)
			bolt.CFrame = circularDoor.CFrame * CFrame.Angles(boltAngle, 0, 0) * CFrame.new(0, 2.05, 0)
			bolt.Anchored = true
			bolt.Material = Enum.Material.Metal
			bolt.Color = Color3.fromRGB(205, 212, 222)
			bolt.Parent = doorAssembly
			table.insert(bolts, bolt)
		end

		-- Small Status Indicator LED on Top of Door (Subtle, NOT A BLOWOUT LIGHT!)
		local indicatorLamp = Instance.new("Part")
		indicatorLamp.Name = "StatusLamp"
		indicatorLamp.Size = Vector3.new(0.4, 0.2, 0.4)
		indicatorLamp.CFrame = outerFrame.CFrame * CFrame.new(0, 2.9, -1.0)
		indicatorLamp.Anchored = true
		indicatorLamp.Material = Enum.Material.SmoothPlastic
		indicatorLamp.Color = Color3.fromRGB(40, 45, 55)
		indicatorLamp.Parent = vaultModel

		local pointGlow = Instance.new("PointLight")
		pointGlow.Brightness = 0.5 -- Very soft indicator
		pointGlow.Range = 4
		pointGlow.Color = Color3.fromRGB(100, 140, 180) -- Gentle cool blue standby
		pointGlow.Parent = indicatorLamp

		-- Billboard Tag (High readability, elegant compact dark badge)
		local bbGui = Instance.new("BillboardGui")
		bbGui.Size = UDim2.new(0, 110, 0, 38)
		bbGui.StudsOffset = Vector3.new(0, 3.5, 0)
		bbGui.AlwaysOnTop = false
		bbGui.MaxDistance = 50
		bbGui.Parent = outerFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
		label.BackgroundTransparency = 0.2
		label.TextColor3 = Color3.fromRGB(225, 230, 240)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Text = string.format("金库 #%02d", i)
		label.Parent = bbGui

		local lblStroke = Instance.new("UIStroke")
		lblStroke.Color = Color3.fromRGB(70, 80, 95)
		lblStroke.Thickness = 1
		lblStroke.Parent = label

		local lblCorner = Instance.new("UICorner")
		lblCorner.CornerRadius = UDim.new(0, 6)
		lblCorner.Parent = label

		-- Proximity Prompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "锁定底牌 (Claim Vault)"
		prompt.ObjectText = string.format("金库 #%02d", i)
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = outerFrame

		vaultModels[i] = {
			model = vaultModel,
			vaultId = i,
			doorAssembly = doorAssembly,
			mainDoor = circularDoor,
			spokeWheel = spokeWheel,
			lockBolts = bolts,
			prompt = prompt,
			displayGui = bbGui,
			displayLabel = label,
			indicatorLight = pointGlow,
		}
	end

	return vaultModels
end

-- Realistic Hydraulic Opening Animation
function StageBuilder.openVaultDoor(vaultId: number, rewardValue: number)
	local v = vaultModels[vaultId]
	if not v then return end

	-- 1. Rotate the spoke wheel (Unlocking Mechanism)
	local wheelTween = TweenService:Create(v.spokeWheel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = v.spokeWheel.CFrame * CFrame.Angles(math.rad(120), 0, 0)
	})
	wheelTween:Play()

	-- 2. Steam / Hydraulic Pressure Release Particles
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 70
	emitter.Lifetime = NumberRange.new(0.3, 0.55)
	emitter.Speed = NumberRange.new(3, 6)
	emitter.SpreadAngle = Vector2.new(50, 50)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1.8),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	emitter.Color = ColorSequence.new(Color3.fromRGB(220, 225, 235)) -- Cool white steam
	emitter.Parent = v.spokeWheel

	task.delay(0.4, function()
		emitter.Enabled = false
		task.wait(0.8)
		emitter:Destroy()
	end)

	-- 3. Retract lock bolts and swing/drop heavy circular door
	task.delay(0.2, function()
		for _, b in ipairs(v.lockBolts) do
			TweenService:Create(b, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = b.CFrame * CFrame.new(0, -0.4, 0)
			}):Play()
		end

		local targetDoorCF = v.mainDoor.CFrame * CFrame.new(0, -3.8, 0)
		TweenService:Create(v.mainDoor, TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = targetDoorCF
		}):Play()
	end)

	-- 4. Update Visuals
	v.indicatorLight.Color = if rewardValue >= 2500 then Color3.fromRGB(245, 184, 0) else Color3.fromRGB(120, 130, 145)
	v.indicatorLight.Brightness = 1.2
	v.displayLabel.TextColor3 = if rewardValue >= 2500 then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(200, 210, 225)
	v.displayLabel.Text = "¥ " .. RewardPool.formatNumber(rewardValue)
	v.prompt.Enabled = false
end

function StageBuilder.setVaultClaimed(vaultId: number)
	local v = vaultModels[vaultId]
	if not v then return end

	v.indicatorLight.Color = Color3.fromRGB(245, 184, 0) -- Subdued gold status
	v.indicatorLight.Brightness = 1.5
	v.displayLabel.TextColor3 = Color3.fromRGB(255, 205, 75)
	v.displayLabel.Text = string.format("★ 底牌 #%02d ★", vaultId)
	v.prompt.Enabled = false
end

function StageBuilder.animateLeverPull()
	if StageBuilder.leverHandle then
		local targetCF = CFrame.new(0, 3.2, 2.5) * CFrame.Angles(math.rad(-45), 0, 0)
		local tween = TweenService:Create(StageBuilder.leverHandle, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = targetCF,
			Color = Color3.fromRGB(255, 200, 50),
		})
		tween:Play()
	end
	if StageBuilder.leverPrompt then
		StageBuilder.leverPrompt.Enabled = false
	end
end

function StageBuilder.resetLever()
	if StageBuilder.leverHandle then
		local baseCF = CFrame.new(0, 3.8, 2.5) * CFrame.Angles(math.rad(28), 0, 0)
		StageBuilder.leverHandle.CFrame = baseCF
		StageBuilder.leverHandle.Color = Color3.fromRGB(220, 45, 45)
	end
	if StageBuilder.leverPrompt then
		StageBuilder.leverPrompt.Enabled = false
	end
end

function StageBuilder.setLeverEnabled(enabled: boolean)
	if StageBuilder.leverPrompt then
		StageBuilder.leverPrompt.Enabled = enabled
	end
end

function StageBuilder.updatePromptAction(actionText: string)
	for _, v in pairs(vaultModels) do
		if v.prompt.Enabled then
			v.prompt.ActionText = actionText
		end
	end
end

function StageBuilder.getVaults(): { [number]: VaultModel }
	return vaultModels
end

return StageBuilder
