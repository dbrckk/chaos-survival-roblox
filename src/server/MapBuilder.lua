local MapBuilder = {}

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function buildLobby(root, config)
    local lobby = Instance.new("Folder")
    lobby.Name = "Lobby"
    lobby.Parent = root

    local floor = part(
        lobby,
        "Floor",
        Vector3.new(74, 2, 74),
        config.LobbyCenter,
        Color3.fromRGB(30, 34, 46),
        Enum.Material.Slate
    )

    local decor = Instance.new("Folder")
    decor.Name = "Decor"
    decor.Parent = lobby

    local centerPlatform = part(
        decor,
        "CenterPlatform",
        Vector3.new(24, 1.2, 24),
        config.LobbyCenter + Vector3.new(0, 1.45, 0),
        Color3.fromRGB(49, 57, 78),
        Enum.Material.Metal
    )

    local centerGlow = part(
        decor,
        "CenterGlow",
        Vector3.new(20, 0.22, 20),
        config.LobbyCenter + Vector3.new(0, 2.08, 0),
        Color3.fromRGB(80, 175, 255),
        Enum.Material.Neon
    )
    centerGlow.CanCollide = false
    centerGlow.Transparency = 0.22

    local glowLight = Instance.new("PointLight")
    glowLight.Name = "LobbyGlow"
    glowLight.Color = centerGlow.Color
    glowLight.Brightness = 1.3
    glowLight.Range = 26
    glowLight.Shadows = false
    glowLight.Parent = centerGlow

    local cornerOffsets = {
        Vector3.new(-31, 5, -31),
        Vector3.new(31, 5, -31),
        Vector3.new(-31, 5, 31),
        Vector3.new(31, 5, 31),
    }

    for i, offset in ipairs(cornerOffsets) do
        local pylon = part(
            decor,
            "Pylon" .. i,
            Vector3.new(2.2, 10, 2.2),
            config.LobbyCenter + offset,
            Color3.fromRGB(58, 70, 96),
            Enum.Material.Metal
        )

        local cap = part(
            decor,
            "PylonGlow" .. i,
            Vector3.new(2.8, 0.55, 2.8),
            pylon.Position + Vector3.new(0, 5.25, 0),
            Color3.fromRGB(125, 85, 255),
            Enum.Material.Neon
        )
        cap.CanCollide = false

        local light = Instance.new("PointLight")
        light.Color = cap.Color
        light.Brightness = 0.8
        light.Range = 16
        light.Shadows = false
        light.Parent = cap
    end

    local arenaDirection = Vector3.new(0, 0, 1)
    local archCenter = config.LobbyCenter + arenaDirection * 27

    local leftColumn = part(
        decor,
        "ArenaGateLeft",
        Vector3.new(3, 13, 3),
        archCenter + Vector3.new(-10, 6.5, 0),
        Color3.fromRGB(61, 71, 96),
        Enum.Material.Metal
    )

    local rightColumn = part(
        decor,
        "ArenaGateRight",
        Vector3.new(3, 13, 3),
        archCenter + Vector3.new(10, 6.5, 0),
        Color3.fromRGB(61, 71, 96),
        Enum.Material.Metal
    )

    local archTop = part(
        decor,
        "ArenaGateTop",
        Vector3.new(23, 3, 3),
        archCenter + Vector3.new(0, 13, 0),
        Color3.fromRGB(95, 72, 160),
        Enum.Material.Neon
    )

    local sign = part(
        decor,
        "ChaosSign",
        Vector3.new(18, 6, 0.5),
        config.LobbyCenter + Vector3.new(0, 10, -25),
        Color3.fromRGB(18, 21, 30),
        Enum.Material.Metal
    )
    sign.CanCollide = false

    local surface = Instance.new("SurfaceGui")
    surface.Name = "TitleGui"
    surface.Face = Enum.NormalId.Front
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 45
    surface.AlwaysOnTop = false
    surface.Parent = sign

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromScale(1, 0.62)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.fromRGB(245, 248, 255)
    title.TextStrokeTransparency = 0.65
    title.TextScaled = true
    title.Text = "CHAOS SURVIVAL"
    title.Parent = surface

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromScale(0, 0.62)
    subtitle.Size = UDim2.fromScale(1, 0.30)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.TextColor3 = Color3.fromRGB(120, 195, 255)
    subtitle.TextScaled = true
    subtitle.Text = "VOTE • SURVIVE • REPEAT"
    subtitle.Parent = surface

    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(8, 1, 8)
    lobbySpawn.Position = config.LobbyCenter + Vector3.new(0, 2.8, 0)
    lobbySpawn.Anchored = true
    lobbySpawn.Neutral = true
    lobbySpawn.Transparency = 1
    lobbySpawn.CanCollide = false
    lobbySpawn.Parent = lobby

    floor:SetAttribute("VisualVersion", 2)
    centerPlatform:SetAttribute("SafeHub", true)
    leftColumn:SetAttribute("ArenaGate", true)
    rightColumn:SetAttribute("ArenaGate", true)
    archTop:SetAttribute("ArenaGate", true)
