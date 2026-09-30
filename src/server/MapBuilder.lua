local ArenaVariants = require(script.Parent.ArenaVariants)

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

function MapBuilder.buildArena(config, variantId)
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

    local variant = ArenaVariants.get(variantId) or ArenaVariants.get("Classic")
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

function MapBuilder.build(config, variantId)
    local old = workspace:FindFirstChild("GeneratedMap")
    if old then
        old:Destroy()
    end

    local root = Instance.new("Folder")
    root.Name = "GeneratedMap"
    root.Parent = workspace

    buildLobby(root, config)
    MapBuilder.buildArena(config, variantId or "Classic")

    return root
end

return MapBuilder
