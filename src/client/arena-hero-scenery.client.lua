local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "ArenaHeroSceneryLocal"
folder.Parent = workspace

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
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function makeWedge(name, size, cframe, color, material, transparency, castShadow)
    local part = Instance.new("WedgePart")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = castShadow == true
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function makeSurfaceLabel(part, face, text, color, tier)
    if tier.Name == "Low" then
        return nil
    end

    local gui = Instance.new("SurfaceGui")
    gui.Name = "HeroStoryLabel"
    gui.Face = face or Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = tier.Name == "High" and 48 or 36
    gui.LightInfluence = 0
    gui.AlwaysOnTop = false
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = true
    label.TextStrokeColor3 = Color3.fromRGB(3, 6, 10)
    label.TextStrokeTransparency = 0.44
    label.Parent = gui

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0.06, 0)
    padding.PaddingRight = UDim.new(0.06, 0)
    padding.PaddingTop = UDim.new(0.12, 0)
    padding.PaddingBottom = UDim.new(0.12, 0)
    padding.Parent = label

    return gui
end

local function localFrame(base, x, y, z, yaw)
    return base.CFrame
        * CFrame.new(x, y, z)
        * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local function addPylon(base, index, x, z, height, theme, tier, yaw)
    local structure = makePart(
        "HeroPylon" .. index,
        Vector3.new(2.8, height, 2.8),
        localFrame(base, x, height * 0.5 + 0.7, z, yaw),
        theme.Structure:Lerp(VisualTheme.World.Deep, 0.22),
        Enum.Material.Metal,
        tier.Name == "Low" and 0.10 or 0.03,
        tier.Name == "High"
    )

    local strip = makePart(
        "HeroPylonGlow" .. index,
        Vector3.new(0.34, height * 0.68, 2.94),
        structure.CFrame * CFrame.new(0, 0, -0.04),
        index % 2 == 0 and theme.Secondary or theme.Accent,
        Enum.Material.Neon,
        tier.Name == "Low" and 0.46 or 0.22,
        false
    )

    if tier.Name == "High" then
        makePart(
            "HeroPylonCap" .. index,
            Vector3.new(5.6, 0.75, 1.15),
            structure.CFrame * CFrame.new(0, height * 0.5 - 0.85, 0),
            theme.Detail,
            Enum.Material.DiamondPlate,
            0.12,
            true
        )
    end

    return structure, strip
end

local function addClassicBroadcastLandmark(base, theme, tier)
    local hz = base.Size.Z * 0.5
    local frame = localFrame(base, 0, 0, -hz - 15, 0)
    local height = tier.Name == "Low" and 11 or 14

    for side = -1, 1, 2 do
        makePart(
            side < 0 and "ClassicBroadcastTowerL" or "ClassicBroadcastTowerR",
            Vector3.new(2.2, height, 2.2),
            frame * CFrame.new(side * 8.2, height * 0.5 + 0.8, 0),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.22),
            Enum.Material.Metal,
            0.05,
            tier.Name == "High"
        )
    end

    makePart(
        "ClassicBroadcastBridge",
        Vector3.new(19, 1.1, 2.2),
        frame * CFrame.new(0, height + 0.15, 0),
        theme.Detail,
        Enum.Material.DiamondPlate,
        0.08,
        tier.Name == "High"
    )

    local screen = makePart(
        "ClassicBroadcastScreen",
        Vector3.new(12.6, 4.8, 0.55),
        frame * CFrame.new(0, height * 0.64, -1.15),
        VisualTheme.World.Deep,
        Enum.Material.Metal,
        0.02,
        false
    )
    makeSurfaceLabel(
        screen,
        Enum.NormalId.Back,
        "LIVE // CLASSIC GRID",
        theme.Accent,
        tier
    )

    local tally = makePart(
        "ClassicBroadcastTally",
        Vector3.new(8.4, 0.32, 0.72),
        frame * CFrame.new(0, height * 0.64 - 2.8, -1.20),
        theme.Secondary,
        Enum.Material.Neon,
        tier.Name == "Low" and 0.58 or 0.26,
        false
    )
    tally.CastShadow = false

    if tier.Name == "High" then
        for side = -1, 1, 2 do
            makePart(
                side < 0 and "ClassicBroadcastAntennaL" or "ClassicBroadcastAntennaR",
                Vector3.new(0.34, 7.5, 0.34),
                frame * CFrame.new(side * 8.2, height + 4.3, 0),
                theme.Accent,
                Enum.Material.Neon,
                0.30,
                false
            )
        end
    end
