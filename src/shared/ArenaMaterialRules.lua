local ArenaMaterialRules = {}

function ArenaMaterialRules.targetMaterial(variant, originalMaterial, bucket, tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return originalMaterial
    end

    local value = math.clamp(math.floor(tonumber(bucket) or 0), 0, 99)
    local threshold = tier == "High" and 34 or 20
    if value >= threshold then
        return originalMaterial
    end

    local id = tostring(variant or "Classic")

    if id == "Towers" then
        if originalMaterial == Enum.Material.Metal then
            return Enum.Material.CorrodedMetal
        elseif originalMaterial == Enum.Material.DiamondPlate then
            return Enum.Material.Metal
        end
    elseif id == "Crossroads" then
        if originalMaterial == Enum.Material.Metal then
            return Enum.Material.Concrete
        elseif originalMaterial == Enum.Material.DiamondPlate then
            return Enum.Material.Slate
        end
    elseif id == "Orbital" then
        if originalMaterial == Enum.Material.Metal
            or originalMaterial == Enum.Material.DiamondPlate
        then
            return Enum.Material.SmoothPlastic
        end
    else
        if originalMaterial == Enum.Material.Metal then
            return Enum.Material.DiamondPlate
        elseif originalMaterial == Enum.Material.SmoothPlastic then
            return Enum.Material.Metal
        end
    end

    return originalMaterial
end

return ArenaMaterialRules
