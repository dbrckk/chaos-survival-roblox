local FlowCombo = {}

FlowCombo.WindowSeconds = 5
FlowCombo.BonusCoins = 2

function FlowCombo.qualifies(lastMechanicAt, now, alreadyClaimed)
    if alreadyClaimed == true then
        return false
    end

    local lastAt = tonumber(lastMechanicAt)
    local current = tonumber(now)
    if not lastAt or not current or lastAt <= 0 or current < lastAt then
        return false
    end

    return (current - lastAt) <= FlowCombo.WindowSeconds
end

return FlowCombo
