local VisualBudgetRules = {}

VisualBudgetRules.Budgets = {
    High = {
        Parts = 900,
        Lights = 64,
        Effects = 110,
    },
    Medium = {
        Parts = 680,
        Lights = 48,
        Effects = 82,
    },
    Low = {
        Parts = 440,
        Lights = 32,
        Effects = 56,
    },
}

function VisualBudgetRules.forTier(tierName)
    return VisualBudgetRules.Budgets[tierName] or VisualBudgetRules.Budgets.High
end

function VisualBudgetRules.withinBudget(tierName, metrics)
    local budget = VisualBudgetRules.forTier(tierName)
    local values = metrics or {}

    return (tonumber(values.Parts) or 0) <= budget.Parts
        and (tonumber(values.Lights) or 0) <= budget.Lights
        and (tonumber(values.Effects) or 0) <= budget.Effects
end

function VisualBudgetRules.overages(tierName, metrics)
    local budget = VisualBudgetRules.forTier(tierName)
    local values = metrics or {}
    local result = {}

    for _, key in ipairs({"Parts", "Lights", "Effects"}) do
        local count = tonumber(values[key]) or 0
        local limit = budget[key]
        if count > limit then
            result[key] = count - limit
        end
    end

    return result
end

return VisualBudgetRules
