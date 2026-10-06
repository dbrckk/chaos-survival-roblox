local Lighting = game:GetService("Lighting")

local ArenaPostProcessLayer = {}

local function getOrCreate(name, className)
    local existing = Lighting:FindFirstChild(name)
    if existing and not existing:IsA(className) then
        existing:Destroy()
        existing = nil
    end

    local effect = existing or Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    return effect
end

function ArenaPostProcessLayer.get()
    local layer = {
        Color = getOrCreate("ArenaIdentityColor", "ColorCorrectionEffect"),
        Atmosphere = getOrCreate("ArenaIdentityAtmosphere", "Atmosphere"),
        Bloom = getOrCreate("ArenaIdentityBloom", "BloomEffect"),
        Depth = getOrCreate("ArenaIdentityDepth", "DepthOfFieldEffect"),
        SunRays = getOrCreate("ArenaIdentitySunRays", "SunRaysEffect"),
    }

    -- Remove superseded duplicate owners from older client builds / hot reloads.
    for _, legacyName in ipairs({
        "ChaosColor",
        "ChaosAtmosphere",
        "ChaosBloom",
        "ChaosRays",
    }) do
        local legacy = Lighting:FindFirstChild(legacyName)
        if legacy then
            legacy:Destroy()
        end
    end

    return layer
end

return ArenaPostProcessLayer
