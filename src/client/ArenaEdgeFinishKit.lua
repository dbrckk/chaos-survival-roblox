-- Chaos Signal perimeter facade: one signature language per arena.
-- Geometry is outside the playable deck and has no collision or moving parts.
local ArenaEdgeFinishKit = {}

local MOTIFS = {
    Classic = {"ClassicSurveyBrace", "ClassicBearingPlate", "ClassicRadarBeacon"},
    Towers = {"TowerCantilever", "TowerCableGuard", "TowerHoistBeacon"},
    Crossroads = {"CrossroadsTransitChevron", "CrossroadsRoutePlate", "CrossroadsSignalStud"},
    Orbital = {"OrbitalFluxArc", "OrbitalContainmentPanel", "OrbitalTelemetryCore"},
}

local function count(tier)
    if tier == "Low" then return 1 end
    if tier == "High" then return 3 end
    return 2
end

function ArenaEdgeFinishKit.names(variant)
    return MOTIFS[variant]
end

function ArenaEdgeFinishKit.count(tier)
    return count(tier)
end

local function create(parent, frame, sideName, name, size, offset, rotation, color, material, alpha, shape)
    local part = Instance.new("Part")
    part.Name = name .. sideName
    part.Size = size
    part.CFrame = frame * CFrame.new(offset) * (rotation or CFrame.identity)
    part.Color = color
    part.Material = material
    part.Transparency = alpha or 0
    if shape then part.Shape = shape end
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part:SetAttribute("ChaosEdgeFinish", true)
    part.Parent = parent
    return part
end

function ArenaEdgeFinishKit.build(parent, base, variant, tier, theme)
    local motifs = MOTIFS[variant]
    if not parent or not base or not base:IsA("BasePart")
        or not motifs or not theme
    then
        return {}
    end

    local halfX, halfZ = base.Size.X * 0.5, base.Size.Z * 0.5
    local deckY = base.Size.Y * 0.5
    local sides = {
        {Name = "North", Offset = Vector3.new(0, deckY - 0.75, -halfZ - 0.55), Yaw = 0, Span = halfX},
        {Name = "South", Offset = Vector3.new(0, deckY - 0.75, halfZ + 0.55), Yaw = math.pi, Span = halfX},
        {Name = "East", Offset = Vector3.new(halfX + 0.55, deckY - 0.75, 0), Yaw = math.pi * 0.5, Span = halfZ},
        {Name = "West", Offset = Vector3.new(-halfX - 0.55, deckY - 0.75, 0), Yaw = -math.pi * 0.5, Span = halfZ},
    }
    local built = {}
    local budget = count(tier)
    for _, side in ipairs(sides) do
        local frame = base.CFrame * CFrame.new(side.Offset)
            * CFrame.Angles(0, side.Yaw, 0)
        local width = math.clamp(side.Span * 0.30, 2.6, 10.5)

        local function add(index, size, offset, rotation, color, material, alpha, shape)
            if index > budget then return end
            table.insert(built, create(parent, frame, side.Name,
                motifs[index], size, offset, rotation, color, material, alpha, shape))
        end

        if variant == "Classic" then
            -- Survey-triangulation silhouette, dull gauge and isolated lamp.
            add(1, Vector3.new(width, 0.38, 0.42),
                Vector3.new(0, -0.64, -0.82),
                CFrame.Angles(0, 0, math.rad(17)),
                theme.Structure, Enum.Material.DiamondPlate, 0.09)
            add(2, Vector3.new(width * 0.62, 0.17, 0.19),
                Vector3.new(0, 0.10, -0.92), nil,
                theme.Detail, Enum.Material.Metal, 0.12)
            add(3, Vector3.new(0.58, 0.15, 0.16),
                Vector3.new(width * 0.31, 0.25, -1.00), nil,
                theme.Accent, Enum.Material.Neon, 0.40)

        elseif variant == "Towers" then
            -- Deep vertical hoist with exposed cable protection.
            add(1, Vector3.new(width * 0.72, 2.85, 0.48),
                Vector3.new(0, -1.25, -0.72),
                CFrame.Angles(0, 0, math.rad(-10)),
                theme.Structure, Enum.Material.CorrodedMetal, 0.08)
            add(2, Vector3.new(width * 0.58, 0.35, 0.29),
                Vector3.new(0, -2.43, -0.91), nil,
                theme.Detail, Enum.Material.Metal, 0.11)
            add(3, Vector3.new(0.16, 1.25, 0.16),
                Vector3.new(width * 0.25, -1.17, -1.02), nil,
                theme.Accent, Enum.Material.Neon, 0.46)

        elseif variant == "Crossroads" then
            -- Bracketed wayfinding chevron: the silhouette carries the message.
            add(1, Vector3.new(width * 0.78, 0.40, 0.29),
                Vector3.new(0, -0.23, -0.87),
                CFrame.Angles(0, 0, math.rad(25)),
                theme.Detail, Enum.Material.Metal, 0.07)
            add(2, Vector3.new(width * 0.62, 0.27, 0.23),
                Vector3.new(0, -0.08, -1.02),
                CFrame.Angles(0, 0, math.rad(-25)),
                theme.Secondary, Enum.Material.Metal, 0.10)
            add(3, Vector3.new(0.48, 0.26, 0.18),
                Vector3.new(width * 0.35, 0.25, -1.09), nil,
                theme.Accent, Enum.Material.Neon, 0.45)

        elseif variant == "Orbital" then
            -- Radial field restraint with glass rather than generic neon rails.
            add(1, Vector3.new(width * 0.80, 0.42, 0.36),
                Vector3.new(0, -0.24, -0.87),
                CFrame.Angles(0, 0, math.rad(-28)),
                theme.Structure, Enum.Material.Metal, 0.13)
            add(2, Vector3.new(width * 0.57, 0.29, 0.22),
                Vector3.new(0, 0.09, -1.03),
                CFrame.Angles(0, 0, math.rad(20)),
                theme.Detail, Enum.Material.Glass, 0.30)
            add(3, Vector3.new(0.42, 0.42, 0.42),
                Vector3.new(0, 0.19, -1.18), nil,
                theme.Accent, Enum.Material.Glass, 0.22, Enum.PartType.Ball)
        end
    end

    return built
end

return ArenaEdgeFinishKit
