-- Deterministic trace for the complete visible round flow.
local RoundJourneyRules = {}
function RoundJourneyRules.advance(progress, phase)
    local stage = math.clamp(math.floor(tonumber(progress) or 0), 0, 4)
    local current = tostring(phase or "")
    if current == "waiting" then
        return 0, false
    elseif current == "intermission" then
        return 1, false
    elseif current == "ready" then
        return (stage == 1 or stage == 2) and 2 or 0, false
    elseif current == "round" then
        return (stage == 2 or stage == 3) and 3 or 0, false
    elseif current == "result" then
        if stage == 3 then return 4, true end
        return stage == 4 and 4 or 0, false
    end
    return stage, false
end
-- RESULT must lead to a later, server-numbered READY. This additional
-- contract is intentionally separate from the four-stage intro journey:
-- a pretty victory card is not proof the server actually starts a new game.
function RoundJourneyRules.replayStarted(lastFinishedRound, nextState)
    if type(nextState) ~= "table" or nextState.phase ~= "ready" then
        return false
    end
    local finished = tonumber(lastFinishedRound)
    local nextId = tonumber(nextState.roundNumber)
    return finished ~= nil and nextId ~= nil
        and finished == finished and nextId == nextId
        and finished > 0 and nextId == finished + 1
end

return RoundJourneyRules
