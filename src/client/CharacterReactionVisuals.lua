-- Testable Roblox-native visual primitives. No character motor, physics,
-- health, camera or Animator is changed. Beam instances follow their root.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local CharacterReactionVisuals = {}
local MAX_LIVE_BEAMS = 12

-- Only Beam instances count toward the renderer budget (attachments are free
-- bookkeeping). Prune dead references between bursts.
local function liveBeamCount(activePieces)
    local count = 0
    for instance in pairs(activePieces) do
        if not instance.Parent then
            activePieces[instance] = nil
        elseif instance:IsA("Beam") then
            count += 1
        end
    end
    return count
end

function CharacterReactionVisuals.activeBeams(activePieces)
    return type(activePieces) == "table" and liveBeamCount(activePieces) or 0
end

local function colorFor(kind, mode)
    if mode == "Landing" then
        return Color3.fromRGB(95, 216, 255)
    elseif kind == "Bomb" then
        return Color3.fromRGB(255, 107, 127)
    elseif kind == "Meteor" then
        return Color3.fromRGB(255, 184, 86)
    end
    return Color3.fromRGB(106, 220, 235)
end

-- A different movement silhouette for every type of hazard: meteors throw
-- sparks upward; bombs push a broad low pressure-front; dodges trail behind
-- the avatar. This is a pure recipe for engine tests to inspect.
function CharacterReactionVisuals.signature(mode, kind, index, strength)
    if mode ~= "Dodge" and mode ~= "Shock" and mode ~= "Landing" then
        return nil
    end
    local side = (tonumber(index) or 1) % 2 == 0 and 1 or -1
    local stripe = math.ceil(math.max(1, tonumber(index) or 1) / 2)
    local height = 0.24 + stripe * 0.22
    local intensity = math.clamp(tonumber(strength) or 0, 0, 1)
    local startPosition
    local endPosition
    local curve0
    local curve1
    if mode == "Dodge" and kind == "Bomb" then
        -- Bomb evasions produce a low, swept pressure-ribbon with wide lateral spread.
        startPosition = Vector3.new(side * 0.62, -0.50 + height, 0.68)
        endPosition = Vector3.new(side * (1.45 + intensity * 0.55),
            -0.18 + height, -0.69)
        curve0 = side * (0.46 + intensity * 0.24)
        curve1 = -side * 0.32
    elseif mode == "Dodge" and kind == "Meteor" then
        -- Meteor escapes leave a steeper upward afterimage.
        startPosition = Vector3.new(side * 0.60, -0.32 + height, 0.52)
        endPosition = Vector3.new(side * (0.94 + intensity * 0.36),
            1.18 + height + intensity * 0.12, -0.58)
        curve0 = side * (0.23 + intensity * 0.26)
        curve1 = -side * 0.24
    elseif mode == "Dodge" then
        startPosition = Vector3.new(side * 0.72, -0.36 + height, 0.62)
        endPosition = Vector3.new(side * (1.10 + intensity * 0.42),
            0.92 + height, -0.52)
        curve0 = side * (0.35 + intensity * 0.35)
        curve1 = -side * 0.22
    elseif mode == "Shock" and kind == "Meteor" then
        -- A high, angular ejection rather than a generic sideways ring.
        startPosition = Vector3.new(side * 0.49, 0.10 + height, 0.35)
        endPosition = Vector3.new(side * (1.04 + intensity * 0.28),
            1.30 + height + intensity * 0.25, -0.43)
        curve0 = side * (0.12 + intensity * 0.17)
        curve1 = -side * 0.48
    elseif mode == "Shock" then
        -- The Bomb signature moves horizontally around the character's waist.
        startPosition = Vector3.new(side * 0.55, 0.18 + height, 0.38)
        endPosition = Vector3.new(side * (1.55 + intensity * 0.45),
            0.30 + height, -0.36)
        curve0 = side * (0.45 + intensity * 0.26)
        curve1 = -side * 0.13
    else
        startPosition = Vector3.new(side * 0.45, -1.10, 0.32)
        endPosition = Vector3.new(side * (0.92 + intensity * 0.32), -1.62, -0.72)
        curve0 = side * 0.24
        curve1 = -side * 0.18
    end

    local lifetime = mode == "Dodge" and 0.42
        or (mode == "Shock" and 0.31 or 0.34)
    return {
        Start = startPosition,
        Finish = endPosition,
        Curve0 = curve0,
        Curve1 = curve1,
        Width = 0.09 + 0.055 * intensity,
        Lifetime = lifetime,
        Segments = mode == "Landing" and 6 or 8,
        Emission = mode == "Landing" and 0.40
            or (mode == "Shock" and kind == "Bomb" and 0.55 or 0.72),
        Color = colorFor(kind, mode),
    }
