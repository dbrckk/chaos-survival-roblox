-- Original Chaos Signal environment motifs. Non-colliding, deterministic
-- detail placed on existing static technical props and distant structures.
-- The Tier budget changes the amount of geometry, never the base silhouette.
local ArenaDetailKit = {}

local MOTIFS = {
    Classic = {
        Service = {"ClassicOpticShroud", "ClassicRegistrationRail", "ClassicAntennaFin"},
        Midground = {"ClassicTrussDiagonal", "ClassicTrussSpine", "ClassicSignalWindow"},
    },
    Towers = {
        Service = {"TowerCrateSeal", "TowerCrateLockrail", "TowerPressureGauge"},
        Midground = {"TowerCoolingVent", "TowerCoolantManifold", "TowerCoolingBeacon"},
    },
    Crossroads = {
        Service = {"CrossroadsDirectionArrow", "CrossroadsRouteStack", "CrossroadsBollardLumen"},
        Midground = {"CrossroadsTransitCornice", "CrossroadsRouteBridge", "CrossroadsLaneBeacon"},
    },
    Orbital = {
        Service = {"OrbitalCanisterCollar", "OrbitalMagneticClamp", "OrbitalChargeBand"},
        Midground = {"OrbitalRadialSpine", "OrbitalSolarFin", "OrbitalTelemetryNode"},
    },
}

function ArenaDetailKit.names(variant, role)
    local byArena = MOTIFS[variant]
    return byArena and byArena[role] or nil
end

function ArenaDetailKit.count(tier)
    if tier == "Low" then return 1 end
    if tier == "High" then return 3 end
    return 2
end

