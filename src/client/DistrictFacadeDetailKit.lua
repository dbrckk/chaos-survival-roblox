--!strict
-- Render the optional entrance and roofline details with the district LOD.
-- Server replicates the readable two-piece doorway only; 16 buildings no
-- longer send the optional 96 cosmetic Parts to every joining phone.
-- This kit is called solely by the existing 0.65/0.90s scenery LOD loop.
-- No new RenderStepped, heartbeat, remote, physics or streaming listeners.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Lest imports this client kit from source against an older published
-- test place where the new Shared ModuleScript may not exist yet.
local shared = ReplicatedStorage:FindFirstChild("Shared")
local stylesModule = shared and shared:FindFirstChild("DistrictFacadeStyles")
local Styles = if stylesModule
    then require(stylesModule)
    else require("../shared/DistrictFacadeStyles")

local Armor = require(script.Parent.ApprovedPerimeterArmorMeshKit)
local Bridge = require(script.Parent.ApprovedTowersSignatureBridgeMeshKit)
local LargeStructures = require(script.Parent.PremiumLargeStructureMeshKit)
local Reactor = require(script.Parent.ApprovedOrbitalReactorLandmarkMeshKit)

type Profile = {source: MeshPart, id: number, rotation: CFrame?, swapXZ: boolean?, swapXY: boolean?}
type Profiles = {casting: Profile?, slope: Profile?, lintel: Profile?, shaft: Profile?, collar: Profile?}

local function profile(source: MeshPart?, id: number?, rotation: CFrame?, swapXZ: boolean?,
    swapXY: boolean?): Profile?
    if not source or not id then return nil end
    return {source = source, id = id, rotation = rotation, swapXZ = swapXZ, swapXY = swapXY}
end

local DistrictFacadeDetailKit = {}
local MEDIUM = {
    "ServiceEntryLintel",
    "ServiceEntryCanopy",
    "PortalHydraulicColumn-1",
    "PortalHydraulicColumn1",
}
local HIGH = {
    [1] = {"SurveyInstrumentCabinet-1", "SurveyInstrumentCabinet1"},
    [2] = {"FreightWinchHousing-1", "FreightWinchHousing1"},
    [3] = {"TurbineDuctCollar-1", "TurbineDuctCollar1"},
    [4] = {"AerialCableConduit-1", "AerialCableConduit1"},
}

-- Resolve each verified template once for the entire district pass.
function DistrictFacadeDetailKit.sources(tierName, pressure): Profiles
    if (tierName ~= "Medium" and tierName ~= "High") or (tonumber(pressure) or 0) >= 1 then
        return {}
    end
    local cast = Armor.wayfinderProfile()
    local slope
    if cast then
        local sloped, yaw, swapXZ, slopeId = Armor.slopedCapProfile(cast)
        slope = profile(sloped, slopeId, yaw, swapXZ)
    end
    local swept = Bridge.sweptProfile()
    local shaft, shaftId = LargeStructures.forgedShaftProfile()
    local ring = if tierName == "High" then Reactor.ringProfile() else nil
    local crosswise = swept and swept.Size.X < swept.Size.Z or false
    return {
        casting = profile(cast, 88962643359267),
        slope = slope,
        lintel = profile(swept, Bridge.AssetId,
            if crosswise then CFrame.Angles(0, math.pi / 2, 0) else nil, crosswise),
        shaft = profile(shaft, shaftId),
        collar = profile(ring, Reactor.NodeAssetId, CFrame.Angles(0, 0, math.pi / 2), nil, true),
    }
end

local function owned(model, name)
    local child = model:FindFirstChild(name)
    if child and child:IsA("BasePart")
        and child:GetAttribute("LocalFacadeDetail") == true then
        return child
    end
    return nil
end

local function destroyNames(model, names)
    for _, name in ipairs(names) do
        local child = owned(model, name)
        if child then child:Destroy() end
    end
end

local function clearOwned(model, slot)
    -- A changing or incomplete streamed provenance must also remove the
    -- previous locally created details, but never server-owned Parts.
    -- On normal Low/offscreen ticks we already know the slot: inspect only
    -- its six names instead of up to twelve per model, every 0.65 seconds.
    destroyNames(model, MEDIUM)
    if HIGH[slot] then
        destroyNames(model, HIGH[slot])
    else
        -- Missing/invalid streamed metadata: clean every prior profile
        -- so no old optional details survive a provenance transition.
        for _, names in pairs(HIGH) do
            destroyNames(model, names)
        end
    end
