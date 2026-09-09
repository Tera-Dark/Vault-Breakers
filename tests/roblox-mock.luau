--!nonstrict
-- Reflection-checked Roblox contract double. NO rendering, physics, asset access or DataStore guarantees.
local Mock={time=0,tasks={},stores={},packets={},viewport={1360,800},server=true}
local function tagged(name,values,meta) values.__type=name;return setmetatable(values,meta) end
local function typeof(value) return if type(value)=="table" and value.__type then value.__type else type(value) end
local vectorMeta={}
local Vector3={}
function Vector3.new(x,y,z)return tagged("Vector3",{X=x or 0,Y=y or 0,Z=z or 0},vectorMeta)end
vectorMeta.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vectorMeta.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vectorMeta.__unm=function(a)return Vector3.new(-a.X,-a.Y,-a.Z)end
vectorMeta.__mul=function(a,b)if type(a)=="number" then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
vectorMeta.__div=function(a,b)return a*(1/b)end
vectorMeta.__index=function(v,key)
	if key=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
	if key=="Unit" then return v/math.max(v.Magnitude,1e-12) end
	if key=="Dot" then return function(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
	if key=="Cross" then return function(a,b)return Vector3.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X)end end
	if key=="Lerp" then return function(a,b,t)return a+(b-a)*t end end
end
Vector3.zero,Vector3.one=Vector3.new(),Vector3.new(1,1,1)
local Vector2={}
function Vector2.new(x,y)return tagged("Vector2",{X=x or 0,Y=y or 0},{})end
Vector2.zero=Vector2.new()
local UDim={new=function(scale,offset)return tagged("UDim",{Scale=scale or 0,Offset=offset or 0},{})end}
local UDim2={}
function UDim2.new(a,b,c,d)return tagged("UDim2",{X=UDim.new(a,b),Y=UDim.new(c,d)},{})end
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local colorMeta={}
local Color3={}
function Color3.new(r,g,b)return tagged("Color3",{R=r or 0,G=g or 0,B=b or 0},colorMeta)end
function Color3.fromRGB(r,g,b)return Color3.new(r/255,g/255,b/255)end
colorMeta.__index={Lerp=function(a,b,t)return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t)end}
local cfMeta={}
local CFrame={}
local function cf(p,r)return tagged("CFrame",{p=p,r=r or {1,0,0,0,1,0,0,0,1}},cfMeta)end
function CFrame.new(x,y,z)return cf(if typeof(x)=="Vector3" then x else Vector3.new(x,y,z))end
local function rotate(r,v)return Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z)end
cfMeta.__mul=function(a,b)
	if typeof(b)=="Vector3" then return a.p+rotate(a.r,b) end
	local r={};for row=0,2 do for col=0,2 do r[row*3+col+1]=0;for k=0,2 do r[row*3+col+1]+=a.r[row*3+k+1]*b.r[k*3+col+1] end end end
	return cf(a*b.p,r)
end
cfMeta.__index=function(value,key)
	if key=="Position" then return value.p elseif key=="LookVector" then return Vector3.new(-value.r[3],-value.r[6],-value.r[9]) end
	if key=="Inverse" then return function(a)local r={a.r[1],a.r[4],a.r[7],a.r[2],a.r[5],a.r[8],a.r[3],a.r[6],a.r[9]};return cf(rotate(r,-a.p),r)end end
end
function CFrame.Angles(x,y,z)
	local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
	return cf(Vector3.zero,{1,0,0,0,cx,-sx,0,sx,cx})*cf(Vector3.zero,{cy,0,sy,0,1,0,-sy,0,cy})*cf(Vector3.zero,{cz,-sz,0,sz,cz,0,0,0,1})
end
function CFrame.lookAt(p,target,up)
	local f=(target-p).Unit;local right=f:Cross(up or Vector3.new(0,1,0)).Unit;local u=right:Cross(f)
	return cf(p,{right.X,u.X,-f.X,right.Y,u.Y,-f.Y,right.Z,u.Z,-f.Z})