end

local function addTowerServiceLandmark(base, theme, tier)
    local hx = base.Size.X * 0.5
    local frame = localFrame(base, hx + 13, 0, 0, 90)
    local shaftHeight = tier.Name == "Low" and 18 or 25

    local shaft = makePart(
        "TowerServiceShaft",
        Vector3.new(7.5, shaftHeight, 7.5),
        frame * CFrame.new(0, shaftHeight * 0.5 + 0.8, 0),
        theme.Structure:Lerp(VisualTheme.World.Deep, 0.30),
        Enum.Material.Metal,
        tier.Name == "Low" and 0.15 or 0.05,
        tier.Name == "High"
    )

    for side = -1, 1, 2 do
        makePart(
            side < 0 and "TowerServiceRailL" or "TowerServiceRailR",
            Vector3.new(0.34, shaftHeight * 0.82, 7.9),
            shaft.CFrame * CFrame.new(side * 2.8, 0, 0),
            side < 0 and theme.Accent or theme.Secondary,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.62 or 0.34,
            false
        )
    end

    local car = makePart(
        "TowerServiceCar",
        Vector3.new(6.2, 4.2, 6.2),
        frame * CFrame.new(0, shaftHeight * 0.45, 0),
        theme.Detail,
        Enum.Material.DiamondPlate,
        0.08,
        tier.Name == "High"
    )
    makeSurfaceLabel(
        car,
        Enum.NormalId.Front,
        "MAINT // LIFT A",
        theme.Secondary,
        tier
    )

    if tier.Name ~= "Low" then
        makePart(
            "TowerServiceCrown",
            Vector3.new(12, 1.0, 2.2),
            frame * CFrame.new(0, shaftHeight + 1.2, 0),
            theme.Accent,
            Enum.Material.Neon,
            0.38,
            false
        )
    end
end

local function addCrossroadsTransitLandmark(base, theme, tier)
    local hz = base.Size.Z * 0.5
    local frame = localFrame(base, 0, 0, hz + 14, 180)
    local width = tier.Name == "Low" and 20 or 27
    local height = tier.Name == "Low" and 8 or 11

    for side = -1, 1, 2 do
        makePart(
            side < 0 and "CrossroadsTransitPylonL" or "CrossroadsTransitPylonR",
            Vector3.new(2.0, height, 3.0),
            frame * CFrame.new(side * width * 0.5, height * 0.5 + 0.7, 0),
            theme.Structure,
            Enum.Material.Metal,
            0.05,
            tier.Name == "High"
        )
    end

    makePart(
        "CrossroadsTransitBeam",
        Vector3.new(width + 2, 1.25, 3.0),
        frame * CFrame.new(0, height + 0.25, 0),
        theme.Detail,
        Enum.Material.DiamondPlate,
        0.08,
        tier.Name == "High"
    )

    local sign = makePart(
        "CrossroadsTransitSign",
        Vector3.new(16, 3.8, 0.55),
        frame * CFrame.new(0, height - 2.0, -1.75),
        VisualTheme.World.Deep,
        Enum.Material.Metal,
        0.02,
        false
    )
    makeSurfaceLabel(
        sign,
        Enum.NormalId.Back,
        "TRANSIT // SECTOR 04",
        theme.Accent,
        tier
    )

    local signalColors = {theme.Accent, theme.Secondary, theme.Detail}
    for i = 1, (tier.Name == "Low" and 2 or 3) do
        makePart(
            "CrossroadsTransitSignal" .. i,
            Vector3.new(2.8, 0.28, 0.62),
            frame * CFrame.new(-5.0 + (i - 1) * 5.0, height - 4.3, -1.80),
            signalColors[i],
            Enum.Material.Neon,
            tier.Name == "Low" and 0.55 or 0.24,
            false
        )
    end
