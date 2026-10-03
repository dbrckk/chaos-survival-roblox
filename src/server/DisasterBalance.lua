local DisasterBalance = {}

DisasterBalance.IncompatiblePairs = {
    Freeze = {
        SpeedSurge = true,
        Tornado = true,
        JumpShock = true,
        Meteors = true,
        Bombs = true,
        RisingLava = true,
        DisappearingPlatforms = true,
        ShrinkingArena = true,
    },
    SpeedSurge = {
        Freeze = true,
        DisappearingPlatforms = true,
    },
    Tornado = {
        Freeze = true,
        JumpShock = true,
    },
    JumpShock = {
        Freeze = true,
        Tornado = true,
        ShrinkingArena = true,
    },
    DisappearingPlatforms = {
        SpeedSurge = true,
        Freeze = true,
    },
    Meteors = {
        Freeze = true,
    },
    Bombs = {
        Freeze = true,
    },
    RisingLava = {
        Freeze = true,
    },
    ShrinkingArena = {
        Freeze = true,
        JumpShock = true,
    },
}

function DisasterBalance.compatible(aId, bId)
    if aId == bId then
        return false
    end

    local a = DisasterBalance.IncompatiblePairs[aId]
    local b = DisasterBalance.IncompatiblePairs[bId]

    return not ((a and a[bId]) or (b and b[aId]))
end

function DisasterBalance.filterCompatible(primaryId, disasters)
    local result = {}
    for _, disaster in ipairs(disasters) do
        if disaster.Id ~= primaryId and DisasterBalance.compatible(primaryId, disaster.Id) then
            table.insert(result, disaster)
        end
    end
    return result
end

function DisasterBalance.mobileProfile(playerCount)
    local count = math.max(1, tonumber(playerCount) or 1)
    return {
        MeteorWarningSeconds = count <= 2 and 1.05 or 0.9,
        MeteorDamage = count <= 2 and 45 or 50,
        MeteorRadius = 8,
        BombWarningSeconds = count <= 2 and 1.45 or 1.25,
        BombDamage = count <= 2 and 42 or 48,
        BombRadius = 8,
        FreezeSeconds = count <= 2 and 0.9 or 1.1,
        TornadoForce = count <= 2 and 14 or 17,
        SpeedMultiplier = count <= 2 and 1.4 or 1.5,
        JumpHorizontalForce = count <= 2 and 6 or 8,
    }
end

return DisasterBalance
