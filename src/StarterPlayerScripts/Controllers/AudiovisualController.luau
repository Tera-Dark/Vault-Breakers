--!strict
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local AudiovisualController = {}

local colorCorrection: ColorCorrectionEffect
local heartbeatSound: Sound
local alarmSound: Sound
local whooshSound: Sound

function AudiovisualController.init(parentGui: ScreenGui)
	-- Setup Lighting Atmosphere & Color Correction
	colorCorrection = Lighting:FindFirstChild("VaultColorCorrection") :: ColorCorrectionEffect
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "VaultColorCorrection"
		colorCorrection.Brightness = 0.01
		colorCorrection.Contrast = 0.25
		colorCorrection.Saturation = 0.12
		colorCorrection.TintColor = Color3.fromRGB(255, 246, 230) -- Warm cinematic amber
		colorCorrection.Parent = Lighting
	end

	-- Procedural Audio Generator using Roblox Asset IDs or Sound instances
	heartbeatSound = Instance.new("Sound")
	heartbeatSound.Name = "HeartbeatFX"
	heartbeatSound.SoundId = "rbxassetid://9114223175" -- Classic Deep Thump / Heartbeat
	heartbeatSound.Volume = 0.8
	heartbeatSound.Looped = true
	heartbeatSound.Parent = SoundService

	alarmSound = Instance.new("Sound")
	alarmSound.Name = "AlarmFX"
	alarmSound.SoundId = "rbxassetid://9114227073" -- Sci-Fi Warning Pulse
	alarmSound.Volume = 0.6
	alarmSound.Looped = true
	alarmSound.Parent = SoundService

	whooshSound = Instance.new("Sound")
	whooshSound.Name = "WhooshFX"
	whooshSound.SoundId = "rbxassetid://9114221995" -- Transition Impact
	whooshSound.Volume = 1.0
	whooshSound.Parent = SoundService

	-- Critical Pressure Vignette Overlay on Client GUI
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "CriticalVignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxassetid://6578174261" -- Soft Radial Vignette
	vignette.ImageColor3 = Color3.fromRGB(255, 30, 30)
	vignette.ImageTransparency = 1
	vignette.ZIndex = 10
	vignette.Parent = parentGui

	AudiovisualController.vignette = vignette
end

function AudiovisualController.enterCriticalPressure()
	if not AudiovisualController.vignette then return end

	-- Red Lighting pulse
	local redTween = TweenService:Create(colorCorrection, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		TintColor = Color3.fromRGB(255, 170, 170),
		Brightness = -0.08,
	})
	redTween:Play()
	AudiovisualController.activeLightingTween = redTween

	-- Pulsing Red Vignette
	local vigTween = TweenService:Create(AudiovisualController.vignette, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		ImageTransparency = 0.45,
	})
	vigTween:Play()
	AudiovisualController.activeVigTween = vigTween

	pcall(function()
		heartbeatSound:Play()
		alarmSound:Play()
	end)
end

function AudiovisualController.exitCriticalPressure()
	if AudiovisualController.activeLightingTween then
		AudiovisualController.activeLightingTween:Cancel()
		AudiovisualController.activeLightingTween = nil
	end
	if AudiovisualController.activeVigTween then
		AudiovisualController.activeVigTween:Cancel()
		AudiovisualController.activeVigTween = nil
	end

	colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
	colorCorrection.Brightness = 0.02
	if AudiovisualController.vignette then
		AudiovisualController.vignette.ImageTransparency = 1
	end

	pcall(function()
		heartbeatSound:Stop()
		alarmSound:Stop()
	end)
end

function AudiovisualController.playFinalReveal()
	-- PRD 37: Lights down, dramatic pause
	local darkTween = TweenService:Create(colorCorrection, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = -0.3,
		Saturation = -0.4,
	})
	darkTween:Play()

	pcall(function()
		whooshSound:Play()
	end)

	task.delay(2.5, function()
		-- Flash reveal
		local flashTween = TweenService:Create(colorCorrection, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0.2,
			Saturation = 0.2,
		})
		flashTween:Play()
		task.wait(0.5)
		colorCorrection.Brightness = 0.02
		colorCorrection.Saturation = 0.05
	end)
end

return AudiovisualController
