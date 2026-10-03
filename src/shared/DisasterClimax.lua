local DisasterClimax = {}

DisasterClimax.StageThresholds = {
    Surge = 0.98,
    Critical = 1.06,
}

DisasterClimax.Profiles = {
    RisingLava = {Kind="lava", Color=Color3.fromRGB(255,85,20), Secondary=Color3.fromRGB(255,215,75)},
    Meteors = {Kind="meteor", Color=Color3.fromRGB(255,120,45), Secondary=Color3.fromRGB(255,225,130)},
    LowGravity = {Kind="gravity", Color=Color3.fromRGB(105,130,255), Secondary=Color3.fromRGB(210,225,255)},
    DisappearingPlatforms = {Kind="fracture", Color=Color3.fromRGB(255,205,65), Secondary=Color3.fromRGB(255,240,150)},
    Tornado = {Kind="tornado", Color=Color3.fromRGB(75,205,215), Secondary=Color3.fromRGB(190,245,245)},
    Freeze = {Kind="freeze", Color=Color3.fromRGB(80,190,255), Secondary=Color3.fromRGB(205,245,255)},
    Bombs = {Kind="bomb", Color=Color3.fromRGB(255,60,60), Secondary=Color3.fromRGB(255,155,95)},
    SpeedSurge = {Kind="speed", Color=Color3.fromRGB(245,80,205), Secondary=Color3.fromRGB(255,195,245)},
    Darkness = {Kind="darkness", Color=Color3.fromRGB(100,90,205), Secondary=Color3.fromRGB(195,180,255)},
    ShrinkingArena = {Kind="shrink", Color=Color3.fromRGB(185,75,240), Secondary=Color3.fromRGB(245,175,255)},
    JumpShock = {Kind="shock", Color=Color3.fromRGB(80,155,255), Secondary=Color3.fromRGB(190,225,255)},
}

function DisasterClimax.stageFor(intensity, finalRush, overdrive)
    if finalRush == true then
        return 3
    end

    local value = tonumber(intensity) or 0
    if overdrive == true then
        return math.max(
            2,
            value >= DisasterClimax.StageThresholds.Critical and 2 or 1
        )
    end

    if value >= DisasterClimax.StageThresholds.Critical then
        return 2
    elseif value >= DisasterClimax.StageThresholds.Surge then
        return 1
    end
    return 0
end

function DisasterClimax.get(id)
    return DisasterClimax.Profiles[id]
end

return DisasterClimax
