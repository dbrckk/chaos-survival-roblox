-- Chaos Signal: minimal, recognizable platform detailing on moving geometry.
-- Decorative welds follow the authoritative platform without collisions.
-- No custom asset IDs, dynamic emitters, scripted physics or animation loops.
local PlatformFinishKit = {}

local NAMES = {
    Classic = {"ClassicCalibrationPlate", "ClassicDatumTick", "ClassicArmoredLip"},
    Towers = {"TowerHoistMount", "TowerGuideBracket", "TowerMaintenanceMark"},
    Crossroads = {"CrossroadsRouteChevron", "CrossroadsTrafficBranch", "CrossroadsDirectionStud"},
    Orbital = {"OrbitalFluxSpine", "OrbitalMagnetGuide", "OrbitalTelemetryEye"},
}

function PlatformFinishKit.names(variant)
    return NAMES[variant]
end

function PlatformFinishKit.count(tier)
    if tier == "Low" then return 1 end
    if tier == "High" then return 3 end
    return 2
end

local function add(parent, platform, name, localFrame, size, color, material, alpha, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = platform.CFrame * localFrame
    part.Color = color
    part.Material = material
    part.Transparency = alpha
    if shape then part.Shape = shape end
    part.Anchored = false
    part.Massless = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part:SetAttribute("ChaosPlatformTrim", true)
    part.Parent = parent

    local joint = Instance.new("WeldConstraint")
    joint.Name = "ChaosPlatformTrimWeld"
    joint.Part0 = part
    joint.Part1 = platform
    joint.Parent = part
    return part
end

function PlatformFinishKit.build(parent, platform, variant, tier, theme)
    local names = NAMES[variant]
    if not parent or not platform or not platform:IsA("BasePart")
        or not names or not theme
    then
        return {}
    end

    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    local top = sy * 0.5 + 0.055
    local count = PlatformFinishKit.count(tier)
    local built = {}
    local function piece(i, localFrame, size, color, material, alpha, shape)
        if i > count then return end
        table.insert(built, add(parent, platform, names[i], localFrame, size,
            color, material, alpha, shape))
    end

    if variant == "Classic" then
        -- Datum plate and instrument hashes communicate an engineered radar grid.
        piece(1, CFrame.new(-sx * 0.23, top, -sz * 0.26),
            Vector3.new(sx * 0.38, 0.026, 0.36),
            theme.Detail, Enum.Material.Metal, 0.24)
        piece(2, CFrame.new(-sx * 0.23, top + 0.015, -sz * 0.23),
            Vector3.new(0.12, 0.027, sz * 0.22),
            theme.Secondary, Enum.Material.Metal, 0.25)
        piece(3, CFrame.new(-sx * 0.43, -sy * 0.11, 0),
            Vector3.new(0.24, sy * 0.68, sz * 0.26),
            theme.Structure, Enum.Material.DiamondPlate, 0.08)

    elseif variant == "Towers" then
        -- Below-deck hoist cradle keeps the walking surface unobstructed.
        piece(1, CFrame.new(0, -sy * 0.5 - 0.16, 0),
            Vector3.new(sx * 0.58, 0.27, sz * 0.20),
            theme.Structure, Enum.Material.DiamondPlate, 0.10)
        piece(2, CFrame.new(sx * 0.36, -sy * 0.24, 0),
            Vector3.new(0.33, sy * 0.47, sz * 0.51),
            theme.Detail, Enum.Material.Metal, 0.11)
        piece(3, CFrame.new(0, -sy * 0.5 - 0.33, 0),
            Vector3.new(sx * 0.20, 0.10, sz * 0.23),
            theme.Accent, Enum.Material.Neon, 0.53)

    elseif variant == "Crossroads" then
        -- Routing chevrons, not free-floating light strips, direct the eye.
        piece(1, CFrame.new(-sx * 0.19, top, -sz * 0.13)
            * CFrame.Angles(0, math.rad(-34), 0),
            Vector3.new(sx * 0.40, 0.026, 0.29),
            theme.Detail, Enum.Material.Metal, 0.15)
        piece(2, CFrame.new(sx * 0.16, top + 0.005, sz * 0.13)
            * CFrame.Angles(0, math.rad(34), 0),
            Vector3.new(sx * 0.32, 0.027, 0.20),
            theme.Secondary, Enum.Material.Metal, 0.23)
        piece(3, CFrame.new(sx * 0.37, top + 0.015, sz * 0.33),
            Vector3.new(0.42, 0.028, 0.42),
            theme.Accent, Enum.Material.Glass, 0.48)

    elseif variant == "Orbital" then
        -- An arc-segment tangent to the route + a non-flashing telemetry lens.
        piece(1, CFrame.new(0, top, -sz * 0.29),
            Vector3.new(sx * 0.58, 0.028, 0.26),
            theme.Detail, Enum.Material.Metal, 0.12)
        piece(2, CFrame.new(0, top + 0.008, -sz * 0.21),
            Vector3.new(sx * 0.34, 0.027, 0.13),
            theme.Secondary, Enum.Material.Glass, 0.40)
        piece(3, CFrame.new(sx * 0.33, top + 0.017, -sz * 0.29),
            Vector3.new(0.39, 0.045, 0.39),
            theme.Accent, Enum.Material.Glass, 0.35, Enum.PartType.Ball)
    end

    return built
end

return PlatformFinishKit
