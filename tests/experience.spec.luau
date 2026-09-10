--!nonstrict
-- Actual production entrypoints with controllable audio/avatar/store doubles; NOT native acceptance.
math.randomseed(6231)
local passed,failures=0,{}
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local function test(name,fn)local ok,err=pcall(fn);if ok then passed+=1;print("PASS",name)else table.insert(failures,name..": "..tostring(err));warn("FAIL "..name..": "..tostring(err))end end
local function module(path)return require(nodes[path])end
local Engine=module("src/ServerScriptService/Core/RunEngine.luau");local enew=Engine.new;Mock.engines={}
Engine.new=function(def,deps)local e=enew(def,deps);Mock.engines[def.id]=e;return e end
local Stage=module("src/ServerScriptService/Core/StageBuilder.luau");local build=Stage.build
Stage.build=function()Mock.world=build();return Mock.world end
for _,item in {{"Controllers/AudiovisualController","effects"},{"Controllers/StagePresentationController","director"},{"Controllers/HallController","hall"},{"Controllers/AudienceController","audience"},{"UI/LiveBroadcast","television"},{"UI/App","app"}}do
	local m=module("src/StarterPlayerScripts/"..item[1]..".luau");local new=m.new;m.new=function(...)local result=new(...);Mock[item[2]]=result;return result end
end
factories["src/ServerScriptService/Main.server.luau"](nodes["src/ServerScriptService/Main.server.luau"])
local p1,p2,p3=Mock.player(801,"LocalBreaker"),Mock.player(802,"MainGuest"),Mock.player(803,"QuickGuest")
Mock.client=p1;game:GetService("Players")._properties.LocalPlayer=p1
factories["src/StarterPlayerScripts/ClientMain.client.luau"](nodes["src/StarterPlayerScripts/ClientMain.client.luau"])
local app=Mock.app;local Data=module("src/ServerScriptService/Services/PlayerDataService.luau")
local Remotes=game:GetService("ReplicatedStorage").VaultRemotes
local function action(p,command,payload)Remotes.Action.OnServerEvent:Fire(p,command,payload or{})end
local function payload(e,choice)return{arenaId=e.arena.id,runId=e.runId,phaseId=e.phaseId,choice=choice}end
local function frame(seconds,noHeartbeat)Mock.advance(seconds or .1,noHeartbeat);game:GetService("RunService").RenderStepped:Fire(.016)end
local function tick(e)frame(math.max(0,e.deadline-Mock.time)+.001)end
local function inside(child,parent)
	local p,s,a,b=child.AbsolutePosition,child.AbsoluteSize,parent.AbsolutePosition,parent.AbsoluteSize
	assert(p.X>=a.X-1 and p.Y>=a.Y-1 and p.X+s.X<=a.X+b.X+1 and p.Y+s.Y<=a.Y+b.Y+1,child.Name.." outside "..parent.Name)
end
local function clear()
	for _,e in Mock.engines do if e.state~="IDLE"then e:release(Mock.time)end end
	app.actions.closeMenu();Mock.audioFailure=false;Mock.avatarFailure=false;Mock.avatarDelay=nil;Mock.storeDelay=nil;Mock.orderedFailure=false
	frame(2.2)
end
local function claim(p,id)
	local e=Mock.engines[id];Mock.finishShow(e,true)
	local v=Mock.world.arenas[id].vaults[1];p.Character.HumanoidRootPart.CFrame=v.anchor.CFrame;v.prompt.Triggered:Fire(p);frame(.1)
end
local function breach(p,id,predicate)
	local e=Mock.engines[id];Mock.finishShow(e,true)
	for index,v in e.vaults do if not v.opened and not v.claimed and(not predicate or predicate(v.value))then
		local door=Mock.world.arenas[id].vaults[index];p.Character.HumanoidRootPart.CFrame=door.anchor.CFrame;door.prompt.Triggered:Fire(p);eq(e.state,"OPENING");tick(e);return index
	end end
	error("no eligible fixture vault")
end
local function offer(p,id)
	local e=Mock.engines[id];Mock.finishShow(e,true)
	while e.state=="BREACH"do breach(p,id);Mock.finishShow(e)end
	eq(e.state,"OFFER");frame(.05)
end
for _,p in {p1,p2,p3}do action(p,"SYNC")end
frame(.1)