end

local function countOwned(model, names)
    local count = 0
    for _, name in ipairs(names) do
        if owned(model, name) then count += 1 end
    end
    return count
end

local function add(model, origin, name, kind, size, localFrame,
    color, material, requiredTier, artwork: Profile?)
    local existing = owned(model, name)
    local source = artwork and artwork.source
    if existing then
        if source and artwork and existing:IsA("MeshPart") and existing.MeshId == source.MeshId
            and existing:GetAttribute("Original3DAssetId") == artwork.id then return existing end
        if not source and existing.ClassName == kind then return existing end
    elseif model:FindFirstChild(name) then
        return nil
    end

    local mesh = source and source:Clone()
    if not mesh and existing and existing.ClassName == kind then return existing end
    local piece = mesh or Instance.new(kind)
    if mesh and artwork then
        mesh:ClearAllChildren()
        mesh.TextureID = ""
        mesh.MaterialVariant = ""
        mesh.Transparency = 0
        mesh.LocalTransparencyModifier = 0
        mesh.DoubleSided = true
        mesh:SetAttribute("Original3DAssetId", artwork.id)
        if artwork.rotation then localFrame *= artwork.rotation end
        if artwork.swapXZ then size = Vector3.new(size.Z, size.Y, size.X) end
        -- The collar's normal is mapped from the mesh's Y axis to the duct's X axis.
        if artwork.swapXY then size = Vector3.new(size.Y, size.X, size.Z) end
    end
    piece.Name = name
    piece.Size = size
    piece.CFrame = origin * localFrame
    piece.Color = color
    piece.Material = material
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanTouch = false
    piece.CanQuery = false
    piece.CastShadow = false
    piece:SetAttribute("LocalFacadeDetail", true)
    piece:SetAttribute("SceneryMinimumTier", requiredTier)
    if material == Enum.Material.Concrete or material == Enum.Material.WoodPlanks
        -- 0.42-stud hydraulic rods and 0.56-stud conduits do not merit
        -- expensive 2K maps. Keep PBR eligibility for large doors and
        -- meaningful structural volumes, preserving their native finish.
        or name:find("PortalHydraulicColumn", 1, true)
        or name:find("AerialCableConduit", 1, true) then
        piece:SetAttribute("PreserveNativeMaterial", true)
    end
    if existing then existing:Destroy() end
    piece.Parent = model
    return piece
end

-- Use the server-owned flat door as an exact geometric origin; this avoids
-- sending a redundant CFrame and three palette Color3 attributes per model.
-- The source door is at origin * CFrame.new(-0.35, 4.0, -4.36).
local function originAndPalette(model)
    local door = model:FindFirstChild("ServiceEntryDoor")
    local recess = model:FindFirstChild("ServiceEntryRecess")
    local rim = model:FindFirstChild("FoundationRim")
    if not (door and door:IsA("BasePart")
        and recess and recess:IsA("BasePart")
        and rim and rim:IsA("BasePart")) then
        return nil
    end
    if door.Size.Z < 0.15 or door.Size.Z > 0.30 then
        return nil
    end
    return door.CFrame * CFrame.new(0.35, -4.0, 4.36),
        door.Color, recess.Color, rim.Color
end

local function makeMedium(model, origin, steel, alloy, finish, profiles: Profiles)
    add(model, origin, "ServiceEntryLintel", "Part",
        Vector3.new(6.7, 0.62, 0.95),
        CFrame.new(0, 6.98, -4.13), alloy, finish.lintel, "Medium", profiles.lintel)
    -- Deep freight and harbor canopies slope down toward the approach.
    local canopyShape = (finish.canopyDepth >= 2.4)
        and "WedgePart" or "Part"
    add(model, origin, "ServiceEntryCanopy", canopyShape,
        Vector3.new(7.6, 0.38, finish.canopyDepth),
        CFrame.new(0, 7.45, -4.57), steel, finish.canopy, "Medium",
        if canopyShape == "WedgePart" then profiles.slope else profiles.casting)
    for _, direction in ipairs({-1, 1}) do
        add(model, origin, "PortalHydraulicColumn" .. tostring(direction),
            "Part", Vector3.new(0.42, 5.25, 0.42),
            CFrame.new(direction * 3.35, 4.08, -4.20),
            alloy, finish.hardware, "Medium", profiles.shaft)
    end
