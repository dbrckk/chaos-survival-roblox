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

    part(
        lobby,
        "Floor",
        Vector3.new(70, 2, 70),
        config.LobbyCenter,
        Color3.fromRGB(45, 50, 65)
    )

    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(8, 1, 8)
    lobbySpawn.Position = config.LobbyCenter + Vector3.new(0, 2, 0)
    lobbySpawn.Anchored = true
    lobbySpawn.Neutral = true
    lobbySpawn.Parent = lobby
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
