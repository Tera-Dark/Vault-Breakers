--!nonstrict
-- Small, dependency-free set-building primitives. All dimensions are in studs.
local G = {}
function G.block(parent, name, size, cf, color, material, collide)
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame = name, size, cf
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.Anchored = true
	part.CanCollide = collide == true
	part.CanTouch = false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end
function G.disk(parent, name, cf, diameter, depth, color, material)
	local part = G.block(parent, name, Vector3.new(depth, diameter, diameter), cf * CFrame.Angles(0, math.pi / 2, 0), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end
function G.ring(parent, name, cf, radius, width, depth, color, segments)
	segments = segments or 16
	for i = 1, segments do
		local a = i * math.pi * 2 / segments
		G.block(parent, name, Vector3.new(width, 2 * radius * math.sin(math.pi / segments) * 1.04, depth),
			cf * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a), color)
	end
end
function G.beam(parent, name, a, b, width, color, material)
	return G.block(parent, name, Vector3.new(width, width, (a - b).Magnitude), CFrame.lookAt((a + b) / 2, b), color, material)
end
function G.label(part, text, color, width, height)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Graphics"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(width or 600, height or 120)
	gui.LightInfluence = 0.15
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Copy"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.92, 0.86)
	label.Position = UDim2.fromScale(0.04, 0.07)
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamMedium
	label.TextWrapped = true
	label.Parent = gui
	return label
end
function G.prompt(part, name, action, object, hold)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name, prompt.ActionText, prompt.ObjectText = name, action, object
	prompt.HoldDuration = hold or 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonR2
	prompt.Parent = part
	return prompt
end
function G.hidden(parent, name, cf)
	local part = G.block(parent, name, Vector3.one, cf, Color3.new(0, 0, 0))
	part.Transparency, part.CanQuery, part.CastShadow = 1, false, false
	return part
end
return G
