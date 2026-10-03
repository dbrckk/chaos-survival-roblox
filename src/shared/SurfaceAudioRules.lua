local SurfaceAudioRules = {}

local DEFAULT = {
    Low = 0,
    Mid = 0,
    High = 0,
    Wet = -42,
    Decay = 0.12,
}

local PROFILES = {
    [Enum.Material.DiamondPlate] = {
        Low = -2.2,
        Mid = 2.4,
        High = 1.6,
        Wet = -31,
        Decay = 0.20,
    },
    [Enum.Material.Metal] = {
        Low = -0.8,
        Mid = 1.8,
        High = 0.8,
        Wet = -29,
        Decay = 0.24,
    },
    [Enum.Material.Slate] = {
        Low = 1.8,
        Mid = 0.4,
        High = -2.8,
        Wet = -36,
        Decay = 0.16,
    },
    [Enum.Material.SmoothPlastic] = {
        Low = -2.6,
        Mid = 0.2,
        High = 2.0,
        Wet = -40,
        Decay = 0.12,
    },
    [Enum.Material.Ice] = {
        Low = -4.0,
        Mid = -0.8,
        High = 3.6,
        Wet = -27,
        Decay = 0.32,
    },
    [Enum.Material.Concrete] = {
        Low = 1.2,
        Mid = 0.5,
        High = -1.8,
        Wet = -38,
        Decay = 0.14,
    },
}

function SurfaceAudioRules.profile(material)
    return PROFILES[material] or DEFAULT
end

return SurfaceAudioRules