local function add(parent, name, source, size, offset, rotation, color, material, transparency, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = source.CFrame * CFrame.new(offset)
        * (rotation or CFrame.identity)
    part.Color = color
    part.Material = material
    part.Transparency = transparency or 0
    if shape then
        part.Shape = shape
    end
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part:SetAttribute("ChaosVisualMotif", true)
    part.Parent = parent
    return part
end

-- The same world palette produces different physical silhouettes in each arena.
-- Base prop modules continue to own all lifecycle and cleanup.
function ArenaDetailKit.build(parent, role, variant, host, tier, theme)
    local names = ArenaDetailKit.names(variant, role)
    if not names or not host or not host:IsA("BasePart")
        or not theme or not parent
    then
        return {}
    end
    local sx, sy, sz = host.Size.X, host.Size.Y, host.Size.Z
    local count = ArenaDetailKit.count(tier)
    local pieces = {}
    local function piece(i, size, offset, rotation, color, material, transparency, shape)
        if i > count then return end
        table.insert(pieces, add(parent, names[i], host, size, offset, rotation,
            color, material, transparency, shape))
    end

    if role == "Service" then
        if variant == "Classic" then
            -- Lens shroud + engraved measurement rail + tracking fin.
            piece(1, Vector3.new(sx * 0.88, sy * 0.40, 0.19),
                Vector3.new(0, sy * 0.16, -sz * 0.50 - 0.16),
                nil, theme.Structure, Enum.Material.Metal, 0.03)
            piece(2, Vector3.new(sx * 0.72, 0.09, 0.12),
                Vector3.new(0, sy * 0.53, -sz * 0.28),
                nil, theme.Secondary, Enum.Material.Metal, 0.07)
            piece(3, Vector3.new(0.11, sy * 0.78, sz * 0.42),
                Vector3.new(-sx * 0.37, sy * 0.30, 0),
                CFrame.Angles(0, 0, math.rad(13)),
                theme.Detail, Enum.Material.DiamondPlate, 0.06)
        elseif variant == "Towers" then
            -- Maintenance access hatch with a separate locking mechanism.
            piece(1, Vector3.new(sx * 0.73, sy * 0.65, 0.14),
                Vector3.new(0, 0, -sz * 0.5 - 0.11),
                nil, theme.Detail, Enum.Material.DiamondPlate, 0.05)
            piece(2, Vector3.new(sx * 0.41, 0.14, 0.19),
                Vector3.new(0, sy * 0.12, -sz * 0.5 - 0.22),
                nil, theme.Secondary, Enum.Material.Metal, 0.05)
            piece(3, Vector3.new(0.41, 0.41, 0.15),
                Vector3.new(sx * 0.25, -sy * 0.19, -sz * 0.5 - 0.22),
                nil, theme.Accent, Enum.Material.Glass, 0.26, Enum.PartType.Ball)
        elseif variant == "Crossroads" then
            -- Wayfinding chevron; remains recognizable without light or color.
            piece(1, Vector3.new(sx * 0.81, sy * 0.43, 0.10),
                Vector3.new(0, sy * 0.10, -sz * 0.5 - 0.08),
                CFrame.Angles(0, 0, math.rad(30)),
                theme.Detail, Enum.Material.Metal, 0.04)
            piece(2, Vector3.new(sx * 0.82, 0.16, 0.12),
                Vector3.new(0, -sy * 0.18, -sz * 0.5 - 0.10),
                nil, theme.Secondary, Enum.Material.Metal, 0.10)
            piece(3, Vector3.new(0.20, 0.24, 0.12),
                Vector3.new(0, sy * 0.46, -sz * 0.5 - 0.09),
                nil, theme.Accent, Enum.Material.Neon, 0.22)
        elseif variant == "Orbital" then
            -- An outer restraint and magnetic clamp for each power cell.
            piece(1, Vector3.new(sx * 1.07, 0.22, sz * 1.07),
                Vector3.new(0, 0, 0),
                nil, theme.Detail, Enum.Material.Metal, 0.11)
            piece(2, Vector3.new(0.21, sy * 0.58, sz * 0.88),
                Vector3.new(sx * 0.46, 0, 0),
                CFrame.Angles(0, 0, math.rad(12)),
                theme.Secondary, Enum.Material.Metal, 0.16)
            piece(3, Vector3.new(sx * 1.12, 0.10, sz * 1.12),
                Vector3.new(0, sy * 0.29, 0),
                nil, theme.Accent, Enum.Material.Neon, 0.40)
        end
    elseif role == "Midground" then
        if variant == "Classic" then
            -- Broadcast truss silhouette, exterior joint, luminous aperture.
            piece(1, Vector3.new(sx * 0.83, 0.40, 0.35),
                Vector3.new(0, sy * 0.24, -sz * 0.5 - 0.21),
                CFrame.Angles(0, 0, math.rad(18)),
                theme.Detail, Enum.Material.Metal, 0.10)
            piece(2, Vector3.new(0.52, sy * 0.75, 0.31),
                Vector3.new(sx * 0.34, 0, -sz * 0.5 - 0.17),
                nil, theme.Structure, Enum.Material.DiamondPlate, 0.13)
            piece(3, Vector3.new(sx * 0.26, sy * 0.11, 0.10),
                Vector3.new(-sx * 0.29, sy * 0.34, -sz * 0.5 - 0.19),
                nil, theme.Accent, Enum.Material.Glass, 0.35)
        elseif variant == "Towers" then
            -- Exterior cooling grille with long vertical negative space.
            piece(1, Vector3.new(sx * 0.48, sy * 0.67, 0.34),
                Vector3.new(0, 0, -sz * 0.5 - 0.20),
                nil, theme.Detail, Enum.Material.Metal, 0.12)
            piece(2, Vector3.new(sx * 0.67, 0.38, 0.28),
                Vector3.new(0, sy * 0.31, -sz * 0.5 - 0.26),
                nil, theme.Secondary, Enum.Material.Metal, 0.08)
            piece(3, Vector3.new(sx * 0.12, 0.35, 0.18),
                Vector3.new(sx * 0.24, sy * 0.44, -sz * 0.5 - 0.29),
                nil, theme.Accent, Enum.Material.Neon, 0.32)
        elseif variant == "Crossroads" then
            -- Bold transit roofline and a short elevated directional spine.
            piece(1, Vector3.new(sx * 0.85, 0.38, sz * 0.30),
                Vector3.new(0, sy * 0.5 + 0.16, -sz * 0.22),
                nil, theme.Detail, Enum.Material.Metal, 0.08)
            piece(2, Vector3.new(sx * 0.62, 0.24, 0.32),
                Vector3.new(0, sy * 0.5 + 0.44, -sz * 0.19),
                CFrame.Angles(0, 0, math.rad(8)),
                theme.Secondary, Enum.Material.Metal, 0.09)
            piece(3, Vector3.new(sx * 0.24, 0.20, 0.20),
                Vector3.new(sx * 0.22, sy * 0.5 + 0.61, -sz * 0.15),
                nil, theme.Accent, Enum.Material.Neon, 0.42)
        elseif variant == "Orbital" then
            -- Orbital panels offset the existing planetary sphere silhouette.
            piece(1, Vector3.new(sx * 0.78, sy * 0.17, 0.24),
                Vector3.new(0, sy * 0.24, -sz * 0.48),
                CFrame.Angles(0, 0, math.rad(29)),
                theme.Detail, Enum.Material.Metal, 0.14)
            piece(2, Vector3.new(sx * 0.64, sy * 0.24, 0.17),
                Vector3.new(0, -sy * 0.26, -sz * 0.49),
                CFrame.Angles(0, 0, math.rad(-25)),
                theme.Secondary, Enum.Material.Glass, 0.28)
            piece(3, Vector3.new(sx * 0.21, sy * 0.21, 0.19),
                Vector3.new(0, 0, -sz * 0.51),
                nil, theme.Accent, Enum.Material.Neon, 0.38)
        end
    end
    return pieces
end

return ArenaDetailKit