end

local function addOrbitalReactorLandmark(base, theme, tier)
    local hx = base.Size.X * 0.5
    local frame = localFrame(base, -hx - 14, 0, 0, -90)
    local coreSize = tier.Name == "Low" and 5.5 or 7.5

    local core = makePart(
        "OrbitalReactorCore",
        Vector3.new(coreSize, coreSize, coreSize),
        frame * CFrame.new(0, 8.8, 0),
        theme.Accent,
        Enum.Material.Neon,
        tier.Name == "Low" and 0.42 or 0.20,
        false
    )
    core.Shape = Enum.PartType.Ball

    local hub = makePart(
        "OrbitalReactorHub",
        Vector3.new(3.2, 16, 3.2),
        frame * CFrame.new(0, 8.4, 0),
        theme.Structure,
        Enum.Material.Metal,
        tier.Name == "Low" and 0.18 or 0.08,
        tier.Name == "High"
    )

    local armCount = tier.Name == "Low" and 4 or 6
    for i = 1, armCount do
        local angle = ((i - 1) / armCount) * math.pi * 2
        makePart(
            "OrbitalReactorArm" .. i,
            Vector3.new(8.5, 0.50, 0.66),
            frame
                * CFrame.new(0, 8.8, 0)
                * CFrame.Angles(0, 0, angle)
                * CFrame.new(4.2, 0, 0),
            i % 2 == 0 and theme.Secondary or theme.Detail,
            Enum.Material.Metal,
            tier.Name == "Low" and 0.34 or 0.14,
            tier.Name == "High"
        )
    end

    local panel = makePart(
        "OrbitalReactorPanel",
        Vector3.new(9.0, 3.3, 0.50),
        frame * CFrame.new(0, 2.8, -2.2),
        VisualTheme.World.Deep,
        Enum.Material.Metal,
        0.02,
        false
    )
    makeSurfaceLabel(
        panel,
        Enum.NormalId.Front,
        "ORBITAL // REACTOR ONLINE",
        theme.Secondary,
        tier
    )
    hub.CastShadow = tier.Name == "High"
end