end

function MapBuilder.buildArena(config, variantId, arenaVariants)
    local root = workspace:FindFirstChild("GeneratedMap")
    if not root then
        root = Instance.new("Folder")
        root.Name = "GeneratedMap"
        root.Parent = workspace
    end

    local oldArena = root:FindFirstChild("Arena")
    if oldArena then
        oldArena:Destroy()
    end

    assert(arenaVariants, "arenaVariants is required")
    local variant = arenaVariants.get(variantId) or arenaVariants.get("Classic")
    local arena = Instance.new("Folder")
    arena.Name = "Arena"
    arena:SetAttribute("VariantId", variant.Id)
    arena:SetAttribute("VariantName", variant.Name)
    arena.Parent = root

    local base = part(
        arena,
        "Base",
        variant.BaseSize,
        config.ArenaCenter,
        variant.BaseColor,
        Enum.Material.Concrete
    )
    base:SetAttribute("OriginalSizeX", base.Size.X)
    base:SetAttribute("OriginalSizeZ", base.Size.Z)

    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "Spawns"
    spawnFolder.Parent = arena

    for i, offset in ipairs(variant.SpawnOffsets) do
        local s = part(
            spawnFolder,
            "Spawn" .. i,
            Vector3.new(4, 1, 4),
            config.ArenaCenter + offset,
            Color3.fromRGB(90, 200, 120)
        )
        s.Transparency = 0.35
    end

    local platforms = Instance.new("Folder")
    platforms.Name = "Platforms"
    platforms.Parent = arena

    local decor = Instance.new("Folder")
    decor.Name = "Decor"
    decor.Parent = arena

    local halfX = variant.BaseSize.X * 0.5
    local halfZ = variant.BaseSize.Z * 0.5
    local edgeThickness = 0.35
    local edgeHeight = 0.45

    local edgeColor = variant.PlatformColor
    local north = part(
        decor,
        "EdgeNorth",
        Vector3.new(variant.BaseSize.X, edgeHeight, edgeThickness),
        config.ArenaCenter + Vector3.new(0, 1.25, -halfZ + 0.4),
        edgeColor,
        Enum.Material.Neon
    )
    north.CanCollide = false

    local south = part(
        decor,
        "EdgeSouth",
        Vector3.new(variant.BaseSize.X, edgeHeight, edgeThickness),
        config.ArenaCenter + Vector3.new(0, 1.25, halfZ - 0.4),
        edgeColor,
        Enum.Material.Neon
    )
    south.CanCollide = false

    local west = part(
        decor,
        "EdgeWest",
        Vector3.new(edgeThickness, edgeHeight, variant.BaseSize.Z),
        config.ArenaCenter + Vector3.new(-halfX + 0.4, 1.25, 0),
        edgeColor,
        Enum.Material.Neon
    )
    west.CanCollide = false

    local east = part(
        decor,
        "EdgeEast",
        Vector3.new(edgeThickness, edgeHeight, variant.BaseSize.Z),
        config.ArenaCenter + Vector3.new(halfX - 0.4, 1.25, 0),
        edgeColor,
        Enum.Material.Neon
    )
    east.CanCollide = false

    local beacon = part(
        decor,
        "CenterBeacon",
        Vector3.new(1.4, 14, 1.4),
        config.ArenaCenter + Vector3.new(0, 7, 0),
        edgeColor,
        Enum.Material.Neon
    )
    beacon.CanCollide = false
    beacon.Transparency = 0.35

    local light = Instance.new("PointLight")
    light.Name = "ArenaGlow"
    light.Color = edgeColor
    light.Brightness = 1.2
    light.Range = 28
    light.Shadows = false
    light.Parent = beacon

    for i, definition in ipairs(variant.Platforms) do
        part(
            platforms,
            "Platform" .. i,
            definition.size,
            config.ArenaCenter + definition.offset,
            variant.PlatformColor
        )
    end

    return arena
end

function MapBuilder.build(config, variantId, arenaVariants)
    local old = workspace:FindFirstChild("GeneratedMap")
    if old then
        old:Destroy()
    end

    local root = Instance.new("Folder")
    root.Name = "GeneratedMap"
    root.Parent = workspace

    buildLobby(root, config)
    MapBuilder.buildArena(config, variantId or "Classic", arenaVariants)

    return root
end

return MapBuilder
