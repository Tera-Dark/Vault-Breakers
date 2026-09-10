--!nonstrict
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C = require(ReplicatedStorage.VaultBreakers.Config.VisualConfig)
local Numbers = require(ReplicatedStorage.VaultBreakers.Config.RewardPool)
local G = require(script.Parent.Geometry)
local Vault = require(script.Parent.VaultModel)
local ShowSet = require(script.Parent.ShowSet)
local StageBuilder = {}
local Arena = {}
Arena.__index = Arena
local WHITE = Color3.fromRGB(255, 242, 218)
local MATTE = Enum.Material.SmoothPlastic

local function lightPanel(parent, cf, width, depth, brightness)
	G.block(parent, "LightHousing", Vector3.new(width + 0.4, 0.3, depth + 0.4), cf, C.Ink)
	local diffuser = G.block(parent, "Diffuser", Vector3.new(width, 0.08, depth), cf * CFrame.new(0, -0.2, 0), C.Ivory, Enum.Material.Neon)
	local light = Instance.new("SurfaceLight")
	light.Face, light.Color, light.Brightness = Enum.NormalId.Bottom, WHITE, brightness
	light.Angle, light.Range, light.Shadows = 120, 55, false
	light.Parent = diffuser
end

local function cameraProp(parent, cf)
	local head = cf * CFrame.new(0, 5.0, 0)
	G.block(parent, "StudioCamera", Vector3.new(1.25, 0.85, 1.65), head, C.Ink)
	G.disk(parent, "LensHousing", head * CFrame.new(0, 0, -1.0), 0.75, 0.55, C.Steel)
	G.disk(parent, "LensGlass", head * CFrame.new(0, 0, -1.3), 0.57, 0.06, C.Teal, Enum.Material.Glass)
	for i = 1, 3 do
		local angle = i * math.pi * 2 / 3
		G.beam(parent, "Tripod", (cf * CFrame.new(0, 4.7, 0)).Position,
			(cf * CFrame.new(math.cos(angle) * 1.3, 0.5, math.sin(angle) * 1.3)).Position, 0.14, C.Steel)
	end
end

