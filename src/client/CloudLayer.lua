local CloudLayer = {}

function CloudLayer.getOrCreate()
    local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace.Terrain
    local canonical = nil

    for _, child in ipairs(terrain:GetChildren()) do
        if child:IsA("Clouds") then
            if not canonical or child.Name == "ArenaIdentityClouds" then
                if canonical and canonical ~= child then
                    canonical:Destroy()
                end
                canonical = child
            else
                child:Destroy()
            end
        end
    end

    if canonical then
        canonical.Name = "ArenaIdentityClouds"
        return canonical
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
