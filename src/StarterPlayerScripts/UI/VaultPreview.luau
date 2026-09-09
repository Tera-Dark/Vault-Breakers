--!nonstrict
-- Actual game geometry in a small viewport, not a mock screenshot or an external image asset.
local UI = require(script.Parent.Components)
local C = UI.colors
local Preview = {}
function Preview.new(parent)
	local viewport = UI.new("ViewportFrame", parent, { Name="VaultPreview", BackgroundTransparency=1, Ambient=Color3.fromRGB(145,155,166), LightColor=C.Ivory, LightDirection=Vector3.new(-1,-1,-1), BorderSizePixel=0 })
	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	camera.Parent, viewport.CurrentCamera = viewport, camera
	task.spawn(function()
		local world = workspace:WaitForChild("VaultWorld",20)
		local main = world and world:WaitForChild("MAIN",10)
		local original = main and main:WaitForChild("Vault_01",10)
		if not original or not viewport.Parent then return end
		local clone = original:Clone()
		local anchor = clone:FindFirstChild("Interaction")
		if anchor then clone:PivotTo(anchor.CFrame:Inverse() * clone:GetPivot()) end
		for _, child in clone:GetDescendants() do
			if child:IsA("ProximityPrompt") or child:IsA("ParticleEmitter") or child:IsA("SurfaceGui") then child:Destroy() end
		end
		clone.Parent = viewport
		local cf = clone:GetBoundingBox()
		camera.CFrame = CFrame.lookAt(cf.Position+Vector3.new(10,6,-20),cf.Position)
	end)
	return viewport
end
return Preview
