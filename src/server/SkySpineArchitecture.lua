-- 200+ stud SKY SPINE interchange / five original 3D identities.
-- Every piece here is DECORATIVE. The real physical ten-deck route is
-- owned exclusively by ArenaVariants/MapBuilder and by ordinary player
-- collision; none of these pieces can create fake bridges or trap avatars.
local RouteSignalGeometry = require("./RouteSignalGeometry")
local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
local horizonModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonModule then require(horizonModule)
    else require("../shared/HorizonMonumentGeometry")

local SkySpineArchitecture = {}

local function detail(deck, index, name, size, cf, color, material, kind, mesh, inlaySide, alongX)
    local frame = deck.CFrame * cf
    local item = RouteSignalGeometry.fit(mesh, frame, size, inlaySide, alongX)
    if not item then
        item = Instance.new(kind or "Part")
        item.Size = size
        item.CFrame = frame
        item.TopSurface = Enum.SurfaceType.Smooth
        item.BottomSurface = Enum.SurfaceType.Smooth
    end
    item.Name = "SkySpine" .. index .. "_" .. name
    item.Color = color
    item.Material = material or Enum.Material.Metal
    item.Anchored = true
    item.CanCollide = false
    item.CanTouch = false
    item.CanQuery = false
    item.CastShadow = false
    item:SetAttribute("PerimeterPlatformIndex", index)
    item:SetAttribute("SkySpineDecor", true)
    return item
end

