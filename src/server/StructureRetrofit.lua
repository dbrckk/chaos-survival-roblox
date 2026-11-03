--!strict
-- Upgrade existing simple exterior markers and lobby pylons into original
-- three-dimensional architectural assemblies. All pieces are cosmetic.
-- No new gameplay colliders, links, fake safe paths, particle loops or assets.
local StructureRetrofit = {}

local PALETTES = {
    Classic = {metal = Enum.Material.DiamondPlate, secondary = Enum.Material.CorrodedMetal},
    Towers = {metal = Enum.Material.Foil, secondary = Enum.Material.DiamondPlate},
    Crossroads = {metal = Enum.Material.CorrodedMetal, secondary = Enum.Material.DiamondPlate},
    Orbital = {metal = Enum.Material.CeramicTiles, secondary = Enum.Material.Foil},
    Harbor = {metal = Enum.Material.CorrodedMetal, secondary = Enum.Material.DiamondPlate},
}

local function add(model, origin, name, frame, size, color, material, kind, pbr)
    local item = Instance.new(kind or "Part")
    item.Name = name
    item.Size = size
    item.CFrame = origin * frame
    item.Color = color
    item.Material = material
    item.Transparency = 0.045
    item.Anchored = true
    item.CanCollide = false
    item.CanTouch = false
    item.CanQuery = false
    item.CastShadow = false
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    if pbr then item:SetAttribute("OriginalRetrofitPbrSurface", true) end
    item.Parent = model
    return item
end

local function spar(model, origin, name, startPoint, endPoint, size, color, material)
    local delta = endPoint - startPoint
    return add(model, origin, name,
        CFrame.lookAt((startPoint + endPoint) * 0.5, endPoint),
        Vector3.new(size, size, delta.Magnitude),
        color, material, nil, false)
end

