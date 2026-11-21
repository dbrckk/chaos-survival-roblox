local Workspace = game:GetService("Workspace")

local ArenaAtmosphereStyle = require("./ArenaAtmosphereStyle")
local ReactorAssets = require("./PremiumOrbitalReactorLandmarkAssets")
local ForgedBridgeAssets = require("./PremiumTowersSignatureBridgeAssets")
local LargeStructureAssets = require("./PremiumLargeStructureAssets")
local PerimeterArmorAssets = require("./PremiumPerimeterArmorAssets")
local RouteSignalGeometry = require("./RouteSignalGeometry")

local function makePart(parent, name, size, cframe, color, material, profile, assetId)
    local mesh = RouteSignalGeometry.fit(profile, cframe, size)
    local object = mesh or Instance.new("Part")
    object.Name = name
    if mesh then
        mesh:SetAttribute("Original3DAssetId", assetId)
    else
        object.Size = size
        object.CFrame = cframe
        object.TopSurface = Enum.SurfaceType.Smooth
        object.BottomSurface = Enum.SurfaceType.Smooth
    end
    object.Anchored = true
    object.CanCollide = false
    object.CanTouch = false
    object.CanQuery = false
    object.CastShadow = false
    object.Color = color
    object.Material = material or Enum.Material.Metal
    object.Parent = parent
    return object
end

