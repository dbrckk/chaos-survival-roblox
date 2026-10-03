local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "ArenaUnderstructureLocal"
folder.Parent = workspace

local function clear()
    folder:ClearAllChildren()
end

local function makePart(name, size, cframe, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = material or Enum.Material.Metal
    p.Color = color
    p.Transparency = transparency or 0
    p.Parent = folder
    return p
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
    local center = base.Position
    local bottomY = center.Y - base.Size.Y * 0.5
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5

    local ribCount = tier.Name == "Low" and 4 or (tier.Name == "Medium" and 6 or 8)
    for i = 1, ribCount do
        local t = ribCount == 1 and 0 or ((i - 1) / (ribCount - 1)) * 2 - 1
        local horizontal = i % 2 == 0

        local size = horizontal
            and Vector3.new(base.Size.X * 0.82, 0.75, 1.15)
            or Vector3.new(1.15, 0.75, base.Size.Z * 0.82)
        local offset = horizontal
            and Vector3.new(0, -1.0 - ((i % 3) * 0.22), t * halfZ * 0.68)
            or Vector3.new(t * halfX * 0.68, -1.0 - ((i % 3) * 0.22), 0)

        makePart(
            "UnderRib" .. i,
            size,
            CFrame.new(Vector3.new(center.X, bottomY, center.Z) + offset),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.38),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.24 or 0.12
        )
    end

    local cornerOffsets = {
        Vector3.new(-halfX * 0.72, 0, -halfZ * 0.72),
        Vector3.new(halfX * 0.72, 0, -halfZ * 0.72),
        Vector3.new(-halfX * 0.72, 0, halfZ * 0.72),
        Vector3.new(halfX * 0.72, 0, halfZ * 0.72),
    }

    for i, offset in ipairs(cornerOffsets) do
        local depth = variant == "Towers" and 12 or (variant == "Orbital" and 8 or 9)
        local support = makePart(
            "UnderSupport" .. i,
            Vector3.new(2.8, depth, 2.8),
            CFrame.new(center + Vector3.new(offset.X, -(base.Size.Y * 0.5) - depth * 0.5 + 0.4, offset.Z)),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.48),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.28 or 0.14
        )

        if tier.Name ~= "Low" then
            local glow = makePart(
                "UnderSupportGlow" .. i,
                Vector3.new(0.32, depth * 0.62, 2.95),
                support.CFrame,
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.48
            )
            glow.CastShadow = false
        end
    end

    if variant == "Orbital" then
        local segments = tier.Name == "Low" and 6 or 10
        local radius = math.min(halfX, halfZ) * 0.64
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local pos = center + Vector3.new(
                math.cos(angle) * radius,
                -(base.Size.Y * 0.5) - 2.0,
                math.sin(angle) * radius
            )
            makePart(
                "UnderOrbitalArc" .. i,
                Vector3.new(radius * 0.34, 0.45, 1.15),
                CFrame.new(pos) * CFrame.Angles(0, -tangent, 0),
                i % 2 == 0 and theme.Accent or theme.Structure,
                i % 2 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                i % 2 == 0 and 0.50 or 0.18
            )
        end
    elseif variant == "Towers" and tier.Name ~= "Low" then
        for i = 1, 4 do
            local angle = math.rad(45 + (i - 1) * 90)
            local pos = center + Vector3.new(
                math.cos(angle) * halfX * 0.56,
                -(base.Size.Y * 0.5) - 4.0,
                math.sin(angle) * halfZ * 0.56
            )
            makePart(
                "UnderTowerBrace" .. i,
                Vector3.new(2.2, 10, 2.2),
                CFrame.new(pos) * CFrame.Angles(math.rad(22), 0, math.rad(22)),
                theme.Detail,
                Enum.Material.Metal,
                0.22
            )
        end
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
