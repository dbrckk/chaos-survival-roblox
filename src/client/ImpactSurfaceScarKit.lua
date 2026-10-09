-- Short-lived material-aware impact scars. Static and collision-free:
-- no new server-owned damage parts, decals, textures, lights or emitters.
-- Budget matches the former one-disc plus 0/3/5 straight-crack layout.
local ImpactSurfaceScarKit = {}

local METAL = {
    [Enum.Material.Metal] = true,
    [Enum.Material.DiamondPlate] = true,
    [Enum.Material.CorrodedMetal] = true,
}
local STONE = {
    [Enum.Material.Slate] = true,
    [Enum.Material.Concrete] = true,
    [Enum.Material.Granite] = true,
    [Enum.Material.Rock] = true,
    [Enum.Material.Basalt] = true,
    [Enum.Material.Pavement] = true,
    [Enum.Material.Cobblestone] = true,
}
local SOFT = {
    [Enum.Material.Ground] = true,
    [Enum.Material.Sand] = true,
    [Enum.Material.Grass] = true,
    [Enum.Material.Mud] = true,
}
local COLD = {
    [Enum.Material.Ice] = true,
    [Enum.Material.Snow] = true,
    [Enum.Material.Glacier] = true,
}

function ImpactSurfaceScarKit.family(material)
    if METAL[material] then return "Metal" end
    if STONE[material] then return "Stone" end
    if SOFT[material] then return "Dust" end
    if COLD[material] then return "Ice" end
    if material == Enum.Material.Glass or material == Enum.Material.Neon
        or material == Enum.Material.SmoothPlastic then
        return "Polished"
    end
    return "Stone"
end

local MAT = {
    Metal = {Enum.Material.Metal, Color3.fromRGB(53, 65, 76), 0.50},
    Stone = {Enum.Material.Slate, Color3.fromRGB(42, 40, 39), 0.58},
    Dust = {Enum.Material.Ground, Color3.fromRGB(73, 61, 50), 0.64},
    Ice = {Enum.Material.Ice, Color3.fromRGB(145, 193, 213), 0.44},
    Polished = {Enum.Material.Glass, Color3.fromRGB(69, 102, 120), 0.32},
}

function ImpactSurfaceScarKit.recipe(kind, tier, material, groundColor,
        hazardColor, reduced)
    if kind ~= "Meteor" and kind ~= "Bomb" then return nil end
    local family = ImpactSurfaceScarKit.family(material)
    local spec = MAT[family]
    local surface = typeof(groundColor) == "Color3"
        and groundColor or Color3.fromRGB(110, 107, 100)
    local hazard = typeof(hazardColor) == "Color3"
        and hazardColor or Color3.fromRGB(220, 115, 65)
    local count = tier == "High" and 5 or (tier == "Medium" and 3 or 0)
    if reduced == true then count = 0 end
    local glow = kind == "Meteor" and 0.08 or 0.035
    return {
        Family = family,
        Material = spec[1],
        Color = surface:Lerp(spec[2], spec[3]):Lerp(hazard, glow),
        CrackCount = count,
        Alpha = tier == "Low" and 0.74
            or (reduced == true and 0.69 or (tier == "High" and 0.49 or 0.60)),
        Signature = kind == "Meteor" and "FacetedCrater" or "PressureScorch",
    }
end

function ImpactSurfaceScarKit.visible(phase, kind, tier, viewerDistance)
    if phase ~= "round" or (kind ~= "Meteor" and kind ~= "Bomb")
        or type(viewerDistance) ~= "number" or viewerDistance < 0 then
        return false
    end
    local range = tier == "High" and 150
        or (tier == "Medium" and 108 or 64)
    return viewerDistance <= range
end

function ImpactSurfaceScarKit.crack(index, total, radius, kind, family)
    if (kind ~= "Meteor" and kind ~= "Bomb")
        or type(index) ~= "number" or type(total) ~= "number"
        or total < 1 or index < 1 or index > total
        or type(radius) ~= "number" or radius <= 0 then
        return nil
    end
    local angle = ((index - 1) / total) * math.pi * 2
        + (kind == "Meteor" and 0.21 or 0.11)
    local distance = radius * (kind == "Meteor" and 0.36 or 0.30)
    local reach = radius * (0.28 + (index % 3) * 0.055)
    local isFracture = kind == "Meteor" or family == "Ice"
    return {
        Name = isFracture and "RimFacet" or "PressureCut",
        Wedge = isFracture,
        Offset = Vector3.new(math.cos(angle) * distance, 0.055,
            math.sin(angle) * distance),
        Angle = -angle + (index % 2 == 0 and 0.18 or -0.14),
        Size = Vector3.new(
            isFracture and math.max(0.20, radius * 0.06) or 0.105,
            isFracture and 0.075 or 0.028,
            reach
        ),
    }
end

function ImpactSurfaceScarKit.build(parent, frame, kind, tier,
        material, groundColor, hazardColor, radius, reduced)
    if not parent or typeof(frame) ~= "CFrame"
        or type(radius) ~= "number" or radius <= 0 then
        return {}
    end
    local style = ImpactSurfaceScarKit.recipe(
        kind, tier, material, groundColor, hazardColor, reduced
    )
    if not style then return {} end
    local extent = math.clamp(radius, 2, 40)
    local built = {}
    local crater = Instance.new(kind == "Meteor" and "WedgePart" or "Part")
    crater.Name = "Impact" .. style.Signature
    crater.Anchored = true
    crater.CanCollide = false
    crater.CanTouch = false
    crater.CanQuery = false
    crater.CastShadow = false
    crater.Material = style.Material
    crater.Color = style.Color
    crater.Transparency = style.Alpha
    crater.Size = kind == "Meteor"
        and Vector3.new(extent * 0.59, 0.055, extent * 0.55)
        or Vector3.new(extent * 0.63, 0.035, extent * 0.69)
    crater.CFrame = frame * CFrame.new(0, 0.025, 0)
        * CFrame.Angles(0, kind == "Meteor" and math.rad(24) or math.rad(44), 0)
    crater:SetAttribute("ImpactScarFamily", style.Family)
    crater.Parent = parent
    table.insert(built, crater)

    for index = 1, style.CrackCount do
        local spec = ImpactSurfaceScarKit.crack(
            index, style.CrackCount, extent, kind, style.Family
        )
        local piece = Instance.new(spec.Wedge and "WedgePart" or "Part")
        piece.Name = style.Signature .. spec.Name .. index
        piece.Size = spec.Size
        piece.CFrame = frame * CFrame.new(spec.Offset)
            * CFrame.Angles(0, spec.Angle, 0)
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece.Material = style.Material
        piece.Color = style.Color:Lerp(Color3.fromRGB(23, 25, 31),
            style.Family == "Ice" and 0.10 or 0.23)
        piece.Transparency = math.clamp(style.Alpha + 0.04, 0, 0.88)
        piece:SetAttribute("ImpactScarFamily", style.Family)
        piece.Parent = parent
        table.insert(built, piece)
    end
    return built
end

function ImpactSurfaceScarKit.settlement(tier, reduced, initialColor, lifetime)
    if tier == "Low" or reduced == true or typeof(initialColor) ~= "Color3"
        or type(lifetime) ~= "number" or lifetime <= 1 then
        return nil
    end
    local delay = lifetime * 0.26
    local duration = math.min(0.95, lifetime * 0.19)
    return {
        StartAfter = delay,
        Duration = duration,
        Color = initialColor:Lerp(Color3.fromRGB(59, 63, 69), 0.42),
        Transparency = tier == "High" and 0.66 or 0.72,
    }
end

return ImpactSurfaceScarKit
