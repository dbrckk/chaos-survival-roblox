local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "ArenaSilhouetteBreakupLocal"
folder.Parent = workspace

local mapConnection = nil

local function clear()
    folder:ClearAllChildren()
end

local function makePart(name, size, cframe, color, material, transparency, shape, castShadow)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = castShadow == true
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Transparency = transparency or 0
    if shape then
        p.Shape = shape
    end
    p.Parent = folder
    return p
end

local function makeWedge(name, size, cframe, color, material, transparency, castShadow)
    local p = Instance.new("WedgePart")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = castShadow == true
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Transparency = transparency or 0
    p.Parent = folder
    return p
end

local function localFrame(base, x, y, z, yaw, pitch, roll)
    return base.CFrame
        * CFrame.new(x, y, z)
        * CFrame.Angles(
            math.rad(pitch or 0),
            math.rad(yaw or 0),
            math.rad(roll or 0)
        )
end

local function classic(base, theme, high)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local dark = theme.Structure:Lerp(VisualTheme.World.Deep, 0.42)

    local mast = makePart(
        "ClassicServiceMast",
        Vector3.new(2.4, high and 22 or 17, 2.4),
        localFrame(base, hx + 10, high and 11.7 or 9.2, hz * 0.42, -8),
        dark,
        Enum.Material.Metal,
        0.05,
        nil,
        high
    )

    makePart(
        "ClassicServiceBoom",
        Vector3.new(high and 17 or 13, 1.0, 1.5),
        mast.CFrame * CFrame.new(-6.0, mast.Size.Y * 0.34, 0)
            * CFrame.Angles(0, 0, math.rad(-6)),
        theme.Detail,
        Enum.Material.DiamondPlate,
        0.10,
        nil,
        high
    )

    makeWedge(
        "ClassicServiceBrace",
        Vector3.new(1.2, high and 8.5 or 6.2, 1.2),
        mast.CFrame * CFrame.new(-3.4, 1.6, 0) * CFrame.Angles(0, 0, math.rad(24)),
        dark,
        Enum.Material.Metal,
        0.08,
        high
    )

    if high then
        local dish = makePart(
            "ClassicSignalDish",
            Vector3.new(4.6, 0.70, 4.6),
            mast.CFrame * CFrame.new(0.2, mast.Size.Y * 0.43, -0.4)
                * CFrame.Angles(math.rad(15), 0, math.rad(90)),
            theme.Detail,
            Enum.Material.Metal,
            0.12,
            Enum.PartType.Cylinder,
            true
        )
        makePart(
            "ClassicSignalDishFeed",
            Vector3.new(0.30, 2.8, 0.30),
            dish.CFrame * CFrame.new(0, 1.55, 0),
            theme.Accent,
            Enum.Material.Neon,
            0.52,
            nil,
            false
        )
    end
end

local function towers(base, theme, high)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local dark = theme.Structure:Lerp(VisualTheme.World.Void, 0.30)

    local heights = high and {24, 18, 13} or {20, 14}
    for i, height in ipairs(heights) do
        local stack = makePart(
            "TowerExhaustStack" .. i,
            Vector3.new(3.1, height, 3.1),
            localFrame(
                base,
                -hx - 10 - (i - 1) * 3.6,
                height * 0.5 + 0.6,
                -hz * 0.36 + (i - 1) * 2.1,
                0
            ),
            dark:Lerp(theme.Detail, i * 0.06),
            Enum.Material.CorrodedMetal,
            0.06,
            Enum.PartType.Cylinder,
            high
        )
        makePart(
            "TowerExhaustCap" .. i,
            Vector3.new(4.1, 0.8, 4.1),
            stack.CFrame * CFrame.new(0, height * 0.5 + 0.4, 0),
            theme.Detail,
            Enum.Material.Metal,
            0.10,
            Enum.PartType.Cylinder,
            high
        )
    end

    makePart(
        "TowerServiceCatwalk",
        Vector3.new(high and 17 or 12, 0.75, 2.4),
        localFrame(base, -hx - 13, high and 12.5 or 10.5, -hz * 0.29, -12),
        theme.Detail,
        Enum.Material.DiamondPlate,
        0.10,
        nil,
        high
    )

    makePart(
        "TowerServiceStatus",
        Vector3.new(0.28, high and 7.5 or 5.0, 0.55),
        localFrame(base, -hx - 8.7, high and 11.7 or 9.4, -hz * 0.31, -12),
        theme.Accent,
        Enum.Material.Neon,
        0.58,
        nil,
        false
    )