function Arena.new(root, cameraFolder, id, origin, radius, width)
	local self = setmetatable({ id = id, origin = origin, radius = radius, generation = 0, tweens = {}, vaults = {} }, Arena)
	self.root = Instance.new("Model")
	self.root.Name = id
	self.root:SetAttribute("ArenaId", id)
	self.root.Parent = root
	local cf = CFrame.new(origin)
	local function box(name, size, pos, color, material, collide)
		return G.block(self.root, name, size, cf * CFrame.new(pos), color, material, collide)
	end
	local depth = radius + 17
	box("StudioFloor", Vector3.new(width, 1.2, depth * 2), Vector3.new(0, 0.2, 0), C.Panel, MATTE, true)
	local stage = G.disk(self.root, "PerformanceDeck", cf * CFrame.new(0, 0.88, 0) * CFrame.Angles(math.pi / 2, 0, 0), radius * 2 + 12, 0.24, C.Raised)
	stage.CanCollide = true
	G.ring(self.root, "DeckInlay", cf * CFrame.new(0, 1.02, 0) * CFrame.Angles(math.pi / 2, 0, 0), radius - 5, 0.12, 0.025, C.Amber, 40)
	G.ring(self.root, "InnerInlay", cf * CFrame.new(0, 1.025, 0) * CFrame.Angles(math.pi / 2, 0, 0), 8.3, 0.10, 0.025, C.Steel, 28)
	box("BackWall", Vector3.new(width, 31, 1), Vector3.new(0, 15.5, -depth), C.Ink, MATTE, true)
	for _, x in { -width / 2, width / 2 } do
		box("SideWall", Vector3.new(1, 31, depth * 2), Vector3.new(x, 15.5, 0), C.Ink, MATTE, true)
		for z = -depth + 7, depth - 4, 7 do
			box("AcousticFin", Vector3.new(0.7, 22, 1.2), Vector3.new(x - math.sign(x) * 0.7, 12, z), C.Raised)
		end
		box("WallWainscot", Vector3.new(0.65, 0.12, depth * 2 - 2), Vector3.new(x - math.sign(x), 8.5, 0), C.Steel)
	end
	-- A low front wall leaves the spectator balcony's sightline open.
	box("FrontGuard", Vector3.new(width, 7, 0.8), Vector3.new(0, 3.5, depth), C.Panel, MATTE, true)
	box("Ceiling", Vector3.new(width, 0.8, depth * 2), Vector3.new(0, 31.2, 0), C.Ink, MATTE, true)
	-- Structural grid, diagonal truss members, and four broad studio softboxes.
	for _, x in { -20, 20 } do
		box("TrussChord", Vector3.new(0.24, 0.24, depth * 1.45), Vector3.new(x, 27.5, 0), C.Steel)
		box("TrussChord", Vector3.new(0.24, 0.24, depth * 1.45), Vector3.new(x, 26.5, 0), C.Steel)
		for z = -depth * 0.65, depth * 0.65, 6 do
			G.beam(self.root, "TrussWeb", origin + Vector3.new(x, 26.5, z), origin + Vector3.new(x, 27.5, z + 3), 0.12, C.Line)
		end
		for _, z in { -18, 18 } do lightPanel(self.root, cf * CFrame.new(x, 26, z), 9, 7, 2.5) end
	end
	for _, x in { -width * 0.35, width * 0.35 } do
		local lamp = box("SideFill", Vector3.new(1.0, 5.0, 0.3), Vector3.new(x, 13, -depth + 0.8), C.Teal, Enum.Material.Neon)
		local fill = Instance.new("PointLight")
		fill.Brightness, fill.Range, fill.Color, fill.Shadows = 1.1, 36, C.Teal, false
		fill.Parent = lamp
	end
	-- A legible broadcast screen above the rear vaults, facing the contestant.
	local screenCF = cf * CFrame.new(0, 18.9, -depth + 0.8) * CFrame.Angles(0, math.pi, 0)
	G.block(self.root, "ScreenBezel", Vector3.new(31, 10.2, 0.55), screenCF, C.Steel)
	local screen = G.block(self.root, "CuratorScreen", Vector3.new(30.4, 9.6, 0.14), screenCF * CFrame.new(0, 0, -0.38), C.Ink, MATTE)
	self.screenLabel = G.label(screen, "THE CURATOR\n\nKNOW WHEN TO LEAVE.", C.Ivory, 1200, 380)
	local onAir = G.block(self.root, "OnAir", Vector3.new(6.4, 0.9, 0.15), screenCF * CFrame.new(0, 6.1, -0.1), C.Raised)
	self.onAirLabel = G.label(onAir, "STANDBY", C.Muted, 420, 60)
	for _, x in { -21, 21 } do
		local sign = G.block(self.root, "StudioWayfinding", Vector3.new(6.5, 2.0, 0.12), cf * CFrame.new(x, 20, -depth + 0.7) * CFrame.Angles(0, math.pi, 0), C.Panel)
		G.label(sign, if id == "MAIN" then "01\nMAIN STAGE" else "02\nQUICK RUN", C.Muted, 300, 130)
	end
	local pollCF = CFrame.lookAt(origin + Vector3.new(width / 2 - 0.8, 15, 0), origin + Vector3.new(0, 15, 0))
	local pollScreen = G.block(self.root, "AudienceScreen", Vector3.new(16, 5, 0.2), pollCF, C.Panel)
	self.pollLabel = G.label(pollScreen, "AUDIENCE OPINIONS\nNO VOTES YET", C.Teal, 900, 250)
	for index = 1, 12 do
		local angle = math.rad(40 + (index - 1) * 280 / 11)
		local position = origin + Vector3.new(math.sin(angle) * radius, 1.02, math.cos(angle) * radius)
		local vaultCF = CFrame.lookAt(position, origin + Vector3.new(0, 1.02, 0))
		self.vaults[index] = Vault.build(self.root, index, vaultCF, id == "MAIN")
	end
	-- Contestant podium with tactile decision keys; UI is an accessibility alternative.
	local consoleCF = cf * CFrame.new(0, 0, 9) * CFrame.Angles(0, math.pi, 0)
	G.block(self.root, "ConsoleFoot", Vector3.new(7.5, 0.35, 3.0), consoleCF * CFrame.new(0, 1.23, 0), C.Ink)
	G.block(self.root, "ConsoleStem", Vector3.new(5.8, 2.2, 1.8), consoleCF * CFrame.new(0, 2.5, 0), C.Panel, nil, true)
	G.block(self.root, "ConsoleTop", Vector3.new(8.0, 0.38, 3.4), consoleCF * CFrame.new(0, 3.85, 0), C.Ivory, MATTE)
	self.buttons = {}
	for i, color in { C.Amber, C.Teal } do
		-- Console faces +Z: local +X is the contestant's left.
		local x = if i == 1 then 2.0 else -2.0
		local key = G.block(self.root, "DecisionKey" .. i, Vector3.new(2.1, 0.22, 1.5), consoleCF * CFrame.new(x, 4.15, 0), color, MATTE)
		local plaque = G.block(self.root, "DecisionLegend", Vector3.new(2.8, 0.6, 0.07), consoleCF * CFrame.new(x, 3.42, -0.98), C.Ink)
		local text = if i == 1 then "EXTRACT" else "PUSH"
		self.buttons[i] = { part = key, label = G.label(plaque, text, color, 280, 60), prompt = G.prompt(key, "DecisionPrompt" .. i, text, "DECISION CONSOLE", 0.15) }
		self.buttons[i].prompt.Enabled = false
	end
	local leverBase = box("LifelineConsole", Vector3.new(2.4, 2.3, 2.0), Vector3.new(-7.8, 2.35, 6.8), C.Panel, nil, true)
	local leverFrame = cf * CFrame.new(-7.8, 3.4, 6.8)
	local lever = Instance.new("Model")
	lever.Name, lever.Parent = "AudienceLever", self.root
	local pivot = G.hidden(lever, "LeverPivot", leverFrame)
	lever.PrimaryPart = pivot
	G.block(lever, "Shaft", Vector3.new(0.18, 1.2, 0.18), leverFrame * CFrame.new(0, 0.6, 0) * CFrame.Angles(0.2, 0, 0), C.Silver)
	G.block(lever, "Grip", Vector3.new(0.95, 0.3, 0.3), leverFrame * CFrame.new(0, 1.2, 0.1), C.Red, MATTE)
	local leverSign = G.block(self.root, "LeverLegend", Vector3.new(2.4, 1.0, 0.12), cf * CFrame.new(-7.8, 2.6, 7.84) * CFrame.Angles(0, math.pi, 0), C.Ink)
	G.label(leverSign, if id == "MAIN" then "AUDIENCE\nLIFELINE" else "QUICK RUN\nNO LIFELINE", C.Muted, 220, 100)
	self.lever, self.leverClosed = lever, lever:GetPivot()
	self.leverLamp = box("LifelineReadyStrip", Vector3.new(1.8, 0.08, 0.08), Vector3.new(-7.8, 3.55, 7.79), C.Line, Enum.Material.Neon)
	self.leverPrompt = G.prompt(leverBase, "LifelinePrompt", "ASK THE AUDIENCE", "ONE LIFELINE / ROUND 3+", 0.4)
	self.leverPrompt.Enabled = false
	cameraProp(self.root, cf * CFrame.new(-radius + 3, 0.9, radius + 5) * CFrame.Angles(0, -0.7, 0))
	cameraProp(self.root, cf * CFrame.new(radius - 3, 0.9, radius + 5) * CFrame.Angles(0, 0.7, 0))
	self.spawn = CFrame.lookAt(origin + Vector3.new(0, 4.4, 16), origin + Vector3.new(0, 4.4, -5))
	G.hidden(cameraFolder, id .. "Wide", CFrame.lookAt(origin + Vector3.new(0, 23, radius + 10), origin + Vector3.new(0, 5, -5)))
	return self
