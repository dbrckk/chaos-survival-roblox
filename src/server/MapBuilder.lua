local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local shared = ReplicatedStorage:FindFirstChild("Shared")
local visualThemeModule = shared and shared:FindFirstChild("VisualTheme")
local VisualTheme = if visualThemeModule
    then require(visualThemeModule)
    else require("../shared/VisualTheme")
local arenaPresentationModule = shared and shared:FindFirstChild("ArenaPresentation")
local ArenaPresentation = if arenaPresentationModule
    then require(arenaPresentationModule)
    else require("../shared/ArenaPresentation")
local skyRouteConnectionModule = shared and shared:FindFirstChild("SkyRouteConnectionRules")
local SkyRouteConnectionRules = if skyRouteConnectionModule
    then require(skyRouteConnectionModule)
    else require("../shared/SkyRouteConnectionRules")
-- Cloud engine specs can import new source modules before the published
-- place has received them; prefer sibling ModuleScript, otherwise source.
local helixModule = script and script.Parent:FindFirstChild("OrbitalHelix")
local OrbitalHelix = if helixModule
    then require(helixModule)
    else require("./OrbitalHelix")

local HeroArchitecture = require("./HeroArchitecture")
local ArenaDistrictArchitecture = require("./ArenaDistrictArchitecture")
local HarborScenery = require("./HarborScenery")
local PromenadeArchitecture = require("./PromenadeArchitecture")
local SkySpineArchitecture = require("./SkySpineArchitecture")
local RouteSignalGeometry = require("./RouteSignalGeometry")
local PremiumLargeStructureAssets = require("./PremiumLargeStructureAssets")
local SkyRouteMonuments = require("./SkyRouteMonuments")
local ArchitecturalCladding = require("./ArchitecturalCladding")
local ArenaGroundArchitecture = require("./ArenaGroundArchitecture")
local StructureRetrofit = require("./StructureRetrofit")

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

local function fitDecorMesh(profile, name, pose, size, color, material)
    local detail = RouteSignalGeometry.fit(profile, pose, size)
    if not detail then
        detail = decorPart(nil, name, size, pose.Position, color, material)
        detail.CFrame = pose
    end
    detail.Name = name
    detail.Color = color
    detail.Material = material
    return detail
end

local function bindLandingBillboard(billboard, deck)
    local function refresh()
        local phase = deck:GetAttribute("CollapsePhase")
        billboard.Enabled = deck.Parent ~= nil
            and deck.CanCollide and deck.Transparency < 0.75
            and phase ~= "Warning" and phase ~= "Gone"
    end
    deck:GetAttributeChangedSignal("CollapsePhase"):Connect(refresh)
    deck:GetPropertyChangedSignal("CanCollide"):Connect(refresh)
    deck:GetPropertyChangedSignal("Transparency"):Connect(refresh)
    refresh()
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

        -- Distinctive architectural kitbash: actual layered 3D forms rather
        -- than generic floating neon blocks. All authored pieces share the
        -- existing model, without dynamic updates, shadows or colliders.
        -- Ground-level floor remains authoritative for hazards and R15.
        for _, side in ipairs({-1, 1}) do
            piece(side < 0 and "CompressorPodL" or "CompressorPodR",
                "Part", Vector3.new(3.7, 3.1, 4.6),
                CFrame.new(side * 7.0, 2.4, 1.1),
                Enum.Material.Metal,
                theme.Structure:Lerp(theme.Detail, 0.36), 0.04)
            local intake = piece(
                side < 0 and "IntakeTurbineL" or "IntakeTurbineR",
                "Part", Vector3.new(2.6, 0.8, 2.6),
                CFrame.new(side * 7.0, 3.4, -1.4)
                    * CFrame.Angles(math.rad(90), 0, 0),
                Enum.Material.Metal, theme.Detail, 0.08)
            intake.Shape = Enum.PartType.Cylinder
            piece(side < 0 and "AngledServiceWingL" or "AngledServiceWingR",
                "WedgePart", Vector3.new(3.4, 1.7, 5.7),
                CFrame.new(side * 7.0, 4.9, 1.1)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal,
                theme.Structure:Lerp(theme.Secondary, 0.23), 0.06)
            piece(side < 0 and "PodDataRailL" or "PodDataRailR",
                "Part", Vector3.new(0.18, 0.22, 3.1),
                CFrame.new(side * 8.85, 3.4, 0.7),
                Enum.Material.Neon, side < 0 and accent or secondary, 0.40)
        end
        local generator = piece("GeneratorRotor", "Part",
            Vector3.new(2.7, 0.9, 2.7),
            CFrame.new(0, 8.1, -1.4)
                * CFrame.Angles(math.rad(90), 0, 0),
            Enum.Material.Metal, theme.Detail, 0.08)
        generator.Shape = Enum.PartType.Cylinder
        piece("GeneratorShield", "Part", Vector3.new(4.0, 0.55, 1.4),
            CFrame.new(0, 7.8, -0.4), Enum.Material.Metal,
            theme.Structure:Lerp(theme.Accent, 0.24), 0.07)

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
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

    local origin = CFrame.new(
        config.ArenaCenter + Vector3.new(
            variant.BaseSize.X * 0.24,
            variant.BaseSize.Y * 0.5,
            -(variant.BaseSize.Z * 0.5 + 66)
        )
    )
    model:SetAttribute("NorthSignatureOrigin", origin)
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
    elseif variant.Id == "Harbor" then
        -- Northern container-lift terminal: paired heavy port towers,
        -- unequal suspended payloads and a tall articulated gantry.
        -- Original exterior-only metal parts; no lights/collision/VFX.
        for side = -1, 1, 2 do
            piece(side < 0 and "QuayPortLeg" or "QuayStarboardLeg",
                "Part", Vector3.new(3.3, 40, 3.8),
                CFrame.new(side * 16, 20, 0),
                Enum.Material.Metal, hull)
            piece(side < 0 and "QuayRakerPort" or "QuayRakerStarboard",
                "Part", Vector3.new(1.2, 34, 1.5),
                CFrame.new(side * 10.5, 25, 0)
                    * CFrame.Angles(0, 0, side * math.rad(23)),
                Enum.Material.Metal, metal)
            piece(side < 0 and "QuayWinchPort" or "QuayWinchStarboard",
                "Part", Vector3.new(5.4, 4.2, 5.5),
                CFrame.new(side * 10.6, 44, 0),
                Enum.Material.Metal, metal)
            piece(side < 0 and "QuayHoistPort" or "QuayHoistStarboard",
                "Part", Vector3.new(0.3, 17, 0.3),
                CFrame.new(side * 10.6, 33, -2.5),
                Enum.Material.Metal, rim)
        end
        piece("QuayCraneSpanningBeam", "Part",
            Vector3.new(41, 2.1, 4.4), CFrame.new(0, 43.5, 0),
            Enum.Material.Metal, metal)
        piece("QuayCraneCounterweight", "Part",
            Vector3.new(7, 5.8, 7), CFrame.new(-10, 48, 3.0),
            Enum.Material.Metal, hull)
        piece("QuayStormMast", "Part",
            Vector3.new(1.1, 11.5, 1.1), CFrame.new(0, 51.5, 0),
            Enum.Material.Metal, metal)
        piece("QuayControlCab", "Part",
            Vector3.new(7.2, 5.4, 5.2), CFrame.new(4.8, 39.5, 0),
            Enum.Material.Glass, glint, 0.25)
        piece("QuayCargoStack", "Part",
            Vector3.new(21, 4.2, 9), CFrame.new(0, 4.1, 0),
            Enum.Material.Metal, hull)
        piece("QuaySpreader", "Part",
            Vector3.new(25, 0.8, 1.8), CFrame.new(0, 23, -2.5),
            Enum.Material.Metal, rim)
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
    model.Parent = decor
end

