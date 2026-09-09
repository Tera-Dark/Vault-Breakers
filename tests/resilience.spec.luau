--!nonstrict
-- Additional regressions: asynchronous lifecycle / transport and native-adjacent boundaries.
math.randomseed(431)
local count,failures=0,{}
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local function test(name,callback)
	local ok,err=pcall(callback)
	if ok then count+=1;print("PASS",name)else table.insert(failures,name..": "..tostring(err));warn("FAIL "..name..": "..tostring(err))end
end
local function module(path)return require(nodes[path])end
local Prompt=module("src/StarterPlayerScripts/Controllers/PromptController.luau")
local Engine=module("src/ServerScriptService/Core/RunEngine.luau")
local build=Engine.new;Mock.engines={}
Engine.new=function(def,deps)local e=build(def,deps);Mock.engines[def.id]=e;return e end
local Stage=module("src/ServerScriptService/Core/StageBuilder.luau");local stageBuild=Stage.build
Stage.build=function()Mock.world=stageBuild();return Mock.world end
factories["src/ServerScriptService/Main.server.luau"](nodes["src/ServerScriptService/Main.server.luau"])
local p1,p2,p3=Mock.player(501,"Breaker"),Mock.player(502,"Quick"),Mock.player(503,"Viewer")
local remotes=game:GetService("ReplicatedStorage").VaultRemotes
local function action(p,name,payload)remotes.Action.OnServerEvent:Fire(p,name,payload or {})end
local function payload(e,choice)return{arenaId=e.arena.id,runId=e.runId,phaseId=e.phaseId,choice=choice}end
local function tick(e)Mock.advance(math.max(0,e.deadline-Mock.time)+0.001)end
local function clear()
	for id,e in Mock.engines do if e.state~="IDLE"then e:release(Mock.time)end end
	Mock.advance(2.1)
end
local function enter(p,id)
	action(p,"PLAY",{target=id});Mock.advance(.2)
	local e,stage=Mock.engines[id],Mock.world.arenas[id]
	eq(e.breakerId,p.UserId)
	p.Character.HumanoidRootPart.CFrame=stage.vaults[1].anchor.CFrame
	stage.vaults[1].prompt.Triggered:Fire(p)
	return e,stage
end
local function offer(p,id)
	local e,stage=enter(p,id)
	while e.state=="BREACH"do
		for i,v in e.vaults do if not v.opened and not v.claimed then
			p.Character.HumanoidRootPart.CFrame=stage.vaults[i].anchor.CFrame;stage.vaults[i].prompt.Triggered:Fire(p);break
		end end
		tick(e)
	end
	eq(e.state,"OFFER");return e,stage
end
for _,p in {p1,p2,p3}do action(p,"SYNC")end

test("leaving the audience removes a vote immediately, not only on disconnect",function()
	clear();local e=offer(p1,"MAIN")
	action(p3,"WATCH",{target="MAIN"});action(p3,"VOTE",payload(e,"PUSH"));eq(e:snapshot().poll.total,1)
	action(p3,"LOBBY");eq(e:snapshot().poll.total,0)
end)
test("switching studios or becoming a Breaker cannot leave a ghost vote",function()
	clear();local e=offer(p1,"MAIN")
	action(p3,"WATCH",{target="MAIN"});action(p3,"VOTE",payload(e,"EXTRACT"))
	action(p3,"WATCH",{target="QUICK"});eq(e:snapshot().poll.total,0)
	action(p3,"WATCH",{target="MAIN"});action(p3,"VOTE",payload(e,"PUSH"))
	action(p3,"PLAY",{target="QUICK"});eq(Mock.engines.QUICK.breakerId,p3.UserId);eq(e:snapshot().poll.total,0)
end)
test("late remote / physical decisions cannot beat an expired server clock",function()
	clear();local e,stage=offer(p1,"MAIN");local old=payload(e,"EXTRACT")
	Mock.advance(e.deadline-Mock.time+.01,true) -- no Heartbeat yet
	action(p1,"DECIDE",old);eq(e.state,"TRANSITION");assert(e.decisions[1].automatic)
	clear();e,stage=offer(p1,"MAIN")
	p1.Character.HumanoidRootPart.CFrame=stage.buttons[1].part.CFrame
	Mock.advance(e.deadline-Mock.time+.01,true)
	stage.buttons[1].prompt.Triggered:Fire(p1);eq(e.state,"TRANSITION");assert(e.decisions[1].automatic)
end)
test("a dead character releases its stage without waiting for a replacement character",function()
	clear();local e=enter(p1,"MAIN");local humanoid=p1.Character.Humanoid
	humanoid.Health=0;humanoid.Died:Fire();eq(e.state,"IDLE")
	humanoid.Health=100
end)
p1.Character.Humanoid.Health=100
clear()

