--!nonstrict
-- Run the real server and client. These are menu interaction contracts, not a native playtest.
math.randomseed(20260910)
local passed,failures=0,{}
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local function test(name,callback)
	local ok,err=pcall(callback)
	if ok then passed+=1;print("PASS",name)else table.insert(failures,name..": "..tostring(err));warn("FAIL "..name..": "..tostring(err))end
end
local function module(path)return require(nodes[path])end
local Engine=module("src/ServerScriptService/Core/RunEngine.luau")
local engineNew=Engine.new;Mock.engines={}
Engine.new=function(def,deps)local e=engineNew(def,deps);Mock.engines[def.id]=e;return e end
local Stage=module("src/ServerScriptService/Core/StageBuilder.luau")
local build=Stage.build
Stage.build=function()Mock.world=build();return Mock.world end
factories["src/ServerScriptService/Main.server.luau"](nodes["src/ServerScriptService/Main.server.luau"])
local player=Mock.player(701,"You")
Mock.client=player;game:GetService("Players")._properties.LocalPlayer=player
local App=module("src/StarterPlayerScripts/UI/App.luau");local appNew=App.new
App.new=function(gui,model,actions)Mock.app=appNew(gui,model,actions);return Mock.app end
factories["src/StarterPlayerScripts/ClientMain.client.luau"](nodes["src/StarterPlayerScripts/ClientMain.client.luau"])
Mock.advance(.1)
local app=Mock.app
local input=game:GetService("UserInputService")
local function key(code,processed)input.InputBegan:Fire({KeyCode=code},processed or false)end

