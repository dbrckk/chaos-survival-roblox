-- Procedural, non-physical warning silhouettes placed in arena-local space.
-- The server's authoritative warning Part, lifetime and damage are untouched.
local HazardWarningSignatureRules = {}

local COUNTS = {
    Freeze = {Low = 4, Medium = 6, High = 8},
    JumpShock = {Low = 1, Medium = 3, High = 4},
}
local REDUCED = {Freeze = 2, JumpShock = 1}

function HazardWarningSignatureRules.count(kind, tier, reduced)
    local limits = COUNTS[kind]
    if not limits then return 0 end
    if reduced == true then return REDUCED[kind] end
    return limits[tier] or limits.Low
end

-- Use Base.CFrame rotation when it exists. The warning center remains the
-- server-supplied point, without moving/correcting its effective hitbox.
function HazardWarningSignatureRules.frame(position, deck)
    if typeof(position) ~= "Vector3" then return nil end
    if typeof(deck) == "CFrame" then
        return CFrame.new(position) * deck.Rotation
    end
    return CFrame.new(position)
end

-- Freeze uses short glass/ice-like faceted teeth near the warning perimeter.
-- Shock uses angular inward-facing strokes, not a duplicate solid ring.
function HazardWarningSignatureRules.recipe(kind, index, count, diameter, progress)
    if not COUNTS[kind] or type(index) ~= "number"
        or type(count) ~= "number" or index % 1 ~= 0
        or count < 1 or count > 8 or index < 1 or index > count
        or type(diameter) ~= "number" or diameter <= 0 then
        return nil
    end
    local t = math.clamp(tonumber(progress) or 0, 0, 1)
    local freeze = kind == "Freeze"
    local radius = math.clamp(diameter * 0.5, 3, 90)
    local angle = ((index - 1) / count) * math.pi * 2
        + (freeze and 0.20 or -0.16)
    local offsetRadius = radius * (freeze and 0.84 or 0.72)
    local localPosition = Vector3.new(
        math.cos(angle) * offsetRadius,
        freeze and 0.19 or 0.13,
        math.sin(angle) * offsetRadius
    )
    local tangent = CFrame.Angles(
        0, -angle - math.pi * 0.5
            + ((index % 2 == 0) and 0.21 or -0.17),
        freeze and ((index % 2 == 0) and 0.09 or -0.09) or 0
    )
    local baseLength = math.clamp(radius * (freeze and 0.16 or 0.20),
        freeze and 2.0 or 1.4, freeze and 11 or 12)
    local extension = freeze and (0.91 + 0.09 * t) or (0.78 + 0.22 * t)
    return {
        Wedge = freeze,
        Material = freeze and Enum.Material.Glass or Enum.Material.Neon,
        Offset = localPosition,
        Rotation = tangent,
        Size = Vector3.new(
            baseLength * extension,
            freeze and 0.12 or 0.055,
            freeze and 0.36 or 0.14
        ),
        Transparency = math.clamp(
            (freeze and 0.46 or 0.34) + t * (freeze and 0.25 or 0.48),
            0.30, 0.92
        ),
        Secondary = index % 2 == 0,
        Color = freeze and Color3.fromRGB(140, 222, 245)
            or Color3.fromRGB(76, 214, 255),
        SecondaryColor = freeze and Color3.fromRGB(203, 243, 255)
            or Color3.fromRGB(170, 235, 255),
    }
end

-- The world-space warning should describe the danger accurately, not
-- suggest that jumping evades JumpShock (the server applies its impulse
-- regardless of the player's jump state). Localized from the shared HUD copy.
local WARNING_IDS = {
    Meteor = "Meteors",
    Bomb = "Bombs",
    Freeze = "Freeze",
    JumpShock = "JumpShock",
}
function HazardWarningSignatureRules.label(kind, localeId, localization)
    local id = WARNING_IDS[kind]
    if not id then return nil end
    if not localization then return string.upper(kind) end
    local label
    if kind == "Meteor" or kind == "Bomb" then
        label = localization.hazardAction(localeId, id)
    else
        label = localization.hazardName(localeId, id)
    end
    return label or string.upper(kind)
end

return HazardWarningSignatureRules
