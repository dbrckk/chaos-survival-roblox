local ChaosFusion = {}

ChaosFusion.SurvivalBonusCoins = 5

local LABELS = {
    RisingLava = "LAVA",
    Meteors = "METEORS",
    LowGravity = "MOON",
    DisappearingPlatforms = "PHASE",
    Tornado = "TORNADO",
    Freeze = "FREEZE",
    Bombs = "BOMBS",
    SpeedSurge = "SPEED",
    Darkness = "BLACKOUT",
    ShrinkingArena = "SHRINK",
    JumpShock = "SHOCK",
}

local SPECIAL = {
    ["Bombs|RisingLava"] = "INFERNO BARRAGE",
    ["Meteors|RisingLava"] = "APOCALYPSE RAIN",
    ["Meteors|Tornado"] = "STORMFALL",
    ["SpeedSurge|Tornado"] = "HYPERSTORM",
    ["Darkness|Freeze"] = "VOIDFROST",
    ["JumpShock|LowGravity"] = "ZERO-G SHOCK",
    ["DisappearingPlatforms|ShrinkingArena"] = "TOTAL COLLAPSE",
    ["Darkness|Meteors"] = "NIGHTFALL IMPACT",
    ["Bombs|SpeedSurge"] = "BLITZ MODE",
}

local function key(a, b)
    local left = tostring(a or "")
    local right = tostring(b or "")
    if left > right then
        left, right = right, left
    end
    return left .. "|" .. right
end

function ChaosFusion.name(a, b)
    local special = SPECIAL[key(a, b)]
    if special then
        return special
    end

    local left = LABELS[a] or tostring(a or "CHAOS")
    local right = LABELS[b] or tostring(b or "CHAOS")
    return left .. " × " .. right
end

function ChaosFusion.bonusCoins()
    return ChaosFusion.SurvivalBonusCoins
end

return ChaosFusion