test("showtime uses the entrance, portrait and skip path without consuming Claim time",function()
	app.actions.play("MAIN");frame(.2);local e=Mock.engines.MAIN;eq(e.state,"SHOWTIME")
	assert(app.run.portrait.Visible and app.run.skip.Visible);eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Scriptable)
	eq((p1.Character.HumanoidRootPart.Position-Mock.world.arenas.MAIN.entranceSpawn.Position).Magnitude,0)
	assert(not e:skipShowtime(p2.UserId,Mock.time))
	for _,size in {{1360,800},{390,844},{360,640},{568,320},{568,260},{320,260}}do
		Mock.viewport=size;app:resize();inside(app.run.skip,app.root);inside(app.run.portrait,app.root);inside(app.run.introName,app.root)
		assert(app.run.skip.AbsolutePosition.Y>=app.run.portrait.AbsolutePosition.Y+app.run.portrait.AbsoluteSize.Y)
	end
	Mock.viewport={1360,800};app:resize()
	Mock.captureGUI(app,"showtime-desktop")
	app.actions.skipShowtime();eq(e.state,"CLAIM");eq(e.deadline-Mock.time,45)
	eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Custom)
	claim(p1,"MAIN")
end)
test("small eliminations produce scoped gold/confetti/cheer, not Credits or decision points",function()
	local before=Data.get(p1).data.credits;local quality=Data.get(p1).data.qualityPoints
	local id=breach(p1,"MAIN",function(value)return value<=50 end);local e=Mock.engines.MAIN
	eq(e.state,"BREACH_REACT");eq(e:snapshot().lastBreach.id,id)
	frame(.28)
	assert(#Mock.director.confetti==14);assert(Mock.effects.sounds.Cheer.IsPlaying)
	eq(Data.get(p1).data.credits,before);eq(Data.get(p1).data.qualityPoints,quality)
	eq(game:GetService("Lighting").Brightness,2)
	for _,light in Mock.director.arenas.QUICK.lights do eq(light.object.Brightness,light.brightness)end
end)
test("jackpot loss has a short quiet beat and local red pulse; reduced motion cancels animated effects",function()
	Mock.finishShow(Mock.engines.MAIN)
	breach(p1,"MAIN",function(value)return value>=5000 end)
	assert(not Mock.effects.sounds.Gasp.IsPlaying)
	frame(.24);assert(Mock.effects.sounds.Gasp.IsPlaying);assert(Mock.effects.sounds.Impact.IsPlaying)
	local lights=Mock.director.arenas.MAIN.lights;assert(lights[1].object.Color.G<lights[1].color.G)
	app.actions.setting("reducedMotion",true);frame(.05)
	eq(#Mock.director.confetti,0);eq(Mock.effects.correction.Brightness,0)
	for _,light in lights do eq(light.object.Color.G,light.color.G)end
	app.actions.setting("reducedMotion",false)
end)
test("quote roll is shared by HUD and live TV, with controls locked until all 18 seconds begin",function()
	local e=Mock.engines.MAIN;Mock.finishShow(e)
	while e.state=="BREACH"do
		breach(p1,"MAIN");tick(e) -- end reaction, but do not skip the last quote roll
	end
	eq(e.state,"OFFER_ROLL");assert(not app.run.left.Active)
	local endAt=e.deadline;local target=e.offer
	frame(.4,true);eq(app.run.amount.Text,Mock.television.amount.Text)
	assert(app.run.amount.Text~=tostring(target).." CR")
	Mock.captureGUI(app,"rolling-offer")
	local previous=Mock.viewport;Mock.viewport={1280,560};Mock.captureGUI({root=Mock.television.root},"live-tv",{background="flat"});Mock.viewport=previous
	action(p1,"DECIDE",payload(e,"EXTRACT"));eq(e.state,"OFFER_ROLL")
	tick(e);eq(e.state,"OFFER");eq(e.deadline-Mock.time,18);assert(e.deadline>endAt)
	assert(app.run.left.Active);eq(Mock.television.amount.Text,app.run.amount.Text)
	for _,v in app.model.directory.broadcast.MAIN.vaults do if not v.opened then eq(v.value,nil)end end
end)
test("final two doors get focused lighting and explicit physical KEEP/SWAP; glyph contact cannot decide",function()
	local e=Mock.engines.MAIN
	for round=1,4 do
		if e.state~="OFFER"then offer(p1,"MAIN")end
		app.actions.choice(2);tick(e)
	end
	eq(e.state,"FINAL_CHOICE");frame(.1)
	local rig=Mock.world.arenas.MAIN.root.ShowRig
	assert(rig.FocusA.Focus.Enabled and rig.FocusB.Focus.Enabled and rig.ContestantFill.Focus.Enabled)
	for i,v in Mock.world.arenas.MAIN.vaults do
		local eligible=i==e.claimId or i==e.finalId
		eq(v.model.FloorGlyph.Transparency<1,eligible);eq(v.prompt.Enabled,eligible);assert(not v.model.FloorGlyph.CanTouch)
	end
	Mock.captureGUI(app,"final-choice")
	captureScene(Mock.json(Mock.captureWorld()))
	local chosen=e.finalId;local door=Mock.world.arenas.MAIN.vaults[chosen]
	door.model.FloorGlyph.Touched:Fire(p1.Character.HumanoidRootPart);eq(e.state,"FINAL_CHOICE")
	p1.Character.HumanoidRootPart.CFrame=door.anchor.CFrame;door.prompt.Triggered:Fire(p1);eq(e.state,"REVEAL");eq(e.chosenId,chosen)
	tick(e);eq(e.state,"RESULT");assert(Data.get(p1).data.achievements.FINALIST)
	app.actions.returnLobby();frame(.2)
	assert(not rig.FocusA.Focus.Enabled and not rig.FocusB.Focus.Enabled)
end)
test("a deliberately used sofa enters a reversible director view; incidental sitting does not",function()
	clear();local item=Mock.world.seats[1];local h=p1.Character.Humanoid
	item.seat:Sit(h);frame(.1);assert(not p1:GetAttribute("VaultSeatView"));eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Custom)
	h.Sit=false
	p1.Character.HumanoidRootPart.CFrame=item.seat.CFrame;item.prompt.Triggered:Fire(p1);frame(1)
	assert(p1:GetAttribute("VaultSeatView"));eq(h.SeatPart,item.seat);eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Scriptable)
	app.actions.stand();frame(.1);eq(h.SeatPart,nil);eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Custom)
	app.actions.setting("seatCamera",false)
	item.prompt.Triggered:Fire(p1);frame(.1);eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Custom)
	app.actions.play("MAIN");frame(.2);eq(h.SeatPart,nil);assert(not p1:GetAttribute("VaultSeatView"));eq(Mock.engines.MAIN.state,"SHOWTIME")
	app.actions.returnLobby();app.actions.setting("seatCamera",true);frame(.2)
