-- Four distinct creator-approved genuine MeshPart district facades/rooflines.
-- Mount authentic 3D INSTEAD of the overlapping primitive Roblox roofline,
-- while preserving server-owned foundations, door, wayfinding signs and
-- gameplay. The original native silhouette returns whenever 3D leaves.
-- Reuses the existing scenery LOD camera tick; no new RenderStepped loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PremiumDistrictFacadeMeshKit = {}
local NAMES = {"Observatory", "Freight", "Turbine", "Aerial"}
local IDS = {132020956214241, 88725004643299,
    84217436280282, 135791763112202}
-- On High, twelve of sixteen district profiles can replace their native
-- blockout rooflines with approved true 3D; on Medium five nearer profiles.
-- Low Android retains one verified model, keeping its original GPU bound.
-- Exact camera-ranked residency with exit-only hysteresis, no new loops.
local BUDGET = {
    Low = {count = 1, distance = 130, retention = 16},
    Medium = {count = 5, distance = 205, retention = 22},
    High = {count = 12, distance = 270, retention = 28},
}
local holder = Instance.new("Folder")
holder.Name = "ApprovedDistrictFacadesLocal"
-- Verified local owner for the shared, bounded, 2K nearfield finish.
-- This folder contains only the four creator-approved facade clones.
holder:SetAttribute("CosmeticOnly", true)
holder.Parent = workspace
local activeArena = nil
local mounted = {}
local watchedBase = nil
local baseChanged = nil

-- The playable Base SHRINKS during an actual survival round, but its
-- original creator-authored district landmarks stay in fixed world space.
-- Check the immutable MapBuilder footprint instead of live floor width.
-- The part must still belong to this exact live arena, remain physical,
-- and never expand beyond its originally signed dimensions.
local function authenticBase(base, arena)
    if not base or not base:IsA("BasePart")
        or not arena or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return false end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    return typeof(sx) == "number" and typeof(sz) == "number"
        and sx >= 318 and sz >= 318
        and base.Size.X > 0 and base.Size.Z > 0
        and base.Size.X <= sx + 0.2 and base.Size.Z <= sz + 0.2
end

-- These are EXACT server-authored primitive roof/facade duplicates that
-- genuine approved meshes replace. DO NOT hide core volumetric load-bearing
-- silhouettes, foundation/LOD anchors, doors or actual sector signage.
-- The client owns only cosmetic Transparency; server physics is untouched.
local NATIVE_REPLACED = {
    AngledRoofL = true, AngledRoofR = true,
    ["TopRail-1"] = true, TopRail1 = true,
    ServiceEntryLintel = true, ServiceEntryCanopy = true,
    ["PortalHydraulicColumn-1"] = true, PortalHydraulicColumn1 = true,
    ["SurveyInstrumentCabinet-1"] = true, SurveyInstrumentCabinet1 = true,
    ["FreightWinchHousing-1"] = true, FreightWinchHousing1 = true,
    ["TurbineDuctCollar-1"] = true, TurbineDuctCollar1 = true,
    ["AerialCableConduit-1"] = true, AerialCableConduit1 = true,
}
local PROFILE_ROOF = {
    [1] = {
        ["ObservatoryFin-1"] = true, ObservatoryFin1 = true,
        OrbitalSurveyLens = true,
    },
    [2] = {
        CrossGantry = true, CabShell = true, CabGlass = true,
        ["GantryBlade-1"] = true, GantryBlade1 = true,
    },
    [3] = {
        ["VentTurbine-1"] = true, VentTurbine0 = true, VentTurbine1 = true,
        ["VentArmour-1"] = true, VentArmour0 = true, VentArmour1 = true,
    },
    [4] = {
        AerialMast = true, ["CrossAerial-1"] = true,
        CrossAerial1 = true, SignalCrystal = true,
    },
}

local function restoreNative(entry)
    for part, alpha in pairs(entry.replaced) do
        -- Never overwrite another system's newer transparency choice.
        if part.Parent == entry.building and part.Transparency == 1
            and not part.CanCollide and not part.CanTouch
            and not part.CanQuery then
            part.Transparency = alpha
        end
        entry.replaced[part] = nil
    end
end

local function suppressNative(entry)
    local roof = PROFILE_ROOF[entry.slot]
    if not roof then return end
    for _, part in ipairs(entry.building:GetChildren()) do
        if part:IsA("BasePart") and part.Parent == entry.building
            and part.Anchored and not part.CanCollide
            and not part.CanTouch and not part.CanQuery
            and (NATIVE_REPLACED[part.Name] == true
                or roof[part.Name] == true)
            and part.Transparency < 1 then
            if entry.replaced[part] == nil then
                entry.replaced[part] = part.Transparency
            end
            part.Transparency = 1
        end
    end
