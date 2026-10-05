local SocialExperienceRules = {}

local REACTION_KEYS = {
    gg = "SOCIAL_REACTION_GG",
    again = "SOCIAL_REACTION_AGAIN",
    wow = "SOCIAL_REACTION_WOW",
}

function SocialExperienceRules.shouldShow(phase, voteOptions, games, dataLoaded)
    if dataLoaded ~= true or math.max(0, math.floor(tonumber(games) or 0)) < 1 then
        return false
    end

    local current = tostring(phase or "waiting")
    if current == "result" then
        return true
    end

    return current == "intermission"
        and not (type(voteOptions) == "table" and #voteOptions > 0)
end

function SocialExperienceRules.intent(lastSurvived)
    return lastSurvived == false and "comeback" or "celebrate"
end

function SocialExperienceRules.buttonKey(lastSurvived)
    return SocialExperienceRules.intent(lastSurvived) == "comeback"
        and "BRING_BACKUP"
        or "INVITE_FRIENDS"
end

function SocialExperienceRules.promptKey(lastSurvived)
    return SocialExperienceRules.intent(lastSurvived) == "comeback"
        and "INVITE_PROMPT_LOSS"
        or "INVITE_PROMPT_WIN"
end

function SocialExperienceRules.inviterUserId(payload, joiningUserId)
    if type(payload) ~= "table" or payload.source ~= "chaos_crew" then
        return nil
    end

    local inviter = tonumber(payload.inviter)
    local joining = tonumber(joiningUserId)
    if not inviter or inviter <= 0 or inviter % 1 ~= 0 then
        return nil
    end
    inviter = math.floor(inviter)

    if joining and inviter == joining then
        return nil
    end
    return inviter
end

function SocialExperienceRules.reactionKey(reactionId)
    return REACTION_KEYS[tostring(reactionId or "")]
end

function SocialExperienceRules.canReact(phase, humanPlayers, games)
    return tostring(phase or "") == "result"
        and math.max(0, math.floor(tonumber(humanPlayers) or 0)) >= 2
        and math.max(0, math.floor(tonumber(games) or 0)) >= 1
end

function SocialExperienceRules.beaconEmphasis(phase)
    local current = tostring(phase or "waiting")
    if current == "result" then
        return 1
    elseif current == "intermission" then
        return 0.72
    elseif current == "waiting" then
        return 0.45
    end
    return 0
end

return SocialExperienceRules
