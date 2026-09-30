local RateLimiter = {}

function RateLimiter.new(intervalSeconds)
    assert(type(intervalSeconds) == "number" and intervalSeconds >= 0, "intervalSeconds must be non-negative")

    local lastByKey = {}

    return function(key, now)
        local timestamp = now or os.clock()
        local previous = lastByKey[key]

        if previous ~= nil and timestamp - previous < intervalSeconds then
            return false
        end

        lastByKey[key] = timestamp
        return true
    end
end

return RateLimiter
