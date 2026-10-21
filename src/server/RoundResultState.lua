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
    local title = survivors == 0 and "TOTAL WIPEOUT"
        or (tostring(survivors) .. " SURVIVED")

    return {
        phase = "result",
        roundNumber = context.roundNumber,
        title = title,
        hint = context.fusionName
            and (tostring(context.fusionName) .. " complete • Next round soon")
            or "Next round soon",
        seconds = nonnegativeInt(context.seconds),
        doubleChaos = context.doubleChaos == true,
        fusionName = context.fusionName,
        soloMode = context.soloMode == true,
        arenaName = context.arenaName,
        arenaId = context.arenaId,
        disasterIds = context.disasterIds,
        survivorsAlive = survivors,
        contestantCount = nonnegativeInt(context.contestantCount),
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
