-- Lightweight impact-specific 3D accents layered on top of the existing
-- shock rings, smoke, scorch decals and game-authoritative damage.
-- Only Meteor and Bomb events are known to the HazardImpactFeedback protocol.
local ImpactSetpieceRules = {}

-- Network-sourced impact data must not reach CFrame/Tween/raycast math
-- with non-finite coordinates or colors. Gameplay remains server-owned.
local function finite(number)
    return type(number) == "number" and number == number
        and math.abs(number) < math.huge
end

function ImpactSetpieceRules.validPayload(payload)
    if type(payload) ~= "table" or typeof(payload.position) ~= "Vector3"
        or typeof(payload.color) ~= "Color3" then
        return false
    end
    local p, c = payload.position, payload.color
    return finite(p.X) and finite(p.Y) and finite(p.Z)
        and math.abs(p.X) <= 1e7 and math.abs(p.Y) <= 1e7
        and math.abs(p.Z) <= 1e7
        and finite(c.R) and finite(c.G) and finite(c.B)
        and c.R >= 0 and c.R <= 1
        and c.G >= 0 and c.G <= 1
        and c.B >= 0 and c.B <= 1
end

-- Invalid/missing radii produce bounded neutral art, never NaN geometry.
function ImpactSetpieceRules.safeRadius(value)
    local radius = tonumber(value)
    if not finite(radius) then return 8 end
    return math.clamp(radius, 1, 40)
end

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
-- Accent geometry is independently budgeted below the debris/shard budget.
-- Low devices get at most two inexpensive, short-lived fragments; reduced
-- motion continues to suppress all decorative shrapnel.
local FINISH_BUDGETS = {
    Medium = {Meteor = 2, Bomb = 2},
    High = {Meteor = 4, Bomb = 4},
}
local BUDGETS = {
    Low = {Meteor = 2, Bomb = 2},
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
        Radius = ImpactSetpieceRules.safeRadius(radius),
        ColorMix = variant.ColorMix,
        Material = variant.Material,
        Prefix = variant.Prefix,
    }
end

function ImpactSetpieceRules.finishCount(kind, tier, reduceMotion)
    if reduceMotion == true or not VARIANTS[tostring(kind or "")] then
        return 0
    end
    local budgets = FINISH_BUDGETS[tostring(tier or "Low")]
    return budgets and (budgets[kind] or 0) or 0
end

function ImpactSetpieceRules.finish(kind, index, total, radius)
    if kind ~= "Meteor" and kind ~= "Bomb" then
        return nil
    end
    if not finite(index) or not finite(total) or index % 1 ~= 0
        or total % 1 ~= 0 or index < 1 or total < 1
        or index > total or total > 4 then
        return nil
    end
    local size = ImpactSetpieceRules.safeRadius(radius)
    local slot, segments = index, total
    -- Meteor: chipped offset edges. Bomb: alternating tangential pressure
    -- arcs. No additional pieces, randomness or per-frame animation.
    local phaseSkew = kind == "Meteor"
        and (slot % 2 == 0 and -0.10 or 0.08)
        or (slot % 2 == 0 and 0.06 or -0.06)
    local angle = ((slot - 0.5) / segments) * math.pi * 2 + phaseSkew
    local facet = 0.90 + (slot % 3) * 0.07
    return {
        Angle = angle,
        YawSkew = kind == "Meteor" and phaseSkew * 0.4 or phaseSkew,
        Bank = kind == "Meteor"
            and math.rad(slot % 2 == 0 and -15 or 22)
            or math.rad(slot % 2 == 0 and 8 or -8),
        Direction = Vector3.new(math.cos(angle), 0, math.sin(angle)),
        StartRadius = size * (kind == "Meteor" and 0.15 or 0.25),
        EndRadius = size * (kind == "Meteor" and 0.47 or 0.78),
        Lift = kind == "Meteor" and (0.45 + (slot % 2) * 0.35) or 0.08,
        Width = math.max(0.35, size * (kind == "Meteor" and 0.095 or 0.21))
            * facet,
        Height = math.max(0.15, size * (kind == "Meteor" and 0.15 or 0.018))
            * (kind == "Meteor" and facet or 1),
    }
end

-- Static deterministic positioning avoids random visual flicker and makes
-- every client see a recognizable radial signature at each impact.
function ImpactSetpieceRules.fragment(kind, index, count, radius)
    if (kind ~= "Meteor" and kind ~= "Bomb")
        or not finite(index) or not finite(count)
        or index % 1 ~= 0 or count % 1 ~= 0
        or index < 1 or count < 1 or count > 8 or index > count then
        return nil
    end
    local size = ImpactSetpieceRules.safeRadius(radius)
    local total, i = count, index
    local variation = kind == "Meteor"
        and (((i * 5) % 7) - 3) * 0.035
        or ((i % 3) - 1) * 0.035
    local angle = (i - 1) / total * math.pi * 2 + variation
    local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))

    if kind == "Meteor" then
        return {
            Direction = direction,
            StartRadius = size * 0.12,
            EndRadius = size * 0.62,
            Lift = 1.2 + (i % 3) * 0.55,
            Length = math.max(0.6, size * 0.19) * (0.85 + (i % 3) * 0.08),
            Width = math.max(0.12, size * 0.045) * (0.86 + (i % 3) * 0.10),
            YawSkew = variation * 0.55,
            Bank = math.rad(i % 2 == 0 and -28 or 30),
        }
    end

    return {
        Direction = direction,
        StartRadius = size * 0.20,
        EndRadius = size * 0.72,
        Lift = 0.14,
        Length = math.max(0.8, size * 0.58) * (0.88 + (i % 4) * 0.06),
        Width = math.max(0.12, size * 0.030) * (0.95 + (i % 2) * 0.10),
        YawSkew = (i % 2 == 0 and -0.13 or 0.13),
        Bank = math.rad(i % 2 == 0 and -7 or 7),
    }
end

return ImpactSetpieceRules
