local Workspace = game:GetService("Workspace")

local ArenaAtmosphereStyle = require("./ArenaAtmosphereStyle")

local function makePart(parent, name, size, cframe, color, material)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.CFrame = cframe
    object.Anchored = true
    object.CanCollide = false
    object.CanTouch = false
    object.CanQuery = false
    object.CastShadow = false
    object.Color = color
    object.Material = material or Enum.Material.Metal
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
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

local function addRing(folder, center, theme)
    for index = 0, 11 do
        local angle = math.rad(index * 30)
        local position = center + Vector3.new(
            math.cos(angle) * theme.ringRadius,
            1.65,
            math.sin(angle) * theme.ringRadius
        )
        local tangent = CFrame.lookAt(position, center) * CFrame.Angles(0, math.rad(90), 0)
        local segment = makePart(
            folder,
            "PerimeterPulse" .. tostring(index + 1),
            Vector3.new(7.4, 0.22, 0.42),
            tangent,
            index % 2 == 0 and theme.accent or theme.secondary,
            Enum.Material.Neon
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
            harbor and Enum.Material.CorrodedMetal or Enum.Material.Metal
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
            Enum.Material.Neon
        )
        if harbor then cap.Shape = Enum.PartType.Cylinder end
        addLight(cap, cap.Color, 0.65, 12)
    end
end

local function addOrbitalCore(folder, center, theme)
    local core = makePart(
        folder,
        "OrbitalCore",
        Vector3.new(4.5, 4.5, 4.5),
        CFrame.new(center + Vector3.new(0, 22, 0)),
        theme.accent,
        Enum.Material.Neon
    )
    core.Shape = Enum.PartType.Ball
    core.Transparency = 0.18
    addLight(core, theme.accent, 1.35, 26)

    for index = 0, 7 do
        local angle = math.rad(index * 45)
        local position = center + Vector3.new(math.cos(angle) * 24, 22, math.sin(angle) * 24)
        local node = makePart(
            folder,
            "OrbitalNode" .. tostring(index + 1),
            Vector3.new(1.3, 1.3, 1.3),
            CFrame.new(position),
            index % 2 == 0 and theme.accent or theme.secondary,
            Enum.Material.Neon
        )
        node.Shape = Enum.PartType.Ball
        node.Transparency = 0.12
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
            harbor and Enum.Material.CorrodedMetal or Enum.Material.Metal
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
                harbor and Enum.Material.CorrodedMetal or Enum.Material.Metal
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
            Enum.Material.Neon
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
    addRing(folder, center, theme)
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