end

-- Shock outlines must travel away from the actual explosion, rather than
-- follow the facing direction of whichever avatar received the event.
-- Nil/degenerate positions keep the original avatar-relative composition.
function CharacterReactionVisuals.shockOrientation(rootCFrame, sourcePosition)
    if typeof(rootCFrame) ~= "CFrame"
        or typeof(sourcePosition) ~= "Vector3" then
        return CFrame.new(), false
    end
    local delta = rootCFrame.Position - sourcePosition
    local flat = Vector3.new(delta.X, 0, delta.Z)
    if flat.Magnitude < 0.05 then
        return CFrame.new(), false
    end
    local localAway = rootCFrame:VectorToObjectSpace(flat.Unit)
    local horizontal = Vector3.new(localAway.X, 0, localAway.Z)
    if horizontal.Magnitude < 0.05 then
        return CFrame.new(), false
    end
    return CFrame.lookAt(Vector3.zero, horizontal.Unit), true
end

-- Beams follow the root, then taper progressively; no extra BaseParts,
-- per-frame loops, physics impulses or screen-space camera movement.
local function stroke(root, mode, kind, index, strength, activePieces, orientation, directional)
    local design = CharacterReactionVisuals.signature(mode, kind, index, strength)
    if not design then return end

    local a = Instance.new("Attachment")
    a.Name = "ChaosReaction" .. mode .. "Start"
    a.Position = orientation:VectorToWorldSpace(design.Start)
    a.Parent = root
    local b = Instance.new("Attachment")
    b.Name = "ChaosReaction" .. mode .. "End"
    b.Position = orientation:VectorToWorldSpace(design.Finish)
    b.Parent = root

    local beam = Instance.new("Beam")
    beam.Name = "ChaosReaction" .. mode
    beam.Attachment0 = a
    beam.Attachment1 = b
    beam.Segments = design.Segments
    beam.FaceCamera = true
    beam.LightEmission = design.Emission
    beam.LightInfluence = 0
    beam.Width0 = design.Width
    beam.Width1 = 0.015
    beam.CurveSize0 = design.Curve0
    beam.CurveSize1 = design.Curve1
    beam.Color = ColorSequence.new(design.Color, Color3.fromRGB(230, 248, 255))
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.60, 0.38),
        NumberSequenceKeypoint.new(1, 1),
    })
    beam:SetAttribute("ChaosReactionMode", mode)
    beam:SetAttribute("ChaosReactionKind", kind)
    beam:SetAttribute("ChaosReactionDirectional", directional == true)
    beam.Parent = root

    -- The last ~70% of the effect collapses to a fine filament instead of
    -- snapping off at the end of the lifetime. One tween per Beam, bounded.
    task.delay(design.Lifetime * 0.22, function()
        if beam.Parent then
            TweenService:Create(
                beam,
                TweenInfo.new(design.Lifetime * 0.68,
                    Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Width0 = 0.002, Width1 = 0}
            ):Play()
        end
    end)

    local instances = {a, b, beam}
    for _, instance in ipairs(instances) do
        activePieces[instance] = true
        Debris:AddItem(instance, design.Lifetime)
    end
    -- One expiration callback per stroke, not one callback per instance.
    task.delay(design.Lifetime + 0.02, function()
        for _, instance in ipairs(instances) do
            activePieces[instance] = nil
        end
    end)
end

function CharacterReactionVisuals.burst(root, mode, kind, count, strength, activePieces, sourcePosition)
    if not root or not root:IsA("BasePart") or not root.Parent
        or type(activePieces) ~= "table"
        or CharacterReactionVisuals.signature(mode, kind, 1, strength) == nil
    then
        return 0
    end
    local requested = math.clamp(math.floor(tonumber(count) or 0), 0, 3)
    local available = math.max(0, MAX_LIVE_BEAMS - liveBeamCount(activePieces))
    local pieces = math.min(requested, available)
    local intensity = math.clamp(tonumber(strength) or 0, 0, 1)
    local orientation, directional = CFrame.new(), false
    if mode == "Shock" then
        orientation, directional = CharacterReactionVisuals.shockOrientation(
            root.CFrame, sourcePosition
        )
    end
    for i = 1, pieces do
        stroke(root, mode, kind, i, intensity, activePieces, orientation, directional)
    end
    return pieces
end

return CharacterReactionVisuals