-- Give the southern horizon a second, independently authored silhouette.
-- The northern hero is intentionally asymmetrical; without an opposite
-- landmark, half the camera directions still show mostly empty distance.
-- Keep every piece outside the playable deck AND outside the kill plane.
-- All parts are static, shadowless and noninteractive for Android budgets.
local function addSouthHorizonMonument(decor, config, variant, theme)
    local model = Instance.new("Model")
    model.Name = "SouthHorizonMonument"
    model:SetAttribute("ChaosDistantScenery", true)
    model:SetAttribute("SignatureVariant", variant.Id)
    model.Parent = decor

    local origin = CFrame.new(config.ArenaCenter + Vector3.new(
        -variant.BaseSize.X * 0.20,
        variant.BaseSize.Y * 0.5,
        variant.BaseSize.Z * 0.5 + 54
    ))
    local hull = theme.Structure:Lerp(Color3.fromRGB(18, 26, 36), 0.30)
    local alloy = theme.Detail:Lerp(theme.Structure, 0.57)
    local signal = theme.Secondary:Lerp(theme.Structure, 0.36)

    local function piece(name, kind, size, offset, material, color, opacity)
        local item = Instance.new(kind or "Part")
        item.Name = name
        item.Size = size
        item.CFrame = origin * offset
        item.Anchored = true
        item.CanCollide = false
        item.CanTouch = false
        item.CanQuery = false
        item.CastShadow = false
        item.Material = material or Enum.Material.Metal
        item.Color = color or hull
        item.Transparency = opacity or 0
        item.Parent = model
        return item
    end

    piece("Foundation", "Part", Vector3.new(47, 2, 13),
        CFrame.new(0, -1, 0), Enum.Material.Concrete, hull)
    piece("FloorInset", "Part", Vector3.new(39, 0.3, 10),
        CFrame.new(0, 0.16, 0), Enum.Material.Metal, alloy, 0.12)

    if variant.Id == "Orbital" then
        -- A vertical segmented observation ring with genuinely open
        -- center space: never a flat neon disc or a phantom floor.
        local radius, segments = 17, 14
        local chord = 2 * radius * math.sin(math.pi / segments) + 0.08
        for index = 0, segments - 1 do
            local angle = index * math.pi * 2 / segments
            piece("ObservationArc" .. (index + 1), "Part",
                Vector3.new(chord, 1.6, 1.85),
                CFrame.new(radius * math.sin(angle),
                    23 + radius * math.cos(angle), 0)
                    * CFrame.Angles(0, 0, -angle),
                Enum.Material.Metal,
                index % 3 == 0 and signal or alloy, 0.06)
        end
        for side = -1, 1, 2 do
            piece(side < 0 and "LeftRingSupport" or "RightRingSupport",
                "Part", Vector3.new(2.6, 23, 3),
                CFrame.new(side * 15.5, 11.5, 0),
                Enum.Material.Metal, hull)
        end
        local orb = piece("SuspendedOrb", "Part",
            Vector3.new(6.4, 6.4, 6.4), CFrame.new(0, 23, 0),
            Enum.Material.Glass, signal, 0.38)
        orb.Shape = Enum.PartType.Ball
        piece("OrbClamp", "Part", Vector3.new(9.5, 0.8, 2.4),
            CFrame.new(0, 23, -0.2), Enum.Material.Metal, alloy)
    elseif variant.Id == "Towers" then
        -- Heavy industry with two offset lift shafts and a suspended
        -- bridge. Unequal heights make the far skyline recognizable.
        for side = -1, 1, 2 do
            local height = side < 0 and 37 or 46
            piece(side < 0 and "WestLift" or "EastLift",
                "Part", Vector3.new(6.5, height, 7),
                CFrame.new(side * 17.5, height * 0.5, 0),
                Enum.Material.Concrete, hull)
            piece(side < 0 and "WestCrown" or "EastCrown",
                "WedgePart", Vector3.new(9.5, 4.5, 8.5),
                CFrame.new(side * 17.5, height + 2, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, alloy)
            piece(side < 0 and "WestLiftRail" or "EastLiftRail",
                "Part", Vector3.new(0.42, height - 7, 0.6),
                CFrame.new(side * 17.5, height * 0.5, -3.7),
                Enum.Material.Neon, signal, 0.48)
            piece(side < 0 and "WestSuspension" or "EastSuspension",
                "Part", Vector3.new(0.9, 16, 1),
                CFrame.new(side * 10, 31, 0)
                    * CFrame.Angles(0, 0, side * math.rad(26)),
                Enum.Material.Metal, alloy)
        end
        piece("SkyTransfer", "Part", Vector3.new(40, 2.1, 6),
            CFrame.new(0, 36, 0), Enum.Material.Metal, alloy)
        piece("UnderslungLift", "Part", Vector3.new(7, 7, 6),
            CFrame.new(3.5, 31.5, 0), Enum.Material.Metal, hull)
        piece("TransferSignal", "WedgePart", Vector3.new(7, 2, 2),
            CFrame.new(3.5, 26.5, -3.0), Enum.Material.Metal, signal, 0.17)
    elseif variant.Id == "Crossroads" then
        -- A freight exchange with branched cantilevers; the diagonal
        -- overhangs are real sculpted wedges, not floating HUD shapes.
        piece("ExchangeCore", "Part", Vector3.new(8, 39, 8),
            CFrame.new(0, 19.5, 0), Enum.Material.Concrete, hull)
        for side = -1, 1, 2 do
            piece(side < 0 and "WestFork" or "EastFork",
                "Part", Vector3.new(21, 2.4, 5.5),
                CFrame.new(side * 12, 34, 0)
                    * CFrame.Angles(0, 0, side * math.rad(14)),
                Enum.Material.Metal, alloy)
            piece(side < 0 and "WestFreightArm" or "EastFreightArm",
                "WedgePart", Vector3.new(9, 4.8, 6.4),
                CFrame.new(side * 21, 39, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, hull)
            piece(side < 0 and "WestCounterweight" or "EastCounterweight",
                "Part", Vector3.new(5, 8, 5.5),
                CFrame.new(side * 18, 23, 0), Enum.Material.Metal, hull)
            piece(side < 0 and "WestSignal" or "EastSignal",
                "Part", Vector3.new(7, 0.32, 0.4),
                CFrame.new(side * 15, 36, -2.9),
                Enum.Material.Neon, signal, 0.42)
        end
        piece("CentralSwitchCab", "Part", Vector3.new(10, 5, 7),
            CFrame.new(0, 43, 0), Enum.Material.Metal, alloy)
        piece("CabWindow", "Part", Vector3.new(7, 2.2, 0.28),
            CFrame.new(0, 43, -3.6), Enum.Material.Glass, signal, 0.24)
    elseif variant.Id == "Harbor" then
        -- Southern storm-break lightship and twin container stacks.
        -- This open drydock gantry stays behind the player's horizon.
        for side = -1, 1, 2 do
            piece(side < 0 and "WestQuayColumn" or "EastQuayColumn",
                "Part", Vector3.new(4.5, 35, 4.5),
                CFrame.new(side * 16, 17.5, 0),
                Enum.Material.Concrete, hull)
            piece(side < 0 and "WestQuayCargo" or "EastQuayCargo",
                "Part", Vector3.new(11, 7, 8),
                CFrame.new(side * 16, 5.5, 0),
                Enum.Material.Metal, alloy)
            piece(side < 0 and "WestContainerHoist" or "EastContainerHoist",
                "Part", Vector3.new(0.8, 19, 1.0),
                CFrame.new(side * 12.5, 27, 0),
                Enum.Material.Metal, signal)
            piece(side < 0 and "WestQuayRig" or "EastQuayRig",
                "WedgePart", Vector3.new(8, 4, 5),
                CFrame.new(side * 17, 38, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, alloy)
        end
        piece("HarborLightshipBridge", "Part",
            Vector3.new(41, 2.2, 5.7), CFrame.new(0, 34.5, 0),
            Enum.Material.Metal, hull)
        piece("HarborSignalCab", "Part",
            Vector3.new(9, 4.5, 6), CFrame.new(0, 39, 0),
            Enum.Material.Metal, alloy)
        piece("HarborStormLens", "Part",
            Vector3.new(6.8, 2, 0.22), CFrame.new(0, 39.3, -3.1),
            Enum.Material.Glass, signal, 0.25)
        piece("HarborStormBeacon", "Part",
            Vector3.new(0.8, 7, 0.8), CFrame.new(0, 46, 0),
            Enum.Material.Metal, hull)
    else
        -- Classic Grid's multi-dish radar observatory contrasts with
        -- the taller single northern relay tower.
        for side = -1, 1, 2 do
            piece(side < 0 and "WestRadarPylon" or "EastRadarPylon",
                "Part", Vector3.new(3.5, 28, 4.5),
                CFrame.new(side * 16, 14, 0),
                Enum.Material.Concrete, hull)
            local dish = piece(
                side < 0 and "WestRadarDish" or "EastRadarDish",
                "Part", Vector3.new(0.9, 12, 12),
                CFrame.new(side * 16, 34, 0)
                    * CFrame.Angles(0, math.pi * 0.5, 0),
                Enum.Material.Metal, alloy, 0.08)
            dish.Shape = Enum.PartType.Cylinder
            piece(side < 0 and "WestReceiver" or "EastReceiver",
                "Part", Vector3.new(2.1, 2.1, 2.1),
                CFrame.new(side * 16, 34, -2.2),
                Enum.Material.Glass, signal, 0.18)
            piece(side < 0 and "WestServiceBrace" or "EastServiceBrace",
                "Part", Vector3.new(0.8, 24, 1.3),
                CFrame.new(side * 8, 17, 0)
                    * CFrame.Angles(0, 0, side * math.rad(28)),
                Enum.Material.Metal, alloy)
        end
        piece("ObservatoryBridge", "Part", Vector3.new(35, 1.8, 5.5),
            CFrame.new(0, 24, 0), Enum.Material.Metal, hull)
        piece("ObservatoryCabin", "Part", Vector3.new(8, 8, 7),
            CFrame.new(0, 27, 0), Enum.Material.Metal, alloy)
        piece("ObservatoryGlass", "Part", Vector3.new(6.2, 3.1, 0.3),
            CFrame.new(0, 29, -3.6),
            Enum.Material.Glass, signal, 0.25)
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

-- Low-cost original skyline silhouettes beyond the playable boundary.
-- Two offset industrial structures per side add perspective and scale.
-- All geometry is noninteractive and cannot trap players or NPCs.
local function addExteriorSilhouettePairs(decor, config, variant, theme)
    local halfX = variant.BaseSize.X * 0.5
    local halfZ = variant.BaseSize.Z * 0.5
    local positions = {
        {name = "North", x = -38, z = -halfZ - 42, yaw = 0},
        {name = "East", x = halfX + 42, z = -38, yaw = math.pi * 0.5},
        {name = "South", x = 38, z = halfZ + 42, yaw = math.pi},
        {name = "West", x = -halfX - 42, z = 38, yaw = -math.pi * 0.5},
    }
    local floorTop = variant.BaseSize.Y * 0.5
    local shell = theme.Structure:Lerp(theme.Surface, 0.18)
    local trim = theme.Detail:Lerp(theme.Structure, 0.45)
    local signal = theme.Accent:Lerp(theme.Structure, 0.58)

    for index, position in ipairs(positions) do
        local model = Instance.new("Model")
        model.Name = "ExteriorSilhouette" .. position.name
        model:SetAttribute("ChaosDistantScenery", true)
        model.Parent = decor
        local height = 18 + index * 3
        local frame = CFrame.new(config.ArenaCenter
            + Vector3.new(position.x, floorTop, position.z))
            * CFrame.Angles(0, position.yaw, 0)

        local function segment(name, size, offset, material, color)
            local p = Instance.new("Part")
            p.Name = name
            p.Size = size
            p.CFrame = frame * CFrame.new(offset)
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = material
            p.Color = color
            p.Parent = model
            return p
        end

        segment("ReactorShell", Vector3.new(9, height, 8),
            Vector3.new(0, height * 0.5, 0), Enum.Material.Metal, shell)
        segment("RoofCanopy", Vector3.new(12, 1.2, 10),
            Vector3.new(0, height + 0.6, 0), Enum.Material.Metal, trim)
        for side = -1, 1, 2 do
            segment(side < 0 and "LeftRib" or "RightRib",
                Vector3.new(1.2, height * 0.75, 1.4),
                Vector3.new(side * 5, height * 0.42, -2.8),
                Enum.Material.Metal, trim)
        end
        segment("SignalBand", Vector3.new(6, 0.35, 0.18),
            Vector3.new(0, height * 0.68, -4.08),
            Enum.Material.Neon, signal)
        segment("Antenna", Vector3.new(0.55, 6, 0.55),
            Vector3.new(0, height + 3.5, 0),
            Enum.Material.Metal, trim)
    end
end

local function addArenaFoundation(decor, config, variant, theme, sweptProfile, beaconShaft)
    local baseSize = variant.BaseSize
    local center = config.ArenaCenter

    -- Four rails meet at their centerlines and leave the keel visible.
    local undercarriage = Instance.new("Model")
    undercarriage.Name = "ArenaUndercarriage"
    undercarriage:SetAttribute("CosmeticOnly", true)
    undercarriage.Parent = decor
    local insetX = math.max(4, baseSize.X * 0.5 - 3.0)
    local insetZ = math.max(4, baseSize.Z * 0.5 - 3.0)
    for side = -1, 1, 2 do
        local northSouth = fitDecorMesh(
            sweptProfile, "FoundryX" .. tostring(side),
            CFrame.new(center + Vector3.new(0, -2.25, side * insetZ)),
            Vector3.new(2 * insetX, 2.2, 2.8),
            theme.Structure, VisualTheme.Materials.Structure)
        local eastWest = fitDecorMesh(
            sweptProfile, "FoundryZ" .. tostring(side),
            CFrame.new(center + Vector3.new(side * insetX, -2.25, 0)),
            Vector3.new(2.8, 2.2, 2 * insetZ),
            theme.Structure, VisualTheme.Materials.Structure)
        for _, rail in ipairs({northSouth, eastWest}) do
            rail.Transparency = 0.06
            rail:SetAttribute("PremiumArchitecturalSurface", true)
            rail.Parent = undercarriage
        end
    end

    local deckInset = decorPart(
        decor,
        "ArenaDeckInset",
        Vector3.new(math.max(8, baseSize.X - 7), 0.14, math.max(8, baseSize.Z - 7)),
        center + Vector3.new(0, 1.08, 0),
        theme.Surface:Lerp(theme.Detail, 0.43),
        theme.PanelMaterial or VisualTheme.Materials.Panel
    )
    -- A broad neutral midtone keeps the REAL floor readable on mobile;
    -- subdued route paint and red/orange disaster telegraphs stay distinct.
    deckInset.Transparency = 0.03
    -- Existing Harbor timber remains on smaller route panels. The enormous
    -- working port deck uses actual salt-worn steel, not a default wooden
    -- slab pretending to be a seaport floor.
    if variant.Id == "Harbor" then
        deckInset.Material = Enum.Material.CorrodedMetal
    end
    deckInset:SetAttribute("PremiumArchitecturalSurface", true)

    local laneLengthX = math.max(18, baseSize.X - 18)
    local laneLengthZ = math.max(18, baseSize.Z - 18)
    local laneY = baseSize.Y * 0.5 + 0.17
    local laneX = Vector3.new(laneLengthX, 0.06, 0.36)
    local laneZ = Vector3.new(0.36, 0.06, laneLengthZ)
    local lanes = {
        {name = "DeckLineNorth", size = laneX, pos = Vector3.new(0, laneY, -12), color = theme.Accent},
        {name = "DeckLineSouth", size = laneX, pos = Vector3.new(0, laneY, 12), color = theme.Secondary},
        {name = "DeckLineWest", size = laneZ, pos = Vector3.new(-12, laneY, 0), color = theme.Secondary},
        {name = "DeckLineEast", size = laneZ, pos = Vector3.new(12, laneY, 0), color = theme.Accent},
    }

    for _, def in ipairs(lanes) do
        local line = fitDecorMesh(
            sweptProfile,
            def.name,
            CFrame.new(center + def.pos),
            def.size,
            def.color,
            VisualTheme.Materials.Glow
        )
        -- The shallow section and muted glow keep warning contours readable.
        line.Transparency = 0.58
        line.Parent = decor
    end

    -- Place the static exterior accents along the floor's four sides.
    local outerX = baseSize.X * 0.5 + 4.5
    local outerZ = baseSize.Z * 0.5 + 4.5
    local haloY = -baseSize.Y * 0.5 - 0.15
    local segmentsPerSide = 4
    local haloSize = Vector3.new(5.5, 0.18, 0.42)
    for side, edge in ipairs({
        {offset = Vector3.new(0, haloY, -outerZ), span = baseSize.X, yaw = 0},
        {offset = Vector3.new(outerX, haloY, 0), span = baseSize.Z, yaw = -math.pi * 0.5},
        {offset = Vector3.new(0, haloY, outerZ), span = baseSize.X, yaw = math.pi},
        {offset = Vector3.new(-outerX, haloY, 0), span = baseSize.Z, yaw = math.pi * 0.5},
    }) do
        local frame = CFrame.new(center + edge.offset) * CFrame.Angles(0, edge.yaw, 0)
        for slot = 1, segmentsPerSide do
            local index = (side - 1) * segmentsPerSide + slot
            local along = edge.span * ((slot - 0.5) / segmentsPerSide - 0.5)
            local color = index % 2 == 0 and theme.Accent or theme.Secondary
            local halo = fitDecorMesh(sweptProfile, "OuterHalo" .. index,
                frame * CFrame.new(along, 0, 0), haloSize, color, VisualTheme.Materials.Glow)
            halo.Transparency = 0.34
            halo.Parent = decor
        end
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

        -- Seat the slit in front of the inward-facing shell, above the foot.
        local face = CFrame.lookAt(column.Position, center + Vector3.new(0, offset.Y, 0))
        local slit = fitDecorMesh(
            beaconShaft,
            "FrameColumnGlow" .. i,
            face * CFrame.new(0, 0.4, -2.08),
            Vector3.new(0.42, 4.8, 0.28),
            (i % 2 == 0) and theme.Secondary or theme.Accent,
            VisualTheme.Materials.Glow
        )
        slit.Transparency = 0.20
        slit.Parent = decor
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
    elseif variant.Id == "Harbor" then
        -- Two tiers of flush quay markings break up the large industrial
        -- ground without adding false cover, fake water or collider parts.
        -- Blue/seafoam is deliberate; the hazard palette owns amber/red.
        local lanes = {
            {x = -89, z = -23, alongX = false},
            {x = -89, z = 23, alongX = false},
            {x = 89, z = -23, alongX = false},
            {x = 89, z = 23, alongX = false},
            {x = -23, z = -89, alongX = true},
            {x = 23, z = -89, alongX = true},
            {x = -23, z = 89, alongX = true},
            {x = 23, z = 89, alongX = true},
        }
        for index, lane in ipairs(lanes) do
            local line = decorPart(
                decor, "HarborQuayInlay" .. index,
                lane.alongX and Vector3.new(52, 0.055, 0.45)
                    or Vector3.new(0.45, 0.055, 52),
                center + Vector3.new(lane.x, 1.20, lane.z),
                index % 2 == 0 and theme.Accent or theme.Secondary,
                theme.PanelMaterial
            )
            line.Transparency = 0.38
            line.CastShadow = false
        end
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

local function towersForgedBridgeSource()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedTowersSignatureBridgeTemplates")
    if not holder or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild("ForgedBridge")
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalTowersSignatureBridge3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= 126298311664881 then return nil end
    return model
end

local function accessChassisSource()
    local templates = ReplicatedStorage:FindFirstChild("ApprovedRemainingStructureTemplates")
    if not templates or templates:GetAttribute("OwnerVerified") ~= true then return nil end
    local chassis = templates:FindFirstChild("AccessChassis")
    if not chassis or not chassis:IsA("Model")
        or chassis:GetAttribute("OwnerVerified") ~= true
        or chassis:GetAttribute("CosmeticOnly") ~= true
        or chassis:GetAttribute("P4OriginalRemainingStructure3D") ~= true
        or chassis:GetAttribute("Original3DAssetId") ~= 106401955318567 then return nil end
    return chassis
end

local function approvedMeshRegion(model, name)
    local mesh = model and model:FindFirstChild(name)
    return mesh and mesh:IsA("MeshPart") and mesh.Archivable and mesh or nil
end

local function wayfinderBaseSource()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedPerimeterArmorTemplates")
    if not holder or not holder:IsA("Folder") or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local model = holder:FindFirstChild("Cap")
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalPerimeterArmor3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= 88962643359267 then return nil end
    return approvedMeshRegion(model, "WayfinderBase")
end

local function beaconShaftSource(variant)
    local id = PremiumLargeStructureAssets.approvedId(variant)
    local holder = ReplicatedStorage:FindFirstChild("ApprovedLargeStructureTemplates")
    if not id or not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild(variant)
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalLargeStructure3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= id then return nil end
    return approvedMeshRegion(model, "BeaconShaft")
end

local BRANCH_CHEVRON = {
    size = Vector3.new(0.25, 0.065, 2.0), spread = 0.48, angle = math.rad(34), alpha = 0.44,
}
local FORK_CHEVRON = {
    size = Vector3.new(0.33, 0.065, 2.4), spread = 0.55, angle = math.rad(36), alpha = 0.32,
}

local PERIMETER_STEP_CHEVRON = {
    size = Vector3.new(0.26, 0.07, 1.80), spread = 0.42, angle = math.rad(35), alpha = 0.43,
}
local PROMENADE_CHEVRON = {
    size = Vector3.new(0.30, 0.08, 2.55), spread = 0.62, angle = math.rad(35), alpha = 0.34,
}
local SPINE_TURN_CHEVRON = {
    size = Vector3.new(0.35, 0.08, 2.55), spread = 0.62, angle = math.rad(35), alpha = 0.24,
}

local function addRouteChevron(decor, name, deck, index, forward, color, style, profile, offset)
    -- Clear the landing panel and keep the marker tied to the physical deck.
    local point = deck.Position + Vector3.new(0, deck.Size.Y * 0.5 + 0.155, 0)
        + (offset or Vector3.zero)
    local look = CFrame.lookAt(point, point + forward)
    for side = -1, 1, 2 do
        local arrowName = name .. "_" .. tostring(side)
        local pose = look * CFrame.new(side * style.spread, 0, 0)
            * CFrame.Angles(0, side * style.angle, 0)
        local mark = fitDecorMesh(profile, arrowName, pose, style.size, color, VisualTheme.Materials.Glow)
        mark.Transparency = style.alpha
        mark:SetAttribute("PerimeterPlatformIndex", index)
        mark:SetAttribute("ChaosWayfinding", true)
        mark.Parent = decor
    end
end

local function addSpineExitChevrons(decor, spine, promenade, color, profile)
    local along = spine.CFrame.LookVector
    local approachCenter = (promenade.Position - spine.Position):Dot(along)
    local approachHalf = (math.abs(promenade.CFrame.RightVector:Dot(along)) * promenade.Size.X
        + math.abs(promenade.CFrame.LookVector:Dot(along)) * promenade.Size.Z) * 0.5
    local halfSpan = spine.Size.Z * 0.5
    local near = math.max(-halfSpan, approachCenter - approachHalf)
    local far = math.min(halfSpan, approachCenter + approachHalf)
    local style = SPINE_TURN_CHEVRON
    local sine, cosine = math.sin(style.angle), math.cos(style.angle)
    local clearance = style.spread + (sine * style.size.Z + cosine * style.size.X) * 0.5
    -- Keep both arrows inside the shared approach, even if there is only
    -- a sliver of real overlap at an otherwise valid intersection.
    if far - near < clearance * 2 then return end

    local center = along * ((near + far) * 0.5)
    local across = spine.CFrame.RightVector
    local spacing = spine.Size.X * 0.25
    local halfWidth = spacing + (cosine * style.size.Z + sine * style.size.X) * 0.5
    if halfWidth > spine.Size.X * 0.5 then return end
    local relativeCenter = spine.Position + center - promenade.Position
    for _, axis in ipairs({promenade.CFrame.RightVector, promenade.CFrame.LookVector}) do
        local halfDeck = (math.abs(axis:Dot(promenade.CFrame.RightVector)) * promenade.Size.X
            + math.abs(axis:Dot(promenade.CFrame.LookVector)) * promenade.Size.Z) * 0.5
        local reach = math.abs(axis:Dot(relativeCenter)) + math.abs(axis:Dot(across)) * halfWidth
            + math.abs(axis:Dot(along)) * clearance
        if reach > halfDeck then return end
    end

    local index = tonumber(spine.Name:match("^Platform(%d+)$"))
    local prefix = "SkySpine" .. index .. "_PromenadeChevron"
    for direction = -1, 1, 2 do
        local forward = across * direction
        local offset = center + forward * spacing
        addRouteChevron(decor, prefix .. direction, spine, index, forward, color, style, profile, offset)
    end
end

local function harborLandingAlongX(definition)
    if definition.HarborSkywayLane then return true end
    if definition.HarborSpokeRoute then return definition.HarborSpokeRoute % 2 == 0 end
    if definition.HarborRoute then
        -- Each freight switchback alternates X and Z after the first landing.
        return definition.HarborStep % 2 == 1
    end
    return nil
end

local function addPlatformGlow(decor, platform, index, theme, routeTier, edgeBand, edgeOverhang, routeAlongX)
    local name = "PlatformGlow" .. index
    local color = (index % 2 == 0) and theme.Secondary or theme.Accent
    local transparency = 0.64
    if routeTier then
        color = routeTier == 1 and theme.Accent
            or (routeTier == 2 and theme.Accent:Lerp(theme.Secondary, 0.30)
                or (routeTier == 3 and theme.Secondary
                    or theme.Secondary:Lerp(theme.Accent, 0.55)))
        transparency = 0.72 - routeTier * 0.04
    end

    local size = platform.Size
    local alongX = if routeAlongX ~= nil then routeAlongX else size.X > size.Z
    local atRim = platform:GetAttribute("BranchStep") ~= nil
        or platform:GetAttribute("CrosslinkRoute") ~= nil
    -- The grounded riser reaches the arena floor. Place the band below
    -- the sculpted fascia near the landing surface, rather than at its foot.
    local height = if atRim then size.Y * 0.5 - 1.02 else -size.Y * 0.5 - 0.47
    local glow = edgeBand and RouteSignalGeometry.fit(edgeBand,
        platform.CFrame * CFrame.new(0, height, 0),
        Vector3.new(
            size.X + (alongX and 0.28 or edgeOverhang),
            0.14,
            size.Z + (alongX and edgeOverhang or 0.28)
        ), nil, alongX)
    if glow then
        -- The two bands clear the underside of the frame and share one mesh.
        glow.Name = name
        glow.Material = VisualTheme.Materials.Glow
        glow.Color = color
        glow.Transparency = transparency
        glow.Parent = decor
    else
        local glow = decorPart(decor, name, Vector3.new(size.X + 0.28, 0.12, size.Z + 0.28),
            platform.Position - Vector3.new(0, size.Y * 0.5 + 0.13, 0),
            color, VisualTheme.Materials.Glow)
        glow.Transparency = transparency
    end
end

local function addPlatformFinish(decor, platform, index, theme, underdeckSignal, lattice,
    forgedBevel, harborAlongX)
    local topPanel = decorPart(
        decor,
        "PlatformPanel" .. index,
        Vector3.new(
            math.max(1, platform.Size.X - 0.8),
            0.10,
            math.max(1, platform.Size.Z - 0.8)
        ),
        platform.Position + Vector3.new(0, (platform.Size.Y * 0.5) + 0.055, 0),
        theme.Surface:Lerp(theme.Detail, 0.48),
        theme.PanelMaterial or VisualTheme.Materials.Panel
    )
    -- Neutral midtone landings remain visible without light emitters;
    -- progression changes tint, while hazards still own bright warning hues.
    -- Quiet, durable walking inset: hazards keep visual priority and the
    -- rim now reads as a separate machined structural layer.
    topPanel.Transparency = 0.07
    -- Creator-owned original PBR, selected by the existing camera budget.
    -- Never alter the collidable platform Material used by disasters.
    if topPanel.Material ~= Enum.Material.WoodPlanks then
        topPanel:SetAttribute("PremiumArchitecturalSurface", true)
    end
    local routeTier = tonumber(platform:GetAttribute("RouteTier"))
    local parkourGrade = tonumber(platform:GetAttribute("ParkourGrade"))
    if parkourGrade then
        -- Make the ACTUAL collision landing area visibly readable.
        -- Recolor the existing inset only: no extra geometry, lights,
        -- expensive material or warning-color overlap on low-end phones.
        topPanel.Color = theme.Surface:Lerp(
            theme.Detail, 0.44 + math.clamp(parkourGrade, 1, 4) * 0.055
        )
    elseif routeTier then
        topPanel.Color = theme.Surface:Lerp(
            theme.Detail, 0.45 + (math.clamp(routeTier, 1, 4) - 1) * 0.05
        )
    end

    -- Encode ACTUAL playable sky routes into the landing surface rather
    -- than more floating signs or neon floor strips. Two promenade lanes
    -- use different muted tints; the transverse Sky Spine has a coherent
    -- third finish. All stay part-owned, hazard-neutral and zero-cost in
    -- geometry or additional lights.
    local promenadeLane = tonumber(platform:GetAttribute("PromenadeLane"))
    local skySpineStep = tonumber(platform:GetAttribute("SkySpineStep"))
    local perimeterStep = tonumber(platform:GetAttribute("PerimeterStep"))
    if promenadeLane == 1 or promenadeLane == 2 then
        topPanel.Color = theme.Surface:Lerp(theme.Detail, 0.55)
            :Lerp(promenadeLane == 1 and theme.Accent or theme.Secondary, 0.14)
    elseif skySpineStep then
        topPanel.Color = theme.Surface:Lerp(theme.Detail, 0.58)
            :Lerp(theme.Secondary, 0.10)
    elseif perimeterStep then
        topPanel.Color = topPanel.Color:Lerp(
            perimeterStep == 8 and theme.Accent or theme.Secondary,
            perimeterStep == 8 and 0.13 or 0.06
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
    local visibleGrade = parkourGrade or routeTier
    local edgeColor = theme.Structure:Lerp(
        visibleGrade and theme.Secondary or theme.Detail,
        visibleGrade and (0.14 + math.clamp(visibleGrade, 1, 4) * 0.04)
            or 0.40
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
    local facings = {0, math.pi, math.pi * 0.5, -math.pi * 0.5}
    for edgeIndex, spec in ipairs(edgeSpecs) do
        local size = spec[1]
        if edgeIndex > 2 then size = Vector3.new(size.Z, size.Y, size.X) end
        local where = Vector3.new(
            platform.Position.X, 0, platform.Position.Z) + spec[2]
        local yaw = facings[edgeIndex]
        local bevel
        if forgedBevel then
            -- Keep the footprint of the native wedge. The swept face
            -- extends downwards to show its facets below the deck lip.
            local mesh = forgedBevel:Clone()
            local sourceAlongX = mesh.Size.X > mesh.Size.Z
            mesh.Size = sourceAlongX and Vector3.new(size.X, .44, size.Z)
                or Vector3.new(size.Z, .44, size.X)
            mesh.CFrame = CFrame.new(where - Vector3.new(0, .08, 0))
                * CFrame.Angles(0, yaw + (sourceAlongX and 0 or math.pi * .5), 0)
            bevel = mesh
        else
            local wedge = Instance.new("WedgePart")
            wedge.Size = size
            wedge.CFrame = CFrame.new(where) * CFrame.Angles(0, yaw, 0)
            wedge.TopSurface = Enum.SurfaceType.Smooth
            wedge.BottomSurface = Enum.SurfaceType.Smooth
            bevel = wedge
        end
        bevel.Name = "PlatformBevel" .. index .. "_" .. edgeIndex
        bevel.Color = edgeColor
        bevel.Material = theme.StructureMaterial or edgeMaterial
        bevel.Transparency = 0.08
        bevel.Anchored = true
        bevel.CanCollide = false
        bevel.CanTouch = false
        bevel.CanQuery = false
        bevel.CastShadow = false
        bevel:SetAttribute("OriginalStructuralBevel", true)
        bevel.Parent = decor
    end

    local frameName = "PlatformUnderFrame" .. index
    local frameColor = theme.Structure:Lerp(VisualTheme.World.Deep, 0.30)
    local size = platform.Size
    local frameSize = Vector3.new(size.X + 0.5, 0.42, size.Z + 0.5)
    local framePose = platform.CFrame * CFrame.new(0, -size.Y * 0.5 - 0.18, 0)
    local underFrame = lattice and lattice:Clone()
    if underFrame then
        if harborAlongX == nil then
            local meshAlongX = underFrame.Size.X > underFrame.Size.Z
            local deckAlongX = size.X > size.Z
            local length = math.max(size.X, size.Z) * 0.98
            local width = math.min(size.X, size.Z) * 0.93
            frameSize = meshAlongX and Vector3.new(length, 0.56, width)
                or Vector3.new(width, 0.56, length)
            framePose = platform.CFrame * CFrame.new(0, -size.Y * 0.5 - 0.27, 0)
                * CFrame.Angles(0, meshAlongX ~= deckAlongX and math.pi * 0.5 or 0, 0)
        end
        -- Harbor retains the original frame envelope so a fully loaded
        -- sculpted caisson can claim the same structural fallback.
        underFrame.Size = frameSize
        underFrame.CFrame = framePose
    else
        underFrame = decorPart(nil, frameName, frameSize, framePose.Position,
            frameColor, VisualTheme.Materials.Structure)
    end
    underFrame.Name = frameName
    underFrame.Color = frameColor
    underFrame.Material = VisualTheme.Materials.Structure
    underFrame.Transparency = 0.04
    underFrame:SetAttribute("PremiumArchitecturalSurface", true)
    underFrame.Parent = decor

    local coreName = "PlatformCoreGlow" .. index
    local coreColor = (index % 2 == 0) and theme.Secondary or theme.Accent
    local coreAlpha = routeTier and (0.72 - math.clamp(routeTier, 1, 4) * 0.04) or 0.56
    local skybridge = platform:GetAttribute("ChaosSkybridge") == true
    local signalTemplate = (promenadeLane or skySpineStep or skybridge or harborAlongX ~= nil)
        and underdeckSignal
    local core
    if signalTemplate then
        local alongX = if harborAlongX ~= nil then harborAlongX else size.X > size.Z
        local length = (alongX and size.X or size.Z) * 0.62
        -- A narrow Tower Run deck needs more relative width to clear the ribs.
        local width = (alongX and size.Z or size.X) * (skybridge and 0.34 or 0.22)
        local signalSize = alongX and Vector3.new(length, 0.30, width)
            or Vector3.new(width, 0.30, length)
        core = RouteSignalGeometry.fit(signalTemplate,
            platform.CFrame * CFrame.new(0, -size.Y * 0.5 - 0.52, 0), signalSize, nil, alongX)
    end
    if core then
        core.Name = coreName
        core.Color = coreColor
        core.Material = VisualTheme.Materials.Glow
        core.Transparency = coreAlpha
        core.Parent = decor
    else
        local fallback = decorPart(decor, coreName,
            Vector3.new(math.max(0.8, size.X * 0.32), 0.12, math.max(0.8, size.Z * 0.32)),
            platform.Position - Vector3.new(0, size.Y * 0.5 + 0.42, 0),
            coreColor, VisualTheme.Materials.Glow)
        fallback.Transparency = coreAlpha
    end

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
    decor:SetAttribute("PremiumSurfaceSkinSource", true)
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
    floorInset:SetAttribute("PremiumArchitecturalSurface", true)

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

    -- Retain the existing collidable lobby entrance and pylons, but hide
    -- their simplistic silhouettes behind authored multi-layer 3D casing.
    StructureRetrofit.buildLobby(decor, config.LobbyCenter)

    floor:SetAttribute("VisualVersion", 2)
    centerPlatform:SetAttribute("SafeHub", true)
    leftColumn:SetAttribute("ArenaGate", true)
    rightColumn:SetAttribute("ArenaGate", true)
    archTop:SetAttribute("ArenaGate", true)
end

function MapBuilder.buildArena(config, variantId, arenaVariants, themeProvider)
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
    -- CI may mount an older published Shared package alongside the newer
    -- source being tested. An explicit, server-only provider lets the
    -- engine regression exercise the exact candidate visual palette.
    -- Production callers omit it and use the replicated Material palette.
    local theme = (themeProvider or VisualTheme).arena(variant.Id)
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

    local forgedBridge = towersForgedBridgeSource()
    local sweptProfile = approvedMeshRegion(forgedBridge, "SweptCrossbeam")
    local edgeBand = approvedMeshRegion(forgedBridge, "SculptedEdgeBand")
    local spawnGlowSize = Vector3.new(5.2, 0.12, 5.2)
    -- Clear the visible floor finish while keeping the gameplay spawn in place.
    local guideY = base.Position.Y + ArenaPresentation.deckArtOffset(base, spawnGlowSize.Y) + 0.025
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
        local guideFrame = s.CFrame + Vector3.new(0, guideY - spawnPosition.Y, 0)
        for side = -1, 1, 2 do
            -- Each arm's inner tip points along the spawn's forward axis.
            local pose = guideFrame * CFrame.new(side * 0.78, 0, -3)
                * CFrame.Angles(0, math.rad(-side * 34), 0)
            local guide = fitDecorMesh(
                sweptProfile,
                "EntryChevron" .. i .. "_" .. tostring(side),
                pose,
                Vector3.new(2.6, 0.08, 0.24),
                guideColor,
                VisualTheme.Materials.Glow
            )
            guide.Transparency = 0.22
            guide:SetAttribute("ChaosWayfinding", true)
            guide.Parent = entryGuides
        end

        local glow = fitDecorMesh(
            edgeBand,
            "SpawnGlow" .. i,
            guideFrame,
            spawnGlowSize,
            guideColor,
            VisualTheme.Materials.Glow
        )
        glow.Transparency = 0.16
        glow.Parent = arena
    end

    local platforms = Instance.new("Folder")
    platforms.Name = "Platforms"
    platforms.Parent = arena

    local decor = Instance.new("Folder")
    decor.Name = "Decor"
    decor:SetAttribute("PremiumSurfaceSkinSource", true)
    decor.Parent = arena

    local chassis = accessChassisSource()
    local underdeckLattice = approvedMeshRegion(chassis, "UnderdeckLattice")
    local wayfinderBase = wayfinderBaseSource()
    local beaconShaft = beaconShaftSource(variant.Id)
    addArenaFoundation(decor, config, variant, theme, sweptProfile, beaconShaft)
    -- Original modular top deck: 6 x 6 textured industrial panels,
    -- recessed service grooves and volumetric undercarriage fins.
    -- All floor art follows the shrinking REAL base and is noncolliding.
    ArenaGroundArchitecture.build(decor, base, variant.Id, theme, underdeckLattice, sweptProfile, wayfinderBase)
    addPerimeterStations(decor, config, variant, theme)
    addDistantSkyline(decor, config, variant, theme)
    addArenaSignatureMegastructure(decor, config, variant, theme)
    -- One distinctive real 3D skyline per arena. No external asset ID is
    -- required; this is the always-available mobile-friendly model layer.
    HeroArchitecture.build(decor, arena:FindFirstChild("Base"), variant.Id, theme)
    -- Faceted original 3D shells, machined collars, diagonal load spars
    -- and cantilevers on the four EXISTING foundation towers. No physics.
    ArchitecturalCladding.build(decor, base, variant.Id, theme, wayfinderBase, sweptProfile)
    if variant.Id == "Harbor" then
        -- Exterior harbor cranes distinguish the new cargo port without
        -- extra colliders, sound loops or cameras tracking scenic models.
        HarborScenery.build(decor, base, theme)
    end
    -- Twelve 3D models occupy the now-playable outer districts. They are
    -- cosmetic and LOD managed, not new physical/hazard blocking geometry.
    ArenaDistrictArchitecture.build(decor, base, variant.Id, theme)
    addSouthHorizonMonument(decor, config, variant, theme)
    addExteriorCornerRidges(decor, config, variant, theme)
    addExteriorSilhouettePairs(decor, config, variant, theme)
    addVariantIdentity(decor, config, variant, theme)
    addVariantLandmarks(decor, config, variant, theme)
    -- Faceted exterior machinery over the EXISTING simple skyline markers.
    -- Static beyond the shrinking arena edge, fully noncolliding/LOD-owned.
    StructureRetrofit.buildArena(decor, base, variant.Id, theme)
    addVariantFloorLanguage(decor, config, variant, theme)
    addArenaHologram(decor, config, variant, theme)

    local halfX = variant.BaseSize.X * 0.5
    local halfZ = variant.BaseSize.Z * 0.5
    local edgeThickness = 0.35
    local edgeHeight = 0.45
    local edgeY = base.Size.Y * 0.5 + 0.25
    local edgeColor = theme.Accent
    local edgeSizeX = Vector3.new(base.Size.X, edgeHeight, edgeThickness)
    local edgeSizeZ = Vector3.new(edgeThickness, edgeHeight, base.Size.Z)
    -- The swept crossbeam is continuous end to end, including the joins at the corners.
    for _, edge in ipairs({
        {name = "EdgeNorth", size = edgeSizeX, offset = Vector3.new(0, edgeY, -halfZ + 0.4)},
        {name = "EdgeSouth", size = edgeSizeX, offset = Vector3.new(0, edgeY, halfZ - 0.4)},
        {name = "EdgeWest", size = edgeSizeZ, offset = Vector3.new(-halfX + 0.4, edgeY, 0)},
        {name = "EdgeEast", size = edgeSizeZ, offset = Vector3.new(halfX - 0.4, edgeY, 0)},
    }) do
        local border = fitDecorMesh(sweptProfile, edge.name, base.CFrame * CFrame.new(edge.offset),
            edge.size, edgeColor, Enum.Material.Neon)
        border.Transparency = 0
        border.Parent = decor
    end

    -- The client uses the center of this part for the orbit and particles.
    local beacon = fitDecorMesh(
        beaconShaft,
        "CenterBeacon",
        base.CFrame * CFrame.new(0, 7, 0),
        Vector3.new(1.4, 14, 1.4),
        edgeColor,
        Enum.Material.Neon
    )
    beacon.Transparency = 0.35

    local light = Instance.new("PointLight")
    light.Name = "ArenaGlow"
    light.Color = edgeColor
    light.Brightness = 1.2
    light.Range = 28
    light.Shadows = false
    light.Parent = beacon
    beacon.Parent = decor

    -- PerimeterRoutes are appended AFTER every original platform ID.
    -- Keeping the combined parts under Platforms lets all server-owned
    -- disaster and AI systems treat outer routes as real gameplay geometry.
    local platformDefinitions = table.clone(variant.Platforms)
    local underdeckSignal = approvedMeshRegion(chassis, "UnderdeckSignal")
    for _, definition in ipairs(variant.PerimeterPlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end
    -- Keep all original skybridge and perimeter indices unchanged.
    for _, definition in ipairs(variant.BranchPlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end
    -- Append only: preserve every existing owner/index and keep bridges
    -- fully server-authoritative for disasters, AI and collectibles.
    for _, definition in ipairs(variant.CrosslinkPlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end
    -- Genuine Harbor top-deck links append LAST; no original platform
    -- indices or existing disaster/collectible anchors are renumbered.
    for _, definition in ipairs(variant.SkywayPlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end
    -- Harbor cardinal dry-dock outposts append after all 94 authored
    -- historical deck identities. Their collision belongs to the same
    -- authoritative platform folder as every hazard, AI and shard route.
    for _, definition in ipairs(variant.SpokePlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end
    -- Two large, physically traversable air corridors connect the far
    -- north/south lookouts of every arena. Always append AFTER Harbor's
    -- dock spurs: no existing platform ID, hazard owner, or bot target
    -- changes. Exactly 16 collision decks, no floor-level collision wall.
    local lookoutEntries = {}
    for _, definition in ipairs(variant.PromenadePlatforms or {}) do
        table.insert(platformDefinitions, definition)
        local leftLookout = (definition.PromenadeLane - 1) * 2 + 1
        if definition.PromenadeStep == 1 then
            lookoutEntries[leftLookout] = definition.offset
        elseif definition.PromenadeStep == 8 then
            lookoutEntries[leftLookout + 1] = definition.offset
        end
    end
    -- The new REAL transverse Sky Spine is appended after both historical
    -- promenade lanes; no legacy platform, bridge or AI route ID changes.
    for _, definition in ipairs(variant.SkySpinePlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end

    local promenadeJunctions = {}
    local spineEndpoints = {}
    local promenadeTone = theme.Accent:Lerp(theme.Detail, 0.34)
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
        -- A complete climb-to-sky backbone must never be split by random
        -- platform collapse. From the floor: perimeter steps 1..5,
        -- four branch ascents and all eight giant crossing decks. Other
        -- routes remain eligible, so the disaster still has real stakes.
        if definition.PermanentRoute == true then
            platform:SetAttribute("ChaosPermanentRoute", true)
        end
        local routeTier = tonumber(definition.RouteTier)
        if routeTier and routeTier >= 1 and routeTier <= 4 then
            platform:SetAttribute("RouteTier", routeTier)
        end
        local parkourGrade = tonumber(definition.ParkourGrade)
        if parkourGrade and parkourGrade >= 1 and parkourGrade <= 4 then
            -- Server-owned difficulty classification follows the physical
            -- landing footprint; never transmitted as a client claim.
            platform:SetAttribute("ParkourGrade", parkourGrade)
        end
        if definition.HarborRoute then
            -- The seven-step cargo-pier switchbacks are real physical
            -- routes. Preserve both the road and step identity so the
            -- novice coach never points across inaccessible cargo stacks.
            platform:SetAttribute("HarborRoute", definition.HarborRoute)
            platform:SetAttribute("HarborStep", definition.HarborStep)
            platform.Color = theme.Structure:Lerp(theme.Detail, 0.43)
            -- A real timber walking deck, rather than just a visual
            -- plank overlay above a metal collision floor. Roblox native
            -- steps and our local landing accent now agree on the
            -- contacted physical material; storm hazards still own it.
            platform.Material = Enum.Material.WoodPlanks
        end
        if definition.HarborSkywayLane then
            -- Two genuinely walkable elevated freight gantries connect
            -- the Harbor's former dead-end cargo switchbacks. These are
            -- server-owned collision decks, never a cosmetic fake bridge.
            platform:SetAttribute("HarborSkywayLane", definition.HarborSkywayLane)
            platform:SetAttribute("HarborSkywayStep", definition.HarborSkywayStep)
            platform.Color = theme.Structure:Lerp(theme.Secondary, 0.42)
            platform.Material = Enum.Material.CorrodedMetal
        end
        if definition.HarborSpokeRoute then
            -- Real four-step cardinal service piers: accessible from the
            -- ground; clear standard 3-stud vertical and 1.25..2.25-stud
            -- horizontal jumps. Reuse the existing dynamic platform finish
            -- and hazard ownership, no extra client model/animation loop.
            platform:SetAttribute("HarborSpokeRoute", definition.HarborSpokeRoute)
            platform:SetAttribute("HarborSpokeStep", definition.HarborSpokeStep)
            platform.Color = theme.Structure:Lerp(
                definition.HarborSpokeStep <= 2 and theme.Detail
                    or theme.Secondary, 0.42
            )
            platform.Material = definition.HarborSpokeStep <= 2
                and Enum.Material.WoodPlanks or Enum.Material.CorrodedMetal
        end
        if definition.PromenadeLane then
            -- These are genuine elevated crossing platforms at the EXACT
            -- same top elevation as the two connected corner lookouts.
            -- Their physical collision and all platform finish follow
            -- Shrinking Arena; a separate permanent-route marker keeps
            -- Disappearing Platforms from making an inescapable midair gap.
            -- Do not set ChaosSkybridge: Tower's gated skybridge mechanics
            -- own only their original four bridges.
            platform:SetAttribute("PromenadeLane", definition.PromenadeLane)
            platform:SetAttribute("PromenadeStep", definition.PromenadeStep)
            platform.Color = theme.Structure:Lerp(theme.Detail, 0.52)
            platform.Material = theme.PanelMaterial
                or VisualTheme.Materials.Structure
        end
        if definition.SkySpineStep then
            -- Ten physical, permanently supported transverse crossing
            -- decks at the same sky altitude as both long promenades.
            platform:SetAttribute("SkySpineStep", definition.SkySpineStep)
            platform:SetAttribute("SkySpineInterchange", true)
            platform.Color = theme.Structure:Lerp(theme.Secondary, 0.45)
            platform.Material = theme.PanelMaterial
                or VisualTheme.Materials.Structure
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
            if definition.PerimeterStep == 1 then
                -- Only FOUR real, collidable entry decks expose this
                -- server-authored tag. StreamingEnabled may replicate
                -- each Part before its attributes: clients discover the
                -- real route through CollectionService instead of
                -- guessing indices or watching hundreds of platforms.
                CollectionService:AddTag(platform, "ChaosPerimeterEntry")
                -- The first accessible step is the moment to teach the
                -- objective without another full-screen mobile tutorial.
                -- Distance-limited, attached to the REAL physical route,
                -- automatically removed if a disaster removes that deck.
                local sign = Instance.new("BillboardGui")
                sign.Name = "SurvivalRouteBriefing"
                sign.Adornee = platform
                sign.Size = UDim2.fromOffset(200, 48)
                sign.StudsOffsetWorldSpace = Vector3.new(
                    0, platform.Size.Y * 0.5 + 4, 0
                )
                sign.MaxDistance = 55
                sign.AlwaysOnTop = false
                sign.Parent = platform
                local panel = Instance.new("TextLabel")
                panel.Name = "Objective"
                panel.Size = UDim2.fromScale(1, 1)
                panel.BackgroundColor3 = Color3.fromRGB(13, 23, 33)
                panel.BackgroundTransparency = 0.16
                panel.BorderSizePixel = 0
                panel.Font = Enum.Font.GothamBold
                panel.Text = "CLIMB  /  DODGE\nSURVIVE UNTIL 0"
                panel.TextColor3 = Color3.fromRGB(245, 250, 255)
                panel.TextScaled = true
                panel.TextWrapped = true
                panel.Parent = sign
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = panel
                local stroke = Instance.new("UIStroke")
                stroke.Color = theme.Accent
                stroke.Thickness = 1.5
                stroke.Parent = panel
                platform:SetAttribute("SurvivalRouteBriefing", true)
            end
        end

        if definition.BranchRoute then
            -- The corner spurs are real server-authoritative collision
            -- geometry, so every disaster/bot/item uses the same deck.
            platform:SetAttribute("BranchRoute", definition.BranchRoute)
            platform:SetAttribute("BranchStep", definition.BranchStep)
            platform:SetAttribute("BranchParentStep", definition.BranchParentStep)
            platform.Color = theme.Surface:Lerp(theme.Secondary, 0.38)
            platform.Material = theme.StructureMaterial
                or VisualTheme.Materials.Structure
            local forward = Vector3.new(0, 0, definition.offset.Z >= 0 and 1 or -1)
            local entry = definition.BranchStep == 4 and lookoutEntries[definition.BranchRoute]
            if entry then
                local towardEntry = (entry - definition.offset) * Vector3.new(1, 0, 1)
                if towardEntry.Magnitude > 0.01 then forward = towardEntry.Unit end
            end
            addRouteChevron(decor, "BranchStepArrow" .. definition.BranchRoute .. "_" .. definition.BranchStep,
                platform, i, forward, theme.Secondary, BRANCH_CHEVRON, sweptProfile)
        end

        if definition.CrosslinkRoute then
            -- Crossings are real grounded terrain, not cosmetic bridges.
            -- Distinct alloy helps an escaping player recognize the
            -- alternate route without adding lights, UI or moving Parts.
            platform:SetAttribute("CrosslinkRoute", definition.CrosslinkRoute)
            platform:SetAttribute("CrosslinkFromPerimeterStep",
                definition.CrosslinkFromPerimeterStep)
            platform:SetAttribute("CrosslinkToBranchStep",
                definition.CrosslinkToBranchStep)
            platform.Color = theme.Structure:Lerp(theme.Secondary, 0.32)
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
                local railOffset = (width * 0.5 - 0.28) * side
                local railFrame = platform.CFrame * CFrame.new(
                    alongX and 0 or railOffset, platform.Size.Y * 0.5 + 0.045,
                    alongX and railOffset or 0
                )
                local railName = "SkybridgeRail" .. i .. "_" .. tostring(side)
                local color = side < 0 and theme.Accent or theme.Secondary
                local railSize = alongX and Vector3.new(span, 0.08, 0.18)
                    or Vector3.new(0.18, 0.08, span)
                local rail = RouteSignalGeometry.fit(sweptProfile, railFrame, railSize)
                    or decorPart(nil, railName, railSize, railFrame.Position, color,
                        VisualTheme.Materials.Glow)
                rail.Name = railName
                rail.Material = VisualTheme.Materials.Glow
                rail.Color = color
                rail.Transparency = 0.16
                rail:SetAttribute("ChaosWayfinding", true)
                rail.Parent = decor
            end
            -- Three transverse ribs share the existing trim replacement,
            -- hazard visibility and contraction code through their names.
            for ribIndex = -1, 1 do
                local ribName = "SkybridgeRib" .. i .. "_" .. tostring(ribIndex)
                local distance = ribIndex * span * 0.27
                local ribFrame = platform.CFrame * CFrame.new(
                    alongX and distance or 0,
                    -platform.Size.Y * 0.5,
                    alongX and 0 or distance
                )
                if sweptProfile then
                    local rib = sweptProfile:Clone()
                    local sourceAlongX = rib.Size.X > rib.Size.Z
                    rib.Name = ribName
                    rib.Size = sourceAlongX and Vector3.new(width + 0.22, 0.62, 0.76)
                        or Vector3.new(0.76, 0.62, width + 0.22)
                    rib.CFrame = ribFrame * CFrame.new(0, -0.48, 0)
                        * CFrame.Angles(0, sourceAlongX == alongX and math.pi * 0.5 or 0, 0)
                    rib.Color = theme.Structure
                    rib.Material = VisualTheme.Materials.Structure
                    rib.Transparency = 0
                    rib.Parent = decor
                else
                    decorPart(
                        decor, ribName,
                        alongX and Vector3.new(0.46, 0.38, width + 0.22)
                            or Vector3.new(width + 0.22, 0.38, 0.46),
                        (ribFrame * CFrame.new(0, -0.24, 0)).Position,
                        theme.Structure, VisualTheme.Materials.Structure
                    )
                end
            end
        end

        local skybridge = definition.Skybridge == true
        local elevatedRoute = definition.PromenadeLane or definition.SkySpineStep
        local harborAlongX = harborLandingAlongX(definition)
        local harborLanding = harborAlongX ~= nil
        local lookoutAccess = definition.BranchRoute or definition.CrosslinkRoute
        local glowAlongX = if lookoutAccess then definition.BranchStep == 4 else harborAlongX
        addPlatformGlow(decor, platform, i, theme, routeTier,
            (skybridge or elevatedRoute or harborLanding or lookoutAccess) and edgeBand or nil,
            skybridge and 0.42 or 0.96, glowAlongX)
        addPlatformFinish(decor, platform, i, theme, underdeckSignal,
            (skybridge or harborLanding) and underdeckLattice or nil,
            skybridge and sweptProfile or nil, harborAlongX)
        -- Real 320-stud arenas need strong visual destinations, not more
        -- small repeated squares. Twelve major route portals stand on
        -- PHYSICAL perimeter ascent decks #1, #4 and #8, not floating
        -- at guessed coordinates. The tower is wholly noncolliding and
        -- every piece follows its actual owning platform through shrink
        -- and collapse; pre-existing danger telegraphs remain authoritative.
        if definition.PerimeterRoute then
            SkyRouteMonuments.decorate(
                decor, platform, i, definition, variant.Id, theme)
        end
        -- Six large native-metal arches visibly frame the actual elevated
        -- 200-stud promenades. Every noncolliding part is owned by its
        -- physical PlatformN, including ShrinkingArena movement/scaling.
        -- None adds a blocking wall beneath the high walkways.
        if definition.SkySpineStep then
            SkySpineArchitecture.decorate(
                decor, platform, i, definition, variant.Id, theme, sweptProfile)
            if definition.SkySpineStep == 1 then
                spineEndpoints[1] = platform
            elseif definition.SkySpineStep == 10 then
                spineEndpoints[2] = platform
            end
        end
        if definition.PromenadeLane then
            PromenadeArchitecture.decorate(
                decor, platform, i, definition, variant.Id, theme)

            if definition.PromenadeStep == 4 then
                promenadeJunctions[definition.PromenadeLane] = platform
            end
            local arrowName = "PromenadeJumpChevron" .. i .. "_"
            local inset = math.min(5.0, platform.Size.X * 0.24)
            for direction = -1, 1, 2 do
                local forward = platform.CFrame.RightVector * direction
                addRouteChevron(decor, arrowName .. direction, platform, i,
                    forward, promenadeTone, PROMENADE_CHEVRON, sweptProfile, forward * inset)
            end
        end

        if definition.HarborSpokeStep == 4 then
            -- A real, compact destination marker on each of the four
            -- cardinal playable lookouts. Attached to the owned deck:
            -- follows map resizing and is removed automatically on swap.
            local sides = {"N", "E", "S", "W"}
            local outpost = Instance.new("BillboardGui")
            outpost.Name = "HarborDryDockOutpost"
            outpost.Adornee = platform
            outpost.Size = UDim2.fromOffset(120, 28)
            -- Clear the tallest High-tier western communications array
            -- (max top + ~5.7 studs); keep the real destination label
            -- above authored scenery instead of painting through a mast.
            outpost.StudsOffsetWorldSpace = Vector3.new(0, 8.5, 0)
            outpost.MaxDistance = 64
            outpost.AlwaysOnTop = false
            outpost.Parent = platform
            bindLandingBillboard(outpost, platform)
            local sign = Instance.new("TextLabel")
            sign.Name = "OutpostLabel"
            sign.Size = UDim2.fromScale(1, 1)
            sign.BackgroundColor3 = theme.Structure
            sign.BackgroundTransparency = 0.30
            sign.BorderSizePixel = 0
            sign.Font = Enum.Font.GothamBold
            sign.TextScaled = true
            sign.TextColor3 = Color3.fromRGB(236, 243, 246)
            sign.Text = "DOCK " .. sides[definition.HarborSpokeRoute]
            sign.Parent = outpost
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 5)
            corner.Parent = sign
        end

        if definition.BranchStep == 4 then
            -- Short, distance-limited hint over each genuinely reachable
            -- corner destination; the deck carries the label as it moves.
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "SideLookoutLabel"
            billboard.Adornee = platform
            billboard.Size = UDim2.fromOffset(140, 35)
            billboard.StudsOffsetWorldSpace = Vector3.new(
                0, platform.Size.Y * 0.5 + 4, 0
            )
            billboard.MaxDistance = 78
            billboard.AlwaysOnTop = false
            billboard.Parent = platform
            local text = Instance.new("TextLabel")
            text.Name = "Lookout"
            text.Size = UDim2.fromScale(1, 1)
            text.BackgroundColor3 = Color3.fromRGB(18, 28, 38)
            text.BackgroundTransparency = 0.25
            text.BorderSizePixel = 0
            text.Font = Enum.Font.GothamBold
            -- Every side lookout now connects to a genuine elevated
            -- cross-arena route. Do not advertise a dead end at the
            -- exact place where players must discover a second strategy.
            text.Text = "SKY CROSSING"
            text.TextColor3 = Color3.fromRGB(235, 246, 255)
            text.TextScaled = true
            text.Parent = billboard
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = text
        end

        if definition.PerimeterStep == #variant.PerimeterPlatforms / 4 then
            -- Keep the exit sculpture on the outward face of the final terrace,
            -- clear of the walkable deck and the approach from the previous step.
            local frontSign = platformPosition.Z >= config.ArenaCenter.Z
                and 1 or -1
            local outerZ = platformPosition.Z
                + frontSign * (platform.Size.Z * 0.5 + 0.18)
            for side = -1, 1, 2 do
                local rib = fitDecorMesh(
                    beaconShaft,
                    "PerimeterExitRib" .. definition.PerimeterRoute
                        .. "_" .. tostring(side),
                    CFrame.new(platformPosition.X + side * 3.35,
                        platformPosition.Y - 0.20, outerZ),
                    Vector3.new(0.88, platform.Size.Y - 1.05, 0.34),
                    theme.Structure:Lerp(theme.Detail, 0.18),
                    Enum.Material.Metal
                )
                rib.Transparency = 0.06
                rib:SetAttribute("PerimeterPlatformIndex", i)
                rib.Parent = decor
            end
            local crownSize = Vector3.new(8.0, 1.15, 1.0)
            local crownFrame = CFrame.new(
                platformPosition.X,
                platformPosition.Y + platform.Size.Y * 0.5 - 0.45,
                outerZ + frontSign * 0.34
            ) * CFrame.Angles(0, frontSign < 0 and math.pi or 0, 0)
            local cap = RouteSignalGeometry.fit(sweptProfile, crownFrame, crownSize)
            if not cap then
                cap = Instance.new("WedgePart")
                cap.Size = crownSize
                cap.CFrame = crownFrame
                cap.Anchored = true
                cap.CanCollide = false
                cap.CanTouch = false
                cap.CanQuery = false
                cap.CastShadow = false
            end
            cap.Name = "PerimeterExitCrown" .. definition.PerimeterRoute
            cap.Color = theme.Detail:Lerp(theme.Structure, 0.30)
            cap.Material = Enum.Material.Metal
            cap.Transparency = 0.08
            cap:SetAttribute("PerimeterPlatformIndex", i)
            cap.Parent = decor
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

    -- Place the transverse chevron only where the real bridge overlaps
    -- this landing. A nearby disconnected deck must not show a turn cue.
    for lane = 1, 2 do
        local deck, spine = promenadeJunctions[lane], spineEndpoints[lane]
        if SkyRouteConnectionRules.spineJunction(spine, deck) then
            local index = tonumber(deck.Name:match("^Platform(%d+)$"))
            local along = deck.CFrame.LookVector
            local side = (spine.Position - deck.Position):Dot(along) >= 0 and 1 or -1
            local forward = along * side
            addRouteChevron(decor, "PromenadeJumpChevron" .. index .. "_Spine", deck, index,
                forward, theme.Secondary, SPINE_TURN_CHEVRON, sweptProfile, forward * (deck.Size.Z * 0.25))
            addSpineExitChevrons(decor, spine, deck, theme.Secondary, sweptProfile)
        end
    end

    -- The branching choice also needs to be readable AT THE FORK,
    -- without guessing where sixteen peripheral platforms lead.
    for route = 1, 4 do
        local forkIndex = #variant.Platforms
            + (route - 1) * #variant.PerimeterPlatforms / 4 + 5
        local fork = platforms:FindFirstChild("Platform" .. forkIndex)
        if fork and fork:IsA("BasePart") then
            local forwardZ = fork.Position.Z >= config.ArenaCenter.Z
                and 1 or -1
            addRouteChevron(decor, "BranchForkArrow" .. route, fork, forkIndex,
                Vector3.new(0, 0, forwardZ), theme.Secondary, FORK_CHEVRON, sweptProfile)
        end
    end

    -- Wayfinding is physically anchored to the REAL first/last platforms,
    -- not virtual markers that could point to an inaccessible decoration.
    -- Only 8 small labels and 24 ground-inlaid arrows for all four routes.
    for route = 1, 4 do
        local path = variant.PerimeterPlatforms
        local perRoute = #path / 4
        local entry = path[(route - 1) * perRoute + 1]
        for _, cue in ipairs({
            {name = "Entry", step = 1, title = "CLIMB / DODGE"},
            {name = "Lookout", step = perRoute, title = "HIGH GROUND"},
        }) do
            local platformIndex = #variant.Platforms + (route - 1) * perRoute + cue.step
            local deck = platforms:FindFirstChild("Platform" .. platformIndex)
            if not deck or not deck:IsA("BasePart") then continue end

            local pedestalHeight = 0.46
            local center = 0.09 + pedestalHeight * 0.5
            local pose = deck.CFrame * CFrame.new(0, deck.Size.Y * 0.5 + center, 0)
            local pedestal = fitDecorMesh(wayfinderBase, "DistrictWayfinder" .. route .. cue.name,
                pose, Vector3.new(1.8, pedestalHeight, 1.6), theme.Detail, Enum.Material.Metal)
            pedestal.Transparency = 0.22
            pedestal:SetAttribute("PerimeterPlatformIndex", platformIndex)
            pedestal.Parent = decor
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ObjectiveLabel"
            billboard.Size = UDim2.fromOffset(158, 38)
            billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.9 - center, 0)
            billboard.MaxDistance = 85
            billboard.AlwaysOnTop = false
            billboard.Adornee = pedestal
            billboard.Parent = pedestal
            bindLandingBillboard(billboard, deck)
            local text = Instance.new("TextLabel")
            text.Name = "Objective"
            text.Size = UDim2.fromScale(1, 1)
            text.BackgroundColor3 = Color3.fromRGB(12, 19, 30)
            text.BackgroundTransparency = 0.24
            text.TextColor3 = Color3.fromRGB(236, 248, 255)
            text.Font = Enum.Font.GothamBold
            text.TextScaled = true
            text.Text = cue.title
            text.Parent = billboard
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 9)
            corner.Parent = text
            local stroke = Instance.new("UIStroke")
            stroke.Color = theme.Accent
            stroke.Thickness = 1
            stroke.Transparency = 0.35
            stroke.Parent = text
        end
        local sx = entry.offset.X >= 0 and 1 or -1
        for marker = 1, 3 do
            local arrowPoint = config.ArenaCenter + Vector3.new(
                sx * (math.abs(entry.offset.X) - 20 + marker * 3.2),
                variant.BaseSize.Y * 0.5 + 0.22, entry.offset.Z
            )
            local forward = CFrame.lookAt(
                arrowPoint, arrowPoint + Vector3.new(sx, 0, 0)
            )
            for side = -1, 1, 2 do
                local pose = forward * CFrame.new(side * 0.43, 0, 0)
                    * CFrame.Angles(0, math.rad(side * 38), 0)
                local name = "DistrictArrow" .. route .. "_" .. marker .. "_" .. tostring(side)
                local color = marker == 3 and theme.Accent or theme.Secondary
                local chevron = fitDecorMesh(sweptProfile, name, pose, Vector3.new(0.17, 0.055, 1.50),
                    color, VisualTheme.Materials.Glow)
                chevron.Transparency = 0.42
                chevron:SetAttribute("ChaosWayfinding", true)
                chevron.Parent = decor
            end
        end
    end

    if variant.Id == "Orbital" then
        -- Fully physical sloped routes between the outer and inner decks.
        -- No scripted platform movement or client-controlled collisions.
        OrbitalHelix.build(arena, variant, config.ArenaCenter, theme)
    end

    -- Navigation is derived from the ACTUAL eight physical platforms per
    -- outer route. Never point to invented diagonal coordinates: the first
    -- goal must be a walkable entry terrace, then every real climb step.
    -- Floor-painted cues are cosmetic and retracted with the shrinking floor.
    local perRoute = #(variant.PerimeterPlatforms or {}) / 4
    for route = 1, 4 do
        local startIndex = (route - 1) * perRoute
        local entry = variant.PerimeterPlatforms[startIndex + 1]
        local lookout = variant.PerimeterPlatforms[startIndex + perRoute]
        local approach = Vector3.new(entry.offset.X, 0, entry.offset.Z)
        local outward = approach.Unit
        local approachDepth = (math.abs(outward.X) * entry.size.X
            + math.abs(outward.Z) * entry.size.Z) * 0.5
        local approachEnd = approach.Magnitude - approachDepth - 1.6
        local routeColor = route % 2 == 0 and theme.Secondary or theme.Accent

        -- End just short of the entry terrace so the last arrow remains
        -- visible instead of passing underneath the grounded platform.
        for step = 1, 5 do
            local distance = approachEnd * (0.45 + 0.55 * (step - 1) / 4)
            local point = config.ArenaCenter + outward * distance
                + Vector3.new(0, variant.BaseSize.Y * 0.5 + 0.04, 0)
            local facing = CFrame.lookAt(point, point + outward)
            for side = -1, 1, 2 do
                local name = "OuterRouteChevron" .. route .. "_" .. step .. "_" .. side
                local pose = facing * CFrame.new(side * 0.57, 0, 0)
                    * CFrame.Angles(0, math.rad(side * 33), 0)
                local arrow = fitDecorMesh(sweptProfile, name, pose, Vector3.new(0.28, 0.055, 2.5),
                    routeColor, VisualTheme.Materials.Glow)
                arrow.Transparency = 0.45
                arrow:SetAttribute("ChaosWayfinding", true)
                arrow.Parent = decor
            end
        end

        -- Face the next real landing, or the way back at the terminal.
        -- Offsetting each arrow keeps the central signs and forks clear.
        for step = 1, perRoute do
            local platformIndex = #variant.Platforms + startIndex + step
            local neighborIndex = platformIndex + (step < perRoute and 1 or -1)
            local deck = platforms:FindFirstChild("Platform" .. platformIndex)
            local neighbor = platforms:FindFirstChild("Platform" .. neighborIndex)
            if not deck or not neighbor then continue end
            local delta = (neighbor.Position - deck.Position) * Vector3.new(1, 0, 1)
            if delta.Magnitude <= 0.01 then continue end
            local forward = delta.Unit
            local name = "OuterStepChevron" .. route .. "_" .. step
            addRouteChevron(decor, name, deck, platformIndex, forward, routeColor,
                PERIMETER_STEP_CHEVRON, sweptProfile, forward * 2.4)
        end

        -- Three-part destination beacon on open FLOOR beside (never on)
        -- the last high terrace. Its metal mast + glass lens are visible
        -- from the central plaza, without a point light or collision.
        local signX = lookout.offset.X >= 0 and 1 or -1
        local signZ = lookout.offset.Z >= 0 and 1 or -1
        local beaconPoint = config.ArenaCenter + Vector3.new(
            math.clamp(lookout.offset.X + signX * 11, -halfX + 3, halfX - 3),
            variant.BaseSize.Y * 0.5 + 17,
            math.clamp(lookout.offset.Z + signZ * 9, -halfZ + 3, halfZ - 3)
        )
        local terminalIndex = #variant.Platforms + startIndex + perRoute
        local mast = fitDecorMesh(beaconShaft, "OuterRouteSignal" .. route, CFrame.new(beaconPoint),
            Vector3.new(1.55, 34, 1.55), theme.Structure:Lerp(theme.Detail, 0.30), Enum.Material.Metal)
        mast.Transparency = 0.12
        local lens = decorPart(
            decor, "OuterRouteSignalLens" .. route,
            Vector3.new(3.8, 3.8, 3.8),
            beaconPoint + Vector3.new(0, 18.5, 0),
            routeColor, Enum.Material.Glass
        )
        lens.Shape = Enum.PartType.Ball
        lens.Transparency = 0.20
        local crown = fitDecorMesh(wayfinderBase, "OuterRouteSignalCrown" .. route,
            CFrame.new(beaconPoint + Vector3.new(0, 15.9, 0)), Vector3.new(5.0, 0.85, 5.0),
            theme.Detail, Enum.Material.Metal)
        for _, piece in ipairs({mast, lens, crown}) do
            piece:SetAttribute("ChaosWayfinding", true)
            piece:SetAttribute("PerimeterPlatformIndex", terminalIndex)
            piece.Parent = decor
        end
    end

    local pillarSize = Vector3.new(0.8, 7, 0.8)
    local pillarY = (base.Size.Y + pillarSize.Y) * 0.5
    local beaconOffsets = {
        Vector3.new(-halfX + 3, pillarY, -halfZ + 3),
        Vector3.new(halfX - 3, pillarY, -halfZ + 3),
        Vector3.new(-halfX + 3, pillarY, halfZ - 3),
        Vector3.new(halfX - 3, pillarY, halfZ - 3),
    }

    for i, offset in ipairs(beaconOffsets) do
        local frame = base.CFrame * CFrame.new(offset)
        local pillar = fitDecorMesh(
            beaconShaft,
            "EdgeBeacon" .. i,
            frame,
            pillarSize,
            theme.Structure:Lerp(Color3.new(1, 1, 1), 0.08),
            VisualTheme.Materials.Structure
        )
        pillar.Parent = decor

        local color = i % 2 == 0 and theme.Secondary or theme.Accent
        local cap = fitDecorMesh(
            wayfinderBase,
            "EdgeBeaconGlow" .. i,
            frame * CFrame.new(0, pillarSize.Y * 0.5 + 0.05, 0),
            Vector3.new(1.35, 0.36, 1.35),
            color,
            VisualTheme.Materials.Glow
        )
        cap.Transparency = 0.10

        local capLight = Instance.new("PointLight")
        capLight.Name = "EdgeBeaconLight"
        capLight.Color = color
        capLight.Brightness = 0.55
        capLight.Range = 11
        capLight.Shadows = false
        capLight.Parent = cap
        cap.Parent = decor
    end

    return arena
end

function MapBuilder.build(config, variantId, arenaVariants, themeProvider)
    local old = workspace:FindFirstChild("GeneratedMap")
    if old then
        old:Destroy()
    end

    local root = Instance.new("Folder")
    root.Name = "GeneratedMap"
    root.Parent = workspace

    buildLobby(root, config)
    MapBuilder.buildArena(
        config, variantId or "Classic", arenaVariants, themeProvider
    )

    return root
end

return MapBuilder
