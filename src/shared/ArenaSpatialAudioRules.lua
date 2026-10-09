local ArenaSpatialAudioRules = {}

ArenaSpatialAudioRules.Profiles = {
    Classic = {
        Bed = "Wind",
        Secondary = "LowGravity",
        Pitch = 0.62,
        SecondaryPitch = 0.54,
        Volume = 0.070,
        SecondaryVolume = 0.026,
        Radius = 48,
        EQ = {Low = -2.0, Mid = 0.5, High = 1.8},
        Reverb = {Wet = -30, Decay = 0.34, Density = 0.50, Diffusion = 0.72},
    },
    Towers = {
        Bed = "Wind",
        Secondary = "LowGravity",
        Pitch = 0.52,
        SecondaryPitch = 0.46,
        Volume = 0.084,
        SecondaryVolume = 0.032,
        Radius = 44,
        EQ = {Low = 2.0, Mid = -0.8, High = -1.6},
        Reverb = {Wet = -25, Decay = 0.62, Density = 0.78, Diffusion = 0.66},
    },
    Crossroads = {
        Bed = "Wind",
        Secondary = "LowGravity",
        Pitch = 0.78,
        SecondaryPitch = 0.64,
        Volume = 0.064,
        SecondaryVolume = 0.022,
        Radius = 51,
        EQ = {Low = -1.5, Mid = 1.4, High = 0.8},
        Reverb = {Wet = -29, Decay = 0.42, Density = 0.58, Diffusion = 0.82},
    },
    Orbital = {
        Bed = "LowGravity",
        Secondary = "Wind",
        Pitch = 0.58,
        SecondaryPitch = 0.68,
        Volume = 0.078,
        SecondaryVolume = 0.024,
        Radius = 46,
        EQ = {Low = 1.1, Mid = -1.2, High = 0.2},
        Reverb = {Wet = -23, Decay = 0.86, Density = 0.54, Diffusion = 0.92},
    },
}

function ArenaSpatialAudioRules.profile(id)
    return ArenaSpatialAudioRules.Profiles[tostring(id or "Classic")]
        or ArenaSpatialAudioRules.Profiles.Classic
end

function ArenaSpatialAudioRules.sourceCount(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 1
    elseif tier == "High" then
        return 3
    end
    return 2
end

function ArenaSpatialAudioRules.phaseScale(phase, overdrive, finalRush)
    local state = tostring(phase or "waiting")
    if state == "ready" then
        return 0.72
    elseif state == "round" then
        if finalRush == true then
            return 0.22
        elseif overdrive == true then
            return 0.38
        end
        return 0.58
    elseif state == "result" then
        return 0.46
    end
    return 0
end

-- Respect the same accessibility mute state as all other game audio buses.
function ArenaSpatialAudioRules.muteScale(muted)
    return muted == true and 0 or 1
end

function ArenaSpatialAudioRules.rolloff(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 12, 82
    elseif tier == "High" then
        return 10, 118
    end
    return 11, 98
end

return ArenaSpatialAudioRules