local function addAsymmetricServiceCluster(base, theme, tier, variant)
    if tier.Name == "Low" then
        return
    end

    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5

    if variant == "Towers" then
        local frame = localFrame(base, -hx - 12, 0, hz * 0.24, 0)
        local mast = makePart(
            "TowerMaintenanceCraneMast",
            Vector3.new(2.0, 17, 2.0),
            frame * CFrame.new(0, 9.2, 0),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.24),
            Enum.Material.Metal,
            0.06,
            tier.Name == "High"
        )
        makePart(
            "TowerMaintenanceCraneArm",
            Vector3.new(13, 0.90, 1.20),
            mast.CFrame * CFrame.new(4.8, 7.1, 0),
            theme.Detail,
            Enum.Material.DiamondPlate,
            0.08,
            tier.Name == "High"
        )
        makePart(
            "TowerMaintenanceCraneCable",
            Vector3.new(0.20, 7.0, 0.20),
            mast.CFrame * CFrame.new(10.2, 3.4, 0),
            theme.Accent,
            Enum.Material.Neon,
            0.44,
            false
        )
        makePart(
            "TowerMaintenanceCounterweight",
            Vector3.new(4.0, 2.4, 2.4),
            mast.CFrame * CFrame.new(-3.4, 6.5, 0),
            theme.Structure,
            Enum.Material.Metal,
            0.08,
            tier.Name == "High"
        )
    elseif variant == "Crossroads" then
        local frame = localFrame(base, hx + 3.0, 0, -hz * 0.34, 90)
        local amber = Color3.fromRGB(255, 165, 72)
        for i = 1, 3 do
            makePart(
                "CrossroadsClosedLaneBarrier" .. i,
                Vector3.new(5.2, 0.42, 0.62),
                frame
                    * CFrame.new(0, 1.0 + i * 0.58, (i - 2) * 1.35)
                    * CFrame.Angles(0, 0, math.rad(i % 2 == 0 and 7 or -7)),
                i == 2 and theme.Secondary or amber,
                Enum.Material.Neon,
                0.28,
                false
            )
        end
        local sign = makePart(
            "CrossroadsClosedLaneSign",
            Vector3.new(7.0, 3.2, 0.55),
            frame * CFrame.new(0, 4.5, 0),
            VisualTheme.World.Deep,
            Enum.Material.Metal,
            0.02,
            false
        )
        makeSurfaceLabel(
            sign,
            Enum.NormalId.Front,
            "LANE C // CLOSED",
            amber,
            tier
        )
    elseif variant == "Orbital" then
        local frame = localFrame(base, hx * 0.58, 0, -hz - 10, 0)
        local arm = makePart(
            "OrbitalDockingArm",
            Vector3.new(13.5, 1.1, 2.3),
            frame * CFrame.new(0, 8.8, -3.8),
            theme.Structure,
            Enum.Material.Metal,
            0.08,
            tier.Name == "High"
        )
        makePart(
            "OrbitalDockingArmGlow",
            Vector3.new(9.8, 0.24, 2.45),
            arm.CFrame * CFrame.new(0, 0.68, 0),
            theme.Secondary,
            Enum.Material.Neon,
            0.34,
            false
        )
        local pod = makePart(
            "OrbitalDockingPod",
            Vector3.new(5.0, 5.0, 5.0),
            frame * CFrame.new(0, 8.8, -11.0),
            theme.Detail,
            Enum.Material.SmoothPlastic,
            0.08,
            tier.Name == "High"
        )
        pod.Shape = Enum.PartType.Ball
        makePart(
            "OrbitalDockingNeck",
            Vector3.new(2.0, 2.0, 7.2),
            frame * CFrame.new(0, 8.8, -7.3),
            theme.Structure,
            Enum.Material.Metal,
            0.10,
            tier.Name == "High"
        )
    else
        local frame = localFrame(base, -hx - 10, 0, hz * 0.30, 90)
        local booth = makePart(
            "ClassicOpsBooth",
            Vector3.new(8.0, 5.2, 5.0),
            frame * CFrame.new(0, 3.5, 0),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.30),
            Enum.Material.Metal,
            0.05,
            tier.Name == "High"
        )
        local window = makePart(
            "ClassicOpsWindow",
            Vector3.new(5.8, 2.2, 0.30),
            booth.CFrame * CFrame.new(0, 0.4, -2.55),
            theme.Accent,
            Enum.Material.Neon,
            0.42,
            false
        )
        makeSurfaceLabel(
            window,
            Enum.NormalId.Back,
            "CAM 02 // OPS",
            theme.Secondary,
            tier
        )
        makePart(
            "ClassicOpsAntenna",
            Vector3.new(0.32, 6.2, 0.32),
            booth.CFrame * CFrame.new(2.8, 5.0, 0),
            theme.Secondary,
            Enum.Material.Neon,
            0.38,
            false
        )
    end
end