end
CFrame.identity=CFrame.new()
local function simple(name)return {new=function(...)return tagged(name,{values={...}},{})end}end
local NumberRange,NumberSequence,ColorSequence,NumberSequenceKeypoint,TweenInfo=simple("NumberRange"),simple("NumberSequence"),simple("ColorSequence"),simple("NumberSequenceKeypoint"),simple("TweenInfo")
local Enum={}
for name,items in API.enums do
	local group={};for item,value in items do group[item]=tagged("EnumItem",{Name=item,Value=value,EnumType=name},{__tostring=function(a)return "Enum."..a.EnumType.."."..a.Name end})end
	Enum[name]=setmetatable(group,{__index=function(_,key)error("Invalid Enum."..name.."."..key)end})
end
setmetatable(Enum,{__index=function(_,key)error("Unmodelled Enum."..key)end})
local function signal()
	local s={listeners={}}
	function s:Connect(callback)
		local c={callback=callback,Connected=true};function c:Disconnect()self.Connected=false end
		table.insert(self.listeners,c);return c
	end
	function s:Fire(...)
		for _,connection in table.clone(self.listeners) do if connection.Connected then connection.callback(...) end end
	end
	return s
end
local task={}
local function schedule(thread,at,args)table.insert(Mock.tasks,{thread=thread,at=at,args=args or {}});return thread end
local function resume(thread,args)
	local ok,seconds=coroutine.resume(thread,table.unpack(args or {}));assert(ok,seconds)
	if coroutine.status(thread)~="dead" then schedule(thread,Mock.time+(seconds or 1/60)) end
end
function task.spawn(callback,...)local thread=coroutine.create(callback);resume(thread,{...});return thread end
function task.defer(callback,...)return schedule(coroutine.create(callback),Mock.time+0.00001,{...})end
function task.delay(seconds,callback,...)return schedule(coroutine.create(callback),Mock.time+seconds,{...})end
function task.wait(seconds)return coroutine.yield(seconds or 1/60)end
function task.cancel(thread)for i=#Mock.tasks,1,-1 do if Mock.tasks[i].thread==thread then table.remove(Mock.tasks,i)end end end
local os={clock=function()return Mock.time end,time=function()return 1788944000+math.floor(Mock.time)end}
local methods={}
local instMeta={}
local Instance={}
local function member(class,kind,key)
	while API.classes[class] do
		local info=API.classes[class]
		if info[kind][key] then return info[kind][key] end
		class=info.super
	end
end
local function inherits(class,target)
	while API.classes[class] do if class==target then return true end;class=API.classes[class].super end;return false
end
local function default(object,key,kind)
	if key=="TextStrokeTransparency" then return 1 end
	if key=="Name" then return object._class end
	if key=="Visible" or key=="Enabled" then return true end
	if key=="Health" then return 100 end
	if key=="TextXAlignment" then return Enum.TextXAlignment.Center end
	if key=="TextYAlignment" then return Enum.TextYAlignment.Center end
	if key=="Size" and object:IsA("BasePart") then return Vector3.one end
	if kind=="string" or kind=="Content" or kind=="ContentId" then return "" end
	if kind=="bool" then return false end
	if kind=="float" or kind=="int" or kind=="double" or kind=="int64" then return 0 end
	if kind=="CFrame" then return CFrame.new() end
	if kind=="Vector3" then return Vector3.zero end
	if kind=="Vector2" then return Vector2.zero end
	if kind=="UDim2" then return UDim2.new() end
	if kind=="UDim" then return UDim.new() end
	if kind=="Color3" then return Color3.new() end
	if key=="Shape" then return Enum.PartType.Block end
	if kind=="AutomaticSize" then return Enum.AutomaticSize.None end
	return nil
end
function Instance.new(class)
	assert(API.classes[class],"Invalid Instance class "..class)
	return setmetatable({__type="Instance",_class=class,_properties={},_children={},_signals={},_attributes={}},instMeta)
