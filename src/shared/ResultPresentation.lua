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

local ELIMINATION_COPY_FR = {
    Meteor = {
        title = "FRAPPÉ PAR UN MÉTÉORE",
        tip = "Bouge dès que le cercle d'alerte orange apparaît",
    },
    Bomb = {
        title = "PRIS DANS UNE EXPLOSION",
        tip = "Quitte les zones rouges avant l'explosion",
    },
    Lava = {
        title = "RATTRAPÉ PAR LA LAVE",
        tip = "Monte tôt et continue à prendre de la hauteur",
    },
    Tornado = {
        title = "PROJETÉ PAR LA TORNADE",
        tip = "Garde davantage de distance avec la tornade",
    },
    JumpShock = {
        title = "ÉJECTÉ PAR L'ONDE DE CHOC",
        tip = "Laisse plus d'espace autour de l'onde bleue",
    },
    LowGravity = {
        title = "SORTI DE L'ARÈNE",
        tip = "Fais de petits sauts et reviens vers le centre",
    },
    DisappearingPlatforms = {
        title = "PLATEFORME EFFONDRÉE",
        tip = "Quitte les plateformes qui clignotent avant leur disparition",
    },
    ShrinkingArena = {
        title = "RATTRAPÉ PAR L'ARÈNE",
        tip = "Rejoins le centre avant que la limite se referme",
    },
    Fall = {
        title = "TOMBÉ DE L'ARÈNE",
        tip = "Fais des sauts plus courts et reviens vers le centre",
    },
}

local function french(localeId)
    return string.sub(string.lower(tostring(localeId or "")), 1, 2) == "fr"
end

function ResultPresentation.feedbackEliminationCause(survived, cause)
    if survived == true then
        return nil
    end

    local normalized = tostring(cause or "Unknown")
    if normalized == "" then
        return "Unknown"
    end
    return normalized
end

function ResultPresentation.eliminationCopy(feedback, localeId)
    feedback = type(feedback) == "table" and feedback or {}
    local source = french(localeId) and ELIMINATION_COPY_FR or ELIMINATION_COPY
    local copy = source[tostring(feedback.eliminationCause or "")]
    if copy then
        return copy.title, copy.tip
    end

    if french(localeId) then
        return "ÉLIMINÉ", "Réagis tôt à l'alerte du danger et garde une route sûre"
    end
    return "ELIMINATED", "React early to the hazard warning and keep a safe route"
end

local ELIMINATION_TO_DISASTER = {
    Meteor = "Meteors",
    Bomb = "Bombs",
    Lava = "RisingLava",
    Tornado = "Tornado",
    JumpShock = "JumpShock",
    LowGravity = "LowGravity",
    DisappearingPlatforms = "DisappearingPlatforms",
    ShrinkingArena = "ShrinkingArena",
}

function ResultPresentation.visualHazardOrder(feedback)
    feedback = type(feedback) == "table" and feedback or {}
    local ids = type(feedback.disasterIds) == "table" and feedback.disasterIds or {}

    local primary = ids[1]
    local secondary = ids[2]

    if feedback.survived ~= true and secondary then
        local causedBy = ELIMINATION_TO_DISASTER[tostring(feedback.eliminationCause or "")]
        if causedBy and causedBy == secondary then
            primary, secondary = secondary, primary
        end
    end

    return primary, secondary
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

function ResultPresentation.title(feedback, localeId)
    local kind = ResultPresentation.kind(feedback)
    if french(localeId) then
        if kind == "master" then
            return "MANCHE MAÎTRISÉE !"
        elseif kind == "clutch" then
            return "SURVIE EXTRÊME !"
        elseif kind == "survived" then
            return "SURVÉCU !"
        end
    else
        if kind == "master" then
            return "MASTER ROUND!"
        elseif kind == "clutch" then
            return "CLUTCH SURVIVAL!"
        elseif kind == "survived" then
            return "SURVIVED!"
        end
    end

    local title = ResultPresentation.eliminationCopy(feedback, localeId)
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

function ResultPresentation.constellationBudget(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 3
    elseif tier == "High" then
        return 8
    end
    return 6
end

function ResultPresentation.constellationRadius(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 10
    elseif tier == "High" then
        return 16
    end
    return 13
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
