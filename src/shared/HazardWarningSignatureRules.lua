-- Procedural, non-physical warning silhouettes placed in arena-local space.
-- The server's authoritative warning Part, lifetime and damage are untouched.
local HazardWarningSignatureRules = {}

local COUNTS = {
    Freeze = {Low = 4, Medium = 6, High = 8},
    JumpShock = {Low = 1, Medium = 3, High = 4},
}
local REDUCED = {Freeze = 2, JumpShock = 1}

-- Cached warning contrast recipes. Live automatic quality changes must
-- restyle existing Highlights rather than leave their previous intensity.
local PLATFORM_STYLES = {
    Low = {FillTransparency = 0.92, OutlineTransparency = 0.36},
    Standard = {FillTransparency = 0.84, OutlineTransparency = 0.18},
}

function HazardWarningSignatureRules.platformHighlightStyle(tier)
    return tier == "Low" and PLATFORM_STYLES.Low or PLATFORM_STYLES.Standard
end

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


-- The ring grows toward the final impact diameter on ordinary graphics.
-- With ReduceMotion, display the full footprint without any growth.
-- Pure and bounded for late-arriving metadata and reduced-motion clients.
function HazardWarningSignatureRules.visualDiameter(startSize, endSize, progress, reduced)
    local function valid(value)
        return type(value) == "number" and value == value
            and math.abs(value) < math.huge and value > 0
    end
    if not valid(startSize) or not valid(endSize) then
        return nil
    end
    if reduced == true then
        return endSize
    end
    local t = math.clamp(tonumber(progress) or 0, 0, 1)
    return startSize + (endSize - startSize) * t
end

-- A replicated warning Part may arrive before its attributes, regardless of
-- their write order on the server. Never guess a 0.05-second warning from
-- partial metadata: that would hide the hazard cue before it is usable.
local WARNING_PARTS = {
    MeteorWarning = "Meteor",
    BombWarning = "Bomb",
    FreezeWarning = "Freeze",
    JumpShockWarning = "JumpShock",
}

local function finitePositive(value, minimum)
    return type(value) == "number" and value == value
        and math.abs(value) < math.huge and value >= minimum
end

function HazardWarningSignatureRules.snapshot(part, now)
    if typeof(part) ~= "Instance" or not part:IsA("BasePart") then return nil end
    local kind = WARNING_PARTS[part.Name]
    if not kind or part:GetAttribute("WarningKind") ~= kind then return nil end

    local startedAt = part:GetAttribute("WarningStartedAt")
    local duration = part:GetAttribute("WarningDuration")
    local startSize = part:GetAttribute("WarningStartSize")
    local endSize = part:GetAttribute("WarningEndSize")
    if not finitePositive(startedAt, 0) or not finitePositive(duration, 0.05)
        or not finitePositive(startSize, 0.1)
        or not finitePositive(endSize, 0.1)
        or not finitePositive(now, 0) then
        return nil
    end

    local elapsed = math.max(0, now - startedAt)
    if elapsed >= duration then return nil end
    return {
        Kind = kind,
        StartedAt = startedAt,
        Duration = duration,
        StartSize = startSize,
        EndSize = endSize,
        Progress = math.clamp(elapsed / duration, 0, 1),
    }
end

-- Jump Shock now has a server-verified airborne dodge. Its prompt
-- switches from anticipation to action shortly before the actual impact,
-- not on warning creation, or an early jump would be mistimed.
HazardWarningSignatureRules.JumpNowWindow = 0.42

function HazardWarningSignatureRules.jumpPrompt(secondsRemaining, localeId, localization)
    local remaining = tonumber(secondsRemaining)
    if not remaining or remaining ~= remaining
        or math.abs(remaining) == math.huge or remaining <= 0 then
        return nil
    end
    local key = remaining <= HazardWarningSignatureRules.JumpNowWindow
        and "JUMP_SHOCK_NOW" or "JUMP_SHOCK_READY"
    if localization and type(localization.text) == "function" then
        return localization.text(localeId, key)
    end
    return key == "JUMP_SHOCK_NOW" and "JUMP!" or "GET READY"
end

-- The world-space warning and the top-of-screen mobile cue share this
-- localized timeline and the server's replicated impact countdown.
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
    elseif kind == "JumpShock" then
        label = HazardWarningSignatureRules.jumpPrompt(1, localeId, localization)
    else
        label = localization.hazardName(localeId, id)
    end
    return label or string.upper(kind)
end

-- Alert timing derives from the authoritative warning start, so players
-- joining during an active hazard see the remaining animation rather than
-- a fresh full-duration countdown.
function HazardWarningSignatureRules.window(startedAt, duration, now)
    local start = tonumber(startedAt)
    local span = tonumber(duration)
    local clock = tonumber(now)
    if not start or not span or not clock
        or start ~= start or span ~= span or clock ~= clock
        or math.abs(start) == math.huge or math.abs(clock) == math.huge
        or span < 0.05 or span == math.huge then
        return nil, nil
    end
    span = math.clamp(span, 0.05, 2.5)
    local progress = math.clamp((clock - start) / span, 0, 1)
    return span * (1 - progress), progress