end

local function crossroads(base, theme, high)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local dark = theme.Structure:Lerp(VisualTheme.World.Deep, 0.34)

    local left = makePart(
        "CrossroadsServicePylonL",
        Vector3.new(2.2, high and 13 or 10, 2.8),
        localFrame(base, -hx - 9, high and 7.2 or 5.7, hz * 0.22, 0),
        dark,
        Enum.Material.Metal,
        0.06,
        nil,
        high
    )
    local right = makePart(
        "CrossroadsServicePylonR",
        Vector3.new(2.2, high and 9 or 7, 2.8),
        localFrame(base, -hx - 9, high and 5.2 or 4.2, hz * 0.44, 0),
        dark:Lerp(theme.Detail, 0.12),
        Enum.Material.Metal,
        0.08,
        nil,
        high
    )

    makePart(
        "CrossroadsServiceBeam",
        Vector3.new(2.0, 0.9, hz * 0.28),
        CFrame.new((left.Position + right.Position) * 0.5 + Vector3.new(0, 3.8, 0))
            * CFrame.Angles(math.rad(9), 0, 0),
        theme.Detail,
        Enum.Material.DiamondPlate,
        0.10,
        nil,
        high
    )

    makeWedge(
        "CrossroadsServiceCanopy",
        Vector3.new(7.5, 1.1, high and 10 or 7.5),
        localFrame(base, -hx - 8.4, high and 11.0 or 8.7, hz * 0.34, 0, 0, -7),
        dark,
        Enum.Material.Metal,
        0.10,
        high
    )

    makePart(
        "CrossroadsServiceMarker",
        Vector3.new(0.35, 4.0, 0.55),
        left.CFrame * CFrame.new(0, 2.1, -1.55),
        theme.Secondary,
        Enum.Material.Neon,
        0.60,
        nil,
        false
    )
end

local function orbital(base, theme, high)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local dark = theme.Structure:Lerp(VisualTheme.World.Deep, 0.38)

    local spineHeight = high and 24 or 18
    local spine = makePart(
        "OrbitalDockSpine",
        Vector3.new(3.6, spineHeight, 3.6),
        localFrame(base, hx * 0.62, spineHeight * 0.5 + 1.0, -hz - 11, 12),
        dark,
        Enum.Material.Metal,
        0.05,
        nil,
        high
    )

    local ribCount = high and 4 or 3
    for i = 1, ribCount do
        local length = 7 + i * 1.9
        makePart(
            "OrbitalDockRib" .. i,
            Vector3.new(length, 0.65, 1.10),
            spine.CFrame
                * CFrame.new((i % 2 == 0 and 1 or -1) * length * 0.35, -5.0 + i * 3.2, 0)
                * CFrame.Angles(0, 0, math.rad(i % 2 == 0 and 8 or -8)),
            i == ribCount and theme.Detail or dark:Lerp(theme.Detail, 0.18),
            Enum.Material.Metal,
            0.10,
            nil,
            high
        )
    end

    local node = makePart(
        "OrbitalDockNode",
        Vector3.new(high and 5.8 or 4.6, high and 5.8 or 4.6, high and 5.8 or 4.6),
        spine.CFrame * CFrame.new(high and -7.5 or -5.8, 5.0, -0.4),
        theme.Detail,
        Enum.Material.Metal,
        0.08,
        Enum.PartType.Ball,
        high
    )

    makePart(
        "OrbitalDockNodeAccent",
        Vector3.new(0.30, node.Size.Y * 0.58, 0.45),
        node.CFrame * CFrame.new(0, 0, -node.Size.Z * 0.5 - 0.08),
        theme.Secondary,
        Enum.Material.Neon,
        0.60,
        nil,
        false
    )
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
    local high = tier.Name == "High"

    if variant == "Towers" then
        towers(base, theme, high)
    elseif variant == "Crossroads" then
        crossroads(base, theme, high)
    elseif variant == "Orbital" then
        orbital(base, theme, high)
    else
        classic(base, theme, high)
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