local function addMacroSilhouette(base, theme, tier, variant)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5

    if variant == "Classic" then
        local frame = localFrame(base, 0, 0, -hz - 27, 0)
        local height = tier.Name == "Low" and 20 or (tier.Name == "Medium" and 27 or 34)

        for side = -1, 1, 2 do
            local mast = makePart(
                side < 0 and "ClassicMegaMastL" or "ClassicMegaMastR",
                Vector3.new(2.8, height, 3.4),
                frame * CFrame.new(side * 12.5, height * 0.5 + 0.8, 0),
                theme.Structure:Lerp(VisualTheme.World.Deep, 0.28),
                Enum.Material.Metal,
                tier.Name == "Low" and 0.14 or 0.04,
                tier.Name == "High"
            )
            makePart(
                side < 0 and "ClassicMegaMastGlowL" or "ClassicMegaMastGlowR",
                Vector3.new(0.30, height * 0.68, 3.55),
                mast.CFrame,
                side < 0 and theme.Accent or theme.Secondary,
                Enum.Material.Neon,
                tier.Name == "Low" and 0.64 or 0.34,
                false
            )
        end

        makePart(
            "ClassicMegaCrown",
            Vector3.new(29, 1.6, 3.4),
            frame * CFrame.new(0, height + 0.45, 0),
            theme.Detail,
            Enum.Material.DiamondPlate,
            0.08,
            tier.Name == "High"
        )

        local screen = makePart(
            "ClassicMegaScreen",
            Vector3.new(18, 5.8, 0.62),
            frame * CFrame.new(0, height - 5.4, -1.95),
            VisualTheme.World.Deep,
            Enum.Material.Metal,
            0.02,
            false
        )
        makeSurfaceLabel(
            screen,
            Enum.NormalId.Back,
            "CHAOS // LIVE",
            theme.Accent,
            tier
        )

        if tier.Name == "High" then
            makePart(
                "ClassicMegaAntenna",
                Vector3.new(0.42, 11, 0.42),
                frame * CFrame.new(0, height + 6.2, 0),
                theme.Secondary,
                Enum.Material.Neon,
                0.44,
                false
            )
        end
    elseif variant == "Towers" then
        local frame = localFrame(base, 0, 0, -hz - 29, 0)
        local height = tier.Name == "Low" and 30 or (tier.Name == "Medium" and 38 or 46)
        local spread = tier.Name == "Low" and 9.5 or 11.5

        for side = -1, 1, 2 do
            local shaft = makePart(
                side < 0 and "TowerMegaShaftL" or "TowerMegaShaftR",
                Vector3.new(4.2, height, 5.0),
                frame * CFrame.new(side * spread, height * 0.5 + 0.8, 0),
                theme.Structure:Lerp(VisualTheme.World.Deep, 0.32),
                Enum.Material.Metal,
                tier.Name == "Low" and 0.16 or 0.05,
                tier.Name == "High"
            )
            makePart(
                side < 0 and "TowerMegaRailL" or "TowerMegaRailR",
                Vector3.new(0.38, height * 0.78, 5.15),
                shaft.CFrame,
                side < 0 and theme.Accent or theme.Secondary,
                Enum.Material.Neon,
                tier.Name == "Low" and 0.66 or 0.38,
                false
            )
        end

        makePart(
            "TowerMegaGantry",
            Vector3.new(spread * 2 + 8, 2.0, 5.2),
            frame * CFrame.new(0, height + 0.25, 0),
            theme.Detail,
            Enum.Material.DiamondPlate,
            0.08,
            tier.Name == "High"
        )

        local lift = makePart(
            "TowerMegaLift",
            Vector3.new(10, 6.0, 4.6),
            frame * CFrame.new(0, height * 0.58, -0.3),
            theme.Detail:Lerp(VisualTheme.World.Deep, 0.12),
            Enum.Material.Metal,
            0.08,
            tier.Name == "High"
        )
        makeSurfaceLabel(
            lift,
            Enum.NormalId.Back,
            "VERTICAL // LIFT",
            theme.Secondary,
            tier
        )

        if tier.Name ~= "Low" then
            for side = -1, 1, 2 do
                makePart(
                    side < 0 and "TowerMegaCableL" or "TowerMegaCableR",
                    Vector3.new(0.18, height * 0.36, 0.18),
                    frame * CFrame.new(side * 3.7, height * 0.79, -0.4),
                    theme.Accent,
                    Enum.Material.Neon,
                    0.52,
                    false
                )
            end
        end
    elseif variant == "Crossroads" then
        local frame = localFrame(base, 0, 0, hz + 27, 180)
        local height = tier.Name == "Low" and 18 or (tier.Name == "Medium" and 25 or 31)
        local spread = tier.Name == "Low" and 12 or 15

        for side = -1, 1, 2 do
            makePart(
                side < 0 and "CrossroadsMegaPylonL" or "CrossroadsMegaPylonR",
                Vector3.new(3.0, height, 3.8),
                frame * CFrame.new(side * spread, height * 0.5 + 0.8, 0),
                theme.Structure:Lerp(VisualTheme.World.Deep, 0.22),
                Enum.Material.Metal,
                tier.Name == "Low" and 0.15 or 0.05,
                tier.Name == "High"
            )
        end

        makePart(
            "CrossroadsMegaHeader",
            Vector3.new(spread * 2 + 8, 1.6, 3.8),
            frame * CFrame.new(0, height + 0.25, 0),
            theme.Detail,
            Enum.Material.DiamondPlate,
            0.08,
            tier.Name == "High"
        )

        for direction = -1, 1, 2 do
            local arm = makePart(
                direction < 0 and "CrossroadsSkyDirectionL" or "CrossroadsSkyDirectionR",
                Vector3.new(tier.Name == "Low" and 13 or 18, 0.78, 1.6),
                frame
                    * CFrame.new(direction * 6.8, height - 4.5, -1.7)
                    * CFrame.Angles(0, 0, math.rad(direction * 14)),
                direction < 0 and theme.Accent or theme.Secondary,
                Enum.Material.Neon,
                tier.Name == "Low" and 0.58 or 0.30,
                false
            )

            if tier.Name == "High" then
                makeWedge(
                    direction < 0 and "CrossroadsSkyArrowL" or "CrossroadsSkyArrowR",
                    Vector3.new(4.8, 1.8, 1.7),
                    arm.CFrame
                        * CFrame.new(direction * ((arm.Size.X * 0.5) + 2.0), 0, 0)
                        * CFrame.Angles(0, direction < 0 and math.pi or 0, 0),
                    arm.Color,
                    Enum.Material.Neon,
                    0.22,
                    false
                )
            end
        end

        local sign = makePart(
            "CrossroadsMegaSign",
            Vector3.new(15.5, 4.4, 0.62),
            frame * CFrame.new(0, height - 9.2, -2.05),
            VisualTheme.World.Deep,
            Enum.Material.Metal,
            0.02,
            false
        )
        makeSurfaceLabel(
            sign,
            Enum.NormalId.Back,
            "JUNCTION // 04",
            theme.Accent,
            tier
        )
    elseif variant == "Orbital" then
        local radius = math.max(base.Size.X, base.Size.Z) * 0.74
        local segments = tier.Name == "Low" and 6 or (tier.Name == "Medium" and 9 or 12)
        local height = tier.Name == "Low" and 18 or (tier.Name == "Medium" and 24 or 28)

        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local x = math.cos(angle) * radius
            local z = math.sin(angle) * radius
            local segmentLength = (2 * math.pi * radius / segments) * 0.72
            local ringSegment = makePart(
                "OrbitalSkyRing" .. i,
                Vector3.new(segmentLength, tier.Name == "Low" and 0.8 or 1.15, 2.8),
                localFrame(
                    base,
                    x,
                    height + math.sin(angle * 2) * 2.2,
                    z,
                    -math.deg(tangent)
                ) * CFrame.Angles(math.rad(12), 0, 0),
                theme.Structure:Lerp(VisualTheme.World.Deep, 0.12),
                Enum.Material.Metal,
                tier.Name == "Low" and 0.22 or 0.08,
                tier.Name == "High"
            )

            if tier.Name ~= "Low" then
                makePart(
                    "OrbitalSkyRingGlow" .. i,
                    Vector3.new(segmentLength * 0.72, 0.22, 2.95),
                    ringSegment.CFrame * CFrame.new(0, 0.72, 0),
                    i % 3 == 0 and theme.Secondary or theme.Accent,
                    Enum.Material.Neon,
                    0.38,
                    false
                )
            end
        end

        local crown = makePart(
            "OrbitalSkyCrown",
            Vector3.new(7.0, 7.0, 7.0),
            localFrame(base, 0, height + 8.0, -radius * 0.92, 0),
            theme.Accent,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.58 or 0.36,
            false
        )
        crown.Shape = Enum.PartType.Ball
    end
