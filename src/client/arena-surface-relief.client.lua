local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "ArenaSurfaceReliefLocal"
folder.Parent = workspace

local mapConnection = nil

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
    part.Color = color
    part.Material = material or Enum.Material.Metal
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function makeWedge(name, size, cframe, color, transparency)
    local part = Instance.new("WedgePart")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = true
    part.Color = color
    part.Material = Enum.Material.Metal
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function addCornerBevels(base, theme, tier)
    if tier.Name ~= "High" then
        return
    end

    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local y = base.Size.Y * 0.5 + 0.13
    local defs = {
        {Vector3.new(-hx + 2.8, y, -hz + 2.8), 0},
        {Vector3.new(hx - 2.8, y, -hz + 2.8), 90},
        {Vector3.new(hx - 2.8, y, hz - 2.8), 180},
        {Vector3.new(-hx + 2.8, y, hz - 2.8), 270},
    }

    for i, def in ipairs(defs) do
        local wedge = makeWedge(
            "ReliefCornerBevel" .. i,
            Vector3.new(5.2, 0.28, 5.2),
            base.CFrame
                * CFrame.new(def[1])
                * CFrame.Angles(0, math.rad(def[2]), 0),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.22),
            0.12
        )
        wedge.CastShadow = true

        makePart(
            "ReliefCornerLens" .. i,
            Vector3.new(2.8, 0.12, 0.34),
            wedge.CFrame * CFrame.new(0.5, 0.20, -1.35),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Glass,
            0.38,
            false
        )
    end
end

local function addServiceFasteners(base, theme, tier)
    if tier.Name == "Low" then
        return
    end

    local count = tier.Name == "High" and 12 or 6
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local y = base.Size.Y * 0.5 + 0.16

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local x = math.cos(angle) * hx * 0.82
        local z = math.sin(angle) * hz * 0.82
        local bolt = makePart(
            "ReliefFastener" .. i,
            Vector3.new(0.44, 0.16, 0.44),
            base.CFrame * CFrame.new(x, y, z),
            theme.Detail:Lerp(Color3.new(1, 1, 1), 0.08),
            Enum.Material.Metal,
            tier.Name == "High" and 0.06 or 0.18,
            tier.Name == "High"
        )
        bolt.Shape = Enum.PartType.Cylinder
        bolt.CFrame = bolt.CFrame * CFrame.Angles(0, 0, math.rad(90))
    end
end

local function addClassic(base, theme, tier)
    local y = base.Size.Y * 0.5 + 0.11
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local count = tier.Name == "High" and 6 or 4

    for i = 1, count do
        local row = (i - 1) % 2
        local col = math.floor((i - 1) / 2)
        local x = (-0.40 + col * 0.40) * hx
        local z = row == 0 and -hz * 0.56 or hz * 0.56

        local hatch = makePart(
            "ClassicReliefHatch" .. i,
            Vector3.new(8.2, 0.16, 4.6),
            base.CFrame * CFrame.new(x, y, z),
            theme.Surface:Lerp(theme.Structure, 0.58),
            Enum.Material.DiamondPlate,
            0.08,
            tier.Name == "High"
        )

        local litInset = tier.Name == "High" and i % 2 == 1
        makePart(
            "ClassicReliefHatchInset" .. i,
            Vector3.new(5.4, 0.08, 0.22),
            hatch.CFrame * CFrame.new(0, 0.13, 0),
            litInset and theme.Accent or theme.Detail,
            litInset and Enum.Material.Neon or Enum.Material.Metal,
            litInset and 0.62 or 0.26,
            false
        )
    end
end

local function addTowers(base, theme, tier)
    local y = base.Size.Y * 0.5 + 0.13
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local count = tier.Name == "High" and 8 or 4

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local tangent = angle + math.pi * 0.5
        local x = math.cos(angle) * hx * 0.52
        local z = math.sin(angle) * hz * 0.52
        local rib = makePart(
            "TowerReliefRib" .. i,
            Vector3.new(10.5, 0.22, 1.0),
            base.CFrame
                * CFrame.new(x, y, z)
                * CFrame.Angles(0, -tangent, 0),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.16),
            i % 3 == 0 and Enum.Material.CorrodedMetal or Enum.Material.Metal,
            0.08,
            tier.Name == "High"
        )

        if tier.Name == "High" then
            makePart(
                "TowerReliefRibLens" .. i,
                Vector3.new(5.8, 0.09, 0.20),
                rib.CFrame * CFrame.new(0, 0.17, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Glass,
                0.34,
                false
            )
        end
    end
end

local function addCrossroads(base, theme, tier)
    local y = base.Size.Y * 0.5 + 0.10
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local stripCount = tier.Name == "High" and 7 or 4

    for lane = 1, 4 do
        local horizontal = lane <= 2
        local side = lane % 2 == 0 and 1 or -1
        for i = 1, stripCount do
            local t = (i / (stripCount + 1)) * 2 - 1
            local size = horizontal
                and Vector3.new(3.6, 0.14, 0.70)
                or Vector3.new(0.70, 0.14, 3.6)
            local offset = horizontal
                and Vector3.new(t * hx * 0.62, y, side * hz * 0.34)
                or Vector3.new(side * hx * 0.34, y, t * hz * 0.62)

            makePart(
                "CrossroadsRumble" .. lane .. "_" .. i,
                size,
                base.CFrame * CFrame.new(offset),
                i % 3 == 0 and theme.Secondary or theme.Detail,
                Enum.Material.Metal,
                tier.Name == "High" and 0.20 or 0.32,
                false
            )
        end
    end
end

local function addOrbital(base, theme, tier)
    local y = base.Size.Y * 0.5 + 0.10
    local radius = math.min(base.Size.X, base.Size.Z) * 0.28
    local count = tier.Name == "High" and 14 or 8

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local tangent = angle + math.pi * 0.5
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local segment = makePart(
            "OrbitalReliefSegment" .. i,
            Vector3.new(5.6, 0.18, 1.15),
            base.CFrame
                * CFrame.new(x, y, z)
                * CFrame.Angles(0, -tangent, 0),
            i % 2 == 0 and theme.Structure or theme.Detail,
            i % 4 == 0 and Enum.Material.Glass or Enum.Material.Metal,
            i % 4 == 0 and 0.34 or 0.10,
            tier.Name == "High"
        )

        local litSegment = tier.Name == "High" and i % 4 == 0
            or tier.Name == "Medium" and i == 4
        if litSegment then
            makePart(
                "OrbitalReliefGlow" .. i,
                Vector3.new(3.2, 0.08, 0.18),
                segment.CFrame * CFrame.new(0, 0.15, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                tier.Name == "High" and 0.58 or 0.68,
                false
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

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    if tier.Name == "Low" then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)

    addCornerBevels(base, theme, tier)
    addServiceFasteners(base, theme, tier)

    if variant == "Towers" then
        addTowers(base, theme, tier)
    elseif variant == "Crossroads" then
        addCrossroads(base, theme, tier)
    elseif variant == "Orbital" then
        addOrbital(base, theme, tier)
    else
        addClassic(base, theme, tier)
    end
end

local function bindMap()
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.delay(0.06, rebuild)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            bindMap()
            rebuild()
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
        bindMap()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuild)

bindMap()
rebuild()
