--!strict
local ProfileSchema = {}
local FIELDS = {
	"credits", "reputation", "runs", "totalEarnings", "bestExtract", "bestFinal",
	"qualityPoints", "decisionStreak", "longestStreak", "decisionsMade", "soundDecisions", "mainAppearances",
}
local function safe(value: any): number
	return if type(value) == "number" and value == value then math.clamp(math.floor(value), 0, 1e12) else 0
end
function ProfileSchema.normalize(raw: any): any
	local source = if type(raw) == "table" then raw else {}
	if type(source.profile) == "table" then source = source.profile end
	local profile: any = { version = 2 }
	for _, key in FIELDS do profile[key] = safe(source[key]) end
	if source.version ~= 2 then
		profile.credits = safe(source.cash or source.credits)
		profile.runs = safe(source.careerMatches or source.runs)
		profile.bestExtract = safe(source.careerEarnings or source.bestExtract)
	end
	profile.heat = if profile.qualityPoints >= 12 then 2 elseif profile.qualityPoints >= 7 then 1.5
		elseif profile.qualityPoints >= 3 then 1.2 else 1
	profile.highestHeat = math.clamp(if type(source.highestHeat) == "number" and source.highestHeat == source.highestHeat then source.highestHeat else 1, profile.heat, 2)
	return profile
end
return ProfileSchema
