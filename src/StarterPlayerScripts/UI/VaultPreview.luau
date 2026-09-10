--!nonstrict
-- Original, lightweight menu miniatures. No uploaded images, live player avatars,
-- hidden vault values or Workspace clones. Built once, only when the menu is first opened.
local UI=require(script.Parent.Components)
local C=UI.colors
local Preview={}
local gold=Color3.fromRGB(255,195,76)
local teal=Color3.fromRGB(79,211,182)
local steel=Color3.fromRGB(58,80,107)
local edge=Color3.fromRGB(126,157,178)
local dark=Color3.fromRGB(19,29,43)
local skin=Color3.fromRGB(255,210,96)
local function builder(parent,cf,scale)
	local s=scale or 1
	return function(name,size,position,color,rotation,shape)
		local part=Instance.new("Part")
		part.Name=name;part.Size=size*s;part.CFrame=cf*CFrame.new(position*s)*(rotation or CFrame.new())
		part.Color=color;part.Material=Enum.Material.SmoothPlastic
		if name=="Wheel"or name=="WheelSpoke"or name=="Hub"then part:SetAttribute("MenuOriginalTone",color)end
		part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
		if shape then part.Shape=shape end
		part.Parent=parent;return part
	end
end
local function vault(parent,cf,accent,scale)
	local box=builder(parent,cf,scale)
	box("Cabinet",Vector3.new(5.7,7,2.4),Vector3.new(0,3.5,0),steel)
	box("Foot",Vector3.new(6.2,.5,3),Vector3.new(0,.25,-.2),dark)
	for _,x in {-2.65,2.65}do box("ArmourEdge",Vector3.new(.22,6.7,.2),Vector3.new(x,3.6,-1.3),edge)end
	local turn=CFrame.Angles(0,math.pi/2,0)
	box("RoundDoor",Vector3.new(.38,5.15,5.15),Vector3.new(0,3.65,-1.36),edge,turn,Enum.PartType.Cylinder)
	box("DoorInset",Vector3.new(.4,4.6,4.6),Vector3.new(0,3.65,-1.53),steel,turn,Enum.PartType.Cylinder)
	for i=1,12 do
		local a=i*math.pi/6
		box("Rim",Vector3.new(.12,1.15,.13),Vector3.new(math.cos(a)*2.17,3.65+math.sin(a)*2.17,-1.8),dark,CFrame.Angles(0,0,a))
	end
	for i=1,6 do
		local a=i*math.pi/3
		box("Bolt",Vector3.new(.24,.24,.24),Vector3.new(math.cos(a)*2.4,3.65+math.sin(a)*2.4,-1.66),C.Ivory)
	end
	for i=1,8 do
		local a=i*math.pi/4
		box("Wheel",Vector3.new(.16,.64,.16),Vector3.new(math.cos(a)*.76,3.65+math.sin(a)*.76,-2.01),accent,CFrame.Angles(0,0,a))
	end
	for _,a in {0,math.pi/2}do box("WheelSpoke",Vector3.new(1.5,.12,.14),Vector3.new(0,3.65,-2),edge,CFrame.Angles(0,0,a))end
	box("Hub",Vector3.new(.48,.46,.46),Vector3.new(0,3.65,-2.04),C.Ivory,turn,Enum.PartType.Cylinder)
	box("StudioStripe",Vector3.new(3.8,.2,.2),Vector3.new(0,6.65,-1.3),accent)
	for _,y in {2,5.2}do box("Hinge",Vector3.new(.4,.95,.5),Vector3.new(-2.28,y,-1.58),edge)end
end
local function breaker(parent,cf,accent,scale)
	local box=builder(parent,cf,scale)
	box("Jacket",Vector3.new(2,2,1),Vector3.new(0,3.4,0),accent)
	box("Vest",Vector3.new(1.7,1.55,.18),Vector3.new(0,3.5,-.59),dark)
	box("Zip",Vector3.new(.09,1.4,.05),Vector3.new(0,3.48,-.71),gold)
	box("Badge",Vector3.new(.36,.28,.06),Vector3.new(.48,3.92,-.72),C.Ivory)
	for _,side in {-1,1}do
		box("Sleeve",Vector3.new(.95,1.65,1),Vector3.new(side*1.48,3.48,0),accent,CFrame.Angles(0,0,side*.1))
		box("Hand",Vector3.new(.92,.62,.95),Vector3.new(side*1.58,2.39,0),skin)
		box("Leg",Vector3.new(.93,1.95,.95),Vector3.new(side*.51,1.46,0),steel)
		box("Boot",Vector3.new(1.04,.48,1.3),Vector3.new(side*.51,.3,-.14),dark)
	end
	box("Head",Vector3.new(1.34,1.44,1.44),Vector3.new(0,5.08,0),skin,CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder)
	for _,x in {-.31,.31}do box("Eye",Vector3.new(.13,.19,.045),Vector3.new(x,5.18,-.675),dark)end
	box("Smile",Vector3.new(.35,.08,.045),Vector3.new(0,4.83,-.675),dark)
	for _,side in {-1,1}do box("SmileCorner",Vector3.new(.09,.18,.045),Vector3.new(side*.23,4.9,-.675),dark,CFrame.Angles(0,0,-side*.35))end
	box("Helmet",Vector3.new(1.6,.37,1.47),Vector3.new(0,5.79,0),dark)
	box("HelmetBrim",Vector3.new(1.86,.17,1.66),Vector3.new(0,5.61,-.1),dark)
	box("HelmetStripe",Vector3.new(.36,.05,1.43),Vector3.new(0,6,0),accent)
