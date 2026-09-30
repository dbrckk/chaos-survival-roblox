local RateLimiter = {}

local EPSILON = 1e-9

function RateLimiter.new(intervalSeconds)
    assert(type(intervalSeconds) == "number" and intervalSeconds >= 0, "intervalSeconds must be non-negative")

    local lastByKey = {}

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
        return true
    end
end

return RateLimiter