end

local function buildClassic(base, theme, tier)
    addAsymmetricServiceCluster(base, theme, tier, "Classic")
    addMacroSilhouette(base, theme, tier, "Classic")

    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local positions = {
        {-hx - 8, -hz - 8, 45},
        {hx + 8, -hz - 8, -45},
        {-hx - 8, hz + 8, -45},
        {hx + 8, hz + 8, 45},
    }

    for i, item in ipairs(positions) do
        addPylon(base, i, item[1], item[2], 14 + (i % 2) * 2, theme, tier, item[3])
    end

    addClassicBroadcastLandmark(base, theme, tier)

    if tier.Name ~= "Low" then
        local fins = {
            {-hx - 10, 0, -18, 0},
            {hx + 10, 0, 18, 0},
            {-18, 0, hz + 10, 90},
            {18, 0, -hz - 10, 90},
        }
        for i, item in ipairs(fins) do
            makeWedge(
                "ClassicSkyFin" .. i,
                Vector3.new(1.0, 10 + (i % 2) * 3, 6.5),
                localFrame(base, item[1], 6.0, item[3], item[4]),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.48,
                false
            )
        end
    end
end

local function buildTowers(base, theme, tier)
    addAsymmetricServiceCluster(base, theme, tier, "Towers")
    addMacroSilhouette(base, theme, tier, "Towers")

    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local positions = {
        {-hx - 7, -hz - 7},
        {hx + 7, -hz - 7},
        {-hx - 7, hz + 7},
        {hx + 7, hz + 7},
    }

    for i, item in ipairs(positions) do
        local height = tier.Name == "Low" and 22 or 28
        local pylon = makePart(
            "TowerCrown" .. i,
            Vector3.new(4.2, height, 4.2),
            localFrame(base, item[1], height * 0.5 + 0.8, item[2], 45),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.28),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.16 or 0.05,
            tier.Name == "High"
        )

        makePart(
            "TowerCrownGlow" .. i,
            Vector3.new(0.44, height * 0.70, 4.34),
            pylon.CFrame,
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.58 or 0.26,
            false
        )

        if tier.Name ~= "Low" then
            makeWedge(
                "TowerCrownWing" .. i,
                Vector3.new(9.5, 0.7, 1.25),
                pylon.CFrame * CFrame.new(0, height * 0.5 - 2.2, 0),
                theme.Detail,
                Enum.Material.DiamondPlate,
                0.14,
                tier.Name == "High"
            )
        end
    end

    addTowerServiceLandmark(base, theme, tier)

    if tier.Name == "High" then
        for i = 1, 4 do
            local angle = math.rad(45 + (i - 1) * 90)
            local radius = math.min(hx, hz) * 0.48
            local posX = math.cos(angle) * radius
            local posZ = math.sin(angle) * radius
            makePart(
                "TowerSkyBrace" .. i,
                Vector3.new(15, 0.45, 0.65),
                localFrame(base, posX, 19.5, posZ, -math.deg(angle)),
                theme.Accent,
                Enum.Material.Neon,
                0.52,
                false
            )
        end
    end
