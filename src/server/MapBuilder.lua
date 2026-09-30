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

function MapBuilder.build(config)
    local old = workspace:FindFirstChild("GeneratedMap")
    if old then old:Destroy() end

    local root = Instance.new("Folder")
    root.Name = "GeneratedMap"
    root.Parent = workspace

    local lobby = Instance.new("Folder")
    lobby.Name = "Lobby"
    lobby.Parent = root
    part(lobby, "Floor", Vector3.new(70, 2, 70), config.LobbyCenter, Color3.fromRGB(45, 50, 65))

    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(8, 1, 8)
    lobbySpawn.Position = config.LobbyCenter + Vector3.new(0, 2, 0)
    lobbySpawn.Anchored = true
    lobbySpawn.Neutral = true
    lobbySpawn.Parent = lobby

    local arena = Instance.new("Folder")
    arena.Name = "Arena"
    arena.Parent = root

    local base = part(arena, "Base", Vector3.new(100, 2, 100), config.ArenaCenter, Color3.fromRGB(92, 103, 125), Enum.Material.Concrete)
    base:SetAttribute("OriginalSizeX", base.Size.X)
    base:SetAttribute("OriginalSizeZ", base.Size.Z)

    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "Spawns"
    spawnFolder.Parent = arena

    local offsets = {
        Vector3.new(-30,3,-30), Vector3.new(30,3,-30), Vector3.new(-30,3,30), Vector3.new(30,3,30),
        Vector3.new(0,3,-35), Vector3.new(0,3,35), Vector3.new(-35,3,0), Vector3.new(35,3,0)
    }

    for i, offset in ipairs(offsets) do
        local s = part(spawnFolder, "Spawn"..i, Vector3.new(4,1,4), config.ArenaCenter + offset, Color3.fromRGB(90,200,120))
        s.Transparency = 0.35
    end

    local platforms = Instance.new("Folder")
    platforms.Name = "Platforms"
    platforms.Parent = arena

    local heights = {5, 10, 15, 20}
    for i = 1, 18 do
        local x = ((i * 23) % 75) - 37
        local z = ((i * 41) % 75) - 37
        local h = heights[(i % #heights) + 1]
        part(platforms, "Platform"..i, Vector3.new(12,2,12), config.ArenaCenter + Vector3.new(x,h,z), Color3.fromRGB(120,145,190))
    end

    return root
end

return MapBuilder
