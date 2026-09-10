--!nonstrict
-- Executed against the actual production modules, not a reimplementation of their logic.
local Config = requireTest("src/ReplicatedStorage/Config/GameConfig.luau")
local Pool = requireTest("src/ReplicatedStorage/Config/RewardPool.luau")
local Offer = requireTest("src/ReplicatedStorage/Config/OfferAlgorithm.luau")
local Quality = requireTest("src/ReplicatedStorage/Shared/DecisionQuality.luau")
local Schema = requireTest("src/ReplicatedStorage/Shared/ProfileSchema.luau")
local Decisions = requireTest("src/ServerScriptService/Services/DecisionService.luau")
local Engine = requireTest("src/ServerScriptService/Core/RunEngine.luau")
local Queue = requireTest("src/ServerScriptService/Services/QueueService.luau")
local Limiter = requireTest("src/ServerScriptService/Services/RateLimiter.luau")
local passed = 0
local function test(name, callback)
	local ok, failure = pcall(callback)
	assert(ok, name .. ": " .. tostring(failure))
	passed += 1
	print("PASS", name)
end
local function equal(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function engine(audience, seed)
	local value = seed or 17
	local function random(a,b)
		value = (value * 48271) % 2147483647
		return a + value % (b - a + 1)
	end
	return Engine.new({ id = if audience == false then "QUICK" else "MAIN", audience = audience ~= false }, {
		config = Config, rewards = Pool.VALUES, offers = Offer, quality = Quality, random = random,
	})
end
local function start(e, heat)
	assert(e:start({ id = 1, name = "Breaker", heat = heat or 1 }, 100))
	if e.state=="SHOWTIME"then assert(e:skipShowtime(1,100))end
	assert(e:claim(1, 1, 101))
end
local function advance(e) e:step(e.deadline) end
local function presentations(e)while e.state=="BREACH_REACT"or e.state=="OFFER_ROLL"do e:step(e.deadline)end end
local function openRound(e)
	presentations(e)
	while e.state == "BREACH" do
		for _, v in e.vaults do
			if not v.claimed and not v.opened then assert(e:breach(1, v.id, e.deadline - 1)); break end
		end
		equal(e.state, "OPENING")
		advance(e);presentations(e)
	end
	equal(e.state, "OFFER")
end
local function push(e) assert(e:decide(1,"PUSH",e.deadline-1)); advance(e) end

test("public state never leaks an unopened reward, including during opening / reveal", function()
	local e = engine(); start(e)
	for _, v in e:snapshot().vaults do equal(v.value,nil) end
	assert(e:breach(1,2,102)); equal(e:snapshot().vaults[2].value,nil)
	advance(e); equal(e:snapshot().vaults[2].value,e.vaults[2].value)
	openRound(e); assert(e:decide(1,"EXTRACT",e.deadline-1))
	equal(e:snapshot().vaults[1].value,nil); equal(e:snapshot().result,nil)
	advance(e); equal(e:snapshot().vaults[1].value,e.vaults[1].value)
end)
test("12 -> 8 -> 5 -> 3 -> 2, four offers, then reachable KEEP/SWAP", function()
	local e=engine(); start(e)
	for round,remaining in {8,5,3,2} do
		openRound(e); equal(e.round,round); equal(#e:snapshot().remaining,remaining); push(e)
	end
	equal(e.state,"FINAL_CHOICE"); assert(e.finalId and e.finalId ~= e.claimId)
end)
test("wrong player, malformed indices, claimed doors and double breach rejected",function()
	local e=engine(); assert(e:start({id=1,name="B"},0));assert(e:skipShowtime(1,0))
	assert(not e:claim(2,1,1)); assert(not e:claim(1,0,1)); assert(not e:claim(1,1.5,1)); assert(not e:claim(1,0/0,1))
	assert(e:claim(1,1,1)); assert(not e:breach(1,1,2)); assert(not e:breach(2,2,2))
	assert(e:breach(1,2,2)); assert(not e:breach(1,3,2)); advance(e)
	assert(not e:breach(1,2,e.deadline-1))
end)
test("last breach locks input before delayed offer; no extra openings / duplicate offers",function()
	local e=engine();start(e)
	for id=2,5 do
		assert(e:breach(1,id,e.deadline-1)); assert(not e:breach(1,6,e.deadline-1)); advance(e);presentations(e)
	end
	equal(#e:snapshot().remaining,8); equal(e.state,"OFFER")
	assert(not e:breach(1,6,e.deadline-1))
end)
test("extraction pays once; multiplier was locked at run start",function()
	local e=engine();start(e,1.5);openRound(e)
	local amount=e.offer
	assert(e:decide(1,"EXTRACT",e.deadline-1)); assert(not e:decide(1,"EXTRACT",e.deadline-1))
	advance(e);equal(e.result.credits,math.floor(amount*1.5+0.5))
	local settlements=0
	for _,event in e:drainEvents() do if event.kind=="SETTLE" then settlements+=1 end end
	equal(settlements,1); e:step(e.deadline-1); equal(#e:drainEvents(),0)
end)
test("KEEP and SWAP award exactly the chosen hidden vault",function()
	for _,choice in {"KEEP","SWAP"} do
		local e=engine();start(e)
		for _=1,4 do openRound(e);push(e) end
		local expected=e.vaults[if choice=="KEEP" then e.claimId else e.finalId].value
		assert(e:chooseFinal(1,choice,e.deadline-1));advance(e)
		equal(e.result.baseCredits,expected);equal(e.result.choice,choice)
		equal(e.result.otherValue,e.vaults[if choice=="KEEP" then e.finalId else e.claimId].value)
	end
end)
test("timeouts AUTO PUSH and final KEEP; automatic choices award no quality points",function()
	local e=engine();start(e)
	for _=1,4 do
		openRound(e);advance(e);equal(e.decisions[#e.decisions].score,0);advance(e)
	end
	equal(e.state,"FINAL_CHOICE");advance(e);advance(e)
	equal(e.result.choice,"KEEP");equal(e.result.baseCredits,e.vaults[1].value)
end)
test("lifeline only once, only Main round 3+, freezes decisions and preserves offer",function()
	local e=engine();start(e);openRound(e);assert(not e:lifeline(1,e.deadline-1));push(e)
	openRound(e);push(e);openRound(e)
	local amount=e.offer; assert(e:lifeline(1,e.deadline-2)); equal(e.state,"LIFELINE")
	assert(not e:decide(1,"EXTRACT",e.deadline-1));advance(e)
	equal(e.state,"OFFER");equal(e.offer,amount);equal(e.consensus,"NONE")
	assert(not e:lifeline(1,e.deadline-1))
	local quick=engine(false);start(quick)
	for _=1,2 do openRound(quick);push(quick) end
	openRound(quick);assert(not quick:lifeline(1,quick.deadline-1));assert(not quick:vote(2,"PUSH",quick.deadline-1))
end)
test("one vote per spectator, switch / departure / no-vote and tie handled honestly",function()
	local e=engine();start(e);openRound(e)
	assert(not e:vote(1,"PUSH",e.deadline-1));assert(not e:vote(2,"KEEP",e.deadline-1));equal(e:snapshot().poll.total,0)
	assert(e:vote(2,"PUSH",e.deadline-1));assert(e:vote(2,"PUSH",e.deadline-1));equal(e:snapshot().poll.total,1)
	assert(e:vote(2,"EXTRACT",e.deadline-1));equal(e:snapshot(2).poll.myVote,"EXTRACT")
	e:playerLeft(2,e.deadline-1);equal(e:snapshot().poll.total,0)
	push(e);openRound(e);push(e);openRound(e)
	assert(e:lifeline(1,e.deadline-1));e:vote(2,"PUSH",e.deadline-1);e:vote(3,"EXTRACT",e.deadline-1);advance(e)
	equal(e.consensus,"TIE")
end)
test("final audience poll uses KEEP/SWAP, not stale Extract/Push",function()
	local e=engine();start(e);for _=1,4 do openRound(e);push(e) end
	assert(not e:vote(2,"PUSH",e.deadline-1));assert(e:vote(2,"SWAP",e.deadline-1));equal(e:snapshot().poll.kind,"FINAL")
end)
test("AFK and disconnect free the stage; stale phase and run requests cannot act",function()
	local e=engine();e:start({id=1,name="B"},0);e:skipShowtime(1,0);local run,phase=e.runId,e.phaseId
	advance(e);equal(e.state,"IDLE");assert(not e:matches(run,phase))
	start(e);assert(not e:matches(run,phase));e:breach(1,2,102);e:playerLeft(1,102.1)
	equal(e.state,"IDLE");e:step(1000);equal(e.state,"IDLE");equal(#e.vaults,0)
end)
test("clean replay restores all twelve unopened doors and a new claim",function()
	local e=engine();start(e);openRound(e);e:decide(1,"EXTRACT",e.deadline-1);advance(e);advance(e)
	equal(e.state,"IDLE");start(e);equal(#e:_remaining(),12);equal(e.breached,0);equal(e.round,1)
end)
test("two arenas cannot share votes, timers, rewards or results",function()
	local main,quick=engine(),engine(false,29);start(main);start(quick)
	openRound(main);openRound(quick);main:vote(9,"PUSH",main.deadline-1);equal(quick:snapshot().poll.total,0)
	local quickPhase=quick.phaseId;main:decide(1,"EXTRACT",main.deadline-1);advance(main)
	equal(quick.phaseId,quickPhase);equal(quick.result,nil);equal(quick.state,"OFFER")
end)
test("risk evaluation uses contemporaneous board, recognises certainty and defensible push",function()
	equal(Quality.evaluate("EXTRACT",4500,5000.5,{1,10000}).grade,"ELITE_EXTRACT")
	equal(Quality.evaluate("PUSH",500,5000,{2500,7500}).grade,"REASONABLE_PUSH")
	equal(Quality.evaluate("PUSH",4900,4950,{4900,5000}).grade,"THIN_UPSIDE")
	equal(Quality.evaluate("PUSH",500,5000,{2500,7500},true).score,0)
end)
test("profile migration sanitises input and Heat changes by decisions, never RNG outcome",function()
	local old=Schema.normalize({cash=12000,careerMatches=7,careerEarnings=9000})
	equal(old.credits,12000);equal(old.runs,7);equal(old.bestExtract,9000)
	local bad=Schema.normalize({version=2,credits=0/0,reputation=-2,qualityPoints="12"})
	equal(bad.credits,0);equal(bad.reputation,0);equal(bad.heat,1)
	for _=1,3 do Decisions.apply(bad,{{score=1,automatic=false}}) end
	equal(bad.heat,1.2)
	local heat=bad.heat;Decisions.apply(bad,{{score=0,automatic=true}});equal(bad.heat,heat)
end)
test("queue is FIFO, preference-aware and duplicate-free; leaving removes ticket",function()
	local q=Queue.new();assert(q:add(1,"QUICK"));assert(not q:add(1,"AUTO"));q:add(2,"AUTO");q:add(3,"MAIN")
	equal(q:popFor("MAIN"),2);equal(q:popFor("QUICK"),1);equal(q:position(3),1)
	q:remove(3);equal(q:popFor("MAIN"),nil)
end)
test("rate limit bounds bursts and recovers with time",function()
	local limit=Limiter.new();for _=1,10 do assert(limit:allow(1,0)) end
	assert(not limit:allow(1,0));assert(limit:allow(1,1));limit:forget(1);assert(limit:allow(1,1))
end)
test("server board records only real completions, ranks base rewards, and remains bounded",function()
	local board=requireTest("src/ServerScriptService/Services/LeaderboardService.luau")
	local player={UserId=1,DisplayName="P1"}
	board.update(player,{bestExtract=999999,heat=2,reputation=99});equal(#board.rows(),0)
	for i=1,24 do
		board.record({UserId=i,DisplayName="P"..i},{baseCredits=i*10,credits=i*20,heat=2},{reputation=i})
	end
	equal(#board.rows(),8);equal(board.rows()[1].best,240);equal(board.rows()[8].best,170)
	board.record({UserId=25,DisplayName="Tie"},{baseCredits=240,credits=480,heat=2},{reputation=1})
	equal(board.rows()[1].userId,24);equal(board.rows()[2].userId,25)
end)
test("deadlines win over late Claim, breach, EXTRACT, final SWAP and lifeline input",function()
	local e=engine();e:start({id=1,name="B"},0);e:skipShowtime(1,0)
	assert(not e:claim(1,1,e.deadline));equal(e.state,"IDLE")
	start(e);assert(not e:breach(1,2,e.deadline));equal(e.state,"IDLE")
	start(e);openRound(e);assert(not e:decide(1,"EXTRACT",e.deadline));equal(e.state,"TRANSITION");assert(e.decisions[1].automatic)
	advance(e);openRound(e);push(e);openRound(e)
	assert(not e:lifeline(1,e.deadline));assert(not e.lifelineUsed);equal(e.state,"TRANSITION")
	advance(e);openRound(e);push(e);equal(e.state,"FINAL_CHOICE")
	assert(not e:chooseFinal(1,"SWAP",e.deadline));equal(e.choice,"KEEP");assert(e.automatic)
end)
test("expired polls reject late votes and snapshot revisions only increase on changes",function()
	local e=engine();start(e);openRound(e)
	local version=e:snapshot().revision
	assert(e:vote(2,"PUSH",e.deadline-1));assert(e:snapshot().revision>version)
	version=e:snapshot().revision;assert(e:vote(2,"PUSH",e.deadline-1));equal(e:snapshot().revision,version)
	assert(e:withdrawVote(2));equal(e:snapshot().poll.total,0);assert(e:snapshot().revision>version)
	assert(not e:vote(2,"EXTRACT",e.deadline));equal(e.state,"TRANSITION")
end)
test("1,000 seeded full runs reach a single valid settlement with conserved prize pool",function()
	for seed=1,1000 do
		local e=engine(true,seed);start(e)
		local endRound=1+(seed%5)
		for round=1,4 do
			openRound(e)
			assert(e.offer>=1 and e.offer<=e:_remaining()[#e:_remaining()])
			if round==endRound then e:decide(1,"EXTRACT",e.deadline-1);break else push(e) end
		end
		if e.state=="FINAL_CHOICE" then e:chooseFinal(1,if seed%2==0 then "KEEP" else "SWAP",e.deadline-1) end
		advance(e);equal(e.state,"RESULT");assert(e.result.credits>=1 and e.result.credits<=20000)
		local seen={};for _,vault in e.vaults do assert(not seen[vault.value]);seen[vault.value]=true end
		local count=0;for _,event in e:drainEvents() do if event.kind=="SETTLE" then count+=1 end end;equal(count,1)
	end
end)
print(string.format("%d test groups passed, including 1,000 deterministic end-to-end engine runs.",passed))
