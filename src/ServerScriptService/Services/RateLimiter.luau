--!strict
local RateLimiter = {}
RateLimiter.__index = RateLimiter
function RateLimiter.new(): any
	return setmetatable({ buckets = {} }, RateLimiter)
end
function RateLimiter.allow(self: any, id: number, now: number): boolean
	local bucket = self.buckets[id] or { tokens = 10, time = now }
	bucket.tokens = math.min(10, bucket.tokens + math.max(0, now - bucket.time) * 5)
	bucket.time = now
	self.buckets[id] = bucket
	if bucket.tokens < 1 then return false end
	bucket.tokens -= 1
	return true
end
function RateLimiter.forget(self: any, id: number) self.buckets[id] = nil end
return RateLimiter
