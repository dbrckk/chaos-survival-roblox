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
