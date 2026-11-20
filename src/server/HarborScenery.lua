--!strict
-- STORM HARBOR skyline: four creator-authored, collision-free gantry
-- cranes and one full original static cargo vessel, outside the actual
-- 320x320 survival map.
-- Client-side motion uses the same named anchors for either geometry.
-- Atomic streaming and distant-scene tags allow Android LOD culling.
local RouteSignalGeometry = require("./RouteSignalGeometry")
local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
local capModule = shared and shared:FindFirstChild("PerimeterCapGeometry")
local PerimeterCapGeometry = if capModule then require(capModule)
    else require("../shared/PerimeterCapGeometry")

type Profile = {part: MeshPart?, assetId: number?, rotation: CFrame?, swapXZ: boolean?}
type Profiles = {
    bevel: Profile?, beam: Profile?, shaft: Profile?, cast: Profile?, ring: Profile?, lens: Profile?,
}

local HarborScenery = {}

local function available(profile: Profile?): Profile?
    local source = profile and profile.part
    return if source and source.Archivable and source.MeshId ~= "" then profile else nil
end

local function geometry(model, name, size, frame, tone, material, profile: Profile?,
        kind: string?, alongX: boolean?, cylinder: boolean?)
    local source = profile and profile.part
    local mesh
    if source and profile and source.MeshId ~= "" then
        local meshSize, meshFrame = size, frame
        if cylinder then
            meshSize = Vector3.new(size.Y, size.X, size.Z)
            meshFrame *= CFrame.Angles(0, 0, -math.pi / 2)
        end
        if profile.rotation then meshFrame *= profile.rotation end
        if profile.swapXZ then meshSize = Vector3.new(meshSize.Z, meshSize.Y, meshSize.X) end
        -- Motion and full-model mounts depend on the original frame of
        -- the crane crossgirder and cargo deck. Only free spans may yaw.
        local spanX = if alongX == nil then source.Size.X > source.Size.Z else alongX
        mesh = RouteSignalGeometry.fit(source, meshFrame, meshSize, nil, spanX)
    end
    local piece = mesh or Instance.new(kind or "Part")
    if mesh then
        mesh.Transparency = 0
        mesh:SetAttribute("Original3DAssetId", profile and profile.assetId)
    else
        piece.Size = size
        piece.CFrame = frame
        if cylinder and piece:IsA("Part") then piece.Shape = Enum.PartType.Cylinder end
    end
    piece.Name = name
    piece.Color = tone
    piece.Material = material or Enum.Material.Metal
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanTouch = false
    piece.CanQuery = false
    piece.CastShadow = false
    piece.Parent = model
    return piece
end