end

local function addCrossroadGate(base, index, x, z, yaw, theme, tier)
    local width = tier.Name == "Low" and 12 or 16
    local height = tier.Name == "Low" and 8 or 11

    local gateFrame = localFrame(base, x, 0, z, yaw)
    local left = makePart(
        "CrossroadGateL" .. index,
        Vector3.new(1.8, height, 2.2),
        gateFrame * CFrame.new(-width * 0.5, height * 0.5 + 0.7, 0),
        theme.Structure,
        Enum.Material.Metal,
        0.06,
        tier.Name == "High"
    )
    local right = makePart(
        "CrossroadGateR" .. index,
        Vector3.new(1.8, height, 2.2),
        gateFrame * CFrame.new(width * 0.5, height * 0.5 + 0.7, 0),
        theme.Structure,
        Enum.Material.Metal,
        0.06,
        tier.Name == "High"
    )
    makePart(
        "CrossroadGateTop" .. index,
        Vector3.new(width + 1.8, 1.25, 2.2),
        gateFrame * CFrame.new(0, height + 0.25, 0),
        theme.Detail,
        Enum.Material.DiamondPlate,
        0.10,
        tier.Name == "High"
    )

    if tier.Name ~= "Low" then
        makePart(
            "CrossroadGateGlowL" .. index,
            Vector3.new(0.22, height * 0.72, 2.34),
            left.CFrame,
            index % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            0.30,
            false
        )
        makePart(
            "CrossroadGateGlowR" .. index,
            Vector3.new(0.22, height * 0.72, 2.34),
            right.CFrame,
            index % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            0.30,
            false
        )
    end
