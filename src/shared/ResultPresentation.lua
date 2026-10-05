local ResultPresentation = {}

local ELIMINATION_COPY = {
    Meteor = {
        title = "HIT BY METEOR",
        tip = "Move as soon as the orange warning circle appears",
    },
    Bomb = {
        title = "CAUGHT IN BOMB BLAST",
        tip = "Leave red markers before they detonate",
    },
    Lava = {
        title = "CAUGHT BY LAVA",
        tip = "Climb early and keep gaining height",
    },
    Tornado = {
        title = "THROWN BY TORNADO",
        tip = "Keep more distance from the tornado",
    },
    JumpShock = {
        title = "KNOCKED OFF BY SHOCKWAVE",
        tip = "Give the blue shockwave extra space",
    },
    LowGravity = {
        title = "DRIFTED OFF THE ARENA",
        tip = "Use short jumps and steer back toward the center",
    },
    DisappearingPlatforms = {
        title = "PLATFORM COLLAPSED",
        tip = "Leave flashing platforms before they disappear",
    },
    ShrinkingArena = {
        title = "CAUGHT BY THE SHRINK",
        tip = "Move toward the center before the boundary closes",
    },
    Fall = {
        title = "FELL FROM THE ARENA",
        tip = "Use shorter jumps and recover toward the center",
    },
}

function ResultPresentation.eliminationCopy(feedback)
    feedback = type(feedback) == "table" and feedback or {}
    local copy = ELIMINATION_COPY[tostring(feedback.eliminationCause or "")]
    if copy then
        return copy.title, copy.tip
    end
    return "ELIMINATED", "React early to the hazard warning and keep a safe route"
end

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
    local title = ResultPresentation.eliminationCopy(feedback)
    return title
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