end

function Arena:_animate(model, target, seconds)
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()
	local generation = self.generation
	local connection = value:GetPropertyChangedSignal("Value"):Connect(function()
		if self.generation == generation and model.Parent then model:PivotTo(value.Value) end
	end)
	local tween = TweenService:Create(value, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = target })
	local record = { tween = tween, value = value, connection = connection }
	table.insert(self.tweens, record)
	tween:Play()
end

function Arena:open(id, slow)
	local vault = self.vaults[id]
	if not vault or vault.opened then return end
	vault.opened = true
	vault.prompt.Enabled = false
	self:_animate(vault.wheel, vault.wheelClosed * CFrame.Angles(math.rad(85), 0, 0), 0.22)
	for _, rod in vault.rods do
		local tween = TweenService:Create(rod.part, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = rod.closed * CFrame.new(-0.35, 0, 0) })
		table.insert(self.tweens, { tween = tween })
		tween:Play()
	end
	vault.emitter:Emit(7)
	local generation = self.generation
	task.delay(if slow then 1.0 else 0.25, function()
		if self.generation ~= generation then return end
		self:_animate(vault.door, vault.closed * CFrame.Angles(0, math.rad(108), 0), if slow then 1.9 else 0.9)
	end)
end

function Arena:reset()
	self.generation += 1
	for _, record in self.tweens do
		record.tween:Cancel()
		if record.connection then record.connection:Disconnect() end
		if record.value then record.value:Destroy() end
	end
	self.tweens = {}
	for id, vault in self.vaults do
		vault.door:PivotTo(vault.closed)
		vault.wheel:PivotTo(vault.wheelClosed)
		for _, rod in vault.rods do rod.part.CFrame = rod.closed end
		vault.opened = false
		vault.tag.Text, vault.tag.TextColor3 = string.format("VAULT  /  %02d", id), C.Ivory
		vault.valueLabel.Text, vault.valueLabel.TextColor3 = "SEALED\nUNKNOWN VALUE", C.Muted
		vault.status.Color = C.Teal
		vault.prompt.Enabled = false
		vault.emitter:Clear()
	end
	self.lever:PivotTo(self.leverClosed)
	self.leverPrompt.Enabled = false
