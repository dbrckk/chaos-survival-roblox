local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:FindFirstChild("Shared")
local visualThemeModule = shared and shared:FindFirstChild("VisualTheme")
local VisualTheme = if visualThemeModule
    then require(visualThemeModule)
    else require("../shared/VisualTheme")
local arenaPresentationModule = shared and shared:FindFirstChild("ArenaPresentation")
local ArenaPresentation = if arenaPresentationModule
    then require(arenaPresentationModule)
    else require("../shared/ArenaPresentation")
-- Cloud engine specs can import new source modules before the published
-- place has received them; prefer sibling ModuleScript, otherwise source.
local helixModule = script and script.Parent:FindFirstChild("OrbitalHelix")
local OrbitalHelix = if helixModule
    then require(helixModule)
    else require("./OrbitalHelix")

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

-- Four authored 3D perimeter landmarks make an expanded arena read as a
-- destination rather than a bare enlarged slab. These are original
-- Roblox-native model assemblies (not externally licensed/imported meshes).
-- Keep every piece decorative so the danger floor, humanoid collision,
-- base-shrinking, AI navigation and platform jump tests stay authoritative.
-- Exactly four stations, no lights, loops, remote calls or live motion.
local function addPerimeterStations(decor, config, variant, theme)
    local halfX = variant.BaseSize.X * 0.5
    local halfZ = variant.BaseSize.Z * 0.5
    local anchors = {
        {name = "North", position = Vector3.new(0, 0, -halfZ + 17), yaw = 0},
        {name = "East", position = Vector3.new(halfX - 17, 0, 0), yaw = math.pi * 0.5},
        {name = "South", position = Vector3.new(0, 0, halfZ - 17), yaw = math.pi},
        {name = "West", position = Vector3.new(-halfX + 17, 0, 0), yaw = -math.pi * 0.5},
    }
    local baseTop = variant.BaseSize.Y * 0.5
    local accent = theme.Accent:Lerp(theme.Structure, 0.52)
    local secondary = theme.Secondary:Lerp(theme.Structure, 0.55)

    for index, anchor in ipairs(anchors) do
        local model = Instance.new("Model")
        model.Name = "PerimeterStation" .. anchor.name
        model:SetAttribute("ChaosPerimeterStation", true)
        model:SetAttribute("StationIndex", index)
        model.Parent = decor
        local origin = CFrame.new(
            config.ArenaCenter + anchor.position + Vector3.new(0, baseTop, 0)
        ) * CFrame.Angles(0, anchor.yaw, 0)

        local function piece(name, className, size, offset, material, color, opacity)
            local item = Instance.new(className or "Part")
            item.Name = name
            item.Size = size
            item.CFrame = origin * offset
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
            item.CastShadow = false
            item.Material = material
            item.Color = color
            item.Transparency = opacity or 0
            item.Parent = model
            return item
        end

        -- Recessed platform marker. The real floor underneath stays the
        -- sole walkable surface; the mark never catches feet or incoming
        -- projectiles and does not leave islands after Shrinking Arena.
        piece("InlaidStationBase", "Part", Vector3.new(12, 0.07, 11),
            CFrame.new(0, 0.035, 0), theme.PanelMaterial or Enum.Material.Metal,
            theme.Structure:Lerp(theme.Surface, 0.18), 0.14)
        for _, side in ipairs({-1, 1}) do
            piece(side < 0 and "LeftButtress" or "RightButtress",
                "Part", Vector3.new(1.5, 9, 2),
                CFrame.new(side * 5.3, 4.5, 0), Enum.Material.Metal,
                theme.Structure, 0.06)
            piece(side < 0 and "LeftAngledCap" or "RightAngledCap",
                "WedgePart", Vector3.new(2.9, 2.2, 2.4),
                CFrame.new(side * 5.0, 9.1, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, theme.Detail, 0.08)
            piece(side < 0 and "LeftLightNotch" or "RightLightNotch",
                "Part", Vector3.new(0.14, 1.8, 1.1),
                CFrame.new(side * 5.3, 5.0, -1.06), Enum.Material.Neon,
                side < 0 and accent or secondary, 0.38)
        end
        piece("CrossBrace", "Part", Vector3.new(9.1, 0.65, 1.25),
            CFrame.new(0, 9.0, -0.2), Enum.Material.Metal,
            theme.Structure:Lerp(theme.Detail, 0.22), 0.04)
        piece("CoreHousing", "Part", Vector3.new(3.2, 3.7, 2.8),
            CFrame.new(0, 4.9, 0.1), Enum.Material.Metal,
            theme.Detail:Lerp(theme.Structure, 0.35), 0.06)
        local core = piece("CoreLens", "Part", Vector3.new(2.7, 2.7, 2.7),
            CFrame.new(0, 5.1, -1.65), Enum.Material.Glass,
            accent:Lerp(secondary, 0.25), 0.33)
        core.Shape = Enum.PartType.Ball
        piece("WayfindingInset", "Part", Vector3.new(3.1, 0.16, 1.6),
            CFrame.new(0, 0.11, -4.25), Enum.Material.Neon,
            accent, 0.57)

        if variant.Id == "Towers" then
            -- Twin crane masts convey vertical scale without placing an
            -- overhead platform where an R15 could become trapped.
            piece("ServiceMast", "Part", Vector3.new(0.75, 6.8, 0.75),
                CFrame.new(0, 12.6, 0.3), Enum.Material.Metal,
                theme.Structure, 0.04)
            piece("SignalCrown", "WedgePart", Vector3.new(2.2, 1.4, 1.8),
                CFrame.new(0, 16.6, 0.3), Enum.Material.Metal,
                secondary, 0.10)
        elseif variant.Id == "Orbital" then
            -- Cylindrical receiver and two radial braces distinguish the
            -- reactor site from both tower cranes and grid substations.
            local dish = piece("ReceiverDish", "Part", Vector3.new(3.4, 0.65, 3.4),
                CFrame.new(0, 10.4, 0), Enum.Material.Metal,
                theme.Detail, 0.12)
            dish.Shape = Enum.PartType.Cylinder
            piece("ReceiverAntenna", "Part", Vector3.new(0.38, 3.4, 0.38),
                CFrame.new(0, 12.35, 0), Enum.Material.Metal,
                accent, 0.22)
        elseif variant.Id == "Crossroads" then
            piece("ExchangeBeam", "Part", Vector3.new(2.5, 0.75, 8.5),
                CFrame.new(0, 8.2, 0), Enum.Material.Metal,
                theme.Detail, 0.10)
            piece("SwitchyardMarker", "WedgePart", Vector3.new(1.5, 2, 2),
                CFrame.new(0, 10.0, 0), Enum.Material.Metal,
                secondary, 0.12)
        else
            piece("RelaySpire", "Part", Vector3.new(0.7, 4.4, 0.7),
                CFrame.new(0, 11.5, 0), Enum.Material.Metal,
                theme.Detail, 0.10)
            piece("RelayCrown", "WedgePart", Vector3.new(2.4, 1.6, 2),
                CFrame.new(0, 14.6, 0), Enum.Material.Metal,
                accent, 0.12)
        end
    end
end

-- The enlarged 150+ stud maps need a believable horizon, not just
-- extra empty floor. Four purpose-built exterior silhouettes provide depth
-- from the player's ground-height camera while remaining OUTSIDE the
-- hazard arena. These are original, lightweight Roblox-native 3D objects:
-- no remote models, texture IDs, scripts, draw loops, physics or lights.
-- Taller roofs remain outside every safe player/AI route and kill plane.
local function addDistantSkyline(decor, config, variant, theme)
    local halfX = variant.BaseSize.X * 0.5
    local halfZ = variant.BaseSize.Z * 0.5
    local directions = {
        {id = "North", x = -22, z = -halfZ - 23, yaw = 0},
        {id = "East", x = halfX + 23, z = -22, yaw = math.pi * 0.5},
        {id = "South", x = 22, z = halfZ + 23, yaw = math.pi},
        {id = "West", x = -halfX - 23, z = 22, yaw = -math.pi * 0.5},
    }
    local floorTop = variant.BaseSize.Y * 0.5
    for index, direction in ipairs(directions) do
        local model = Instance.new("Model")
        model.Name = "SkylineStructure" .. direction.id
        model:SetAttribute("ChaosDistantScenery", true)
        model.Parent = decor

        local height = (variant.Id == "Towers" and 25
            or (variant.Id == "Crossroads" and 20
                or (variant.Id == "Orbital" and 22 or 17)))
            + (index % 2) * 3
        local base = CFrame.new(
            config.ArenaCenter
                + Vector3.new(direction.x, floorTop, direction.z)
        ) * CFrame.Angles(0, direction.yaw, 0)
        local hullColor = theme.Structure:Lerp(theme.Surface, 0.14)
        local metalColor = theme.Detail:Lerp(theme.Structure, 0.65)
        local signalColor = theme.Secondary:Lerp(theme.Structure, 0.54)

        local function detail(name, kind, size, offset, material, color,
                transparency)
            local p = Instance.new(kind)
            p.Name = name
            p.Size = size
            p.CFrame = base * offset
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = material
            p.Color = color
            p.Transparency = transparency or 0
            p.Parent = model
            return p
        end

        -- Deep metal masses and recessed details are the main read, not
        -- fluorescent slabs. No visual object is a fake walkable platform.
        detail("Foundation", "Part", Vector3.new(14, 2.3, 10),
            CFrame.new(0, -1.1, 0), Enum.Material.Concrete,
            hullColor, 0.04)
        detail("StructuralCore", "Part", Vector3.new(8.5, height, 7.4),
            CFrame.new(0, height * 0.5, 0),
            Enum.Material.Metal, hullColor, 0.03)
        detail("TopCap", "WedgePart", Vector3.new(11.4, 3, 8.8),
            CFrame.new(0, height + 1.3, 0),
            Enum.Material.Metal, metalColor, 0.06)
        for side = -1, 1, 2 do
            detail(side < 0 and "OuterRibL" or "OuterRibR",
                "WedgePart", Vector3.new(2.2, 5.4, 8),
                CFrame.new(side * 4.6, 2.8, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, metalColor, 0.06)
            detail(side < 0 and "InsetL" or "InsetR",
                "Part", Vector3.new(0.24, height * 0.54, 0.85),
                CFrame.new(side * 4.30, height * 0.52, -3.6),
                Enum.Material.Metal, signalColor, 0.28)
        end

        if variant.Id == "Orbital" then
            local dish = detail("ReceiverHead", "Part",
                Vector3.new(5.5, 0.75, 5.5),
                CFrame.new(0, height + 3.4, 0),
                Enum.Material.Metal, metalColor, 0.06)
            dish.Shape = Enum.PartType.Cylinder
        elseif variant.Id == "Crossroads" then
            detail("ExchangeMast", "Part", Vector3.new(0.7, 5.5, 0.7),
                CFrame.new(0, height + 4.0, 0),
                Enum.Material.Metal, metalColor, 0.04)
            detail("CrossAntenna", "Part", Vector3.new(7.5, 0.4, 0.4),
                CFrame.new(0, height + 6.1, 0),
                Enum.Material.Metal, metalColor, 0.05)
        elseif variant.Id == "Towers" then
            detail("ServiceMast", "Part", Vector3.new(0.85, 7, 0.85),
                CFrame.new(0, height + 4.6, 0),
                Enum.Material.Metal, metalColor, 0.06)
        else
            detail("RelayAerial", "WedgePart", Vector3.new(3.4, 3.2, 2),
                CFrame.new(0, height + 3.2, 0),
                Enum.Material.Metal, metalColor, 0.06)
        end
    end

    -- Two additional depth layers behind each primary skyline silhouette.
    -- These structures are far beyond the playable floor and cannot be
    -- mistaken for traversable decks. No lights, particles, or updates.
    -- Dark layered silhouettes break up the boxy horizon in Android view.
    local farColor = theme.Structure:Lerp(Color3.fromRGB(11, 15, 24), 0.46)
    for index, direction in ipairs(directions) do
        local side = Vector3.new(math.cos(direction.yaw), 0,
            -math.sin(direction.yaw))
        local outward = Vector3.new(
            math.sin(direction.yaw), 0, -math.cos(direction.yaw)
        )
        for layer = 1, 2 do
            local model = Instance.new("Model")
            model.Name = "SkylineDepth" .. direction.id .. layer
            model:SetAttribute("ChaosDistantScenery", true)
            model.Parent = decor
            local height = (variant.Id == "Towers" and 31 or 22)
                + layer * 5 + ((index + layer) % 3) * 3
            local origin = config.ArenaCenter
                + Vector3.new(direction.x, variant.BaseSize.Y * 0.5,
                    direction.z)
                + outward * (16 + layer * 10)
                + side * (layer == 1 and -17 or 19)
            local body = Instance.new("WedgePart")
            body.Name = "DistantRoofMass"
            body.Size = Vector3.new(10 + layer * 3, height, 8)
            body.CFrame = CFrame.new(origin + Vector3.new(0, height * 0.5, 0))
                * CFrame.Angles(0, direction.yaw, 0)
            body.Material = Enum.Material.Metal
            body.Color = farColor
            body.Transparency = 0.14 + layer * 0.12
            body.Anchored = true
            body.CanCollide = false
            body.CanTouch = false
            body.CanQuery = false
            body.CastShadow = false
            body.Parent = model
            local spire = Instance.new("Part")
            spire.Name = "DistantAerial"
            spire.Size = Vector3.new(0.38, 4 + layer * 2, 0.38)
            spire.CFrame = CFrame.new(origin
                + Vector3.new(0, height + 2 + layer, 0))
            spire.Material = Enum.Material.Metal
            spire.Color = farColor
            spire.Transparency = 0.20 + layer * 0.10
            spire.Anchored = true
            spire.CanCollide = false
            spire.CanTouch = false
            spire.CanQuery = false
            spire.CastShadow = false
            spire.Parent = model
        end
    end
end

-- One large, scene-specific architectural silhouette per arena.
-- Deliberately positioned beyond the kill/physics floor, behind the playable
-- skyline. These are ORIGINAL runtime Roblox models and require no asset ID.
-- Their large-scale shapes are legible from a mobile third-person camera,
-- with dark industrial mass first and restrained colored accents second.
-- Never give the hero structure collision, touch, queries, shadows, lights,
-- animations, untrusted assets, or gameplay significance.
local function addArenaSignatureMegastructure(decor, config, variant, theme)
    local model = Instance.new("Model")
    model.Name = "ArenaSignatureMegastructure"
    model:SetAttribute("ChaosDistantScenery", true)
    model:SetAttribute("SignatureVariant", variant.Id)
    model.Parent = decor

    local origin = CFrame.new(
        config.ArenaCenter + Vector3.new(
            variant.BaseSize.X * 0.24,
            variant.BaseSize.Y * 0.5,
            -(variant.BaseSize.Z * 0.5 + 66)
        )
    )
    local hull = theme.Structure:Lerp(Color3.fromRGB(21, 28, 38), 0.37)
    local metal = theme.Detail:Lerp(theme.Structure, 0.55)
    local rim = theme.Accent:Lerp(theme.Structure, 0.68)
    local glint = theme.Secondary:Lerp(theme.Structure, 0.50)

    local function piece(name, kind, size, localFrame, material, color, transparency)
        local object = Instance.new(kind or "Part")
        object.Name = name
        object.Size = size
        object.CFrame = origin * localFrame
        object.Anchored = true
        object.CanCollide = false
        object.CanTouch = false
        object.CanQuery = false
        object.CastShadow = false
        object.Material = material or Enum.Material.Metal
        object.Color = color or hull
        object.Transparency = transparency or 0
        object.Parent = model
        return object
    end

    piece("Foundation", "Part", Vector3.new(35, 1.8, 18),
        CFrame.new(0, -0.9, 0), Enum.Material.Concrete, hull, 0.04)
    piece("InsetBase", "Part", Vector3.new(31, 0.25, 13),
        CFrame.new(0, 0.16, 0), Enum.Material.Metal, metal, 0.10)

    if variant.Id == "Orbital" then
        -- A vertical accelerator torus, instead of one more stack of
        -- rectangular decks. The segmented metal ring is a real 3D
        -- architectural silhouette, not a bright opaque VFX plane.
        local radius = 20
        local segments = 16
        local chord = 2 * radius * math.sin(math.pi / segments) + 0.10
        for index = 0, segments - 1 do
            local angle = index * math.pi * 2 / segments
            piece("ReactorArc" .. (index + 1), "Part",
                Vector3.new(chord, 1.35, 2.1),
                CFrame.new(radius * math.sin(angle),
                    29 + radius * math.cos(angle), 0)
                    * CFrame.Angles(0, 0, -angle),
                Enum.Material.Metal,
                index % 4 == 0 and rim or metal, 0.05)
        end
        for side = -1, 1, 2 do
            piece(side < 0 and "RingSupportLeft" or "RingSupportRight",
                "Part", Vector3.new(3.3, 24, 3.5),
                CFrame.new(side * 17, 12, 0), Enum.Material.Metal, hull)
            piece(side < 0 and "RingFootLeft" or "RingFootRight",
                "WedgePart", Vector3.new(7, 6, 8),
                CFrame.new(side * 17, 3, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, metal, 0.05)
        end
        local core = piece("SuspendedReactorCore", "Part",
            Vector3.new(10, 10, 10), CFrame.new(0, 29, 0),
            Enum.Material.Glass, glint, 0.32)
        core.Shape = Enum.PartType.Ball
        piece("CoreRetainer", "Part", Vector3.new(13, 1.4, 3),
            CFrame.new(0, 29, 0), Enum.Material.Metal, hull, 0.06)
    elseif variant.Id == "Towers" then
        -- A distant suspended service bridge with two asymmetrical
        -- elevator towers and cable trusses; no player can reach it.
        for side = -1, 1, 2 do
            piece(side < 0 and "LiftTowerWest" or "LiftTowerEast",
                "Part", Vector3.new(7, 41, 8),
                CFrame.new(side * 16, 20.5, 0),
                Enum.Material.Concrete, hull, 0.03)
            piece(side < 0 and "TowerCrownWest" or "TowerCrownEast",
                "WedgePart", Vector3.new(10, 6, 10),
                CFrame.new(side * 16, 44, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, metal)
            piece(side < 0 and "TowerInlayWest" or "TowerInlayEast",
                "Part", Vector3.new(0.22, 29, 1.0),
                CFrame.new(side * 16 + (side < 0 and 3.6 or -3.6),
                    21, -3.4), Enum.Material.Metal, rim, 0.21)
            piece(side < 0 and "TowerDiagonalWest" or "TowerDiagonalEast",
                "Part", Vector3.new(1.0, 32, 1.5),
                CFrame.new(side * 8, 27, 0)
                    * CFrame.Angles(0, 0, side * math.rad(27)),
                Enum.Material.Metal, metal)
        end
        piece("OverheadServiceBridge", "Part", Vector3.new(41, 2.4, 6.5),
            CFrame.new(0, 39, 0), Enum.Material.Metal, metal)
        piece("LowerTruss", "Part", Vector3.new(35, 0.8, 1.2),
            CFrame.new(0, 35.6, -3.2), Enum.Material.Metal, hull)
        piece("HangingSignal", "WedgePart", Vector3.new(4.8, 3, 2),
            CFrame.new(0, 33.7, -3), Enum.Material.Metal, glint, 0.18)
    elseif variant.Id == "Crossroads" then
        -- A double-decker freight-switching gantry with a sharply
        -- branched outline, distinct from tower cranes and reactor arcs.
        for side = -1, 1, 2 do
            piece(side < 0 and "ExchangeLegWest" or "ExchangeLegEast",
                "Part", Vector3.new(5.2, 34, 6),
                CFrame.new(side * 16, 17, 0),
                Enum.Material.Concrete, hull)
            piece(side < 0 and "CantileverWest" or "CantileverEast",
                "WedgePart", Vector3.new(11, 4, 7),
                CFrame.new(side * 18.3, 38, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, metal)
            piece(side < 0 and "SwitchBraceWest" or "SwitchBraceEast",
                "Part", Vector3.new(1.1, 22, 1.4),
                CFrame.new(side * 8, 25, -2)
                    * CFrame.Angles(0, 0, side * math.rad(32)),
                Enum.Material.Metal, metal)
        end
        piece("LowerExchange", "Part", Vector3.new(42, 2, 6),
            CFrame.new(0, 29, 0), Enum.Material.Metal, metal)
        piece("UpperExchange", "Part", Vector3.new(48, 1.3, 5.4),
            CFrame.new(0, 36.5, 0), Enum.Material.Metal, hull)
        piece("Switchboard", "Part", Vector3.new(7.5, 4.4, 0.55),
            CFrame.new(0, 33, -3.2), Enum.Material.Metal, glint, 0.15)
        piece("SignalPylon", "Part", Vector3.new(1.4, 16, 1.5),
            CFrame.new(0, 45, 0), Enum.Material.Metal, hull)
        piece("SignalCrown", "WedgePart", Vector3.new(5.6, 3.4, 2.8),
            CFrame.new(0, 54, 0), Enum.Material.Metal, rim, 0.12)
    else
        -- Classic Grid: a long-range relay observatory and dish array.
        -- Cylindrical receivers/diagonal legs interrupt the default
        -- box-on-box profile while staying fully static.
        for side = -1, 1, 2 do
            piece(side < 0 and "RelayButtressWest" or "RelayButtressEast",
                "Part", Vector3.new(3.5, 33, 4.5),
                CFrame.new(side * 11.8, 16.5, 0),
                Enum.Material.Concrete, hull)
            piece(side < 0 and "RelaySparWest" or "RelaySparEast",
                "Part", Vector3.new(1.1, 31, 1.4),
                CFrame.new(side * 7.5, 24, -0.8)
                    * CFrame.Angles(0, 0, side * math.rad(21)),
                Enum.Material.Metal, metal)
            local receiver = piece(
                side < 0 and "ReceiverDishWest" or "ReceiverDishEast",
                "Part", Vector3.new(0.8, 10.5, 10.5),
                CFrame.new(side * 13, 44 + side * 3, 0)
                    * CFrame.Angles(0, math.pi * 0.5, 0),
                Enum.Material.Metal, metal, 0.10)
            receiver.Shape = Enum.PartType.Cylinder
            piece(side < 0 and "ReceiverHubWest" or "ReceiverHubEast",
                "Part", Vector3.new(2.1, 2.1, 2.1),
                CFrame.new(side * 13, 44 + side * 3, -0.8),
                Enum.Material.Metal, rim)
        end
        piece("PrimaryRelayMast", "Part", Vector3.new(3, 55, 3),
            CFrame.new(0, 27.5, 0), Enum.Material.Metal, hull)
        piece("RelayHead", "WedgePart", Vector3.new(7, 4.7, 4.2),
            CFrame.new(0, 58, 0), Enum.Material.Metal, metal)
        piece("DishBridge", "Part", Vector3.new(30, 1.2, 2),
            CFrame.new(0, 37, 0), Enum.Material.Metal, hull)
        piece("ServicePanel", "Part", Vector3.new(5, 3.2, 0.55),
            CFrame.new(0, 35, -2.25), Enum.Material.Metal, glint, 0.17)
    end
end

-- Four original sculpted exterior corner ridges close the empty diagonal
-- horizon. They sit beyond both axes of the arena floor, so no collision,
-- hazards, NPC navigation or playable jumps depend on their presence.
-- Twelve anchored wedge shapes per map; no runtime updates or textures.
local function addExteriorCornerRidges(decor, config, variant, theme)
    local x = variant.BaseSize.X * 0.5 + 28
    local z = variant.BaseSize.Z * 0.5 + 28
    local stone = theme.Structure:Lerp(Color3.fromRGB(25, 31, 39), 0.45)
    local metal = theme.Detail:Lerp(stone, 0.72)
    for _, corner in ipairs({
        {id = "NW", sx = -1, sz = -1},
        {id = "NE", sx = 1, sz = -1},
        {id = "SW", sx = -1, sz = 1},
        {id = "SE", sx = 1, sz = 1},
    }) do
        local model = Instance.new("Model")
        model.Name = "ExteriorRidge" .. corner.id
        model:SetAttribute("ChaosDistantScenery", true)
        model.Parent = decor
        local center = config.ArenaCenter + Vector3.new(
            corner.sx * x, variant.BaseSize.Y * 0.5,
            corner.sz * z
        )
        local yaw = math.atan2(corner.sx, corner.sz)
        for index = 1, 3 do
            local height = 9 + ((index * 7 + corner.sx * 3
                + corner.sz * 5 + 20) % 11)
            local ridge = Instance.new("WedgePart")
            ridge.Name = "Ridge" .. index
            ridge.Size = Vector3.new(11 + index * 3, height,
                13 + index * 2)
            ridge.CFrame = CFrame.new(center + Vector3.new(
                (index - 2) * corner.sx * 8, height * 0.5 - 1.5,
                (index - 2) * corner.sz * 6
            )) * CFrame.Angles(0, yaw + (index - 2) * 0.32, 0)
            ridge.Anchored = true
            ridge.CanCollide = false
            ridge.CanTouch = false
            ridge.CanQuery = false
            ridge.CastShadow = false
            ridge.Material = index == 2 and Enum.Material.Concrete
                or Enum.Material.Metal
            ridge.Color = index == 2 and stone or metal
            ridge.Transparency = 0.07 + index * 0.04
            ridge.Parent = model
        end
    end
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
        theme.PanelMaterial or VisualTheme.Materials.Panel
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
        -- These 130+ stud navigation seams should not bloom brighter
        -- than actual hazard telegraphs on short Android sightlines.
        line.Transparency = 0.58
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

local function addVariantLandmarks(decor, config, variant, theme)
    local center = config.ArenaCenter
    local halfX = variant.BaseSize.X * 0.5
    local halfZ = variant.BaseSize.Z * 0.5

    if variant.Id == "Classic" then
        local defs = {
            {offset = Vector3.new(-halfX - 5, 8, -18), size = Vector3.new(1.8, 16, 5.5)},
            {offset = Vector3.new(halfX + 5, 8, 18), size = Vector3.new(1.8, 16, 5.5)},
            {offset = Vector3.new(-18, 8, halfZ + 5), size = Vector3.new(5.5, 16, 1.8)},
            {offset = Vector3.new(18, 8, -halfZ - 5), size = Vector3.new(5.5, 16, 1.8)},
        }
        for i, def in ipairs(defs) do
            local fin = decorPart(
                decor,
                "ClassicBroadcastFin" .. i,
                def.size,
                center + def.offset,
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            fin.Transparency = 0.05

            local stripSize = def.size.X < def.size.Z
                and Vector3.new(0.22, 10, def.size.Z + 0.08)
                or Vector3.new(def.size.X + 0.08, 10, 0.22)
            local strip = decorPart(
                decor,
                "ClassicBroadcastGlow" .. i,
                stripSize,
                fin.Position + Vector3.new(0, 0.5, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            strip.Transparency = 0.24
        end
    elseif variant.Id == "Towers" then
        local offsets = {
            Vector3.new(-halfX - 6, 12, -halfZ - 6),
            Vector3.new(halfX + 6, 12, -halfZ - 6),
            Vector3.new(-halfX - 6, 12, halfZ + 6),
            Vector3.new(halfX + 6, 12, halfZ + 6),
        }
        for i, offset in ipairs(offsets) do
            local machinery = decorPart(
                decor,
                "TowerMachinery" .. i,
                Vector3.new(5.2, 24, 5.2),
                center + offset,
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            machinery.Transparency = 0.04

            local cap = decorPart(
                decor,
                "TowerMachineryCap" .. i,
                Vector3.new(7.4, 1.0, 7.4),
                machinery.Position + Vector3.new(0, 12.4, 0),
                theme.Accent,
                VisualTheme.Materials.Glow
            )
            cap.Transparency = 0.18

            local antenna = decorPart(
                decor,
                "TowerAntenna" .. i,
                Vector3.new(0.55, 9, 0.55),
                machinery.Position + Vector3.new(0, 17.2, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            antenna.Transparency = 0.16
        end
    elseif variant.Id == "Crossroads" then
        local defs = {
            {offset = Vector3.new(0, 8, -halfZ - 4), size = Vector3.new(28, 2.0, 2.0)},
            {offset = Vector3.new(0, 8, halfZ + 4), size = Vector3.new(28, 2.0, 2.0)},
            {offset = Vector3.new(-halfX - 4, 8, 0), size = Vector3.new(2.0, 2.0, 28)},
            {offset = Vector3.new(halfX + 4, 8, 0), size = Vector3.new(2.0, 2.0, 28)},
        }
        for i, def in ipairs(defs) do
            local gantry = decorPart(
                decor,
                "CrossroadGantry" .. i,
                def.size,
                center + def.offset,
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            gantry.Transparency = 0.04

            local signal = decorPart(
                decor,
                "CrossroadSignal" .. i,
                def.size.X > def.size.Z and Vector3.new(18, 0.34, 2.12) or Vector3.new(2.12, 0.34, 18),
                gantry.Position,
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            signal.Transparency = 0.16
        end
    elseif variant.Id == "Orbital" then
        local radius = math.max(halfX, halfZ) + 7
        for i = 1, 8 do
            local angle = ((i - 1) / 8) * math.pi * 2
            local position = center + Vector3.new(
                math.cos(angle) * radius,
                9 + ((i % 2) * 3),
                math.sin(angle) * radius
            )

            local node = decorPart(
                decor,
                "OrbitalReactorNode" .. i,
                Vector3.new(4.4, 4.4, 4.4),
                position,
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            node.Shape = Enum.PartType.Ball
            node.Transparency = 0.20

            local strut = decorPart(
                decor,
                "OrbitalReactorStrut" .. i,
                Vector3.new(8.5, 0.55, 0.55),
                center + Vector3.new(
                    math.cos(angle) * (radius - 4.4),
                    7,
                    math.sin(angle) * (radius - 4.4)
                ),
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            strut.CFrame = CFrame.new(strut.Position) * CFrame.Angles(0, -angle, 0)
            strut.Transparency = 0.10
        end
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
    gui.Face = Enum.NormalId.Back
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 42
    gui.LightInfluence = 0
    gui.AlwaysOnTop = false
    gui.Parent = sign

    local header = Instance.new("TextLabel")
    header.Name = "ArenaIdentityTitle"
    header:SetAttribute("BaseText", variant.Name)
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
    separator.Name = "ArenaIdentitySeparator"
    separator.AnchorPoint = Vector2.new(0.5, 0)
    separator.Position = UDim2.fromScale(0.5, 0.55)
    separator.Size = UDim2.new(0.78, 0, 0, 3)
    separator.BackgroundColor3 = theme.Accent
    separator.BorderSizePixel = 0
    separator.Parent = gui

    local hint = Instance.new("TextLabel")
    hint.Name = "ArenaIdentityHint"
    hint:SetAttribute("BaseText", variant.StrategyHint or "ADAPT • MOVE • SURVIVE")
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

        -- Four restrained, flush floor chevrons guide new players toward
        -- the reachable tier-one terraces (jump from floor to their tops).
        -- They avoid orange/red hazard colors, cast no shadows and cannot
        -- obscure collision or intercept touch controls.
        local routeDirections = {
            Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
            Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        }
        for routeIndex, direction in ipairs(routeDirections) do
            -- Outside the raised tiers, adjacent to each cardinal entry
            -- spawn. The arrow points IN toward the first reachable deck;
            -- avoid marking low headroom directly below the transfers.
            local position = center + direction * 32
                + Vector3.new(0, 1.28, 0)
            local facing = CFrame.lookAt(position,
                position - direction, Vector3.yAxis)
            for side = -1, 1, 2 do
                local marker = decorPart(
                    decor,
                    "ClassicEntryChevron" .. routeIndex .. "_" .. tostring(side),
                    Vector3.new(0.15, 0.05, 1.35),
                    position,
                    routeIndex % 2 == 0 and theme.Secondary or theme.Accent,
                    VisualTheme.Materials.Glow
                )
                marker.CFrame = facing
                    * CFrame.new(side * 0.36, 0, 0)
                    * CFrame.Angles(0, math.rad(side * 36), 0)
                marker.Transparency = 0.47
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
                theme.Surface:Lerp(
                    i % 2 == 0 and theme.Secondary or theme.Accent, 0.24
                ),
                theme.PanelMaterial or Enum.Material.Metal
            )
            plate.Transparency = 0.34

            local core = decorPart(
                decor,
                "TowerGroundCore" .. i,
                Vector3.new(5.5, 0.10, 5.5),
                center + offset + Vector3.new(0, 0.03, 0),
                theme.Accent,
                VisualTheme.Materials.Glow
            )
            core.Transparency = 0.74
        end

        -- Eight small floor-inlaid chevrons at four genuine tower ascent
        -- approaches, not false arrows beneath elevated collision decks.
        -- Two restrained cyan wings per route are visible to first-time
        -- players arriving at the original corner and cardinal spawns.
        local approaches = {
            {-1, -1}, {1, -1}, {-1, 1}, {1, 1},
        }
        for index, signs in ipairs(approaches) do
            local x, z = signs[1], signs[2]
            local origin = center + Vector3.new(x * 10, 1.22, z * 23)
            local firstDeck = center + Vector3.new(x * 6, 1.22, z * 14)
            local facing = CFrame.lookAt(origin, firstDeck, Vector3.yAxis)
            for side = -1, 1, 2 do
                local arrow = decorPart(
                    decor,
                    "TowerAscentChevron" .. index .. "_" .. tostring(side),
                    Vector3.new(0.14, 0.055, 1.25),
                    origin,
                    index % 2 == 0 and theme.Accent or theme.Secondary,
                    VisualTheme.Materials.Glow
                )
                arrow.CFrame = facing
                    * CFrame.new(side * 0.37, 0, 0)
                    * CFrame.Angles(0, math.rad(side * 34), 0)
                arrow.Transparency = 0.47
            end
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
                theme.Surface:Lerp(theme.Detail, 0.36),
                theme.PanelMaterial or Enum.Material.Metal
            )
            lane.Transparency = 0.38
        end

        -- Flux Relay navigation is physically readable from the floor.
        -- Inlaid cyan chevrons teach the return-to-hub loop rather than
        -- forcing the player to decode a HUD paragraph during a disaster.
        for laneIndex = 1, 4 do
            local direction = laneIndex == 1 and Vector3.new(1, 0, 0)
                or (laneIndex == 2 and Vector3.new(0, 0, 1)
                    or (laneIndex == 3 and Vector3.new(-1, 0, 0)
                        or Vector3.new(0, 0, -1)))
            for stepIndex = 1, 3 do
                local distance = 23 + stepIndex * 3.15
                local position = center + direction * distance
                    + Vector3.new(0, 1.29, 0)
                local facing = CFrame.lookAt(position,
                    center + Vector3.new(0, 1.29, 0))
                for side = -1, 1, 2 do
                    local mark = decorPart(
                        decor,
                        "FluxRouteChevron" .. laneIndex .. "_" ..
                            stepIndex .. "_" .. tostring(side),
                        Vector3.new(0.13, 0.05, 0.95),
                        position,
                        stepIndex == 3 and theme.Accent or theme.Secondary,
                        VisualTheme.Materials.Glow
                    )
                    mark.CFrame = facing * CFrame.new(side * 0.38, 0, 0)
                        * CFrame.Angles(0, math.rad(side * 34), 0)
                    mark.Transparency = 0.36 + (3 - stepIndex) * 0.06
                    mark.CastShadow = false
                end
            end
        end

        local hub = decorPart(
            decor,
            "CrossroadHubMark",
            Vector3.new(22, 0.10, 22),
            center + Vector3.new(0, 1.22, 0),
            theme.Detail:Lerp(theme.Secondary, 0.24),
            theme.PanelMaterial or Enum.Material.Metal
        )
        hub.Transparency = 0.32
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
            theme.Detail:Lerp(theme.Accent, 0.28),
            theme.PanelMaterial or Enum.Material.Metal
        )
        coreMark.Shape = Enum.PartType.Cylinder
        coreMark.CFrame = CFrame.new(coreMark.Position) * CFrame.Angles(0, 0, math.rad(90))
        coreMark.Transparency = 0.34
    end

    local panelOffsetX = math.max(18, (variant.BaseSize.X * 0.5) - 17)
    local panelOffsetZ = math.max(18, (variant.BaseSize.Z * 0.5) - 17)
    local panelRotation = variant.Id == "Orbital" and 45
        or (variant.Id == "Crossroads" and 0 or 8)
    local panelOffsets = {
        Vector3.new(-panelOffsetX, 1.17, -panelOffsetZ),
        Vector3.new(panelOffsetX, 1.17, -panelOffsetZ),
        Vector3.new(-panelOffsetX, 1.17, panelOffsetZ),
        Vector3.new(panelOffsetX, 1.17, panelOffsetZ),
    }
    for i, offset in ipairs(panelOffsets) do
        local maintenance = decorPart(
            decor,
            "FloorMaintenancePanel" .. i,
            Vector3.new(15, 0.045, 9),
            center + offset,
            theme.Surface:Lerp(theme.Structure, 0.38),
            theme.PanelMaterial or VisualTheme.Materials.Panel
        )
        maintenance.CFrame = CFrame.new(maintenance.Position)
            * CFrame.Angles(0, math.rad((i % 2 == 0 and -1 or 1) * panelRotation), 0)
        maintenance.Transparency = 0.32
        maintenance.CanCollide = false
        maintenance.CanTouch = false
        maintenance.CanQuery = false
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
        theme.Surface:Lerp(theme.Structure, 0.26),
        theme.PanelMaterial or VisualTheme.Materials.Panel
    )
    -- Quiet, durable walking inset: hazards keep visual priority and the
    -- rim now reads as a separate machined structural layer.
    topPanel.Transparency = 0.07
    local routeTier = tonumber(platform:GetAttribute("RouteTier"))
    if routeTier then
        -- Tiers stay predominantly machined metal. Subtle cold-color
        -- differences reveal the height route without competing with
        -- orange/red disaster warnings or introducing extra draw calls.
        topPanel.Color = theme.Surface:Lerp(
            theme.Detail, 0.24 + (math.clamp(routeTier, 1, 4) - 1) * 0.06
        )
    end

    -- Four separate, shallow edge chamfers give the deck a deliberate
    -- machined silhouette instead of the default square Roblox slab.
    -- They sit OUTSIDE the walkable top surface, below foot level,
    -- and remain non-colliding/non-queryable. Disappearing Platforms
    -- must hide them together with the parent platform.
    local halfX, halfZ = platform.Size.X * 0.5, platform.Size.Z * 0.5
    local bevelDepth = math.clamp(math.min(halfX, halfZ) * 0.15, 0.28, 0.65)
    local bevelY = platform.Position.Y + platform.Size.Y * 0.5 - 0.20
    local edgeColor = theme.Structure:Lerp(
        routeTier and theme.Secondary or theme.Detail,
        routeTier and (0.14 + math.clamp(routeTier, 1, 4) * 0.04) or 0.40
    )
    local edgeMaterial = VisualTheme.Materials.Structure
    local edgeSpecs = {
        {Vector3.new(platform.Size.X + 0.12, 0.30, bevelDepth),
            Vector3.new(0, bevelY, -halfZ - bevelDepth * 0.27)},
        {Vector3.new(platform.Size.X + 0.12, 0.30, bevelDepth),
            Vector3.new(0, bevelY, halfZ + bevelDepth * 0.27)},
        {Vector3.new(bevelDepth, 0.30, platform.Size.Z + 0.12),
            Vector3.new(-halfX - bevelDepth * 0.27, bevelY, 0)},
        {Vector3.new(bevelDepth, 0.30, platform.Size.Z + 0.12),
            Vector3.new(halfX + bevelDepth * 0.27, bevelY, 0)},
    }
    for edgeIndex, spec in ipairs(edgeSpecs) do
        local bevel = decorPart(
            decor,
            "PlatformBevel" .. index .. "_" .. edgeIndex,
            spec[1],
            Vector3.new(platform.Position.X, 0, platform.Position.Z) + spec[2],
            edgeColor,
            edgeMaterial
        )
        bevel.Transparency = 0.08
    end

    local underFrame = decorPart(
        decor,
        "PlatformUnderFrame" .. index,
        Vector3.new(platform.Size.X + 0.5, 0.42, platform.Size.Z + 0.5),
        platform.Position - Vector3.new(0, (platform.Size.Y * 0.5) + 0.18, 0),
        theme.Structure:Lerp(VisualTheme.World.Deep, 0.30),
        VisualTheme.Materials.Structure
    )
    underFrame.Transparency = 0.04

    local core = decorPart(
        decor,
        "PlatformCoreGlow" .. index,
        Vector3.new(
            math.max(0.8, platform.Size.X * 0.32),
            0.12,
            math.max(0.8, platform.Size.Z * 0.32)
        ),
        platform.Position - Vector3.new(0, (platform.Size.Y * 0.5) + 0.42, 0),
        (index % 2 == 0) and theme.Secondary or theme.Accent,
        VisualTheme.Materials.Glow
    )
    core.Transparency = routeTier and
        (0.72 - math.clamp(routeTier, 1, 4) * 0.04) or 0.56

    local platformBottom = platform.Position.Y - (platform.Size.Y * 0.5)
    local deckTop = 1.15
    local supportHeight = platformBottom - deckTop
    if supportHeight >= 3.5 then
        local supportWidth = math.clamp(math.min(platform.Size.X, platform.Size.Z) * 0.10, 0.72, 1.35)
        local supportColor = theme.Structure:Lerp(theme.Detail, 0.14)
        local insetX = math.max(0, (platform.Size.X * 0.5) - 2.0)
        local insetZ = math.max(0, (platform.Size.Z * 0.5) - 2.0)
        local supportOffsets = {
            Vector3.new(-insetX, 0, -insetZ),
            Vector3.new(insetX, 0, insetZ),
        }

        if math.min(platform.Size.X, platform.Size.Z) >= 11 then
            table.insert(supportOffsets, Vector3.new(-insetX, 0, insetZ))
            table.insert(supportOffsets, Vector3.new(insetX, 0, -insetZ))
        end

        for supportIndex, offset in ipairs(supportOffsets) do
            local support = decorPart(
                decor,
                "PlatformSupport" .. index .. "_" .. supportIndex,
                Vector3.new(supportWidth, supportHeight, supportWidth),
                Vector3.new(
                    platform.Position.X + offset.X,
                    deckTop + (supportHeight * 0.5),
                    platform.Position.Z + offset.Z
                ),
                supportColor,
                VisualTheme.Materials.Structure
            )
            support.Transparency = 0.14
            support.CanCollide = false
            support.CanTouch = false
            support.CanQuery = false
        end
    end
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


    local loopSteps = {
        {label = "01  VOTE", offset = Vector3.new(-21, 1.16, -10), color = VisualTheme.Accents.Cyan},
        {label = "02  SURVIVE", offset = Vector3.new(0, 1.16, -18), color = VisualTheme.Accents.Violet},
        {label = "03  REPEAT", offset = Vector3.new(21, 1.16, -10), color = VisualTheme.Accents.Magenta},
    }

    for i, def in ipairs(loopSteps) do
        local panel = decorPart(
            decor,
            "LobbyLoopPanel" .. i,
            Vector3.new(15, 0.10, 5.2),
            config.LobbyCenter + def.offset,
            VisualTheme.World.Deep,
            VisualTheme.Materials.Panel
        )
        panel.Transparency = 0.03

        local gui = Instance.new("SurfaceGui")
        gui.Name = "LoopPanelGui"
        gui.Face = Enum.NormalId.Top
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 34
        gui.LightInfluence = 0
        gui.AlwaysOnTop = false
        gui.Parent = panel

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.GothamBlack
        text.Text = def.label
        text.TextColor3 = def.color
        text.TextStrokeColor3 = Color3.fromRGB(5, 8, 14)
        text.TextStrokeTransparency = 0.40
        text.TextScaled = true
        text.Parent = gui
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

    local gateInnerGlow = decorPart(
        decor,
        "ArenaGateInnerGlow",
        Vector3.new(17.8, 0.34, 0.48),
        archCenter + Vector3.new(0, 11.45, -1.62),
        VisualTheme.Accents.Cyan,
        VisualTheme.Materials.Glow
    )
    gateInnerGlow.Transparency = 0.16
    gateInnerGlow.CanCollide = false
    gateInnerGlow.CanTouch = false
    gateInnerGlow.CanQuery = false

    for side = -1, 1, 2 do
        for index = 1, 2 do
            local indicator = decorPart(
                decor,
                (side < 0 and "ArenaGateIndicatorL" or "ArenaGateIndicatorR") .. index,
                Vector3.new(0.34, 3.6, 0.34),
                archCenter + Vector3.new(side * (8.45 + index * 0.52), 5.3 + index * 3.8, -1.60),
                index == 1 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
                VisualTheme.Materials.Glow
            )
            indicator.Transparency = 0.22
            indicator.CanCollide = false
            indicator.CanTouch = false
            indicator.CanQuery = false
        end
    end

    local gateGui = Instance.new("SurfaceGui")
    gateGui.Name = "ArenaGateGui"
    gateGui.Face = Enum.NormalId.Front
    gateGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gateGui.PixelsPerStud = 42
    gateGui.LightInfluence = 0
    gateGui.AlwaysOnTop = false
    gateGui.Parent = archTop

    local gatePanel = Instance.new("Frame")
    gatePanel.Name = "GatePanel"
    gatePanel.AnchorPoint = Vector2.new(0.5, 0.5)
    gatePanel.Position = UDim2.fromScale(0.5, 0.5)
    gatePanel.Size = UDim2.fromScale(0.88, 0.72)
    gatePanel.BackgroundColor3 = VisualTheme.World.Deep
    gatePanel.BackgroundTransparency = 0.10
    gatePanel.BorderSizePixel = 0
    gatePanel.Parent = gateGui

    local gateCorner = Instance.new("UICorner")
    gateCorner.CornerRadius = UDim.new(0.08, 0)
    gateCorner.Parent = gatePanel

    local gateStroke = Instance.new("UIStroke")
    gateStroke.Name = "GateStroke"
    gateStroke.Color = VisualTheme.Accents.Cyan
    gateStroke.Thickness = 2
    gateStroke.Transparency = 0.18
    gateStroke.Parent = gatePanel

    local gateStatus = Instance.new("TextLabel")
    gateStatus.Name = "GateStatus"
    gateStatus.Position = UDim2.fromScale(0.05, 0.08)
    gateStatus.Size = UDim2.fromScale(0.90, 0.48)
    gateStatus.BackgroundTransparency = 1
    gateStatus.Font = Enum.Font.GothamBlack
    gateStatus.Text = "ARENA LINK"
    gateStatus.TextColor3 = Color3.fromRGB(245, 248, 255)
    gateStatus.TextStrokeColor3 = Color3.fromRGB(3, 6, 12)
    gateStatus.TextStrokeTransparency = 0.60
    gateStatus.TextScaled = true
    gateStatus.Parent = gatePanel

    local gateSubstatus = Instance.new("TextLabel")
    gateSubstatus.Name = "GateSubstatus"
    gateSubstatus.Position = UDim2.fromScale(0.05, 0.57)
    gateSubstatus.Size = UDim2.fromScale(0.90, 0.25)
    gateSubstatus.BackgroundTransparency = 1
    gateSubstatus.Font = Enum.Font.GothamBold
    gateSubstatus.Text = "MOVE • VOTE • SURVIVE"
    gateSubstatus.TextColor3 = VisualTheme.Accents.Cyan
    gateSubstatus.TextStrokeColor3 = Color3.fromRGB(3, 6, 12)
    gateSubstatus.TextStrokeTransparency = 0.72
    gateSubstatus.TextScaled = true
    gateSubstatus.Parent = gatePanel

    local runwayCenter = config.LobbyCenter + Vector3.new(0, 1.18, 17.5)
    local runway = decorPart(
        decor,
        "ArenaRunway",
        Vector3.new(14, 0.10, 29),
        runwayCenter,
        VisualTheme.World.Deep:Lerp(VisualTheme.World.SurfaceRaised, 0.22),
        VisualTheme.Materials.Panel
    )
    runway.Transparency = 0.02
    runway.CanCollide = false

    for side = -1, 1, 2 do
        local rail = decorPart(
            decor,
            side < 0 and "ArenaRunwayRailLeft" or "ArenaRunwayRailRight",
            Vector3.new(0.30, 0.12, 29),
            runwayCenter + Vector3.new(side * 6.4, 0.10, 0),
            side < 0 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
            VisualTheme.Materials.Glow
        )
        rail.Transparency = 0.16
        rail.CanCollide = false
        rail.CanTouch = false
        rail.CanQuery = false
    end

    for i = 1, 4 do
        local z = 7 + (i * 4.7)
        local height = 6.5 + (i * 0.45)
        local leftRib = decorPart(
            decor,
            "ArenaApproachRibL" .. i,
            Vector3.new(0.55, height, 0.55),
            config.LobbyCenter + Vector3.new(-7.2, 1.1 + height * 0.5, z),
            VisualTheme.World.Metal,
            VisualTheme.Materials.Structure
        )
        leftRib.Transparency = 0.04

        local rightRib = decorPart(
            decor,
            "ArenaApproachRibR" .. i,
            Vector3.new(0.55, height, 0.55),
            config.LobbyCenter + Vector3.new(7.2, 1.1 + height * 0.5, z),
            VisualTheme.World.Metal,
            VisualTheme.Materials.Structure
        )
        rightRib.Transparency = 0.04

        local topRib = decorPart(
            decor,
            "ArenaApproachRibTop" .. i,
            Vector3.new(14.9, 0.42, 0.55),
            config.LobbyCenter + Vector3.new(0, 1.1 + height, z),
            i % 2 == 0 and VisualTheme.Accents.Violet or VisualTheme.Accents.Cyan,
            VisualTheme.Materials.Glow
        )
        topRib.Transparency = 0.24
        topRib.CanCollide = false
        topRib.CanTouch = false
        topRib.CanQuery = false
    end

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
    surface.Face = Enum.NormalId.Back
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 45
    surface.AlwaysOnTop = false
    surface.Parent = sign

    local brandMark = Instance.new("Frame")
    brandMark.Name = "ChaosWorldBrandSigil"
    brandMark.AnchorPoint = Vector2.new(0.5, 0.5)
    brandMark.Position = UDim2.fromScale(0.16, 0.50)
    brandMark.Size = UDim2.fromScale(0.20, 0.62)
    brandMark.BackgroundTransparency = 1
    brandMark.Parent = surface

    local outerDiamond = Instance.new("Frame")
    outerDiamond.Name = "OuterDiamond"
    outerDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
    outerDiamond.Position = UDim2.fromScale(0.5, 0.5)
    outerDiamond.Size = UDim2.fromScale(0.66, 0.66)
    outerDiamond.Rotation = 45
    outerDiamond.BackgroundColor3 = VisualTheme.Accents.Cyan
    outerDiamond.BackgroundTransparency = 0.78
    outerDiamond.BorderSizePixel = 0
    outerDiamond.Parent = brandMark

    local outerCorner = Instance.new("UICorner")
    outerCorner.CornerRadius = UDim.new(0, 8)
    outerCorner.Parent = outerDiamond

    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = VisualTheme.Accents.Cyan
    outerStroke.Thickness = 2
    outerStroke.Transparency = 0.18
    outerStroke.Parent = outerDiamond

    local middleDiamond = Instance.new("Frame")
    middleDiamond.Name = "MiddleDiamond"
    middleDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
    middleDiamond.Position = UDim2.fromScale(0.5, 0.5)
    middleDiamond.Size = UDim2.fromScale(0.46, 0.46)
    middleDiamond.Rotation = 45
    middleDiamond.BackgroundColor3 = VisualTheme.Accents.Violet
    middleDiamond.BackgroundTransparency = 0.20
    middleDiamond.BorderSizePixel = 0
    middleDiamond.Parent = brandMark

    local middleCorner = Instance.new("UICorner")
    middleCorner.CornerRadius = UDim.new(0, 7)
    middleCorner.Parent = middleDiamond

    local crystal = Instance.new("Frame")
    crystal.Name = "CrystalCore"
    crystal.AnchorPoint = Vector2.new(0.5, 0.5)
    crystal.Position = UDim2.fromScale(0.5, 0.5)
    crystal.Size = UDim2.fromScale(0.22, 0.44)
    crystal.Rotation = 45
    crystal.BackgroundColor3 = VisualTheme.Accents.Cyan:Lerp(Color3.new(1, 1, 1), 0.30)
    crystal.BorderSizePixel = 0
    crystal.Parent = brandMark

    local crystalCorner = Instance.new("UICorner")
    crystalCorner.CornerRadius = UDim.new(0, 6)
    crystalCorner.Parent = crystal

    for i, def in ipairs({
        {x = 0.12, y = 0.50, rotation = -18, color = VisualTheme.Accents.Cyan},
        {x = 0.88, y = 0.50, rotation = 18, color = VisualTheme.Accents.Violet},
        {x = 0.50, y = 0.10, rotation = 90, color = VisualTheme.Accents.Orange},
    }) do
        local slash = Instance.new("Frame")
        slash.Name = "OrbitSlash" .. i
        slash.AnchorPoint = Vector2.new(0.5, 0.5)
        slash.Position = UDim2.fromScale(def.x, def.y)
        slash.Size = UDim2.fromScale(0.28, 0.055)
        slash.Rotation = def.rotation
        slash.BackgroundColor3 = def.color
        slash.BackgroundTransparency = 0.10
        slash.BorderSizePixel = 0
        slash.Parent = brandMark

        local slashCorner = Instance.new("UICorner")
        slashCorner.CornerRadius = UDim.new(1, 0)
        slashCorner.Parent = slash
    end

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromScale(0.29, 0)
    title.Size = UDim2.fromScale(0.66, 0.62)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.fromRGB(245, 248, 255)
    title.TextStrokeTransparency = 0.65
    title.TextScaled = true
    title.Text = "CHAOS SURVIVAL"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = surface

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromScale(0.29, 0.62)
    subtitle.Size = UDim2.fromScale(0.66, 0.30)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.TextColor3 = Color3.fromRGB(120, 195, 255)
    subtitle.TextScaled = true
    subtitle.Text = "VOTE • SURVIVE • ADAPT"
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
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

    local haloRadius = 18
    for i = 1, 12 do
        local angle = ((i - 1) / 12) * math.pi * 2
        local position = config.LobbyCenter + Vector3.new(
            math.cos(angle) * haloRadius,
            13.5 + math.sin(angle * 2) * 0.45,
            math.sin(angle) * haloRadius
        )
        local segment = decorPart(
            decor,
            "LobbyHaloSegment" .. i,
            Vector3.new(4.8, 0.22, 0.48),
            position,
            (i % 3 == 0) and VisualTheme.Accents.Magenta
                or ((i % 2 == 0) and VisualTheme.Accents.Violet or VisualTheme.Accents.Cyan),
            VisualTheme.Materials.Glow
        )
        segment.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, 0)
        segment.Transparency = 0.24
        segment.CanCollide = false
        segment.CanTouch = false
        segment.CanQuery = false
        segment.CastShadow = false
    end

    local identityPanels = {
        {
            name = "Disasters",
            text = "11 DISASTERS",
            offset = Vector3.new(-28, 5.5, -16),
            color = VisualTheme.Accents.Cyan,
            face = Enum.NormalId.Front,
        },
        {
            name = "Arenas",
            text = "4 ARENAS",
            offset = Vector3.new(28, 5.5, -16),
            color = VisualTheme.Accents.Violet,
            face = Enum.NormalId.Front,
        },
        {
            name = "Solo",
            text = "SOLO READY",
            offset = Vector3.new(-28, 5.5, 16),
            color = VisualTheme.Accents.Magenta,
            face = Enum.NormalId.Back,
        },
        {
            name = "FairPlay",
            text = "COSMETIC • NO P2W",
            offset = Vector3.new(28, 5.5, 16),
            color = VisualTheme.Accents.Gold or Color3.fromRGB(255, 205, 85),
            face = Enum.NormalId.Back,
        },
    }

    for i, def in ipairs(identityPanels) do
        local panel = decorPart(
            decor,
            "LobbyIdentityPanel" .. i,
            Vector3.new(12, 4.2, 0.45),
            config.LobbyCenter + def.offset,
            VisualTheme.World.Deep,
            VisualTheme.Materials.Structure
        )
        panel.CanCollide = false
        panel.Transparency = 0.04

        local rail = decorPart(
            decor,
            "LobbyIdentityRail" .. i,
            Vector3.new(12.4, 0.24, 0.60),
            panel.Position + Vector3.new(0, -2.0, 0),
            def.color,
            VisualTheme.Materials.Glow
        )
        rail.CanCollide = false
        rail.CanTouch = false
        rail.CanQuery = false
        rail.Transparency = 0.16

        local gui = Instance.new("SurfaceGui")
        gui.Name = def.name .. "Gui"
        gui.Face = def.face
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 44
        gui.LightInfluence = 0
        gui.AlwaysOnTop = false
        gui.Parent = panel

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBlack
        label.Text = def.text
        label.TextColor3 = def.color
        label.TextStrokeColor3 = Color3.fromRGB(4, 7, 12)
        label.TextStrokeTransparency = 0.46
        label.TextScaled = true
        label.Parent = gui
    end

    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(8, 1, 8)
    -- Keep the ENTIRE native 8x8 footprint off the raised centre stage
    -- AND off the solid "02 SURVIVE" loop panel at z=-18. The staging
    -- sign overhead is non-colliding, and the flat lobby floor extends
    -- beyond every edge of the spawn footprint.
    -- Face the arena gate (+Z) so first-time players see where to go.
    local spawnPosition = config.LobbyCenter + Vector3.new(0, 2.8, -27)
    lobbySpawn.CFrame = CFrame.lookAt(spawnPosition, spawnPosition + Vector3.new(0, 0, 1))
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
        theme.FloorMaterial or VisualTheme.Materials.Floor
    )
    base:SetAttribute("OriginalSizeX", base.Size.X)
    base:SetAttribute("OriginalSizeZ", base.Size.Z)

    local killPlane = part(
        arena,
        "KillPlane",
        Vector3.new(
            math.max(160, variant.BaseSize.X + 32), 2,
            math.max(160, variant.BaseSize.Z + 32)
        ),
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

    local entryGuides = Instance.new("Folder")
    entryGuides.Name = "EntryGuides"
    entryGuides.Parent = arena

    for i, offset in ipairs(variant.SpawnOffsets) do
        -- Markers sit ON the arena floor, never as floating solid slabs
        -- directly inside the player's feet or beneath a mezzanine.
        local spawnPosition = config.ArenaCenter + Vector3.new(
            offset.X, variant.BaseSize.Y * 0.5 + 0.14, offset.Z
        )
        local s = part(
            spawnFolder,
            "Spawn" .. i,
            Vector3.new(4.6, 0.12, 4.6),
            spawnPosition,
            theme.Detail:Lerp(Color3.new(1, 1, 1), 0.10),
            VisualTheme.Materials.Structure
        )
        s.CFrame = ArenaPresentation.spawnCFrame(
            variant.Id,
            spawnPosition,
            config.ArenaCenter
        )
        -- Spawns are cosmetic locators. The floor is the only support;
        -- solid marker slabs formerly trapped avatars below raised decks.
        s.CanCollide = false
        s.CanTouch = false
        s.CanQuery = false
        s.Transparency = 0.34

        local guideColor = i % 2 == 0 and theme.Secondary or theme.Accent
        for side = -1, 1, 2 do
            local guide = decorPart(
                entryGuides,
                "EntryChevron" .. i .. "_" .. tostring(side),
                Vector3.new(2.6, 0.08, 0.24),
                spawnPosition,
                guideColor,
                VisualTheme.Materials.Glow
            )
            guide.CFrame = s.CFrame
                * CFrame.new(side * 0.78, 0.04, -3.0)
                * CFrame.Angles(0, math.rad(side * 34), 0)
            guide.Transparency = 0.22
        end

        local glow = part(
            arena,
            "SpawnGlow" .. i,
            Vector3.new(5.2, 0.12, 5.2),
            spawnPosition + Vector3.new(0, -0.03, 0),
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
    addPerimeterStations(decor, config, variant, theme)
    addDistantSkyline(decor, config, variant, theme)
    addArenaSignatureMegastructure(decor, config, variant, theme)
    addExteriorCornerRidges(decor, config, variant, theme)
    addVariantIdentity(decor, config, variant, theme)
    addVariantLandmarks(decor, config, variant, theme)
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

    -- PerimeterRoutes are appended AFTER every original platform ID.
    -- Keeping the combined parts under Platforms lets all server-owned
    -- disaster and AI systems treat outer routes as real gameplay geometry.
    local platformDefinitions = table.clone(variant.Platforms)
    for _, definition in ipairs(variant.PerimeterPlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end

    for i, definition in ipairs(platformDefinitions) do
        local platformPosition = config.ArenaCenter + definition.offset
        local platform = part(
            platforms,
            "Platform" .. i,
            definition.size,
            platformPosition,
            theme.Detail,
            theme.StructureMaterial or VisualTheme.Materials.Structure
        )
        platform.Color = theme.Detail:Lerp(theme.Surface, 0.28)
        local routeTier = tonumber(definition.RouteTier)
        if routeTier and routeTier >= 1 and routeTier <= 4 then
            platform:SetAttribute("RouteTier", routeTier)
        end
        if definition.PerimeterRoute then
            -- Explicit route metadata is visible to wayfinding and QA.
            -- It is not a fake waypoint: this is a collidable real Part.
            platform:SetAttribute("PerimeterRoute", definition.PerimeterRoute)
            platform:SetAttribute("PerimeterStep", definition.PerimeterStep)
            platform.Color = theme.Surface:Lerp(
                definition.PerimeterStep == 1 and theme.Detail or theme.Secondary,
                0.30
            )
            platform.Material = theme.StructureMaterial
                or VisualTheme.Materials.Structure
        end

        if definition.Skybridge == true then
            platform.Name = "Skybridge" .. tostring(i)
            platform:SetAttribute("ChaosSkybridge", true)
            platform.Material = VisualTheme.Materials.Structure
            -- Clean parallel luminous rails make the route legible without
            -- opaque barriers that interfere with dodge/parkour.
            local alongX = platform.Size.X > platform.Size.Z
            local span = math.max(platform.Size.X, platform.Size.Z) - 0.8
            local width = math.min(platform.Size.X, platform.Size.Z)
            for side = -1, 1, 2 do
                local railOffset = (width * 0.5 - 0.34) * side
                local rail = decorPart(
                    decor,
                    "SkybridgeRail" .. i .. "_" .. tostring(side),
                    alongX and Vector3.new(span, 0.14, 0.20)
                        or Vector3.new(0.20, 0.14, span),
                    platform.Position + Vector3.new(
                        alongX and 0 or railOffset,
                        (platform.Size.Y * 0.5) + 0.10,
                        alongX and railOffset or 0
                    ),
                    side < 0 and theme.Accent or theme.Secondary,
                    VisualTheme.Materials.Glow
                )
                rail.Transparency = 0.16
                rail.CastShadow = false
            end
            -- Three under-deck ribs per bridge suggest structural engineering
            -- at no collision cost. The bridge itself remains the only
            -- physical route.
            for ribIndex = -1, 1 do
                local rib = decorPart(
                    decor,
                    "SkybridgeRib" .. i .. "_" .. tostring(ribIndex),
                    alongX and Vector3.new(0.46, 0.38, width + 0.22)
                        or Vector3.new(width + 0.22, 0.38, 0.46),
                    platform.Position + Vector3.new(
                        alongX and ribIndex * span * 0.27 or 0,
                        -(platform.Size.Y * 0.5) - 0.24,
                        alongX and 0 or ribIndex * span * 0.27
                    ),
                    theme.Structure,
                    VisualTheme.Materials.Structure
                )
                rib.CastShadow = false
            end
        end

        local trim = decorPart(
            decor,
            "PlatformGlow" .. i,
            Vector3.new(definition.size.X + 0.28, 0.12, definition.size.Z + 0.28),
            platformPosition - Vector3.new(0, (definition.size.Y * 0.5) + 0.13, 0),
            (i % 2 == 0) and theme.Secondary or theme.Accent,
            VisualTheme.Materials.Glow
        )
        trim.CanCollide = false
        trim.CanTouch = false
        trim.CanQuery = false
        -- An exposed fluorescent slab under every deck made the platforms
        -- read like toy blocks. The engineered shadow lip is primary,
        -- with a thinner subdued signal layer beneath it.
        if routeTier then
            local tierColor = routeTier == 1 and theme.Accent
                or (routeTier == 2 and theme.Accent:Lerp(theme.Secondary, 0.30)
                    or (routeTier == 3 and theme.Secondary
                        or theme.Secondary:Lerp(theme.Accent, 0.55)))
            trim.Color = tierColor
            trim.Transparency = 0.72 - routeTier * 0.04
        else
            trim.Transparency = 0.64
        end
        addPlatformFinish(decor, platform, i, theme)

        if definition.PerimeterStep == 2 then
            -- Original native three-dimensional exit facade: four simple
            -- nonblocking components per route, no extra emitters/lights.
            -- Mounted on the OUTWARD face of the solid exit pedestal,
            -- away from the player's approach and central hazard lanes.
            local frontSign = platformPosition.Z >= config.ArenaCenter.Z
                and 1 or -1
            local outerZ = platformPosition.Z
                + frontSign * (platform.Size.Z * 0.5 + 0.18)
            for side = -1, 1, 2 do
                local rib = decorPart(
                    decor,
                    "PerimeterExitRib" .. definition.PerimeterRoute
                        .. "_" .. tostring(side),
                    Vector3.new(0.88, platform.Size.Y - 1.05, 0.34),
                    Vector3.new(platformPosition.X + side * 3.35,
                        platformPosition.Y - 0.20, outerZ),
                    theme.Structure:Lerp(theme.Detail, 0.18),
                    Enum.Material.Metal
                )
                rib.Transparency = 0.06
                rib:SetAttribute("PerimeterPlatformIndex", i)
            end
            local cap = Instance.new("WedgePart")
            cap.Name = "PerimeterExitCrown" .. definition.PerimeterRoute
            cap.Size = Vector3.new(8.0, 1.15, 1.0)
            cap.CFrame = CFrame.new(
                platformPosition.X,
                platformPosition.Y + platform.Size.Y * 0.5 - 0.45,
                outerZ + frontSign * 0.34
            ) * CFrame.Angles(0, frontSign < 0 and math.pi or 0, 0)
            cap.Color = theme.Detail:Lerp(theme.Structure, 0.30)
            cap.Material = Enum.Material.Metal
            cap.Anchored = true
            cap.CanCollide = false
            cap.CanTouch = false
            cap.CanQuery = false
            cap.CastShadow = false
            cap.Transparency = 0.08
            cap.Parent = decor
            cap:SetAttribute("PerimeterPlatformIndex", i)
            local lens = decorPart(
                decor,
                "PerimeterExitLens" .. definition.PerimeterRoute,
                Vector3.new(2.1, 2.1, 0.35),
                Vector3.new(platformPosition.X, platformPosition.Y,
                    outerZ + frontSign * 0.22),
                theme.Accent:Lerp(theme.Structure, 0.56),
                Enum.Material.Glass
            )
            lens.Transparency = 0.34
            lens:SetAttribute("PerimeterPlatformIndex", i)
        end
    end

    if variant.Id == "Orbital" then
        -- Fully physical sloped routes between the outer and inner decks.
        -- No scripted platform movement or client-controlled collisions.
        OrbitalHelix.build(arena, variant, config.ArenaCenter, theme)
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
