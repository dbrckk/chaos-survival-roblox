local AttentionBudgetRules = {}

function AttentionBudgetRules.voteActive(phase, voteOptions)
    return tostring(phase or "") == "intermission"
        and type(voteOptions) == "table"
        and #voteOptions > 0
end

function AttentionBudgetRules.canShowMetaNotification(phase, voteOptions, games)
    local current = tostring(phase or "waiting")
    local completedGames = math.max(0, math.floor(tonumber(games) or 0))

    return completedGames > 0
        and current == "intermission"
        and not AttentionBudgetRules.voteActive(current, voteOptions)
end

function AttentionBudgetRules.suppressMetaControls(phase, voteOptions, games)
    local current = tostring(phase or "waiting")
    local completedGames = math.max(0, math.floor(tonumber(games) or 0))

    if completedGames <= 0 then
        return true
    end

    if current == "ready"
        or current == "round"
        or current == "result"
    then
        return true
    end

    return AttentionBudgetRules.voteActive(current, voteOptions)
end

return AttentionBudgetRules
