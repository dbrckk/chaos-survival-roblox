local DisasterResidue = {}

DisasterResidue.Profiles = {
    RisingLava = {Kind="char", Color=Color3.fromRGB(95,42,24), Material=Enum.Material.Slate},
    Meteors = {Kind="crater", Color=Color3.fromRGB(82,48,34), Material=Enum.Material.Slate},
    LowGravity = {Kind="dust", Color=Color3.fromRGB(118,126,162), Material=Enum.Material.SmoothPlastic},
    DisappearingPlatforms = {Kind="fracture", Color=Color3.fromRGB(116,92,38), Material=Enum.Material.Metal},
    Tornado = {Kind="scrape", Color=Color3.fromRGB(96,112,116), Material=Enum.Material.Metal},
    Freeze = {Kind="frost", Color=Color3.fromRGB(185,228,245), Material=Enum.Material.Ice},
    Bombs = {Kind="scorch", Color=Color3.fromRGB(62,46,48), Material=Enum.Material.Slate},
    SpeedSurge = {Kind="streak", Color=Color3.fromRGB(116,62,116), Material=Enum.Material.SmoothPlastic},
    Darkness = {Kind="void", Color=Color3.fromRGB(58,54,82), Material=Enum.Material.SmoothPlastic},
    ShrinkingArena = {Kind="edge", Color=Color3.fromRGB(105,64,118), Material=Enum.Material.Metal},
    JumpShock = {Kind="shock", Color=Color3.fromRGB(88,112,145), Material=Enum.Material.SmoothPlastic},
}

-- Quiet aging palettes: nine different physical residues settle instead of
-- all remaining at a constant color before abruptly fading.
local SETTLED = {
    RisingLava = Color3.fromRGB(53, 46, 45),
    LowGravity = Color3.fromRGB(66, 73, 104),
    DisappearingPlatforms = Color3.fromRGB(65, 57, 48),
    Tornado = Color3.fromRGB(63, 74, 79),
    Freeze = Color3.fromRGB(115, 141, 157),
    SpeedSurge = Color3.fromRGB(76, 52, 80),
    Darkness = Color3.fromRGB(37, 40, 55),
    ShrinkingArena = Color3.fromRGB(72, 49, 84),
    JumpShock = Color3.fromRGB(63, 80, 103),
}

function DisasterResidue.settlement(id, tierName, reduceMotion, startingColor, lifetime)
    local settled = SETTLED[id]
    if not settled or (tierName ~= "Medium" and tierName ~= "High")
        or reduceMotion == true or typeof(startingColor) ~= "Color3"
    then
        return nil
    end
    local duration = math.max(0.2, tonumber(lifetime) or 0)
    -- Begin early enough to finish long before the existing final fade.
    local delay = duration * 0.34
    local tweenTime = math.min(0.8, duration * 0.19)
    return {
        Color = startingColor:Lerp(settled, tierName == "High" and 0.68 or 0.49),
        StartAfter = delay,
        Duration = tweenTime,
        Transparency = tierName == "High" and 0.30 or 0.40,
    }
end

function DisasterResidue.get(id)
    return DisasterResidue.Profiles[id]
end

function DisasterResidue.resultBudget(tierName)
    if tierName == "Low" then
        return 3
    elseif tierName == "Medium" then
        return 5
    end
    return 7
end

function DisasterResidue.impactLifetime(tierName)
    if tierName == "Low" then
        return 2.4
    elseif tierName == "Medium" then
        return 4.0
    end
    return 5.5
end

return DisasterResidue
