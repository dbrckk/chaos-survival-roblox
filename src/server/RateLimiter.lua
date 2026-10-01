local RateLimiter = {}

local EPSILON = 1e-9
local PRUNE_EVERY_CALLS = 128
local MIN_STALE_SECONDS = 60

function RateLimiter.new(intervalSeconds)
    assert(type(intervalSeconds) == "number" and intervalSeconds >= 0, "intervalSeconds must be non-negative")

    local lastByKey = {}
    local callsSincePrune = 0
    local staleSeconds = math.max(MIN_STALE_SECONDS, intervalSeconds * 4)

    return function(key, now)
        local timestamp = now or os.clock()
        local previous = lastByKey[key]

        if previous ~= nil then
            local elapsed = timestamp - previous
            if elapsed + EPSILON < intervalSeconds then
                return false
            end
        end

        lastByKey[key] = timestamp
        callsSincePrune += 1

        if callsSincePrune >= PRUNE_EVERY_CALLS then
            callsSincePrune = 0
            local cutoff = timestamp - staleSeconds
            for storedKey, lastTimestamp in pairs(lastByKey) do
                if lastTimestamp < cutoff then
                    lastByKey[storedKey] = nil
                end
            end
        end

        return true
    end
end

return RateLimiter
