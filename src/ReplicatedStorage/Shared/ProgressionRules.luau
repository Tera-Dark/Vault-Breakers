--!strict
-- Experience/quality titles only. A rare result never grants Heat, reputation or better odds.
local Progression={}
function Progression.apply(profile:any,result:any):{string}
	local earned={}
	local function grant(id)
		if not profile.achievements[id]then profile.achievements[id]=true;table.insert(earned,id)end
	end
	for _,d in result.decisions or{}do
		if d.score>0 and not d.automatic then
			if d.decision=="PUSH"then profile.goodPushes+=1 elseif d.decision=="EXTRACT"then profile.goodExtracts+=1 end
		end
	end
	if not result.extracted then grant("FINALIST");if result.baseCredits==1 then grant("ONE_CREDIT")end end
	if profile.goodExtracts>=3 then grant("STEADY")end
	if profile.goodPushes>=3 then grant("RESOLUTE")end
	return earned
end
return Progression
