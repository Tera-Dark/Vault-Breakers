--!nonstrict
local State=requireTest("src/StarterPlayerScripts/Controllers/ClientState.luau")
local count=0
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local function test(name,run)local ok,err=pcall(run);assert(ok,name..": "..tostring(err));count+=1;print("PASS",name)end
local function create()local m={userId=5,pending=false};return State.new(m),m end
local function snap(arena,run,phase,state,owner,version)
	return {arenaId=arena,runId=run,phaseId=phase,state=state,breakerId=owner,revision=version or 1,deadline=100+run,result=if state=="RESULT" then {}else nil}
end
local function directory(id,run,phase,own,seq)
	return {myArena=if own then id else nil,view=id,arenas={{id=id,runId=run,phaseId=phase}},sequence=seq or 1}
end

test("snapshot-before-directory and directory-before-snapshot converge without an old board",function()
	for _,snapshotFirst in {true,false} do
		local state,m=create();local s=snap("MAIN",2,1,"CLAIM",5)
		state:snapshot(snap("MAIN",1,28,"RESULT",99))
		if snapshotFirst then state:snapshot(s)end
		state:directory(directory("MAIN",2,1,true))
		if not snapshotFirst then eq(m.snapshot,nil);assert(m.syncing);state:snapshot(s)end
		eq(m.snapshot,s);assert(not m.syncing)
	end
end)
test("a first result that arrives before its assignment is shown, not treated as dismissed",function()
	local state,m=create();local result=snap("MAIN",1,30,"RESULT",5)
	state:snapshot(result);assert(not m.showRecap)
	state:directory(directory("MAIN",1,30,true));assert(m.showRecap);eq(m.recap,result)
end)
test("a future directory phase or a wrong owner hides controls until a matching snapshot",function()
	local state,m=create();state:directory(directory("MAIN",1,6,true))
	state:snapshot(snap("MAIN",1,5,"OPENING",5));eq(m.snapshot,nil)
	state:snapshot(snap("MAIN",1,6,"OFFER",9,2));eq(m.snapshot,nil)
	state:snapshot(snap("MAIN",1,6,"OFFER",5,3));eq(m.snapshot.breakerId,5)
end)
test("old directory and same-phase poll packets do not roll back newer data",function()
	local state,m=create();state:directory(directory("MAIN",2,7,false,10))
	state:snapshot(snap("MAIN",2,7,"OFFER",3,20))
	assert(not state:snapshot(snap("MAIN",2,7,"OFFER",3,19)))
	assert(not state:directory(directory("QUICK",1,2,false,9)))
	eq(state:view(),"MAIN");eq(m.snapshot.revision,20)
end)
test("unrelated snapshots cannot unlock a pending decision; timeout requests refresh only",function()
	local state,m=create();state:directory(directory("MAIN",1,7,true));state:snapshot(snap("MAIN",1,7,"OFFER",5))
	assert(state:beginAction("DECIDE","EXTRACT",10));assert(not state:beginAction("DECIDE","PUSH",11))
	state:snapshot(snap("QUICK",6,2,"BREACH",9));assert(m.pending)
	assert(not state:expirePending(11.99));assert(state:expirePending(12));assert(not m.pending)
	assert(not state:expirePending(13))
end)
test("dismissed recaps stay dismissed across duplicate snapshots / Sync; next run can show a new recap",function()
	local state,m=create();state:directory(directory("MAIN",1,30,true))
	local s=snap("MAIN",1,30,"RESULT",5);state:snapshot(s);assert(m.showRecap)
	state:hideRecap();state:snapshot(s);state:directory(directory("MAIN",1,30,true,2));assert(not m.showRecap)
	state:directory(directory("LOBBY",0,0,false,3));state:directory(directory("MAIN",2,1,true,4))
	state:snapshot(snap("MAIN",2,1,"CLAIM",5));assert(not m.showRecap)
	state:snapshot(snap("MAIN",2,30,"RESULT",5));assert(m.showRecap);eq(m.recap.runId,2)
end)
test("timed release retains the recap without occupying an arena, late old results do not replace a newer one",function()
	local state,m=create();state:directory(directory("MAIN",3,30,true))
	local newer=snap("MAIN",3,30,"RESULT",5);state:snapshot(newer)
	state:directory(directory("LOBBY",0,0,false,2));assert(m.showRecap);eq(m.snapshot,nil)
	state:snapshot(snap("QUICK",1,25,"RESULT",5));eq(m.recap,newer)
end)
print(string.format("%d pure client transport/state groups passed.",count))