end

function Arena:effect(event)
	if event.kind == "START" or event.kind == "RELEASE" then self:reset()
	elseif event.kind == "CLAIM" then
		local vault = self.vaults[event.vaultId]
		vault.tag.Text, vault.tag.TextColor3 = string.format("CLAIM  /  %02d", event.vaultId), C.Amber
		vault.status.Color = C.Amber
	elseif event.kind == "OPEN" then self:open(event.vaultId, false)
	elseif event.kind == "BREACHED" then
		local vault = self.vaults[event.vaultId]
		vault.valueLabel.Text = Numbers.formatNumber(event.value) .. " CR\nELIMINATED"
		vault.valueLabel.TextColor3 = if event.value >= 2500 then C.Red else C.Teal
		vault.status.Color = C.Line
		vault.tag.Text, vault.tag.TextColor3 = string.format("%02d  /  OPENED", event.vaultId), C.Muted
	elseif event.kind == "LIFELINE" then self:_animate(self.lever, self.leverClosed * CFrame.Angles(math.rad(-65), 0, 0), 0.4)
	elseif event.kind == "REVEAL" then
		self:open(event.vaultId, true)
		if event.otherId then self:open(event.otherId, true) end
	elseif event.kind == "SETTLE" then
		local vault = self.vaults[event.chosenId]
		vault.valueLabel.Text = Numbers.formatNumber(event.result.chosenValue) .. " CR\nREVEALED"
		vault.valueLabel.TextColor3, vault.status.Color = C.Amber, C.Amber
		if not event.result.extracted then
			for id, other in self.vaults do
				if other.opened and other.valueLabel.Text:find("SEALED") then
					other.valueLabel.Text = Numbers.formatNumber(if id == event.chosenId then event.result.chosenValue elseif event.result.choice == "SWAP" then event.result.claimValue else event.result.otherValue) .. " CR\nREVEALED"
				end
			end
		end
	end