test("a camera target that replicates late is retried within the same phase",function()
	local Controller=module("src/StarterPlayerScripts/Controllers/CameraController.luau")
	game:GetService("Players")._properties.LocalPlayer=p3
	local controller=Controller.new();local world=workspace.VaultWorld
	workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
	local snapshot={arenaId="MAIN",runId=30,phaseId=7,state="OFFER",breakerId=p1.UserId}
	world.Parent=nil;controller:update("MAIN",snapshot,{reducedMotion=false},p3.UserId)
	world.Parent=workspace;controller:update("MAIN",snapshot,{reducedMotion=false},p3.UserId)
	eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Scriptable);controller:restore()
end)
-- Always restore the set even if the regression above failed.
Mock.world.root.Parent=workspace

test("replacement cameras are controlled and restored independently",function()
	local Controller=module("src/StarterPlayerScripts/Controllers/CameraController.luau")
	local controller=Controller.new();local previous=workspace.CurrentCamera
	previous.CameraType=Enum.CameraType.Custom;previous.FieldOfView=70
	local snapshot={arenaId="MAIN",runId=31,phaseId=7,state="OFFER",breakerId=p1.UserId}
	controller:update("MAIN",snapshot,{reducedMotion=false},p3.UserId)
	local replacement=Instance.new("Camera");replacement.Parent=workspace;replacement.FieldOfView=76;replacement.CameraType=Enum.CameraType.Custom
	workspace.CurrentCamera=replacement;controller:update("MAIN",snapshot,{reducedMotion=false},p3.UserId)
	eq(replacement.CameraType,Enum.CameraType.Scriptable);controller:restore();eq(replacement.FieldOfView,76)
	workspace.CurrentCamera=previous
end)
test("opening a modal disables physical prompts as well as keyboard decisions",function()
	clear();local e,stage=enter(p1,"MAIN")
	local Controller=module("src/StarterPlayerScripts/Controllers/PromptController.luau")
	local controller=Controller.new(p1.UserId)
	controller:update(e:snapshot(),"en",true)
	assert(not stage.vaults[2].prompt.Enabled)
	game:GetService("ProximityPromptService").PromptShown:Fire(stage.vaults[2].prompt)
	assert(not stage.vaults[2].prompt.Enabled)
	controller:update(e:snapshot(),"en",false);assert(stage.vaults[2].prompt.Enabled)
end)
clear()

