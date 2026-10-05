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

        local supportGlow = tier.Name == "High" and i % 2 == 1
            or tier.Name == "Medium" and i == 1
        if supportGlow then
            local glow = makePart(
                "UnderSupportGlow" .. i,
                Vector3.new(0.32, depth * 0.62, 2.95),
                support.CFrame,
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                tier.Name == "High" and 0.54 or 0.62
            )
            glow.CastShadow = false
        end
    end

    if variant == "Classic" then
        local chassisY = bottomY - 4.4
        local beamX = makePart(
            "UnderClassicChassisX",
            Vector3.new(base.Size.X * 0.62, 2.2, 6.0),
            CFrame.new(center.X, chassisY, center.Z),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.30),
            Enum.Material.DiamondPlate,
            tier.Name == "Low" and 0.30 or 0.14
        )
        local beamZ = makePart(
            "UnderClassicChassisZ",
            Vector3.new(6.0, 2.2, base.Size.Z * 0.62),
            CFrame.new(center.X, chassisY - 0.35, center.Z),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.36),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.32 or 0.16
        )
        beamX.CastShadow = false
        beamZ.CastShadow = false

        if tier.Name ~= "Low" then
            for side = -1, 1, 2 do
                local bay = makePart(
                    side < 0 and "UnderClassicDataBayL" or "UnderClassicDataBayR",
                    Vector3.new(13, 4.2, 8.0),
                    CFrame.new(
                        center + Vector3.new(side * halfX * 0.30, -6.7, halfZ * 0.14)
                    ),
                    theme.Detail:Lerp(VisualTheme.World.Deep, 0.24),
                    Enum.Material.DiamondPlate,
                    0.16
                )
                if tier.Name == "High" or side < 0 then
                    makePart(
                        side < 0 and "UnderClassicDataGlowL" or "UnderClassicDataGlowR",
                        Vector3.new(8.5, 0.30, 8.12),
                        bay.CFrame * CFrame.new(0, 2.26, 0),
                        side < 0 and theme.Accent or theme.Secondary,
                        Enum.Material.Neon,
                        tier.Name == "High" and 0.58 or 0.66
                    )
                end
            end
        end
    elseif variant == "Crossroads" then
        local junction = makePart(
            "UnderCrossroadsJunction",
            Vector3.new(15, 4.5, 15),
            CFrame.new(center + Vector3.new(0, -6.0, 0)),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.26),
            Enum.Material.Concrete,
            tier.Name == "Low" and 0.28 or 0.12
        )
        junction.CastShadow = false

        local trunks = {
            {
                name = "North",
                size = Vector3.new(7.0, 2.0, halfZ * 0.84),
                offset = Vector3.new(0, -4.9, -halfZ * 0.42),
            },
            {
                name = "South",
                size = Vector3.new(7.0, 2.0, halfZ * 0.84),
                offset = Vector3.new(0, -4.9, halfZ * 0.42),
            },
            {
                name = "West",
                size = Vector3.new(halfX * 0.84, 2.0, 7.0),
                offset = Vector3.new(-halfX * 0.42, -4.9, 0),
            },
            {
                name = "East",
                size = Vector3.new(halfX * 0.84, 2.0, 7.0),
                offset = Vector3.new(halfX * 0.42, -4.9, 0),
            },
        }
        for i, def in ipairs(trunks) do
            local trunk = makePart(
                "UnderCrossroadsTrunk" .. def.name,
                def.size,
                CFrame.new(center + def.offset),
                theme.Structure,
                Enum.Material.Concrete,
                tier.Name == "Low" and 0.34 or 0.18
            )
            trunk.CastShadow = false

            local trunkGlow = tier.Name == "High" and i % 2 == 1
                or tier.Name == "Medium" and i == 1
            if trunkGlow then
                local glowSize = def.size.X > def.size.Z
                    and Vector3.new(def.size.X * 0.70, 0.24, 7.15)
                    or Vector3.new(7.15, 0.24, def.size.Z * 0.70)
                makePart(
                    "UnderCrossroadsTrunkGlow" .. i,
                    glowSize,
                    trunk.CFrame * CFrame.new(0, 1.12, 0),
                    i % 2 == 0 and theme.Secondary or theme.Accent,
                    Enum.Material.Neon,
                    tier.Name == "High" and 0.60 or 0.68
                )
            end
        end
    end

    if variant == "Orbital" then
        local hub = makePart(
            "UnderOrbitalHub",
            Vector3.new(
                tier.Name == "Low" and 10 or 14,
                tier.Name == "Low" and 10 or 14,
                tier.Name == "Low" and 10 or 14
            ),
            CFrame.new(center + Vector3.new(0, -7.5, 0)),
            theme.Structure,
            Enum.Material.Metal,
            tier.Name == "Low" and 0.24 or 0.10
        )
        hub.Shape = Enum.PartType.Ball
        hub.CastShadow = false

        if tier.Name ~= "Low" then
            local spokeCount = tier.Name == "High" and 6 or 4
            for i = 1, spokeCount do
                local angle = ((i - 1) / spokeCount) * math.pi * 2
                local radius = math.min(halfX, halfZ) * 0.34
                local pos = center + Vector3.new(
                    math.cos(angle) * radius * 0.5,
                    -7.5,
                    math.sin(angle) * radius * 0.5
                )
                makePart(
                    "UnderOrbitalSpoke" .. i,
                    Vector3.new(radius, 0.70, 1.30),
                    CFrame.new(pos)
                        * CFrame.Angles(0, -(angle + math.pi * 0.5), 0),
                    i % 3 == 0 and theme.Secondary or theme.Detail,
                    i % 3 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                    i % 3 == 0 and 0.58 or 0.18
                )
            end
        end

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
                i % 3 == 0 and theme.Accent or theme.Structure,
                i % 3 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                i % 3 == 0 and 0.58 or 0.18
            )
        end
    elseif variant == "Towers" then
        local coreDepth = tier.Name == "Low" and 12 or 18
        local core = makePart(
            "UnderTowerCore",
            Vector3.new(10, coreDepth, 10),
            CFrame.new(
                center + Vector3.new(
                    0,
                    -(base.Size.Y * 0.5) - coreDepth * 0.5 + 0.2,
                    0
                )
            ),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.30),
            Enum.Material.CorrodedMetal,
            tier.Name == "Low" and 0.26 or 0.10
        )
        core.CastShadow = false

        if tier.Name ~= "Low" then
            makePart(
                "UnderTowerCoreGlow",
                Vector3.new(0.42, coreDepth * 0.72, 10.15),
                core.CFrame,
                theme.Accent,
                Enum.Material.Neon,
                0.46
            )

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
