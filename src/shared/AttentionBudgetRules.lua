-- Pure rules are loaded by Lest without a ModuleScript 'script' global.
-- Keep the ballot guard dependency-free; parity is asserted by core_b1 specs.
local function validVoteOptions(options)
    if type(options) ~= "table" or #options < 1 or #options > 3 then
        return false
    end
    local seen = {}
    for index = 1, #options do
        local option = options[index]
        if type(option) ~= "table"
            or type(option.id) ~= "string" or option.id == ""
            or seen[option.id] then
            return false
        end
        seen[option.id] = true
    end
    return true
end

local AttentionBudgetRules = {}

function AttentionBudgetRules.voteActive(phase, voteOptions)
    return tostring(phase or "") == "intermission"
        and validVoteOptions(voteOptions)
end

function AttentionBudgetRules.canShowMetaNotification(phase, voteOptions, games)
    local current = tostring(phase or "waiting")
    local completedGames = math.max(0, math.floor(tonumber(games) or 0))

    return completedGames > 0
        and current == "intermission"
        and not AttentionBudgetRules.voteActive(current, voteOptions)
end

function AttentionBudgetRules.enqueueBounded(queue, item, limit)
    local target = queue or {}
    if item == nil then
        return target
    end

    local maxItems = math.max(1, math.floor(tonumber(limit) or 8))
    target[#target + 1] = item
    while #target > maxItems do
        table.remove(target, 1)
    end
    return target
end

function AttentionBudgetRules.popFirst(queue)
    if type(queue) ~= "table" or #queue == 0 then
        return nil
    end
    return table.remove(queue, 1)
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