end

local function buildCrossroads(base, theme, tier)
    addAsymmetricServiceCluster(base, theme, tier, "Crossroads")
    addMacroSilhouette(base, theme, tier, "Crossroads")

    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5
    local corners = {
        {-hx - 7, -hz - 7, 45},
        {hx + 7, -hz - 7, -45},
        {-hx - 7, hz + 7, -45},
        {hx + 7, hz + 7, 45},
    }

    addCrossroadsTransitLandmark(base, theme, tier)

    for i, item in ipairs(corners) do
        local height = tier.Name == "Low" and 13 or 17
        local body = makePart(
            "CrossroadHeroMonolith" .. i,
            Vector3.new(5.2, height, 2.0),
            localFrame(base, item[1], height * 0.5 + 0.7, item[2], item[3]),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.18),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.16 or 0.05,
            tier.Name == "High"
        )

        makePart(
            "CrossroadHeroSignal" .. i,
            Vector3.new(4.0, height * 0.52, 0.26),
            body.CFrame * CFrame.new(0, 1.0, -1.02),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.58 or 0.28,
            false
        )

        if tier.Name == "High" then
            makeWedge(
                "CrossroadHeroBlade" .. i,
                Vector3.new(8.0, 0.5, 0.8),
                body.CFrame * CFrame.new(0, height * 0.5 - 1.1, 0),
                theme.Detail,
                Enum.Material.DiamondPlate,
                0.16,
                true
            )
        end
    end
end

local function buildOrbital(base, theme, tier)
    addAsymmetricServiceCluster(base, theme, tier, "Orbital")
    addMacroSilhouette(base, theme, tier, "Orbital")
    addOrbitalReactorLandmark(base, theme, tier)

    local radius = math.min(base.Size.X, base.Size.Z) * 0.56
    local segments = tier.Name == "Low" and 6 or (tier.Name == "Medium" and 10 or 14)

    for i = 1, segments do
        local angle = ((i - 1) / segments) * math.pi * 2
        local tangent = angle + math.pi * 0.5
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius

        local arc = makePart(
            "OrbitalHeroArc" .. i,
            Vector3.new(radius * 0.34, 1.15, 2.2),
            localFrame(base, x, 7.5 + ((i % 2) * 1.6), z, -math.deg(tangent)),
            theme.Structure,
            Enum.Material.Metal,
            tier.Name == "Low" and 0.20 or 0.07,
            tier.Name == "High"
        )

        if tier.Name ~= "Low" then
            makePart(
                "OrbitalHeroGlow" .. i,
                Vector3.new(radius * 0.26, 0.22, 2.32),
                arc.CFrame * CFrame.new(0, 0.72, 0),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.24,
                false
            )
        end
    end

    local mastCount = tier.Name == "Low" and 4 or 8
    for i = 1, mastCount do
        local angle = ((i - 1) / mastCount) * math.pi * 2
        local mastRadius = radius + 2.5
        local x = math.cos(angle) * mastRadius
        local z = math.sin(angle) * mastRadius
        makePart(
            "OrbitalMast" .. i,
            Vector3.new(1.15, 12, 1.15),
            localFrame(base, x, 6.6, z, 0),
            theme.Detail,
            Enum.Material.Metal,
            0.16,
            tier.Name == "High"
        )
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