end
local function studioCamera(parent,cf)
	local box=builder(parent,cf)
	box("Camera",Vector3.new(2.4,1.5,2.5),Vector3.new(0,3.7,0),dark)
	box("Monitor",Vector3.new(.15,1.1,1.7),Vector3.new(-1.27,3.9,0),steel)
	box("Tally",Vector3.new(.26,.22,.18),Vector3.new(.7,4.57,-1),gold)
	local turn=CFrame.Angles(0,math.pi/2,0)
	box("Lens",Vector3.new(.8,1.5,1.5),Vector3.new(0,3.7,-1.55),edge,turn,Enum.PartType.Cylinder)
	box("LensGlass",Vector3.new(.1,1.1,1.1),Vector3.new(0,3.7,-2.01),teal,turn,Enum.PartType.Cylinder)
	for i=1,3 do
		local a=i*math.pi*2/3
		local bottom=Vector3.new(math.cos(a)*1.55,.15,math.sin(a)*1.55)
		local top=Vector3.new(0,3,0)
		box("Tripod",Vector3.new(.17,.17,(top-bottom).Magnitude),(bottom+top)/2,edge,CFrame.lookAt(Vector3.zero,top-bottom))
	end
end
function Preview.new(parent,kind)
	local viewport=UI.new("ViewportFrame",parent,{
		Name=kind.."Preview",BackgroundTransparency=1,BorderSizePixel=0,Active=false,
		Ambient=Color3.fromRGB(168,183,201),LightColor=Color3.fromRGB(255,241,217),LightDirection=Vector3.new(-.7,-1,-.6),
	})
	viewport:SetAttribute("MenuArt",kind)
	return viewport
end
function Preview.prepare(viewport)
	if viewport:GetAttribute("Prepared")then return end
	viewport:SetAttribute("Prepared",true)
	local kind=viewport:GetAttribute("MenuArt")
	local model=Instance.new("Model");model.Name="MenuMiniature";model.Parent=viewport
	local box=builder(model,CFrame.new())
	box("Stage",Vector3.new(15,.35,9),Vector3.new(0,-.16,1),dark)
	local camera=Instance.new("Camera");camera.Name="ThumbnailCamera";camera.FieldOfView=30;camera.Parent=viewport;viewport.CurrentCamera=camera
	if kind=="PLAY"then
		vault(model,CFrame.new(2,0,1)*CFrame.Angles(0,-.2,0),gold,.94)
		breaker(model,CFrame.new(-2.35,0,-2.15)*CFrame.Angles(0,-.18,0),Color3.fromRGB(238,145,51))
		camera.CFrame=CFrame.lookAt(Vector3.new(-6.8,6.1,-11.8),Vector3.new(0,3.45,-.65))
	elseif kind=="STAGES"then
		vault(model,CFrame.new(-2.3,0,0)*CFrame.Angles(0,.15,0),gold,.7)
		vault(model,CFrame.new(2.3,0,.9)*CFrame.Angles(0,-.18,0),teal,.7)
		camera.CFrame=CFrame.lookAt(Vector3.new(-5.8,4.8,-9.5),Vector3.new(0,2.5,0))
	else
		studioCamera(model,CFrame.new(-1.8,0,-2)*CFrame.Angles(0,-.45,0))
		breaker(model,CFrame.new(1.7,0,1)*CFrame.Angles(0,-.25,0),teal,.8)
		vault(model,CFrame.new(3.9,0,3.5),gold,.43)
		camera.CFrame=CFrame.lookAt(Vector3.new(-5,4.8,-8.6),Vector3.new(0,2.8,0))
	end
end
function Preview.style(viewport,id,item)
	if not viewport:GetAttribute("Prepared")or viewport:GetAttribute("Style")==id then return end
	viewport:SetAttribute("Style",id)
	for _,object in viewport:GetDescendants()do
		local original=object:GetAttribute("MenuOriginalTone")
		if original then object.Color=if item and item.rgb then Color3.fromRGB(table.unpack(item.rgb))else original end
	end
end
return Preview
