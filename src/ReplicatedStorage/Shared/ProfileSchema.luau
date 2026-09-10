--!strict
local Catalog=require(script.Parent.Parent.Config.CosmeticCatalog)
local Schema={VERSION=3}
local FIELDS={"credits","reputation","runs","totalEarnings","bestExtract","bestFinal","qualityPoints","decisionStreak","longestStreak","decisionsMade","soundDecisions","mainAppearances","goodPushes","goodExtracts"}
local function safe(value:any):number
	return if type(value)=="number"and value==value then math.clamp(math.floor(value),0,1e12)else 0
end
local function source(raw:any):any
	local value=if type(raw)=="table"then raw else{}
	return if type(value.profile)=="table"then value.profile else value
end
function Schema.supported(raw:any):boolean
	local version=source(raw).version
	return version==nil or version==1 or version==2 or version==3
end
function Schema.normalize(raw:any):any
	local old=source(raw);local profile:any={version=3}
	for _,key in FIELDS do profile[key]=safe(old[key])end
	if old.version~=2 and old.version~=3 then
		profile.credits=safe(old.cash or old.credits);profile.runs=safe(old.careerMatches or old.runs);profile.bestExtract=safe(old.careerEarnings or old.bestExtract)
	end
	profile.heat=if profile.qualityPoints>=12 then 2 elseif profile.qualityPoints>=7 then 1.5 elseif profile.qualityPoints>=3 then 1.2 else 1
	profile.highestHeat=math.clamp(if type(old.highestHeat)=="number"and old.highestHeat==old.highestHeat then old.highestHeat else 1,profile.heat,2)
	profile.ownedCosmetics={CLASSIC=true};profile.achievements={}
	if type(old.ownedCosmetics)=="table"then for id in Catalog.ITEMS do if old.ownedCosmetics[id]==true then profile.ownedCosmetics[id]=true end end end
	if type(old.achievements)=="table"then for _,id in Catalog.TITLES do if old.achievements[id]==true then profile.achievements[id]=true end end end
	profile.equippedCosmetic=if type(old.equippedCosmetic)=="string"and profile.ownedCosmetics[old.equippedCosmetic]then old.equippedCosmetic else"CLASSIC"
	profile.equippedTitle=if type(old.equippedTitle)=="string"and profile.achievements[old.equippedTitle]then old.equippedTitle else""
	return profile
end
function Schema.copy(profile:any):any
	local copy=table.clone(profile)
	copy.ownedCosmetics=table.clone(profile.ownedCosmetics)
	copy.achievements=table.clone(profile.achievements)
	return copy
end
return Schema
