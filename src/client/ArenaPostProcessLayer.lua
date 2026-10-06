local Lighting = game:GetService("Lighting")

local ArenaPostProcessLayer = {}

local function getOrCreate(name, className, exclusiveClass)
    local existing = nil

    for _, child in ipairs(Lighting:GetChildren()) do
        if child.Name == name then
            if child:IsA(className) and not existing then
                existing = child
            else
                child:Destroy()
            end
        elseif exclusiveClass and child:IsA(className) then
            child:Destroy()
        end
    end

    local effect = existing or Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    return effect
end

function ArenaPostProcessLayer.get()
    local layer = {
        -- ColorCorrection is not class-exclusive because Freeze/aftermath use
        -- temporary overlays. The four other persistent classes are exclusive.
        Color = getOrCreate("ArenaIdentityColor", "ColorCorrectionEffect", false),
        Atmosphere = getOrCreate("ArenaIdentityAtmosphere", "Atmosphere", true),
        Bloom = getOrCreate("ArenaIdentityBloom", "BloomEffect", true),
        Depth = getOrCreate("ArenaIdentityDepth", "DepthOfFieldEffect", true),
        SunRays = getOrCreate("ArenaIdentitySunRays", "SunRaysEffect", true),
    }

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