end
instMeta.__index=function(object,key)
	if key=="ClassName" then return object._class end
	if methods[key] then return methods[key] end
	if key=="Position" and object:IsA("BasePart") then return object.CFrame.Position end
	if key=="AbsoluteSize" then
		if object:IsA("ScreenGui") then return Vector2.new(table.unpack(Mock.viewport)) end
		local p=object.Parent;local base=if p then p.AbsoluteSize else Vector2.new(table.unpack(Mock.viewport))
		local size=object.Size;return Vector2.new(base.X*size.X.Scale+size.X.Offset,base.Y*size.Y.Scale+size.Y.Offset)
	end
	if key=="AbsolutePosition" then
		local parent=object.Parent;local base=if parent and parent:IsA("GuiObject") then parent.AbsolutePosition else Vector2.zero
		local parentSize=if parent then parent.AbsoluteSize else Vector2.new(table.unpack(Mock.viewport))
		local pos,size,anchor=object.Position,object.AbsoluteSize,object.AnchorPoint
		local scroll=if parent and parent:IsA("ScrollingFrame") then parent.CanvasPosition else Vector2.zero
		return Vector2.new(base.X+parentSize.X*pos.X.Scale+pos.X.Offset-size.X*anchor.X-scroll.X,base.Y+parentSize.Y*pos.Y.Scale+pos.Y.Offset-size.Y*anchor.Y-scroll.Y)
	end
	local kind=member(object._class,"properties",key)
	if kind then
		local value=object._properties[key]
		if value~=nil then return value end
		return default(object,key,kind)
	end
	if member(object._class,"events",key) then
		if not object._signals[key] then object._signals[key]=signal() end
		return object._signals[key]
	end
	for _,child in object._children do if child.Name==key then return child end end
	error(object._class.." has no member "..tostring(key))
end
instMeta.__newindex=function(object,key,value)
	if string.sub(key,1,1)=="_" then rawset(object,key,value);return end
	assert(member(object._class,"properties",key),object._class.." has no writable property "..key)
	if key=="Parent" then
		local previous=object._properties.Parent
		if previous==value then return end
		local descendants=object:GetDescendants();table.insert(descendants,1,object)
		local function notify(ancestor,event)
			while ancestor do
				if ancestor._signals[event] then for _,desc in descendants do ancestor._signals[event]:Fire(desc)end end
				ancestor=ancestor.Parent
			end
		end
		notify(previous,"DescendantRemoving")
		if previous then local index=table.find(previous._children,object);if index then table.remove(previous._children,index)end;if previous._signals.ChildRemoved then previous.ChildRemoved:Fire(object)end end
		object._properties.Parent=value
		if value then table.insert(value._children,object);if value._signals.ChildAdded then value.ChildAdded:Fire(object)end end
		notify(value,"DescendantAdded")
	elseif key=="Position" and object:IsA("BasePart") then
		object._properties.CFrame=cf(value,object.CFrame.r)
	else object._properties[key]=value end
	if object._signals["Property:"..key] then object._signals["Property:"..key]:Fire() end
end
function methods:IsA(class)return inherits(self._class,class)end
function methods:GetChildren()return table.clone(self._children)end
function methods:GetDescendants()
	local result={};for _,child in self._children do table.insert(result,child);for _,desc in child:GetDescendants()do table.insert(result,desc)end end;return result
end
function methods:FindFirstChild(name,recursive)
	for _,child in (if recursive then self:GetDescendants()else self._children)do if child.Name==name then return child end end
end
function methods:WaitForChild(name,timeout)
	local child=self:FindFirstChild(name)
	if not child then error("WaitForChild missing "..self:GetFullName().."/"..name.." (would wait in Studio)")end
	return child
end
function methods:FindFirstChildOfClass(class)for _,child in self._children do if child.ClassName==class then return child end end end
function methods:GetFullName()return if self.Parent then self.Parent:GetFullName().."."..self.Name else self.Name end
function methods:GetAttribute(name)return self._attributes[name]end
function methods:SetAttribute(name,value)self._attributes[name]=value end
function methods:GetPropertyChangedSignal(key)
	assert(member(self._class,"properties",key),"Unknown property signal "..self._class.."."..key)
	local name="Property:"..key;if not self._signals[name] then self._signals[name]=signal()end;return self._signals[name]
