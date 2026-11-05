-- Stable, tier-independent original station positions around the
-- authentic 320-stud Orbital Ring. Only six real cosmetic silhouettes;
-- no RemoteEvent, gameplay floor, physical collisions or update loop.
local Rules = {}

-- Low is a true subset of Medium, Medium of High. Each new quality tier
-- ADDS original ring locations rather than rotating existing stations.
-- Retain two existing sculptural source families (odd/even index).
local TIERS = {
    Low = {1, 3, 6},
    Medium = {1, 3, 4, 6},
    High = {1, 2, 3, 4, 5, 6},
}

function Rules.indices(tier)
    return TIERS[tier] or TIERS.Low
end

function Rules.angle(index)
    if type(index) ~= "number" or index ~= math.floor(index)
        or index < 1 or index > 6 then return nil end
    -- Deliberately divide by SIX, never by count of current tier.
    return ((index - 1) / 6) * math.pi * 2 + math.rad(18)
end

function Rules.offset(baseSize, index)
    local angle = Rules.angle(index)
    if typeof(baseSize) ~= "Vector3" or not angle
        or baseSize.X < 160 or baseSize.Z < 160 then return nil end
    local radius = math.min(baseSize.X, baseSize.Z) * 0.76
        + (index % 2) * 7
    return Vector3.new(
        math.cos(angle) * radius,
        10 + (index % 2) * 4,
        math.sin(angle) * radius
    )
end

return Rules
