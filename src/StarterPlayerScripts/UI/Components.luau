--!nonstrict
local TweenService = game:GetService("TweenService")
local C = require(game:GetService("ReplicatedStorage").VaultBreakers.Config.VisualConfig)
local UI = { colors = C, click = function() end, reducedMotion = false }
function UI.new(class, parent, properties)
	local object = Instance.new(class)
	for key, value in properties or {} do object[key] = value end
	object.Parent = parent
	return object
end
function UI.corner(parent, radius) return UI.new("UICorner", parent, { CornerRadius = UDim.new(0, radius or 8) }) end
function UI.stroke(parent, color, transparency)
	return UI.new("UIStroke", parent, { Color = color or C.Line, Thickness = 1, Transparency = transparency or 0.25, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
function UI.frame(parent, name, color)
	return UI.new("Frame", parent, { Name = name, BackgroundColor3 = color or C.Panel, BorderSizePixel = 0 })
end
function UI.text(parent, name, text, size, color, bold)
	return UI.new("TextLabel", parent, {
		Name = name, Text = text or "", TextSize = size or 16, TextColor3 = color or C.Text,
		Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham,
		BackgroundTransparency = 1, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true, RichText = false,
	})
end
function UI.place(object, x, y, w, h)
	object.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
	object.Size = UDim2.fromOffset(math.max(1, math.floor(w)), math.max(1, math.floor(h)))
end
function UI.card(parent, name, color)
	local card = UI.frame(parent, name, color)
	card.BackgroundTransparency = 0.04
	UI.corner(card, 10); UI.stroke(card)
	return card
end
function UI.button(parent, name, text, style, callback)
	local background = if style == "primary" then C.Amber elseif style == "teal" then C.Teal else C.Raised
	local button = UI.new("TextButton", parent, {
		Name = name, Text = text, TextSize = 16, Font = Enum.Font.GothamBold,
		TextColor3 = if style == "primary" or style == "teal" then C.Ink else C.Text,
		BackgroundColor3 = background, BorderSizePixel = 0, AutoButtonColor = false,
		Selectable = true, Active = true, TextWrapped = true,
	})
	UI.corner(button, 7)
	local outline = UI.stroke(button, if style == "primary" then C.Amber elseif style == "teal" then C.Teal else C.Line, 0.1)
	local function focus(active)
		if button:GetAttribute("Disabled") then return end
		local color = if active then background:Lerp(C.Ivory, 0.14) else background
		if UI.reducedMotion then button.BackgroundColor3 = color
		else TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = color }):Play() end
		outline.Color = if active then C.Ivory else (button:GetAttribute("Accent") or (if style == "primary" then C.Amber elseif style == "teal" then C.Teal else C.Line))
	end
	button.MouseEnter:Connect(function() focus(true) end)
	button.MouseLeave:Connect(function() focus(false) end)
	button.SelectionGained:Connect(function() focus(true) end)
	button.SelectionLost:Connect(function() focus(false) end)
	button.Activated:Connect(function()
		if not button:GetAttribute("Disabled") then UI.click(); callback() end
	end)
	return button
end
-- Chunky menu controls, separate from the restrained in-run decision HUD.
function UI.gameButton(parent,name,text,style,callback)
	local button=UI.button(parent,name,text,style,callback)
	button.Font=Enum.Font.FredokaOne
	button.TextSize=19
	local outline=button:FindFirstChildOfClass("UIStroke")
	outline.Thickness=2;outline.Transparency=0
	return button
end
function UI.gameText(parent,name,text,size,color)
	local label=UI.text(parent,name,text,size,color,true)
	label.Font=Enum.Font.FredokaOne
	label.TextStrokeColor3=C.Ink;label.TextStrokeTransparency=0
	return label
end
function UI.enabled(button, enabled)
	button:SetAttribute("Disabled", not enabled)
	button.Active, button.Selectable = enabled, enabled
	button.BackgroundTransparency = if enabled then 0 else 0.5
	button.TextTransparency = if enabled then 0 else 0.45
end
function UI.mark(parent, name, color)
	local mark = UI.frame(parent, name, C.Ink)
	mark.BackgroundTransparency = 1
	for _, p in { {0,0}, {1,0}, {0,1}, {1,1} } do
		local x, y = p[1], p[2]
		local a = UI.frame(mark,"Corner",color or C.Amber)
		a.Size, a.Position = UDim2.fromScale(0.34,0.075), UDim2.fromScale(x*0.66,y*0.925)
		local b = UI.frame(mark,"Corner",color or C.Amber)
		b.Size, b.Position = UDim2.fromScale(0.075,0.34), UDim2.fromScale(x*0.925,y*0.66)
	end
	local diamond = UI.frame(mark,"Core",color or C.Amber)
	diamond.AnchorPoint, diamond.Position, diamond.Size, diamond.Rotation = Vector2.new(0.5,0.5),UDim2.fromScale(0.5,0.5),UDim2.fromScale(0.32,0.32),45
	return mark
end
function UI.rule(parent)
	local rule = UI.frame(parent,"Rule",C.Line)
	rule.BackgroundTransparency = 0.35
	return rule
end
return UI