end
function methods:Destroy()
	for _,child in table.clone(self._children)do child:Destroy()end
	self.Parent=nil;self._destroyed=true
end
function methods:Clone()
	local lookup={}
	local function collect(object)
		local copy=Instance.new(object.ClassName);lookup[object]=copy;copy._attributes=table.clone(object._attributes)
		for _,child in object:GetChildren()do local c=collect(child);c.Parent=copy end
		return copy
	end
	local result=collect(self)
	for original,copy in lookup do
		for key,value in original._properties do if key~="Parent" then copy[key]=lookup[value] or value end end
	end
	return result
end
function methods:GetBoundingBox()
	local min,max=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
	local count=0
	for _,part in self:GetDescendants()do if part:IsA("BasePart")then
		count+=1
		for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
			local p=part.CFrame*Vector3.new(part.Size.X*x/2,part.Size.Y*y/2,part.Size.Z*z/2)
			min=Vector3.new(math.min(min.X,p.X),math.min(min.Y,p.Y),math.min(min.Z,p.Z));max=Vector3.new(math.max(max.X,p.X),math.max(max.Y,p.Y),math.max(max.Z,p.Z))
		end end end
	end end
	if count==0 then return CFrame.new(),Vector3.zero end
	return CFrame.new((min+max)/2),max-min
end
function methods:GetPivot()
	if self:IsA("BasePart")then return self.CFrame end
	if self.PrimaryPart then return self.PrimaryPart.CFrame end
	return self._properties.WorldPivot or (self:GetBoundingBox())
end
function methods:PivotTo(target)
	if self:IsA("BasePart")then self.CFrame=target;return end
	local delta=target*self:GetPivot():Inverse()
	for _,part in self:GetDescendants()do if part:IsA("BasePart")then part.CFrame=delta*part.CFrame end end
	self.WorldPivot=target
end
function methods:Emit()end
function methods:Clear()end
function methods:Play()self._properties.IsPlaying=true end
function methods:Stop()self._properties.IsPlaying=false end
function methods:GetServerTimeNow()return Mock.time end
function methods:BindToClose(callback)table.insert(Mock.closers,callback)end
function methods:IsServer()return Mock.server end
function methods:GetPlayers()local list={};for _,p in self:GetChildren()do if p:IsA("Player")then table.insert(list,p)end end;return list end
function methods:GetPlayerByUserId(id)for _,p in self:GetPlayers()do if p.UserId==id then return p end end end
-- Remote payloads are copied, not shared with server tables. Optional manual delivery
-- permits cross-event ordering / latency tests; it is NOT native Roblox replication.
function Mock.copy(value)
	if type(value)~="table" or value.__type then return value end
	local result={};for k,v in value do result[k]=Mock.copy(v)end;return result
end
function Mock.deliver(packet)
	if Mock.client==packet.target and packet.remote._signals.OnClientEvent then
		packet.remote.OnClientEvent:Fire(table.unpack(Mock.copy(packet.args)))
	end
end
function methods:FireClient(player,...)
	local packet={event=self.Name,player=player.UserId,args=Mock.copy({...}),target=player,remote=self}
	table.insert(Mock.packets,packet)
	if not Mock.holdPackets then Mock.deliver(packet)end
end
function methods:FireServer(...)self.OnServerEvent:Fire(Mock.client,table.unpack(Mock.copy({...})))end
function methods:GenerateGUID()Mock.guid=(Mock.guid or 0)+1;return "mock-session-guid-"..Mock.guid end
function methods:GetFocusedTextBox()return Mock.focusedTextBox end
function methods:GetLastInputType()return Mock.lastInput or Enum.UserInputType.Keyboard end
function methods:IsStudio()return Mock.studio==true end
function methods:Create(object,info,properties)
	local tween={cancelled=false,Completed=signal()}
	function tween:Play()
		task.delay(info.values[1] or 0,function()if not self.cancelled then for k,v in properties do object[k]=v end;self.Completed:Fire()end end)
	end
	function tween:Cancel()self.cancelled=true end
	return tween
