local ResultPresentation = {}

function ResultPresentation.kind(feedback)
    feedback = type(feedback) == "table" and feedback or {}

    local survived = feedback.survived == true
    local momentumBest = math.max(0, math.floor(tonumber(feedback.momentumBest) or 0))
    local master = survived
        and feedback.challengeCompleted == true
        and momentumBest >= 4

    if master then
        return "master"
    elseif survived and feedback.criticalSurvival == true then
        return "clutch"
    elseif survived then
        return "survived"
    end
    return "eliminated"
end

function ResultPresentation.title(feedback)
    local kind = ResultPresentation.kind(feedback)
    if kind == "master" then
        return "MASTER ROUND!"
    elseif kind == "clutch" then
        return "CLUTCH SURVIVAL!"
    elseif kind == "survived" then
        return "SURVIVED!"
    end
    return "ELIMINATED"
end

function ResultPresentation.worldLabel(feedback, isLocal)
    local kind = ResultPresentation.kind(feedback)

    if kind == "master" then
        return isLocal and "MASTER ROUND" or "MASTER SURVIVOR"
    elseif kind == "clutch" then
        return isLocal and "CLUTCH SURVIVAL" or "SURVIVOR"
    elseif kind == "survived" then
        return isLocal and "YOU SURVIVED" or "SURVIVOR"
    end

    return isLocal and "ELIMINATED" or nil
end

function ResultPresentation.intensity(feedback)
    local kind = ResultPresentation.kind(feedback)
    if kind == "master" then
        return 1
    elseif kind == "clutch" then
        return 0.86
    elseif kind == "survived" then
        return 0.72
    end
    return 0.48
end

return ResultPresentation
