local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:FindFirstChild("Shared")
local visualThemeModule = shared and shared:FindFirstChild("VisualTheme")
local VisualTheme = if visualThemeModule
    then require(visualThemeModule)
    else require("../shared/VisualTheme")

local MapBuilder = {}

function MapBuilder.humanoidFromHit(hit)
    local current = hit
    while current and current ~= workspace do
        if current:IsA("Model") then
            local humanoid = current:FindFirstChildOfClass("Humanoid")
            if humanoid then
                return humanoid
            end
        end
        current = current.Parent
    end

    return nil
end

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end


local function decorPart(parent, name, size, position, color, material)
    local p = part(parent, name, size, position, color, material)
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    return p
end

local function addArenaFoundation(decor, config, variant, theme)
    local baseSize = variant.BaseSize
    local center = config.ArenaCenter

    local undercarriage = decorPart(
        decor,
        "ArenaUndercarriage",
        Vector3.new(math.max(8, baseSize.X - 5), 2.4, math.max(8, baseSize.Z - 5)),
        center + Vector3.new(0, -2.1, 0),
        theme.Structure,
        VisualTheme.Materials.Structure
    )
    undercarriage.Transparency = 0.04

    local deckInset = decorPart(
        decor,
        "ArenaDeckInset",
        Vector3.new(math.max(8, baseSize.X - 7), 0.14, math.max(8, baseSize.Z - 7)),
        center + Vector3.new(0, 1.08, 0),
        theme.Surface:Lerp(theme.Detail, 0.22),
        VisualTheme.Materials.Panel
    )
    deckInset.Transparency = 0.03

    local laneLengthX = math.max(18, baseSize.X - 18)
    local laneLengthZ = math.max(18, baseSize.Z - 18)
    local lanes = {
        {name = "DeckLineNorth", size = Vector3.new(laneLengthX, 0.08, 0.36), pos = Vector3.new(0, 1.17, -12), color = theme.Accent},
        {name = "DeckLineSouth", size = Vector3.new(laneLengthX, 0.08, 0.36), pos = Vector3.new(0, 1.17, 12), color = theme.Secondary},
        {name = "DeckLineWest", size = Vector3.new(0.36, 0.08, laneLengthZ), pos = Vector3.new(-12, 1.17, 0), color = theme.Secondary},
        {name = "DeckLineEast", size = Vector3.new(0.36, 0.08, laneLengthZ), pos = Vector3.new(12, 1.17, 0), color = theme.Accent},
    }

    for _, def in ipairs(lanes) do
        local line = decorPart(
            decor,
            def.name,
            def.size,
            center + def.pos,
            def.color,
            VisualTheme.Materials.Glow
        )
        line.Transparency = 0.30
    end

    local radiusX = (baseSize.X * 0.5) + 4.5
    local radiusZ = (baseSize.Z * 0.5) + 4.5
    local segmentCount = 16
    for i = 1, segmentCount do
        local angle = ((i - 1) / segmentCount) * math.pi * 2
        local x = math.cos(angle) * radiusX
        local z = math.sin(angle) * radiusZ
        local halo = decorPart(
            decor,
            "OuterHalo" .. i,
            Vector3.new(5.5, 0.18, 0.42),
            center + Vector3.new(x, -1.15, z),
            (i % 2 == 0) and theme.Accent or theme.Secondary,
            VisualTheme.Materials.Glow
        )
        halo.CFrame = CFrame.new(halo.Position) * CFrame.Angles(0, -angle, 0)
        halo.Transparency = 0.34
    end

    local frameOffsets = {
        Vector3.new(-baseSize.X * 0.32, 4.2, -baseSize.Z * 0.32),
        Vector3.new(baseSize.X * 0.32, 4.2, -baseSize.Z * 0.32),
        Vector3.new(-baseSize.X * 0.32, 4.2, baseSize.Z * 0.32),
        Vector3.new(baseSize.X * 0.32, 4.2, baseSize.Z * 0.32),
    }

    for i, offset in ipairs(frameOffsets) do
        local column = decorPart(
            decor,
            "FrameColumn" .. i,
            Vector3.new(1.4, 8.4, 1.4),
            center + offset,
            theme.Structure,
            VisualTheme.Materials.Structure
        )
        column.Transparency = 0.05

        local slit = decorPart(
            decor,
            "FrameColumnGlow" .. i,
            Vector3.new(0.42, 5.6, 1.48),
            column.Position,
            (i % 2 == 0) and theme.Secondary or theme.Accent,
            VisualTheme.Materials.Glow
        )
        slit.Transparency = 0.20
    end
