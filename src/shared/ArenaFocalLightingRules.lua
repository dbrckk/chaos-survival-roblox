local ArenaFocalLightingRules = {}

ArenaFocalLightingRules.Definitions = {
    Classic = {
        {Offset = Vector3.new(0, 15, -1.15), Role = "Accent", Range = 54, Angle = 58},
        {Offset = Vector3.new(-0.92, 9, 0.25), Role = "Secondary", Range = 44, Angle = 50},
        {Offset = Vector3.new(0.78, 11, 0.78), Role = "Accent", Range = 42, Angle = 48},
    },
    Towers = {
        {Offset = Vector3.new(1.18, 24, 0.0), Role = "Accent", Range = 58, Angle = 46},
        {Offset = Vector3.new(-0.82, 18, 0.74), Role = "Secondary", Range = 48, Angle = 42},
        {Offset = Vector3.new(0.34, 28, -0.92), Role = "Detail", Range = 52, Angle = 44},
    },
    Crossroads = {
        {Offset = Vector3.new(0, 12, 1.18), Role = "Accent", Range = 56, Angle = 62},
        {Offset = Vector3.new(-1.10, 8, -0.18), Role = "Secondary", Range = 50, Angle = 56},
        {Offset = Vector3.new(0.92, 9, -0.72), Role = "Detail", Range = 46, Angle = 52},
    },
    Orbital = {
        {Offset = Vector3.new(-1.18, 14, 0), Role = "Accent", Range = 54, Angle = 56},
        {Offset = Vector3.new(0.62, 16, -0.92), Role = "Secondary", Range = 48, Angle = 48},
        {Offset = Vector3.new(0.82, 11, 0.74), Role = "Accent", Range = 46, Angle = 50},
    },
}

function ArenaFocalLightingRules.sourceCount(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 0
    elseif tier == "High" then
        return 3
    end
    return 2
end

function ArenaFocalLightingRules.phaseScale(phase, finalRush)
    local state = tostring(phase or "waiting")
    if state == "ready" then
        return 0.82
    elseif state == "round" then
        return finalRush == true and 0.08 or 0.30
    elseif state == "result" then
        return 0.48
    end
    return 0
end

function ArenaFocalLightingRules.definitions(variant)
    return ArenaFocalLightingRules.Definitions[tostring(variant or "Classic")]
        or ArenaFocalLightingRules.Definitions.Classic
end

return ArenaFocalLightingRules