end
function methods:GetDataStore(name)
	if Mock.storeFailure then error("DataStore disabled for contract test")end
	if not Mock.stores[name]then Mock.stores[name]={}end
	local values=Mock.stores[name]
	return {UpdateAsync=function(_,key,transform)
		if Mock.storeFailure or (Mock.failKeys and Mock.failKeys[key]) then error("DataStore disabled for contract test")end
		if Mock.storeDelay and Mock.storeDelay[key] then task.wait(Mock.storeDelay[key])end
		local value=transform(Mock.copy(values[key]));if value~=nil then values[key]=Mock.copy(value) end;return Mock.copy(value)
	end}
end
Mock.closers={}
local game=Instance.new("DataModel")
game.Name="Game";game._properties.JobId="contract-test-server"
local services={}
function methods:GetService(name)
	if not services[name]then services[name]=Instance.new(name);services[name].Name=name;services[name].Parent=game end
	return services[name]
end
local workspace=game:GetService("Workspace")
workspace.CurrentCamera=Instance.new("Camera");workspace.CurrentCamera.Parent=workspace
workspace.CurrentCamera.FieldOfView=70
local function require()error("source loader not installed")end
function Mock.advance(seconds,noHeartbeat)
	local target=Mock.time+seconds
	local iterations=0
	while true do
		local selected,at=nil,math.huge
		for i,item in Mock.tasks do if item.at<at then selected,at=i,item.at end end
		if not selected or at>target then break end
		local item=table.remove(Mock.tasks,selected);Mock.time=item.at;resume(item.thread,item.args)
		iterations+=1;assert(iterations<5000,"task runaway")
	end
	Mock.time=target
	if not noHeartbeat then game:GetService("RunService").Heartbeat:Fire(seconds)end
end
function Mock.player(id,name)
	local p=Instance.new("Player");p.Name=name;p._properties.UserId=id;p._properties.DisplayName=name
	local character=Instance.new("Model");character.Name=name.."Character";character.Parent=workspace
	local humanoid=Instance.new("Humanoid");humanoid.Name="Humanoid";humanoid.Parent=character
	local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Transparency=1;root.Parent=character;character.PrimaryPart=root
	p._properties.Character=character
	local gui=Instance.new("PlayerGui");gui.Name="PlayerGui";gui.Parent=p
	p.Parent=game:GetService("Players")
	game:GetService("Players").PlayerAdded:Fire(p)
	return p
end
function Mock.source(path,class,name,parent)
	local object=Instance.new(class);object.Name=name;object._modulePath=path;object.Parent=parent;return object
end
function Mock.captureWorld(root)
	local result={}
	for _,p in (root or workspace):GetDescendants()do
		if p:IsA("BasePart")and p.Transparency<0.95 then
			local r=p.CFrame.r;local v=p.Position
			table.insert(result,{name=p:GetFullName(),size={p.Size.X,p.Size.Y,p.Size.Z},matrix={r[1],r[2],r[3],v.X,r[4],r[5],r[6],v.Y,r[7],r[8],r[9],v.Z},color={p.Color.R,p.Color.G,p.Color.B},shape=if p:IsA("Part")then p.Shape.Name else "Block",material=if p.Material then p.Material.Name else "Plastic",alpha=1-p.Transparency})
		end
	end
	return result
end
-- Serialize in the VM, rather than pinning thousands of tables in the JS/Luau interop cache.
function Mock.json(value)
	local kind=type(value)
	if kind=="number" then return tostring(value) end
	if kind=="boolean" then return if value then "true" else "false" end
	if kind=="string" then
		local escaped=value:gsub('[%z\1-\31\\"]',function(c)
			if c=='"'then return '\\"'elseif c=='\\'then return '\\\\'else return string.format('\\u%04x',string.byte(c))end
		end)
		return '"'..escaped..'"'
	end
	if kind=="table" then
		local parts={}
		if #value>0 then for _,v in value do table.insert(parts,Mock.json(v))end;return '['..table.concat(parts,',')..']'end
		for k,v in value do table.insert(parts,Mock.json(tostring(k))..':'..Mock.json(v))end
		return '{'..table.concat(parts,',')..'}'
	end
	return 'null'
end
