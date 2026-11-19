-- Massive structural arches over ACTUAL collidable promenade decks.
-- Six original steel/ceramic/cargo gate ensembles per arena, each attached
-- to its exact platform index for ShrinkingArena size and CFrame updates.
-- Cosmetic arches and approved underdeck relief share the physical deck's index.
local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
local lodRulesModule = shared and shared:FindFirstChild("PlatformIdentityLodRules")
local PlatformIdentityLodRules = if lodRulesModule then require(lodRulesModule)
    else require("../shared/PlatformIdentityLodRules")
local horizonModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonModule then require(horizonModule)
    else require("../shared/HorizonMonumentGeometry")
local RouteSignalGeometry = require("./RouteSignalGeometry")
local PromenadeArchitecture = {}

local function make(decor, platform, index, name, size, offset, color,
    material, className, mesh)
    local p = mesh or Instance.new(className or "Part")
    p.Name = "Promenade" .. index .. "_" .. name
    if not mesh then
        p.Size = size
        p.CFrame = platform.CFrame * offset
    end
    p.Color = color
    p.Material = material
    p.Transparency = 0.06
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    -- ShrinkingArena already captures deck-owned decor by this attribute,
    -- moving/scaling it together with the true physical walkway.
    p:SetAttribute("PerimeterPlatformIndex", index)
    p:SetAttribute("PromenadeVisualOnly", true)
    p.Parent = decor
    return p
end

-- The lookout and its end span share a level strip. Put the cue in
-- that strip and seat two braces where the thin span leaves the solid pier.
function PromenadeArchitecture.decorateLookoutJoint(decor, lookout, index, span, theme, beam)
    local localCenter = lookout.CFrame:PointToObjectSpace(span.Position)
    local lookoutTop = lookout.Size.Y * 0.5
    local spanTop = localCenter.Y + span.Size.Y * 0.5
    if math.abs(localCenter.Z) > 0.05 or math.abs(lookoutTop - spanTop) > 0.05
        or math.abs(lookout.CFrame.RightVector:Dot(span.CFrame.RightVector)) < 0.999 then
        return nil
    end
    local edge = lookout.Size.X * 0.5
    local near = math.abs(localCenter.X) - span.Size.X * 0.5
    local far = math.abs(localCenter.X) + span.Size.X * 0.5
    if near < 0 or edge - near < 2.5 or far - edge < 2.6 then return nil end

    local direction = if localCenter.X < 0 then -1 else 1
    local depth = math.min(lookout.Size.Z, span.Size.Z)
    local inset = math.min(2.0, (edge - near) * 0.5)
    if beam and beam.part and beam.part.MeshId ~= "" then
        local size = Vector3.new(inset + 2.6, 1.25, 1.40)
        local x = direction * (edge + (2.6 - inset) * 0.5)
        local y = spanTop - span.Size.Y - 0.46
        local color = theme.Detail:Lerp(theme.Structure, 0.38)
        for side = -1, 1, 2 do
            local offset = CFrame.new(x, y, side * (depth * 0.5 - 1.35))
            local mesh = RouteSignalGeometry.fit(beam.part, lookout.CFrame * offset, size, nil, true)
            if mesh then
                mesh.Name = "LookoutJointBrace" .. index .. "_" .. side
                mesh.Color = color
                mesh.Material = lookout.Material
                mesh.Transparency = 0
                mesh:SetAttribute("Original3DAssetId", beam.assetId)
                mesh:SetAttribute("PerimeterPlatformIndex", index)
                mesh.Parent = decor
            end
        end
    end

    return lookout.CFrame.RightVector * (direction * (near + edge) * 0.5)
end