local function addLight(parent, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = false
    light.Parent = parent
end

local function addRing(folder, center, theme, variantId, floorTop)
    local orbital = variantId == "Orbital"
    local bridge = orbital and ForgedBridgeAssets.approvedSource()
    local profile = bridge and bridge:FindFirstChild("SweptCrossbeam")
    if profile and (not profile:IsA("MeshPart") or profile.MeshId == "") then profile = nil end
    -- Orbital pulses sit at floor level and run tangent to the ring.
    local height = orbital and floorTop + 0.21 or 1.65
    local size = Vector3.new(7.4, orbital and 0.055 or 0.22, 0.42)
    for index = 0, 11 do
        local angle = math.rad(index * 30)
        local position = center + Vector3.new(
            math.cos(angle) * theme.ringRadius,
            height,
            math.sin(angle) * theme.ringRadius
        )
        local tangent = if orbital then CFrame.lookAt(position, center + Vector3.new(0, height, 0))
            else CFrame.lookAt(position, center) * CFrame.Angles(0, math.rad(90), 0)
        local segment = makePart(
            folder,
            "PerimeterPulse" .. tostring(index + 1),
            size,
            tangent,
            index % 2 == 0 and theme.accent or theme.secondary,
            Enum.Material.Neon, profile, 126298311664881
        )
        segment.Transparency = 0.12
    end
end

local function addTowers(folder, center, theme, variantId)
    local offsets = {
        Vector3.new(-41, 0, -41),
        Vector3.new(41, 0, -41),
        Vector3.new(-41, 0, 41),
        Vector3.new(41, 0, 41),
    }

    local harbor = variantId == "Harbor"
    local shaft, shaftId, beacon
    if variantId == "Orbital" then
        shaft, shaftId = LargeStructureAssets.shaftProfile(variantId)
        beacon = ReactorAssets.nodeProfile(Vector3.new(2.96, 2.9503, 2.96))
    end
    local verticalCylinder = CFrame.Angles(0, 0, math.pi * 0.5)
    for index, offset in ipairs(offsets) do
        local height = theme.pillarHeight + ((index % 2) * 3)
        local pillarOrigin = CFrame.new(
            center + offset + Vector3.new(0, height * 0.5 + 1, 0))
        -- Maritime low-cost fallback: rounded, salt-worn mooring poles,
        -- instead of Classic's four square, dark survey pylons.
        -- Exactly two Parts and one PointLight per existing station.
        local pillar = makePart(
            folder,
            "AtmospherePillar" .. tostring(index),
            harbor and Vector3.new(height, 1.65, 1.65)
                or Vector3.new(1.25, height, 1.25),
            harbor and pillarOrigin * verticalCylinder or pillarOrigin,
            harbor and theme.structure or Color3.fromRGB(42, 48, 62),
            harbor and Enum.Material.CorrodedMetal or Enum.Material.Metal,
            shaft, shaftId
        )
        if harbor then pillar.Shape = Enum.PartType.Cylinder end
        pillar.Transparency = 0.08

        local capOrigin = CFrame.new(
            pillar.Position + Vector3.new(0, height * 0.5, 0))
        local cap = makePart(
            folder,
            "AtmosphereBeacon" .. tostring(index),
            harbor and Vector3.new(0.45, 2.1, 2.1)
                or Vector3.new(2.1, 0.45, 2.1),
            harbor and capOrigin * verticalCylinder or capOrigin,
            index % 2 == 0 and theme.accent or theme.secondary,
            Enum.Material.Neon, beacon, 104654294187035
        )
        if harbor then cap.Shape = Enum.PartType.Cylinder end
        addLight(cap, cap.Color, 0.65, 12)
    end
end

local function addOrbitalCore(folder, center, theme)
    local profile = ReactorAssets.nodeProfile(Vector3.new(2.96, 2.9503, 2.96))
    local function lens(name, diameter, position, color, transparency)
        local size = Vector3.new(diameter, diameter, diameter)
        local frame = CFrame.new(position)
        local part = makePart(nil, name, size, frame, color, Enum.Material.Neon, profile, 104654294187035)
        if part:IsA("Part") then part.Shape = Enum.PartType.Ball end
        part.Transparency = transparency
        part.Parent = folder
        return part
    end

    local core = lens("OrbitalCore", 4.5, center + Vector3.new(0, 22, 0), theme.accent, 0.18)
    addLight(core, theme.accent, 1.35, 26)

    for index = 0, 7 do
        local angle = math.rad(index * 45)
        local position = center + Vector3.new(math.cos(angle) * 24, 22, math.sin(angle) * 24)
        lens("OrbitalNode" .. tostring(index + 1), 1.3, position,
            index % 2 == 0 and theme.accent or theme.secondary, 0.12)
    end
end

local function addCrossroadsGuides(folder, center, theme)
    for index = -4, 4 do
        if index ~= 0 then
            local offset = index * 10
            local horizontal = makePart(
                folder,
                "CrossGuideX" .. tostring(index),
                Vector3.new(7, 0.12, 0.35),
                CFrame.new(center + Vector3.new(offset, 1.58, 0)),
                theme.accent,
                Enum.Material.Neon
            )
            horizontal.Transparency = 0.24

            local vertical = makePart(
                folder,
                "CrossGuideZ" .. tostring(index),
                Vector3.new(0.35, 0.12, 7),
                CFrame.new(center + Vector3.new(0, 1.58, offset)),
                theme.secondary,
                Enum.Material.Neon
            )
            vertical.Transparency = 0.24
        end
    end
end

-- A few distant structural landmarks give each arena a recognizable
-- silhouette without obstructing jumps or spawning more lights/particles.
-- These are purely cosmetic, non-queryable and never affect hazard physics.
local function addDistantSilhouette(folder, center, theme, variantId, base)
    local extentX = base.Size.X * 0.5 + 10
    local extentZ = base.Size.Z * 0.5 + 10
    local locations = {
        Vector3.new(-extentX, 0, -extentZ),
        Vector3.new(extentX, 0, -extentZ),
        Vector3.new(-extentX, 0, extentZ),
        Vector3.new(extentX, 0, extentZ),
    }
    local harbor = variantId == "Harbor"
    local shaft, shaftId, collar, beacon
    if variantId == "Orbital" then
        shaft, shaftId = LargeStructureAssets.shaftProfile(variantId)
        collar = PerimeterArmorAssets.wayfinderProfile()
        beacon = ReactorAssets.nodeProfile(Vector3.new(2.96, 2.9503, 2.96))
    end
    local verticalCylinder = CFrame.Angles(0, 0, math.pi * 0.5)
    for index, offset in ipairs(locations) do
        local height = (variantId == "Towers" and 23)
            or (variantId == "Orbital" and 17)
            or (variantId == "Crossroads" and 13)
            or (harbor and 15)
            or 11
        local origin = center + offset + Vector3.new(0, height * 0.5, 0)
        local spine = makePart(
            folder,
            "SilhouetteSpine" .. index,
            harbor and Vector3.new(height, 2.4, 2.4)
                or Vector3.new(2.4, height, 2.4),
            CFrame.new(origin) * (harbor and verticalCylinder or CFrame.identity),
            harbor and theme.structure or Color3.fromRGB(29, 37, 53),
            harbor and Enum.Material.CorrodedMetal or Enum.Material.Metal,
            shaft, shaftId
        )
        if harbor then spine.Shape = Enum.PartType.Cylinder end
        spine.Transparency = 0.04

        -- Harbor's beacon poles use circular plated collars, unlike
        -- the square survey-grid tower bands. Same 16 scenery Parts.
        for level = 1, 2 do
            local bandOrigin = CFrame.new(
                origin + Vector3.new(0, -height * 0.3 + level * height * 0.2, 0))
            local band = makePart(
                folder,
                "SilhouetteBand" .. index .. "_" .. level,
                harbor and Vector3.new(0.32, 3.1, 3.1)
                    or Vector3.new(3.1, 0.32, 3.1),
                harbor and bandOrigin * verticalCylinder or bandOrigin,
                theme.secondary,
                harbor and Enum.Material.CorrodedMetal or Enum.Material.Metal,
                collar, 88962643359267
            )
            if harbor then band.Shape = Enum.PartType.Cylinder end
            band.Transparency = 0.14
        end

        local capOrigin = CFrame.new(
            origin + Vector3.new(0, height * 0.5 + 0.2, 0))
        local cap = makePart(
            folder,
            "SilhouetteCap" .. index,
            harbor and Vector3.new(0.5, 3.7, 3.7)
                or Vector3.new(3.7, 0.5, 3.7),
            harbor and capOrigin * verticalCylinder or capOrigin,
            index % 2 == 0 and theme.accent or theme.secondary,
            Enum.Material.Neon, beacon, 104654294187035
        )
        if harbor then cap.Shape = Enum.PartType.Cylinder end
        cap.Transparency = 0.25
    end
end

local function enhanceArena(arena)
    if not arena or not arena:IsA("Folder") or arena.Name ~= "Arena" then
        return
    end

    if arena:FindFirstChild("Atmosphere") then
        return
    end

    local variantId = arena:GetAttribute("VariantId") or "Classic"
    local theme = ArenaAtmosphereStyle.profileFor(variantId)
    local base = arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "Atmosphere"
    folder:SetAttribute("VariantId", variantId)
    folder:SetAttribute("VisualVersion", 2)
    folder.Parent = arena

    local center = base.Position
    addRing(folder, center, theme, variantId, base.Size.Y * 0.5)
    addTowers(folder, center, theme, variantId)
    addDistantSilhouette(folder, center, theme, variantId, base)

    if variantId == "Orbital" then
        addOrbitalCore(folder, center, theme)
    elseif variantId == "Crossroads" then
        addCrossroadsGuides(folder, center, theme)
    elseif variantId == "Towers" then
        local crown = makePart(
            folder,
            "TowerCrown",
            Vector3.new(20, 0.35, 20),
            CFrame.new(center + Vector3.new(0, 22, 0)),
            theme.secondary,
            Enum.Material.Neon
        )
        crown.Transparency = 0.42
    elseif variantId == "Classic" then
        -- Harbor already uses genuine quay inlays and real dock geometry;
        -- never place Classic's central neon survey panel over its deck.
        local hub = makePart(
            folder,
            "ClassicHubGlow",
            Vector3.new(16, 0.16, 16),
            CFrame.new(center + Vector3.new(0, 1.6, 0)),
            theme.accent,
            Enum.Material.Neon
        )
        hub.Transparency = 0.38
    end
end

local function watchGeneratedMap(root)
    local existing = root:FindFirstChild("Arena")
    if existing then
        task.defer(enhanceArena, existing)
    end

    root.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            task.defer(enhanceArena, child)
        end
    end)
end

local existingRoot = Workspace:FindFirstChild("GeneratedMap")
if existingRoot then
    watchGeneratedMap(existingRoot)
end

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        watchGeneratedMap(child)
    end
end)
