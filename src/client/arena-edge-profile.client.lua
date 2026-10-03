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

local function addVariantEdgeLanguage(base, theme, tier, variant)
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local surfaceY = base.Size.Y * 0.5 + 0.16
    local low = tier.Name == "Low"

    if variant == "Towers" then
        local offsets = {
            {-halfX - 1.0, -halfZ * 0.34},
            {-halfX - 1.0, halfZ * 0.34},
            {halfX + 1.0, -halfZ * 0.34},
            {halfX + 1.0, halfZ * 0.34},
            {-halfX * 0.34, -halfZ - 1.0},
            {halfX * 0.34, -halfZ - 1.0},
            {-halfX * 0.34, halfZ + 1.0},
            {halfX * 0.34, halfZ + 1.0},
        }
        local count = low and 4 or #offsets
        for i = 1, count do
            local x, z = offsets[i][1], offsets[i][2]
            local buttress = makePart(
                "TowerEdgeButtress" .. i,
                Vector3.new(1.35, 4.8, 2.4),
                base.CFrame * CFrame.new(x, -1.8, z),
                theme.Structure:Lerp(VisualTheme.World.Void, 0.34),
                Enum.Material.Metal,
                low and 0.28 or 0.12
            )
            if not low then
                makePart(
                    "TowerEdgeButtressGlow" .. i,
                    Vector3.new(0.26, 3.0, 2.5),
                    buttress.CFrame * CFrame.new(0, 0.35, 0),
                    i % 2 == 0 and theme.Secondary or theme.Accent,
                    Enum.Material.Neon,
                    0.46
                )
            end
        end
    elseif variant == "Crossroads" then
        local length = low and 5.4 or 7.2
        local alpha = low and 0.62 or 0.38
        local gates = {
            {x = -7.0, z = -halfZ - length * 0.5, sx = 0.34, sz = length},
            {x = 7.0, z = -halfZ - length * 0.5, sx = 0.34, sz = length},
            {x = -7.0, z = halfZ + length * 0.5, sx = 0.34, sz = length},
            {x = 7.0, z = halfZ + length * 0.5, sx = 0.34, sz = length},
            {x = -halfX - length * 0.5, z = -7.0, sx = length, sz = 0.34},
            {x = -halfX - length * 0.5, z = 7.0, sx = length, sz = 0.34},
            {x = halfX + length * 0.5, z = -7.0, sx = length, sz = 0.34},
            {x = halfX + length * 0.5, z = 7.0, sx = length, sz = 0.34},
        }
        for i, def in ipairs(gates) do
            makePart(
                "CrossroadsExitRail" .. i,
                Vector3.new(def.sx, 0.20, def.sz),
                base.CFrame * CFrame.new(def.x, surfaceY, def.z),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                alpha
            )
        end

        if not low then
            local caps = {
                {0, -halfZ - length, base.Size.X * 0.22, 0.28},
                {0, halfZ + length, base.Size.X * 0.22, 0.28},
                {-halfX - length, 0, 0.28, base.Size.Z * 0.22},
                {halfX + length, 0, 0.28, base.Size.Z * 0.22},
            }
            for i, def in ipairs(caps) do
                makePart(
                    "CrossroadsExitCap" .. i,
                    Vector3.new(def[3], 0.24, def[4]),
                    base.CFrame * CFrame.new(def[1], surfaceY + 0.02, def[2]),
                    theme.Detail,
                    Enum.Material.Metal,
                    0.34
                )
            end
        end
    elseif variant == "Orbital" then
        local count = low and 8 or (tier.Name == "Medium" and 10 or 14)
        local radius = math.min(halfX, halfZ) * 0.90
        for i = 1, count do
            local angle = ((i - 1) / count) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local pos = Vector3.new(
                math.cos(angle) * radius,
                surfaceY,
                math.sin(angle) * radius
            )
            makePart(
                "OrbitalEdgeTick" .. i,
                Vector3.new(low and 3.4 or 4.8, 0.16, low and 0.34 or 0.46),
                base.CFrame
                    * CFrame.new(pos)
                    * CFrame.Angles(0, -tangent, 0),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                i % 2 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                low and 0.68 or 0.42
            )
        end
    else
        local count = low and 4 or (tier.Name == "Medium" and 6 or 8)
        for i = 1, count do
            local t = (i / (count + 1)) * 2 - 1
            local horizontal = i % 2 == 0
            local x = horizontal and t * halfX * 0.78 or (i % 4 < 2 and -halfX - 0.72 or halfX + 0.72)
            local z = horizontal and (i % 4 < 2 and -halfZ - 0.72 or halfZ + 0.72) or t * halfZ * 0.78
            local size = horizontal
                and Vector3.new(3.8, 0.22, 0.72)
                or Vector3.new(0.72, 0.22, 3.8)
            makePart(
                "ClassicEdgeTick" .. i,
                size,
                base.CFrame * CFrame.new(x, surfaceY, z),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                low and 0.66 or 0.44
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

    addVariantEdgeLanguage(base, theme, tier, variant)

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