end)
test("preset reactions are audience-only, rate-limited, bounded and never count as votes",function()
	clear();action(p2,"PLAY",{target="MAIN"});action(p3,"PLAY",{target="QUICK"});frame(.2)
	local e=Mock.engines.MAIN
	local function reaction(p,key)action(p,"REACTION",{arenaId="MAIN",runId=e.runId,key=key})end
	reaction(p3,"WOW");eq(#Mock.audience.bubbles,0)
	app.actions.toggleSocial();assert(app.social.open)
	for _,size in {{1360,800},{390,844},{568,260},{320,260}}do Mock.viewport=size;app:resize();inside(app.social.panel,app.root);inside(app.social.close,app.social.panel);for _,button in app.social.buttons do inside(button,app.social.panel)end end
	Mock.viewport={1360,800};app:resize();Mock.captureGUI(app,"audience-reactions");app.actions.react("WOW");eq(#Mock.audience.bubbles,1)
	eq(e:snapshot().poll.total,0);assert(not app.social.open)
	reaction(p1,"CASH");eq(#Mock.audience.bubbles,1)
	reaction(p1,"unfiltered player message");eq(#Mock.audience.bubbles,1)
	local a,b,c=Mock.player(804,"ViewerA"),Mock.player(805,"ViewerB"),Mock.player(806,"ViewerC")
	for _,p in {a,b,c}do action(p,"SYNC");reaction(p,"GASP")end
	eq(#Mock.audience.bubbles,3);frame(2.7);eq(#Mock.audience.bubbles,0)
end)
test("cosmetic purchases require confirmation, ignore client prices and cannot double-charge or alter a live run",function()
	clear();local entry=Data.get(p1);entry.data.credits=3000;Data.onChanged(p1)
	app.actions.confirmStyle("BRASS");eq(app.overlayMode,"STYLE_CONFIRM");eq(entry.data.credits,3000)
	app.overlay.close.Activated:Fire();eq(entry.data.credits,3000)
	app.actions.confirmStyle("BRASS");app.overlay.body:FindFirstChild("ConfirmPurchase").Activated:Fire()
	eq(entry.data.credits,2500);assert(entry.data.ownedCosmetics.BRASS)
	action(p1,"BUY_STYLE",{id="BRASS",price=0});eq(entry.data.credits,2500)
	action(p1,"BUY_STYLE",{id="NO_SUCH_ITEM",price=-1000});eq(entry.data.credits,2500)
	app.actions.play("MAIN");frame(.2);local e=Mock.engines.MAIN;eq(e.cosmeticId,"CLASSIC")
	action(p1,"EQUIP_STYLE",{id="BRASS"});eq(entry.data.equippedCosmetic,"BRASS");eq(e.cosmeticId,"CLASSIC")
	app.actions.returnLobby();frame(.2);app.actions.play("MAIN");frame(.2);eq(e.cosmeticId,"BRASS")
	local hub=Mock.world.arenas.MAIN.vaults[1].wheel.Hub
	eq(hub.Color.R,242/255);eq(Mock.world.arenas.MAIN.vaults[1].status.Color.G,module("src/ReplicatedStorage/Config/VisualConfig.luau").Teal.G)
end)
test("public/profile save snapshots deeply isolate ownership while a save is in flight",function()
	local entry=Data.get(p1);app.actions.returnLobby();frame(.2)
	entry.data.credits=3000;Data.onChanged(p1)
	local copy=Data.public(p1);copy.ownedCosmetics.BRASS=false;assert(entry.data.ownedCosmetics.BRASS)
	Mock.storeDelay={User_801=.6}
	task.spawn(function()Data.save(p1.UserId,false)end)
	assert(entry.saving);local ok=Data.style(p1,"BUY_STYLE","ARCTIC");assert(ok);eq(entry.data.credits,1800)
	frame(.65,true);assert(not Mock.stores.VaultBreakers_UserData_v1.User_801.profile.ownedCosmetics.ARCTIC)
	Mock.storeDelay=nil;assert(Data.save(p1.UserId,false));assert(Mock.stores.VaultBreakers_UserData_v1.User_801.profile.ownedCosmetics.ARCTIC)
	entry.status="SESSION_ONLY";local balance=entry.data.credits;assert(not Data.style(p1,"BUY_STYLE","PLUM"));eq(entry.data.credits,balance);entry.status="READY"
end)
test("future profile versions cannot be downgraded or overwritten by the v3 migration",function()
	local raw={profile={version=4,credits=777,newField="preserve"}}
	Mock.stores.VaultBreakers_UserData_v1.User_809=Mock.copy(raw)
	local p=Mock.player(809,"FutureProfile");frame(1.1)
	eq(Data.get(p).status,"SESSION_ONLY");eq(Mock.json(Mock.stores.VaultBreakers_UserData_v1.User_809),Mock.json(raw))
end)
test("hall avatar loads are bounded and stale async completions cannot replace a newer winner",function()
	clear();Mock.avatarDelay=.4
	Mock.hall:update({scope="SERVER",rows={{userId=3001,name="Old",best=500}}},"en")
	Mock.hall:update({scope="SERVER",rows={{userId=3002,name="New",best=600}}},"en")
	Mock.advance(.5,true);local slot=Mock.hall.slots[1];eq(slot.userId,3002);eq(slot.avatar.Name,"WinnerAvatar")
	local parts=0;for _,o in slot.avatar:GetDescendants()do if o:IsA("BasePart")then parts+=1;assert(o.Anchored and not o.CanCollide and not o.CanTouch)end end;assert(parts<=55)
	Mock.avatarFailure=true;Mock.hall:update({scope="SERVER",rows={{userId=3003,name="Unavailable",best=700}}},"en");Mock.advance(.5,true)
	assert(Mock.hall.slots[1].failed);eq(Mock.hall.slots[1].avatar.Name,"PortraitLoading")
	Mock.avatarFailure=false;Mock.avatarDelay=nil
end)
test("optional historical rankings are monotonic, retryable, cached honestly and disabled by default",function()
	local History=module("src/ServerScriptService/Services/HistoryService.luau")
	local off=History.new(false);off:enqueue({breakerId=1,baseCredits=500});eq(next(off.pending),nil);eq(off:display({}).scope,"SERVER")
	local h=History.new(true);h:enqueue({breakerId=1,baseCredits=500});h:enqueue({breakerId=1,baseCredits=50});assert(h:flush());assert(h:refresh());eq(h.rows[1].best,500)
	Mock.orderedFailure=true;h:enqueue({breakerId=1,baseCredits=1000});assert(not h:flush());eq(h.pending[1],1000);assert(not h:refresh());assert(h:display({}).cached)
	Mock.orderedFailure=false;assert(h:flush());assert(h:refresh());eq(h.rows[1].best,1000);assert(not h:display({}).cached)
end)
test("music and crowd controls are independent; Quick does not inherit Main reactions",function()
	clear();app.actions.play("QUICK");frame(.2)
	local e=Mock.engines.QUICK;assert(Mock.effects.sounds.Music.IsPlaying)
	app.actions.setting("music",false);assert(not Mock.effects.sounds.Music.IsPlaying);assert(Mock.effects.groups.SFX.Volume>0)
	app.actions.setting("crowd",false);eq(Mock.effects.groups.CROWD.Volume,0)
	local main={arenaId="MAIN",runId=999,phaseId=1,state="BREACH_REACT",phaseStartedAt=Mock.time,deadline=Mock.time+1,round=1,lastBreach={id=1,value=1,at=Mock.time}}
	Mock.effects:update(e:snapshot(),app.model.settings,{MAIN=main},{});eq(Mock.effects.scope,"QUICK:"..e.runId);assert(not Mock.effects.sounds.Cheer.IsPlaying)
	app.actions.setting("sound",false);for _,sound in Mock.effects.sounds do assert(not sound.IsPlaying)end
	app.actions.setting("sound",true);app.actions.setting("music",true);app.actions.setting("crowd",true)
end)
test("leaving a reveal cancels delayed emotional audio; unloaded one-shots never play late",function()
	local fx=Mock.effects
	local s={arenaId="MAIN",runId=999,phaseId=1,state="BREACH_REACT",phaseStartedAt=Mock.time,deadline=Mock.time+1,round=1,lastBreach={id=1,value=10000,at=Mock.time}}
	fx:update(s,app.model.settings,{},{});fx:stop("Gasp")
	fx:update({arenaId="MAIN",runId=999,phaseId=2,state="IDLE",phaseStartedAt=Mock.time,deadline=0},app.model.settings,{},{})
	Mock.advance(.25,true);assert(not fx.sounds.Gasp.IsPlaying)
	fx:stop("Breach");fx.sounds.Breach._properties.IsLoaded=false;fx:play("Breach");assert(not fx.sounds.Breach.IsPlaying)
	fx.sounds.Breach._properties.IsLoaded=true;Mock.advance(.2,true);assert(not fx.sounds.Breach.IsPlaying)
end)
test("death during showtime releases immediately without paying or leaving a forced camera",function()
	clear();local before=Data.get(p1).data.credits
	app.actions.play("MAIN");frame(.1);eq(Mock.engines.MAIN.state,"SHOWTIME")
	local h=p1.Character.Humanoid;h.Health=0;h.Died:Fire();frame(.1)
	eq(Mock.engines.MAIN.state,"IDLE");eq(Data.get(p1).data.credits,before);eq(workspace.CurrentCamera.CameraType,Enum.CameraType.Custom)
	assert(not p1:GetAttribute("VaultSeatView"));eq(#Mock.director.confetti,0);h.Health=100
end)
test("a partially replicated show rig is retried without caching missing vault references",function()
	local Controller=module("src/StarterPlayerScripts/Controllers/StagePresentationController.luau")
	local controller=Controller.new();local vault=Mock.world.arenas.MAIN.vaults[12].model;local parent=vault.Parent
	vault.Parent=nil
	controller:update(app.model.directory.broadcast,app.model.settings,p1,false);eq(controller.arenas.MAIN,nil)
	vault.Parent=parent;controller:update(app.model.directory.broadcast,app.model.settings,p1,false)
	assert(controller.arenas.MAIN and controller.arenas.MAIN.vaults[12].glyph)
	controller:destroy()
end)
print(string.format("%d show/social/progression integration groups passed; %d failed.",passed,#failures))
assert(#failures==0,table.concat(failures,"\n"))
