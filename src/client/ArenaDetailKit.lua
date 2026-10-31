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
    Harbor = {
        -- Large ship forms, not stickers on freight blocks.
        Midground = {"HarborBowTaper", "HarborAftDeckhouse", "HarborLoadBoom"},
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

local function add(parent, name, source, size, offset, rotation, color, material, transparency, shape, kind)
    local part = Instance.new(kind or "Part")
    part.Name = name
    part.Size = size
    part.CFrame = source.CFrame * CFrame.new(offset)
        * (rotation or CFrame.identity)
    part.Color = color
    part.Material = material
    part.Transparency = transparency or 0
    if shape and part:IsA("Part") then
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
    local function piece(i, size, offset, rotation, color, material, transparency, shape, kind)
        if i > count then return end
        table.insert(pieces, add(parent, names[i], host, size, offset, rotation,
            color, material, transparency, shape, kind))
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
        -- Structural silhouettes replace ornamental strips. Low receives
        -- one prominent macro feature per distant building; Medium gets
        -- its supporting mass; High gets one final service-scale accent.
        -- These are static, local, noncolliding pieces on existing hosts.
        if variant == "Classic" then
            -- The broadcast installation finally reads as a radar station:
            -- a rooftop receiver mast, braced crossarm and physical sensor.
            piece(1, Vector3.new(1.15, sy * 1.35, 1.15),
                Vector3.new(0, sy * 1.05, 0),
                CFrame.Angles(0, 0, math.rad(8)),
                theme.Structure, Enum.Material.CorrodedMetal, 0.04)
            piece(2, Vector3.new(sx * 0.84, 0.62, 1.05),
                Vector3.new(0, sy * 1.52, 0),
                CFrame.Angles(0, math.rad(12), 0),
                theme.Detail, Enum.Material.Metal, 0.04)
            piece(3, Vector3.new(2.2, 2.2, 2.2),
                Vector3.new(0, sy * 1.67, -0.2),
                nil, theme.Accent:Lerp(theme.Structure, 0.55),
                Enum.Material.Glass, 0.14, Enum.PartType.Ball)
        elseif variant == "Towers" then
            -- Real rooftop cooling stacks form the tall industrial skyline.
            -- The machined cap and exposed manifold sit on their own mass.
            piece(1, Vector3.new(sx * 0.74, sy * 0.73, sz * 0.76),
                Vector3.new(sx * 0.12, sy * 0.79, 0),
                CFrame.Angles(0, math.rad(12), 0),
                theme.Structure:Lerp(theme.Detail, 0.22),
                Enum.Material.CorrodedMetal, 0.04)
            piece(2, Vector3.new(sx * 0.88, sy * 0.10, sz * 0.88),
                Vector3.new(sx * 0.12, sy * 1.19, 0),
                nil, theme.Detail, Enum.Material.DiamondPlate, 0.04)
            piece(3, Vector3.new(sx * 0.34, sy * 0.15, sz * 0.36),
                Vector3.new(sx * 0.12, sy * 1.34, 0),
                nil, theme.Secondary:Lerp(theme.Structure, 0.55),
                Enum.Material.Metal, 0.04)
        elseif variant == "Crossroads" then
            -- Oversailing transit head + the actual equipment housing:
            -- horizontal massing instead of one more tiny route arrow.
            piece(1, Vector3.new(sx * 1.23, math.max(0.88, sy * 0.22), sz * 0.52),
                Vector3.new(0, sy * 0.66, 0),
                nil, theme.Detail, Enum.Material.CorrodedMetal, 0.05)
            piece(2, Vector3.new(sx * 0.35, math.max(2.4, sy * 0.67), sz * 0.54),
                Vector3.new(-sx * 0.23, sy * 1.05, 0),
                nil, theme.Structure, Enum.Material.Concrete, 0.03)
            piece(3, Vector3.new(sx * 0.67, 0.54, sz * 0.48),
                Vector3.new(sx * 0.15, sy * 1.43, 0),
                CFrame.Angles(0, math.rad(-8), 0),
                theme.Secondary:Lerp(theme.Structure, 0.68),
                Enum.Material.Metal, 0.07)
        elseif variant == "Orbital" then
            -- Two articulated solar-fin wings and the central service hub
            -- break up a remote spherical shell without using neon rings.
            piece(1, Vector3.new(sx * 0.18, sy * 1.22, sz * 0.95),
                Vector3.new(sx * 0.78, 0, 0),
                CFrame.Angles(0, math.rad(16), math.rad(20)),
                theme.Detail, Enum.Material.CeramicTiles, 0.06)
            piece(2, Vector3.new(sx * 0.18, sy * 1.22, sz * 0.95),
                Vector3.new(-sx * 0.78, 0, 0),
                CFrame.Angles(0, math.rad(-16), math.rad(-20)),
                theme.Detail, Enum.Material.CeramicTiles, 0.06)
            piece(3, Vector3.new(sx * 0.32, sy * 0.32, sz * 0.32),
                Vector3.new(0, 0, -sz * 0.54),
                nil, theme.Accent:Lerp(theme.Structure, 0.53),
                Enum.Material.Metal, 0.05, Enum.PartType.Ball)
        elseif variant == "Harbor" then
            -- Off-map freight barges need an actual tapered prow, aft
            -- wheelhouse and load-boom silhouette, not a third metal box.
            -- WedgePart is Roblox-native geometry; no new MeshPart/asset ID.
            piece(1, Vector3.new(sx * 0.30, sy * 0.94, sz * 0.92),
                Vector3.new(sx * 0.61, -0.05, 0),
                CFrame.Angles(0, math.rad(90), 0),
                theme.Structure, Enum.Material.CorrodedMetal, 0.04,
                nil, "WedgePart")
            piece(2, Vector3.new(sx * 0.23, sy * 1.72, sz * 0.55),
                Vector3.new(-sx * 0.39, sy * 1.05, 0),
                nil, theme.Detail:Lerp(theme.Structure, 0.55),
                Enum.Material.CorrodedMetal, 0.03)
            piece(3, Vector3.new(sx * 0.63, math.max(0.45, sy * 0.21), sz * 0.18),
                Vector3.new(-sx * 0.17, sy * 1.92, 0),
                nil, theme.Detail, Enum.Material.Metal, 0.04)
        end
    end
    return pieces
end

return ArenaDetailKit
