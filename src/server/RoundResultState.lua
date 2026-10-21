-- A finished round is visible to players before any persistence, achievement,
-- or analytics write. Results are based solely on the frozen server roster.
-- This module never grants rewards or changes round participation.
local RoundResultState = {}

local function nonnegativeInt(value)
    local n = tonumber(value) or 0
    if n ~= n or n == math.huge or n == -math.huge then
        return 0
    end
    return math.max(0, math.floor(n))
end

function RoundResultState.snapshot(context)
    assert(type(context) == "table", "result context required")
    assert(type(context.participantUserIds) == "table", "participant roster required")
    assert(type(context.survivorUserIds) == "table", "survivor roster required")
    local survivors = #context.survivorUserIds
        + nonnegativeInt(context.aiSurvivorsAlive)
    -- Champion requires exactly one living contestant across humans and
    -- bots, and a competitive roster of at least two entrants.
    -- Never label a lone unopposed player or a survivor with living bots.
    local contestantCount = nonnegativeInt(context.contestantCount)
    local soleSurvivorUserId = nil
    if survivors == 1 and #context.survivorUserIds == 1
        and contestantCount >= 2
    then
        soleSurvivorUserId = context.survivorUserIds[1]
    end
    local title = survivors == 0 and "TOTAL WIPEOUT"
        or (tostring(survivors) .. " SURVIVED")

    return {
        phase = "result",
        roundNumber = context.roundNumber,
        title = title,
        hint = context.fusionName
            and (tostring(context.fusionName) .. " complete • Back to lobby, then vote")
            or "Returning to lobby • Vote and play again automatically",
        seconds = nonnegativeInt(context.seconds),
        doubleChaos = context.doubleChaos == true,
        fusionName = context.fusionName,
        soloMode = context.soloMode == true,
        arenaName = context.arenaName,
        arenaId = context.arenaId,
        disasterIds = context.disasterIds,
        survivorsAlive = survivors,
        contestantCount = contestantCount,
        soleSurvivorUserId = soleSurvivorUserId,
        -- Frozen identity lists, not the eventual success/failure of payouts.
        survivorUserIds = context.survivorUserIds,
        participantUserIds = context.participantUserIds,
    }
end

function RoundResultState.atSecond(snapshot, seconds)
    local packet = {}
    for key, value in pairs(snapshot) do
        packet[key] = value
    end
    packet.seconds = nonnegativeInt(seconds)
    return packet
end

return RoundResultState
