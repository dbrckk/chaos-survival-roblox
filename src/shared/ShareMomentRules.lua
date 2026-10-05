local ShareMomentRules = {}

local REASON_KEYS = {
    last_survivor = "SHARE_REASON_LAST_SURVIVOR",
    master = "SHARE_REASON_MASTER",
    double_chaos = "SHARE_REASON_DOUBLE_CHAOS",
    clutch = "SHARE_REASON_CLUTCH",
    crew = "SHARE_REASON_CREW",
}

local VALID_REASONS = {}
for reason in pairs(REASON_KEYS) do
    VALID_REASONS[reason] = true
end

function ShareMomentRules.reason(feedback, state)
    feedback = type(feedback) == "table" and feedback or {}
    state = type(state) == "table" and state or {}

    if tostring(state.phase or "") ~= "result" or feedback.survived ~= true then
        return nil
    end

    local survivors = math.max(0, math.floor(tonumber(state.survivorsAlive) or 0))
    if survivors == 1 then
        return "last_survivor"
    end

    local momentumBest = math.max(0, math.floor(tonumber(feedback.momentumBest) or 0))
    local master = feedback.challengeCompleted == true and momentumBest >= 4
    if master then
        return "master"
    end

    if feedback.doubleChaos == true then
        return "double_chaos"
    end

    if feedback.criticalSurvival == true then
        return "clutch"
    end

    local crewRounds = math.max(0, math.floor(tonumber(feedback.crewRounds) or 0))
    if crewRounds >= 3 then
        return "crew"
    end

    return nil
end

function ShareMomentRules.shouldShow(feedback, state, games)
    return math.max(0, math.floor(tonumber(games) or 0)) >= 1
        and ShareMomentRules.reason(feedback, state) ~= nil
end

function ShareMomentRules.reasonKey(reason)
    return REASON_KEYS[tostring(reason or "")]
end

function ShareMomentRules.validReason(reason)
    return VALID_REASONS[tostring(reason or "")] == true
end

function ShareMomentRules.launchReason(reason)
    local value = tostring(reason or "")
    return ShareMomentRules.validReason(value) and value or "highlight"
end

return ShareMomentRules
