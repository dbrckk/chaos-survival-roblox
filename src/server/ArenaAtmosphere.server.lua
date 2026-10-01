local Workspace = game:GetService("Workspace")

local THEMES = {
    Classic = {
        accent = Color3.fromRGB(90, 180, 255),
        secondary = Color3.fromRGB(150, 95, 255),
        pillarHeight = 8,
        ringRadius = 43,
    },
    Towers = {
        accent = Color3.fromRGB(65, 220, 255),
        secondary = Color3.fromRGB(255, 185, 70),
        pillarHeight = 18,
        ringRadius = 40,
    },
    Crossroads = {
        accent = Color3.fromRGB(205, 105, 255),
        secondary = Color3.fromRGB(255, 95, 155),
        pillarHeight = 11,
        ringRadius = 44,
    },
    Orbital = {
        accent = Color3.fromRGB(65, 255, 205),
        secondary = Color3.fromRGB(95, 135, 255),
        pillarHeight = 13,
        ringRadius = 42,
    },
}

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

local function addTowers(folder, center, theme)
    local offsets = {
        Vector3.new(-41, 0, -41),
        Vector3.new(41, 0, -41),
        Vector3.new(-41, 0, 41),
        Vector3.new(41, 0, 41),
    }

    for index, offset in ipairs(offsets) do
        local height = theme.pillarHeight + ((index % 2) * 3)
        local pillar = makePart(
            folder,
            "AtmospherePillar" .. tostring(index),
            Vector3.new(1.25, height, 1.25),
            CFrame.new(center + offset + Vector3.new(0, height * 0.5 + 1, 0)),
            Color3.fromRGB(42, 48, 62),
            Enum.Material.Metal
        )
        pillar.Transparency = 0.08

        local cap = makePart(
            folder,
            "AtmosphereBeacon" .. tostring(index),
            Vector3.new(2.1, 0.45, 2.1),
            CFrame.new(pillar.Position + Vector3.new(0, height * 0.5, 0)),
            index % 2 == 0 and theme.accent or theme.secondary,
            Enum.Material.Neon
        )
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

local function enhanceArena(arena)
    if not arena or not arena:IsA("Folder") or arena.Name ~= "Arena" then
        return
    end

    if arena:FindFirstChild("Atmosphere") then
        return
    end

    local variantId = arena:GetAttribute("VariantId") or "Classic"
    local theme = THEMES[variantId] or THEMES.Classic
    local base = arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "Atmosphere"
    folder:SetAttribute("VariantId", variantId)
    folder:SetAttribute("VisualVersion", 1)
    folder.Parent = arena

    local center = base.Position
    addRing(folder, center, theme)
    addTowers(folder, center, theme)

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
    else
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
