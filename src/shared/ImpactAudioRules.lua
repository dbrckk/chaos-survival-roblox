-- Strictly local sound presentation policy. The server's hazard events,
-- hitboxes and authoritative impact timing are never modified here.
local ImpactAudioRules = {}

local TIERS = {
    Low = {MaxDistance = 72, MaxLayers = 1},
    Medium = {MaxDistance = 104, MaxLayers = 2},
    High = {MaxDistance = 125, MaxLayers = 3},
}

function ImpactAudioRules.plan(kind, distance, tierName, muted)
    if kind ~= "Meteor" and kind ~= "Bomb" then return nil end
    if muted == true then return nil end
    local range = TIERS[tostring(tierName or "Low")] or TIERS.Low
    local d = tonumber(distance)
    if not d or d < 0 or d > range.MaxDistance or d ~= d then return nil end
    -- Mid-field impacts use one less sound layer; distant events one only.
    -- Roblox spatial rolloff remains active as the primary attenuation.
    local layers = range.MaxLayers
    if d > 86 then
        layers = 1
    elseif d > 44 then
        layers = math.min(2, layers)
    end
    return {
        Kind = kind,
        LayerCount = layers,
        MinDistance = 8,
        MaxDistance = range.MaxDistance,
        VolumeScale = d <= 44 and 1 or (d <= 86 and 0.86 or 0.74),
        Lifetime = 2.8,
    }
end

return ImpactAudioRules