function SkySpineArchitecture.decorate(decor, deck, index, def, variant, theme, signalProfile, profiles)
    if not decor or not deck or not deck:IsA("BasePart")
        or type(def) ~= "table" or type(theme) ~= "table"
        or not def.SkySpineStep then return 0 end
    local step = def.SkySpineStep
    local top = deck.Size.Y * 0.5
    local accent = theme.Accent:Lerp(theme.Detail, 0.28)
    local secondary = theme.Secondary:Lerp(theme.Structure, 0.32)
    local metal = theme.Structure:Lerp(theme.Detail, 0.38)
    local count = 0
    local function add(name, size, cf, color, material, kind, mesh, inlaySide, underdeck3D)
        count += 1
        local item = detail(deck, index, name, size,
            cf, color, material, kind, mesh, inlaySide)
        if underdeck3D and item:IsA("MeshPart") then
            item:SetAttribute("OriginalSkySpineUnderdeck3D", true)
            item:SetAttribute("Original3DAssetId", 126298311664881)
        end
        item.Parent = decor
        return item
    end
    local forgedProfile = signalProfile and signalProfile.MeshId ~= "" and signalProfile or nil
    local function underdeck(name, size, cf, color, material)
        add(name, size, cf, color, material, nil, forgedProfile, nil, true)
    end

    -- Actual cross-arena silhouette: repeated, thin surface borders and
    -- a mechanical underslung girder. All rails have zero collision.
    for side = -1, 1, 2 do
        local rail = add("LightedEdge" .. side,
            Vector3.new(0.26, 0.17, deck.Size.Z - 1.1),
            CFrame.new(side * (deck.Size.X * 0.5 - 0.32),
                top + 0.12, 0),
            side < 0 and accent or secondary, Enum.Material.Neon, nil, signalProfile)
        rail.Transparency = 0.36
        underdeck("Undercarriage" .. side,
            Vector3.new(0.66, 0.6, deck.Size.Z - 0.8),
            CFrame.new(side * 3.9, -top - 0.28, 0),
            metal, Enum.Material.CorrodedMetal)
    end
    underdeck("CrossStiffener", Vector3.new(deck.Size.X + 0.6, 0.48, 0.64),
        CFrame.new(0, -top - 0.42, 0),
        secondary, Enum.Material.Metal)

    -- A rhythm of tall roof-height navigational frames makes the third
    -- high bridge recognizable from the 320x320 combat floor. Their
    -- pylons remain OUTSIDE the true 12-stud-wide walking footprint.
    if step == 2 or step == 5 or step == 6 or step == 9 then
        local pylonOffset = 8
        local pylonSize = Vector3.new(1.5, 12.2, 1.7)
        -- Seat the light into the inward face of the pylon. Its raised
        -- face clears the metal so players on the deck can see it.
        local inlayOffset = pylonOffset - pylonSize.X * 0.5 - 0.03
        local shaftSource = profiles and profiles.shaft
        local shaft = shaftSource and shaftSource.part
        if shaft and shaft.MeshId == "" then shaft = nil end
        for side = -1, 1, 2 do
            -- Give the sculpted shaft enough height to seat it inside the beam.
            local shaftSize = Vector3.new(pylonSize.X, 12.65, pylonSize.Z)
            local pylon = shaft and detail(deck, index, "MonumentalPylon" .. side, shaftSize,
                CFrame.new(side * pylonOffset, top + shaftSize.Y * .5, 0),
                metal, Enum.Material.Metal, nil, shaft, nil, shaft.Size.X > shaft.Size.Z)
            if pylon and pylon:IsA("MeshPart") then
                pylon:SetAttribute("OriginalSkySpinePylonShaft3D", true)
                pylon:SetAttribute("Original3DAssetId", shaftSource.assetId)
                pylon.Parent = decor
                count += 1
            else
                if pylon then pylon:Destroy() end
                add("MonumentalPylon" .. side, pylonSize,
                    CFrame.new(side * pylonOffset, top + 6.1, 0), metal, Enum.Material.Metal)
            end
            add("SignalInlay" .. side,
                Vector3.new(0.30, 7.5, 0.42),
                CFrame.new(side * inlayOffset, top + 6.4, 0),
                accent, Enum.Material.Neon, nil, signalProfile, side).Transparency = 0.24
        end
        local crown = detail(deck, index, "InterchangeCrown", Vector3.new(17.2, 1.4, 2.5),
            CFrame.new(0, top + 13, 0), metal, Enum.Material.Metal, nil, forgedProfile)
        local sculpted = crown:IsA("MeshPart")
        if sculpted then
            crown:SetAttribute("OriginalSkySpineCrosshead3D", true)
            crown:SetAttribute("Original3DAssetId", 126298311664881)
        end
        crown.Parent = decor
        count += 1
        add("OverheadPulse", Vector3.new(13, 0.35, 0.7),
            CFrame.new(0, top + 12.7, sculpted and -1.27 or -0.58),
            accent, Enum.Material.Neon, nil, signalProfile).Transparency = 0.22
    end

    -- Five original sky-fortress signatures at the two centre decks,
    -- rather than the same unthemed recolored arch on every map.
    if step == 5 or step == 6 then
        local function command(name, size, offset, color, material, kind, shape)
            local profile = HorizonMonumentGeometry.skySpineCommandProfile(name)
            local source = profiles and profiles[profile]
            local mesh = source and source.part
            if mesh and mesh.MeshId == "" then mesh = nil end
            local cylinder = shape == Enum.PartType.Cylinder
            local alongX = mesh and (cylinder or profile == "beam" or mesh.Size.X > mesh.Size.Z)
            local item = detail(deck, index, name, size, offset, color, material,
                kind, mesh, cylinder and 1 or nil, alongX)
            if item:IsA("MeshPart") then
                item:SetAttribute("OriginalSkySpineCommandFallback3D", true)
                item:SetAttribute("Original3DAssetId", source.assetId)
            elseif shape and item:IsA("Part") then
                item.Shape = shape
            end
            item.Parent = decor
            count += 1
        end
        if variant == "Classic" then
            command("CommandRadar",
                Vector3.new(0.8, 6.8, 6.8),
                CFrame.new(0, top + 17.0, 0)
                    * CFrame.Angles(0, 0, math.rad(24)),
                secondary, Enum.Material.Metal, nil, Enum.PartType.Cylinder)
            command("SurveyBeacon", Vector3.new(1.7, 2.2, 1.7),
                CFrame.new(0, top + 18.1, -0.35),
                accent, Enum.Material.Glass)
        elseif variant == "Towers" then
            command("CargoOverpass", Vector3.new(14, 2.2, 3.7),
                CFrame.new(0, top + 17.3, 0),
                secondary, Enum.Material.DiamondPlate)
            command("HangingTransitCabin", Vector3.new(3.8, 3.8, 3.2),
                CFrame.new(0, top + 14.0, 0),
                accent, Enum.Material.Metal)
        elseif variant == "Crossroads" then
            for side = -1, 1, 2 do
                command("RoutingAileron" .. side,
                    Vector3.new(6.8, 2.1, 1.0),
                    CFrame.new(side * 4.1, top + 16.8, 0)
                        * CFrame.Angles(0, 0, math.rad(side * 26)),
                    accent, Enum.Material.Metal, "WedgePart")
            end
        elseif variant == "Orbital" then
            command("OrbitalPowerOrb",
                Vector3.new(5.8, 5.8, 5.8),
                CFrame.new(0, top + 17.3, 0),
                accent, Enum.Material.Glass, nil, Enum.PartType.Ball)
            command("OrbitRing",
                Vector3.new(0.55, 8.4, 8.4),
                CFrame.new(0, top + 17.3, 0)
                    * CFrame.Angles(0, 0, math.pi * 0.5),
                secondary, Enum.Material.CeramicTiles, nil, Enum.PartType.Cylinder)
        elseif variant == "Harbor" then
            command("DryDockHighCrane",
                Vector3.new(16, 1.7, 2.9),
                CFrame.new(3, top + 17.3, 0),
                secondary, Enum.Material.CorrodedMetal)
            command("CableLift", Vector3.new(0.36, 4.6, 0.36),
                CFrame.new(9.1, top + 14.2, 0),
                metal, Enum.Material.Metal)
            command("FreightPod", Vector3.new(4.1, 3.1, 3.5),
                CFrame.new(9.1, top + 10.4, 0),
                accent, Enum.Material.WoodPlanks)
        end
    end
    -- No light, particle emitter, RenderStepped listener or active physics.
    assert(count <= 14, "Sky Spine decorative part budget exceeded")
    return count
end

return SkySpineArchitecture