local function variantEquipment(decor, platform, index, variant, theme, top, profiles)
    local metal = theme.Structure:Lerp(theme.Detail, 0.35)
    local accent = theme.Accent:Lerp(theme.Structure, 0.55)
    local secondary = theme.Secondary:Lerp(theme.Detail, 0.32)
    local equipment = 0
    local function add(name, size, offset, color, material, className)
        local profile = HorizonMonumentGeometry.promenadeRoofProfile(name)
        local source = profiles and profiles[profile]
        local template = source and source.part
        offset = CFrame.new(0, top, 0) * offset
        local mesh
        if template and template.MeshId ~= "" then
            -- Beams run along the deck X. Retain the original axes of
            -- housings, lenses and shafts for the local equipment mounts.
            local alongX = profile == "beam" or template.Size.X > template.Size.Z
            mesh = RouteSignalGeometry.fit(template, platform.CFrame * offset, size, nil, alongX)
            if mesh then
                mesh:SetAttribute("OriginalPromenadeEquipment3D", true)
                mesh:SetAttribute("Original3DAssetId", source.assetId)
            end
        end
        make(decor, platform, index, name, size, offset, color, material, className, mesh)
        equipment += 1
    end

    if variant == "Classic" then
        add("SurveyDish", Vector3.new(5.5, 0.70, 5.5),
            CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(18)),
            secondary, Enum.Material.Metal)
        add("SurveyMast", Vector3.new(0.52, 5, 0.52),
            CFrame.new(0, 4.0, 0), metal, Enum.Material.Metal)
        add("SurveyTip", Vector3.new(1.8, 1.8, 1.8),
            CFrame.new(0, 6.3, 0), accent, Enum.Material.Glass)
    elseif variant == "Towers" then
        add("HoistMachine", Vector3.new(7.2, 3.5, 4.2),
            CFrame.new(0, 2.0, 0), metal, Enum.Material.DiamondPlate)
        add("HoistRail", Vector3.new(0.6, 5.0, 0.6),
            CFrame.new(4.2, 3.8, 0), secondary, Enum.Material.Metal)
        add("HoistBeacon", Vector3.new(2.2, 0.55, 2.0),
            CFrame.new(0, 4.2, 0), accent, Enum.Material.Glass)
    elseif variant == "Crossroads" then
        add("SignalConcourse", Vector3.new(10.8, 2.1, 3.0),
            CFrame.new(0, 1.45, 0), metal, Enum.Material.CorrodedMetal)
        for side = -1, 1, 2 do
            add("SwitchFin" .. tostring(side),
                Vector3.new(4.9, 1.4, 0.8),
                CFrame.new(side * 6.1, 3.0, 0)
                    * CFrame.Angles(0, 0, math.rad(side * 24)),
                side < 0 and accent or secondary, Enum.Material.Metal,
                "WedgePart")
        end
    elseif variant == "Orbital" then
        add("GyroCore", Vector3.new(4.2, 4.2, 4.2),
            CFrame.new(0, 3.3, 0), accent, Enum.Material.Glass)
        for side = -1, 1, 2 do
            add("ContainmentFin" .. tostring(side),
                Vector3.new(0.9, 5.5, 3.2),
                CFrame.new(side * 4.4, 2.8, 0)
                    * CFrame.Angles(0, 0, math.rad(side * 18)),
                secondary, Enum.Material.CeramicTiles, "WedgePart")
        end
    elseif variant == "Harbor" then
        add("FreightHoistArm", Vector3.new(16.8, 1.6, 2.3),
            CFrame.new(1.0, 1.9, 0), metal, Enum.Material.CorrodedMetal)
        add("SuspendedCrate", Vector3.new(4.2, 3.8, 4.2),
            CFrame.new(8.1, -2.3, -4.0),
            secondary, Enum.Material.WoodPlanks)
        add("CargoChain", Vector3.new(0.3, 3.2, 0.3),
            CFrame.new(8.1, 0.8, -4.0), accent, Enum.Material.Metal)
    end
    return equipment
end

