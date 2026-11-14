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
-- Eight nearby complete roofline profiles on desktop Medium instead of
-- five: same four approved assets, same camera LOD, no added imports.
-- Android Medium remains capped at THREE by TOUCH_CAP below.
-- Low Android retains one verified model, keeping its original GPU bound.
-- Exact camera-ranked residency with exit-only hysteresis, no new loops.
local BUDGET = {
    Low = {count = 1, distance = 130, retention = 16},
    Medium = {count = 8, distance = 205, retention = 22},
    High = {count = 16, distance = 270, retention = 28},
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
local RESIDENT_MARKER = "LocalApprovedDistrictFacadeMounted"

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

-- The marker belongs exclusively to this local approved MeshPart owner.
-- The door/wayfinding/structural fallback remains intact on every tier.
local function markResident(entry, present)
    local model = entry.building
    if model and model.Parent then
        local target = present and true or nil
        if model:GetAttribute(RESIDENT_MARKER) ~= target then
            model:SetAttribute(RESIDENT_MARKER, target)
        end
    end
end

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
    -- A local Medium/High optional Part can have been destroyed by the
    -- detail kit after its genuine mesh replacement became resident.
    -- Drop those stale references; the native server Parts stay tracked.
    for part in pairs(entry.replaced) do
        if part.Parent ~= entry.building then entry.replaced[part] = nil end
    end
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
    if entry.disposed then return end
    entry.disposed = true
    -- A clone/source ancestry callback may fire synchronously while the
    -- model is destroyed. Clear the mounted identity BEFORE destroying it.
    if mounted[entry.building] == entry then
        mounted[entry.building] = nil
    end
    for _, connection in ipairs(entry.connections or {}) do
        connection:Disconnect()
    end
    markResident(entry, false)
    -- Restore native geometry BEFORE its genuine 3D source disappears.
    restoreNative(entry)
    entry.model:Destroy()
end

local function clearMounted()
    local cohort = {}
    for _, entry in pairs(mounted) do cohort[#cohort + 1] = entry end
    for _, entry in ipairs(cohort) do dispose(entry) end
end

-- A single approved profile is reused across up to four buildings.
-- Releasing only one entry from each source signal risks leaving other
-- facades visible over hidden native rooflines during callback teardown.
-- Snapshot and release the entire source cohort synchronously.
local function revokeSource(source)
    local cohort = {}
    for _, entry in pairs(mounted) do
        if entry.source == source then cohort[#cohort + 1] = entry end
    end
    for _, entry in ipairs(cohort) do dispose(entry) end
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
    if not root or not root:IsA("Folder")
        or root.Parent ~= ReplicatedStorage
        or root:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = root:FindFirstChild(NAMES[slot])
    if not source or not source:IsA("Model")
        or source.Parent ~= root
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
    if entry.disposed or entry.model.Parent ~= holder
        or entry.source.Parent ~= entry.sourceFolder
        or entry.sourceFolder.Parent ~= ReplicatedStorage
        or entry.sourceFolder.Name ~= "ApprovedDistrictFacadeTemplates"
        or entry.sourceFolder:GetAttribute("OwnerVerified") ~= true
        or entry.source:GetAttribute("OwnerVerified") ~= true
        or entry.source:GetAttribute("CosmeticOnly") ~= true
        or entry.source:GetAttribute("DistrictFacade3D") ~= true
        or entry.source:GetAttribute("Original3DAssetId") ~= IDS[entry.slot]
        or #entry.pieces < 1 or #entry.pieces > 24 then
        return false
    end
    local actual = 0
    for _, part in ipairs(entry.model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or not part.Anchored
                or part.CanCollide or part.CanTouch or part.CanQuery
                or not part.Massless then return false end
            actual += 1
        elseif part:IsA("LuaSourceContainer") then
            return false
        end
    end
    if actual ~= #entry.pieces then return false end
    for _, part in ipairs(entry.pieces) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
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
        slot = slot, pieces = pieces, source = source,
        sourceFolder = source.Parent, connections = {}, replaced = {},
    }
    local function immediatelyHideUnsafe()
        if entry.disposed then return end
        -- Shrink/stream-out or door motion can occur BEFORE the next LOD
        -- tick. Immediately reveal every native roofline and hide imported
        -- art, without ever revealing a non-authoritative walkable surface.
        if not valid(entry, district, base) then
            markResident(entry, false)
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
            markResident(entry, true)
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
    -- A local visual budget eviction or streamed-out imported MeshPart
    -- must reveal native geometry now, not after an unrelated camera move.
    local function revokeIfMounted()
        if mounted[building] == entry then dispose(entry) end
    end
    entry.connections[#entry.connections + 1] =
        clone.AncestryChanged:Connect(function()
            if clone.Parent ~= holder then revokeIfMounted() end
        end)
    entry.connections[#entry.connections + 1] =
        clone.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then revokeIfMounted() end
        end)
    -- An extra injected primitive or script must never be allowed to
    -- coexist with a locally hidden original facade. Fall back instantly.
    entry.connections[#entry.connections + 1] =
        clone.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") or part:IsA("LuaSourceContainer") then
                revokeIfMounted()
            end
        end)
    entry.connections[#entry.connections + 1] =
        source.AncestryChanged:Connect(function()
            if source.Parent ~= entry.sourceFolder
                or entry.sourceFolder.Parent ~= ReplicatedStorage then
                revokeSource(source)
            end
        end)
    entry.connections[#entry.connections + 1] =
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then revokeSource(source) end
        end)
    entry.connections[#entry.connections + 1] =
        source.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") or part:IsA("LuaSourceContainer") then
                revokeSource(source)
            end
        end)
    entry.connections[#entry.connections + 1] =
        entry.sourceFolder:GetAttributeChangedSignal(
            "OwnerVerified"):Connect(function()
                if entry.sourceFolder:GetAttribute("OwnerVerified") ~= true then
                    clearMounted()
                end
            end)
    for _, attribute in ipairs({
        "OwnerVerified", "CosmeticOnly", "DistrictFacade3D",
        "Original3DAssetId",
    }) do
        entry.connections[#entry.connections + 1] =
            source:GetAttributeChangedSignal(attribute):Connect(function()
                if not valid(entry, district, base) then
                    revokeSource(source)
                end
            end)
    end
    -- In-place source/clone mutation does not emit ancestry or
    -- descendant events. Never leave the native roof hidden after a
    -- mesh's geometry, collision or anchoring changes. Bind once per
    -- resident model; dispose disconnects all of these signals.
    for _, sourcePiece in ipairs(source:GetDescendants()) do
        if sourcePiece:IsA("MeshPart") then
            for _, property in ipairs({
                "MeshId", "Size", "CFrame", "Anchored",
                "CanCollide", "CanTouch", "CanQuery",
            }) do
                entry.connections[#entry.connections + 1] =
                    sourcePiece:GetPropertyChangedSignal(property):Connect(
                        function() revokeSource(source) end)
            end
        end
    end
    for _, piece in ipairs(pieces) do
        for _, property in ipairs({
            "MeshId", "Size", "CFrame", "Anchored", "Massless",
            "CanCollide", "CanTouch", "CanQuery",
        }) do
            entry.connections[#entry.connections + 1] =
                piece:GetPropertyChangedSignal(property):Connect(
                    revokeIfMounted)
        end
    end
    immediatelyHideUnsafe()
    return entry
end

-- The approved rear/side shell owner runs after this facade owner on
-- each camera pass. On Medium/High a previously authenticated six-mesh
-- sidewall can exist with an unmounted/streamed-out front. A small symmetric
-- rank bonus lets the NEXT camera pass complete that building, without
-- adding facade models, prioritizing offscreen structures or touching Low.
function PremiumDistrictFacadeMeshKit.pairedPriority(priority, sidewallMounted, tier)
    if type(priority) ~= "number" then return priority end
    if tier ~= "Low" and sidewallMounted == true then
        return priority - 12
    end
    return priority
end

-- On healthy desktop High, all SIXTEEN genuine district buildings can
-- display existing owner-approved roof/facade originals rather than their
-- simple block rooflines. No new assets or source imports. Touch still caps
-- at 1/3/8 and GPU pressure 1 retains the old desktop High maximum of
-- SIX: quality upgrades cannot compete with emergency pressure relief.
-- At pressure 2 restore every native roofline.
-- This prevents genuine sidewall fallbacks from leaving an expensive
-- facade still consuming mobile render budget without its 3D envelope.
local TOUCH_CAP = {Low = 1, Medium = 3, High = 8}

function PremiumDistrictFacadeMeshKit.residentBudget(tier, touch, pressure)
    local spec = BUDGET[tier] or BUDGET.Low
    local cap = spec.count
    if touch == true then
        cap = math.min(cap, TOUCH_CAP[tier] or 0)
    end
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    if stress >= 2 then return 0 end
    if stress == 1 then
        local reduced = math.floor(cap * .5)
        return tier == "High" and math.min(reduced, 6) or reduced
    end
    return cap
end

function PremiumDistrictFacadeMeshKit.sync(arena, cameraPoint, tier, cameraReady, cameraLook, touch, pressure)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    local cap = PremiumDistrictFacadeMeshKit.residentBudget(
        tier, touch, pressure)
    if cap == 0 or not arena or not cameraReady
        or typeof(cameraPoint) ~= "Vector3" then
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

    -- The SAME four approved source profiles may serve sixteen buildings.
    -- Validate each source once per existing scenery LOD sample instead of
    -- repeating OwnerVerified, 3D bounds and descendant scans for every
    -- candidate, then once again for each mounted facade. Keep this cache
    -- local to ONE synchronous sample so streamed source changes remain
    -- subject to verification on the very next sample.
    local approvedByProfile = {}
    for profile = 1, 4 do
        approvedByProfile[profile] = template(profile)
    end
    local candidates = {}
    for _, building in ipairs(district:GetChildren()) do
        local slot, door = eligible(building, district)
        if slot and approvedByProfile[slot] then
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
                priority = PremiumDistrictFacadeMeshKit.pairedPriority(
                    priority, building:GetAttribute(
                        "LocalApprovedDistrictSidewallMounted") == true, tier)
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
    local limit = math.min(#candidates, cap)
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    -- The same eight approved facade slots used to cluster along one
    -- promenade on healthy desktop Medium. Keep the nearest THREE
    -- authentic models, then complete different visible district sectors
    -- using their existing validated building/door owners. The following
    -- sidewall pass prioritizes these resident facades, giving a full
    -- original 3D envelope rather than eight unrelated half-buildings.
    -- Touch, Low, High and GPU pressure preserve their prior priorities.
    if tier == "Medium" and touch ~= true and stress == 0
        and limit > 3 then
        local foreground = math.min(limit, 3)
        for i = 1, foreground do
            local item = candidates[i]
            wanted[item.building] = item
        end
        local taken = foreground
        local spacingCap = math.max(base.Size.X, base.Size.Z) * .65
        while taken < limit do
            local winner, winnerScore = nil, -math.huge
            for _, candidate in ipairs(candidates) do
                if not wanted[candidate.building] then
                    local nearest = spacingCap
                    for building in pairs(wanted) do
                        local otherDoor = building:FindFirstChild(
                            "ServiceEntryDoor")
                        if otherDoor and otherDoor:IsA("BasePart") then
                            local delta = candidate.door.Position
                                - otherDoor.Position
                            nearest = math.min(nearest,
                                Vector3.new(delta.X, delta.Y * .65,
                                    delta.Z).Magnitude)
                        end
                    end
                    local score = nearest - candidate.priority * .14
                    if score > winnerScore or (score == winnerScore
                        and winner and candidate.building.Name
                            < winner.building.Name) then
                        winner, winnerScore = candidate, score
                    end
                end
            end
            if not winner then break end
            wanted[winner.building] = winner
            taken += 1
        end
    else
        for i = 1, limit do
            wanted[candidates[i].building] = candidates[i]
        end
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
                desired.slot, desired.door, approvedByProfile[desired.slot])
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
-- A bit is present only for a live, model-verified, visible original
-- facade on a real district owner. Streamed-out or LOD-evicted owners
-- never count, regardless of native Parts existing in the server.
function PremiumDistrictFacadeMeshKit.residentMask16()
    local mask = 0
    for building, entry in pairs(mounted) do
        local index = building:GetAttribute("DistrictIndex")
        if not entry.disposed and entry.model.Parent == holder
            and building.Parent
            and building:GetAttribute(RESIDENT_MARKER) == true
            and type(index) == "number" and index % 1 == 0
            and index >= 1 and index <= 16 then
            mask = bit32.bor(mask, bit32.lshift(1, index - 1))
        end
    end
    return mask
end

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
