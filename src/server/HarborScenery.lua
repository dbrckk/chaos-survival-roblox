--!strict
-- STORM HARBOR skyline: four creator-authored, collision-free gantry
-- crane silhouettes, outside the actual 320x320 survival map.
-- Zero moving parts, sound emitters, scripts, lights or runtime loops.
-- Atomic streaming and distant-scene tags allow Android LOD culling.
local HarborScenery = {}

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

    return folder
end

return HarborScenery