end

function Arena:update(snapshot)
	local state = snapshot.state
	local rig=self.root:FindFirstChild("ShowRig");local entrance=rig and rig:FindFirstChild("ContestantScreen")
	if entrance then
		entrance.Graphics.Copy.Text=if snapshot.breakerId then "CONTESTANT ON AIR\n"..snapshot.breakerName else "YOUR STAGE AWAITS"
		entrance.Graphics.Portrait.Image=if snapshot.breakerId then "rbxthumb://type=AvatarHeadShot&id="..snapshot.breakerId.."&w=150&h=150"else ""
	end
	for id, vault in self.vaults do
		local data = snapshot.vaults[id]
		vault.prompt.Enabled = ((state == "CLAIM" or state == "BREACH") and data ~= nil and not data.claimed and not data.opened) or (state=="FINAL_CHOICE" and (id==snapshot.claimId or id==snapshot.finalId))
		vault.prompt.ActionText = if state=="FINAL_CHOICE" then (if id==snapshot.claimId then "KEEP / 保留底牌" else "SWAP / 交换金库") elseif state == "CLAIM" then "CLAIM / 锁定底牌" else "BREACH / 开启排除"
	end
	self.leverPrompt.Enabled = snapshot.lifelineAvailable
	self.leverLamp.Color = if snapshot.lifelineAvailable then C.Amber else C.Line
	for i, button in self.buttons do
		local text = if state == "FINAL_CHOICE" then (if i == 1 then "KEEP" else "SWAP") else (if i == 1 then "EXTRACT" else "PUSH")
		button.label.Text, button.prompt.ActionText = text, text
		button.prompt.Enabled = state == "OFFER" or state == "FINAL_CHOICE"
	end
	self.onAirLabel.Text = if state == "IDLE" then "STANDBY" else "ON AIR  /  " .. self.id
	self.onAirLabel.TextColor3 = if state == "IDLE" then C.Muted else C.Amber
	local copy = {
		IDLE = "THE CURATOR\n\nKNOW WHEN TO LEAVE.",
		SHOWTIME = "CONTESTANT ON AIR\n\n"..snapshot.breakerName,
		BREACH_REACT = "ONE VALUE ELIMINATED.\n\nWATCH THE BOARD.",
		OFFER_ROLL = "CALCULATING THE OFFER...",
		CLAIM = "YOUR CLAIM. YOUR CALL.\n\nCHOOSE ONE VAULT.",
		BREACH = string.format("ROUND %02d\n\nOPEN %d MORE VAULTS", snapshot.round, snapshot.quota - snapshot.breached),
		OPENING = "LOCKS RELEASED.\n\nONE POSSIBILITY LEAVES.",
		OFFER = "THE CURATOR OFFERS\n\n" .. Numbers.formatNumber(snapshot.offer) .. " CR",
		LIFELINE = "AUDIENCE LIFELINE\n\nTHE ROOM HAS TEN SECONDS.",
		TRANSITION = "CERTAINTY DECLINED.\n\nTHE RUN CONTINUES.",
		FINAL_CHOICE = "TWO VAULTS. ONE CHOICE.\n\nKEEP  /  SWAP",
		REVEAL = "LIGHTS DOWN.\n\nTHIS WAS ALWAYS A POSSIBILITY.",
		RESULT = "RUN COMPLETE.\n\nYOUR NEXT MOVE AWAITS.",
	}
	self.screenLabel.Text = copy[state] or "THE VAULT"
	local poll = snapshot.poll
	if not snapshot.audience then self.pollLabel.Text = "QUICK RUN\nYOUR OWN STAGE."
	elseif poll.total == 0 then self.pollLabel.Text = "AUDIENCE OPINIONS\nNO VOTES YET"
	else
		local left = math.floor(poll.left / poll.total * 100 + 0.5)
		self.pollLabel.Text = string.format("%s %d%%  /  %s %d%%\n%d FREE OPINIONS", if poll.kind == "FINAL" then "KEEP" else "EXTRACT", left, if poll.kind == "FINAL" then "SWAP" else "PUSH", 100 - left, poll.total)
	end
