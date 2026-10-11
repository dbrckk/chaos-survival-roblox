-- Runtime meteor trails are *visual only*. Cull at camera-relative range
-- and cap total instances so multiple meteors do not exhaust mobile effects.
local MeteorSignatureRules = {}
local PROFILES = {
    Low = {MaxTrails = 0, Range = 0, Lifetime = 0},
    Medium = {MaxTrails = 3, Range = 115, Lifetime = 0.15},
    High = {MaxTrails = 6, Range = 165, Lifetime = 0.23},
}

function MeteorSignatureRules.profile(tier, reducedMotion)
    if reducedMotion == true then return PROFILES.Low end
    return PROFILES[tostring(tier or "")] or PROFILES.Low
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