local function exteriorAnchors(decor, base, variant)
    local result = {}
    local sourcePrefixes = {
        Classic = "ClassicBroadcastFin",
        Towers = "TowerMachinery",
        Crossroads = "CrossroadGantry",
        Orbital = "OrbitalReactorNode",
    }
    local prefix = sourcePrefixes[variant]
    if prefix then
        local finalIndex = variant == "Orbital" and 7 or 4
        local increment = variant == "Orbital" and 2 or 1
        for i = 1, finalIndex, increment do
            local source = decor:FindFirstChild(prefix .. i)
            if source and source:IsA("BasePart") then
                result[#result + 1] = source.Position
            end
        end
    else
        -- Harbor's cranes and actual cargo vessels already own the skyline.
        -- Four unmoving service gantries stand BEYOND the lethal floor edge.
        local halfX, halfZ = base.Size.X * 0.5, base.Size.Z * 0.5
        for _, offset in ipairs({
            Vector3.new(halfX + 13, 10, -36),
            Vector3.new(-halfX - 13, 10, 36),
            Vector3.new(36, 10, halfZ + 13),
            Vector3.new(-36, 10, -halfZ - 13),
        }) do
            result[#result + 1] = base.CFrame:PointToWorldSpace(offset)
        end
    end
    return result
end

function StructureRetrofit.buildArena(decor, base, variant, theme)
    local palette = PALETTES[variant]
    if not palette or not base or not base:IsA("BasePart") then return 0 end
    local anchors = exteriorAnchors(decor, base, variant)
    if #anchors == 0 then return 0 end
    local fleet = Instance.new("Folder")
    fleet.Name = "OriginalExteriorRetrofits"
    fleet.Parent = decor
    local pieces = 0
    for i, center in ipairs(anchors) do
        local model = Instance.new("Model")
        model.Name = variant .. "Retrofit" .. i
        model:SetAttribute("OriginalExteriorRetrofit", true)
        model:SetAttribute("SourceIsOriginal", true)
        model:SetAttribute("CosmeticOnly", true)
        model.Parent = fleet

        local inward = Vector3.new(base.Position.X - center.X, 0,
            base.Position.Z - center.Z)
        if inward.Magnitude < 1 then inward = Vector3.zAxis end
        local origin = CFrame.lookAt(center, center + inward.Unit)
        local body = theme.Structure:Lerp(theme.Detail, 0.29)
        local inset = theme.Surface:Lerp(theme.Structure, 0.32)
        local hardware = theme.Detail:Lerp(theme.Structure, 0.50)
        -- Preserve the existing bare source marker as its non-colliding
        -- interior while giving the silhouette real multi-layer volume.
        add(model, origin, "OuterFrontArmor", CFrame.new(0, 0, -2.05),
            Vector3.new(5.0, 11.8, 0.68), body, palette.metal, nil, true)
        add(model, origin, "RearMaintenanceShell", CFrame.new(0, 0.2, 1.92),
            Vector3.new(4.6, 10.8, 0.78), hardware,
            palette.secondary, nil, true)
        add(model, origin, "RecessedEquipmentBox", CFrame.new(0, -0.6, -2.49),
            Vector3.new(2.3, 5.2, 0.43), inset,
            palette.secondary, nil, false)
        for _, side in ipairs({-1, 1}) do
            add(model, origin, "FacetedSideWing" .. tostring(side),
                CFrame.new(side * 2.35, -0.35, 0)
                    * CFrame.Angles(0, side * math.rad(12), 0),
                Vector3.new(1.6, 10.8, 3.1), body,
                palette.metal, "WedgePart", false)
            spar(model, origin, "DiagonalExteriorStiffener" .. tostring(side),
                Vector3.new(side * 3.2, -5.8, -1.6),
                Vector3.new(side * 1.2, 6.2, -1.7), 0.46,
                hardware, palette.secondary)
            add(model, origin, "CrownButtress" .. tostring(side),
                CFrame.new(side * 2.45, 6.5, -0.3),
                Vector3.new(0.95, 2.2, 3.8), hardware,
                palette.secondary, nil, false)
        end
        add(model, origin, "UpperStructuralCollar", CFrame.new(0, 6.3, 0),
            Vector3.new(6.8, 0.72, 5.4), hardware,
            palette.metal, nil, false)
        add(model, origin, "CantileverPlatformUnderside",
            CFrame.new(0, 7.4, 0.1),
            Vector3.new(5.9, 0.55, 7.5), inset,
            palette.secondary, "WedgePart", false)
        add(model, origin, "WeatherGuardTop", CFrame.new(0, 8.2, 0),
            Vector3.new(4.8, 0.70, 4.6), body,
            palette.metal, nil, true)
        add(model, origin, "BeaconTensionMast", CFrame.new(0, 10.8, 0),
            Vector3.new(0.50, 4.8, 0.50), hardware,
            palette.secondary, nil, false)
        if variant == "Crossroads" then
            -- Crossroads' original gantries are 28-stud horizontal beams,
            -- NOT 12-stud towers. The generic upright casing did not
            -- cover their toy-like rectangular span. Match the original
            -- physical beam's true axis without replacing its signals.
            local source = decor:FindFirstChild("CrossroadGantry" .. i)
            if source and source:IsA("BasePart") then
                local alongX = source.Size.X > source.Size.Z
                local span = math.max(source.Size.X, source.Size.Z)
                -- Keep the original gantry and its danger/signal cues.
                -- This decorative frame uses WORLD axes from the source:
                -- the outer beams remain beyond the shrinking arena.
                local beamFrame = CFrame.new(source.Position)
                local function girder(name, offset, dimensions, material, color, shape)
                    add(model, beamFrame, name, CFrame.new(offset),
                        dimensions, color, material, shape, false)
                end
                local beamSize = alongX
                    and Vector3.new(span + 1.6, 0.62, 0.90)
                    or Vector3.new(0.90, 0.62, span + 1.6)
                local flangeSize = alongX
                    and Vector3.new(span + 1.6, 0.48, 0.64)
                    or Vector3.new(0.64, 0.48, span + 1.6)
                girder("LongSpanUpperStructuralFlange",
                    Vector3.new(0, 1.50, 0), beamSize,
                    palette.metal, body)
                girder("LongSpanLowerStructuralFlange",
                    Vector3.new(0, -1.45, 0), flangeSize,
                    palette.secondary, hardware)
                for _, side in ipairs({-1, 1}) do
                    local offset = alongX
                        and Vector3.new(side * (span * 0.34), -0.28, 0)
                        or Vector3.new(0, -0.28, side * (span * 0.34))
                    girder("LongSpanDiagonalReinforcement" .. tostring(side),
                        offset,
                        alongX and Vector3.new(2.4, 2.6, 0.74)
                            or Vector3.new(0.74, 2.6, 2.4),
                        palette.metal, inset, "WedgePart")
                end
            end
        end
        pieces += #model:GetChildren()
    end
    return pieces
end

function StructureRetrofit.buildLobby(decor, lobbyCenter)
    if not decor then return 0 end
    local color = Color3.fromRGB(99, 121, 154)
    local dark = Color3.fromRGB(45, 62, 83)
    local shell = Enum.Material.DiamondPlate
    local trim = Enum.Material.Foil
    local group = Instance.new("Folder")
    group.Name = "OriginalLobbyArchitecture"
    group.Parent = decor
    local count = 0
    -- Each of the original four 10-stud pylons becomes a faceted
    -- machined object. The underlying original pylon is untouched.
    for index, offset in ipairs({
        Vector3.new(-31, 5, -31), Vector3.new(31, 5, -31),
        Vector3.new(-31, 5, 31), Vector3.new(31, 5, 31),
    }) do
        local model = Instance.new("Model")
        model.Name = "MachinedLobbyPylon" .. index
        model.Parent = group
        local origin = CFrame.new(lobbyCenter + offset)
        for _, side in ipairs({-1, 1}) do
            add(model, origin, "SideArmor" .. tostring(side),
                CFrame.new(side * 1.32, 0, 0)
                    * CFrame.Angles(0, side * math.rad(11), 0),
                Vector3.new(0.95, 8.9, 2.8), color,
                shell, "WedgePart", false)
        end
        add(model, origin, "LowCollar", CFrame.new(0, -4.2, 0),
            Vector3.new(4.6, 1.1, 4.6), dark, shell, nil, false)
        add(model, origin, "UpperCollar", CFrame.new(0, 4.4, 0),
            Vector3.new(4.6, 0.9, 4.6), color, trim, nil, false)
        count += #model:GetChildren()
    end
    -- The actual arena entrance remains the original physical gate.
    -- Only the upper crossbeam and the exterior sides receive shaped
    -- mechanical cladding, never a secondary walkable barrier.
    local gate = Instance.new("Model")
    gate.Name = "MachinedArenaEntrance"
    gate.Parent = group
    local center = CFrame.new(lobbyCenter + Vector3.new(0, 10.5, 27))
    add(gate, center, "OuterGateCrosshead", CFrame.new(0, 2.8, -1.9),
        Vector3.new(22.7, 2.1, 0.95), color, shell, nil, false)
    for _, side in ipairs({-1, 1}) do
        add(gate, center, "AngledGateSupport" .. tostring(side),
            CFrame.new(side * 11, -3.5, -1.75)
                * CFrame.Angles(0, side * math.rad(10), 0),
            Vector3.new(2.0, 12.0, 2.6), color,
            shell, "WedgePart", false)
        spar(gate, center, "GateStrut" .. tostring(side),
            Vector3.new(side * 10.5, -4.0, -2.3),
            Vector3.new(side * 6.4, 3.9, -2.3),
            0.52, dark, trim)
    end
    count += #gate:GetChildren()
    return count
end

return StructureRetrofit
