--!nonstrict
local Config=requireTest("src/ReplicatedStorage/Config/GameConfig.luau")
local Pool=requireTest("src/ReplicatedStorage/Config/RewardPool.luau")
local Engine=requireTest("src/ServerScriptService/Core/RunEngine.luau")
local Show=requireTest("src/ReplicatedStorage/Shared/ShowRules.luau")
local Broadcast=requireTest("src/ReplicatedStorage/Shared/BroadcastState.luau")
local count=0
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local function test(name,fn)local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));count+=1;print("PASS",name)end
local function engine(main)
 local e=Engine.new({id=if main then"MAIN"else"QUICK",audience=main},{config=Config,rewards=Pool.VALUES,offers=requireTest("src/ReplicatedStorage/Config/OfferAlgorithm.luau"),quality=requireTest("src/ReplicatedStorage/Shared/DecisionQuality.luau"),random=function(a,b)return a end})
 e:start({id=1,name="Breaker",heat=1},0);return e
end
test("showtime is Main-only, skippable by its owner, and does not consume Claim time",function()
 local e=engine(true);eq(e.state,"SHOWTIME");eq(e.deadline,2)
 assert(not e:claim(1,1,.5));assert(not e:skipShowtime(2,.5));e:step(2);eq(e.state,"CLAIM");eq(e.deadline,47)
 e=engine(true);assert(e:skipShowtime(1,.3));eq(e.deadline,45.3)
 eq(engine(false).state,"CLAIM")
end)
test("public reveal reaction precedes quote rolling; the full 18s starts only after lock-in",function()
 local e=engine(false);e:claim(1,1,.1)
 for id=2,5 do
  assert(e:breach(1,id,e.phaseStartedAt+.1));e:step(e.deadline)
  eq(e.state,"BREACH_REACT");assert(e:snapshot().vaults[id].value);assert(not e:breach(1,id+1,e.phaseStartedAt+.1))
  e:step(e.deadline)
 end
 eq(e.state,"OFFER_ROLL");assert(not e:decide(1,"EXTRACT",e.phaseStartedAt+.1))
 assert(not e:vote(2,"PUSH",e.phaseStartedAt+.1))
 local rollEnd=e.deadline;e:step(rollEnd);eq(e.state,"OFFER");eq(e.deadline,rollEnd+18)
 assert(e:decide(1,"EXTRACT",rollEnd+.1))
end)
test("presentation tiers follow pool ranks, not invented 50k/100k thresholds",function()
 for _,v in {1,5,10,25,50}do eq(Show.band(v,Pool.VALUES),"SMALL")end
 eq(Show.band(5000,Pool.VALUES),"JACKPOT");eq(Show.band(10000,Pool.VALUES),"JACKPOT")
 eq(Show.band(100,Pool.VALUES),"NEUTRAL");eq(Show.band(99999,Pool.VALUES),"NEUTRAL")
 local scaled={};for _,v in Pool.VALUES do table.insert(scaled,v*10)end
 eq(Show.band(100000,scaled),"JACKPOT")
end)
test("rolling numbers are bounded, monotonic, land exactly and support reduced motion",function()
 local last=0
 for i=0,100 do local n=Show.counter(1357,10,11,10+i/100);assert(n>=last and n<=1357);last=n end
 eq(last,1357);eq(Show.counter(1357,10,11,10,true),1357)
 assert(not Show.freshBreach({lastBreach={id=1,value=5,at=10}},12))
end)
test("Green Room feed keeps public context but cannot expose sealed mappings or personal votes",function()
 local e=engine(false);e:claim(1,1,.1);e:breach(1,2,.2)
 local feed=Broadcast.fromSnapshot(e:snapshot(2))
 for _,v in feed.vaults do eq(v.value,nil)end
 eq(feed.poll,nil);eq(feed.events,nil);eq(feed.pendingId,nil)
 e:step(e.deadline);feed=Broadcast.fromSnapshot(e:snapshot());assert(feed.lastBreach.at);assert(feed.vaults[2].value);eq(feed.vaults[1].value,nil)
end)
local Schema=requireTest("src/ReplicatedStorage/Shared/ProfileSchema.luau")
local Progression=requireTest("src/ReplicatedStorage/Shared/ProgressionRules.luau")
local Reactions=requireTest("src/ReplicatedStorage/Shared/ReactionRules.luau")
local Catalog=requireTest("src/ReplicatedStorage/Config/CosmeticCatalog.luau")
test("v2 migration preserves career values while sanitizing cosmetic/title ownership",function()
 local p=Schema.normalize({profile={version=2,credits=1234,bestExtract=700,runs=8,qualityPoints=7,ownedCosmetics={BRASS=true,UNKNOWN=true},equippedCosmetic="UNKNOWN",achievements={FINALIST=true,FAKE=true},equippedTitle="FAKE"}})
 eq(p.version,3);eq(p.credits,1234);eq(p.bestExtract,700);eq(p.runs,8);eq(p.heat,1.5)
 assert(p.ownedCosmetics.BRASS and p.ownedCosmetics.CLASSIC);eq(p.ownedCosmetics.UNKNOWN,nil);eq(p.equippedCosmetic,"CLASSIC");eq(p.equippedTitle,"")
 assert(not Schema.supported({profile={version=4}}))
 local c=Schema.copy(p);c.ownedCosmetics.BRASS=false;c.achievements.FINALIST=false;assert(p.ownedCosmetics.BRASS and p.achievements.FINALIST)
end)
test("rare one-credit titles use base prize, never change Heat or retrospectively grade luck",function()
 local p=Schema.normalize({version=3,credits=100,qualityPoints=12})
 local earned=Progression.apply(p,{extracted=false,baseCredits=1,credits=2,decisions={}})
 assert(p.achievements.ONE_CREDIT and p.achievements.FINALIST);eq(#earned,2);eq(p.heat,2);eq(p.credits,100);eq(p.reputation,0)
 eq(#Progression.apply(p,{extracted=false,baseCredits=1,credits=2,decisions={}}),0)
 local extract=Schema.normalize(nil);Progression.apply(extract,{extracted=true,baseCredits=1,decisions={}});assert(not extract.achievements.ONE_CREDIT)
end)
test("quality titles reject blind high-offer PUSH and automatic decisions",function()
 local p=Schema.normalize(nil)
 for _=1,3 do Progression.apply(p,{extracted=true,baseCredits=9999,decisions={{decision="PUSH",score=-1,automatic=false},{decision="PUSH",score=1,automatic=true}}})end
 assert(not p.achievements.RESOLUTE);eq(p.goodPushes,0)
 for _=1,3 do Progression.apply(p,{extracted=true,decisions={{decision="PUSH",score=1,automatic=false},{decision="EXTRACT",score=1,automatic=false}}})end
 assert(p.achievements.RESOLUTE and p.achievements.STEADY);eq(p.heat,1);eq(p.qualityPoints,0)
end)
test("reaction presets have per-user and room-wide budgets with no free text",function()
 local r=Reactions.new();assert(r:accept(1,"WOW",0));assert(not r:accept(1,"GASP",1));assert(not r:accept(2,"raw user text",1))
 assert(r:accept(2,"GASP",1));assert(r:accept(3,"PUSH",1));assert(not r:accept(4,"CASH",1))
 assert(r:accept(4,"CASH",3));assert(r:accept(1,"WOW",4));r:forget(1);assert(r:accept(1,"PUSH",4))
end)
test("cosmetic definitions contain no outcome, timer or progression multiplier parameters",function()
 for id,item in Catalog.ITEMS do
  assert(item.price>=0 and item.price==math.floor(item.price))
  for key in item do assert(key=="price"or key=="name"or key=="rgb",id.." contains gameplay configuration")end
 end
 local a,b=engine(false),engine(false);a.cosmeticId="CLASSIC";b.cosmeticId="BRASS"
 for i,v in a.vaults do eq(v.value,b.vaults[i].value)end
 eq(a.heat,b.heat);eq(a.deadline,b.deadline)
end)
print(count.." show/presentation rule groups passed.")
