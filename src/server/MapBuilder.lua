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
local horizonGeometryModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonGeometryModule then require(horizonGeometryModule)
    else require("../shared/HorizonMonumentGeometry")
local platformIdentityModule = shared and shared:FindFirstChild("PlatformIdentityLodRules")
local PlatformIdentityLodRules = if platformIdentityModule then require(platformIdentityModule)
    else require("../shared/PlatformIdentityLodRules")
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
local PremiumFloorReliefAssets = require("./PremiumFloorReliefAssets")
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

local function fitDecorMesh(profile, name, pose, size, color, material, alongX)
    local detail = RouteSignalGeometry.fit(profile, pose, size, nil, alongX)
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
local function addPerimeterStations(decor, config, variant, theme, profiles)
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

        local function piece(name, className, size, offset, material, color, opacity, profile, inlaySide)
            local frame = origin * offset
            local item = profile and RouteSignalGeometry.fit(profile.part, frame, size, inlaySide)
            if item then
                item:SetAttribute("OriginalPerimeterStationDetail3D", true)
                item:SetAttribute("Original3DAssetId", profile.assetId)
                local turned = not inlaySide
                    and math.abs(item.CFrame.RightVector:Dot(frame.RightVector)) < .5
                item:SetAttribute("StationDetailAxisSwap", if turned then true else nil)
            else
                item = Instance.new(className or "Part")
                item.Size = size
                item.CFrame = frame
            end
            item.Name = name
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

        -- Eight station pieces stay native so the existing client LOD kits
        -- can replace them with complete approved assemblies: two buttresses,
        -- three machinery housings and three rotor drums. A server MeshPart
        -- in those slots would block the client replacement.
        -- Recessed platform marker. The real floor underneath stays the
        -- sole walkable surface; the mark never catches feet or incoming
        -- projectiles and does not leave islands after Shrinking Arena.
        piece("InlaidStationBase", "Part", Vector3.new(12, 0.07, 11),
            CFrame.new(0, 0.035, 0), theme.PanelMaterial or Enum.Material.Metal,
            theme.Structure:Lerp(theme.Surface, 0.18), 0.14, profiles.plate)
        for _, side in ipairs({-1, 1}) do
            piece(side < 0 and "LeftButtress" or "RightButtress",
                "Part", Vector3.new(1.5, 9, 2),
                CFrame.new(side * 5.3, 4.5, 0), Enum.Material.Metal,
                theme.Structure, 0.06)
            piece(side < 0 and "LeftAngledCap" or "RightAngledCap",
                "WedgePart", Vector3.new(2.9, 2.2, 2.4),
                CFrame.new(side * 5.0, 9.1, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal, theme.Detail, 0.08, profiles.wing)
            piece(side < 0 and "LeftLightNotch" or "RightLightNotch",
                "Part", Vector3.new(0.14, 1.8, 1.1),
                CFrame.new(side * 5.3, 5.0, -1.06), Enum.Material.Neon,
                side < 0 and accent or secondary, 0.38, profiles.signal, side)
        end
        piece("CrossBrace", "Part", Vector3.new(9.1, 0.65, 1.25),
            CFrame.new(0, 9.0, -0.2), Enum.Material.Metal,
            theme.Structure:Lerp(theme.Detail, 0.22), 0.04, profiles.wing)
        piece("CoreHousing", "Part", Vector3.new(3.2, 3.7, 2.8),
            CFrame.new(0, 4.9, 0.1), Enum.Material.Metal,
            theme.Detail:Lerp(theme.Structure, 0.35), 0.06)
        local core = piece("CoreLens", "Part", Vector3.new(2.7, 2.7, 2.7),
            CFrame.new(0, 5.1, -1.65), Enum.Material.Glass,
            accent:Lerp(secondary, 0.25), 0.33, profiles.lens)
        if core:IsA("Part") then core.Shape = Enum.PartType.Ball end
        piece("WayfindingInset", "Part", Vector3.new(3.1, 0.16, 1.6),
            CFrame.new(0, 0.11, -4.25), Enum.Material.Neon,
            accent, 0.57, profiles.signal)

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
            if intake:IsA("Part") then intake.Shape = Enum.PartType.Cylinder end
            piece(side < 0 and "AngledServiceWingL" or "AngledServiceWingR",
                "WedgePart", Vector3.new(3.4, 1.7, 5.7),
                CFrame.new(side * 7.0, 4.9, 1.1)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                Enum.Material.Metal,
                theme.Structure:Lerp(theme.Secondary, 0.23), 0.06, profiles.wing)
            -- Outer cast armor is a separate cosmetic owner: the eight native
            -- station slots remain available for the complete client LOD kit.
            piece(side < 0 and "PodArmorL" or "PodArmorR",
                "Part", Vector3.new(0.34, 2.15, 3.8),
                CFrame.new(side * 8.96, 2.35, 1.1),
                Enum.Material.Metal,
                theme.Detail:Lerp(theme.Structure, 0.42), 0.05, profiles.housing)
            piece(side < 0 and "PodDataRailL" or "PodDataRailR",
                "Part", Vector3.new(0.18, 0.22, 3.1),
                CFrame.new(side * 8.85, 3.4, 0.7),
                Enum.Material.Neon, side < 0 and accent or secondary, 0.40, profiles.rail)
        end
        local generator = piece("GeneratorRotor", "Part",
            Vector3.new(2.7, 0.9, 2.7),
            CFrame.new(0, 8.1, -1.4)
                * CFrame.Angles(math.rad(90), 0, 0),
            Enum.Material.Metal, theme.Detail, 0.08)
        if generator:IsA("Part") then generator.Shape = Enum.PartType.Cylinder end
        piece("GeneratorShield", "Part", Vector3.new(4.0, 0.55, 1.4),
            CFrame.new(0, 7.8, -0.4), Enum.Material.Metal,
            theme.Structure:Lerp(theme.Accent, 0.24), 0.07, profiles.wing)
        -- Raised cast shoulders frame the generator without replacing the
        -- native rotor slot owned by the client LOD assembly. Both trims
        -- are noninteractive and use the already approved station mesh.
        for _, side in ipairs({-1, 1}) do
            piece(side < 0 and "GeneratorShoulderL" or "GeneratorShoulderR",
                "Part", Vector3.new(0.58, 0.75, 2.65),
                CFrame.new(side * 2.35, 8.05, -1.0),
                Enum.Material.Metal,
                theme.Structure:Lerp(theme.Detail, 0.30), 0.06, profiles.housing)
        end
        -- Upper service arch: approved swept metal segments visually connect
        -- the generator shoulders to the tower without adding a walkable ledge.
        -- The native generator rotor stays untouched for client LOD ownership.
        for _, side in ipairs({-1, 1}) do
            piece(side < 0 and "UpperServiceRibL" or "UpperServiceRibR",
                "Part", Vector3.new(0.52, 2.1, 1.45),
                CFrame.new(side * 2.35, 9.15, 0.15)
                    * CFrame.Angles(math.rad(side * 18), 0, 0),
                Enum.Material.Metal,
                theme.Detail:Lerp(theme.Structure, 0.38), 0.08, profiles.wing)
        end

        if variant.Id == "Towers" then
            -- Twin crane masts convey vertical scale without placing an
            -- overhead platform where an R15 could become trapped.
            piece("ServiceMast", "Part", Vector3.new(0.75, 6.8, 0.75),
                CFrame.new(0, 12.6, 0.3), Enum.Material.Metal,
                theme.Structure, 0.04, profiles.shaft)
            piece("SignalCrown", "WedgePart", Vector3.new(2.2, 1.4, 1.8),
                CFrame.new(0, 16.6, 0.3), Enum.Material.Metal,
                secondary, 0.10, profiles.wing)
            piece("CrownSpine", "Part", Vector3.new(0.46, 2.25, 0.72),
                CFrame.new(0, 17.55, 0.3), Enum.Material.Metal,
                theme.Detail, 0.08, profiles.shaft)
        elseif variant.Id == "Orbital" then
            -- Cylindrical receiver and two radial braces distinguish the
            -- reactor site from both tower cranes and grid substations.
            local dish = piece("ReceiverDish", "Part", Vector3.new(3.4, 0.65, 3.4),
                CFrame.new(0, 10.4, 0), Enum.Material.Metal,
                theme.Detail, 0.12, profiles.turbine)
            if dish:IsA("Part") then dish.Shape = Enum.PartType.Cylinder end
            piece("ReceiverAntenna", "Part", Vector3.new(0.38, 3.4, 0.38),
                CFrame.new(0, 12.35, 0), Enum.Material.Metal,
                accent, 0.22, profiles.shaft)
            piece("ReceiverCrown", "Part", Vector3.new(1.9, 0.42, 1.9),
                CFrame.new(0, 14.2, 0), Enum.Material.Metal,
                secondary, 0.10, profiles.housing)
        elseif variant.Id == "Crossroads" then
            piece("ExchangeBeam", "Part", Vector3.new(2.5, 0.75, 8.5),
                CFrame.new(0, 8.2, 0), Enum.Material.Metal,
                theme.Detail, 0.10, profiles.wing)
            piece("SwitchyardMarker", "WedgePart", Vector3.new(1.5, 2, 2),
                CFrame.new(0, 10.0, 0), Enum.Material.Metal,
                secondary, 0.12, profiles.wing)
            piece("SwitchyardCrown", "Part", Vector3.new(0.7, 1.4, 1.5),
                CFrame.new(0, 11.45, 0), Enum.Material.Metal,
                accent, 0.10, profiles.shaft)
        else
            piece("RelaySpire", "Part", Vector3.new(0.7, 4.4, 0.7),
                CFrame.new(0, 11.5, 0), Enum.Material.Metal,
                theme.Detail, 0.10, profiles.shaft)
            piece("RelayCrown", "WedgePart", Vector3.new(2.4, 1.6, 2),
                CFrame.new(0, 14.6, 0), Enum.Material.Metal,
                accent, 0.12, profiles.wing)
            piece("RelayCrownFin", "Part", Vector3.new(0.5, 1.4, 1.4),
                CFrame.new(0, 15.75, 0), Enum.Material.Metal,
                secondary, 0.10, profiles.wing)
        end
    end
end

local function exteriorPart(name, frame, size, material, color, source, alongX, fallbackClass)
    local mesh = source and RouteSignalGeometry.fit(source.part, frame, size, nil, alongX)
    local item = mesh or Instance.new(fallbackClass or "Part")
    if mesh then
        mesh:SetAttribute("OriginalExteriorDetail3D", true)
        mesh:SetAttribute("Original3DAssetId", source.assetId)
        local turned = math.abs(mesh.CFrame.RightVector:Dot(frame.RightVector)) < .5
        mesh:SetAttribute("ExteriorDetailAxisSwap", if turned then true else nil)
    else
        item.Size = size
        item.CFrame = frame
    end
    item.Name = name
    item.Anchored = true
    item.CanCollide = false
    item.CanTouch = false
    item.CanQuery = false
    item.CastShadow = false
    item.Material = material
    item.Color = color
    return item
end

local function horizonPieceBuilder(model, origin, hull, variant, templates)
    return function(name, kind, size, offset, material, color, opacity, shape)
        local profile = HorizonMonumentGeometry.profile(model.Name, name)
        local template = templates[profile]
        local assetId = HorizonMonumentGeometry.assetId(profile, variant)
        local source = template and template.MeshId ~= "" and assetId
            and {part = template, assetId = assetId} or nil
        -- Keep casting slopes in Z and the fitted radar drums on their short X axis.
        local item = exteriorPart(name, origin * offset, size, material or Enum.Material.Metal,
            color or hull, source, true, kind)
        if shape and item:IsA("Part") then item.Shape = shape end
        item.Transparency = opacity or 0
        item.Parent = model
    end
end

-- The enlarged 150+ stud maps need a believable horizon, not just
-- extra empty floor. Four purpose-built exterior silhouettes provide depth
-- from the player's ground-height camera while remaining OUTSIDE the
-- hazard arena. Each slot uses one fitted approved profile when available.
-- Taller roofs remain outside every safe player/AI route and kill plane.
local function addDistantSkyline(decor, config, variant, theme, templates)
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
        model:SetAttribute("SignatureVariant", variant.Id)
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

        local detail = horizonPieceBuilder(model, base, hullColor, variant.Id, templates)

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
            detail("ReceiverHead", "Part",
                Vector3.new(5.5, 0.75, 5.5),
                CFrame.new(0, height + 3.4, 0),
                Enum.Material.Metal, metalColor, 0.06, Enum.PartType.Cylinder)
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
            model:SetAttribute("SignatureVariant", variant.Id)
            model.Parent = decor
            local height = (variant.Id == "Towers" and 31 or 22)
                + layer * 5 + ((index + layer) % 3) * 3
            local origin = config.ArenaCenter
                + Vector3.new(direction.x, variant.BaseSize.Y * 0.5,
                    direction.z)
                + outward * (16 + layer * 10)
                + side * (layer == 1 and -17 or 19)
            local detail = horizonPieceBuilder(model, CFrame.new(origin), farColor, variant.Id, templates)
            detail("DistantRoofMass", "WedgePart", Vector3.new(10 + layer * 3, height, 8),
                CFrame.new(0, height * .5, 0) * CFrame.Angles(0, direction.yaw, 0),
                Enum.Material.Metal, farColor, .14 + layer * .12)
            detail("DistantAerial", "Part", Vector3.new(.38, 4 + layer * 2, .38),
                CFrame.new(0, height + 2 + layer, 0),
                Enum.Material.Metal, farColor, .20 + layer * .10)
        end
    end
end

-- One large, scene-specific architectural silhouette per arena.
-- Deliberately positioned beyond the kill/physics floor, behind the playable
-- skyline. Optional approved profiles fit the authored fallback footprints.
-- Their large-scale shapes are legible from a mobile third-person camera,
-- with dark industrial mass first and restrained colored accents second.
-- Never give the hero structure collision, touch, queries, shadows, lights,
-- animations, untrusted assets, or gameplay significance.
local function addArenaSignatureMegastructure(decor, config, variant, theme, templates)
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

    local piece = horizonPieceBuilder(model, origin, hull, variant.Id, templates)

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
        piece("SuspendedReactorCore", "Part",
            Vector3.new(10, 10, 10), CFrame.new(0, 29, 0),
            Enum.Material.Glass, glint, 0.32, Enum.PartType.Ball)
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
            piece(
                side < 0 and "ReceiverDishWest" or "ReceiverDishEast",
                "Part", Vector3.new(0.8, 10.5, 10.5),
                CFrame.new(side * 13, 44 + side * 3, 0)
                    * CFrame.Angles(0, math.pi * 0.5, 0),
                Enum.Material.Metal, metal, 0.10, Enum.PartType.Cylinder)
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
local function addSouthHorizonMonument(decor, config, variant, theme, templates)
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

    local piece = horizonPieceBuilder(model, origin, hull, variant.Id, templates)

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
        piece("SuspendedOrb", "Part",
            Vector3.new(6.4, 6.4, 6.4), CFrame.new(0, 23, 0),
            Enum.Material.Glass, signal, 0.38, Enum.PartType.Ball)
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
            piece(
                side < 0 and "WestRadarDish" or "EastRadarDish",
                "Part", Vector3.new(0.9, 12, 12),
                CFrame.new(side * 16, 34, 0)
                    * CFrame.Angles(0, math.pi * 0.5, 0),
                Enum.Material.Metal, alloy, 0.08, Enum.PartType.Cylinder)
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

-- The four corner groups sit beyond both axes of the arena floor.
-- Each crest uses one fitted casting or the original wedge.
local function addExteriorCornerRidges(decor, config, variant, theme, casting)
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
            local size = Vector3.new(11 + index * 3, height, 13 + index * 2)
            local frame = CFrame.new(center + Vector3.new(
                (index - 2) * corner.sx * 8, height * 0.5 - 1.5,
                (index - 2) * corner.sz * 6
            )) * CFrame.Angles(0, yaw + (index - 2) * 0.32, 0)
            local ridge = exteriorPart("Ridge" .. index, frame, size,
                index == 2 and Enum.Material.Concrete or Enum.Material.Metal,
                index == 2 and stone or metal, casting, true, "WedgePart")
            ridge.Transparency = 0.07 + index * 0.04
            ridge.Parent = model
        end
    end
end

-- Low-cost original skyline silhouettes beyond the playable boundary.
-- One six-piece industrial silhouette per side adds perspective and scale.
-- All geometry is noninteractive and cannot trap players or NPCs.
local function addExteriorSilhouettes(decor, config, variant, theme, profiles)
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

        local function segment(name, size, offset, material, color, source, alongX)
            local p = exteriorPart(name, frame * CFrame.new(offset), size, material,
                color, source, alongX)
            p.Parent = model
        end

        segment("ReactorShell", Vector3.new(9, height, 8),
            Vector3.new(0, height * 0.5, 0), Enum.Material.Metal, shell, profiles.shell)
        segment("RoofCanopy", Vector3.new(12, 1.2, 10),
            Vector3.new(0, height + 0.6, 0), Enum.Material.Metal, trim, profiles.roof, true)
        for side = -1, 1, 2 do
            segment(side < 0 and "LeftRib" or "RightRib",
                Vector3.new(1.2, height * 0.75, 1.4),
                Vector3.new(side * 5, height * 0.42, -2.8),
                Enum.Material.Metal, trim, profiles.shaft)
        end
        segment("SignalBand", Vector3.new(6, 0.35, 0.18),
            Vector3.new(0, height * 0.68, -4.08),
            Enum.Material.Neon, signal, profiles.signal)
        segment("Antenna", Vector3.new(0.55, 6, 0.55),
            Vector3.new(0, height + 3.5, 0),
            Enum.Material.Metal, trim, profiles.shaft)
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

    -- Sculpted diagonal corner gussets give the exposed underside a
    -- load-bearing silhouette. They sit below the authoritative floor and
    -- remain cosmetic, with native noncolliding fallback if meshes are absent.
    for xSign = -1, 1, 2 do
        for zSign = -1, 1, 2 do
            local corner = center + Vector3.new(
                xSign * (insetX - 2.0), -2.0, zSign * (insetZ - 2.0))
            local brace = fitDecorMesh(
                sweptProfile,
                "UndercarriageCornerGusset" .. (xSign < 0 and "L" or "R")
                    .. (zSign < 0 and "N" or "S"),
                CFrame.new(corner) * CFrame.Angles(0, math.rad(xSign * zSign * 45), 0),
                Vector3.new(7.2, 2.6, 1.3),
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            brace.Transparency = 0.05
            brace:SetAttribute("PremiumArchitecturalSurface", true)
            brace.Parent = undercarriage
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

    -- Four broad forged edge skirts break up the arena's exposed slab
    -- silhouette. Keep them outside the playable deck and below its top:
    -- no visual obstruction to hazards, spawn guides or mobile wayfinding.
    local skirtY = -0.32
    local edgeSkirts = {
        {name = "North", pose = CFrame.new(center + Vector3.new(0, skirtY, -baseSize.Z * 0.5 - 0.16)),
            size = Vector3.new(baseSize.X - 4, 1.25, 0.42)},
        {name = "South", pose = CFrame.new(center + Vector3.new(0, skirtY, baseSize.Z * 0.5 + 0.16)),
            size = Vector3.new(baseSize.X - 4, 1.25, 0.42)},
        {name = "West", pose = CFrame.new(center + Vector3.new(-baseSize.X * 0.5 - 0.16, skirtY, 0)),
            size = Vector3.new(0.42, 1.25, baseSize.Z - 4)},
        {name = "East", pose = CFrame.new(center + Vector3.new(baseSize.X * 0.5 + 0.16, skirtY, 0)),
            size = Vector3.new(0.42, 1.25, baseSize.Z - 4)},
    }
    for _, edge in ipairs(edgeSkirts) do
        local skirt = fitDecorMesh(
            sweptProfile, "ForgedDeckSkirt" .. edge.name,
            edge.pose, edge.size, theme.Structure,
            VisualTheme.Materials.Structure
        )
        skirt.Transparency = 0.06
        skirt:SetAttribute("PremiumArchitecturalSurface", true)
        skirt.Parent = decor
    end

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
        local column = fitDecorMesh(
            beaconShaft,
            "FrameColumn" .. i,
            CFrame.new(center + offset),
            Vector3.new(1.4, 8.4, 1.4),
            theme.Structure,
            VisualTheme.Materials.Structure
        )
        column.Transparency = 0.05
        column.Parent = decor

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

local meshRegionByBounds = RouteSignalGeometry.regionByBounds

local function approvedHorizonRegion(holderName, name, tag, assetId, regionSize)
    local holder = ReplicatedStorage:FindFirstChild(holderName)
    if not holder or not holder:IsA("Folder") then return nil end
    local model = RouteSignalGeometry.approvedModel(holder, name, tag, assetId)
    return model and meshRegionByBounds(model, regionSize) or nil
end

local function orbitalReactorNodeRegion(regionSize)
    return approvedHorizonRegion("ApprovedOrbitalReactorLandmarkTemplates", "Node",
        "OriginalOrbitalReactorLandmark3D", 104654294187035, regionSize)
end

local function addVariantIdentity(decor, config, variant, theme, castProfile, sweptProfile, beaconShaft)
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
            local tower = fitDecorMesh(
                beaconShaft,
                "GridMarker" .. i,
                CFrame.new(center + offset),
                Vector3.new(2.2, 12, 2.2),
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            tower.Transparency = 0.06
            tower.Parent = decor

            local crown = fitDecorMesh(
                castProfile,
                "GridMarkerGlow" .. i,
                CFrame.new(tower.Position + Vector3.new(0, 6.1, 0)),
                Vector3.new(3.8, 0.32, 3.8),
                (i % 2 == 0) and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            crown.Transparency = 0.16
            crown.Parent = decor
        end
    elseif variant.Id == "Towers" then
        local corners = {
            Vector3.new(-halfX + 7, 10, -halfZ + 7),
            Vector3.new(halfX - 7, 10, -halfZ + 7),
            Vector3.new(-halfX + 7, 10, halfZ - 7),
            Vector3.new(halfX - 7, 10, halfZ - 7),
        }

        for i, offset in ipairs(corners) do
            local mast = fitDecorMesh(
                beaconShaft,
                "TowerSpine" .. i,
                CFrame.new(center + offset),
                Vector3.new(2.6, 20, 2.6),
                theme.Structure,
                VisualTheme.Materials.Structure
            )
            mast.Transparency = 0.04
            mast.Parent = decor

            for level = 1, 3 do
                local band = fitDecorMesh(
                    sweptProfile,
                    "TowerBand" .. i .. "_" .. level,
                    CFrame.new(mast.Position + Vector3.new(0, -6 + (level * 4.5), 0)),
                    Vector3.new(4.4, 0.28, 4.4),
                    level == 2 and theme.Secondary or theme.Accent,
                    VisualTheme.Materials.Glow
                )
                band.Transparency = 0.22
                band.Parent = decor
            end
        end
    elseif variant.Id == "Crossroads" then
        local gateY = variant.BaseSize.Y * 0.5 + 10
        local gates = {
            {pos = Vector3.new(0, gateY, -halfZ + 7), size = Vector3.new(18, 1.2, 1.4)},
            {pos = Vector3.new(0, gateY, halfZ - 7), size = Vector3.new(18, 1.2, 1.4)},
            {pos = Vector3.new(-halfX + 7, gateY, 0), size = Vector3.new(1.4, 1.2, 18)},
            {pos = Vector3.new(halfX - 7, gateY, 0), size = Vector3.new(1.4, 1.2, 18)},
        }

        for i, def in ipairs(gates) do
            local rail = fitDecorMesh(
                sweptProfile,
                "CrossroadGate" .. i,
                CFrame.new(center + def.pos),
                def.size,
                (i % 2 == 0) and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            rail.Transparency = 0.18
            rail.Parent = decor

            local lateral = def.size.X > def.size.Z and Vector3.new(8.5, 0, 0) or Vector3.new(0, 0, 8.5)
            local postCenter = rail.Position - Vector3.new(0, 5, 0)
            for sign = -1, 1, 2 do
                local post = fitDecorMesh(
                    beaconShaft,
                    "CrossroadPost" .. i .. "_" .. tostring(sign),
                    CFrame.new(postCenter + lateral * sign),
                    Vector3.new(1.2, 10, 1.2),
                    theme.Structure,
                    VisualTheme.Materials.Structure
                )
                post.Transparency = 0.05
                post.Parent = decor
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

            local segment = fitDecorMesh(
                sweptProfile,
                "OrbitalCrown" .. i,
                CFrame.new(position) * CFrame.Angles(0, -angle, math.rad(4)),
                Vector3.new(7.4, 0.42, 0.8),
                (i % 2 == 0) and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            segment.Transparency = 0.20
            segment.Parent = decor
        end

        local core = fitDecorMesh(
            orbitalReactorNodeRegion(Vector3.new(2.96, 2.9503, 2.96)),
            "OrbitalCore",
            CFrame.new(center + Vector3.new(0, 13, 0)),
            Vector3.new(5, 5, 5),
            theme.Secondary,
            VisualTheme.Materials.Glow
        )
        if core:IsA("Part") then core.Shape = Enum.PartType.Ball end
        core.Transparency = 0.34

        local coreLight = Instance.new("PointLight")
        coreLight.Name = "OrbitalCoreLight"
        coreLight.Color = theme.Accent
        coreLight.Brightness = 1.1
        coreLight.Range = 24
        coreLight.Shadows = false
        coreLight.Parent = core
        core.Parent = decor
    end
end

local function addVariantLandmarks(decor, config, variant, theme, castProfile, sweptProfile, beaconShaft)
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
            local fin = fitDecorMesh(
                sweptProfile, "ClassicBroadcastFin" .. i,
                CFrame.new(center + def.offset), def.size,
                theme.Structure, VisualTheme.Materials.Structure
            )
            fin.Parent = decor
            fin.Transparency = 0.05

            local stripSize = def.size.X < def.size.Z
                and Vector3.new(0.22, 10, def.size.Z + 0.08)
                or Vector3.new(def.size.X + 0.08, 10, 0.22)
            local strip = fitDecorMesh(
                sweptProfile, "ClassicBroadcastGlow" .. i,
                CFrame.new(fin.Position + Vector3.new(0, 0.5, 0)),
                stripSize,
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            strip.Parent = decor
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
            local machinery = fitDecorMesh(
                beaconShaft, "TowerMachinery" .. i,
                CFrame.new(center + offset), Vector3.new(5.2, 24, 5.2),
                theme.Structure, VisualTheme.Materials.Structure
            )
            machinery.Parent = decor
            machinery.Transparency = 0.04

            local cap = fitDecorMesh(
                castProfile, "TowerMachineryCap" .. i,
                CFrame.new(machinery.Position + Vector3.new(0, 12.4, 0)),
                Vector3.new(7.4, 1.0, 7.4), theme.Accent,
                VisualTheme.Materials.Glow
            )
            cap.Parent = decor
            cap.Transparency = 0.18

            local antenna = fitDecorMesh(
                beaconShaft, "TowerAntenna" .. i,
                CFrame.new(machinery.Position + Vector3.new(0, 17.2, 0)),
                Vector3.new(0.55, 9, 0.55),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            antenna.Parent = decor
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
            local gantry = fitDecorMesh(
                sweptProfile, "CrossroadGantry" .. i,
                CFrame.new(center + def.offset), def.size,
                theme.Structure, VisualTheme.Materials.Structure
            )
            gantry.Parent = decor
            gantry.Transparency = 0.04

            local signal = fitDecorMesh(
                sweptProfile, "CrossroadSignal" .. i,
                CFrame.new(gantry.Position),
                def.size.X > def.size.Z and Vector3.new(18, 0.34, 2.12)
                    or Vector3.new(2.12, 0.34, 18),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            signal.Parent = decor
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

            local node = fitDecorMesh(
                castProfile, "OrbitalReactorNode" .. i,
                CFrame.new(position), Vector3.new(4.4, 4.4, 4.4),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                VisualTheme.Materials.Glow
            )
            if node:IsA("Part") then node.Shape = Enum.PartType.Ball end
            node.Parent = decor
            node.Transparency = 0.20

            local strutPosition = center + Vector3.new(
                math.cos(angle) * (radius - 4.4), 7,
                math.sin(angle) * (radius - 4.4)
            )
            local strut = fitDecorMesh(
                sweptProfile, "OrbitalReactorStrut" .. i,
                CFrame.new(strutPosition) * CFrame.Angles(0, -angle, 0),
                Vector3.new(8.5, 0.55, 0.55),
                theme.Structure, VisualTheme.Materials.Structure
            )
            strut.Parent = decor
            strut.Transparency = 0.10
        end
    end
end

local function addArenaHologram(decor, config, variant, theme, sweptProfile)
    local sign = decorPart(
        decor,
        "ArenaIdentityHologram",
        Vector3.new(20, 6.4, 0.28),
        config.ArenaCenter + Vector3.new(0, 11, -(variant.BaseSize.Z * 0.5) - 5.5),
        theme.Surface,
        VisualTheme.Materials.Panel
    )
    sign.Transparency = 0.20

    -- The sign stays a native Part so its SurfaceGui remains predictable.
    -- Only the noninteractive rear glow is eligible for a sculpted mesh.
    local backGlow = fitDecorMesh(
        sweptProfile, "ArenaIdentityGlow",
        CFrame.new(sign.Position + Vector3.new(0, 0, 0.20)),
        Vector3.new(21.2, 7.3, 0.10),
        theme.Accent, VisualTheme.Materials.Glow
    )
    backGlow.Parent = decor
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

local function floorReliefRegion(name, regionSize)
    local holder = ReplicatedStorage:FindFirstChild("ApprovedFloorReliefTemplates")
    if not holder or not holder:IsA("Folder") or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local relief = holder:FindFirstChild(name)
    if not relief or not relief:IsA("Model")
        or relief:GetAttribute("OwnerVerified") ~= true
        or relief:GetAttribute("CosmeticOnly") ~= true
        or relief:GetAttribute("OriginalFloorRelief3D") ~= true
        or relief:GetAttribute("Original3DAssetId") ~= PremiumFloorReliefAssets.approvedId(name) then
        return nil
    end
    return meshRegionByBounds(relief, regionSize)
end

local function towersFloorProfiles()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedVariantTowersLandmarkTemplates")
    if not holder or not holder:IsA("Folder") or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local machinery = holder:FindFirstChild("Machinery")
    if not machinery or not machinery:IsA("Model")
        or machinery:GetAttribute("OwnerVerified") ~= true
        or machinery:GetAttribute("CosmeticOnly") ~= true
        or machinery:GetAttribute("OriginalTowersMachinery3D") ~= true
        or machinery:GetAttribute("Original3DAssetId") ~= 72143366927826 then
        return nil
    end
    -- The canopy and the twelve-sided core are separate material regions.
    return meshRegionByBounds(machinery, Vector3.new(7.36, 1.0, 7.36)),
        meshRegionByBounds(machinery, Vector3.new(5.30, 24, 5.28))
end

local function addFloorChevron(decor, name, facing, profile, style, color, alpha)
    for side = -1, 1, 2 do
        -- Separate the wing surfaces where they meet at the tip.
        local pose = facing * CFrame.new(side * style.spread, side * 0.003, 0)
            * CFrame.Angles(0, side * style.angle, 0)
        local mark = fitDecorMesh(profile, name .. "_" .. tostring(side), pose,
            style.size, color, VisualTheme.Materials.Glow)
        mark.Transparency = alpha
        mark.Parent = decor
    end
end

-- Each approved floor relief has a continuous bevelled base in one material region.
local FLOOR_RELIEF_BASE_REGIONS = {
    Classic = Vector3.new(8.00, 0.12, 4.34),
    Towers = Vector3.new(10.22, 0.12, 0.94),
    Crossroads = Vector3.new(3.50, 0.12, 0.66),
    Orbital = Vector3.new(5.42, 0.168, 1.08),
    Harbor = Vector3.new(7.55, 0.12, 2.74),
}

local function addVariantFloorLanguage(decor, base, variant, theme, sweptProfile, floorProfile)
    local center = base.Position

    if variant.Id == "Classic" then
        local gridThickness = 0.05
        local gridY = ArenaPresentation.deckArtOffset(base, gridThickness) + 0.015
        local xLineSize = Vector3.new(0.16, gridThickness, variant.BaseSize.Z - 14)
        local zLineSize = Vector3.new(variant.BaseSize.X - 14, gridThickness, 0.16)
        for _, i in ipairs({-2, -1, 1, 2}) do
            local color = i % 2 == 0 and theme.Secondary or theme.Accent
            local xLine = fitDecorMesh(
                sweptProfile,
                "ClassicGridX" .. tostring(i),
                CFrame.new(center + Vector3.new(i * 16, gridY, 0)),
                xLineSize,
                color,
                VisualTheme.Materials.Glow
            )
            xLine.Transparency = 0.54
            xLine.Parent = decor

            -- Lift the crossing rail slightly while keeping both axes below sweep warnings.
            local zLine = fitDecorMesh(
                sweptProfile,
                "ClassicGridZ" .. tostring(i),
                CFrame.new(center + Vector3.new(0, gridY + 0.008, i * 16)),
                zLineSize,
                color,
                VisualTheme.Materials.Glow
            )
            zLine.Transparency = 0.54
            zLine.Parent = decor
        end

        -- Four restrained, flush floor chevrons guide new players toward
        -- the reachable tier-one terraces (jump from floor to their tops).
        -- They avoid orange/red hazard colors, cast no shadows and cannot
        -- obscure collision or intercept touch controls.
        local routeDirections = {
            Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
            Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        }
        local entryStyle = {size = Vector3.new(0.15, 0.05, 1.35), spread = 0.36, angle = math.rad(36)}
        for routeIndex, direction in ipairs(routeDirections) do
            -- Outside the raised tiers, adjacent to each cardinal entry
            -- spawn. The arrow points IN toward the first reachable deck;
            -- avoid marking low headroom directly below the transfers.
            local position = center + direction * 32
                + Vector3.new(0, 1.28, 0)
            local facing = CFrame.lookAt(position,
                position - direction, Vector3.yAxis)
            addFloorChevron(decor, "ClassicEntryChevron" .. routeIndex, facing, floorProfile,
                entryStyle, routeIndex % 2 == 0 and theme.Secondary or theme.Accent, 0.47)
        end
    elseif variant.Id == "Towers" then
        local plateProfile, coreProfile = towersFloorProfiles()
        local plateSize = Vector3.new(17, 0.08, 17)
        local coreSize = Vector3.new(5.5, 0.10, 5.5)
        local plateY = ArenaPresentation.deckArtOffset(base, plateSize.Y) + 0.015
        -- Keep the translucent core just above the plate to avoid surface overlap.
        local coreRise = (plateSize.Y + coreSize.Y) * 0.5 + 0.006
        local pads = {
            Vector3.new(-28, plateY, -28),
            Vector3.new(28, plateY, -28),
            Vector3.new(-28, plateY, 28),
            Vector3.new(28, plateY, 28),
        }
        for i, offset in ipairs(pads) do
            local pose = CFrame.new(center + offset)
            local plate = fitDecorMesh(
                plateProfile,
                "TowerGroundPlate" .. i,
                pose,
                plateSize,
                theme.Surface:Lerp(
                    i % 2 == 0 and theme.Secondary or theme.Accent, 0.24
                ),
                theme.PanelMaterial or Enum.Material.Metal
            )
            plate.Transparency = 0.34
            plate.Parent = decor

            local core = fitDecorMesh(
                coreProfile,
                "TowerGroundCore" .. i,
                pose * CFrame.new(0, coreRise, 0),
                coreSize,
                theme.Accent,
                VisualTheme.Materials.Glow
            )
            core.Transparency = 0.74
            core.Parent = decor
        end

        -- Four floor chevrons guide the approach to the first tower decks.
        local approaches = {
            {-1, -1}, {1, -1}, {-1, 1}, {1, 1},
        }
        local ascentStyle = {size = Vector3.new(0.14, 0.055, 1.25), spread = 0.37, angle = math.rad(34)}
        for index, signs in ipairs(approaches) do
            local x, z = signs[1], signs[2]
            local origin = center + Vector3.new(x * 10, 1.22, z * 23)
            local firstDeck = center + Vector3.new(x * 6, 1.22, z * 14)
            local facing = CFrame.lookAt(origin, firstDeck, Vector3.yAxis)
            addFloorChevron(decor, "TowerAscentChevron" .. index, facing, floorProfile,
                ascentStyle, index % 2 == 0 and theme.Accent or theme.Secondary, 0.47)
        end
    elseif variant.Id == "Crossroads" then
        local laneWidth, laneThickness = 13, 0.08
        local hubWidth, hubThickness = 22, 0.10
        -- Keep the far ends at 53 studs and tuck the other ends under the hub.
        local inner, outer = hubWidth * 0.5 - 0.25, 53
        local laneLength, laneCenter = outer - inner, (outer + inner) * 0.5
        local laneY = ArenaPresentation.deckArtOffset(base, laneThickness) + 0.015
        local northSouth = Vector3.new(laneWidth, laneThickness, laneLength)
        local eastWest = Vector3.new(laneLength, laneThickness, laneWidth)
        local laneDefs = {
            {size = northSouth, offset = Vector3.new(0, laneY, -laneCenter)},
            {size = northSouth, offset = Vector3.new(0, laneY, laneCenter)},
            {size = eastWest, offset = Vector3.new(-laneCenter, laneY, 0)},
            {size = eastWest, offset = Vector3.new(laneCenter, laneY, 0)},
        }
        for i, def in ipairs(laneDefs) do
            local lane = fitDecorMesh(
                floorProfile,
                "CrossroadLaneFill" .. i,
                CFrame.new(center + def.offset),
                def.size,
                theme.Surface:Lerp(theme.Detail, 0.36),
                theme.PanelMaterial or Enum.Material.Metal
            )
            lane.Transparency = 0.38
            lane.Parent = decor
        end

        -- Flux Relay navigation is physically readable from the floor.
        -- Keep the chevrons above the lanes and close the gap at their tips.
        local relayStyle = {size = Vector3.new(0.13, 0.05, 0.95), spread = 0.28, angle = math.rad(34)}
        local relayY = laneY + (laneThickness + relayStyle.size.Y) * 0.5 + 0.008
        local relayCenter = center + Vector3.new(0, relayY, 0)
        for laneIndex = 1, 4 do
            local direction = laneIndex == 1 and Vector3.new(1, 0, 0)
                or (laneIndex == 2 and Vector3.new(0, 0, 1)
                    or (laneIndex == 3 and Vector3.new(-1, 0, 0)
                        or Vector3.new(0, 0, -1)))
            for stepIndex = 1, 3 do
                local distance = 23 + stepIndex * 3.15
                local position = relayCenter + direction * distance
                local facing = CFrame.lookAt(position, relayCenter)
                addFloorChevron(decor, "FluxRouteChevron" .. laneIndex .. "_" .. stepIndex,
                    facing, floorProfile, relayStyle, stepIndex == 3 and theme.Accent or theme.Secondary,
                    0.36 + (3 - stepIndex) * 0.06)
            end
        end

        local hubY = ArenaPresentation.deckArtOffset(base, hubThickness) + 0.02
        local hub = fitDecorMesh(
            floorReliefRegion("AnchorBolt", Vector3.new(4.05, 0.60, 4.05)),
            "CrossroadHubMark",
            CFrame.new(center + Vector3.new(0, hubY, 0)),
            Vector3.new(hubWidth, hubThickness, hubWidth),
            theme.Detail:Lerp(theme.Secondary, 0.24),
            theme.PanelMaterial or Enum.Material.Metal
        )
        hub.Transparency = 0.32
        hub.Parent = decor
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
        local thickness = 0.055
        local quayY = ArenaPresentation.deckArtOffset(base, thickness) + 0.02
        for index, lane in ipairs(lanes) do
            local size = lane.alongX and Vector3.new(52, thickness, 0.45)
                or Vector3.new(0.45, thickness, 52)
            local line = fitDecorMesh(
                floorProfile, "HarborQuayInlay" .. index,
                CFrame.new(center + Vector3.new(lane.x, quayY, lane.z)),
                size,
                index % 2 == 0 and theme.Accent or theme.Secondary,
                theme.PanelMaterial
            )
            line.Transparency = 0.38
            line.Parent = decor
        end
    elseif variant.Id == "Orbital" then
        local hubDiameter = 14
        local outerRadius = 25
        -- End under the outer edge of the ring, leaving its opening clear.
        local innerRadius = hubDiameter * 0.5 - 0.2
        local spokeSize = Vector3.new(outerRadius - innerRadius, 0.07, 0.20)
        local spokeCenter = (innerRadius + outerRadius) * 0.5
        -- The raised ground modules finish above the inset deck.
        local spokeY = ArenaPresentation.deckArtOffset(base, spokeSize.Y) + 0.02
        for i = 0, 7 do
            local angle = math.rad(i * 45)
            local position = center + Vector3.new(
                math.cos(angle) * spokeCenter,
                spokeY,
                math.sin(angle) * spokeCenter
            )
            local spoke = fitDecorMesh(
                sweptProfile,
                "OrbitalSpoke" .. tostring(i + 1),
                CFrame.new(position) * CFrame.Angles(0, -angle, 0),
                spokeSize,
                i % 2 == 0 and theme.Accent or theme.Secondary,
                VisualTheme.Materials.Glow
            )
            spoke.Transparency = 0.52
            spoke.Parent = decor
        end

        local markSize = Vector3.new(hubDiameter, 0.10, hubDiameter)
        local markY = ArenaPresentation.deckArtOffset(base, markSize.Y) + 0.02
        local markPose = CFrame.new(center + Vector3.new(0, markY, 0))
        local coreMark = fitDecorMesh(
            orbitalReactorNodeRegion(Vector3.new(4.11, 0.39, 4.11)),
            "OrbitalCoreMark",
            markPose,
            markSize,
            theme.Detail:Lerp(theme.Accent, 0.28),
            theme.PanelMaterial or Enum.Material.Metal
        )
        if coreMark:IsA("Part") then
            coreMark.Shape = Enum.PartType.Cylinder
            coreMark.Size = Vector3.new(markSize.Y, markSize.X, markSize.Z)
            coreMark.CFrame = markPose * CFrame.Angles(0, 0, math.pi * 0.5)
        end
        coreMark.Transparency = 0.34
        coreMark.Parent = decor
    end

    local panelSize = Vector3.new(15, 0.05, 9)
    -- Clear the sculpted client ground tiles as well as the native finish.
    local panelY = ArenaPresentation.deckArtOffset(base, panelSize.Y) + 0.03
    local panelOffsetX = math.max(18, (variant.BaseSize.X * 0.5) - 17)
    local panelOffsetZ = math.max(18, (variant.BaseSize.Z * 0.5) - 17)
    local panelRotation = variant.Id == "Orbital" and 45
        or (variant.Id == "Crossroads" and 0 or 8)
    local panelOffsets = {
        Vector3.new(-panelOffsetX, panelY, -panelOffsetZ),
        Vector3.new(panelOffsetX, panelY, -panelOffsetZ),
        Vector3.new(-panelOffsetX, panelY, panelOffsetZ),
        Vector3.new(panelOffsetX, panelY, panelOffsetZ),
    }
    for i, offset in ipairs(panelOffsets) do
        local pose = CFrame.new(center + offset)
            * CFrame.Angles(0, math.rad((i % 2 == 0 and -1 or 1) * panelRotation), 0)
        local maintenance = fitDecorMesh(
            floorProfile,
            "FloorMaintenancePanel" .. i,
            pose,
            panelSize,
            theme.Surface:Lerp(theme.Structure, 0.38),
            theme.PanelMaterial or VisualTheme.Materials.Panel
        )
        maintenance.Transparency = 0.32
        maintenance.Parent = decor
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
    local atRim = platform:GetAttribute("PerimeterStep") ~= nil
        or platform:GetAttribute("BranchStep") ~= nil
        or platform:GetAttribute("CrosslinkRoute") ~= nil
    -- The grounded riser reaches the arena floor. Place the band below
    -- the sculpted fascia near the landing surface, rather than at its foot.
    local height = if atRim then size.Y * 0.5 - 1.02 else -size.Y * 0.5 - 0.47
    local rimSize = Vector3.new(
        size.X + (alongX and 0.28 or edgeOverhang),
        0.14,
        size.Z + (alongX and edgeOverhang or 0.28)
    )
    local rimPose = platform.CFrame * CFrame.new(0, height, 0)
    local glow = RouteSignalGeometry.fit(edgeBand, rimPose, rimSize, nil, alongX)
    if not glow then
        -- Match the approved mesh footprint and position exactly so missing
        -- assets never cause a shifted or differently sized route cue.
        glow = decorPart(nil, name, rimSize, rimPose.Position,
            color, VisualTheme.Materials.Glow)
        glow.CFrame = rimPose
    end
    glow.Name = name
    glow.Material = VisualTheme.Materials.Glow
    glow.Color = color
    glow.Transparency = transparency
    glow.Parent = decor
end

local function addPlatformFinish(decor, platform, index, theme, panelProfile, underdeckSignal, lattice,
    frameFallback, bevelProfile, harborAlongX, elevatedTrim, harborSkywayBeam, bevelFallback)
    -- Keep the panel's authored size and axes for route-mask and shrink checks.
    local panelAlongX = panelProfile and panelProfile.Size.X > panelProfile.Size.Z
    local topPanel = fitDecorMesh(
        panelProfile,
        "PlatformPanel" .. index,
        platform.CFrame * CFrame.new(0, platform.Size.Y * 0.5 + 0.055, 0),
        Vector3.new(
            math.max(1, platform.Size.X - 0.8),
            0.10,
            math.max(1, platform.Size.Z - 0.8)
        ),
        theme.Surface:Lerp(theme.Detail, 0.48),
        theme.PanelMaterial or VisualTheme.Materials.Panel,
        panelAlongX
    )
    if topPanel:IsA("MeshPart") then
        topPanel:SetAttribute("OriginalPlatformPanel3D", true)
    end
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
    local promenadeStep = platform:GetAttribute("PromenadeStep")
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
    topPanel.Parent = decor

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
    local useBridgeBevel = bevelProfile and bevelProfile.Name == "SweptCrossbeam"
    local skywayBeam = harborSkywayBeam and harborSkywayBeam.MeshId ~= "" and harborSkywayBeam
    local bevelAlongX = bevelProfile and bevelProfile.Size.X > bevelProfile.Size.Z
    for edgeIndex, spec in ipairs(edgeSpecs) do
        local size = spec[1]
        if edgeIndex > 2 then size = Vector3.new(size.Z, size.Y, size.X) end
        local where = Vector3.new(
            platform.Position.X, 0, platform.Position.Z) + spec[2]
        local yaw = facings[edgeIndex]
        local pose = CFrame.new(where) * CFrame.Angles(0, yaw, 0)
        local bevel
        -- Long edges are X-aligned on a Promenade and Z-aligned on the Spine.
        local longEdge = if skySpineStep then edgeIndex > 2 else edgeIndex <= 2
        local longProfile = (elevatedTrim and longEdge and elevatedTrim.beam)
            or (edgeIndex <= 2 and skywayBeam)
        if longProfile then
            bevel = RouteSignalGeometry.fit(longProfile, pose, size, nil, true)
            if bevel then
                bevel:SetAttribute("OriginalPlatformBevel3D", true)
                bevel:SetAttribute("OriginalElevatedForgedBevel3D", true)
                bevel:SetAttribute("Original3DAssetId", 126298311664881)
            end
        end
        local bridgeBevel = not bevel and useBridgeBevel and bevelProfile:Clone()
        if bridgeBevel then
            bevel = bridgeBevel
            -- Keep the footprint of the native wedge. The swept face
            -- extends downwards to show its facets below the deck lip.
            bevel.Size = bevelAlongX and Vector3.new(size.X, .44, size.Z)
                or Vector3.new(size.Z, .44, size.X)
            bevel.CFrame = CFrame.new(where - Vector3.new(0, .08, 0))
                * CFrame.Angles(0, yaw + (bevelAlongX and 0 or math.pi * .5), 0)
        elseif not bevel and not useBridgeBevel then
            -- Preserve the exact fallback axes and dimensions for the local rim owners.
            local source = bevelProfile or bevelFallback
            -- A closed floor casting follows the existing wedge axes so
            -- the full rim owner can still authenticate either shape.
            local alongX = bevelProfile ~= nil or (source and source.Size.X > source.Size.Z)
            bevel = RouteSignalGeometry.fit(source, pose, size, nil, alongX)
            if bevel then
                bevel:SetAttribute("OriginalPlatformBevel3D", true)
                if harborAlongX ~= nil and bevelProfile then
                    bevel:SetAttribute("Original3DAssetId", 94830155055482)
                end
            end
        end
        if not bevel then
            local wedge = Instance.new("WedgePart")
            wedge.Size = size
            wedge.CFrame = pose
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
    local underFrame
    -- Portal spans already have a separate truss below this frame.
    if elevatedTrim and not PromenadeArchitecture.portalHeight(promenadeStep) then
        underFrame = RouteSignalGeometry.fit(elevatedTrim.lattice, framePose, frameSize, nil, not skySpineStep)
        if underFrame then
            underFrame:SetAttribute("OriginalElevatedLatticeFrame3D", true)
            underFrame:SetAttribute("Original3DAssetId", 106401955318567)
        end
    end
    local deckLattice = not underFrame and lattice and lattice:Clone()
    if deckLattice then
        underFrame = deckLattice
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
    elseif not underFrame then
        -- Preserve the original frame envelope and deck-relative axes so
        -- route chassis and cradles can still claim this exact owner.
        local frameProfile = frameFallback or (elevatedTrim and elevatedTrim.frameFallback)
            or (harborAlongX ~= nil and panelProfile or nil)
        local frameAlongX = frameProfile and frameProfile.Size.X > frameProfile.Size.Z
        underFrame = fitDecorMesh(frameProfile, frameName, framePose, frameSize,
            frameColor, VisualTheme.Materials.Structure, frameAlongX)
    end
    underFrame.Name = frameName
    underFrame.Color = frameColor
    underFrame.Material = VisualTheme.Materials.Structure
    underFrame.Transparency = 0.04
    underFrame:SetAttribute("PremiumArchitecturalSurface", true)
    if underFrame:IsA("MeshPart") then
        underFrame:SetAttribute("OriginalPlatformUnderFrame3D", true)
    end
    underFrame.Parent = decor

    local coreName = "PlatformCoreGlow" .. index
    local coreColor = (index % 2 == 0) and theme.Secondary or theme.Accent
    local coreAlpha = routeTier and (0.72 - math.clamp(routeTier, 1, 4) * 0.04) or 0.56
    local skybridge = platform:GetAttribute("ChaosSkybridge") == true
    local flatSize = Vector3.new(math.max(0.8, size.X * 0.32), 0.12, math.max(0.8, size.Z * 0.32))
    -- Keep the entry ring clear of the frame and the flat rim fallback.
    local signalDrop = platform:GetAttribute("OrbitalEntryLanding") and 0.62 or 0.42
    local flatPose = platform.CFrame * CFrame.new(0, -size.Y * 0.5 - signalDrop, 0)
    local signalSize, signalPose = flatSize, flatPose
    local alongX
    if promenadeLane or skySpineStep or skybridge or harborAlongX ~= nil then
        alongX = if harborAlongX ~= nil then harborAlongX else size.X > size.Z
        local length = (alongX and size.X or size.Z) * 0.62
        -- A narrow Tower Run deck needs more relative width to clear the ribs.
        local width = (alongX and size.Z or size.X) * (skybridge and 0.34 or 0.22)
        signalSize = alongX and Vector3.new(length, 0.30, width)
            or Vector3.new(width, 0.30, length)
        signalPose = platform.CFrame * CFrame.new(0, -size.Y * 0.5 - 0.52, 0)
    end

    local core = RouteSignalGeometry.fit(underdeckSignal, signalPose, signalSize, nil, alongX)
    if not core then
        -- The fallback must occupy the same deck-relative envelope as the
        -- approved mesh. A world-axis flat Part displaced or rotated incorrectly
        -- beneath elevated/turned routes when the mesh was unavailable.
        core = decorPart(nil, coreName, signalSize, signalPose.Position,
            coreColor, VisualTheme.Materials.Glow)
        core.CFrame = signalPose
    end
    core.Name = coreName
    core.Color = coreColor
    core.Material = VisualTheme.Materials.Glow
    core.Transparency = coreAlpha
    core.Parent = decor
end

local function addPlatformSupports(decor, base, platform, index, theme, shaft, assetId)
    local platformBottom = platform.Position.Y - platform.Size.Y * 0.5
    local footY = PlatformIdentityLodRules.platformSupportFootY(base, platform)
    local supportHeight = platformBottom - footY
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

        -- Keep the authored axes for client overlays and bridge contraction.
        local shaftAlongX = shaft and shaft.Size.X > shaft.Size.Z
        for supportIndex, offset in ipairs(supportOffsets) do
            -- Transform once into world space. The cosmetic support is
            -- vertical but inherits the deck yaw for its sculpted facets.
            local worldOffset = platform.CFrame:PointToWorldSpace(offset)
            local supportPose = CFrame.new(
                worldOffset.X, footY + supportHeight * 0.5, worldOffset.Z
            ) * platform.CFrame.Rotation
            local support = fitDecorMesh(
                shaft,
                "PlatformSupport" .. index .. "_" .. supportIndex,
                supportPose,
                Vector3.new(supportWidth, supportHeight, supportWidth),
                supportColor,
                VisualTheme.Materials.Structure,
                shaftAlongX
            )
            support.Transparency = 0.14
            if support:IsA("MeshPart") then
                support:SetAttribute("OriginalPlatformSupport3D", true)
                support:SetAttribute("Original3DAssetId", assetId)
            end
            support.Parent = decor
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

    local function sculpt(part, profile)
        CollectionService:AddTag(part, profile)
        return part
    end

    local function detail(profile, name, pose, size, color, material)
        local finish = decorPart(nil, name, size, pose.Position, color, material)
        finish.CFrame = pose
        return sculpt(finish, profile)
    end

    local function mountSignGui(panel, gui)
        -- The label uses the original face even if the client masks the
        -- backing and fits a beveled mesh with a different local axis.
        local surface = decorPart(nil, "SignTextSurface", panel.Size, panel.Position, panel.Color)
        surface.CFrame = panel.CFrame
        surface.Transparency = 1
        gui.Parent = surface
        surface.Parent = panel
    end

    local cast = "LobbySculptedCasting"
    local shaft = "LobbySculptedShaft"
    local lobbyLanes = {
        {name = "LobbyLaneNorth", size = Vector3.new(2.4, 0.08, 23), offset = Vector3.new(0, 1.16, -24),
            color = VisualTheme.Accents.Cyan},
        {name = "LobbyLaneWest", size = Vector3.new(23, 0.08, 2.4), offset = Vector3.new(-24, 1.16, 0),
            color = VisualTheme.Accents.Cyan},
        {name = "LobbyLaneEast", size = Vector3.new(23, 0.08, 2.4), offset = Vector3.new(24, 1.16, 0),
            color = VisualTheme.Accents.Violet},
    }

    for _, def in ipairs(lobbyLanes) do
        local lane = detail(
            cast, def.name,
            CFrame.new(config.LobbyCenter + def.offset), def.size,
            def.color, VisualTheme.Materials.Glow
        )
        lane.Parent = decor
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
        sculpt(panel, cast)

        local gui = Instance.new("SurfaceGui")
        gui.Name = "LoopPanelGui"
        gui.Face = Enum.NormalId.Top
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 34
        gui.LightInfluence = 0
        gui.AlwaysOnTop = false
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
        mountSignGui(panel, gui)
    end

    local centerPlatform = part(
        decor,
        "CenterPlatform",
        Vector3.new(24, 1.2, 24),
        config.LobbyCenter + Vector3.new(0, 1.45, 0),
        VisualTheme.World.SurfaceRaised,
        VisualTheme.Materials.Structure
    )

    -- Four cosmetic forged skirts conceal the platform's exposed square
    -- sides without replacing the authoritative walkable collision Part.
    -- Client-side approved swept meshes have a native-Part fallback.
    for side = 1, 4 do
        local alongX = side <= 2
        local skirt = detail(
            "LobbySculptedSwept",
            "CenterPlatformForgedSkirt" .. side,
            CFrame.new(config.LobbyCenter + Vector3.new(
                alongX and 0 or (side == 3 and -12.12 or 12.12),
                1.45,
                alongX and (side == 1 and -12.12 or 12.12) or 0
            )),
            alongX and Vector3.new(23.6, 0.84, 0.38)
                or Vector3.new(0.38, 0.84, 23.6),
            VisualTheme.World.Metal,
            VisualTheme.Materials.Structure
        )
        skirt.Parent = decor
    end

    local centerGlow = detail(
        cast, "CenterGlow",
        CFrame.new(config.LobbyCenter + Vector3.new(0, 2.08, 0)),
        Vector3.new(7.5, 0.22, 7.5),
        VisualTheme.Accents.Cyan, VisualTheme.Materials.Glow
    )
    centerGlow.Parent = decor
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

        local cap = detail(
            cast, "PylonGlow" .. i,
            CFrame.new(pylon.Position + Vector3.new(0, 5.25, 0)),
            Vector3.new(2.8, 0.55, 2.8),
            VisualTheme.Accents.Violet, VisualTheme.Materials.Glow
        )
        cap.Parent = decor
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

    sculpt(leftColumn, shaft)
    sculpt(rightColumn, shaft)
    sculpt(archTop, "LobbySculptedSwept")

    local gateInnerGlow = detail(
        cast, "ArenaGateInnerGlow",
        CFrame.new(archCenter + Vector3.new(0, 11.45, -1.62)),
        Vector3.new(17.8, 0.34, 0.48),
        VisualTheme.Accents.Cyan, VisualTheme.Materials.Glow
    )
    gateInnerGlow.Parent = decor
    gateInnerGlow.Transparency = 0.16
    gateInnerGlow.CanCollide = false
    gateInnerGlow.CanTouch = false
    gateInnerGlow.CanQuery = false

    for side = -1, 1, 2 do
        for index = 1, 2 do
            local indicator = detail(
                shaft,
                (side < 0 and "ArenaGateIndicatorL" or "ArenaGateIndicatorR") .. index,
                CFrame.new(archCenter + Vector3.new(
                    side * (8.45 + index * 0.52), 5.3 + index * 3.8, -1.60)),
                Vector3.new(0.34, 3.6, 0.34),
                index == 1 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
                VisualTheme.Materials.Glow
            )
            indicator.Parent = decor
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
    mountSignGui(archTop, gateGui)

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

    local stageFront = centerPlatform.Size.Z * 0.5
    local guideY = centerPlatform.Size.Y * 0.5 + 0.075
    local tip = centerPlatform.CFrame:PointToWorldSpace(
        Vector3.new(0, guideY, stageFront - 1.1))
    for side = -1, 1, 2 do
        local shoulder = centerPlatform.CFrame:PointToWorldSpace(
            Vector3.new(side * 2.25, guideY, stageFront - 3.75))
        local arm = detail(
            "LobbySculptedSwept",
            side < 0 and "StageExitChevronLeft" or "StageExitChevronRight",
            CFrame.lookAt(shoulder:Lerp(tip, 0.5), tip),
            Vector3.new(0.34, 0.08, (tip - shoulder).Magnitude),
            VisualTheme.Accents.Cyan, VisualTheme.Materials.Glow
        )
        arm.Transparency = 0.24
        arm.Parent = decor
    end

    -- Start beyond the forged stage lip and continue to the gate landing.
    local runwayStart = centerPlatform.Position + arenaDirection * (stageFront + 0.55)
    local runwayEnd = archCenter + arenaDirection * 5
    local runwayLength = (runwayEnd - runwayStart):Dot(arenaDirection)
    local midpoint = runwayStart:Lerp(runwayEnd, 0.5)
    local runwayCenter = Vector3.new(midpoint.X, floor.Position.Y + 1.18, midpoint.Z)
    local runway = decorPart(
        decor,
        "ArenaRunway",
        Vector3.new(14, 0.10, runwayLength),
        runwayCenter,
        VisualTheme.World.Deep:Lerp(VisualTheme.World.SurfaceRaised, 0.22),
        VisualTheme.Materials.Panel
    )
    runway.Transparency = 0.02
    runway.CanCollide = false
    sculpt(runway, cast)

    local railOffset = runway.Size.X * 0.5 - 0.60
    local runwayTop = runway.Size.Y * 0.5
    local runwayHalfLength = runway.Size.Z * 0.5
    for side = -1, 1, 2 do
        local railSide = side < 0 and "Left" or "Right"
        local accent = side < 0 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet
        local railFrame = runway.CFrame * CFrame.new(side * railOffset, runwayTop, 0)
        local rail = detail(
            cast, "ArenaRunwayRail" .. railSide,
            railFrame * CFrame.new(0, 0.05, 0),
            Vector3.new(0.30, 0.12, runway.Size.Z), accent, VisualTheme.Materials.Glow
        )
        rail.Parent = decor
        rail.Transparency = 0.16

        for endSign = -1, 1, 2 do
            local endName = endSign < 0 and "Stage" or "Portal"
            -- Both fittings stay inside the deck edge and outboard of
            -- the animated sweep. Only the terminal covers the light.
            local clamp = detail(
                "LobbySculptedSwept", "ArenaRunwayClamp" .. railSide .. endName,
                railFrame * CFrame.new(0, 0.031, endSign * runwayHalfLength * 0.46),
                Vector3.new(0.72, 0.10, 0.58),
                VisualTheme.World.MetalLight, VisualTheme.Materials.Structure
            )
            clamp.Parent = decor

            local cap = detail(
                "LobbySculptedSwept", "ArenaRunwayEndCap" .. railSide .. endName,
                railFrame * CFrame.new(0, 0.055, endSign * (runwayHalfLength - 0.54)),
                Vector3.new(0.88, 0.15, 1.08),
                VisualTheme.World.MetalLight:Lerp(accent, 0.22), VisualTheme.Materials.Structure
            )
            cap.Parent = decor
        end
    end

    local footSize = Vector3.new(0.76, 0.18, 0.78)
    local jointSize = Vector3.new(0.98, 0.78, 0.88)
    local ribOffset = runway.Size.X * 0.5 + 0.35
    for i = 1, 4 do
        local support = i == 1 and centerPlatform or floorInset
        local z = i == 1 and (stageFront - footSize.Z * 0.5 - 0.11) or (7 + i * 4.7)
        local height = 6.5 + (i * 0.45)
        local slabTop = support.Position.Y + support.Size.Y * 0.5
        local ribStart = slabTop + 0.08
        local ribEnd = config.LobbyCenter.Y + 1.1 + height
        for side = -1, 1, 2 do
            local suffix = (side < 0 and "L" or "R") .. i
            local x = runway.Position.X + side * ribOffset
            local worldZ = config.LobbyCenter.Z + z
            -- The first portal sits on the raised stage. The other three
            -- land on the inset, with each casting outside the runway.
            local foot = detail(
                cast, "ArenaApproachFoot" .. suffix,
                CFrame.new(x + side * 0.05, slabTop + 0.06, worldZ),
                footSize, VisualTheme.World.MetalLight, VisualTheme.Materials.Structure
            )
            foot.Parent = decor
            local rib = detail(
                shaft, "ArenaApproachRib" .. suffix,
                CFrame.new(x, (ribStart + ribEnd) * 0.5, worldZ),
                Vector3.new(0.55, ribEnd - ribStart, 0.55),
                VisualTheme.World.Metal, VisualTheme.Materials.Structure
            )
            rib.Transparency = 0.04
            rib.Parent = decor

            -- Seat the crossbar in the collar while exposing its upper face.
            local joint = detail(
                "LobbySculptedSwept", "ArenaApproachJoint" .. suffix,
                CFrame.new(x + side * 0.05, ribEnd - 0.23, worldZ),
                jointSize, VisualTheme.World.MetalLight, VisualTheme.Materials.Structure
            )
            joint.Parent = decor
        end

        local topRib = detail(
            shaft, "ArenaApproachRibTop" .. i,
            CFrame.new(runway.Position.X, ribEnd, config.LobbyCenter.Z + z)
                * CFrame.Angles(0, 0, math.rad(90)),
            Vector3.new(0.42, 14.9, 0.55),
            i % 2 == 0 and VisualTheme.Accents.Violet or VisualTheme.Accents.Cyan,
            VisualTheme.Materials.Glow
        )
        topRib.Parent = decor
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
    sculpt(sign, cast)

    local surface = Instance.new("SurfaceGui")
    surface.Name = "TitleGui"
    surface.Face = Enum.NormalId.Back
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 45
    surface.AlwaysOnTop = false
    mountSignGui(sign, surface)

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
        local spine = detail(
            shaft, "LobbyFrameSpine" .. i,
            CFrame.new(config.LobbyCenter + offset),
            Vector3.new(1.6, 14, 1.6),
            VisualTheme.World.Metal, VisualTheme.Materials.Structure
        )
        spine.Parent = decor
        spine.Transparency = 0.03

        local band = detail(
            cast, "LobbyFrameBand" .. i,
            CFrame.new(spine.Position + Vector3.new(0, 5.3, 0)),
            Vector3.new(3.6, 0.34, 3.6),
            (i % 2 == 0) and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
            VisualTheme.Materials.Glow
        )
        band.Parent = decor
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
        local segment = detail(
            cast, "LobbyHaloSegment" .. i,
            CFrame.new(position) * CFrame.Angles(0, -angle, 0),
            Vector3.new(4.8, 0.22, 0.48),
            (i % 3 == 0) and VisualTheme.Accents.Magenta
                or ((i % 2 == 0) and VisualTheme.Accents.Violet or VisualTheme.Accents.Cyan),
            VisualTheme.Materials.Glow
        )
        segment.Parent = decor
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
        sculpt(panel, cast)

        local rail = detail(
            cast, "LobbyIdentityRail" .. i,
            CFrame.new(panel.Position + Vector3.new(0, -2.0, 0)),
            Vector3.new(12.4, 0.24, 0.60),
            def.color, VisualTheme.Materials.Glow
        )
        rail.Parent = decor
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
        mountSignGui(panel, gui)
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
    StructureRetrofit.buildLobby(decor, config.LobbyCenter, centerPlatform)

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
    local underdeckSpars = approvedMeshRegion(chassis, "UnderdeckSpars")
    local wayfinderBase = wayfinderBaseSource()
    local beaconShaft, shaftAssetId = PremiumLargeStructureAssets.shaftProfile(variant.Id)
    -- A loaded polygonal shaft from another approved column can fill the
    -- same elevated-route support envelope while the arena's shaft loads.
    local routeShaft, routeShaftAssetId = beaconShaft, shaftAssetId
    if not routeShaft then
        for _, sourceVariant in ipairs(arenaVariants.Order or {}) do
            if sourceVariant ~= variant.Id then
                routeShaft, routeShaftAssetId = PremiumLargeStructureAssets.shaftProfile(sourceVariant)
                if routeShaft then break end
            end
        end
    end
    local rimBevel = floorReliefRegion("Harbor", Vector3.new(2.50, 0.16, 0.16))
    local bevelCasting = floorReliefRegion("Classic", FLOOR_RELIEF_BASE_REGIONS.Classic)
    addArenaFoundation(decor, config, variant, theme, sweptProfile, beaconShaft)
    -- Original modular top deck: 6 x 6 textured industrial panels,
    -- recessed service grooves and volumetric undercarriage fins.
    -- All floor art follows the shrinking REAL base and is noncolliding.
    ArenaGroundArchitecture.build(decor, base, variant.Id, theme, underdeckLattice, sweptProfile,
        wayfinderBase, bevelCasting)
    local orbitalLens = orbitalReactorNodeRegion(Vector3.new(2.96, 2.9503, 2.96))
    local rotorAssetId = HorizonMonumentGeometry.assetId("rotor")
    local perimeterRotor = approvedHorizonRegion(
        "ApprovedPerimeterRotorTemplates", "Rotor", "OriginalPerimeterRotor3D",
        rotorAssetId, Vector3.new(2.56, .72, 2.56))
    local detailProfiles = {
        bevel = {part = bevelCasting, assetId = HorizonMonumentGeometry.assetId("bevel")},
        beam = {part = sweptProfile, assetId = 126298311664881},
        underframe = {part = underdeckSpars, assetId = 106401955318567},
        cast = {part = wayfinderBase, assetId = 88962643359267},
        lens = {part = orbitalLens, assetId = 104654294187035},
        ring = {part = orbitalReactorNodeRegion(Vector3.new(4.11, 0.39, 4.11)),
            assetId = 104654294187035},
        rotor = {part = perimeterRotor, assetId = rotorAssetId},
        shaft = {part = beaconShaft, assetId = shaftAssetId},
        signal = {part = rimBevel, assetId = PremiumFloorReliefAssets.approvedId("Harbor")},
    }
    addPerimeterStations(decor, config, variant, theme, {
        plate = detailProfiles.cast,
        signal = detailProfiles.beam,
        lens = detailProfiles.lens,
        rail = {part = rimBevel, assetId = 94830155055482},
        housing = detailProfiles.cast,
        shaft = detailProfiles.shaft,
        turbine = detailProfiles.rotor,
        wing = detailProfiles.beam,
    })
    local horizonTemplates = {
        bevel = bevelCasting,
        beam = sweptProfile,
        cast = wayfinderBase,
        lens = orbitalLens,
        roller = rimBevel and rimBevel.Size.X > rimBevel.Size.Z and rimBevel or nil,
        shaft = beaconShaft,
        rotor = if variant.Id == "Orbital" then perimeterRotor else nil,
        depthHull = approvedHorizonRegion(
            "ApprovedSkylineDepthSculptTemplates", "Roof", "OriginalSkylineDepthSculpt3D",
            HorizonMonumentGeometry.assetId("depthHull"), Vector3.new(11.4, 33.95, 6.94)),
    }
    addDistantSkyline(decor, config, variant, theme, horizonTemplates)
    addArenaSignatureMegastructure(decor, config, variant, theme, horizonTemplates)
    -- Each outboard hero has a lightweight silhouette and per-piece fallbacks.
    HeroArchitecture.build(decor, base, variant.Id, theme, detailProfiles)
    -- Faceted original 3D shells, machined collars, diagonal load spars
    -- and cantilevers on the four EXISTING foundation towers. No physics.
    ArchitecturalCladding.build(decor, base, variant.Id, theme, wayfinderBase, sweptProfile)
    if variant.Id == "Harbor" then
        -- Exterior harbor cranes distinguish the new cargo port without
        -- extra colliders, sound loops or cameras tracking scenic models.
        HarborScenery.build(decor, base, theme, detailProfiles)
    end
    -- Twelve 3D models occupy the now-playable outer districts. They are
    -- cosmetic and LOD managed, not new physical/hazard blocking geometry.
    ArenaDistrictArchitecture.build(decor, base, variant.Id, theme, wayfinderBase, detailProfiles)
    addSouthHorizonMonument(decor, config, variant, theme, horizonTemplates)
    local exteriorCasting = {part = wayfinderBase, assetId = 88962643359267}
    addExteriorCornerRidges(decor, config, variant, theme, exteriorCasting)
    addExteriorSilhouettes(decor, config, variant, theme, {
        shell = {part = bevelCasting,
            assetId = PremiumFloorReliefAssets.approvedId("Classic")},
        roof = exteriorCasting,
        shaft = {part = beaconShaft, assetId = PremiumLargeStructureAssets.approvedId(variant.Id)},
        signal = {part = sweptProfile, assetId = 126298311664881},
    })
    addVariantIdentity(decor, config, variant, theme, wayfinderBase, sweptProfile, beaconShaft)
    addVariantLandmarks(decor, config, variant, theme, wayfinderBase, sweptProfile, beaconShaft)
    -- Faceted exterior machinery over the EXISTING simple skyline markers.
    -- Static beyond the shrinking arena edge, fully noncolliding/LOD-owned.
    StructureRetrofit.buildArena(decor, base, variant.Id, theme, detailProfiles)
    local baseRegion = FLOOR_RELIEF_BASE_REGIONS[variant.Id]
    local floorProfile = baseRegion and floorReliefRegion(variant.Id, baseRegion)
    local monumentProfiles = table.clone(detailProfiles)
    monumentProfiles.shaft = {part = routeShaft, assetId = routeShaftAssetId}
    if floorProfile then
        monumentProfiles.bevel = {part = floorProfile, assetId = PremiumFloorReliefAssets.approvedId(variant.Id)}
    end
    local routeCasting = variant.Id ~= "Harbor" and (floorProfile or bevelCasting) or nil
    local routeChevronProfile = sweptProfile or routeCasting
    -- Only callers that fit the local span explicitly can accept a
    -- roller imported along either horizontal axis.
    local canonicalRim = rimBevel and rimBevel.Size.X > rimBevel.Size.Z and rimBevel or nil
    addVariantFloorLanguage(decor, base, variant, theme, sweptProfile, floorProfile)
    addArenaHologram(decor, config, variant, theme, sweptProfile)

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
    local lookoutEntries, sideLookouts = {}, {}
    for _, definition in ipairs(variant.PromenadePlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end
    -- The new REAL transverse Sky Spine is appended after both historical
    -- promenade lanes; no legacy platform, bridge or AI route ID changes.
    for _, definition in ipairs(variant.SkySpinePlatforms or {}) do
        table.insert(platformDefinitions, definition)
    end

    local promenadeJunctions = {}
    local spineEndpoints = {}
    local promenadeTone = theme.Accent:Lerp(theme.Detail, 0.34)
    local closedDeckCasting = floorProfile or bevelCasting
        or (wayfinderBase and wayfinderBase.MeshId ~= "" and wayfinderBase)
    local elevatedTrimProfiles = {
        beam = sweptProfile,
        lattice = underdeckLattice,
        -- The portal truss has its own owner under this shallow frame.
        frameFallback = closedDeckCasting,
    }
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
            if definition.BranchStep == 4 then
                sideLookouts[definition.BranchRoute] = {part = platform, index = i, offset = definition.offset}
            else
                local forward = Vector3.new(0, 0, definition.offset.Z >= 0 and 1 or -1)
                addRouteChevron(decor, "BranchStepArrow" .. definition.BranchRoute .. "_" .. definition.BranchStep,
                    platform, i, forward, theme.Secondary, BRANCH_CHEVRON, routeChevronProfile)
            end
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
        local orbitalEntry = definition.OrbitalEntryLanding == true
        local glowAlongX = if orbitalEntry then math.abs(definition.offset.X) > math.abs(definition.offset.Z) + 0.01
            elseif lookoutAccess then definition.BranchStep == 4
            else harborAlongX
        if orbitalEntry then
            platform:SetAttribute("OrbitalEntryLanding", true)
        end
        -- Both stripes must clear the exposed sides of the grounded riser.
        local edgeOverhang = if skybridge then 0.42
            elseif definition.PerimeterStep then 1.20
            elseif elevatedRoute or harborLanding or lookoutAccess then 0.96
            else 0.28
        -- While common trim loads, keep the existing deck silhouettes
        -- with the arena's own closed casting or Harbor's load roller.
        local reactorLanding = definition.OrbitalReactorLanding == true
        local trimCasting = if reactorLanding or orbitalEntry then closedDeckCasting else routeCasting
        local signalFallback = if harborLanding then rimBevel else trimCasting
        addPlatformGlow(decor, platform, i, theme, routeTier, edgeBand or signalFallback,
            edgeOverhang, glowAlongX)
        local elevatedTrim = elevatedRoute and elevatedTrimProfiles or nil
        local harborSkywayBeam = definition.HarborSkywayLane and sweptProfile or nil
        local bevelSource = (skybridge and sweptProfile)
            or (harborLanding and rimBevel) or canonicalRim
        -- Use the open lattice in the existing shallow frame envelope
        -- so the landed platform still matches the native trim owners.
        local frameProfile = (reactorLanding and underdeckLattice)
            or underdeckSpars or (orbitalEntry and underdeckLattice)
            or (not elevatedRoute and trimCasting) or nil
        local coreProfile = (orbitalEntry and detailProfiles.ring.part) or underdeckSignal or signalFallback
        addPlatformFinish(decor, platform, i, theme, floorProfile or trimCasting,
            coreProfile,
            (skybridge or harborLanding) and underdeckLattice or nil,
            frameProfile, bevelSource, harborAlongX, elevatedTrim,
            harborSkywayBeam, trimCasting)
        if elevatedRoute or reactorLanding then
            addPlatformSupports(decor, base, platform, i, theme, routeShaft, routeShaftAssetId)
        else
            addPlatformSupports(decor, base, platform, i, theme, beaconShaft, shaftAssetId)
        end
        if definition.PerimeterRoute or definition.BranchRoute or definition.CrosslinkRoute then
            SkyRouteMonuments.cladRisers(decor, platform, i, definition, theme, monumentProfiles)
        end
        -- Real 320-stud arenas need strong visual destinations, not more
        -- small repeated squares. Twelve major route portals stand on
        -- PHYSICAL perimeter ascent decks #1, #4 and #8, not floating
        -- at guessed coordinates. The tower is wholly noncolliding and
        -- every piece follows its actual owning platform through shrink
        -- and collapse; pre-existing danger telegraphs remain authoritative.
        if definition.PerimeterRoute then
            SkyRouteMonuments.decorate(
                decor, platform, i, definition, variant.Id, theme, monumentProfiles, platformDefinitions[i + 1])
        end
        -- Six large native-metal arches visibly frame the actual elevated
        -- 200-stud promenades. Every noncolliding part is owned by its
        -- physical PlatformN, including ShrinkingArena movement/scaling.
        -- None adds a blocking wall beneath the high walkways.
        if definition.SkySpineStep then
            SkySpineArchitecture.decorate(
                decor, platform, i, definition, variant.Id, theme, sweptProfile, monumentProfiles)
            if definition.SkySpineStep == 1 then
                spineEndpoints[1] = platform
            elseif definition.SkySpineStep == 10 then
                spineEndpoints[2] = platform
            end
        end
        if definition.PromenadeLane then
            PromenadeArchitecture.decorate(
                decor, platform, i, definition, variant.Id, theme,
                underdeckLattice, monumentProfiles)

            local step = definition.PromenadeStep
            local lane = definition.PromenadeLane
            if step == 4 then
                promenadeJunctions[lane] = platform
            elseif step == 1 or step == 8 then
                lookoutEntries[(lane - 1) * 2 + (step == 1 and 1 or 2)] = platform
            end
            local arrowName = "PromenadeJumpChevron" .. i .. "_"
            local inset = math.min(5.0, platform.Size.X * 0.24)
            for direction = -1, 1, 2 do
                local forward = platform.CFrame.RightVector * direction
                addRouteChevron(decor, arrowName .. direction, platform, i,
                    forward, promenadeTone, PROMENADE_CHEVRON, routeChevronProfile, forward * inset)
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
            bindLandingBillboard(billboard, platform)
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
            local lens = fitDecorMesh(
                sweptProfile, "PerimeterExitLens" .. definition.PerimeterRoute,
                CFrame.new(platformPosition.X, platformPosition.Y,
                    outerZ + frontSign * 0.22),
                Vector3.new(2.1, 2.1, 0.35),
                theme.Accent:Lerp(theme.Structure, 0.56),
                Enum.Material.Glass
            )
            lens.Parent = decor
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
                forward, theme.Secondary, SPINE_TURN_CHEVRON, routeChevronProfile, forward * (deck.Size.Z * 0.25))
            addSpineExitChevrons(decor, spine, deck, theme.Secondary, routeChevronProfile)
        end
    end

    for route, lookout in pairs(sideLookouts) do
        local deck = lookout.part
        local entry = lookoutEntries[route]
        local forward = Vector3.new(0, 0, lookout.offset.Z >= 0 and 1 or -1)
        local offset
        if entry then
            local delta = (entry.Position - deck.Position) * Vector3.new(1, 0, 1)
            if delta.Magnitude > 0.01 then forward = delta.Unit end
            offset = PromenadeArchitecture.decorateLookoutJoint(
                decor, deck, lookout.index, entry, theme, monumentProfiles.beam, monumentProfiles.bevel)
        end
        addRouteChevron(decor, "BranchStepArrow" .. route .. "_4", deck, lookout.index,
            forward, theme.Secondary, BRANCH_CHEVRON, routeChevronProfile, offset)
    end

    -- Put the branch cue on the takeoff side of the fork, facing its
    -- physical first landing. The separate ridge cue keeps its own axis.
    local perimeterCount = #variant.PerimeterPlatforms
    for branchIndex, definition in ipairs(variant.BranchPlatforms or {}) do
        if definition.BranchStep ~= 1 then continue end
        local route = definition.BranchRoute
        local forkIndex = #variant.Platforms + (route - 1) * perimeterCount / 4
            + definition.BranchParentStep
        local landingIndex = #variant.Platforms + perimeterCount + branchIndex
        local fork = platforms:FindFirstChild("Platform" .. forkIndex)
        local landing = platforms:FindFirstChild("Platform" .. landingIndex)
        if not (fork and landing) then continue end
        local delta = (landing.Position - fork.Position) * Vector3.new(1, 0, 1)
        if delta.Magnitude < 0.01 then continue end
        local forward = delta.Unit
        local offset = forward * (math.min(fork.Size.X, fork.Size.Z) * 0.24)
        addRouteChevron(decor, "BranchForkArrow" .. route, fork, forkIndex,
            forward, theme.Secondary, FORK_CHEVRON, routeChevronProfile, offset)
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
        OrbitalHelix.build(arena, variant, config.ArenaCenter, theme, {
            lattice = underdeckLattice,
            spars = underdeckSpars,
            forged = sweptProfile,
            casting = wayfinderBase,
            floor = {part = floorProfile, assetId = PremiumFloorReliefAssets.approvedId("Orbital")},
        })
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
                PERIMETER_STEP_CHEVRON, routeChevronProfile, forward * 2.4)
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
        local lens = fitDecorMesh(
            orbitalLens, "OuterRouteSignalLens" .. route,
            CFrame.new(beaconPoint + Vector3.new(0, 18.5, 0)),
            Vector3.new(3.8, 3.8, 3.8),
            routeColor, Enum.Material.Glass
        )
        if lens:IsA("Part") then
            lens.Shape = Enum.PartType.Ball
        end
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
