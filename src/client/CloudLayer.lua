local CloudLayer = {}

function CloudLayer.getOrCreate()
    local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace.Terrain
    local existing = terrain:FindFirstChildOfClass("Clouds")
    if existing then
        return existing
    end

    local clouds = Instance.new("Clouds")
    clouds.Name = "ArenaIdentityClouds"
    clouds.Enabled = true
    clouds.Cover = 0.38
    clouds.Density = 0.18
    clouds.Parent = terrain
    return clouds
end

return CloudLayer
