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

-- Do not keep references to live settlement arrays. The broadcast state,
-- per-second result packets, and lobby recap must remain a consistent,
-- server-confirmed record even when later systems reuse/mutate their lists.
local function copyList(values)
    if type(values) ~= "table" then return values end
    local copy = {}
    for index, entry in ipairs(values) do
        copy[index] = entry
    end
    return copy
end

function RoundResultState.snapshot(context)
    assert(type(context) == "table", "result context required")
    assert(type(context.participantUserIds) == "table", "participant roster required")
    assert(type(context.survivorUserIds) == "table", "survivor roster required")
    local participantUserIds = copyList(context.participantUserIds)
    local survivorUserIds = copyList(context.survivorUserIds)
    local disasterIds = copyList(context.disasterIds)
    local survivors = #survivorUserIds
        + nonnegativeInt(context.aiSurvivorsAlive)
    -- Champion requires exactly one living contestant across humans and
    -- bots, and a competitive roster of at least two entrants.
    -- Never label a lone unopposed player or a survivor with living bots.
    local contestantCount = nonnegativeInt(context.contestantCount)
    local soleSurvivorUserId = nil
    local soleSurvivorAISlot = nil
    if survivors == 1 and contestantCount >= 2 then
        if #survivorUserIds == 1 then
            soleSurvivorUserId = survivorUserIds[1]
        elseif nonnegativeInt(context.aiSurvivorsAlive) == 1 then
            local aiSlot = nonnegativeInt(context.soleAliveAISlot)
            -- AI slots are currently 1-3. A failed/missing bot snapshot
            -- never fabricates a champion identity.
            if aiSlot >= 1 and aiSlot <= 3 then
                soleSurvivorAISlot = aiSlot
            end
        end
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
        disasterIds = disasterIds,
        survivorsAlive = survivors,
        contestantCount = contestantCount,
        soleSurvivorUserId = soleSurvivorUserId,
        soleSurvivorAISlot = soleSurvivorAISlot,
        -- Frozen identity lists, not the eventual success/failure of payouts.
        survivorUserIds = survivorUserIds,
        participantUserIds = participantUserIds,
    }
end

function RoundResultState.atSecond(snapshot, seconds)
    local packet = {}
    for key, value in pairs(snapshot) do
        packet[key] = value
    end
    -- Preserve the authoritative recap while keeping every outgoing
    -- countdown packet isolated from accidental consumer mutations.
    packet.participantUserIds = copyList(snapshot.participantUserIds)
    packet.survivorUserIds = copyList(snapshot.survivorUserIds)
    packet.disasterIds = copyList(snapshot.disasterIds)
    packet.seconds = nonnegativeInt(seconds)
    return packet
end

return RoundResultState
