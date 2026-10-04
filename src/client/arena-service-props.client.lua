local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "ArenaServicePropsLocal"
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


local function addSurfaceLabel(part, text, color, tier, face)
    if tier.Name == "Low" then
        return
    end

    local gui = Instance.new("SurfaceGui")
    gui.Name = "DiegeticLabel"
    gui.Adornee = part
    gui.Face = face or Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0.62
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = tier.Name == "High" and 38 or 28
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "Marking"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextColor3 = color
    label.TextTransparency = tier.Name == "High" and 0.12 or 0.24
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.54
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0.12, 0)
    padding.PaddingRight = UDim.new(0.12, 0)
    padding.PaddingTop = UDim.new(0.22, 0)
    padding.PaddingBottom = UDim.new(0.22, 0)
    padding.Parent = label
end

local function localFrame(base, x, y, z, yaw)
    return base.CFrame
        * CFrame.new(x, y, z)
        * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local function budget(tierName)
    if tierName == "Low" then
        return 2
    elseif tierName == "High" then
        return 6
    end
    return 4
end

local function addClassic(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local defs = {
        {-hx * 0.78, -hz * 0.78, 45},
        {hx * 0.80, -hz * 0.72, -45},
        {-hx * 0.72, hz * 0.80, -135},
        {hx * 0.76, hz * 0.76, 135},
        {-hx * 0.12, -hz * 0.90, 0},
        {hx * 0.18, hz * 0.90, 180},
    }

    for i = 1, math.min(budget(tier.Name), #defs) do
        local d = defs[i]
        local frame = localFrame(base, d[1], 1.5, d[2], d[3])
        local tripod = makePart(
            "ClassicCameraTripod" .. i,
            Vector3.new(0.7, 2.7, 0.7),
            frame,
            theme.Structure,
            Enum.Material.Metal,
            0.10
        )
        local camera = makePart(
            "ClassicCameraHead" .. i,
            Vector3.new(2.1, 1.0, 1.15),
            tripod.CFrame * CFrame.new(0, 1.55, -0.20),
            theme.Detail,
            Enum.Material.DiamondPlate,
            0.05
        )
        makePart(
            "ClassicCameraLens" .. i,
            Vector3.new(0.72, 0.72, 0.18),
            camera.CFrame * CFrame.new(0, 0, -0.62),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            0.28,
            Enum.PartType.Cylinder
        )
        addSurfaceLabel(camera, string.format("CAM %02d", i), theme.Accent, tier, Enum.NormalId.Top)
    end
end

local function addTowers(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local defs = {
        {-hx * 0.82, -hz * 0.74},
        {hx * 0.78, -hz * 0.80},
        {-hx * 0.80, hz * 0.76},
        {hx * 0.82, hz * 0.72},
        {-hx * 0.18, hz * 0.88},
        {hx * 0.24, -hz * 0.88},
    }

    for i = 1, math.min(budget(tier.Name), #defs) do
        local d = defs[i]
        local crate = makePart(
            "TowerMaintenanceCrate" .. i,
            Vector3.new(3.6, 2.2, 2.8),
            localFrame(base, d[1], 1.2, d[2], (i % 2) * 90),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.18),
            Enum.Material.CorrodedMetal,
            0.08
        )

        addSurfaceLabel(crate, string.format("MAINT %02d", i), theme.Secondary, tier, Enum.NormalId.Front)

        if tier.Name ~= "Low" then
            makePart(
                "TowerMaintenanceLatch" .. i,
                Vector3.new(2.0, 0.22, 2.92),
                crate.CFrame * CFrame.new(0, 1.18, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.48
            )
        end
    end
end

local function addCrossroads(base, theme, tier)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local defs = {
        {-hx * 0.84, -hz * 0.62, 0},
        {hx * 0.84, hz * 0.62, 0},
        {-hx * 0.58, hz * 0.84, 90},
        {hx * 0.58, -hz * 0.84, 90},
        {-hx * 0.16, -hz * 0.88, 0},
        {hx * 0.14, hz * 0.88, 0},
    }

    for i = 1, math.min(budget(tier.Name), #defs) do
        local d = defs[i]
        local frame = localFrame(base, d[1], 0.9, d[2], d[3])
        local post = makePart(
            "CrossroadsBollard" .. i,
            Vector3.new(0.9, 1.8, 0.9),
            frame,
            theme.Structure,
            Enum.Material.Concrete,
            0.08
        )
        addSurfaceLabel(post, string.format("L%02d", i), theme.Accent, tier, Enum.NormalId.Front)
        makePart(
            "CrossroadsBollardCap" .. i,
            Vector3.new(1.05, 0.26, 1.05),
            post.CFrame * CFrame.new(0, 1.0, 0),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.62 or 0.34
        )

        if tier.Name == "High" and i <= 4 then
            makePart(
                "CrossroadsBarrierStub" .. i,
                Vector3.new(4.5, 0.34, 0.42),
                post.CFrame * CFrame.new(i % 2 == 0 and -2.2 or 2.2, 0.55, 0),
                theme.Detail,
                Enum.Material.Metal,
                0.18
            )
        end
    end
end

local function addOrbital(base, theme, tier)
    local radius = math.min(base.Size.X, base.Size.Z) * 0.43
    local count = budget(tier.Name)

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2 + math.rad(12)
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local body = makePart(
            "OrbitalServiceCanister" .. i,
            Vector3.new(2.0, 3.2, 2.0),
            base.CFrame
                * CFrame.new(x, 1.7, z)
                * CFrame.Angles(0, -angle, math.rad(90)),
            theme.Structure,
            Enum.Material.SmoothPlastic,
            0.08,
            Enum.PartType.Cylinder
        )

        makePart(
            "OrbitalServiceCanisterBand" .. i,
            Vector3.new(0.28, 3.30, 2.10),
            body.CFrame,
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.64 or 0.38
        )
        addSurfaceLabel(body, string.format("AUX-%02d", i), theme.Accent, tier, Enum.NormalId.Top)
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
        addTowers(base, theme, tier)
    elseif variant == "Crossroads" then
        addCrossroads(base, theme, tier)
    elseif variant == "Orbital" then
        addOrbital(base, theme, tier)
    else
        addClassic(base, theme, tier)
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