test("joining exposes the playable world, not an unavoidable lobby page",function()
	assert(not app.lobbyScroll.Visible,"The full lobby menu must start CLOSED.")
	assert(not app.overlay.root.Visible and not app.result.root.Visible)
	eq(app.root.BackgroundTransparency,1)
end)
test("M can summon and dismiss the menu without leaving or joining a stage",function()
	local before=#Mock.packets
	key(Enum.KeyCode.M);assert(app.lobbyScroll.Visible,"M must open the menu.")
	key(Enum.KeyCode.M);assert(not app.lobbyScroll.Visible,"M must close the menu.")
	eq(#Mock.packets,before)
end)

local function inside(child,parent)
	local p,s=child.AbsolutePosition,child.AbsoluteSize;local a,b=parent.AbsolutePosition,parent.AbsoluteSize
	assert(p.X>=a.X-1 and p.Y>=a.Y-1 and p.X+s.X<=a.X+b.X+1 and p.Y+s.Y<=a.Y+b.Y+1,child.Name.." outside "..parent.Name)
end
local function visible(node)
	while node and node~=app.gui do if node:IsA("GuiObject")and not node.Visible then return false end;node=node.Parent end
	return node==app.gui
end
local function viewport(w,h)Mock.viewport={w,h};app:resize();Mock.advance(.01)end
local function close()app.actions.closeMenu()end
local function activate(button)assert(button.Active);button.Activated:Fire()end
local function action(p,command,payload)game:GetService("ReplicatedStorage").VaultRemotes.Action.OnServerEvent:Fire(p,command,payload or{})end
local function tick(e)Mock.advance(math.max(0,e.deadline-Mock.time)+.001)end
local function startOffer()
	app.actions.play("MAIN");Mock.advance(.2)
	local e,stage=Mock.engines.MAIN,Mock.world.arenas.MAIN
	eq(e.breakerId,player.UserId)
	player.Character.HumanoidRootPart.CFrame=stage.vaults[1].anchor.CFrame;stage.vaults[1].prompt.Triggered:Fire(player)
	while e.state=="BREACH"do
		for i,vault in e.vaults do if not vault.claimed and not vault.opened then
			player.Character.HumanoidRootPart.CFrame=stage.vaults[i].anchor.CFrame;stage.vaults[i].prompt.Triggered:Fire(player);break
		end end
		tick(e)
	end
	eq(e.state,"OFFER");return e
end

test("a visible menu button closes every subpage directly; Back is a separate action",function()
	for _,mode in {"HOW","SETTINGS","STAGES","BOARD"}do
		close();activate(app.menuButton);app.actions.overlay(mode)
		assert(app.overlay.root.Visible and not app.lobbyScroll.Visible)
		activate(app.overlay.close)
		assert(not app:isMenuVisible());assert(not app.overlay.root.Visible and not app.lobbyScroll.Visible)
		app.actions.overlay(mode);activate(app.overlay.back);assert(app.lobbyScroll.Visible and not app.overlay.root.Visible)
		activate(app.menuButton);assert(not app:isMenuVisible())
	end
end)
test("the menu does not move or freeze the avatar, change cameras, or send gameplay commands",function()
	close();local character=player.Character;local camera=workspace.CurrentCamera
	local position=character.HumanoidRootPart.Position
	local speed=character.Humanoid.WalkSpeed;local fov=camera.FieldOfView;local cameraPosition=camera.CFrame.Position;local cameraType=camera.CameraType
	local before=#Mock.packets
	for _=1,6 do key(Enum.KeyCode.M);key(Enum.KeyCode.M)end
	eq(character.Humanoid.WalkSpeed,speed);eq((character.HumanoidRootPart.Position-position).Magnitude,0)
	eq(camera.FieldOfView,fov);eq((camera.CFrame.Position-cameraPosition).Magnitude,0);eq(camera.CameraType,cameraType)
	eq(#Mock.packets,before);assert(not app.menuButton.Modal)
end)
test("chat and processed keys do not toggle menus; gamepad Up opens and B clears focus",function()
	close();Mock.focusedTextBox={};key(Enum.KeyCode.M);assert(not app:isMenuVisible());Mock.focusedTextBox=nil
	key(Enum.KeyCode.M,true);assert(not app:isMenuVisible())
	input.LastInputTypeChanged:Fire(Enum.UserInputType.Gamepad1)
	key(Enum.KeyCode.DPadUp);assert(app.lobbyScroll.Visible)
	eq(game:GetService("GuiService").SelectedObject,app.lobby.play)
	app.actions.overlay("SETTINGS");app.actions.setting("sound",false)
	eq(game:GetService("GuiService").SelectedObject,app.overlay.preferenceButtons.sound)
	key(Enum.KeyCode.ButtonB,true);assert(not app:isMenuVisible());eq(game:GetService("GuiService").SelectedObject,nil)
	input.LastInputTypeChanged:Fire(Enum.UserInputType.Keyboard)
end)
test("touch and short-screen menus always keep Resume reachable; thumbnails are cached outside Workspace",function()
	close();local worldCount=#workspace:GetDescendants();app.actions.toggleMenu()
	local partCount=0
	for _,item in {app.lobby.stageTile,app.lobby.playTile,app.lobby.watchTile}do
		assert(item.preview.CurrentCamera)
		for _,object in item.preview:GetDescendants()do if object:IsA("BasePart")then partCount+=1;assert(object.Anchored and not object.CanCollide)end end
	end
	assert(partCount>60 and partCount<300);eq(#workspace:GetDescendants(),worldCount)
	local before=#app.gui:GetDescendants()
	for _,size in {{1568,882},{1360,800},{1024,768},{844,414},{844,390},{568,320},{568,260},{390,844},{360,604}}do
		app.model.touch=size[1]<600;viewport(size[1],size[2])
		inside(app.menuButton,app.root);assert(visible(app.menuButton));assert(app.menuButton.AbsoluteSize.X>=44 and app.menuButton.AbsoluteSize.Y>=44)
		for _,tile in {app.lobby.stageTile,app.lobby.playTile,app.lobby.watchTile}do inside(tile.root,app.lobby.root);inside(tile.button,tile.root);assert(tile.button.AbsoluteSize.Y>=44)end
		inside(app.lobbyScroll,app.root)
		if size[1]>=540 then for _,button in {app.lobby.how,app.lobby.board,app.lobby.settings}do inside(button,app.lobbyScroll)end end
		app.lobbyScroll.CanvasPosition=Vector2.new(0,200);inside(app.menuButton,app.root)
		close();assert(not app.lobbyScroll.Visible);app.actions.toggleMenu();eq(app.lobbyScroll.CanvasPosition.Y,0)
	end
	eq(#app.gui:GetDescendants(),before)
	app.model.touch=false;viewport(1360,800);close()
end)
test("opening a menu blocks physical and shortcut decisions but never pauses the live clock",function()
	local e=startOffer();local phase,deadline=e.phaseId,e.deadline
	local stage=Mock.world.arenas.MAIN
	assert(stage.buttons[1].prompt.Enabled)
	key(Enum.KeyCode.M);assert(not stage.buttons[1].prompt.Enabled)
	assert(not Mock.world.lobby.entries.MAIN.prompt.Enabled)
	assert(app.live.Visible);key(Enum.KeyCode.One);eq(e.phaseId,phase);eq(e.deadline,deadline)
	activate(app.lobby.play);assert(not app:isMenuVisible());assert(stage.buttons[1].prompt.Enabled)
	eq(e.phaseId,phase);key(Enum.KeyCode.M);tick(e)
	eq(e.state,"TRANSITION");assert(e.decisions[1].automatic);assert(app.lobbyScroll.Visible)
	close();app.actions.returnLobby();Mock.advance(.2);assert(not app.lobbyScroll.Visible)
end)
test("joining a stage closes the menu before packets arrive; repeated Sync never reopens it",function()
	close();app.actions.toggleMenu();Mock.holdPackets=true;local first=#Mock.packets+1
	activate(app.lobby.play);assert(not app:isMenuVisible())
	Mock.advance(.2)
	for i=first,#Mock.packets do Mock.deliver(Mock.packets[i])end
	Mock.holdPackets=false;assert(app.model.directory.myArena);assert(not app:isMenuVisible())
	for _=1,3 do action(player,"SYNC");assert(not app:isMenuVisible())end
	app.actions.returnLobby();Mock.advance(.2);assert(not app:isMenuVisible())
end)
Mock.holdPackets=false
test("a queue stays visible after dismissal, and a result recap has the same escape route",function()
	close()
	local other=Mock.player(702,"OnAir")
	local third=Mock.player(703,"QuickBreaker")
	action(other,"PLAY",{target="MAIN"});action(third,"PLAY",{target="QUICK"});Mock.advance(.2)
	app.actions.toggleMenu();activate(app.lobby.play);Mock.advance(.2)
	assert(not app:isMenuVisible());assert(app.queue.Visible);assert(app.model.directory.queuePosition>0)
	activate(app.queueCancel);Mock.advance(.2);assert(not app.queue.Visible)
	Mock.engines.MAIN:release(Mock.time);Mock.advance(.2)
	local e=startOffer();app.actions.choice(1);tick(e)
	assert(app.result.root.Visible);assert(app.menuButton.Modal)
	key(Enum.KeyCode.M);assert(not app:isMenuVisible());assert(not app.result.root.Visible)
	app.actions.toggleMenu();eq(app.lobby.playTile.title.Text,string.upper(app:t("replay")));close()
	app.actions.returnLobby();Mock.advance(.2)
	action(other,"PLAY",{target="MAIN"});Mock.advance(.2)
	-- Leave a live main stage for the menu review captures.
end)
close();app.actions.setting("language","en");viewport(1568,882)
captureScene(Mock.json(Mock.captureWorld()))
Mock.captureGUI(app,"world-hud-desktop",{background="lounge"})
app.actions.toggleMenu();Mock.captureGUI(app,"menu-desktop",{background="lounge"})
app.model.touch=true;viewport(390,844);Mock.captureGUI(app,"menu-mobile",{background="lounge"})
viewport(568,320);Mock.captureGUI(app,"menu-landscape",{background="lounge"})
app.actions.setting("language","zh");viewport(1568,882);Mock.captureGUI(app,"menu-desktop-zh",{background="lounge"})
viewport(390,844);Mock.captureGUI(app,"menu-mobile-zh",{background="lounge"})
close();Mock.captureGUI(app,"world-hud-mobile",{background="lounge"})
print(string.format("%d menu interaction groups passed; %d failed.",passed,#failures))
assert(#failures==0,table.concat(failures,"\n"))