end

local function buildLounge(root, cameras)
	local lounge = Instance.new("Model")
	lounge.Name, lounge.Parent = "GreenRoom", root
	local cf = CFrame.new(28, 12, 34)
	local function box(name, size, pos, color, mat, collide)
		return G.block(lounge, name, size, cf * CFrame.new(pos), color, mat, collide)
	end
	box("Floor", Vector3.new(172, 1.0, 54), Vector3.new(0, -0.5, 0), C.Raised, MATTE, true)
	box("Ceiling", Vector3.new(172, 0.6, 54), Vector3.new(0, 20.6, 0), C.Panel, MATTE, true)
	box("BackWall", Vector3.new(172, 20, 1.0), Vector3.new(0, 10, 27), C.Panel, MATTE, true)
	for _, x in { -86, 86 } do box("EndWall", Vector3.new(0.8, 20, 54), Vector3.new(x, 10, 0), C.Panel, MATTE, true) end
	for x = -74, 70, 24 do
		lightPanel(lounge, cf * CFrame.new(x, 19.8, 0), 12, 8, 2.2)
		box("WindowMullion", Vector3.new(0.22, 17, 0.3), Vector3.new(x, 9, -27), C.Steel)
	end
	box("ViewingRail", Vector3.new(172, 0.15, 0.7), Vector3.new(0, 4.1, -27), C.Silver)
	local glass = box("ObservationGlass", Vector3.new(172, 16, 0.18), Vector3.new(0, 8.0, -27), C.Steel, Enum.Material.Glass, true)
	glass.Transparency, glass.CastShadow = 0.85, false
	box("WindowSill", Vector3.new(172, 0.20, 2.5), Vector3.new(0, 3.2, -25.9), C.Ivory, MATTE)
	-- Walkable lounge with actual seats, low tables, acoustic treatment and restrained brass trim.
	for _, x in { -54, -25, 27, 57 } do
		box("Rug", Vector3.new(22, 0.035, 16), Vector3.new(x, 0.025, 1), C.Ink, Enum.Material.Fabric)
		for seatIndex = 1, 3 do
			local sx = x + (seatIndex - 2) * 3.2
			box("SofaBase", Vector3.new(3.15, 0.5, 3.4), Vector3.new(sx, 0.85, 6), C.Ink)
			local seat = Instance.new("Seat")
			seat.Name, seat.Size, seat.CFrame = "LoungeSeat", Vector3.new(3.0, 0.65, 3.1), cf * CFrame.new(sx, 1.5, 6)
			seat.Material, seat.Color, seat.Anchored = Enum.Material.Fabric, C.Steel, true
			seat.Parent = lounge
			box("SofaBack", Vector3.new(3.1, 2.7, 0.7), Vector3.new(sx, 2.2, 7.3), C.Panel, Enum.Material.Fabric)
		end
		box("CoffeeTable", Vector3.new(8.5, 0.22, 3.8), Vector3.new(x, 1.3, 0.1), C.Ivory, MATTE, true)
		for _, dx in { -3.2, 3.2 } do box("TableLeg", Vector3.new(0.22, 1.15, 2.8), Vector3.new(x + dx, 0.65, 0.1), C.Ink) end
	end
	box("RefreshmentCounter", Vector3.new(17, 3.4, 3.4), Vector3.new(46, 1.7, 24.5), C.Ink, MATTE, true)
	box("RefreshmentTop", Vector3.new(17.4, 0.18, 3.7), Vector3.new(46, 3.5, 24.5), C.Ivory, MATTE)
	for i = 1, 5 do
		G.disk(lounge, "StudioCup", cf * CFrame.new(40 + i * 1.8, 3.85, 24.3) * CFrame.Angles(math.pi / 2, 0, 0), 0.58, 0.55, C.Ivory, MATTE)
	end
	for _, x in { -36, 28 } do
		local poster = box("ShowPoster", Vector3.new(6.0, 8.2, 0.15), Vector3.new(x, 9.5, 26.2), C.Ink)
		G.label(poster, "THE RUN\n\n12  VAULTS\n04  OFFERS\n01  YOU", C.Amber, 400, 580)
	end
	for _, x in { -76, -5, 77 } do
		box("BalconySupport", Vector3.new(0.65, 12, 0.65), Vector3.new(x, -6, -25), C.Line, nil, true)
	end
	local welcome = box("WelcomeSign", Vector3.new(22, 5.0, 0.15), Vector3.new(-2, 10.5, 26.2), C.Ink)
	G.label(welcome, "V A U L T   B R E A K E R S\n\nTHE GREEN ROOM   /   YOUR NEXT MOVE", C.Ivory, 1100, 250)
	local entries = {}
	for _, info in { { id = "MAIN", x = -65, color = C.Amber, title = "01  /  MAIN STAGE" }, { id = "QUICK", x = 64, color = C.Teal, title = "02  /  QUICK RUN" } } do
		local entryCF = cf * CFrame.new(info.x, 0, -16) * CFrame.Angles(0, math.pi, 0)
		G.block(lounge, "EntryPlinth", Vector3.new(11, 0.15, 7.5), entryCF * CFrame.new(0, 0.1, 0), info.color)
		G.block(lounge, "EntryConsole", Vector3.new(7.6, 3.2, 1.6), entryCF * CFrame.new(0, 1.7, 0), C.Ink, nil, true)
		local screen = G.block(lounge, "EntryDisplay", Vector3.new(7, 2.1, 0.15), entryCF * CFrame.new(0, 2.3, -0.87), C.Panel)
		local label = G.label(screen, info.title .. "\nAVAILABLE", info.color, 580, 180)
		local prompt = G.prompt(screen, "Entry" .. info.id, "ENTER STAGE", info.title, 0.25)
		entries[info.id] = { label = label, prompt = prompt, part = screen, title = info.title }
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.CFrame = "GreenRoomSpawn", Vector3.new(6, 0.1, 6), cf * CFrame.new(-5, 0.15, 17)
	spawn.Anchored, spawn.CanCollide, spawn.Transparency, spawn.Neutral, spawn.Duration = true, false, 1, true, 0
	spawn.Parent = lounge
	G.hidden(cameras, "Lobby", CFrame.lookAt(cf.Position + Vector3.new(0, 7, 23), cf.Position + Vector3.new(0, 5, -20)))
	return { spawn = CFrame.lookAt(cf.Position + Vector3.new(-5, 4, 14), cf.Position + Vector3.new(-5, 4, -20)), entries = entries, spawnLocation = spawn }
