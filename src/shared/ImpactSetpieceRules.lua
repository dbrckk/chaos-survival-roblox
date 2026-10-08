-- Lightweight impact-specific 3D accents layered on top of the existing
-- shock rings, smoke, scorch decals and game-authoritative damage.
-- Only Meteor and Bomb events are known to the HazardImpactFeedback protocol.
local ImpactSetpieceRules = {}

local VARIANTS = {
    Meteor = {
        Kind = "Meteor",
        ColorMix = 0.50,
        Material = "Glass",
        Prefix = "MeteorShard",
        Lifetime = 0.85,
    },
    Bomb = {
        Kind = "Bomb",
        ColorMix = 0.24,
        Material = "Neon",
        Prefix = "BombPressureSpoke",
        Lifetime = 0.62,
    },
}
local BUDGETS = {
    Low = {Meteor = 0, Bomb = 0},
    Medium = {Meteor = 4, Bomb = 4},
    High = {Meteor = 7, Bomb = 8},
}

function ImpactSetpieceRules.get(kind, tier, reduceMotion, radius)
    if reduceMotion == true then
        return nil
    end
    local variant = VARIANTS[tostring(kind or "")]
    local budget = BUDGETS[tostring(tier or "Low")] or BUDGETS.Low
    local count = budget[variant and variant.Kind or ""] or 0
    if not variant or count == 0 then
        return nil
    end
    return {
        Kind = variant.Kind,
        Count = count,
        Lifetime = variant.Lifetime,
        Radius = math.clamp(tonumber(radius) or 8, 1, 40),
        ColorMix = variant.ColorMix,
        Material = variant.Material,
        Prefix = variant.Prefix,
    }
end

-- Static deterministic positioning avoids random visual flicker and makes
-- every client see a recognizable radial signature at each impact.
function ImpactSetpieceRules.fragment(kind, index, count, radius)
    local size = math.max(1, math.clamp(tonumber(radius) or 8, 1, 40))
    local total = math.max(1, math.floor(tonumber(count) or 1))
    local i = math.clamp(math.floor(tonumber(index) or 1), 1, total)
    local angle = (i - 1) / total * math.pi * 2
    local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))

    if kind == "Meteor" then
        return {
            Direction = direction,
            StartRadius = size * 0.12,
            EndRadius = size * 0.62,
            Lift = 1.2 + (i % 3) * 0.55,
            Length = math.max(0.6, size * 0.19),
            Width = math.max(0.12, size * 0.045),
        }
    end

    return {
        Direction = direction,
        StartRadius = size * 0.20,
        EndRadius = size * 0.72,
        Lift = 0.14,
        Length = math.max(0.8, size * 0.58),
        Width = math.max(0.12, size * 0.030),
    }
end

return ImpactSetpieceRules