end

local function makeHigh(model, origin, steel, dark, alloy, slot, profiles: Profiles)
    for _, direction in ipairs({-1, 1}) do
        local suffix = tostring(direction)
        if slot == 1 then
            add(model, origin, "SurveyInstrumentCabinet" .. suffix,
                "Part", Vector3.new(1.15, 3.3, 1.45),
                CFrame.new(direction * 5.4, 10.1, -2.1),
                dark, Enum.Material.CorrodedMetal, "High", profiles.casting)
        elseif slot == 2 then
            add(model, origin, "FreightWinchHousing" .. suffix,
                "Part", Vector3.new(2.1, 1.9, 1.6),
                CFrame.new(direction * 5.15, 16.2, -2.0),
                alloy, Enum.Material.DiamondPlate, "High", profiles.casting)
        elseif slot == 3 then
            add(model, origin, "TurbineDuctCollar" .. suffix,
                "Part", Vector3.new(1.7, 2.8, 2.7),
                CFrame.new(direction * 3.4, 17.2, -1.6),
                steel, Enum.Material.CorrodedMetal, "High", profiles.collar)
        else
            add(model, origin, "AerialCableConduit" .. suffix,
                "Part", Vector3.new(0.56, 8.8, 0.56),
                CFrame.new(direction * 5.0, 15.7, -2.0)
                    * CFrame.Angles(0, 0, math.rad(direction * 15)),
                alloy, Enum.Material.Metal, "High", profiles.shaft)
        end
    end
end

-- Streamed models own their local details. Hysteresis prevents churn at the cutoff.
function DistrictFacadeDetailKit.sync(model, tierName, visible, distance,
    isTouch, cameraReady, profiles: Profiles)
    if not model or not model:IsA("Model") then return 0 end
    if model:GetAttribute("ArenaDistrictArchitecture") ~= true
        or model:GetAttribute("SourceIsOriginal") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("FacadeVisualVersion") ~= 1 then
        clearOwned(model)
        return 0
    end
    local slot = model:GetAttribute("DistrictProfile")
    local variantId = model:GetAttribute("FacadeVariantId")
    local finish = type(variantId) == "string" and Styles[variantId] or nil
    if type(slot) ~= "number" or slot ~= math.floor(slot)
        or not HIGH[slot] or not finish then
        clearOwned(model)
        return 0
    end

    -- An owner-verified source mesh replaces these six exact OPTIONAL
    -- doorway/roofline parts. Never instantiate and immediately hide
    -- 4/6 redundant Parts every scenery pass while its real 3D lives.
    -- The mesh owner clears this client-only marker BEFORE restoring
    -- native art on eviction/stream-out; the next LOD pass recreates
    -- the details normally, with the authoritative door always present.
    if model:GetAttribute("LocalApprovedDistrictFacadeMounted") == true then
        clearOwned(model, slot)
        return 0
    end

    -- Android keeps the near-field 175/230-stud budgets, avoiding
    -- needless parts on distant buildings. PC High must NOT inherit
    -- that mobile-only distance cap: before local ownership, all six
    -- details were server-replicated and fully visible on desktop High.
    -- A valid camera/viewport is required before generating local art.
    local cutoff = 0
    if tierName == "High" then
        cutoff = isTouch == true and 230 or math.huge
    elseif tierName == "Medium" then
        cutoff = isTouch == true and 175 or 245
    end
    local mediumPresent = owned(model, MEDIUM[1]) ~= nil
    local highPresent = owned(model, HIGH[slot][1]) ~= nil
    local wasNear = mediumPresent or highPresent
    local near = visible == true and cameraReady == true
        and type(distance) == "number" and distance == distance
        and distance >= 0 and distance < math.huge and cutoff > 0
        and distance <= cutoff + (wasNear and 8 or -8)
    if not near then
        clearOwned(model, slot)
        return 0
    end

    local origin, steel, dark, alloy = originAndPalette(model)
    if not origin then
        clearOwned(model, slot)
        return 0
    end
    makeMedium(model, origin, steel, alloy, finish, profiles)
    if tierName == "High" then
        makeHigh(model, origin, steel, dark, alloy, slot, profiles)
        return countOwned(model, MEDIUM) + countOwned(model, HIGH[slot])
    end
    destroyNames(model, HIGH[slot])
    return countOwned(model, MEDIUM)
end

return DistrictFacadeDetailKit
