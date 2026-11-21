-- Procedural hollow transition outlines. No solid discs or flashing screen effects.
-- Segments are local, short lived, non-physical and adapt to mobile graphics tiers.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CinematicPulseRingKit = {}

local SEGMENTS = {Low = 4, Medium = 6, High = 8}

function CinematicPulseRingKit.segmentCount(tier)
    return SEGMENTS[tier] or 0
end

function CinematicPulseRingKit.segmentFrame(centerCF, radius, index, count)
    local angle = (index - 1) / count * math.pi * 2
    return centerCF * CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        * CFrame.Angles(0, -(angle + math.pi * 0.5), 0)
end

function CinematicPulseRingKit.emit(parent, name, centerCF, color, startDiameter,
        endDiameter, duration, tier, reduceMotion, alpha, ringMesh, cloneArc)
    local count = CinematicPulseRingKit.segmentCount(tier)
    local result = {}
    if not parent or typeof(centerCF) ~= "CFrame" or typeof(color) ~= "Color3"
        or count == 0 or type(startDiameter) ~= "number"
        or type(endDiameter) ~= "number" or type(duration) ~= "number"
        or endDiameter <= 0 or duration <= 0 then
        return result
    end

    local targetRadius = endDiameter * 0.5
    local initialRadius = reduceMotion and targetRadius
        or math.clamp(startDiameter * 0.5, 0.30, targetRadius)
    local durationSeconds = reduceMotion and math.min(duration, 0.24) or duration
    local initialAlpha = math.clamp(alpha or 0.40, 0.25, 0.78)
    local function animate(piece, initialFrame, initialSize, targetFrame, targetSize)
        piece.Size = initialSize
        piece.CFrame = initialFrame
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece.Material = Enum.Material.Neon
        piece.Color = color
        piece.Transparency = initialAlpha
        piece:SetAttribute("ChaosTransitionArc", true)
        piece.Parent = parent
        TweenService:Create(
            piece,
            TweenInfo.new(durationSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = targetFrame,
                Size = targetSize,
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(piece, durationSeconds + 0.12)
        table.insert(result, piece)
    end

    if ringMesh then
        ringMesh.Name = name
        animate(ringMesh, centerCF, Vector3.new(initialRadius * 2, 0.055, initialRadius * 2),
            centerCF, Vector3.new(endDiameter, 0.055, endDiameter))
        return result
    end

    local function segmentSize(radius)
        return Vector3.new(math.max(0.65, 2 * radius * math.sin(math.pi / count) * 0.74),
            0.055, 0.18)
    end

    for i = 1, count do
        local piece = (cloneArc and cloneArc()) or Instance.new("Part")
        piece.Name = name .. "_Arc" .. i
        animate(piece,
            CinematicPulseRingKit.segmentFrame(centerCF, initialRadius, i, count), segmentSize(initialRadius),
            CinematicPulseRingKit.segmentFrame(centerCF, targetRadius, i, count), segmentSize(targetRadius))
    end
    return result
end

return CinematicPulseRingKit
