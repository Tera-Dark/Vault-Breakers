--!nonstrict
math.randomseed(1729) -- Stable contract fixtures / offline review boards.
local count=0
local function test(name,callback)
	local ok,err=pcall(callback);assert(ok,name..": "..tostring(err));count+=1;print("PASS",name)
end
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local function module(path)return require(nodes[path])end
local Engine=module("src/ServerScriptService/Core/RunEngine.luau")
local originalEngineNew=Engine.new
Mock.engines={}
Engine.new=function(def,deps)local e=originalEngineNew(def,deps);Mock.engines[def.id]=e;return e end
local Stage=module("src/ServerScriptService/Core/StageBuilder.luau")
local originalBuild=Stage.build
Stage.build=function()Mock.world=originalBuild();return Mock.world end
local mainPath="src/ServerScriptService/Main.server.luau"
local p1,p2,p3
local function action(player,name,payload)
	workspace:GetServerTimeNow()
	game:GetService("ReplicatedStorage").VaultRemotes.Action.OnServerEvent:Fire(player,name,payload or {})
end
local function tick(e)Mock.advance(math.max(0,e.deadline-Mock.time)+0.001)end
local function phasePayload(e,choice)return {arenaId=e.arena.id,runId=e.runId,phaseId=e.phaseId,choice=choice}end
local function claim(player,id)
	Mock.finishShow(Mock.engines[id],true)
	local stage=Mock.world.arenas[id]
	player.Character.HumanoidRootPart.CFrame=stage.vaults[1].anchor.CFrame
	stage.vaults[1].prompt.Triggered:Fire(player)
end
local function openRound(player,id)
	local e,stage=Mock.engines[id],Mock.world.arenas[id]
	Mock.finishShow(e,true)
	while e.state=="BREACH"do
		for i,v in e.vaults do if not v.opened and not v.claimed then
			player.Character.HumanoidRootPart.CFrame=stage.vaults[i].anchor.CFrame
			stage.vaults[i].prompt.Triggered:Fire(player);break
		end end
		eq(e.state,"OPENING");tick(e);Mock.finishShow(e)
	end
	eq(e.state,"OFFER")
end

