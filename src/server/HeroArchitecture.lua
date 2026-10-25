--!strict
-- Original, lightweight 3D skyline art. No remote assets, physics, lights or VFX.
-- One authored hero object per arena, placed outside all real survival paths.
local HeroArchitecture = {}
local TWO_PI = math.pi * 2
local function add(model, origin, name, kind, size, cf, color)
    local p = Instance.new(kind or "Part")
    p.Name = name
    p.Size = size
    p.CFrame = origin * cf
    p.Color = color
    p.Material = Enum.Material.Metal
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = model
    return p
end
local function bar(model, origin, name, a, b, thickness, color)
    local direction = b - a
    return add(model, origin, name, "Part",
        Vector3.new(thickness, direction.Magnitude, thickness),
        CFrame.lookAt((a + b) * 0.5, b) * CFrame.Angles(math.pi / 2, 0, 0),
        color)
end

function HeroArchitecture.build(decor, base, variantId, theme)
    if not decor or not base or not base:IsA("BasePart") then return nil end
    local model = Instance.new("Model")
    model.Name = "ArenaHeroArchitecture3D"
    model:SetAttribute("ChaosDistantScenery", true)
    model:SetAttribute("SignatureVariant", variantId)
    model:SetAttribute("SourceIsOriginal", true)

    -- The largest part/ring has a conservative radius under 22 studs.
    -- A 68-stud eastward stand-off cannot obstruct shrinking arena,
    -- parkour, spawns, kill planes or physics even as scenery streams in.
    local origin = CFrame.new(
        base.Position.X + base.Size.X * 0.5 + 68,
        base.Position.Y + base.Size.Y * 0.5,
        base.Position.Z + base.Size.Z * 0.22
    )
    local dark = theme.Structure:Lerp(Color3.fromRGB(14, 20, 29), 0.32)
    local metal = theme.Detail:Lerp(theme.Structure, 0.40)
    local trim = theme.Accent:Lerp(theme.Structure, 0.67)
    local shadow = dark:Lerp(Color3.fromRGB(6, 10, 15), 0.35)
    local function piece(name, size, position, color)
        return add(model, origin, name, "Part", size, CFrame.new(position),
            color or dark)
    end
    local function beam(name, a, b, thickness, color)
        return bar(model, origin, name, a, b, thickness, color or metal)
    end
    local function halo(prefix, y, radius, sides, depth)
        for i = 0, sides - 1 do
            local first = TWO_PI * i / sides
            local second = TWO_PI * (i + 1) / sides
            beam(prefix .. tostring(i + 1),
                Vector3.new(depth, y + math.cos(first) * radius,
                    math.sin(first) * radius),
                Vector3.new(depth, y + math.cos(second) * radius,
                    math.sin(second) * radius),
                0.66, metal)
        end
    end

    if variantId == "Classic" then
        -- Observatory: actual three-dimensional tripod, 12-sided
        -- receiver ring, inset hub and mast, not a glowing flat sign.
        piece("ObservatoryFoundation", Vector3.new(17, 1.8, 15),
            Vector3.new(0, 0.9, 0))
        piece("CentralPylon", Vector3.new(5.8, 25, 5.8),
            Vector3.new(0, 13, 0), metal)
        piece("RecessedControl", Vector3.new(5, 5, 5),
            Vector3.new(0, 19.5, -3.3), shadow)
        beam("TripodEast", Vector3.new(7, 1.9, 4),
            Vector3.new(0, 16, 0), 1.05)
        beam("TripodWest", Vector3.new(-7, 1.9, 4),
            Vector3.new(0, 16, 0), 1.05)
        beam("TripodRear", Vector3.new(0, 1.9, -6.4),
            Vector3.new(0, 16, 0), 1.05)
        halo("StormDishArc", 26, 6.5, 12, -0.7)
        piece("DishHub", Vector3.new(4.3, 4.3, 4.3),
            Vector3.new(0, 26, 0), trim)
        piece("LightningRod", Vector3.new(0.55, 7.2, 0.55),
            Vector3.new(0, 35.1, 0), metal)
        piece("SensorTip", Vector3.new(1.1, 1.1, 1.1),
            Vector3.new(0, 39.1, 0), trim)
    elseif variantId == "Towers" then
        -- Suspension gantry with a long canopy and TWO genuine hanging
        -- transit cabins; no playable collision or mobile per-frame work.
        piece("TransitFoundation", Vector3.new(30, 1.8, 15),
            Vector3.new(0, 0.9, 0))
        for side = -1, 1, 2 do
            local x = side * 11.6
            beam("GantryLegA" .. tostring(side),
                Vector3.new(x - 2.7, 1.8, -3.3),
                Vector3.new(x, 25, 0), 1.15)
            beam("GantryLegB" .. tostring(side),
                Vector3.new(x + 2.7, 1.8, 3.3),
                Vector3.new(x, 25, 0), 1.15)
            piece("GantryJoint" .. tostring(side),
                Vector3.new(3.1, 3.1, 3.1),
                Vector3.new(x, 25, 0), metal)
        end
        piece("SkyTransitMainBeam", Vector3.new(29, 2.2, 4.8),
            Vector3.new(0, 25.6, 0), metal)
        piece("SkyTransitOverhang", Vector3.new(34, 0.8, 5.4),
            Vector3.new(1, 27.1, 0))
        -- A tall crown visually separates Towers from a squat factory
        -- gantry and makes the skyline unmistakable even on a phone.
        piece("SkyTransitSignalCrown", Vector3.new(1.0, 8, 1.0),
            Vector3.new(0, 31.0, 0), trim)
        for i = -2, 2 do
            beam("CanopyTruss" .. tostring(i),
                Vector3.new(i * 5.3, 25.8, -2),
                Vector3.new(i * 5.3 + 3, 27.5, 2), 0.31)
        end
        for side = -1, 1, 2 do
            local x = side * 6.8
            beam("SuspensionCable" .. tostring(side),
                Vector3.new(x, 24.1, 0),
                Vector3.new(x, 15, 0), 0.22, shadow)
            piece("SuspendedTransitCabin" .. tostring(side),
                Vector3.new(6.4, 3.7, 4),
                Vector3.new(x, 13, 0))
            piece("CabinWindow" .. tostring(side),
                Vector3.new(5.3, 1.25, 0.13),
                Vector3.new(x, 13.4, -2.08), trim)
        end
    elseif variantId == "Crossroads" then
        -- Four-way exchange with a raised routing hub, shoring and a
        -- distinctive offset stack, not a repeated cylindrical skyline.
        piece("SwitchyardFoundation", Vector3.new(24, 1.8, 21),
            Vector3.new(0, 0.9, 0))
        piece("ExchangeCore", Vector3.new(9, 19, 9),
            Vector3.new(0, 10.5, 0), shadow)
        piece("NorthConduit", Vector3.new(4.5, 2, 24),
            Vector3.new(0, 19.2, 0), metal)
        piece("EastConduit", Vector3.new(28, 2, 4.5),
            Vector3.new(0, 22.2, 0))
        for i = 0, 3 do
            local a = TWO_PI * i / 4
            local dx, dz = math.cos(a) * 9, math.sin(a) * 9
            beam("RadialShoring" .. tostring(i + 1),
                Vector3.new(dx * 1.42, 1.8, dz * 1.42),
                Vector3.new(dx * 0.55, 18.5, dz * 0.55), 0.98)
            piece("ExchangeCoupler" .. tostring(i + 1),
                Vector3.new(3.6, 2.2, 3.6),
                Vector3.new(dx, 22.6, dz), metal)
        end
        piece("DataTower", Vector3.new(3.8, 12, 3.8),
            Vector3.new(0, 29, 0))
        for side = -1, 1, 2 do
            piece("SwitchAntenna" .. tostring(side),
                Vector3.new(0.4, 5.2, 0.4),
                Vector3.new(side * 2.3, 37.2, 0), trim)
            piece("ExchangeShroud" .. tostring(side),
                Vector3.new(2.1, 8.4, 2.1),
                Vector3.new(side * 4.1, 13, 0), metal)
        end
    else
        -- Reactor array: two concentric, genuinely 3D segmented orbital
        -- rings plus braced pylons, central core and an inset lens.
        piece("MagneticPlatform", Vector3.new(16, 2, 16),
            Vector3.new(0, 1, 0))
        piece("ReactorFoot", Vector3.new(9.5, 10, 8),
            Vector3.new(0, 7, 0), shadow)
        piece("ReactorUpperMantle", Vector3.new(5.8, 8, 6.2),
            Vector3.new(0, 16, 0), metal)
        halo("OrbitalOuterArc", 24, 12, 12, 0)
        halo("OrbitalInnerArc", 24, 8.6, 10, -1.8)
        piece("HaloLens", Vector3.new(4.9, 4.9, 4.9),
            Vector3.new(0, 24, -2.2), trim)
        for side = -1, 1, 2 do
            beam("RadialStabilizer" .. tostring(side),
                Vector3.new(0, 2, side * 6),
                Vector3.new(0, 19.4, side * 7.2), 0.76)
        end
    end
    local pieces = #model:GetChildren()
    assert(pieces >= 14 and pieces <= 32,
        "Hero 3D art exceeds guarded Android part budget")
    model:SetAttribute("HeroArchitectureParts", pieces)
    model.Parent = decor
    return model
end

return HeroArchitecture
