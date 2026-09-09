--!strict
local Queue = {}
Queue.__index = Queue
function Queue.new(): any return setmetatable({ tickets = {} }, Queue) end
function Queue.remove(self: any, id: number)
	for index = #self.tickets, 1, -1 do
		if self.tickets[index].id == id then table.remove(self.tickets, index) end
	end
end
function Queue.position(self: any, id: number): number
	for index, ticket in self.tickets do if ticket.id == id then return index end end
	return 0
end
function Queue.add(self: any, id: number, target: string): boolean
	if self:position(id) > 0 then return false end
	table.insert(self.tickets, { id = id, target = target })
	return true
end
function Queue.popFor(self: any, arena: string): number?
	for index, ticket in self.tickets do
		if ticket.target == "AUTO" or ticket.target == arena then
			table.remove(self.tickets, index)
			return ticket.id
		end
	end
	return nil
end
return Queue
