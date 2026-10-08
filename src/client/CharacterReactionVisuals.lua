-- Testable Roblox-native visual primitives. No character motor, physics,
-- health, camera or animation is changed. Beam instances follow their root.
local Debris = game:GetService("Debris")
local CharacterReactionVisuals = {}

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

-- Beams create a curved 3D energy silhouette that follows its avatar, even
-- when the character stands still. All artifacts self-destruct in <0.5 sec.
local function stroke(root, mode, kind, index, strength, activePieces)
    local side = index % 2 == 0 and 1 or -1
    local stripe = math.ceil(index / 2)
    local height = 0.24 + stripe * 0.22
    local startPosition
    local endPosition
    if mode == "Dodge" then
        startPosition = Vector3.new(side * 0.72, -0.36 + height, 0.62)
        endPosition = Vector3.new(side * (1.1 + strength * 0.42), 0.92 + height, -0.52)
    elseif mode == "Shock" then
        startPosition = Vector3.new(side * 0.55, 0.16 + height, 0.38)
        endPosition = Vector3.new(side * (1.45 + strength * 0.50), 0.38 + height, -0.40)
    else
        startPosition = Vector3.new(side * 0.45, -1.10, 0.32)
        endPosition = Vector3.new(side * (0.92 + strength * 0.32), -1.62, -0.72)
    end

    local a = Instance.new("Attachment")
    a.Name = "ChaosReaction" .. mode .. "Start"
    a.Position = startPosition
    a.Parent = root
    local b = Instance.new("Attachment")
    b.Name = "ChaosReaction" .. mode .. "End"
    b.Position = endPosition
    b.Parent = root

    local beam = Instance.new("Beam")
    beam.Name = "ChaosReaction" .. mode
    beam.Attachment0 = a
    beam.Attachment1 = b
    beam.Segments = 8
    beam.FaceCamera = true
    beam.LightEmission = 0.72
    beam.LightInfluence = 0
    beam.Width0 = 0.09 + 0.055 * strength
    beam.Width1 = 0.015
    beam.CurveSize0 = side * (0.35 + strength * 0.35)
    beam.CurveSize1 = -side * 0.22
    beam.Color = ColorSequence.new(
        colorFor(kind, mode),
        Color3.fromRGB(230, 248, 255)
    )
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.60, 0.38),
        NumberSequenceKeypoint.new(1, 1),
    })
    beam.Parent = root

    local lifetime = mode == "Dodge" and 0.42
        or (mode == "Shock" and 0.31 or 0.34)
    for _, instance in ipairs({a, b, beam}) do
        activePieces[instance] = true
        Debris:AddItem(instance, lifetime)
        task.delay(lifetime + 0.02, function()
            activePieces[instance] = nil
        end)
    end
end


function CharacterReactionVisuals.burst(root, mode, kind, count, strength, activePieces)
    if not root or not root:IsA("BasePart") or not root.Parent
        or type(activePieces) ~= "table"
    then
        return 0
    end
    local pieces = math.clamp(math.floor(tonumber(count) or 0), 0, 3)
    local intensity = math.clamp(tonumber(strength) or 0, 0, 1)
    for i = 1, pieces do
        stroke(root, mode, kind, i, intensity, activePieces)
    end
    return pieces
end

return CharacterReactionVisuals