end

local function addVariantIdentity(decor, config, variant, theme)
    local center = config.ArenaCenter
    local halfX = variant.BaseSize.X * 0.5
    local halfZ = variant.BaseSize.Z * 0.5

    if variant.Id == "Classic" then
        local markers = {
            Vector3.new(-halfX + 8, 6, 0),
            Vector3.new(halfX - 8, 6, 0),
            Vector3.new(0, 6, -halfZ + 8),
            Vector3.new(0, 6, halfZ - 8),
        }

        for i, offset in ipairs(markers) do
            local tower = decorPart(
                decor,
                "GridMarker" .. i,
                Vector3.new(2.2, 12, 2.2),
                center + offset,
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            tower.Transparency = 0.06

            local crown = decorPart(
                decor,
                "GridMarkerGlow" .. i,
                Vector3.new(3.8, 0.32, 3.8),
                tower.Position + Vector3.new(0, 6.1, 0),
                (i % 2 == 0) and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            crown.Transparency = 0.16
        end
    elseif variant.Id == "Towers" then
        local corners = {
            Vector3.new(-halfX + 7, 10, -halfZ + 7),
            Vector3.new(halfX - 7, 10, -halfZ + 7),
            Vector3.new(-halfX + 7, 10, halfZ - 7),
            Vector3.new(halfX - 7, 10, halfZ - 7),
        }

        for i, offset in ipairs(corners) do
            local mast = decorPart(
                decor,
                "TowerSpine" .. i,
                Vector3.new(2.6, 20, 2.6),
                center + offset,
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            mast.Transparency = 0.04

            for level = 1, 3 do
                local band = decorPart(
                    decor,
                    "TowerBand" .. i .. "_" .. level,
                    Vector3.new(4.4, 0.28, 4.4),
                    mast.Position + Vector3.new(0, -6 + (level * 4.5), 0),
                    level == 2 and theme.Secondary or theme.Accent,
                    VisualTheme.Materials.Glow
                )
                band.Transparency = 0.22
            end
        end
    elseif variant.Id == "Crossroads" then
        local gates = {
            {pos = Vector3.new(0, 6, -halfZ + 7), size = Vector3.new(18, 1.2, 1.4)},
            {pos = Vector3.new(0, 6, halfZ - 7), size = Vector3.new(18, 1.2, 1.4)},
            {pos = Vector3.new(-halfX + 7, 6, 0), size = Vector3.new(1.4, 1.2, 18)},
            {pos = Vector3.new(halfX - 7, 6, 0), size = Vector3.new(1.4, 1.2, 18)},
        }

        for i, def in ipairs(gates) do
            local rail = decorPart(
                decor,
                "CrossroadGate" .. i,
                def.size,
                center + def.pos,
                (i % 2 == 0) and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            rail.Transparency = 0.18

            local postSize = def.size.X > def.size.Z and Vector3.new(1.2, 10, 1.2) or Vector3.new(1.2, 10, 1.2)
            local lateral = def.size.X > def.size.Z and Vector3.new(8.5, -5, 0) or Vector3.new(0, -5, 8.5)
            for sign = -1, 1, 2 do
                local post = decorPart(
                    decor,
                    "CrossroadPost" .. i .. "_" .. tostring(sign),
                    postSize,
                    rail.Position + (lateral * sign),
                    theme.Structure,
                    VisualTheme.Materials.Structure
                )
                post.Transparency = 0.05
            end
        end
    elseif variant.Id == "Orbital" then
        local ringRadius = 27
        local segments = 12

        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local position = center + Vector3.new(
                math.cos(angle) * ringRadius,
                16 + math.sin(angle * 2) * 1.2,
                math.sin(angle) * ringRadius
            )

            local segment = decorPart(
                decor,
                "OrbitalCrown" .. i,
                Vector3.new(7.4, 0.42, 0.8),
                position,
                (i % 2 == 0) and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            segment.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, math.rad(4))
            segment.Transparency = 0.20
        end

        local core = decorPart(
            decor,
            "OrbitalCore",
            Vector3.new(5, 5, 5),
            center + Vector3.new(0, 13, 0),
            theme.Secondary,
            VisualTheme.Materials.Glow
        )
        core.Shape = Enum.PartType.Ball
        core.Transparency = 0.34

        local coreLight = Instance.new("PointLight")
        coreLight.Name = "OrbitalCoreLight"
        coreLight.Color = theme.Accent
        coreLight.Brightness = 1.1
        coreLight.Range = 24
        coreLight.Shadows = false
        coreLight.Parent = core
    end
end

local function addArenaHologram(decor, config, variant, theme)
    local sign = decorPart(
        decor,
        "ArenaIdentityHologram",
        Vector3.new(20, 6.4, 0.28),
        config.ArenaCenter + Vector3.new(0, 11, -(variant.BaseSize.Z * 0.5) - 5.5),
        theme.Surface,
        VisualTheme.Materials.Panel
    )
    sign.Transparency = 0.20

    local backGlow = decorPart(
        decor,
        "ArenaIdentityGlow",
        Vector3.new(21.2, 7.3, 0.10),
        sign.Position + Vector3.new(0, 0, 0.20),
        theme.Accent,
        VisualTheme.Materials.Glow
    )
    backGlow.Transparency = 0.68

    local gui = Instance.new("SurfaceGui")
    gui.Name = "ArenaIdentityGui"
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 42
    gui.LightInfluence = 0
    gui.AlwaysOnTop = false
    gui.Parent = sign

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -24, 0.52, 0)
    header.Position = UDim2.fromOffset(12, 6)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBlack
    header.Text = variant.Name
    header.TextColor3 = Color3.fromRGB(242, 247, 255)
    header.TextStrokeColor3 = theme.Accent
    header.TextStrokeTransparency = 0.56
    header.TextScaled = true
    header.Parent = gui

    local separator = Instance.new("Frame")
    separator.AnchorPoint = Vector2.new(0.5, 0)
    separator.Position = UDim2.fromScale(0.5, 0.55)
    separator.Size = UDim2.new(0.78, 0, 0, 3)
    separator.BackgroundColor3 = theme.Accent
    separator.BorderSizePixel = 0
    separator.Parent = gui

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, -32, 0.30, 0)
    hint.Position = UDim2.new(0, 16, 0.62, 0)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.GothamBold
    hint.Text = variant.StrategyHint or "ADAPT • MOVE • SURVIVE"
    hint.TextColor3 = theme.Detail:Lerp(Color3.new(1, 1, 1), 0.50)
    hint.TextScaled = true
    hint.TextWrapped = true
    hint.Parent = gui
end

local function addVariantFloorLanguage(decor, config, variant, theme)
    local center = config.ArenaCenter

    if variant.Id == "Classic" then
        for i = -2, 2 do
            if i ~= 0 then
                local xLine = decorPart(
                    decor,
                    "ClassicGridX" .. tostring(i),
                    Vector3.new(0.16, 0.06, variant.BaseSize.Z - 14),
                    center + Vector3.new(i * 16, 1.19, 0),
                    i % 2 == 0 and theme.Secondary or theme.Accent,
                    VisualTheme.Materials.Glow
                )
                xLine.Transparency = 0.54

                local zLine = decorPart(
                    decor,
                    "ClassicGridZ" .. tostring(i),
                    Vector3.new(variant.BaseSize.X - 14, 0.06, 0.16),
                    center + Vector3.new(0, 1.19, i * 16),
                    i % 2 == 0 and theme.Secondary or theme.Accent,
                    VisualTheme.Materials.Glow
                )
                zLine.Transparency = 0.54
            end
        end
    elseif variant.Id == "Towers" then
        local pads = {
            Vector3.new(-28, 1.20, -28),
            Vector3.new(28, 1.20, -28),
            Vector3.new(-28, 1.20, 28),
            Vector3.new(28, 1.20, 28),
        }
        for i, offset in ipairs(pads) do
            local plate = decorPart(
                decor,
                "TowerGroundPlate" .. i,
                Vector3.new(17, 0.08, 17),
                center + offset,
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            plate.Transparency = 0.72

            local core = decorPart(
                decor,
                "TowerGroundCore" .. i,
                Vector3.new(5.5, 0.10, 5.5),
                center + offset + Vector3.new(0, 0.03, 0),
                theme.Accent,
                VisualTheme.Materials.Glow
            )
            core.Transparency = 0.42
        end
    elseif variant.Id == "Crossroads" then
        local laneDefs = {
            {size = Vector3.new(13, 0.08, 56), offset = Vector3.new(0, 1.20, -25)},
            {size = Vector3.new(13, 0.08, 56), offset = Vector3.new(0, 1.20, 25)},
            {size = Vector3.new(56, 0.08, 13), offset = Vector3.new(-25, 1.20, 0)},
            {size = Vector3.new(56, 0.08, 13), offset = Vector3.new(25, 1.20, 0)},
        }
        for i, def in ipairs(laneDefs) do
            local lane = decorPart(
                decor,
                "CrossroadLaneFill" .. i,
                def.size,
                center + def.offset,
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            lane.Transparency = 0.84
        end

        local hub = decorPart(
            decor,
            "CrossroadHubMark",
            Vector3.new(22, 0.10, 22),
            center + Vector3.new(0, 1.22, 0),
            theme.Secondary,
            VisualTheme.Materials.Glow
        )
        hub.Transparency = 0.70
    elseif variant.Id == "Orbital" then
        for i = 0, 7 do
            local angle = math.rad(i * 45)
            local radius = 25
            local position = center + Vector3.new(
                math.cos(angle) * radius * 0.5,
                1.20,
                math.sin(angle) * radius * 0.5
            )
            local spoke = decorPart(
                decor,
                "OrbitalSpoke" .. tostring(i + 1),
                Vector3.new(radius, 0.07, 0.20),
                position,
                i % 2 == 0 and theme.Accent or theme.Secondary,
                VisualTheme.Materials.Glow
            )
            spoke.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, 0)
            spoke.Transparency = 0.52
        end

        local coreMark = decorPart(
            decor,
            "OrbitalCoreMark",
            Vector3.new(14, 0.10, 14),
            center + Vector3.new(0, 1.21, 0),
            theme.Accent,
            VisualTheme.Materials.Glow
        )
        coreMark.Shape = Enum.PartType.Cylinder
        coreMark.CFrame = CFrame.new(coreMark.Position) * CFrame.Angles(0, 0, math.rad(90))
        coreMark.Transparency = 0.58
    end
end

local function addPlatformFinish(decor, platform, index, theme)
    local topPanel = decorPart(
        decor,
        "PlatformPanel" .. index,
        Vector3.new(
            math.max(1, platform.Size.X - 0.8),
            0.10,
            math.max(1, platform.Size.Z - 0.8)
        ),
        platform.Position + Vector3.new(0, (platform.Size.Y * 0.5) + 0.055, 0),
        theme.Surface:Lerp(theme.Detail, 0.28),
        VisualTheme.Materials.Panel
    )
    topPanel.Transparency = 0.04

    local underFrame = decorPart(
        decor,
        "PlatformUnderFrame" .. index,
        Vector3.new(platform.Size.X + 0.5, 0.42, platform.Size.Z + 0.5),
        platform.Position - Vector3.new(0, (platform.Size.Y * 0.5) + 0.18, 0),
        theme.Structure,
        VisualTheme.Materials.Structure
    )
    underFrame.Transparency = 0.08

    local core = decorPart(
        decor,
        "PlatformCoreGlow" .. index,
        Vector3.new(
            math.max(0.8, platform.Size.X * 0.42),
            0.16,
            math.max(0.8, platform.Size.Z * 0.42)
        ),
        platform.Position - Vector3.new(0, (platform.Size.Y * 0.5) + 0.42, 0),
        (index % 2 == 0) and theme.Secondary or theme.Accent,
        VisualTheme.Materials.Glow
    )
    core.Transparency = 0.26
end

local function buildLobby(root, config)
    local lobby = Instance.new("Folder")
    lobby.Name = "Lobby"
    lobby.Parent = root

    local floor = part(
        lobby,
        "Floor",
        Vector3.new(74, 2, 74),
        config.LobbyCenter,
        VisualTheme.World.Surface,
        VisualTheme.Materials.Floor
    )

    local decor = Instance.new("Folder")
    decor.Name = "Decor"
    decor.Parent = lobby

    local floorInset = decorPart(
        decor,
        "LobbyFloorInset",
        Vector3.new(68, 0.12, 68),
        config.LobbyCenter + Vector3.new(0, 1.08, 0),
        VisualTheme.World.Deep,
        VisualTheme.Materials.Panel
    )
    floorInset.Transparency = 0.04

    local lobbyLanes = {
        {name = "LobbyLaneNorth", size = Vector3.new(2.4, 0.08, 23), offset = Vector3.new(0, 1.16, -24)},
        {name = "LobbyLaneSouth", size = Vector3.new(2.4, 0.08, 23), offset = Vector3.new(0, 1.16, 24)},
        {name = "LobbyLaneWest", size = Vector3.new(23, 0.08, 2.4), offset = Vector3.new(-24, 1.16, 0)},
        {name = "LobbyLaneEast", size = Vector3.new(23, 0.08, 2.4), offset = Vector3.new(24, 1.16, 0)},
    }

    for i, def in ipairs(lobbyLanes) do
        local lane = decorPart(
            decor,
            def.name,
            def.size,
            config.LobbyCenter + def.offset,
            (i % 2 == 0) and VisualTheme.Accents.Violet or VisualTheme.Accents.Cyan,
            VisualTheme.Materials.Glow
        )
        lane.Transparency = 0.38
    end

    local centerPlatform = part(
        decor,
        "CenterPlatform",
        Vector3.new(24, 1.2, 24),
        config.LobbyCenter + Vector3.new(0, 1.45, 0),
        VisualTheme.World.SurfaceRaised,
        VisualTheme.Materials.Structure
    )

    local centerGlow = part(
        decor,
        "CenterGlow",
        Vector3.new(20, 0.22, 20),
        config.LobbyCenter + Vector3.new(0, 2.08, 0),
        VisualTheme.Accents.Cyan,
        VisualTheme.Materials.Glow
    )
    centerGlow.CanCollide = false
    centerGlow.Transparency = 0.22

    local glowLight = Instance.new("PointLight")
    glowLight.Name = "LobbyGlow"
    glowLight.Color = centerGlow.Color
    glowLight.Brightness = 1.3
    glowLight.Range = 26
    glowLight.Shadows = false
    glowLight.Parent = centerGlow

    local cornerOffsets = {
        Vector3.new(-31, 5, -31),
        Vector3.new(31, 5, -31),
        Vector3.new(-31, 5, 31),
        Vector3.new(31, 5, 31),
    }

    for i, offset in ipairs(cornerOffsets) do
        local pylon = part(
            decor,
            "Pylon" .. i,
            Vector3.new(2.2, 10, 2.2),
            config.LobbyCenter + offset,
            VisualTheme.World.Metal,
            VisualTheme.Materials.Structure
        )

        local cap = part(
            decor,
            "PylonGlow" .. i,
            Vector3.new(2.8, 0.55, 2.8),
            pylon.Position + Vector3.new(0, 5.25, 0),
            VisualTheme.Accents.Violet,
            VisualTheme.Materials.Glow
        )
        cap.CanCollide = false

        local light = Instance.new("PointLight")
        light.Name = "LobbyPylonLight"
        light.Color = cap.Color
        light.Brightness = 0.8
        light.Range = 16
        light.Shadows = false
        light.Parent = cap
    end

    local arenaDirection = Vector3.new(0, 0, 1)
    local archCenter = config.LobbyCenter + arenaDirection * 27

    local leftColumn = part(
        decor,
        "ArenaGateLeft",
        Vector3.new(3, 13, 3),
        archCenter + Vector3.new(-10, 6.5, 0),
        VisualTheme.World.Metal,
        VisualTheme.Materials.Structure
    )

    local rightColumn = part(
        decor,
        "ArenaGateRight",
        Vector3.new(3, 13, 3),
        archCenter + Vector3.new(10, 6.5, 0),
        VisualTheme.World.Metal,
        VisualTheme.Materials.Structure
    )

    local archTop = part(
        decor,
        "ArenaGateTop",
        Vector3.new(23, 3, 3),
        archCenter + Vector3.new(0, 13, 0),
        VisualTheme.Accents.Violet,
        VisualTheme.Materials.Glow
    )

    local sign = part(
        decor,
        "ChaosSign",
        Vector3.new(18, 6, 0.5),
        config.LobbyCenter + Vector3.new(0, 10, -25),
        VisualTheme.World.Deep,
        VisualTheme.Materials.Structure
    )
    sign.CanCollide = false

    local surface = Instance.new("SurfaceGui")
    surface.Name = "TitleGui"
    surface.Face = Enum.NormalId.Front
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 45
    surface.AlwaysOnTop = false
    surface.Parent = sign

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromScale(1, 0.62)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.fromRGB(245, 248, 255)
    title.TextStrokeTransparency = 0.65
    title.TextScaled = true
    title.Text = "CHAOS SURVIVAL"
    title.Parent = surface

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromScale(0, 0.62)
    subtitle.Size = UDim2.fromScale(1, 0.30)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.TextColor3 = Color3.fromRGB(120, 195, 255)
    subtitle.TextScaled = true
    subtitle.Text = "VOTE • SURVIVE • REPEAT"
    subtitle.Parent = surface

    local frameOffsets = {
        Vector3.new(-34, 7, 0),
        Vector3.new(34, 7, 0),
        Vector3.new(0, 7, -34),
        Vector3.new(0, 7, 34),
    }

    for i, offset in ipairs(frameOffsets) do
        local spine = decorPart(
            decor,
            "LobbyFrameSpine" .. i,
            Vector3.new(1.6, 14, 1.6),
            config.LobbyCenter + offset,
            VisualTheme.World.Metal,
            VisualTheme.Materials.Structure
        )
        spine.Transparency = 0.03

        local band = decorPart(
            decor,
            "LobbyFrameBand" .. i,
            Vector3.new(3.6, 0.34, 3.6),
            spine.Position + Vector3.new(0, 5.3, 0),
            (i % 2 == 0) and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
            VisualTheme.Materials.Glow
        )
        band.Transparency = 0.20
    end

    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(8, 1, 8)
    lobbySpawn.Position = config.LobbyCenter + Vector3.new(0, 2.8, 0)
    lobbySpawn.Anchored = true
    lobbySpawn.Neutral = true
    lobbySpawn.Transparency = 1
    lobbySpawn.CanCollide = false
    lobbySpawn.Parent = lobby

    floor:SetAttribute("VisualVersion", 2)
    centerPlatform:SetAttribute("SafeHub", true)
    leftColumn:SetAttribute("ArenaGate", true)
    rightColumn:SetAttribute("ArenaGate", true)
    archTop:SetAttribute("ArenaGate", true)
end

function MapBuilder.buildArena(config, variantId, arenaVariants)
    local root = workspace:FindFirstChild("GeneratedMap")
    if not root then
        root = Instance.new("Folder")
        root.Name = "GeneratedMap"
        root.Parent = workspace
    end

    local oldArena = root:FindFirstChild("Arena")
    if oldArena then
        oldArena:Destroy()
    end

    assert(arenaVariants, "arenaVariants is required")
    local variant = arenaVariants.get(variantId) or arenaVariants.get("Classic")
    local theme = VisualTheme.arena(variant.Id)
    local arena = Instance.new("Folder")
    arena.Name = "Arena"
    arena:SetAttribute("VariantId", variant.Id)
    arena:SetAttribute("VariantName", variant.Name)
    arena.Parent = root

    local base = part(
        arena,
        "Base",
        variant.BaseSize,
        config.ArenaCenter,
        theme.Surface,
        VisualTheme.Materials.Floor
    )
    base:SetAttribute("OriginalSizeX", base.Size.X)
    base:SetAttribute("OriginalSizeZ", base.Size.Z)

    local killPlane = part(
        arena,
        "KillPlane",
        Vector3.new(160, 2, 160),
        config.ArenaCenter + Vector3.new(0, -18, 0),
        Color3.fromRGB(255, 0, 0),
        Enum.Material.SmoothPlastic
    )
    killPlane.Transparency = 1
    killPlane.CanCollide = false
    killPlane.CanQuery = false
    killPlane.CanTouch = true

    killPlane.Touched:Connect(function(hit)
        local humanoid = MapBuilder.humanoidFromHit(hit)
        if humanoid and humanoid.Health > 0 then
            humanoid.Health = 0
        end
    end)

    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "Spawns"
    spawnFolder.Parent = arena

    for i, offset in ipairs(variant.SpawnOffsets) do
        local spawnPosition = config.ArenaCenter + offset
        local s = part(
            spawnFolder,
            "Spawn" .. i,
            Vector3.new(4.6, 0.7, 4.6),
            spawnPosition,
            theme.Detail:Lerp(Color3.new(1, 1, 1), 0.10),
            VisualTheme.Materials.Structure
        )
        s.Transparency = 0.08

        local glow = part(
            arena,
            "SpawnGlow" .. i,
            Vector3.new(5.2, 0.12, 5.2),
            spawnPosition + Vector3.new(0, -0.4, 0),
            (i % 2 == 0) and theme.Secondary or theme.Accent,
            VisualTheme.Materials.Glow
        )
        glow.CanCollide = false
        glow.CanTouch = false
        glow.CanQuery = false
        glow.CastShadow = false
        glow.Transparency = 0.16
    end

    local platforms = Instance.new("Folder")
    platforms.Name = "Platforms"
    platforms.Parent = arena

    local decor = Instance.new("Folder")
    decor.Name = "Decor"
    decor.Parent = arena

    addArenaFoundation(decor, config, variant, theme)
    addVariantIdentity(decor, config, variant, theme)
    addVariantFloorLanguage(decor, config, variant, theme)
    addArenaHologram(decor, config, variant, theme)

    local halfX = variant.BaseSize.X * 0.5
    local halfZ = variant.BaseSize.Z * 0.5
    local edgeThickness = 0.35
    local edgeHeight = 0.45

    local edgeColor = theme.Accent
    local north = decorPart(
        decor,
        "EdgeNorth",
        Vector3.new(variant.BaseSize.X, edgeHeight, edgeThickness),
        config.ArenaCenter + Vector3.new(0, 1.25, -halfZ + 0.4),
        edgeColor,
        Enum.Material.Neon
    )
    north.CanCollide = false

    local south = decorPart(
        decor,
        "EdgeSouth",
        Vector3.new(variant.BaseSize.X, edgeHeight, edgeThickness),
        config.ArenaCenter + Vector3.new(0, 1.25, halfZ - 0.4),
        edgeColor,
        Enum.Material.Neon
    )
    south.CanCollide = false

    local west = decorPart(
        decor,
        "EdgeWest",
        Vector3.new(edgeThickness, edgeHeight, variant.BaseSize.Z),
        config.ArenaCenter + Vector3.new(-halfX + 0.4, 1.25, 0),
        edgeColor,
        Enum.Material.Neon
    )
    west.CanCollide = false

    local east = decorPart(
        decor,
        "EdgeEast",
        Vector3.new(edgeThickness, edgeHeight, variant.BaseSize.Z),
        config.ArenaCenter + Vector3.new(halfX - 0.4, 1.25, 0),
        edgeColor,
        Enum.Material.Neon
    )
    east.CanCollide = false

    local beacon = decorPart(
        decor,
        "CenterBeacon",
        Vector3.new(1.4, 14, 1.4),
        config.ArenaCenter + Vector3.new(0, 7, 0),
        edgeColor,
        Enum.Material.Neon
    )
    beacon.CanCollide = false
    beacon.Transparency = 0.35

    local light = Instance.new("PointLight")
    light.Name = "ArenaGlow"
    light.Color = edgeColor
    light.Brightness = 1.2
    light.Range = 28
    light.Shadows = false
    light.Parent = beacon

    for i, definition in ipairs(variant.Platforms) do
        local platformPosition = config.ArenaCenter + definition.offset
        local platform = part(
            platforms,
            "Platform" .. i,
            definition.size,
            platformPosition,
            theme.Detail,
            VisualTheme.Materials.Structure
        )
        platform.Color = theme.Detail:Lerp(theme.Surface, 0.28)

        local trim = decorPart(
            decor,
            "PlatformGlow" .. i,
            Vector3.new(definition.size.X + 0.5, 0.18, definition.size.Z + 0.5),
            platformPosition - Vector3.new(0, (definition.size.Y * 0.5) + 0.13, 0),
            (i % 2 == 0) and theme.Secondary or theme.Accent,
            VisualTheme.Materials.Glow
        )
        trim.CanCollide = false
        trim.CanTouch = false
        trim.CanQuery = false
        trim.Transparency = 0.18
        addPlatformFinish(decor, platform, i, theme)
    end

    local beaconOffsets = {
        Vector3.new(-halfX + 3, 4.5, -halfZ + 3),
        Vector3.new(halfX - 3, 4.5, -halfZ + 3),
        Vector3.new(-halfX + 3, 4.5, halfZ - 3),
        Vector3.new(halfX - 3, 4.5, halfZ - 3),
    }

    for i, offset in ipairs(beaconOffsets) do
        local pillar = decorPart(
            decor,
            "EdgeBeacon" .. i,
            Vector3.new(0.8, 7, 0.8),
            config.ArenaCenter + offset,
            theme.Structure:Lerp(Color3.new(1, 1, 1), 0.08),
            VisualTheme.Materials.Structure
        )
        pillar.CanCollide = false

        local cap = decorPart(
            decor,
            "EdgeBeaconGlow" .. i,
            Vector3.new(1.35, 0.36, 1.35),
            pillar.Position + Vector3.new(0, 3.55, 0),
            (i % 2 == 0) and theme.Secondary or theme.Accent,
            VisualTheme.Materials.Glow
        )
        cap.Transparency = 0.10

        local capLight = Instance.new("PointLight")
        capLight.Name = "EdgeBeaconLight"
        capLight.Color = (i % 2 == 0) and theme.Secondary or theme.Accent
        capLight.Brightness = 0.55
        capLight.Range = 11
        capLight.Shadows = false
        capLight.Parent = cap
    end

    return arena
end

function MapBuilder.build(config, variantId, arenaVariants)
    local old = workspace:FindFirstChild("GeneratedMap")
    if old then
        old:Destroy()
    end

    local root = Instance.new("Folder")
    root.Name = "GeneratedMap"
    root.Parent = workspace

    buildLobby(root, config)
    MapBuilder.buildArena(config, variantId or "Classic", arenaVariants)

    return root
end

return MapBuilder