end

function StageBuilder.build()
	for _, name in { "VaultWorld", "VaultArena" } do
		local old = Workspace:FindFirstChild(name)
		if old then old:Destroy() end
	end
	Lighting.ClockTime, Lighting.Brightness = 19, 2
	Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(87, 100, 117), Color3.fromRGB(72, 87, 106)
	Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.5, 0.8
	Lighting.GlobalShadows = true
	local bloom = Lighting:FindFirstChild("VaultBloom") or Instance.new("BloomEffect")
	bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold, bloom.Parent = "VaultBloom", 0.08, 12, 1.8, Lighting
	local root = Instance.new("Folder")
	root.Name, root.Parent = "VaultWorld", Workspace
	local cameras = Instance.new("Folder")
	cameras.Name, cameras.Parent = "Cameras", root
	local arenas = {
		MAIN = Arena.new(root, cameras, "MAIN", Vector3.new(0, 0, -51), 34, 106),
		QUICK = Arena.new(root, cameras, "QUICK", Vector3.new(118, 0, -43), 27, 88),
	}
	local lounge = buildLounge(root, cameras)
	-- Relocate any default Studio spawn rather than allowing random spawns outside the set.
	for _, object in Workspace:GetDescendants() do
		if object:IsA("SpawnLocation") and object ~= lounge.spawnLocation then object.Enabled = false end
	end
	local world={ root = root, arenas = arenas, lobby = lounge, cameras = cameras }
	ShowSet.attach(world)
	return world
end
return StageBuilder
