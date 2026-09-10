--!strict
-- Public presentation math only. Never changes prizes, EV, decision quality or clocks.
local Show = {}
function Show.band(value: number, pool: {number}): string
	local ordered=table.clone(pool);table.sort(ordered)
	local rank=table.find(ordered,value)
	if not rank then return "NEUTRAL" end
	if rank<=math.max(1,math.floor(#ordered*0.42)) then return "SMALL" end
	if rank>=#ordered-1 then return "JACKPOT" end
	if rank>=#ordered-3 then return "LARGE" end
	return "NEUTRAL"
end
function Show.progress(started: number, deadline: number, now: number): number
	return if deadline<=started then 1 else math.clamp((now-started)/(deadline-started),0,1)
end
function Show.counter(amount: number, started: number, deadline: number, now: number, reduced: boolean?): number
	if reduced then return amount end
	local p=Show.progress(started,deadline,now)
	return math.clamp(math.floor(amount*(1-(1-p)^3)),0,amount)
end
function Show.freshBreach(s: any, now: number): boolean
	return s.lastBreach~=nil and type(s.lastBreach.at)=="number" and now>=s.lastBreach.at and now-s.lastBreach.at<1.5
end
return Show