end

local function dispose(entry)
    for _, connection in ipairs(entry.connections or {}) do
        connection:Disconnect()
    end
    -- Restore the native art FIRST so LOD exits cannot leave holes in
    -- streamed buildings even if the imported model is removed this tick.
    restoreNative(entry)
    entry.model:Destroy()
end

local function clearMounted()
    for building, entry in pairs(mounted) do
        dispose(entry)
        mounted[building] = nil
    end
end

local function clear()
    clearMounted()
    if baseChanged then baseChanged:Disconnect() end
    baseChanged = nil
    watchedBase = nil
    holder:ClearAllChildren()
end

local function template(slot)
    local root = ReplicatedStorage:FindFirstChild("ApprovedDistrictFacadeTemplates")
    if not root or root:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = root:FindFirstChild(NAMES[slot])
    if not source or not source:IsA("Model")
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("DistrictFacade3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= IDS[slot] then
        return nil
    end
    local meshCount = 0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            meshCount += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if meshCount < 1 or meshCount > 24 then return nil end
    local _, bounds = source:GetBoundingBox()
    if bounds.X < 8 or bounds.X > 31 or bounds.Y < 12
        or bounds.Y > 48 or bounds.Z < 3 or bounds.Z > 28 then
        return nil
    end
    return source
end

local function eligible(building, district)
    if not building:IsA("Model") or building.Parent ~= district
        or building:GetAttribute("ArenaDistrictArchitecture") ~= true
        or building:GetAttribute("SourceIsOriginal") ~= true
        or building:GetAttribute("CosmeticOnly") ~= true
        or building:GetAttribute("FacadeVisualVersion") ~= 1 then
        return nil
    end
    local slot = building:GetAttribute("DistrictProfile")
    local index = building:GetAttribute("DistrictIndex")
    if type(slot) ~= "number" or slot % 1 ~= 0
        or slot < 1 or slot > 4 or type(index) ~= "number"
        or index % 1 ~= 0 or index < 1 or index > 16 then
        return nil
    end
    local door = building:FindFirstChild("ServiceEntryDoor")
    if not door or not door:IsA("Part") or door.Parent ~= building
        or door.CanCollide or door.CanQuery or door.CanTouch
        or door.Size.X < 4 or door.Size.X > 5.5
        or door.Size.Y < 4 or door.Size.Y > 5.5
        or door.Transparency >= 0.7
        or door:GetAttribute("SceneryLodHidden") == true
        or door.LocalTransparencyModifier >= 0.95 then
        return nil
    end
    return slot, door
end

local function valid(entry, district, base)
    local slot, door = eligible(entry.building, district)
    return authenticBase(base, activeArena)
        and slot == entry.slot and door == entry.door
        and (door.CFrame.Position - entry.doorFrame.Position).Magnitude < 0.08
        and (door.Size - entry.doorSize).Magnitude < 0.08
        and door.CFrame.LookVector:Dot(entry.doorFrame.LookVector) > 0.999
        and door.CFrame.RightVector:Dot(entry.doorFrame.RightVector) > 0.999
end

local function mount(building, district, base, slot, door, source)
    local clone = source:Clone()
    local sourceFrame, size = clone:GetBoundingBox()
    -- Source OBJ was authored with ground at Y=0 and centered X/Z.
    -- Recover the exact rotated server building origin from its own door.
    local origin = door.CFrame * CFrame.new(0.35, -4, 4.36)
    local target = origin * CFrame.new(0, size.Y * 0.5, 0)
    local pieces = {}
    for _, item in ipairs(clone:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            item.CFrame = target * sourceFrame:ToObjectSpace(item.CFrame)
            item.Anchored = true
            item.Massless = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
            item.CastShadow = false
            pieces[#pieces + 1] = item
        end
    end
    if #pieces < 1 or #pieces > 24 then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedOriginalDistrictFacade3D"
    -- Source was OwnerVerified/ DistrictFacade3D and passed template()
    -- validation; preserve that provenance on the actual mounted clone.
    clone:SetAttribute("OwnerVerified", true)
    clone:SetAttribute("DistrictFacade3D", true)
    clone:SetAttribute("Original3DAssetId", IDS[slot])
    clone:SetAttribute("DistrictIndex", building:GetAttribute("DistrictIndex"))
    clone:SetAttribute("CosmeticOnly", true)
    clone.Parent = holder
    local entry = {
        model = clone, building = building, door = door,
        doorFrame = door.CFrame, doorSize = door.Size,
        slot = slot, pieces = pieces, connections = {}, replaced = {},
    }
    local function immediatelyHideUnsafe()
        -- Shrink/stream-out or door motion can occur BEFORE the next LOD
        -- tick. Immediately reveal every native roofline and hide imported
        -- art, without ever revealing a non-authoritative walkable surface.
        if not valid(entry, district, base) then
            restoreNative(entry)
            for _, mesh in ipairs(entry.pieces) do
                if mesh.Parent and mesh.LocalTransparencyModifier ~= 1 then
                    mesh.LocalTransparencyModifier = 1
                end
            end
        else
            for _, mesh in ipairs(entry.pieces) do
                if mesh.Parent and mesh.LocalTransparencyModifier ~= 0 then
                    mesh.LocalTransparencyModifier = 0
                end
            end
            suppressNative(entry)
        end
    end
    entry.reconcile = immediatelyHideUnsafe
    for _, property in ipairs({"CFrame", "Size", "Transparency"}) do
        entry.connections[#entry.connections + 1] =
            door:GetPropertyChangedSignal(property):Connect(immediatelyHideUnsafe)
    end
    entry.connections[#entry.connections + 1] =
        door.AncestryChanged:Connect(immediatelyHideUnsafe)
    entry.connections[#entry.connections + 1] =
        building.AncestryChanged:Connect(immediatelyHideUnsafe)
    immediatelyHideUnsafe()
    return entry
end

function PremiumDistrictFacadeMeshKit.sync(arena, cameraPoint, tier, cameraReady, cameraLook)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        clear()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    local district = decor and decor:FindFirstChild("ArenaDistrictArchitecture3D")
    if not authenticBase(base, arena)
        or not district or not district:IsA("Folder") then
        clear()
        return
    end
    if base ~= watchedBase then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase = base
        baseChanged = base:GetPropertyChangedSignal("Size"):Connect(function()
            -- A smaller survival ring does not move its original buildings.
            -- Unmount only when the real builder-authored Base is invalid.
            if not authenticBase(base, activeArena) then
                clearMounted()
            end
        end)
    end

    local look = typeof(cameraLook) == "Vector3"
        and Vector3.new(cameraLook.X, 0, cameraLook.Z)
        or Vector3.zero
    local hasFacing = look.Magnitude > 0.2
    if hasFacing then look = look.Unit end

    local candidates = {}
    for _, building in ipairs(district:GetChildren()) do
        local slot, door = eligible(building, district)
        if slot and template(slot) then
            local delta = door.Position - cameraPoint
            local distance = delta.Magnitude
            local resident = mounted[building] ~= nil
            -- The existing model gets a small *exit-only* margin; new
            -- assets still enter within the previous strict camera range.
            if distance <= budget.distance
                + (resident and budget.retention or 0) then
                local priority = distance
                    - (resident and budget.retention * 0.55 or 0)
                local horizontal = Vector3.new(delta.X, 0, delta.Z)
                if hasFacing and horizontal.Magnitude > 42
                    and horizontal.Unit:Dot(look) < -0.15 then
                    -- Prefer true original 3D facades on screen rather
                    -- than spending precious Android meshes behind camera.
                    priority += 80
                end
                candidates[#candidates + 1] = {
                    building = building, slot = slot, door = door,
                    distance = distance, priority = priority,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.building.Name < b.building.Name
    end)
    local wanted = {}
    for i = 1, math.min(#candidates, budget.count) do
        wanted[candidates[i].building] = candidates[i]
    end
    for building, entry in pairs(mounted) do
        local desired = wanted[building]
        if not desired or desired.slot ~= entry.slot
            or not valid(entry, district, base) then
            dispose(entry)
            mounted[building] = nil
        end
    end
    for building, desired in pairs(wanted) do
        if not mounted[building] then
            mounted[building] = mount(building, district, base,
                desired.slot, desired.door, template(desired.slot))
        elseif mounted[building].reconcile then
            -- Local facade hardware may have appeared on the same tick;
            -- hide newly redundant native trim while the verified 3D lives.
            mounted[building].reconcile()
        end
    end
end

function PremiumDistrictFacadeMeshKit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model.Parent then n += 1 end
    end
    return n
end

-- Real resident native pieces replaced by owner-approved MeshParts, not
-- estimated visual progress. Shares the existing client scenery cadence.
function PremiumDistrictFacadeMeshKit.replacedNativeCount()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model.Parent then
            for native in pairs(entry.replaced) do
                if native.Parent == entry.building and native.Transparency == 1 then
                    n += 1
                end
            end
        end
    end
    return n
end

return PremiumDistrictFacadeMeshKit
