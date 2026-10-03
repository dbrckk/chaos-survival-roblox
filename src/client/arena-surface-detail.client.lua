local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "ArenaSurfaceDetailLocal"
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
    p.Material = material
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
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.035, 0)
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local countScale = tier.Name == "Low" and 0.55 or (tier.Name == "Medium" and 0.78 or 1)

    if variant == "Classic" then
        local lanes = math.max(4, math.floor(8 * countScale))
        for i = 1, lanes do
            local t = (i / (lanes + 1)) * 2 - 1
            local horizontal = i % 2 == 0
            local size = horizontal
                and Vector3.new(base.Size.X * 0.76, 0.05, 0.20)
                or Vector3.new(0.20, 0.05, base.Size.Z * 0.76)
            local offset = horizontal
                and Vector3.new(0, 0, t * halfZ * 0.74)
                or Vector3.new(t * halfX * 0.74, 0, 0)
            makePart(
                "ClassicInset" .. i,
                size,
                CFrame.new(center + offset),
                i % 3 == 0 and theme.Secondary or theme.Detail,
                Enum.Material.Metal,
                0.52
            )
        end
    elseif variant == "Towers" then
        local rings = math.max(3, math.floor(5 * countScale))
        for i = 1, rings do
            local radius = math.min(halfX, halfZ) * (0.18 + i * 0.12)
            local segments = tier.Name == "Low" and 4 or 8
            for s = 1, segments do
                local angle = ((s - 1) / segments) * math.pi * 2
                local tangent = angle + math.pi * 0.5
                local pos = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                makePart(
                    "TowerRing" .. i .. "_" .. s,
                    Vector3.new(math.max(3.0, radius * 0.42), 0.05, 0.16),
                    CFrame.new(pos) * CFrame.Angles(0, -tangent, 0),
                    i % 2 == 0 and theme.Secondary or theme.Detail,
                    Enum.Material.Metal,
                    0.56
                )
            end
        end
    elseif variant == "Crossroads" then
        local laneWidth = math.max(5, math.min(10, base.Size.X * 0.07))
        local offsets = {
            Vector3.new(-halfX * 0.34, 0, 0),
            Vector3.new(halfX * 0.34, 0, 0),
            Vector3.new(0, 0, -halfZ * 0.34),
            Vector3.new(0, 0, halfZ * 0.34),
        }
        for i, offset in ipairs(offsets) do
            local horizontal = i >= 3
            makePart(
                "CrossroadLaneInset" .. i,
                horizontal and Vector3.new(base.Size.X * 0.70, 0.05, 0.24)
                    or Vector3.new(0.24, 0.05, base.Size.Z * 0.70),
                CFrame.new(center + offset),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                tier.Name == "Low" and 0.72 or 0.58
            )
        end

        if tier.Name ~= "Low" then
            for i = 1, 8 do
                local angle = ((i - 1) / 8) * math.pi * 2
                local pos = center + Vector3.new(math.cos(angle) * halfX * 0.48, 0, math.sin(angle) * halfZ * 0.48)
                makePart(
                    "CrossroadNode" .. i,
                    Vector3.new(2.2, 0.05, 2.2),
                    CFrame.new(pos) * CFrame.Angles(0, -angle, 0),
                    theme.Detail,
                    Enum.Material.DiamondPlate,
                    0.42
                )
            end
        end
    elseif variant == "Orbital" then
        local segments = tier.Name == "Low" and 8 or (tier.Name == "Medium" and 12 or 16)
        local radius = math.min(halfX, halfZ) * 0.57
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local pos = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            makePart(
                "OrbitalSurfaceArc" .. i,
                Vector3.new(radius * 0.34, 0.05, 0.22),
                CFrame.new(pos) * CFrame.Angles(0, -tangent, 0),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                tier.Name == "Low" and 0.74 or 0.56
            )
        end

        local core = makePart(
            "OrbitalSurfaceCore",
            Vector3.new(math.min(base.Size.X, base.Size.Z) * 0.22, 0.05, math.min(base.Size.X, base.Size.Z) * 0.22),
            CFrame.new(center),
            theme.Structure,
            Enum.Material.Metal,
            0.48
        )
        core.Shape = Enum.PartType.Cylinder
        core.CFrame = core.CFrame * CFrame.Angles(0, 0, math.rad(90))
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(rebuild)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    task.defer(rebuild)
end)

rebuild()
