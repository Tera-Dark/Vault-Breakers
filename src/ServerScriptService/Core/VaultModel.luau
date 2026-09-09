--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C = require(ReplicatedStorage.VaultBreakers.Config.VisualConfig)
local G = require(script.Parent.Geometry)
local Vault = {}

function Vault.build(parent, id, cf, detailed)
	local model = Instance.new("Model")
	model.Name = string.format("Vault_%02d", id)
	model:SetAttribute("VaultId", id)
	model.Parent = parent
	local function box(name, size, position, color, material, collide)
		return G.block(model, name, size, cf * CFrame.new(position), color, material, collide)
	end
	-- The shell is really hollow; opening the door exposes the chamber, not another solid block.
	box("Plinth", Vector3.new(8.4, 0.45, 5.9), Vector3.new(0, 0.22, 0.2), C.Ink, nil, true)
	box("PlinthBevel", Vector3.new(8.0, 0.26, 5.55), Vector3.new(0, 0.55, 0.2), C.Steel)
	box("ChamberFloor", Vector3.new(7.2, 0.35, 4.8), Vector3.new(0, 0.91, 0.3), C.Raised, nil, true)
	box("LeftJamb", Vector3.new(0.65, 7.2, 4.8), Vector3.new(-3.58, 4.55, 0.3), C.Steel, nil, true)
	box("RightJamb", Vector3.new(0.65, 7.2, 4.8), Vector3.new(3.58, 4.55, 0.3), C.Steel, nil, true)
	box("Lintel", Vector3.new(7.8, 0.65, 4.8), Vector3.new(0, 8.28, 0.3), C.Silver, nil, true)
	box("BackLining", Vector3.new(6.6, 7.0, 0.28), Vector3.new(0, 4.6, 2.57), C.Ink, nil, true)
	box("Threshold", Vector3.new(6.8, 0.12, 1.6), Vector3.new(0, 1.13, -1.3), C.Silver)
	for _, x in { -3.62, 3.62 } do
		box("FrontTrim", Vector3.new(0.16, 6.9, 0.16), Vector3.new(x, 4.65, -2.18), C.Silver)
	end
	G.ring(model, "Oculus", cf * CFrame.new(0, 4.68, -2.06), 3.30, 0.22, 0.18, C.Ink, if detailed then 20 else 16)
	local tag = box("NumberPlate", Vector3.new(5.5, 0.72, 0.16), Vector3.new(0, 8.3, -2.2), C.Ink)
	local numberLabel = G.label(tag, string.format("VAULT  /  %02d", id), C.Ivory, 480, 70)
	local status = box("StatusStrip", Vector3.new(2.0, 0.055, 0.07), Vector3.new(0, 7.82, -2.15), C.Teal, Enum.Material.Neon)
	status.CastShadow = false
	local backDisplay = box("RewardDisplay", Vector3.new(5.6, 2.1, 0.12), Vector3.new(0, 4.7, 2.34), C.Panel)
	local valueLabel = G.label(backDisplay, "SEALED\nUNKNOWN VALUE", C.Muted, 640, 220)
	box("ChamberGlow", Vector3.new(4.6, 0.08, 0.1), Vector3.new(0, 6.6, 2.1), C.Teal, Enum.Material.Neon)
	box("DisplayShelf", Vector3.new(5.4, 0.16, 2.4), Vector3.new(0, 2.8, 1.0), C.Steel)

	local door = Instance.new("Model")
	door.Name, door.Parent = "DoorAssembly", model
	local hinge = G.hidden(door, "HingePivot", cf * CFrame.new(-3.12, 4.68, -2.32))
	door.PrimaryPart = hinge
	local face = cf * CFrame.new(0, 4.68, -2.32)
	G.disk(door, "ArmouredCore", face, 6.28, 0.52, C.Steel)
	G.disk(door, "InsetFace", face * CFrame.new(0, 0, -0.29), 5.83, 0.13, C.Raised)
	G.ring(door, "BrushedRim", face * CFrame.new(0, 0, -0.34), 2.98, 0.10, 0.14, C.Silver, if detailed then 20 else 16)
	-- Six radial lock rods, two real hinge housings, and captive fasteners.
	local rods = {}
	for i = 1, 6 do
		local a = i * math.pi / 3
		local rod = G.block(door, "LockRod", Vector3.new(1.15, 0.24, 0.24), face * CFrame.new(math.cos(a) * 1.95, math.sin(a) * 1.95, -0.51) * CFrame.Angles(0, 0, a), C.Silver)
		table.insert(rods, { part = rod, closed = rod.CFrame })
		G.block(door, "BoltSleeve", Vector3.new(0.42, 0.48, 0.37), face * CFrame.new(math.cos(a) * 2.48, math.sin(a) * 2.48, -0.50) * CFrame.Angles(0, 0, a), C.Steel)
	end
	for _, y in { -1.9, 1.9 } do
		G.block(door, "HingeArm", Vector3.new(1.4, 0.44, 0.55), face * CFrame.new(-2.60, y, -0.55), C.Silver)
		box("HingeBarrel", Vector3.new(0.5, 1.18, 0.66), Vector3.new(-3.22, 4.68 + y, -2.28), C.Steel)
	end
	local wheel = Instance.new("Model")
	wheel.Name, wheel.Parent = "HandWheel", door
	local wheelFace = face * CFrame.new(0, 0, -0.91)
	local hub = G.disk(wheel, "Hub", wheelFace, 0.5, 0.35, C.Amber)
	wheel.PrimaryPart = hub
	G.ring(wheel, "HandRim", wheelFace, 0.98, 0.14, 0.14, C.Silver, 10)
	for i = 1, 3 do
		G.block(wheel, "Spoke", Vector3.new(1.84, 0.12, 0.14), wheelFace * CFrame.Angles(0, 0, i * math.pi / 3), C.Silver)
	end
	for i = 1, (if detailed then 8 else 4) do
		local a = i * math.pi * 2 / (if detailed then 8 else 4)
		G.disk(door, "Fastener", face * CFrame.new(math.cos(a) * 2.77, math.sin(a) * 2.77, -0.4), 0.10, 0.06, C.Ink)
	end
	local serial = G.block(door, "SerialBadge", Vector3.new(0.96, 0.64, 0.07), face * CFrame.new(1.36, 1.38, -0.44), C.Ivory)
	G.label(serial, string.format("%02d", id), C.Ink, 100, 64)
	local interaction = G.hidden(model, "Interaction", cf * CFrame.new(0, 4.0, -3.25))
	interaction.CanQuery = false
	local prompt = G.prompt(interaction, "VaultPrompt", "CLAIM", string.format("VAULT %02d", id), 0.28)
	prompt.Enabled = false
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "PressureRelease"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.25, 0.6)
	emitter.Speed = NumberRange.new(2, 4)
	emitter.Size = NumberSequence.new(0.3, 1.0)
	emitter.Transparency = NumberSequence.new(0.7, 1)
	emitter.Color = ColorSequence.new(C.Silver)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Parent = interaction
	return {
		model = model, door = door, wheel = wheel, prompt = prompt, anchor = interaction,
		closed = door:GetPivot(), wheelClosed = wheel:GetPivot(), tag = numberLabel,
		valueLabel = valueLabel, status = status, emitter = emitter, rods = rods, opened = false,
	}
end
return Vault
