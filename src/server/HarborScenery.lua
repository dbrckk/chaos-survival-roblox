--!strict
-- STORM HARBOR skyline: four creator-authored, collision-free gantry
-- cranes and one full original static cargo vessel, outside the actual
-- 320x320 survival map.
-- Zero moving parts, sound emitters, scripts, lights or runtime loops.
-- Atomic streaming and distant-scene tags allow Android LOD culling.
local HarborScenery = {}

-- One recognizable full cargo-freighter silhouette behind the northern
-- yard. This is an original Roblox-native 3D assembly, not a decal, mesh
-- asset dependency or a gameplay platform. The ship belongs to the same
-- protected distant-scenery LOD fleet as the existing four cranes.
local function buildCargoVessel(fleet, base, theme)
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
    -- of this already-replicated 3D ship, never a new low-cost fake mesh.
    -- The existing scenery LOD exclusively owns the visibility; it
    -- still hides all four separate gantry cranes on Low.
    local lowSilhouette = {
        MainHull = true, LowerKeel = true, MainCargoDeck = true,
        BowTaperPort = true, BowTaperStarboard = true,
        SternDeckhouse = true, Wheelhouse = true, ExhaustStack = true,
    }

    local function segment(name, size, offset, color, material, kind)
        local piece = Instance.new(kind or "Part")
        piece.Name = name
        piece.Size = size
        piece.CFrame = origin * offset
        piece.Color = color or hull
        piece.Material = material or Enum.Material.Metal
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        if lowSilhouette[name] == true then
            piece:SetAttribute("HeroSilhouetteEssential", true)
        end
        piece.Parent = vessel
        return piece
    end
    local function brace(name, a, b, thickness, color)
        local delta = b - a
        return segment(name, Vector3.new(thickness, thickness, delta.Magnitude),
            CFrame.lookAt((a + b) * 0.5, b), color or alloy)
    end

    -- Ship axis is X, starboard/port Z. Layered hull bands and tapered
    -- bow/stern read as a genuine vessel even with particles disabled.
    segment("LowerKeel", Vector3.new(83, 4.2, 14),
        CFrame.new(0, -4.4, 0), lower, Enum.Material.CorrodedMetal)
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
            CFrame.new(0, 4.7, side * 9.5), alloy)
        for index = 1, 5 do
            local x = -35 + (index - 1) * 17
            segment("GuardrailPost" .. side .. "_" .. index,
                Vector3.new(0.24, 2.2, 0.24),
                CFrame.new(x, 6.0, side * 9.55), alloy)
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
                        alloy:Lerp(tone, 0.65))
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
        CFrame.new(-43, 18.7, -2.6), lower)
    segment("ExhaustLip", Vector3.new(5, 0.6, 5),
        CFrame.new(-43, 23.2, -2.6), alloy)
    segment("RadarMast", Vector3.new(0.55, 12.0, 0.55),
        CFrame.new(-31, 29.3, 1.7), alloy)
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

function HarborScenery.build(decor, base, theme)
    if not decor or not base or not base:IsA("BasePart") then
        return nil
    end

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

        local function beam(name, size, offset, color, material)
            local p = Instance.new("Part")
            p.Name = name
            p.Size = size
            p.CFrame = origin * offset
            p.Color = color or metal
            p.Material = material or Enum.Material.Metal
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Parent = crane
            return p
        end

        beam("PortLeg", Vector3.new(1.7, 30, 1.7),
            CFrame.new(-8, 15, 0))
        beam("StarboardLeg", Vector3.new(1.7, 30, 1.7),
            CFrame.new(8, 15, 0))
        beam("MainCrossgirder", Vector3.new(20, 1.8, 2.2),
            CFrame.new(0, 30, 0))
        beam("TrolleyTrack", Vector3.new(1.8, 1.4, 34),
            CFrame.new(0, 32, -3))
        beam("Counterweight", Vector3.new(5.8, 3.5, 4),
            CFrame.new(0, 31.7, 15), shadow)
        beam("TrolleyCabin", Vector3.new(4.1, 3.4, 3.6),
            CFrame.new(0, 29.5, -11), theme.Detail)
        beam("CabinWindow", Vector3.new(3.0, 1.6, 0.12),
            CFrame.new(0, 29.7, -12.88), trim, Enum.Material.Glass)
        beam("HoistCable", Vector3.new(0.25, 13, 0.25),
            CFrame.new(0, 22, -15), shadow)
        beam("CargoSpreader", Vector3.new(9, 0.8, 1.2),
            CFrame.new(0, 15.5, -15), theme.Detail)
        for _, sign in ipairs({-1, 1}) do
            beam(sign < 0 and "PortKnee" or "StarboardKnee",
                Vector3.new(1.15, 12, 1.15),
                CFrame.new(sign * 5, 23.8, 0)
                    * CFrame.Angles(0, 0, math.rad(sign * 31)), metal)
        end

        -- Authored gantry: real triangular bracing, paired trolley rails,
        -- suspended loads and a visible counterweight. Cosmetic-only
        -- parts share the existing per-model mobile LOD; no new loops.
        local function brace(name, from, to, width, color)
            local delta = to - from
            if delta.Magnitude < 0.2 then return end
            return beam(name, Vector3.new(width, width, delta.Magnitude),
                CFrame.lookAt((from + to) * 0.5, to),
                color or metal, Enum.Material.Metal)
        end
        for side = -1, 1, 2 do
            beam("TrackRail" .. side, Vector3.new(0.38, 0.34, 31),
                CFrame.new(side * 1.15, 33.0, -3), trim)
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
                    CFrame.new(side * 3.25, 10.1, -17.72), trim)
            end
        else
            local drum = beam("CableDrum",
                Vector3.new(7.5, 4.3, 4.3),
                CFrame.new(0, 10.3, -15),
                loadTone, Enum.Material.CorrodedMetal)
            drum.Shape = Enum.PartType.Cylinder
            for side = -1, 1, 2 do
                local cap = beam("DrumArmorPlate" .. side,
                    Vector3.new(0.46, 5.1, 5.1),
                    CFrame.new(side * 3.9, 10.3, -15), metal)
                cap.Shape = Enum.PartType.Cylinder
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

    buildCargoVessel(folder, base, theme)

    return folder
end

return HarborScenery