-- One recognizable full cargo-freighter silhouette behind the northern
-- yard, with the same distant-scenery LOD as the four cranes.
local function buildCargoVessel(fleet, base, theme, profiles: Profiles?, slope: Profile?)
    local vessel = Instance.new("Model")
    vessel.Name = "HarborCargoVessel"
    vessel:SetAttribute("ChaosDistantScenery", true)
    vessel:SetAttribute("CosmeticOnly", true)
    vessel:SetAttribute("SourceIsOriginal", true)
    vessel:SetAttribute("HarborVesselScenery", true)
    vessel.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

    local origin = CFrame.new(
        base.Position.X - base.Size.X * 0.18,
        base.Position.Y + base.Size.Y * 0.5 - 3,
        base.Position.Z - base.Size.Z * 0.5 - 68
    )
    local hull = theme.Structure:Lerp(Color3.fromRGB(29, 46, 54), 0.33)
    local lower = hull:Lerp(Color3.fromRGB(18, 29, 36), 0.34)
    local alloy = theme.Detail:Lerp(Color3.fromRGB(112, 127, 127), 0.25)
    local roof = theme.Surface:Lerp(Color3.fromRGB(42, 54, 60), 0.48)
    local stripe = theme.Accent:Lerp(alloy, 0.82)
    local glass = alloy:Lerp(Color3.fromRGB(35, 68, 81), 0.65)
    local cargoColors = {
        theme.Detail:Lerp(Color3.fromRGB(94, 121, 126), 0.55),
        theme.Structure:Lerp(Color3.fromRGB(110, 90, 79), 0.55),
        theme.Secondary:Lerp(Color3.fromRGB(72, 102, 109), 0.66),
    }

    -- The full freighter has many decorative ribs, railings and details.
    -- On low-end Android an entirely invisible cargo landmark leaves the
    -- north skyline empty. Retain exactly fourteen LARGE structural pieces
    -- of this already-replicated 3D ship. Scenery LOD hides the four
    -- fallback gantries on Low.
    local lowSilhouette = {
        MainHull = true, LowerKeel = true, MainCargoDeck = true,
        BowTaperPort = true, BowTaperStarboard = true,
        SternDeckhouse = true, Wheelhouse = true, ExhaustStack = true,
    }

    local bevel = profiles and profiles.bevel
    local truss = profiles and profiles.beam
    local column = profiles and profiles.shaft
    local function segment(name, size, offset, color, material, kind, artwork: Profile?,
            alongX: boolean?)
        local profile = if kind == "WedgePart" then slope else artwork or bevel
        local piece = geometry(vessel, name, size, origin * offset, color or hull,
            material, profile, kind, alongX)
        if lowSilhouette[name] == true then
            piece:SetAttribute("HeroSilhouetteEssential", true)
        end
        return piece
    end
    local function brace(name, a, b, thickness, color)
        local delta = b - a
        return segment(name, Vector3.new(thickness, thickness, delta.Magnitude),
            CFrame.lookAt((a + b) * 0.5, b), color or alloy,
            nil, nil, truss, false)
    end

    -- Ship axis is X, starboard/port Z. Layered hull bands and tapered
    -- bow/stern read as a genuine vessel even with particles disabled.
    segment("LowerKeel", Vector3.new(83, 4.2, 14),
        CFrame.new(0, -4.4, 0), lower, Enum.Material.CorrodedMetal, nil, truss, true)
    segment("MainHull", Vector3.new(88, 8.2, 20),
        CFrame.new(0, -0.4, 0), hull, Enum.Material.CorrodedMetal)
    segment("BowTaperPort", Vector3.new(14, 7.0, 10),
        CFrame.new(49.5, -1.0, -5) * CFrame.Angles(0, math.pi / 2, 0),
        hull, Enum.Material.CorrodedMetal, "WedgePart")
    segment("BowTaperStarboard", Vector3.new(14, 7.0, 10),
        CFrame.new(49.5, -1.0, 5) * CFrame.Angles(0, -math.pi / 2, 0),
        hull, Enum.Material.CorrodedMetal, "WedgePart")
    segment("SternTaperPort", Vector3.new(9, 6.5, 10),
        CFrame.new(-47, -1.0, -4.8) * CFrame.Angles(0, -math.pi / 2, 0),
        hull, Enum.Material.CorrodedMetal, "WedgePart")
    segment("SternTaperStarboard", Vector3.new(9, 6.5, 10),
        CFrame.new(-47, -1.0, 4.8) * CFrame.Angles(0, math.pi / 2, 0),
        hull, Enum.Material.CorrodedMetal, "WedgePart")
    segment("MainCargoDeck", Vector3.new(88, 0.7, 19),
        CFrame.new(0, 4.1, 0), roof)
    for _, side in ipairs({-1, 1}) do
        segment("HullWaterline" .. side, Vector3.new(78, 0.45, 0.18),
            CFrame.new(0, -2.9, side * 10.08), stripe)
        segment("DeckGunwale" .. side, Vector3.new(85, 0.76, 0.65),
            CFrame.new(0, 4.7, side * 9.5), alloy, nil, nil, truss, true)
        for index = 1, 5 do
            local x = -35 + (index - 1) * 17
            segment("GuardrailPost" .. side .. "_" .. index,
                Vector3.new(0.24, 2.2, 0.24),
                CFrame.new(x, 6.0, side * 9.55), alloy, nil, nil, column)
        end
        segment("GuardrailTop" .. side, Vector3.new(75, 0.18, 0.18),
            CFrame.new(0, 7.15, side * 9.55), alloy)
    end

    -- Recessed deck bays with two-high stacks, independent ribs and top
    -- corner castings. Cargo remains cargo: zero invisible colliders.
    for bay = 1, 3 do
        local x = -9 + (bay - 1) * 20
        segment("CargoBaySill" .. bay, Vector3.new(16.6, 0.35, 17),
            CFrame.new(x, 4.65, 0), lower)
        for side = -1, 1, 2 do
            for layer = 1, 2 do
                local z = side * 4.25
                local y = 6.8 + (layer - 1) * 4.6
                local tone = cargoColors[(bay + layer + (side + 1) / 2) % 3 + 1]
                local prefix = "Container" .. bay .. "_" .. side .. "_" .. layer
                if layer == 1 then
                    -- Six first-layer containers establish the ship's
                    -- freight silhouette. All upper tiers and small
                    -- corrugation ribs stay hidden on Low.
                    lowSilhouette[prefix] = true
                end
                segment(prefix, Vector3.new(15, 4.0, 7.7),
                    CFrame.new(x, y, z), tone, Enum.Material.CorrodedMetal)
                for rib = -1, 1, 2 do
                    segment(prefix .. "Rib" .. rib, Vector3.new(0.22, 3.5, 0.24),
                        CFrame.new(x + rib * 5.5, y, z + side * 3.89),
                        alloy:Lerp(tone, 0.65), nil, nil, column)
                end
                segment(prefix .. "DoorLine", Vector3.new(0.20, 3.7, 6.5),
                    CFrame.new(x + 7.55, y, z), lower)
            end
        end
    end

    -- Tall stern bridge supplies a clear human-scale reference, even
    -- through the distant LOD, rather than one generic rectangular barge.
    segment("SternDeckhouse", Vector3.new(13.5, 13, 16),
        CFrame.new(-34, 10.9, 0), alloy)
    segment("Wheelhouse", Vector3.new(16, 5.8, 17),
        CFrame.new(-34, 20.0, 0), roof)
    segment("BridgeCap", Vector3.new(19, 0.75, 19),
        CFrame.new(-34, 23.1, 0), lower)
    segment("BridgePanorama", Vector3.new(0.20, 2.2, 14.5),
        CFrame.new(-25.9, 20.6, 0), glass, Enum.Material.Glass)
    for _, side in ipairs({-1, 1}) do
        segment("BridgeSideWindow" .. side,
            Vector3.new(8.3, 2.15, 0.15),
            CFrame.new(-34, 20.6, side * 8.6),
            glass, Enum.Material.Glass)
    end
    segment("ExhaustStack", Vector3.new(4.5, 8.8, 4.5),
        CFrame.new(-43, 18.7, -2.6), lower, nil, nil, column)
    segment("ExhaustLip", Vector3.new(5, 0.6, 5),
        CFrame.new(-43, 23.2, -2.6), alloy)
    segment("RadarMast", Vector3.new(0.55, 12.0, 0.55),
        CFrame.new(-31, 29.3, 1.7), alloy, nil, nil, column)
    segment("RadarBoom", Vector3.new(8.2, 0.36, 0.50),
        CFrame.new(-31, 34.6, 1.7), stripe)
    brace("MastBackstay",
        Vector3.new(-31, 32.7, 1.7),
        Vector3.new(-41, 22.9, 6.4), 0.24, lower)

    -- Vessel model is built before parenting to avoid partially streamed
    -- bundles; the shared Harbor LOD controller owns all its visual Parts.
    vessel.Parent = fleet
    return vessel
