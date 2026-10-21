-- Protect the entire server round loop from a single participant's
-- unexpected progression/achievement/persistence error. Processing remains
-- sequential and server-owned; a failure is logged, not silently retried,
-- to avoid double-paying any partially completed reward transaction.
local RoundSettlement = {}

function RoundSettlement.eachPlayer(players, process, onError)
    local succeeded = 0
    local failed = 0
    for _, player in ipairs(players or {}) do
        local ok, err = pcall(process, player)
        if ok then
            succeeded += 1
        else
            failed += 1
            if type(onError) == "function" then
                -- Failure reporting must not itself stop the next round.
                pcall(onError, player, tostring(err))
            end
        end
    end
    return succeeded, failed
end

return RoundSettlement
