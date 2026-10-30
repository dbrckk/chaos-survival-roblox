local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local ArenaDetailKit = require(script.Parent.ArenaDetailKit)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "ArenaMidgroundMassLocal"
folder.Parent = workspace

local disconnectMapWatch = nil

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

        ArenaDetailKit.build(folder, "Midground", "Classic", body, tier.Name, theme)

        local glowEnabled = tier.Name == "High" and i <= 3
            or tier.Name == "Medium" and i == 1
        if glowEnabled then
            makePart(
                "ClassicBroadcastMassGlow" .. i,
                Vector3.new(body.Size.X * 0.74, 0.42, body.Size.Z + 0.16),
                body.CFrame * CFrame.new(0, body.Size.Y * 0.5 + 0.23, 0),
                theme.Detail:Lerp(theme.Structure, i % 2 == 0 and 0.33 or 0.18),
                Enum.Material.DiamondPlate,
                tier.Name == "High" and 0.16 or 0.24
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

        ArenaDetailKit.build(folder, "Midground", "Towers", body, tier.Name, theme)

        local stripEnabled = tier.Name == "High" and i % 2 == 1
            or tier.Name == "Medium" and i == 1
        if stripEnabled then
            makePart(
                "TowerCoolingMassStrip" .. i,
                Vector3.new(0.84, body.Size.Y * 0.78, body.Size.Z * 0.16),
                body.CFrame * CFrame.new(0, 0, -body.Size.Z * 0.5 - 0.10),
                theme.Detail:Lerp(theme.Structure, 0.40),
                Enum.Material.CorrodedMetal,
                tier.Name == "High" and 0.12 or 0.20
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

        ArenaDetailKit.build(folder, "Midground", "Crossroads", body, tier.Name, theme)

        local railEnabled = tier.Name == "High" and i % 2 == 1
            or tier.Name == "Medium" and i == 1
        if railEnabled then
            makePart(
                "CrossroadsTransitMassRail" .. i,
                Vector3.new(
                    body.Size.X > body.Size.Z and body.Size.X * 0.76 or 0.56,
                    0.38,
                    body.Size.Z >= body.Size.X and body.Size.Z * 0.76 or 0.56
                ),
                body.CFrame * CFrame.new(0, body.Size.Y * 0.5 + 0.24, 0),
                theme.Detail:Lerp(theme.Structure, 0.30),
                Enum.Material.Concrete,
                tier.Name == "High" and 0.12 or 0.22
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
        -- A low-poly sphere remains recognizable as an orbital node,
        -- while its metallic finish resembles a manufactured hull.
        -- Retain the same geometry and quality-tier part counts.

        local body = makePart(
            "OrbitalStationMass" .. i,
            Vector3.new(size, size, size),
            frame(base, x, 10 + (i % 2) * 4, z, 0),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.20),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.34 or 0.16,
            Enum.PartType.Ball
        )

        ArenaDetailKit.build(folder, "Midground", "Orbital", body, tier.Name, theme)

        if tier.Name ~= "Low" then
            local tangent = angle + math.pi * 0.5
            local glowing = tier.Name == "High" and i % 3 == 0
            makePart(
                "OrbitalStationMassArm" .. i,
                Vector3.new(14 + (i % 2) * 4, 0.60, 1.15),
                body.CFrame * CFrame.Angles(0, -tangent, 0),
                glowing and theme.Secondary:Lerp(theme.Structure, 0.60)
                    or theme.Detail:Lerp(theme.Structure, 0.28),
                Enum.Material.DiamondPlate,
                glowing and 0.22 or 0.12
            )
        end
    end
end


-- Storm Harbor needs maritime silhouettes, not Classic's television
-- transmitter blocks. These NON-WALKABLE cargo hulks are stationed beyond
-- the true map edge, and add layered steel relief without imported assets.
local function buildHarbor(base, theme, tier)
    local hx, hz = base.Size.X * 0.5, base.Size.Z * 0.5
    local count = tier.Name == "Low" and 2
        or (tier.Name == "Medium" and 3 or 4)
    local berths = {
        {-hx * 1.31, -hz * 0.55, 14},
        {hx * 1.32, hz * 0.54, -16},
        {-hx * 0.49, hz * 1.33, 93},
        {hx * 0.58, -hz * 1.34, 86},
    }
    local hullColor = theme.Structure:Lerp(VisualTheme.World.Deep, 0.35)
    local freightColor = theme.Surface:Lerp(
        Color3.fromRGB(111, 97, 82), 0.36
    )
    local ribColor = theme.Detail:Lerp(hullColor, 0.52)
    local deckY = base.Size.Y * 0.5

    for i = 1, count do
        local berth = berths[i]
        local origin = frame(
            base, berth[1], deckY + 0.45, berth[2], berth[3]
        )
        makePart(
            "HarborFreightBargeHull" .. i,
            Vector3.new(28, 3.5, 13.2),
            origin,
            hullColor, Enum.Material.CorrodedMetal,
            tier.Name == "Low" and 0.28 or 0.13
        )
        local container = makePart(
            "HarborFreightContainer" .. i,
            Vector3.new(21.0, 7.4, 8.6),
            origin * CFrame.new(0, 5.18, 0),
            freightColor, Enum.Material.CorrodedMetal,
            tier.Name == "Low" and 0.18 or 0.05
        )
        makePart(
            "HarborFreightLoadSill" .. i,
            Vector3.new(22.0, 0.38, 9.6),
            container.CFrame * CFrame.new(0, -3.9, 0),
            ribColor, Enum.Material.DiamondPlate, 0.08
        )

        if tier.Name ~= "Low" then
            local ribCount = tier.Name == "High" and 4 or 2
            for rib = 1, ribCount do
                local x = -8.0 + (rib - 1) * (16.0 / math.max(1, ribCount - 1))
                makePart(
                    "HarborFreightCorrugation" .. i .. "_" .. rib,
                    Vector3.new(0.24, 6.9, 8.72),
                    container.CFrame * CFrame.new(x, 0, 0),
                    ribColor:Lerp(freightColor, 0.28),
                    Enum.Material.CorrodedMetal, 0.06
                )
            end
        end
        if tier.Name == "High" then
            makePart(
                "HarborFreightRidgeCap" .. i,
                Vector3.new(21.4, 0.24, 8.9),
                container.CFrame * CFrame.new(0, 3.77, 0),
                ribColor, Enum.Material.DiamondPlate, 0.12
            )
        end
    end
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not arena or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)

    if variant == "Towers" then
        buildTowers(base, theme, tier)
    elseif variant == "Crossroads" then
        buildCrossroads(base, theme, tier)
    elseif variant == "Orbital" then
        buildOrbital(base, theme, tier)
    elseif variant == "Harbor" then
        buildHarbor(base, theme, tier)
    elseif variant == "Classic" then
        buildClassic(base, theme, tier)
    end
end

-- The same Base/Variant readiness event can arrive beside a VFX tier
-- update. Coalesce those into one full decorative geometry rebuild.
local rebuildPending = false
local watchedMap = nil

local function scheduleRebuild()
    if rebuildPending then return end
    rebuildPending = true
    task.defer(function()
        rebuildPending = false
        rebuild()
    end)
end

local function bindMap(generated)
    if disconnectMapWatch then
        disconnectMapWatch()
        disconnectMapWatch = nil
    end
    watchedMap = generated
    if generated then
        disconnectMapWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base", scheduleRebuild
        )
    else
        clear()
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == child then
        bindMap(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)

bindMap(workspace:FindFirstChild("GeneratedMap"))
scheduleRebuild()
