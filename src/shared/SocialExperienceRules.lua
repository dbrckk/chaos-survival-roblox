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

function SocialExperienceRules.shareSourceUserId(payload, joiningUserId)
    if type(payload) ~= "table" or payload.source ~= "chaos_share" then
        return nil
    end

    local sharer = tonumber(payload.sharer)
    local joining = tonumber(joiningUserId)
    if not sharer or sharer <= 0 or sharer % 1 ~= 0 then
        return nil
    end
    sharer = math.floor(sharer)

    if joining and sharer == joining then
        return nil
    end
    return sharer
end

function SocialExperienceRules.shareReason(payload)
    if type(payload) ~= "table" or payload.source ~= "chaos_share" then
        return nil
    end

    local reason = tostring(payload.reason or "")
    local allowed = {
        last_survivor = true,
        master = true,
        double_chaos = true,
        clutch = true,
        crew = true,
        highlight = true,
    }
    return allowed[reason] and reason or "highlight"
end

function SocialExperienceRules.crewParticipantIds(entries)
    local present = {}
    local linked = {}

    for _, entry in ipairs(type(entries) == "table" and entries or {}) do
        local userId = math.floor(tonumber(entry.userId) or 0)
        if userId > 0 then
            present[userId] = true
        end
    end

    for _, entry in ipairs(type(entries) == "table" and entries or {}) do
        local userId = math.floor(tonumber(entry.userId) or 0)
        local inviterId = math.floor(tonumber(entry.inviterUserId) or 0)
        if userId > 0
            and inviterId > 0
            and userId ~= inviterId
            and present[inviterId]
        then
            linked[userId] = true
            linked[inviterId] = true
        end
    end

    local result = {}
    for userId in pairs(linked) do
        table.insert(result, userId)
    end
    table.sort(result)
    return result
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
