local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "ArenaHeroSceneryLocal"
folder.Parent = workspace

local function clear()
    folder:ClearAllChildren()
end

local function makePart(name, size, cframe, color, material, transparency, castShadow)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = castShadow == true
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function makeWedge(name, size, cframe, color, material, transparency, castShadow)
    local part = Instance.new("WedgePart")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = castShadow == true
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function localFrame(base, x, y, z, yaw)
    return base.CFrame
        * CFrame.new(x, y, z)
        * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local function addPylon(base, index, x, z, height, theme, tier, yaw)
    local structure = makePart(
        "HeroPylon" .. index,
        Vector3.new(2.8, height, 2.8),
        localFrame(base, x, height * 0.5 + 0.7, z, yaw),
        theme.Structure:Lerp(VisualTheme.World.Deep, 0.22),
        Enum.Material.Metal,
        tier.Name == "Low" and 0.10 or 0.03,
        tier.Name == "High"
    )

    local strip = makePart(
        "HeroPylonGlow" .. index,
        Vector3.new(0.34, height * 0.68, 2.94),
        structure.CFrame * CFrame.new(0, 0, -0.04),
        index % 2 == 0 and theme.Secondary or theme.Accent,
        Enum.Material.Neon,
        tier.Name == "Low" and 0.46 or 0.22,
        false
    )

    if tier.Name == "High" then
        makePart(
            "HeroPylonCap" .. index,
            Vector3.new(5.6, 0.75, 1.15),
            structure.CFrame * CFrame.new(0, height * 0.5 - 0.85, 0),
            theme.Detail,
            Enum.Material.DiamondPlate,
            0.12,
            true
        )
    end

    return structure, strip
end

