-- Offline evidence from actual GUI instances. No Roblox renderer, font metrics or physics.
function Mock.captureGUI(app,name,options)
	game:GetService("RunService").RenderStepped:Fire(.016)
	local entries={}
	local function rgb(c)return {c.R,c.G,c.B}end
	local function visit(parent,clip)
		local children={}
		for index,node in parent:GetChildren()do if node:IsA("GuiObject")and node.Visible then table.insert(children,{node=node,index=index})end end
		table.sort(children,function(a,b)return if a.node.ZIndex==b.node.ZIndex then a.index<b.index else a.node.ZIndex<b.node.ZIndex end)
		for _,item in children do
			local node=item.node
			local p,s=node.AbsolutePosition,node.AbsoluteSize
			local text=if node:IsA("TextLabel")or node:IsA("TextButton")then node.Text else ""
			local el={name=node.Name,class=node.ClassName,z=#entries+1,clip=clip,rotation=node.Rotation,x=p.X,y=p.Y,w=s.X,h=s.Y,bg=rgb(node.BackgroundColor3),alpha=1-node.BackgroundTransparency,text=text}
			if text~=""then
				el.textSize=node.TextSize;el.color=rgb(node.TextColor3);el.align=node.TextXAlignment.Name;el.font=node.Font.Name
				el.textAlpha=1-node.TextTransparency;el.textStroke=1-node.TextStrokeTransparency;el.strokeColor=rgb(node.TextStrokeColor3);el.textScaled=node.TextScaled
			end
			local corner=node:FindFirstChildOfClass("UICorner")
			if corner then el.radius=corner.CornerRadius.Offset+math.min(s.X,s.Y)*corner.CornerRadius.Scale end
			local stroke=node:FindFirstChildOfClass("UIStroke")
			local border=if stroke then {color=rgb(stroke.Color),alpha=1-stroke.Transparency,width=stroke.Thickness}else nil
			local gradient=node:FindFirstChildOfClass("UIGradient")
			if gradient then
				el.gradient={rotation=gradient.Rotation,colors={},transparency={}}
				-- The doubles keep constructor values, not native userdata.
				if gradient.Color then
					local values=gradient.Color.values
					if values then
						for i,value in values do
							if value.__type=="Color3"then table.insert(el.gradient.colors,{time=(i-1)/math.max(1,#values-1),color=rgb(value)})end
						end
					end
				end
			end
			if node:IsA("ViewportFrame")and node.CurrentCamera then
				local camera=node.CurrentCamera;local eye,look=camera.CFrame.Position,camera.CFrame.LookVector
				el.viewport={parts=Mock.captureWorld(node),eye={eye.X,eye.Y,eye.Z},target={eye.X+look.X,eye.Y+look.Y,eye.Z+look.Z},fov=camera.FieldOfView,tint=rgb(node.ImageColor3)}
			end
			table.insert(entries,el)
			local childClip=clip
			if node.ClipsDescendants or node:IsA("ScrollingFrame")then childClip={math.max(clip[1],p.X),math.max(clip[2],p.Y),math.min(clip[3],p.X+s.X),math.min(clip[4],p.Y+s.Y)}end
			visit(node,childClip)
			if border then table.insert(entries,{name=node.Name.."Outline",class="Border",z=#entries+1,clip=clip,x=p.X,y=p.Y,w=s.X,h=s.Y,bg={0,0,0},alpha=0,text="",radius=el.radius,border=border})end
		end
	end
	visit(app.root,{0,0,Mock.viewport[1],Mock.viewport[2]})
	captureLayout(name,Mock.json({width=Mock.viewport[1],height=Mock.viewport[2],elements=entries,background=if options then options.background else nil}))
end
