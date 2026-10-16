-- Runtime meteor trails are *visual only*. Cull at camera-relative range
-- and cap total instances so multiple meteors do not exhaust mobile effects.
local MeteorSignatureRules = {}
local NONE = {MaxTrails = 0, Range = 0, Lifetime = 0}
local PROFILES = {
    -- A single near-camera comet silhouette makes Meteor Shower legible
    -- even after the adaptive tier drops on an Android phone.
    Low = {MaxTrails = 1, Range = 85, Lifetime = 0.17},
    Medium = {MaxTrails = 3, Range = 115, Lifetime = 0.20},
    High = {MaxTrails = 6, Range = 165, Lifetime = 0.23},
}

-- Hand-sculpted comet ribbon silhouettes; one existing Trail per meteor.
-- These constant sequences are shared by every meteor and never allocated
-- during the 0.25-second visibility scanner.
local STYLES = {
    Low = {
        WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.56),
            NumberSequenceKeypoint.new(0.25, 0.68),
            NumberSequenceKeypoint.new(0.65, 0.21),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.23),
            NumberSequenceKeypoint.new(0.50, 0.51),
            NumberSequenceKeypoint.new(1, 1),
        }),
        LightEmission = 0.58,
        Span = 0.16,
    },
    Medium = {
        WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.78),
            NumberSequenceKeypoint.new(0.24, 0.93),
            NumberSequenceKeypoint.new(0.68, 0.32),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.22),
            NumberSequenceKeypoint.new(0.42, 0.38),
            NumberSequenceKeypoint.new(1, 1),
        }),
        LightEmission = 0.70,
        Span = 0.22,
    },
    High = {
        WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(0.15, 1),
            NumberSequenceKeypoint.new(0.35, 0.55),
            NumberSequenceKeypoint.new(0.53, 0.71),
            NumberSequenceKeypoint.new(0.77, 0.26),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.13),
            NumberSequenceKeypoint.new(0.30, 0.22),
            NumberSequenceKeypoint.new(0.70, 0.62),
            NumberSequenceKeypoint.new(1, 1),
        }),
        LightEmission = 0.84,
        Span = 0.26,
    },
}

function MeteorSignatureRules.trailStyle(tier, reducedMotion)
    if reducedMotion == true then return nil end
    return STYLES[tostring(tier or "")]
end

function MeteorSignatureRules.profile(tier, reducedMotion)
    if reducedMotion == true then return NONE end
    return PROFILES[tostring(tier or "")] or NONE
end

-- A RoundState packet is optional/late on join. Reject malformed packets
-- without clearing the last valid visual state or throwing in a client script.
function MeteorSignatureRules.readRoundState(state)
    if type(state) ~= "table" then return nil, nil end
    local phase = tostring(state.phase or "waiting")
    if phase ~= "round" then return phase, false end
    local ids = type(state.disasterIds) == "table"
        and state.disasterIds or {}
    for _, id in ipairs(ids) do
        if id == "Meteors" then return phase, true end
    end
    return phase, false
end

function MeteorSignatureRules.shouldTrail(phase, meteorsActive, viewerPosition,
        meteorPosition, tier, reducedMotion, allocated)
    local profile = MeteorSignatureRules.profile(tier, reducedMotion)
    if phase ~= "round" or meteorsActive ~= true
        or profile.MaxTrails == 0 or (tonumber(allocated) or 0) >= profile.MaxTrails
        or typeof(viewerPosition) ~= "Vector3"
        or typeof(meteorPosition) ~= "Vector3" then
        return false
    end
    return (viewerPosition - meteorPosition).Magnitude <= profile.Range
end

-- Prioritize the closest visible hazards; avoids child creation order determining
-- which meteors receive the limited effects in dense storm rounds.
function MeteorSignatureRules.orderedCandidates(children, viewerPosition)
    local candidates = {}
    if type(children) ~= "table" or typeof(viewerPosition) ~= "Vector3" then
        return candidates
    end
    for _, child in ipairs(children) do
        if child:IsA("BasePart") and child.Name == "RoundMeteor" and child.Parent then
            local distance = (viewerPosition - child.Position).Magnitude
            table.insert(candidates, {Part = child, Distance = distance})
        end
    end
    table.sort(candidates, function(a, b)
        if a.Distance ~= b.Distance then
            return a.Distance < b.Distance
        end
        -- A stable final tie-break is not needed for visual correctness;
        -- if two meteors overlap, either one reads as the same hazard.
        return a.Part.Name < b.Part.Name
    end)
    return candidates
end

return MeteorSignatureRules
