local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "ArenaMidgroundMassLocal"
folder.Parent = workspace

local mapConnection = nil

local function clear()
    folder:ClearAllChildren()
end

local function makePart(name, size, cframe, color, material, transparency, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Color = color
    part.Material = material or Enum.Material.Metal
    part.Transparency = transparency or 0
    if shape then
        part.Shape = shape
    end
    part.Parent = folder
    return part
end

local function frame(base, x, y, z, yaw)
    return base.CFrame
        * CFrame.new(x, y, z)
        * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local function buildClassic(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local count = tier.Name == "Low" and 2 or (tier.Name == "Medium" and 3 or 4)

    local defs = {
        {-hx * 1.36, 8, -hz * 0.70, 16, 10, 18, 8},
        {hx * 1.34, 10, hz * 0.58, 16, 13, 20, -10},
        {-hx * 0.58, 7, hz * 1.40, 28, 8, 10, 0},
        {hx * 0.66, 12, -hz * 1.42, 24, 15, 9, 0},
    }

    for i = 1, count do
        local d = defs[i]
        local body = makePart(
            "ClassicBroadcastMass" .. i,
            Vector3.new(d[4], d[5], d[6]),
            frame(base, d[1], d[2], d[3], d[7]),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.34),
            i % 2 == 0 and Enum.Material.DiamondPlate or Enum.Material.Metal,
            tier.Name == "Low" and 0.34 or 0.18
        )

        if tier.Name ~= "Low" then
            makePart(
                "ClassicBroadcastMassGlow" .. i,
                Vector3.new(body.Size.X * 0.66, 0.28, body.Size.Z + 0.10),
                body.CFrame * CFrame.new(0, body.Size.Y * 0.5 + 0.18, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.58
            )
        end
    end
end

local function buildTowers(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local count = tier.Name == "Low" and 2 or (tier.Name == "Medium" and 4 or 5)
    local defs = {
        {-hx * 1.30, -hz * 0.64, 34, 9},
        {hx * 1.34, hz * 0.50, 44, 10},
        {-hx * 0.48, hz * 1.38, 30, 8},
        {hx * 0.42, -hz * 1.40, 38, 9},
        {hx * 1.46, -hz * 0.22, 27, 7},
    }

    for i = 1, count do
        local d = defs[i]
        local body = makePart(
            "TowerCoolingMass" .. i,
            Vector3.new(d[4], d[3], d[4]),
            frame(base, d[1], d[3] * 0.5 - 2, d[2], 45),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.30),
            Enum.Material.CorrodedMetal,
            tier.Name == "Low" and 0.32 or 0.15
        )

        if tier.Name ~= "Low" then
            makePart(
                "TowerCoolingMassStrip" .. i,
                Vector3.new(0.42, body.Size.Y * 0.68, body.Size.Z + 0.10),
                body.CFrame * CFrame.new(0, 0, -body.Size.Z * 0.5 - 0.08),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.52
            )
        end
    end
end

local function buildCrossroads(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local count = tier.Name == "Low" and 2 or (tier.Name == "Medium" and 3 or 4)
    local defs = {
        {-hx * 1.36, -hz * 0.62, 30, 7, 10, 0},
        {hx * 1.34, hz * 0.54, 34, 8, 10, 0},
        {-hx * 0.52, hz * 1.38, 10, 7, 34, 90},
        {hx * 0.60, -hz * 1.40, 10, 8, 30, 90},
    }

    for i = 1, count do
        local d = defs[i]
        local body = makePart(
            "CrossroadsTransitMass" .. i,
            Vector3.new(d[3], d[4], d[5]),
            frame(base, d[1], d[4] * 0.5 + 2, d[2], d[6]),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.28),
            Enum.Material.Concrete,
            tier.Name == "Low" and 0.36 or 0.18
        )

        if tier.Name ~= "Low" then
            makePart(
                "CrossroadsTransitMassRail" .. i,
                Vector3.new(
                    body.Size.X > body.Size.Z and body.Size.X * 0.76 or 0.34,
                    0.28,
                    body.Size.Z >= body.Size.X and body.Size.Z * 0.76 or 0.34
                ),
                body.CFrame * CFrame.new(0, body.Size.Y * 0.5 + 0.20, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.54
            )
        end
    end
end

local function buildOrbital(base, theme, tier)
    local radius = math.min(base.Size.X, base.Size.Z) * 0.76
    local count = tier.Name == "Low" and 3 or (tier.Name == "Medium" and 4 or 6)

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2 + math.rad(18)
        local radial = radius + (i % 2) * 7
        local x = math.cos(angle) * radial
        local z = math.sin(angle) * radial
        local size = 8 + (i % 3) * 2

        local body = makePart(
            "OrbitalStationMass" .. i,
            Vector3.new(size, size, size),
            frame(base, x, 10 + (i % 2) * 4, z, 0),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.20),
            Enum.Material.SmoothPlastic,
            tier.Name == "Low" and 0.34 or 0.16,
            Enum.PartType.Ball
        )

        if tier.Name ~= "Low" then
            local tangent = angle + math.pi * 0.5
            makePart(
                "OrbitalStationMassArm" .. i,
                Vector3.new(14 + (i % 2) * 4, 0.60, 1.15),
                body.CFrame * CFrame.Angles(0, -tangent, 0),
                i % 2 == 0 and theme.Secondary or theme.Detail,
                i % 2 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                i % 2 == 0 and 0.54 or 0.20
            )
        end
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

local function bindMap(generated)
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
        bindMap(child)
        task.defer(rebuild)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap(nil)
        clear()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    task.defer(rebuild)
end)

bindMap(workspace:FindFirstChild("GeneratedMap"))
rebuild()
