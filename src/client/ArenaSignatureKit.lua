-- Four arena-specific kinetic hero props, built from Roblox primitives.
-- Cosmetic only: every part is anchored, non-colliding and local to this client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Load the theme only during construction; isolated Open Cloud unit tests
-- inject the identical shared palette to avoid missing replicated scripts.
local VisualTheme = nil

local ArenaSignatureKit = {}

local PROFILES = {
    Low = {Segments = 6, Layers = 1, Detail = false, Interval = 0.22, MaxParts = 22},
    Medium = {Segments = 9, Layers = 1, Detail = true, Interval = 0.13, MaxParts = 32},
    High = {Segments = 12, Layers = 2, Detail = true, Interval = 0.09, MaxParts = 50},
}

function ArenaSignatureKit.profile(tier)
    return PROFILES[tier] or PROFILES.Medium
end

local function add(bundle, name, size, cf, color, material, transparency, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = material or Enum.Material.Metal
    p.Transparency = transparency or 0
    p.Color = color
    if shape then
        p.Shape = shape
    end
    p.Parent = bundle.folder
    table.insert(bundle.parts, p)
    return p
end

local function moving(bundle, part, role, cf, index)
    table.insert(bundle.animated, {
        part = part,
        role = role,
        frame = cf,
        index = index or 1,
        color = part.Color,
        transparency = part.Transparency,
    })
    return part
end

local function labelOn(bundle, baseCF, accent, text)
    local plate = add(bundle, "SignatureIdentityPanel",
        Vector3.new(6.8, 0.55, 0.13),
        baseCF * CFrame.new(0, 2.65, 4.10), 
        VisualTheme.World.Deep, Enum.Material.Metal, 0.08)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "SignatureMark"
    gui.Face = Enum.NormalId.Back
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 22
    gui.LightInfluence = 0
    gui.Parent = plate
    local title = Instance.new("TextLabel")
    title.Name = "MarkLabel"
    title.Size = UDim2.fromScale(1, 1)
    title.BackgroundTransparency = 1
    title.Text = text
    title.Font = Enum.Font.GothamBlack
    title.TextScaled = true
    title.TextColor3 = accent
    title.Parent = gui
end

local function classic(bundle, cf, theme, profile)
    local accent = theme.Accent
    add(bundle, "ClassicRadarMast", Vector3.new(0.50, 7.7, 0.50),
        cf * CFrame.new(0, 4.15, 0), theme.Structure, Enum.Material.Metal)
    local hubFrame = cf * CFrame.new(0, 7.9, 0)
    add(bundle, "ClassicRadarHub", Vector3.new(1.3, 0.8, 1.3),
        hubFrame, theme.Detail, Enum.Material.Metal, 0.08, Enum.PartType.Ball)
    local sweep = add(bundle, "ClassicRadarSweep",
        Vector3.new(6.0, 0.15, 0.26),
        hubFrame, accent, Enum.Material.Neon, 0.16)
    moving(bundle, sweep, "radar", hubFrame, 1)
    local sweep2 = add(bundle, "ClassicRadarCross",
        Vector3.new(0.19, 0.15, 4.2),
        hubFrame, theme.Secondary, Enum.Material.Neon, 0.26)
    moving(bundle, sweep2, "radar", hubFrame, 2)
    add(bundle, "ClassicRadarAntenna", Vector3.new(0.22, 2.0, 0.22),
        cf * CFrame.new(0, 9.55, 0), theme.Detail, Enum.Material.Metal)
    if profile.Detail then
        for i = -1, 1, 2 do
            add(bundle, "ClassicSignalDish" .. i, Vector3.new(1.6, 0.16, 1.6),
                cf * CFrame.new(i * 2.2, 6.5, -0.6)
                    * CFrame.Angles(0, 0, math.rad(i * 20)),
                theme.Secondary, Enum.Material.Glass, 0.25, Enum.PartType.Cylinder)
        end
    end
end

local function towers(bundle, cf, theme, profile)
    for side = -1, 1, 2 do
        add(bundle, "TowerLiftRail" .. side,
            Vector3.new(0.35, 11.8, 0.4),
            cf * CFrame.new(side * 2.0, 6.45, 0),
            theme.Structure, Enum.Material.Metal, 0.04)
        add(bundle, "TowerLiftBeacon" .. side,
            Vector3.new(0.60, 0.55, 0.6),
            cf * CFrame.new(side * 2.0, 12.45, 0),
            theme.Accent, Enum.Material.Neon, 0.20)
    end
    add(bundle, "TowerStationCrown", Vector3.new(5.6, 0.4, 2.4),
        cf * CFrame.new(0, 12.0, 0),
        theme.Detail, Enum.Material.Metal)
    local liftCF = cf * CFrame.new(0, 5.2, 0)
    local cabin = add(bundle, "TowerAnimatedLift",
        Vector3.new(3.7, 1.8, 2.3), liftCF,
        theme.Structure, Enum.Material.Metal, 0.20)
    moving(bundle, cabin, "elevator", liftCF, 1)
    local edgeCF = liftCF * CFrame.new(0, 0.91, 1.12)
    local strip = add(bundle, "TowerLiftGuide",
        Vector3.new(3.3, 0.10, 0.09),
        edgeCF, theme.Accent, Enum.Material.Neon, 0.12)
    moving(bundle, strip, "elevator", edgeCF, 1)
    if profile.Detail then
        local serviceCF = cf * CFrame.new(0, 1.9, -1.8)
        add(bundle, "TowerServiceCabinet", Vector3.new(2.1, 2.6, 1.15),
            serviceCF, VisualTheme.World.SurfaceRaised, Enum.Material.DiamondPlate)
    end
end

local function crossroads(bundle, cf, theme, profile)
    for side = -1, 1, 2 do
        add(bundle, "CrossroadSignMast" .. side,
            Vector3.new(0.35, 7.5, 0.35),
            cf * CFrame.new(side * 3.1, 4.05, 0),
            theme.Structure, Enum.Material.Metal)
    end
    add(bundle, "CrossroadSignHeader", Vector3.new(7.8, 0.55, 1.3),
        cf * CFrame.new(0, 7.75, 0), theme.Detail, Enum.Material.Metal)
    for i = 1, 4 do
        local signCF = cf * CFrame.new((i - 2.5) * 1.65, 6.3, 0.65)
        local sign = add(bundle, "CrossroadAnimatedSignal" .. i,
            Vector3.new(1.35, 1.0, 0.18),
            signCF, i % 2 == 0 and theme.Accent or theme.Secondary,
            Enum.Material.Neon, 0.34)
        moving(bundle, sign, "signal", signCF, i)
    end
    if profile.Detail then
        for i = 1, 2 do
            add(bundle, "CrossroadWayfinder" .. i,
                Vector3.new(2.5, 0.20, 0.8),
                cf * CFrame.new(i == 1 and -1.5 or 1.5, 4.3, 0.6),
                theme.Detail, Enum.Material.Glass, 0.27)
        end
    end
end

local function orbital(bundle, cf, theme, profile)
    local heartCF = cf * CFrame.new(0, 6.3, 0)
    local core = add(bundle, "OrbitalGyroscopeHeart",
        Vector3.new(2.25, 2.25, 2.25),
        heartCF, theme.Accent, Enum.Material.Glass, 0.18, Enum.PartType.Ball)
    moving(bundle, core, "heart", heartCF, 1)
    for layer = 1, profile.Layers do
        local radius = layer == 1 and 3.6 or 4.5
        for i = 1, profile.Segments do
            local angle = (i - 1) * math.pi * 2 / profile.Segments
            local frame = CFrame.new(
                math.cos(angle) * radius,
                math.sin(angle) * radius,
                0
            ) * CFrame.Angles(0, 0, angle + math.pi * 0.5)
            local pieceCF = heartCF * frame
            local segment = add(bundle,
                "OrbitalGyroscopeRing" .. layer .. "_" .. i,
                Vector3.new(2 * math.pi * radius / profile.Segments * 0.78, 0.13, 0.18),
                pieceCF, layer == 1 and theme.Accent or theme.Secondary,
                Enum.Material.Neon, 0.21)
            moving(bundle, segment, "ring", heartCF, layer == 1 and i or -i)
            bundle.animated[#bundle.animated].localFrame = frame
        end
    end
    if profile.Detail then
        add(bundle, "OrbitalGyroscopeAnchor",
            Vector3.new(1.2, 2.8, 1.2),
            cf * CFrame.new(0, 1.65, 0), theme.Detail, Enum.Material.Metal, 0.15)
    end
end

-- Large-scale signature silhouettes instead of undifferentiated neon bars.
-- All pieces stay anchored, non-colliding, and under the per-tier part cap.
-- Geometry is built once; the existing animation loop only moves key actors.
local function craftSignature(bundle, cf, theme, profile, variant)
    local metal = theme.Structure
    local trim = theme.Detail

    if variant == "Classic" then
        -- A continuous faceted goniometer halo reads as a radar at a distance.
        local hub = cf * CFrame.new(0, 7.9, -0.18)
        local radius = 3.65
        for i = 1, profile.Segments do
            local angle = (i - 1) * math.pi * 2 / profile.Segments
            add(bundle, "ClassicGoniometerArc" .. i,
                Vector3.new(2 * math.pi * radius / profile.Segments * 0.84, 0.19, 0.29),
                hub * CFrame.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
                    * CFrame.Angles(0, 0, angle + math.pi * 0.5),
                i % 3 == 0 and theme.Accent or trim,
                i % 3 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                i % 3 == 0 and 0.28 or 0.05)
        end
        for side = -1, 1, 2 do
            add(bundle, "ClassicCounterbrace" .. side,
                Vector3.new(0.24, 5.3, 0.34),
                cf * CFrame.new(side * 1.65, 3.3, 0.14)
                    * CFrame.Angles(0, 0, math.rad(side * 20)),
                metal, Enum.Material.DiamondPlate, 0.03)
        end

    elseif variant == "Towers" then
        -- Two continuous segmented load paths make the lift read as industrial
        -- infrastructure rather than a floating cuboid.
        for side = -1, 1, 2 do
            for level = 1, 2 do
                add(bundle, "TowerTensionTruss" .. side .. "_" .. level,
                    Vector3.new(0.24, 4.8, 0.30),
                    cf * CFrame.new(side * 2.76, 3.5 + level * 2.8, -0.1)
                        * CFrame.Angles(0, 0, math.rad(side * (level == 1 and -18 or 18))),
                    metal, Enum.Material.Metal, 0.08)
            end
            add(bundle, "TowerCounterweight" .. side,
                Vector3.new(0.88, 2.35, 1.02),
                cf * CFrame.new(side * 3.08, 8.6, -0.45),
                trim, Enum.Material.DiamondPlate, 0.10)
            add(bundle, "TowerRailMarker" .. side,
                Vector3.new(0.22, 2.2, 0.12),
                cf * CFrame.new(side * 2.05, 8.9, 0.28),
                theme.Accent, Enum.Material.Neon, 0.25)
        end

    elseif variant == "Crossroads" then
        -- Interlocking multi-level wayfinder fins echo transit lanes.
        for side = -1, 1, 2 do
            for i = 1, 3 do
                add(bundle, "CrossroadRouteChevron" .. side .. "_" .. i,
                    Vector3.new(2.3, 0.20, 0.30),
                    cf * CFrame.new(side * (1.18 + i * 0.62), 3.4 + i * 0.83, 1.15)
                        * CFrame.Angles(0, 0, math.rad(side * 30)),
                    i == 3 and theme.Accent or (i == 2 and theme.Secondary or trim),
                    i == 3 and Enum.Material.Neon or Enum.Material.Metal,
                    i == 3 and 0.23 or 0.05)
            end
            add(bundle, "CrossroadGantryCorner" .. side,
                Vector3.new(0.27, 2.4, 0.38),
                cf * CFrame.new(side * 3.7, 6.3, 0.12)
                    * CFrame.Angles(0, 0, math.rad(side * 31)),
                metal, Enum.Material.DiamondPlate, 0.06)
        end

    elseif variant == "Orbital" then
        -- Four grounded field pylons frame a floating gyroscope; dense geometry
        -- stays only in the core, preserving a powerful Low-quality silhouette.
        for i = 1, 4 do
            local angle = (i - 1) * math.pi * 0.5
            local x = math.cos(angle) * 3.25
            local z = math.sin(angle) * 3.25
            add(bundle, "OrbitalContainmentPylon" .. i,
                Vector3.new(0.60, 3.2, 0.60),
                cf * CFrame.new(x, 2.13, z)
                    * CFrame.Angles(0, angle, math.rad(17)),
                metal, Enum.Material.Metal, 0.11)
            add(bundle, "OrbitalContainmentPrism" .. i,
                Vector3.new(0.78, 1.05, 0.78),
                cf * CFrame.new(x, 4.07, z)
                    * CFrame.Angles(0, angle, math.rad(22)),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Glass, 0.24)
        end
        add(bundle, "OrbitalContainmentShell",
            Vector3.new(3.0, 3.0, 3.0),
            cf * CFrame.new(0, 6.3, 0), trim,
            Enum.Material.Glass, 0.76, Enum.PartType.Ball)
    end
end

function ArenaSignatureKit.build(parent, arenaBase, variant, tierName, themeOverride)
    VisualTheme = themeOverride or VisualTheme
        or require(ReplicatedStorage.Shared.VisualTheme)
    assert(arenaBase and arenaBase:IsA("BasePart"), "Arena signature needs an arena base")
    local profile = ArenaSignatureKit.profile(tierName)
    local theme = VisualTheme.arena(variant)
    local folder = Instance.new("Folder")
    folder.Name = "ArenaSignatureSet"
    folder.Parent = parent
    local cf = arenaBase.CFrame * CFrame.new(
        -arenaBase.Size.X * 0.5 - 8,
        arenaBase.Size.Y * 0.5 + 0.7,
        -arenaBase.Size.Z * 0.5 + 13
    )
    local bundle = {
        folder = folder,
        variant = variant,
        tier = tierName,
        profile = profile,
        parts = {},
        animated = {},
    }
    add(bundle, "SignatureFoundation", Vector3.new(9.4, 0.7, 9.4),
        cf, theme.Structure, Enum.Material.Metal)
    add(bundle, "SignatureFoundationLight", Vector3.new(8.6, 0.10, 8.6),
        cf * CFrame.new(0, 0.39, 0),
        theme.Accent, Enum.Material.Neon, 0.55)
    labelOn(bundle, cf, theme.Accent, 
        variant == "Towers" and "LIFT SYSTEM" or (
            variant == "Crossroads" and "TRANSIT CTRL" or (
                variant == "Orbital" and "REACTOR CORE" or "RADAR ARRAY"
            )
        )
    )
    if variant == "Towers" then
        towers(bundle, cf, theme, profile)
    elseif variant == "Crossroads" then
        crossroads(bundle, cf, theme, profile)
    elseif variant == "Orbital" then
        orbital(bundle, cf, theme, profile)
    else
        classic(bundle, cf, theme, profile)
    end

    craftSignature(bundle, cf, theme, profile, variant)
    assert(#bundle.parts <= profile.MaxParts,
        "Arena signature exceeded the visual part budget for " .. tostring(variant))

    if tierName == "High" then
        local light = Instance.new("PointLight")
        light.Name = "ArenaSignatureAccent"
        light.Color = theme.Accent
        light.Brightness = 0.62
        light.Range = 13
        light.Shadows = false
        light.Parent = bundle.parts[2]
    end
    return bundle
end

function ArenaSignatureKit.update(bundle, elapsed, reduceMotion)
    if not bundle or not bundle.folder.Parent then
        return
    end
    local now = reduceMotion == true and 0 or (tonumber(elapsed) or 0)
    for _, entry in ipairs(bundle.animated) do
        local p = entry.part
        if p.Parent then
            if entry.role == "radar" then
                p.CFrame = entry.frame * CFrame.Angles(0, now * 0.47, 0)
            elseif entry.role == "elevator" then
                p.CFrame = entry.frame * CFrame.new(0, math.sin(now * 0.64) * 2.0, 0)
            elseif entry.role == "signal" then
                local pulse = reduceMotion and 0.5
                    or (math.sin(now * 2.5 + entry.index * 1.45) + 1) * 0.5
                p.Transparency = 0.48 - pulse * 0.30
                p.Color = entry.color:Lerp(Color3.new(1, 1, 1), pulse * 0.18)
            elseif entry.role == "heart" then
                local sizeScale = 1 + math.sin(now * 1.5) * 0.045
                p.Size = Vector3.new(2.25, 2.25, 2.25) * sizeScale
            elseif entry.role == "ring" then
                local reverse = entry.index < 0
                local spin = now * (reverse and -0.22 or 0.32)
                p.CFrame = entry.frame
                    * CFrame.Angles(now * 0.10, spin, now * 0.14)
                    * entry.localFrame
            end
        end
    end
end

return ArenaSignatureKit
