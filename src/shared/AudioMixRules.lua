--!strict
-- Shared, deterministic user audio preference policy. A nil volume means
-- 100% so pre-existing player data retains its current sound mix.
local AudioMixRules = {}

function AudioMixRules.percent(value)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        return 100
    end
    return math.floor(math.clamp(value, 0, 100) + 0.5)
end

function AudioMixRules.validServerVolume(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
        and value >= 0 and value <= 100
        and value == math.floor(value)
end

function AudioMixRules.gains(muted, musicVolume, effectsVolume)
    if muted == true then
        return 0, 0
    end
    return AudioMixRules.percent(musicVolume) / 100,
        AudioMixRules.percent(effectsVolume) / 100
end

return AudioMixRules