test("server boots real entrypoint / scene / services without a missing path or invalid API member",function()
	factories[mainPath](nodes[mainPath])
	assert(workspace.VaultWorld.MAIN.CuratorScreen)
	assert(workspace.VaultWorld.QUICK.CuratorScreen)
	eq(#Mock.world.arenas.MAIN.vaults,12);eq(#Mock.world.arenas.QUICK.vaults,12)
	p1,p2,p3=Mock.player(101,"BreakerOne"),Mock.player(102,"BreakerTwo"),Mock.player(103,"Spectator")
	for _,p in {p1,p2,p3}do action(p,"SYNC")end
end)
test("set geometry is finite, collision floors exist, both hollow vaults and true seats built",function()
	local parts,seats,lights=0,0,0
	for _,object in workspace.VaultWorld:GetDescendants()do
		if object:IsA("BasePart")then
			parts+=1;assert(object.Size.X>0 and object.Size.Y>0 and object.Size.Z>0)
			assert(object.Position.X==object.Position.X and math.abs(object.Position.X)<1000)
		end
		if object:IsA("Seat")then seats+=1 end
		if object:IsA("Light")then lights+=1 end
	end
	assert(parts<3000,"Primitive budget exceeded: "..parts);eq(seats,12)
	assert(lights<=32,"Light object budget exceeded: "..lights)
	assert(workspace.VaultWorld.MAIN.StudioFloor.CanCollide)
	print("Scene contract:",parts,"parts,",seats,"seats,",lights,"lights")
	captureScene(Mock.json(Mock.captureWorld()))
end)
test("entry adapter allocates concurrent Main and Quick runs with authoritative identities",function()
	action(p1,"PLAY",{target="MAIN"});action(p2,"PLAY",{target="QUICK"})
	eq(Mock.engines.MAIN.breakerId,101);eq(Mock.engines.QUICK.breakerId,102)
	claim(p1,"MAIN");claim(p2,"QUICK")
	eq(Mock.engines.MAIN.state,"BREACH");eq(Mock.engines.QUICK.state,"BREACH")
end)
test("server rejects remote / physical actions from wrong roles and distant prompts",function()
	local e=Mock.engines.MAIN
	action(p3,"DECIDE",phasePayload(e,"EXTRACT"));eq(e.state,"BREACH")
	p1.Character.HumanoidRootPart.CFrame=CFrame.new(999,999,999)
	Mock.world.arenas.MAIN.vaults[2].prompt.Triggered:Fire(p1);eq(e.state,"BREACH")
	Mock.world.arenas.MAIN.vaults[2].prompt.Triggered:Fire(p2);eq(e.state,"BREACH")
end)
test("physical doors animate as assemblies and reveal only after the opening phase",function()
	local e,stage=Mock.engines.MAIN,Mock.world.arenas.MAIN
	p1.Character.HumanoidRootPart.CFrame=stage.vaults[2].anchor.CFrame
	stage.vaults[2].prompt.Triggered:Fire(p1)
	assert(stage.vaults[2].valueLabel.Text:find("SEALED"));tick(e)
	assert(stage.vaults[2].valueLabel.Text:find("ELIMINATED"))
	assert((stage.vaults[2].door:GetPivot().LookVector-stage.vaults[2].closed.LookVector).Magnitude>0.1)
end)
test("real data service records once, clamps ownership, and resets stage for next run",function()
	local e=Mock.engines.MAIN;openRound(p1,"MAIN")
	local profile=module("src/ServerScriptService/Services/PlayerDataService.luau")
	local before=profile.get(p1).data.credits
	local offered=e.offer
	action(p1,"DECIDE",phasePayload(e,"EXTRACT"));tick(e)
	eq(e.state,"RESULT");eq(profile.get(p1).data.credits,before+offered);eq(profile.get(p1).data.runs,1)
	action(p1,"DECIDE",phasePayload(e,"EXTRACT"));eq(profile.get(p1).data.runs,1)
	action(p1,"LEAVE_RUN",phasePayload(e));eq(e.state,"IDLE")
	for _,vault in Mock.world.arenas.MAIN.vaults do
		assert(not vault.opened and not vault.prompt.Enabled)
		assert((vault.door:GetPivot().LookVector-vault.closed.LookVector).Magnitude<0.000001)
	end
end)
test("late viewer snapshot is scoped to watched arena and withholds all unopened mappings",function()
	action(p1,"PLAY",{target="MAIN"});claim(p1,"MAIN");openRound(p1,"MAIN")
	action(p3,"WATCH",{target="MAIN"})
	local last
	for _,packet in Mock.packets do if packet.player==103 and packet.event=="Snapshot"then last=packet.args[1]end end
	assert(last and last.arenaId=="MAIN");eq(last.state,"OFFER")
	for _,vault in last.vaults do if not vault.opened then eq(vault.value,nil)end end
	action(p3,"VOTE",phasePayload(Mock.engines.MAIN,"PUSH"));eq(Mock.engines.MAIN:snapshot().poll.total,1)
end)
-- Initialise the actual client entrypoint for the spectator; all UI / camera / input subscriptions run.
local App=module("src/StarterPlayerScripts/UI/App.luau")
local originalAppNew=App.new
App.new=function(gui,model,actions)Mock.app=originalAppNew(gui,model,actions);return Mock.app end
local function viewport(w,h)
	Mock.viewport={w,h}
	Mock.app:resize()
	Mock.advance(0.002)
end
local function inside(child,parent)
	local p,s=child.AbsolutePosition,child.AbsoluteSize
	local pp,ps=parent.AbsolutePosition,parent.AbsoluteSize
	assert(p.X>=pp.X-1 and p.Y>=pp.Y-1 and p.X+s.X<=pp.X+ps.X+1 and p.Y+s.Y<=pp.Y+ps.Y+1,
		child.Name.." outside "..parent.Name.." at "..p.X..","..p.Y.." "..s.X.."x"..s.Y)
end
local function capture(name)Mock.captureGUI(Mock.app,name)end

test("actual client entry subscribes before Sync, renders correct spectator controls",function()
	Mock.client=p3;game:GetService("Players")._properties.LocalPlayer=p3
	game:GetService("LocalizationService")._properties.RobloxLocaleId="en-us"
	factories["src/StarterPlayerScripts/ClientMain.client.luau"](nodes["src/StarterPlayerScripts/ClientMain.client.luau"])
	Mock.advance(0.01)
	assert(Mock.app.model.directory and Mock.app.model.snapshot)
	eq(Mock.app.model.snapshot.breakerId,p1.UserId)
	eq(Mock.app.run.cardTitle.Text,"CAST YOUR OPINION")
end)
test("desktop, portrait and landscape UI layouts keep decision controls on-screen",function()
	for _,size in {{1360,800},{1024,768},{844,390},{568,320},{390,844},{360,640}}do
		viewport(size[1],size[2])
		inside(Mock.app.run.left,Mock.app.run.card);inside(Mock.app.run.right,Mock.app.run.card)
		inside(Mock.app.run.card,Mock.app.root);inside(Mock.app.run.leave,Mock.app.root)
		assert(Mock.app.run.left.AbsoluteSize.Y>=44)
		inside(Mock.app.header,Mock.app.root)
	end
	viewport(1360,800);capture("offer-desktop")
	Mock.app.model.touch=true;viewport(390,844);capture("offer-mobile");Mock.app.model.touch=false
	viewport(568,320);capture("offer-landscape")
	Mock.app.model.touch=true;viewport(568,320);capture("offer-touch-landscape")
	inside(Mock.app.run.card,Mock.app.root);inside(Mock.app.run.board,Mock.app.root)
	assert(Mock.app.run.board.AbsolutePosition.Y+Mock.app.run.board.AbsoluteSize.Y<Mock.app.run.card.AbsolutePosition.Y)
	for _,size in {{568,284},{568,260},{844,354},{360,604}}do
		viewport(size[1],size[2]);inside(Mock.app.run.card,Mock.app.root);inside(Mock.app.run.board,Mock.app.root)
		local a,b=Mock.app.run.board,Mock.app.run.card
		assert(a.AbsolutePosition.Y+a.AbsoluteSize.Y<=b.AbsolutePosition.Y or a.AbsolutePosition.X+a.AbsoluteSize.X<=b.AbsolutePosition.X)
	end
	Mock.app.model.touch=false
end)
test("guide / settings / records open and language toggles without replacing core UI",function()
	for _,mode in {"HOW","SETTINGS","BOARD","CONFIRM"}do Mock.app:showOverlay(mode);inside(Mock.app.overlay.panel,Mock.app.root)end
	Mock.app.actions.setting("language","zh");Mock.app:showOverlay("HOW")
	eq(Mock.app.overlay.heading.Text,"一份底牌，四次决定。")
	Mock.app.actions.setting("language","en");Mock.app:showOverlay(nil)
end)
test("returning to the lounge keeps the menu closed; summoned game cards fit a scrollable menu",function()
	Mock.app.actions.returnLobby();Mock.advance(0.2)
	assert(not Mock.app.lobbyScroll.Visible);assert(not Mock.app.run.root.Visible)
	Mock.app.actions.toggleMenu();assert(Mock.app.lobbyScroll.Visible)
	for _,size in {{1360,800},{844,390},{390,844},{360,640}}do
		viewport(size[1],size[2])
		inside(Mock.app.lobby.play,Mock.app.lobby.root)
		inside(Mock.app.lobby.stageTile.root,Mock.app.lobby.root)
		inside(Mock.app.lobby.watchTile.root,Mock.app.lobby.root)
	end
	viewport(1360,800);capture("lobby-desktop")
	viewport(390,844);capture("lobby-mobile")
end)
test("owning client reaches KEEP / SWAP, then follows the chosen reveal camera",function()
	local e=Mock.engines.MAIN
	action(p1,"LEAVE_RUN",phasePayload(e));action(p3,"PLAY",{target="MAIN"});claim(p3,"MAIN")
	for _=1,4 do
		openRound(p3,"MAIN")
		assert(Mock.app.run.card.Visible and Mock.app.run.left.Active)
		Mock.app.actions.choice(2);tick(e)
	end
	eq(e.state,"FINAL_CHOICE");eq(Mock.app.run.left.Text,"KEEP");eq(Mock.app.run.right.Text,"SWAP")
	local chosen=e.finalId
	viewport(390,844);capture("final-mobile")
	Mock.app.actions.choice(2);eq(e.state,"REVEAL");eq(e:snapshot().revealId,chosen)
	for _,v in e:snapshot().vaults do if not v.opened then eq(v.value,nil)end end
	Mock.advance(0.75)
	local camera=workspace.CurrentCamera;eq(camera.CameraType,Enum.CameraType.Scriptable)
	local anchor=Mock.world.arenas.MAIN.vaults[chosen].anchor
	local expected=anchor.Position+anchor.CFrame.LookVector*11+Vector3.new(0,2.1,0)
	assert((camera.CFrame.Position-expected).Magnitude<0.00001)
	Mock.app.actions.setting("reducedMotion",true);eq(camera.CameraType,Enum.CameraType.Custom)
	Mock.app.actions.setting("reducedMotion",false)
	tick(e);eq(e.state,"RESULT");eq(e.result.baseCredits,e.vaults[chosen].value)
	eq(e.result.otherValue,e.vaults[e.claimId].value)
	eq(camera.CameraType,Enum.CameraType.Custom)
end)
test("result scrolling and fixed replay controls work at all viewports; old packets cannot revive a finished run",function()
	local e=Mock.engines.MAIN
	assert(Mock.app.result.root.Visible);assert(Mock.app.result.rows[4].frame.Visible)
	for _,size in {{1360,800},{1024,768},{844,390},{568,320},{390,844},{360,640}}do
		viewport(size[1],size[2])
		inside(Mock.app.result.primary,Mock.app.result.panel);inside(Mock.app.result.secondary,Mock.app.result.panel)
		inside(Mock.app.result.panel,Mock.app.root);assert(Mock.app.result.primary.AbsoluteSize.Y>=44)
	end
	viewport(1360,800);capture("result-desktop");viewport(390,844);capture("result-mobile")
	viewport(568,320);capture("result-landscape")
	local old=e:snapshot();local previous=e.runId
	Mock.app.actions.replay();eq(e.state,"SHOWTIME");eq(e.runId,previous+1)
	game:GetService("ReplicatedStorage").VaultRemotes.Snapshot:FireClient(p3,old)
	eq(Mock.app.model.snapshot.state,"SHOWTIME");assert(not Mock.app.result.root.Visible)
	Mock.app.actions.leave();eq(Mock.app.overlayMode,"CONFIRM");Mock.app.actions.abort();eq(e.state,"IDLE")
	Mock.advance(0.2);Mock.app.actions.showRecap();assert(Mock.app.result.root.Visible)
	Mock.app.actions.returnLobby();assert(not Mock.app.model.showRecap)
end)
test("timed release frees the stage without dismissing the owner's readable recap",function()
	local e=Mock.engines.MAIN
	Mock.advance(0.2);Mock.app.actions.play("MAIN");Mock.advance(0.2);claim(p3,"MAIN");openRound(p3,"MAIN")
	Mock.app.actions.choice(1);tick(e);eq(e.state,"RESULT");assert(Mock.app.result.root.Visible)
	tick(e);eq(e.state,"IDLE");eq(Mock.app.model.directory.myArena,nil)
	assert(Mock.app.result.root.Visible);eq(Mock.app.model.recap.state,"RESULT")
	Mock.app:tick(Mock.time);assert(Mock.app.result.timer.Text:find("Stage released"))
	Mock.app.actions.returnLobby();assert(not Mock.app.result.root.Visible)
end)
test("failed saves warn the client, retain data, and recover on the next successful write",function()
	local data=module("src/ServerScriptService/Services/PlayerDataService.luau")
	Mock.advance(0.2) -- Directory follows the adapter's 10 Hz replication tick.
	local entry=data.get(p3);local credits=entry.data.credits
	Mock.failKeys={User_103=true}
	assert(not data.save(103,false));eq(entry.status,"SAVE_DELAYED");assert(Mock.app.banner.Visible)
	eq(entry.data.credits,credits);assert(Mock.app.bannerText.Text:find("delayed"))
	Mock.failKeys={};assert(data.save(103,false));eq(entry.status,"READY");assert(not Mock.app.banner.Visible)
	eq(Mock.stores.VaultBreakers_UserData_v1.User_103.profile.credits,credits)
end)
test("failed load, live foreign lock, and lock loss never overwrite an existing profile",function()
	local data=module("src/ServerScriptService/Services/PlayerDataService.luau")
	local store=Mock.stores.VaultBreakers_UserData_v1
	local legacy={credits=777,reputation=11,unknownCosmetic="retain-me"}
	store.User_104=legacy;Mock.failKeys={User_104=true}
	local failed=Mock.player(104,"UnavailableData");Mock.advance(1.1)
	eq(data.get(failed).status,"SESSION_ONLY");assert(not data.save(104,true));eq(store.User_104,legacy)
	Mock.failKeys={}
	local locked={profile={credits=900},session={id="other-server",time=os.time()}}
	store.User_105=locked
	local blocked=Mock.player(105,"LockedData");Mock.advance(1.1)
	eq(data.get(blocked).status,"SESSION_ONLY");assert(not data.save(105,true));eq(store.User_105,locked)
	local own=data.get(p3);local foreign={profile={credits=1001},session={id="new-owner",time=os.time()}}
	store.User_103=foreign;assert(not data.save(103,true));eq(own.status,"SESSION_ONLY");eq(store.User_103,foreign)
end)
print(string.format("%d reflection-backed integration / layout contract groups passed. Studio rendering and physics still need playtesting.",count))
