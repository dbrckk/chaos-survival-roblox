-- Protect the entire server round loop from a single participant's
-- unexpected progression/achievement/persistence error. Processing remains
-- sequential and server-owned; a failure is logged, not silently retried,
-- to avoid double-paying any partially completed reward transaction.
local RoundSettlement = {}

-- Freeze each real participant's outcome BEFORE attempting Coins, XP,
-- quests, mastery, analytics or achievements. A failure in any of those
-- independent systems must not erase an actual survivor from the RESULT
-- roster or make later players see a contradictory winner count.
-- Eligibility/liveness are supplied by the authoritative round server.
function RoundSettlement.snapshot(players, eliminated, eligible, alive)
    local participantUserIds = {}
    local survivorUserIds = {}
    local survivedById = {}
    local seen = {}
    for _, player in ipairs(players or {}) do
        local id = type(player) == "table" and tonumber(player.UserId)
            or (typeof(player) == "Instance" and tonumber(player.UserId) or nil)
        if id and id > 0 and id == math.floor(id)
            and not seen[id] and eligible(player)
        then
            seen[id] = true
            participantUserIds[#participantUserIds + 1] = id
            if (not eliminated or eliminated[id] ~= true) and alive(player) then
                survivedById[id] = true
                survivorUserIds[#survivorUserIds + 1] = id
            end
        end
    end
    return participantUserIds, survivorUserIds, survivedById
end

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