test("PromptShown cannot re-enable a vault in an offer or expose lounge entry to its Breaker",function()
	clear();offer(p1,"MAIN")
	local controller=Prompt.new(p1.UserId);controller:update(Mock.engines.MAIN:snapshot(),"en",false)
	local shown=game:GetService("ProximityPromptService").PromptShown
	local vault=Mock.world.arenas.MAIN.vaults[1].prompt
	vault.Enabled=true;shown:Fire(vault);assert(not vault.Enabled)
	local entry=Mock.world.lobby.entries.MAIN.prompt
	entry.Enabled=true;shown:Fire(entry);assert(not entry.Enabled)
end)
test("late prompt descendants and attributes recover without another snapshot phase",function()
	clear();action(p1,"PLAY",{target="MAIN"})
	local controller=Prompt.new(p1.UserId);local snapshot=Mock.engines.MAIN:snapshot()
	controller:update(snapshot,"en",false)
	local vault=Instance.new("Model");vault.Name="LateVault";vault.Parent=workspace.VaultWorld.MAIN
	local anchor=Instance.new("Part");anchor.Parent=vault
	local prompt=Instance.new("ProximityPrompt");prompt.Name="VaultPrompt";prompt.Parent=anchor
	assert(not prompt.Enabled)
	vault:SetAttribute("VaultId",2)
	Mock.advance(1.01,true);controller:update(snapshot,"en",false)
	assert(prompt.Enabled);vault:Destroy()
end)
test("leaving during a slow load cannot delete a returning player's profile",function()
	local data=module("src/ServerScriptService/Services/PlayerDataService.luau")
	Mock.storeDelay={User_601=1.0}
	local old=Mock.player(601,"OldConnection")
	old.Parent=nil;game:GetService("Players").PlayerRemoving:Fire(old)
	local returning=Mock.player(601,"NewConnection")
	Mock.advance(6.0)
	local entry=data.get(returning);assert(entry,"Returning player lost its entry")
	eq(entry.status,"READY");assert(data.get(old)==nil,"Old Player still owns the live entry")
	Mock.storeDelay={}
end)
test("returning during a slow leave-save retains the saved reward and cannot share the old lock",function()
	local data=module("src/ServerScriptService/Services/PlayerDataService.luau")
	local old=Mock.player(602,"SavingConnection")
	data.get(old).data.credits=321
	local oldEntry=data.get(old)
	Mock.storeDelay={User_602=1.0}
	old.Parent=nil;game:GetService("Players").PlayerRemoving:Fire(old)
	local returning=Mock.player(602,"ReturningConnection")
	Mock.advance(6)
	local entry=data.get(returning);assert(entry,"Returning player lost its entry");eq(entry.status,"READY");eq(entry.data.credits,321)
	assert(entry~=oldEntry and data.get(old)==nil)
	Mock.storeDelay={}
end)
Mock.storeDelay={}
local App=module("src/StarterPlayerScripts/UI/App.luau")
local appNew=App.new
App.new=function(gui,model,actions)Mock.app=appNew(gui,model,actions);return Mock.app end
Mock.client=p3;game:GetService("Players")._properties.LocalPlayer=p3
factories["src/StarterPlayerScripts/ClientMain.client.luau"](nodes["src/StarterPlayerScripts/ClientMain.client.luau"])
Mock.advance(.1)
test("actual client gates an early assignment until its snapshot arrives; packets copy payloads",function()
	clear();Mock.holdPackets=true;local first=#Mock.packets+1
	action(p3,"PLAY",{target="QUICK"});Mock.advance(.2)
	local directory,snapshot
	for i=first,#Mock.packets do
		local packet=Mock.packets[i]
		if packet.player==p3.UserId and packet.event=="Directory"then directory=packet end
		if packet.player==p3.UserId and packet.event=="Snapshot"and packet.args[1].arenaId=="QUICK"then snapshot=packet end
	end
	assert(directory and snapshot)
	Mock.deliver(directory);assert(Mock.app.waiting.Visible);eq(Mock.app.model.snapshot,nil)
	Mock.deliver(snapshot);assert(not Mock.app.waiting.Visible);eq(Mock.app.model.snapshot.state,"CLAIM")
	snapshot.args[1].vaults[1].claimed=true;assert(not Mock.app.model.snapshot.vaults[1].claimed)
	Mock.holdPackets=false
end)
Mock.holdPackets=false
test("actual modal actions disable prompts immediately and restore them on close",function()
	local prompt=Mock.world.arenas.QUICK.vaults[1].prompt
	assert(prompt.Enabled)
	Mock.app.actions.overlay("HOW");assert(not prompt.Enabled)
	Mock.app.actions.closeOverlay();assert(prompt.Enabled)
	Mock.app.actions.returnLobby();Mock.advance(.2)
end)
test("actual RenderStepped driver retries missing camera targets without a phase change",function()
	clear();offer(p1,"MAIN")
	local world=workspace.VaultWorld;world.Parent=nil
	action(p3,"WATCH",{target="MAIN"})
	eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Custom)
	world.Parent=workspace;Mock.advance(.25,true)
	game:GetService("RunService").RenderStepped:Fire(.016)
	eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Scriptable)
	Mock.app.actions.returnLobby();Mock.advance(.2)
end)
Mock.world.root.Parent=workspace
test("Studio probes refuse live servers and inspect scene structure without mutating data",function()
	local Checks=module("src/ReplicatedStorage/Shared/StudioChecks.luau")
	Mock.studio=false;assert(not pcall(Checks.run,true))
	local before=Mock.json(Mock.stores)
	Mock.studio=true;Mock.server=true
	local report=Checks.run(true);eq(report.context,"server");eq(report.stats.parts,2652);eq(report.stats.seats,12)
	for _,finding in report.findings do assert(finding.level~="ERROR",finding.code)end
	eq(Mock.json(Mock.stores),before)
end)
test("Studio client probes flag native TextBounds overflow and do not count unmeasured mock text as validated",function()
	local Checks=module("src/ReplicatedStorage/Shared/StudioChecks.luau")
	Mock.studio=true;Mock.server=false
	local button=Mock.app.menuButton
	button._properties.TextBounds=Vector2.new(999,24)
	local report=Checks.run(true);eq(report.context,"client");eq(report.stats.textMeasured,1)
	local found=false
	for _,finding in report.findings do if finding.code=="TEXT_OVERFLOW"and finding.path==button:GetFullName()then found=true end end
	assert(found)
	button._properties.TextBounds=nil
	Mock.server=true;Mock.studio=false
end)
test("shutdown rejects physical actions as well as remotes and does not advance an active run",function()
	clear();offer(p1,"MAIN")
	local e=Mock.engines.MAIN;local phase,revision=e.phaseId,e.revision
	Mock.closers[#Mock.closers]() -- Main's shutdown gate, without invoking the DataStore close worker.
	action(p1,"DECIDE",payload(e,"EXTRACT"));eq(e.phaseId,phase)
	local button=Mock.world.arenas.MAIN.buttons[1]
	p1.Character.HumanoidRootPart.CFrame=button.part.CFrame;button.prompt.Triggered:Fire(p1)
	eq(e.phaseId,phase);eq(e.revision,revision)
	Mock.advance(2);eq(e.state,"OFFER")
end)
print(string.format("%d resilience groups passed; %d failed.",count,#failures))
assert(#failures==0,table.concat(failures,"\n"))
