-- Ground-material accents for Meteor and Bomb events. All client-only
-- and cosmetic: raycast and geometry never alter server hazard physics.
local ImpactMaterialRules = {}

local METALS = {
    [Enum.Material.Metal] = true,
    [Enum.Material.DiamondPlate] = true,
    [Enum.Material.CorrodedMetal] = true,
}
local STONE = {
    [Enum.Material.Concrete] = true,
    [Enum.Material.Slate] = true,
    [Enum.Material.Granite] = true,
    [Enum.Material.Rock] = true,
    [Enum.Material.Basalt] = true,
    [Enum.Material.Pavement] = true,
    [Enum.Material.Cobblestone] = true,
}
local SOFT = {
    [Enum.Material.Sand] = true,
    [Enum.Material.Ground] = true,
    [Enum.Material.Grass] = true,
    [Enum.Material.Mud] = true,
}
local COLD = {
    [Enum.Material.Ice] = true,
    [Enum.Material.Glacier] = true,
    [Enum.Material.Snow] = true,
}

function ImpactMaterialRules.family(material)
    if METALS[material] then return "Metal" end
    if STONE[material] then return "Stone" end
    if SOFT[material] then return "Dust" end
    if COLD[material] then return "Ice" end
    if material == Enum.Material.Glass
        or material == Enum.Material.Neon
        or material == Enum.Material.SmoothPlastic then
        return "Polished"
    end
    return "Stone"
end

function ImpactMaterialRules.palette(material, surfaceColor, eventColor, kind, tier, reduced)
    local family = ImpactMaterialRules.family(material)
    local ground = typeof(surfaceColor) == "Color3"
        and surfaceColor or Color3.fromRGB(112, 105, 99)
    local event = typeof(eventColor) == "Color3"
        and eventColor or Color3.fromRGB(255, 145, 80)
    local meteor = kind == "Meteor"
    local chipMaterial, chipColor, dust, motion
    if family == "Metal" then
        chipMaterial = Enum.Material.Metal
        chipColor = ground:Lerp(Color3.fromRGB(74, 83, 95), 0.58)
        dust = ground:Lerp(Color3.fromRGB(135, 145, 155), 0.56)
        motion = 1.0
    elseif family == "Ice" then
        chipMaterial = Enum.Material.Ice
        chipColor = ground:Lerp(Color3.fromRGB(194, 232, 244), 0.72)
        dust = Color3.fromRGB(179, 220, 236)
        motion = 0.78
    elseif family == "Dust" then
        chipMaterial = Enum.Material.Ground
        chipColor = ground:Lerp(Color3.fromRGB(120, 98, 76), 0.24)
        dust = chipColor
        motion = 0.55
    elseif family == "Polished" then
        chipMaterial = Enum.Material.Glass
        chipColor = ground:Lerp(Color3.fromRGB(177, 192, 203), 0.52)
        dust = ground:Lerp(Color3.fromRGB(139, 153, 161), 0.48)
        motion = 0.90
    else
        chipMaterial = Enum.Material.Slate
        chipColor = ground:Lerp(Color3.fromRGB(90, 84, 78), 0.62)
        dust = chipColor:Lerp(Color3.fromRGB(111, 108, 103), 0.36)
        motion = 0.67
    end
    return {
        Family = family,
        Material = chipMaterial,
        Color = chipColor:Lerp(event, meteor and 0.07 or 0.12),
        DustColor = dust,
        Motion = motion,
        Count = (reduced == true or tier == "Low")
            and 0 or (tier == "High" and 6 or 3),
    }
end

function ImpactMaterialRules.surfaceFrame(position, normal)
    if typeof(position) ~= "Vector3" then return nil end
    local up = typeof(normal) == "Vector3" and normal.Magnitude > 0.01
        and normal.Unit or Vector3.yAxis
    local tangent = math.abs(up:Dot(Vector3.zAxis)) > 0.95
        and Vector3.xAxis or Vector3.zAxis
    local right = tangent:Cross(up).Unit
    local backward = right:Cross(up).Unit
    return CFrame.fromMatrix(position, right, up, backward)
end

function ImpactMaterialRules.fragment(frame, index, count, radius, motion)
    if typeof(frame) ~= "CFrame" or type(index) ~= "number"
        or type(count) ~= "number" or count <= 0 or index < 1
        or index > count or type(radius) ~= "number" or radius <= 0 then
        return nil
    end
    local a = (index - 1) / count * math.pi * 2
    local distance = radius * (0.24 + (index % 3) * 0.14)
    local length = (1.1 + (index % 3) * 0.60) * math.clamp(motion or 1, 0, 1.5)
    local direction = Vector3.new(math.cos(a), 0, math.sin(a))
    return {
        Start = frame * CFrame.new(direction * distance + Vector3.new(0, 0.12, 0))
            * CFrame.Angles(index * 0.20, a, index * 0.14),
        Travel = frame:VectorToWorldSpace(direction * length + Vector3.new(
            0, 0.22 + (index % 3) * 0.15, 0
        )),
        Size = Vector3.new(
            0.18 + (index % 3) * 0.10,
            0.09 + (index % 2) * 0.05,
            0.26 + (index % 4) * 0.09
        ),
    }
end

return ImpactMaterialRules
