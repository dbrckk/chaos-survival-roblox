local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "ArenaEdgeProfileLocal"
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
    local center = base.Position
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local topY = center.Y + base.Size.Y * 0.5

    local dark = theme.Structure:Lerp(VisualTheme.World.Void, 0.48)
    local lipHeight = variant == "Towers" and 2.2 or 1.6

    local sides = {
        {
            name = "North",
            lipSize = Vector3.new(base.Size.X + 1.8, lipHeight, 1.5),
            lipPos = Vector3.new(0, topY - lipHeight * 0.5 - 0.15, -halfZ - 0.45),
            trimSize = Vector3.new(base.Size.X + 1.2, 0.16, 0.22),
            trimPos = Vector3.new(0, topY + 0.07, -halfZ - 0.18),
        },
        {
            name = "South",
            lipSize = Vector3.new(base.Size.X + 1.8, lipHeight, 1.5),
            lipPos = Vector3.new(0, topY - lipHeight * 0.5 - 0.15, halfZ + 0.45),
            trimSize = Vector3.new(base.Size.X + 1.2, 0.16, 0.22),
            trimPos = Vector3.new(0, topY + 0.07, halfZ + 0.18),
        },
        {
            name = "West",
            lipSize = Vector3.new(1.5, lipHeight, base.Size.Z + 1.8),
            lipPos = Vector3.new(-halfX - 0.45, topY - lipHeight * 0.5 - 0.15, 0),
            trimSize = Vector3.new(0.22, 0.16, base.Size.Z + 1.2),
            trimPos = Vector3.new(-halfX - 0.18, topY + 0.07, 0),
        },
        {
            name = "East",
            lipSize = Vector3.new(1.5, lipHeight, base.Size.Z + 1.8),
            lipPos = Vector3.new(halfX + 0.45, topY - lipHeight * 0.5 - 0.15, 0),
            trimSize = Vector3.new(0.22, 0.16, base.Size.Z + 1.2),
            trimPos = Vector3.new(halfX + 0.18, topY + 0.07, 0),
        },
    }

    for i, side in ipairs(sides) do
        makePart(
            "ArenaEdgeLip" .. side.name,
            side.lipSize,
            CFrame.new(center.X + side.lipPos.X, side.lipPos.Y, center.Z + side.lipPos.Z),
            dark,
            Enum.Material.Metal,
            tier.Name == "Low" and 0.22 or 0.10
        )

        if tier.Name ~= "Low" then
            local trim = makePart(
                "ArenaEdgeTrim" .. side.name,
                side.trimSize,
                CFrame.new(center.X + side.trimPos.X, side.trimPos.Y, center.Z + side.trimPos.Z),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                tier.Name == "Medium" and 0.52 or 0.38
            )
            trim:SetAttribute("EdgeBaseColor", trim.Color)
        end
    end

    if tier.Name == "High" then
        local cornerOffsets = {
            Vector3.new(-halfX - 0.55, topY - 0.45, -halfZ - 0.55),
            Vector3.new(halfX + 0.55, topY - 0.45, -halfZ - 0.55),
            Vector3.new(-halfX - 0.55, topY - 0.45, halfZ + 0.55),
            Vector3.new(halfX + 0.55, topY - 0.45, halfZ + 0.55),
        }
        for i, pos in ipairs(cornerOffsets) do
            makePart(
                "ArenaEdgeCorner" .. i,
                Vector3.new(1.7, 2.4, 1.7),
                CFrame.new(center.X + pos.X, pos.Y, center.Z + pos.Z),
                theme.Detail,
                Enum.Material.Metal,
                0.16
            )
        end
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