local function buildClassic(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local positions = {
        {-hx - 8, -hz - 8, 45},
        {hx + 8, -hz - 8, -45},
        {-hx - 8, hz + 8, -45},
        {hx + 8, hz + 8, 45},
    }

    for i, item in ipairs(positions) do
        addPylon(base, i, item[1], item[2], 14 + (i % 2) * 2, theme, tier, item[3])
    end

    if tier.Name ~= "Low" then
        local fins = {
            {-hx - 10, 0, -18, 0},
            {hx + 10, 0, 18, 0},
            {-18, 0, hz + 10, 90},
            {18, 0, -hz - 10, 90},
        }
        for i, item in ipairs(fins) do
            makeWedge(
                "ClassicSkyFin" .. i,
                Vector3.new(1.0, 10 + (i % 2) * 3, 6.5),
                localFrame(base, item[1], 6.0, item[3], item[4]),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.48,
                false
            )
        end
    end
end

local function buildTowers(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local positions = {
        {-hx - 7, -hz - 7},
        {hx + 7, -hz - 7},
        {-hx - 7, hz + 7},
        {hx + 7, hz + 7},
    }

    for i, item in ipairs(positions) do
        local height = tier.Name == "Low" and 22 or 28
        local pylon = makePart(
            "TowerCrown" .. i,
            Vector3.new(4.2, height, 4.2),
            localFrame(base, item[1], height * 0.5 + 0.8, item[2], 45),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.28),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.16 or 0.05,
            tier.Name == "High"
        )

        makePart(
            "TowerCrownGlow" .. i,
            Vector3.new(0.44, height * 0.70, 4.34),
            pylon.CFrame,
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.58 or 0.26,
            false
        )

        if tier.Name ~= "Low" then
            makeWedge(
                "TowerCrownWing" .. i,
                Vector3.new(9.5, 0.7, 1.25),
                pylon.CFrame * CFrame.new(0, height * 0.5 - 2.2, 0),
                theme.Detail,
                Enum.Material.DiamondPlate,
                0.14,
                tier.Name == "High"
            )
        end
    end

    if tier.Name == "High" then
        for i = 1, 4 do
            local angle = math.rad(45 + (i - 1) * 90)
            local radius = math.min(hx, hz) * 0.48
            local posX = math.cos(angle) * radius
            local posZ = math.sin(angle) * radius
            makePart(
                "TowerSkyBrace" .. i,
                Vector3.new(15, 0.45, 0.65),
                localFrame(base, posX, 19.5, posZ, -math.deg(angle)),
                theme.Accent,
                Enum.Material.Neon,
                0.52,
                false
            )
        end
    end
end

local function addCrossroadGate(base, index, x, z, yaw, theme, tier)
    local width = tier.Name == "Low" and 12 or 16
    local height = tier.Name == "Low" and 8 or 11

    local gateFrame = localFrame(base, x, 0, z, yaw)
    local left = makePart(
        "CrossroadGateL" .. index,
        Vector3.new(1.8, height, 2.2),
        gateFrame * CFrame.new(-width * 0.5, height * 0.5 + 0.7, 0),
        theme.Structure,
        Enum.Material.Metal,
        0.06,
        tier.Name == "High"
    )
    local right = makePart(
        "CrossroadGateR" .. index,
        Vector3.new(1.8, height, 2.2),
        gateFrame * CFrame.new(width * 0.5, height * 0.5 + 0.7, 0),
        theme.Structure,
        Enum.Material.Metal,
        0.06,
        tier.Name == "High"
    )
    makePart(
        "CrossroadGateTop" .. index,
        Vector3.new(width + 1.8, 1.25, 2.2),
        gateFrame * CFrame.new(0, height + 0.25, 0),
        theme.Detail,
        Enum.Material.DiamondPlate,
        0.10,
        tier.Name == "High"
    )

    if tier.Name ~= "Low" then
        makePart(
            "CrossroadGateGlowL" .. index,
            Vector3.new(0.22, height * 0.72, 2.34),
            left.CFrame,
            index % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            0.30,
            false
        )
        makePart(
            "CrossroadGateGlowR" .. index,
            Vector3.new(0.22, height * 0.72, 2.34),
            right.CFrame,
            index % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            0.30,
            false
        )
    end
end

local function buildCrossroads(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local corners = {
        {-hx - 7, -hz - 7, 45},
        {hx + 7, -hz - 7, -45},
        {-hx - 7, hz + 7, -45},
        {hx + 7, hz + 7, 45},
    }

    for i, item in ipairs(corners) do
        local height = tier.Name == "Low" and 13 or 17
        local body = makePart(
            "CrossroadHeroMonolith" .. i,
            Vector3.new(5.2, height, 2.0),
            localFrame(base, item[1], height * 0.5 + 0.7, item[2], item[3]),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.18),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.16 or 0.05,
            tier.Name == "High"
        )

        makePart(
            "CrossroadHeroSignal" .. i,
            Vector3.new(4.0, height * 0.52, 0.26),
            body.CFrame * CFrame.new(0, 1.0, -1.02),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.58 or 0.28,
            false
        )

        if tier.Name == "High" then
            makeWedge(
                "CrossroadHeroBlade" .. i,
                Vector3.new(8.0, 0.5, 0.8),
                body.CFrame * CFrame.new(0, height * 0.5 - 1.1, 0),
                theme.Detail,
                Enum.Material.DiamondPlate,
                0.16,
                true
            )
        end
    end
end

local function buildOrbital(base, theme, tier)
    local radius = math.min(base.Size.X, base.Size.Z) * 0.56
    local segments = tier.Name == "Low" and 6 or (tier.Name == "Medium" and 10 or 14)

    for i = 1, segments do
        local angle = ((i - 1) / segments) * math.pi * 2
        local tangent = angle + math.pi * 0.5
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius

        local arc = makePart(
            "OrbitalHeroArc" .. i,
            Vector3.new(radius * 0.34, 1.15, 2.2),
            localFrame(base, x, 7.5 + ((i % 2) * 1.6), z, -math.deg(tangent)),
            theme.Structure,
            Enum.Material.Metal,
            tier.Name == "Low" and 0.20 or 0.07,
            tier.Name == "High"
        )

        if tier.Name ~= "Low" then
            makePart(
                "OrbitalHeroGlow" .. i,
                Vector3.new(radius * 0.26, 0.22, 2.32),
                arc.CFrame * CFrame.new(0, 0.72, 0),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.24,
                false
            )
        end
    end

    local mastCount = tier.Name == "Low" and 4 or 8
    for i = 1, mastCount do
        local angle = ((i - 1) / mastCount) * math.pi * 2
        local mastRadius = radius + 2.5
        local x = math.cos(angle) * mastRadius
        local z = math.sin(angle) * mastRadius
        makePart(
            "OrbitalMast" .. i,
            Vector3.new(1.15, 12, 1.15),
            localFrame(base, x, 6.6, z, 0),
            theme.Detail,
            Enum.Material.Metal,
            0.16,
            tier.Name == "High"
        )
    end
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))

    if variant == "Towers" then
        buildTowers(base, theme, tier)
    elseif variant == "Crossroads" then
        buildCrossroads(base, theme, tier)
    elseif variant == "Orbital" then
        buildOrbital(base, theme, tier)
    else
        buildClassic(base, theme, tier)
    end
end

local mapConnection = nil

local function bindGeneratedMap(generated)
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.defer(rebuild)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(child)
        task.defer(rebuild)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(nil)
        clear()
    end
end)

bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    task.defer(rebuild)
end)

rebuild()