function PromenadeArchitecture.decorate(decor, platform, index, definition,
    variant, theme, trussProfile, profiles)
    if not decor or not platform or not platform:IsA("BasePart")
        or type(definition) ~= "table" or type(theme) ~= "table" then
        return 0
    end
    local lane = definition.PromenadeLane
    local step = definition.PromenadeStep
    -- Monumental gateway rhythm: three obvious spans per lane, leaving
    -- unimpeded sightlines on the other five physical deck sections.
    if (lane ~= 1 and lane ~= 2)
        or (step ~= 2 and step ~= 4 and step ~= 7) then
        return 0
    end

    local count = 0
    local height = platform.Size.Y * 0.5
    local steel = theme.Structure:Lerp(theme.Surface, 0.18)
    local alloy = theme.Detail:Lerp(theme.Structure, 0.30)
    -- Preserve distinct world materials while reducing generic metal repetition.
    local material = variant == "Harbor" and Enum.Material.CorrodedMetal
        or (variant == "Orbital" and Enum.Material.CeramicTiles
            or Enum.Material.Metal)
    local crownHeight = step == 7 and 16.2 or (step == 4 and 14.5 or 13.25)
    local crownSpan = step == 7 and 21.2 or (step == 4 and 19.6 or 18.4)
    local shaftProfile = profiles and profiles.shaft
    local shaft = shaftProfile and shaftProfile.part
    if shaft and shaft.MeshId == "" then shaft = nil end
    local shaftAlongX = shaft and shaft.Size.X > shaft.Size.Z
    local pylonSize = Vector3.new(1.6, crownHeight, 1.8)
    local staySize = Vector3.new(0.65, crownHeight * 0.55, 1.1)
    -- Two side rails outside the ACTUAL 12-stud-wide crossing. Arch
    -- interiors have >11 studs head clearance and no solid decoration,
    -- so running/jumping R6/R15 players never hit invisible beams.
    for side = -1, 1, 2 do
        local pylonOffset = CFrame.new(0, height + crownHeight * 0.5, side * 7.6)
        local pylon = RouteSignalGeometry.fit(shaft, platform.CFrame * pylonOffset,
            pylonSize, nil, shaftAlongX)
        if pylon then
            pylon:SetAttribute("OriginalPromenadePylonShaft3D", true)
            pylon:SetAttribute("Original3DAssetId", shaftProfile.assetId)
        end
        make(decor, platform, index, "LoadPylon" .. side, pylonSize, pylonOffset,
            steel, material, nil, pylon)
        count += 1
        local offset = PlatformIdentityLodRules.promenadeSculptedStayPose(height, crownHeight, side, 1)
        -- The shaft already has its long axis on Y. Keep the diagonal's
        -- local axes so contraction only changes its cross section.
        local stay = RouteSignalGeometry.fit(shaft, platform.CFrame * offset, staySize, nil, shaftAlongX)
        if stay then
            stay:SetAttribute("OriginalPromenadeStay3D", true)
            stay:SetAttribute("Original3DAssetId", shaftProfile.assetId)
        else
            offset = CFrame.new(0, height + crownHeight * 0.66, side * 8.3)
                * CFrame.Angles(math.rad(side * 16), 0, 0)
        end
        make(decor, platform, index, "DiagonalStay" .. side, staySize, offset, alloy, material, nil, stay)
        count += 1
    end
    local crossheadSize = Vector3.new(4.0, 1.2, crownSpan)
    local crossheadOffset = CFrame.new(0, height + crownHeight, 0)
    local beamProfile = profiles and profiles.beam
    local beam = beamProfile and beamProfile.part
    local crosshead = beam and beam.MeshId ~= "" and RouteSignalGeometry.fit(
        beam, platform.CFrame * crossheadOffset, crossheadSize)
    if crosshead then
        crosshead:SetAttribute("OriginalPromenadeCrosshead3D", true)
        crosshead:SetAttribute("Original3DAssetId", beamProfile.assetId)
    end
    make(decor, platform, index, "MonumentalCrosshead", crossheadSize, crossheadOffset,
        alloy, material, nil, crosshead)
    count += 1
    -- Keep the original owner slot and give the mesh a visible depth
    -- below the deck. Native fallback retains its original fit.
    local trussSpan = step == 7 and 15.0 or (step == 4 and 13.0 or 11.0)
    local trussSize, trussOffset = PlatformIdentityLodRules.promenadeUnderdeckGeometry(height, trussSpan, 1, true)
    local truss = trussProfile and trussProfile.MeshId ~= ""
        and RouteSignalGeometry.fit(trussProfile, platform.CFrame * trussOffset, trussSize)
    if truss then
        truss:SetAttribute("OriginalPromenadeUnderdeck3D", true)
        truss:SetAttribute("Original3DAssetId", 106401955318567)
    else
        trussSize, trussOffset = PlatformIdentityLodRules.promenadeUnderdeckGeometry(height, trussSpan, 1, false)
    end
    make(decor, platform, index, "UnderdeckTruss", trussSize, trussOffset, steel, Enum.Material.Metal, nil, truss)
    count += 1
    -- The equipment is above the structural crosshead, or outside
    -- the deck edges. Nothing presents a fake playable upper surface.
    count += variantEquipment(decor, platform, index,
        variant, theme, height + crownHeight, profiles)
    assert(count <= 9, "Monumental promenade arch exceeded part budget")
    return count
end

return PromenadeArchitecture
