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


-- Double Chaos may produce a Meteor and Bomb blast on the same scheduler
-- step. The old shared 100ms gate silently dropped one of them. Separate
-- per-kind cooldowns preserve both identities while still limiting spam.
-- The second *different* impact is gently attenuated to protect phone audio.
local COOLDOWNS = {Low = 0.18, Medium = 0.14, High = 0.12}

local function finite(value)
    return type(value) == "number" and value == value
        and math.abs(value) < math.huge
end

function ImpactAudioRules.gate(kind, now, lastByKind, tierName)
    if kind ~= "Meteor" and kind ~= "Bomb"
        or not finite(now) or now < 0
        or type(lastByKind) ~= "table" then
        return false, 0
    end
    local recent = lastByKind[kind]
    local gap = COOLDOWNS[tostring(tierName or "")] or COOLDOWNS.Low
    if finite(recent) and now - recent < gap then
        return false, 0
    end
    local otherKind = kind == "Meteor" and "Bomb" or "Meteor"
    local other = lastByKind[otherKind]
    local overlap = finite(other) and now >= other and now - other < 0.20
    return true, overlap and 0.68 or 1
end

return ImpactAudioRules