end

function HazardWarningSignatureRules.activeLimit(tier, reduced)
    if reduced == true then return 4 end
    return ({Low = 6, Medium = 10, High = 14})[tier] or 6
end

-- Limit floating world-space warning labels on narrow Android screens.
-- The authoritative world warning, ring, escape arrows and global top HUD
-- are ALWAYS retained. Global timed actions outrank local strike labels;
-- local strikes then use distance from the actual contestant, not unordered
-- Workspace arrival order. Rendering is refreshed by an existing client loop.
local LABEL_BUDGETS = {Low = 3, Medium = 4, High = 5}

function HazardWarningSignatureRules.labelBudget(tier)
    return LABEL_BUDGETS[tier] or LABEL_BUDGETS.Low
end

function HazardWarningSignatureRules.selectLabelWarnings(tracked, viewer, tier)
    local selected = {}
    if type(tracked) ~= "table" or typeof(viewer) ~= "Vector3" then
        return selected
    end
    local candidates = {}
    for part, state in pairs(tracked) do
        if typeof(part) == "Instance" and part:IsA("BasePart")
            and part.Parent == workspace and type(state) == "table" then
            local kind = state.kind
            if kind == "JumpShock" or kind == "Freeze"
                or kind == "Meteor" or kind == "Bomb" then
                local distance = (viewer - part.Position).Magnitude
                if distance == distance and distance < math.huge then
                    local priority = kind == "JumpShock" and 0
                        or (kind == "Freeze" and 1 or 2)
                    candidates[#candidates + 1] = {
                        part = part, priority = priority, distance = distance,
                    }
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return a.distance < b.distance
    end)
    for index = 1, math.min(#candidates,
        HazardWarningSignatureRules.labelBudget(tier)) do
        selected[candidates[index].part] = true
    end
    return selected
end

-- The shown ring is a countdown animation. Escape guidance must use
-- the FINAL damage radius, never the ring's interim size. Match the
-- authoritative DisasterImpact.applyRadialDamage 3D distance: elevated
-- platforms can be outside a blast even when directly above the marker.
-- Ground escape arrows must remain available for a player exactly at the
-- impact center, where horizontal displacement is zero. Prefer the true
-- outward radial bearing, then the character's horizontal facing direction.
-- A missing or vertical facing vector cannot safely imply an escape path.
function HazardWarningSignatureRules.escapeDirection(playerPosition, impactPosition, facing)
    if typeof(playerPosition) ~= "Vector3"
        or typeof(impactPosition) ~= "Vector3" then
        return nil
    end

    local delta = Vector3.new(
        playerPosition.X - impactPosition.X,
        0,
        playerPosition.Z - impactPosition.Z
    )
    if delta.Magnitude >= 0.15 then
        return delta.Unit
    end

    if typeof(facing) ~= "Vector3" then
        return nil
    end
    local flatFacing = Vector3.new(facing.X, 0, facing.Z)
    if flatFacing.Magnitude < 0.15 then
        return nil
    end
    return flatFacing.Unit
end

function HazardWarningSignatureRules.escapeClearance(playerPosition, impactPosition, endDiameter)
    if typeof(playerPosition) ~= "Vector3" or typeof(impactPosition) ~= "Vector3"
        or type(endDiameter) ~= "number" or endDiameter ~= endDiameter
        or math.abs(endDiameter) == math.huge or endDiameter <= 0 then
        return nil
    end
    return (playerPosition - impactPosition).Magnitude
        - math.max(1, endDiameter * 0.5)
end


-- Pick the most actionable overlapping Meteor/Bomb escape cue.
-- A player currently inside a blast's final 3D radius must see the
-- earliest imminent strike first; when impact times are nearly equal,
-- prioritize the deeper exposure. Outside both radii, preserve nearest
-- clearance so a distant impending blast does not eclipse local guidance.
function HazardWarningSignatureRules.preferThreat(
    clearance, remaining, previousClearance, previousRemaining
)
    local function finite(v)
        return type(v) == "number" and v == v and math.abs(v) < math.huge
    end
    if not finite(clearance) or not finite(remaining) or remaining < 0 then
        return false
    end
    if not finite(previousClearance) or not finite(previousRemaining) then
        return true
    end
    local inside = clearance <= 0
    local previousInside = previousClearance <= 0
    if inside ~= previousInside then return inside end
    if inside and math.abs(remaining - previousRemaining) > 0.12 then
        return remaining < previousRemaining
    end
    if clearance ~= previousClearance then return clearance < previousClearance end
    return remaining < previousRemaining
end

return HazardWarningSignatureRules
