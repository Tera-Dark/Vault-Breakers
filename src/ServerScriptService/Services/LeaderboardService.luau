--!strict
-- Only completed runs in this server. Historical profile loads cannot fabricate a studio result.
-- Keep at most eight entries even in a long-lived server with many visitors.
local Board = {}
local entries: { [number]: any } = {}
function Board.rows(): { any }
	local rows = {}
	for _, entry in entries do table.insert(rows, table.clone(entry)) end
	table.sort(rows, function(a, b)
		if a.best == b.best then return a.userId < b.userId end
		return a.best > b.best
	end)
	return rows
end
function Board.update(player: Player, data: any)
	local entry = entries[player.UserId]
	if entry then
		entry.reputation = data.reputation or entry.reputation
		entry.heat = math.max(entry.heat, data.heat or 1)
	end
end
function Board.record(player: Player, result: any, data: any)
	local previous = entries[player.UserId]
	entries[player.UserId] = {
		userId = player.UserId, name = player.DisplayName,
		best = math.max(if previous then previous.best else 0, result.baseCredits),
		heat = math.max(if previous then previous.heat else 1, result.heat, data.heat or 1),
		reputation = data.reputation or 0,
	}
	local rows = Board.rows()
	for i = 9, #rows do entries[rows[i].userId] = nil end
end
return Board