end

function HarborScenery.build(decor, base, theme, profiles: Profiles?)
    if not decor or not base or not base:IsA("BasePart") then
        return nil
    end

    local cast = available(profiles and profiles.cast)
    local bevel = available(profiles and profiles.bevel) or cast
    local truss = available(profiles and profiles.beam)
    local column = available(profiles and profiles.shaft)
    local lens = available(profiles and profiles.lens)
    local ring = available(profiles and profiles.ring)
    local rotation, swapXZ = PerimeterCapGeometry.slope(cast and cast.part)
    local slope = if rotation and cast then {
        part = cast.part, assetId = cast.assetId, rotation = rotation, swapXZ = swapXZ,
    } else nil

    local halfX, halfZ = base.Size.X * 0.5, base.Size.Z * 0.5
    local floorY = base.Position.Y + base.Size.Y * 0.5
    local metal = theme.Structure:Lerp(theme.Detail, 0.34)
    local shadow = theme.Surface:Lerp(Color3.fromRGB(10, 20, 28), 0.50)
    local trim = theme.Accent:Lerp(metal, 0.65)
    local slots = {
        {name = "EastNorth", x = halfX + 45, z = -55, yaw = math.pi * 0.5},
        {name = "EastSouth", x = halfX + 45, z = 55, yaw = math.pi * 0.5},
        {name = "WestNorth", x = -halfX - 45, z = -55, yaw = -math.pi * 0.5},
        {name = "WestSouth", x = -halfX - 45, z = 55, yaw = -math.pi * 0.5},
    }

    local folder = Instance.new("Folder")
    folder.Name = "StormHarborGantryFleet"
    folder.Parent = decor

    for index, slot in ipairs(slots) do
        local crane = Instance.new("Model")
        crane.Name = "HarborGantry" .. slot.name
        crane:SetAttribute("ChaosDistantScenery", true)
        crane:SetAttribute("CosmeticOnly", true)
        crane:SetAttribute("SourceIsOriginal", true)
        crane:SetAttribute("HarborGantryScenery", true)
        crane.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

        local origin = CFrame.new(
            base.Position.X + slot.x,
            floorY,
            base.Position.Z + slot.z
        ) * CFrame.Angles(0, slot.yaw, 0)

        local function beam(name, size, offset, color, material, profile: Profile?,
                alongX: boolean?, cylinder: boolean?)
            return geometry(crane, name, size, origin * offset, color or metal, material,
                (if cylinder then profile else profile or bevel), nil, alongX, cylinder)
        end

        beam("PortLeg", Vector3.new(1.7, 30, 1.7),
            CFrame.new(-8, 15, 0), nil, nil, column)
        beam("StarboardLeg", Vector3.new(1.7, 30, 1.7),
            CFrame.new(8, 15, 0), nil, nil, column)
        beam("MainCrossgirder", Vector3.new(20, 1.8, 2.2),
            CFrame.new(0, 30, 0), nil, nil, truss)
        beam("TrolleyTrack", Vector3.new(1.8, 1.4, 34),
            CFrame.new(0, 32, -3), nil, nil, truss, false)
        beam("Counterweight", Vector3.new(5.8, 3.5, 4),
            CFrame.new(0, 31.7, 15), shadow)
        beam("TrolleyCabin", Vector3.new(4.1, 3.4, 3.6),
            CFrame.new(0, 29.5, -11), theme.Detail)
        beam("CabinWindow", Vector3.new(3.0, 1.6, 0.12),
            CFrame.new(0, 29.7, -12.88), trim, Enum.Material.Glass)
        beam("HoistCable", Vector3.new(0.25, 13, 0.25),
            CFrame.new(0, 22, -15), shadow, nil, column)
        beam("CargoSpreader", Vector3.new(9, 0.8, 1.2),
            CFrame.new(0, 15.5, -15), theme.Detail, nil, truss)
        for _, sign in ipairs({-1, 1}) do
            beam(sign < 0 and "PortKnee" or "StarboardKnee",
                Vector3.new(1.15, 12, 1.15),
                CFrame.new(sign * 5, 23.8, 0)
                    * CFrame.Angles(0, 0, math.rad(sign * 31)), metal, nil, column)
        end

        -- Authored gantry: real triangular bracing, paired trolley rails,
        -- suspended loads and a visible counterweight. Cosmetic-only
        -- parts share the existing per-model mobile LOD; no new loops.
        local function brace(name, from, to, width, color)
            local delta = to - from
            if delta.Magnitude < 0.2 then return end
            return beam(name, Vector3.new(width, width, delta.Magnitude),
                CFrame.lookAt((from + to) * 0.5, to),
                color or metal, Enum.Material.Metal, truss, false)
        end
        for side = -1, 1, 2 do
            beam("TrackRail" .. side, Vector3.new(0.38, 0.34, 31),
                CFrame.new(side * 1.15, 33.0, -3), trim, nil, truss, false)
            brace("GantryKneeBrace" .. side,
                Vector3.new(side * 8, 4.5, -4.2),
                Vector3.new(side * 8, 27.0, 3.4), 0.48, metal)
            beam("CounterweightArmor" .. side,
                Vector3.new(0.45, 3.0, 3.7),
                CFrame.new(side * 2.96, 31.7, 15),
                shadow:Lerp(metal, 0.24), Enum.Material.CorrodedMetal)
            for section = 0, 2 do
                local z = -18 + section * 11
                brace("BoomTruss" .. side .. "_" .. section,
                    Vector3.new(side * 1.15, 32.7, z),
                    Vector3.new(side * 1.15, 35.0, z + 10),
                    0.29, shadow:Lerp(metal, 0.48))
            end
            brace("CargoSling" .. side,
                Vector3.new(side * 3.9, 15.2, -15),
                Vector3.new(side * 3.6, 12.8, -15), 0.20, shadow)
        end
        beam("TrolleyDriveHousing", Vector3.new(3.8, 1.4, 3.3),
            CFrame.new(0, 31.6, -13), shadow, Enum.Material.CorrodedMetal)

        -- Alternating container and industrial cable drum give the four
        -- skyline cranes distinct profiles; no loose or falling objects.
        local loadTone = index % 2 == 0
            and theme.Structure:Lerp(Color3.fromRGB(99, 120, 128), 0.35)
            or theme.Detail:Lerp(Color3.fromRGB(75, 92, 101), 0.43)
        if index % 2 == 1 then
            beam("ContainerArmor", Vector3.new(8.6, 4.9, 5.3),
                CFrame.new(0, 10.1, -15),
                loadTone, Enum.Material.CorrodedMetal)
            beam("ContainerRoof", Vector3.new(8.9, 0.33, 5.55),
                CFrame.new(0, 12.72, -15), metal)
            for side = -1, 1, 2 do
                beam("ContainerRib" .. side,
                    Vector3.new(0.27, 4.4, 0.27),
                    CFrame.new(side * 3.25, 10.1, -17.72), trim, nil, column)
            end
        else
            beam("CableDrum", Vector3.new(7.5, 4.3, 4.3),
                CFrame.new(0, 10.3, -15), loadTone, Enum.Material.CorrodedMetal,
                column or lens, nil, true)
            for side = -1, 1, 2 do
                beam("DrumArmorPlate" .. side, Vector3.new(0.46, 5.1, 5.1),
                    CFrame.new(side * 3.9, 10.3, -15), metal, nil, ring or lens or column, nil, true)
            end
        end

        -- Two restrained reflective stripe accents, NOT hazard colors.
        beam("SignalRidge", Vector3.new(18, 0.24, 0.28),
            CFrame.new(0, 31.3, -0.8), trim)
        if index % 2 == 0 then
            crane:SetAttribute("GantrySector", "South")
        else
            crane:SetAttribute("GantrySector", "North")
        end
        crane.Parent = folder
    end

    buildCargoVessel(folder, base, theme, {
        bevel = bevel, beam = truss, shaft = column,
    }, slope)

    return folder
end

return HarborScenery
