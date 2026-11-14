-- True 1,764-triangle, 6-material creator-approved 3D side/back wall shell.
-- Replaces ONLY five real nonphysical native district volumes, never the
-- service door, original glass, route signs, foundation or physics.
-- One existing scenery LOD camera pass owns all residency and GPU backoff.
-- Original Roblox Model 77387019170428 Approved by run #43302925840.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local ID = 77387019170428
local BUDGET = {
    -- One near-camera complete building, only if its genuine facade
    -- is already resident. Six additional approved MeshParts / 1,764
    -- triangles at most on healthy Low, zero under GPU pressure.
    Low = {count = 1, distance = 128, retention = 16},
    -- Desktop Medium matches eight existing facade slots, so more
    -- buildings show their whole real six-MeshPart envelope. Touch Medium
    -- remains capped at THREE. No new approved asset or LOD loop.
    Medium = {count = 8, distance = 205, retention = 20},
    -- Desktop High may complete all sixteen authentic buildings; touch High
    -- remains capped at eight, pressure High at five.
    High = {count = 16, distance = 275, retention = 28},
}
-- Android shares the existing 440/680/900 Parts census with all original
-- monuments. Medium touch 3 and High touch 8 models max (six MeshParts
-- each); Low spends six pieces ONLY behind a mounted approved facade.
local TOUCH_CAP = {Low = 1, Medium = 3, High = 8}
local SOURCE_FOLDER = "ApprovedDistrictSidewallShellTemplates"
local RESIDENT_MARKER = "LocalApprovedDistrictSidewallMounted"
local REQUIRED = {
    {name = "ServiceCore", size = Vector3.new(6.8, 7.3, 6.8),
        offset = CFrame.new(0, 8.4, 0)},
    {name = "ArmoredSupportL", size = Vector3.new(1.4, 12.6, 2.3),
        offset = CFrame.new(-4.4, 7.1, 1.8)},
    {name = "ArmoredSupportR", size = Vector3.new(1.4, 12.6, 2.3),
        offset = CFrame.new(4.4, 7.1, 1.8)},
    {name = "SideCassette-1", size = Vector3.new(.85, 4.8, 4.6),
        offset = CFrame.new(-3.68, 7.6, .48)},
    {name = "SideCassette1", size = Vector3.new(.85, 4.8, 4.6),
        offset = CFrame.new(3.68, 7.6, .48)},
}

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedDistrictSidewallsLocal"
bucket:SetAttribute("CosmeticOnly", true)
bucket.Parent = workspace
local activeArena = nil
local mounted = {}
local watchedBase = nil
local baseConnection = nil

local function authenticBase(base, arena)
    if not base or not base:IsA("BasePart")
        or not arena or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return false end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    return typeof(sx) == "number" and typeof(sz) == "number"
        and sx >= 318 and sz >= 318
        and base.Size.X > 0 and base.Size.Z > 0
        and base.Size.X <= sx + .2 and base.Size.Z <= sz + .2
end

local function approved()
    local folder = ReplicatedStorage:FindFirstChild(SOURCE_FOLDER)
    if not folder or not folder:IsA("Folder")
        or folder.Parent ~= ReplicatedStorage
        or folder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = folder:FindFirstChild("Sidewall")
    if not source or not source:IsA("Model") or source.Parent ~= folder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalDistrictSidewallShell3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= ID then return nil end
    local pieces = 0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            pieces += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if pieces ~= 6 then return nil end
    local _, size = source:GetBoundingBox()
    local major, minor = math.max(size.X, size.Z),
        math.min(size.X, size.Z)
    if major < 9.7 or major > 11.3 or minor < 6.8
        or minor > 8.1 or size.Y < 12.5 or size.Y > 14 then
        return nil
    end
    return source, folder
end

local function eligible(building, district, requiresFacade)
    -- A Low phone can afford only one full 3D envelope. Do not spend
    -- its six extra mesh slots on an unpaired, still-primitive facade.
    if requiresFacade == true
        and building:GetAttribute("LocalApprovedDistrictFacadeMounted") ~= true then
        return nil
    end
    if not building:IsA("Model") or building.Parent ~= district
        or building:GetAttribute("ArenaDistrictArchitecture") ~= true
        or building:GetAttribute("SourceIsOriginal") ~= true
        or building:GetAttribute("CosmeticOnly") ~= true
        or building:GetAttribute("FacadeVisualVersion") ~= 1 then return nil end
    local index = building:GetAttribute("DistrictIndex")
    local profile = building:GetAttribute("DistrictProfile")
    if type(index) ~= "number" or index % 1 ~= 0
        or index < 1 or index > 16
        or type(profile) ~= "number" or profile % 1 ~= 0
        or profile < 1 or profile > 4 then return nil end
    local door = building:FindFirstChild("ServiceEntryDoor")
    if not door or not door:IsA("Part") or door.Parent ~= building
        or not door.Anchored or door.CanCollide or door.CanTouch
        or door.CanQuery or door.Size.X < 4 or door.Size.X > 5.5
        or door.Size.Y < 4 or door.Size.Y > 5.5
        or door.Transparency >= .7
        or door.LocalTransparencyModifier >= .95
        or door:GetAttribute("SceneryLodHidden") == true then return nil end
    local origin = door.CFrame * CFrame.new(.35, -4, 4.36)
    -- All FIVE server-authored native massing pieces must be available
    -- before mounting; otherwise leave a complete original fallback.
    local resident = mounted[building]
    local natives = {}
    for _, spec in ipairs(REQUIRED) do
        local part = building:FindFirstChild(spec.name)
        local target = origin * spec.offset
        if not part or not part:IsA("Part") or part.Parent ~= building
            or not part.Anchored or part.CanCollide or part.CanTouch
            or part.CanQuery or (part.Size - spec.size).Magnitude > .08
            or (part.Position - target.Position).Magnitude > .12
            or part.CFrame.LookVector:Dot(target.LookVector) < .999
            or part.CFrame.UpVector:Dot(target.UpVector) < .999
            or (part.Transparency >= 1
                and (not resident or not resident.originals[part])) then
            return nil
        end
        natives[#natives + 1] = part
    end
    return door, origin, natives
end

-- A local, diagnostic-only signal for the matching genuine facade kit.
-- Only an authenticated six-MeshPart model can publish residency.
local function markResident(entry, present)
    local building = entry.building
    if building and building.Parent then
        local desired = present and true or nil
        if building:GetAttribute(RESIDENT_MARKER) ~= desired then
            building:SetAttribute(RESIDENT_MARKER, desired)
        end
    end
end

local function restore(entry)
    for native, alpha in pairs(entry.originals) do
        if native.Parent == entry.building and native.Transparency == 1
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery then
            native.Transparency = alpha
        end
        entry.originals[native] = nil
    end
end

local function release(building)
    local entry = mounted[building]
    if not entry then return end
    -- Removing a source MeshPart may synchronously fire multiple callbacks.
    mounted[building] = nil
    for _, conn in ipairs(entry.connections) do conn:Disconnect() end
    markResident(entry, false)
    restore(entry)
    entry.model:Destroy()
end

-- One Roblox source Model is shared by up to sixteen building owners.
-- A property event can skip callbacks as each callback disconnects itself
-- during release. Snapshot ALL affected owners and restore every native
-- shell in one source-cohort operation before the source is discarded.
local function releaseSource(source)
    local owners = {}
    for building, entry in pairs(mounted) do
        if entry.source == source then
            owners[#owners + 1] = building
        end
    end
    for _, building in ipairs(owners) do release(building) end
end

local function clear()
    local buildings = {}
    for building in pairs(mounted) do buildings[#buildings+1] = building end
    for _, building in ipairs(buildings) do release(building) end
    -- An unloaded arena must not retain a listener to its former Base.
    if baseConnection then baseConnection:Disconnect() end
    baseConnection = nil
    watchedBase = nil
end

local function valid(entry, arena, district, base)
    if entry.arena ~= arena or entry.model.Parent ~= bucket
        or entry.source.Parent ~= entry.folder
        or entry.folder.Parent ~= ReplicatedStorage
        or entry.folder:GetAttribute("OwnerVerified") ~= true
        or entry.source:GetAttribute("OwnerVerified") ~= true
        or entry.source:GetAttribute("CosmeticOnly") ~= true
        or entry.source:GetAttribute("OriginalDistrictSidewallShell3D") ~= true
        or entry.source:GetAttribute("Original3DAssetId") ~= ID
        or #entry.pieces ~= 6
        or not authenticBase(base, arena) then return false end
    local door, origin, natives = eligible(
        entry.building, district, entry.requiresFacade)
    if door ~= entry.door or not origin or not natives
        or (door.CFrame.Position - entry.doorFrame.Position).Magnitude > .10
        or door.CFrame.LookVector:Dot(entry.doorFrame.LookVector) < .999
        or door.CFrame.UpVector:Dot(entry.doorFrame.UpVector) < .999 then
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
    if actual ~= 6 then return false end
    for _, part in ipairs(entry.pieces) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    for _, part in ipairs(natives) do
        if entry.originals[part] == nil then return false end
    end
    return true
end

local function mount(arena, district, base, building, door,
        origin, natives, source, folder, requiresFacade)
    local clone = source:Clone()
    local frame, size = clone:GetBoundingBox()
    -- Roblox may swap horizontal glTF axes. Keep uniform original source
    -- scale (none) and rotate only the complete model into the district
    -- building's existing door-derived local coordinate system.
    local yaw = size.X >= size.Z and 0 or math.pi * .5
    local target = origin * CFrame.new(0, size.Y * .5, 0)
        * CFrame.Angles(0, yaw, 0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then clone:Destroy();return end
            part.CFrame = target * frame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            pieces[#pieces + 1] = part
        end
    end
    if #pieces ~= 6 then clone:Destroy();return end
    clone.Name = "ApprovedOriginalDistrictSidewall3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OwnerVerified", true)
    clone:SetAttribute("OriginalDistrictSidewallShell3D", true)
    clone:SetAttribute("Original3DAssetId", ID)
    clone:SetAttribute("DistrictIndex", building:GetAttribute("DistrictIndex"))
    clone.Parent = bucket
    local entry = {
        arena = arena, building = building, model = clone,
        source = source, folder = folder, pieces = pieces,
        door = door, doorFrame = door.CFrame,
        requiresFacade = requiresFacade,
        originals = {}, connections = {},
    }
    for _, part in ipairs(natives) do
        entry.originals[part] = part.Transparency
    end
    mounted[building] = entry
    local function reconcile()
        if mounted[building] ~= entry then return end
        if not valid(entry, arena, district, base) then
            release(building)
            return
        end
        -- Native Parts must only disappear AFTER all 6 source meshes
        -- are fully mounted and geometry/provenance was just verified.
        for _, part in ipairs(natives) do
            if part.Parent == building then part.Transparency = 1 end
        end
        markResident(entry, true)
    end
    -- If the one real Low facade is evicted by streaming, tier or GPU
    -- pressure, reveal all five original native walls immediately.
    entry.connections[#entry.connections + 1] =
        building:GetAttributeChangedSignal(
            "LocalApprovedDistrictFacadeMounted"):Connect(reconcile)
    for _, owner in ipairs({clone, building, door, base}) do
        entry.connections[#entry.connections + 1] =
            owner.AncestryChanged:Connect(reconcile)
    end
    for _, property in ipairs({"CFrame", "Size", "Transparency"}) do
        entry.connections[#entry.connections + 1] =
            door:GetPropertyChangedSignal(property):Connect(reconcile)
    end
    entry.connections[#entry.connections + 1] =
        base:GetPropertyChangedSignal("Size"):Connect(reconcile)
    entry.connections[#entry.connections + 1] =
        source.AncestryChanged:Connect(function()
            if source.Parent ~= folder or folder.Parent ~= ReplicatedStorage then
                releaseSource(source)
            end
        end)
    entry.connections[#entry.connections + 1] =
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then releaseSource(source) end
        end)
    -- Source provenance may be revoked while a clone is resident.
    -- Unmask immediately: waiting until the next camera LOD interval
    -- can otherwise leave unauthenticated shells over hidden originals.
    entry.connections[#entry.connections + 1] =
        source.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") or part:IsA("LuaSourceContainer") then
                releaseSource(source)
            end
        end)
    entry.connections[#entry.connections + 1] =
        folder:GetAttributeChangedSignal("OwnerVerified"):Connect(function()
            if folder:GetAttribute("OwnerVerified") ~= true then
                releaseSource(source)
            end
        end)
    for _, attribute in ipairs({
        "OwnerVerified", "CosmeticOnly",
        "OriginalDistrictSidewallShell3D", "Original3DAssetId",
    }) do
        entry.connections[#entry.connections + 1] =
            source:GetAttributeChangedSignal(attribute):Connect(function()
                if source:GetAttribute("OwnerVerified") ~= true
                    or source:GetAttribute("CosmeticOnly") ~= true
                    or source:GetAttribute("OriginalDistrictSidewallShell3D") ~= true
                    or source:GetAttribute("Original3DAssetId") ~= ID then
                    releaseSource(source)
                end
            end)
    end
    entry.connections[#entry.connections + 1] =
        building.ChildRemoved:Connect(function(part)
            if part == door or entry.originals[part] ~= nil then
                release(building)
            end
        end)
    -- Five native server volumes own the fallback's exact footprint.
    -- No Heartbeat or per-frame checks: only property-change signals.
    for _, native in ipairs(natives) do
        for _, property in ipairs({
            "CFrame", "Size", "Anchored",
            "CanCollide", "CanTouch", "CanQuery",
        }) do
            entry.connections[#entry.connections + 1] =
                native:GetPropertyChangedSignal(property):Connect(reconcile)
        end
    end
    entry.connections[#entry.connections + 1] =
        clone.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then release(building) end
        end)
    entry.connections[#entry.connections + 1] =
        clone.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") or part:IsA("LuaSourceContainer") then
                release(building)
            end
        end)
    -- Source and mounted MeshParts can be mutated in place without
    -- DescendantAdded/Removing. A changed MeshId, geometry or physics
    -- property must restore the five real native walls immediately.
    -- Listen only to the six already-approved pieces, never per frame.
    for _, sourcePiece in ipairs(source:GetDescendants()) do
        if sourcePiece:IsA("MeshPart") then
            for _, property in ipairs({
                "MeshId", "Size", "CFrame", "Anchored",
                "CanCollide", "CanTouch", "CanQuery",
            }) do
                entry.connections[#entry.connections + 1] =
                    sourcePiece:GetPropertyChangedSignal(property):Connect(
                        function() releaseSource(source) end)
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
                    function() release(building) end)
        end
    end
    reconcile()
end

-- Favor a WHOLE authentic building over an orphan back-wall on
-- Medium/High. Only the actual resident approved facade's client marker
-- earns this small bonus: at most 16 studs of ranking, never enough to
-- overturn the existing 80-stud off-camera penalty. Do not change Low's
-- strict paired-only rule or the Low/Medium 1/4 model limits.
function Kit.pairedPriority(priority, facadeMounted, tier)
    if type(priority) ~= "number" then return priority end
    if tier ~= "Low" and facadeMounted == true then
        return priority - 16
    end
    return priority
end

function Kit.sync(arena, cameraPoint, tier, cameraReady, touch, pressure, look)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local spec = BUDGET[tier] or BUDGET.Low
    local cap = spec.count
    if touch == true then cap = math.min(cap, TOUCH_CAP[tier] or 0) end
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    if stress == 1 then
        -- Preserve the previous desktop High pressure cap (five originals).
        -- Touch High still halves 8 -> 4, never expanding mobile residency.
        cap = math.floor(cap * .5)
        if tier == "High" then cap = math.min(cap, 5) end
    end
    if stress >= 2 then cap = 0 end
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
        if baseConnection then baseConnection:Disconnect() end
        watchedBase = base
        baseConnection = base:GetPropertyChangedSignal("Size"):Connect(function()
            if not authenticBase(base, activeArena) then clear() end
        end)
    end
    local source, folder = approved()
    if not source then clear();return end
    local horizontal = typeof(look) == "Vector3"
        and Vector3.new(look.X, 0, look.Z) or Vector3.zero
    local facing = horizontal.Magnitude > .2
    if facing then horizontal = horizontal.Unit end
    local candidates = {}
    for _, building in ipairs(district:GetChildren()) do
        local door, origin, natives = eligible(
            building, district, tier == "Low")
        if door and natives then
            local offset = door.Position-cameraPoint
            local distance = offset.Magnitude
            local held = mounted[building] ~= nil
            if distance <= spec.distance+(held and spec.retention or 0) then
                local priority = distance
                    -(held and spec.retention*.55 or 0)
                local planar = Vector3.new(offset.X,0,offset.Z)
                if facing and planar.Magnitude > 42
                    and planar.Unit:Dot(horizontal) < -.15 then
                    priority += 80
                end
                -- Both kits run in the SAME existing scenery LOD pass:
                -- facade first, sidewall second. Spend each scarce
                -- approved sidewall source on a completed building when
                -- the physical/camera ranking is otherwise comparable.
                priority = Kit.pairedPriority(priority,
                    building:GetAttribute(
                        "LocalApprovedDistrictFacadeMounted") == true, tier)
                candidates[#candidates+1] = {
                    building=building,door=door,origin=origin,natives=natives,
                    priority=priority,distance=distance,
                }
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.building.Name < b.building.Name
    end)
    local wanted={}
    local limit=math.min(cap,#candidates)
    -- Facade sync runs FIRST in the SAME existing scenery-LOD pass.
    -- Complete genuine facade owners first on Medium/High, even when
    -- mobile and emergency pressure budgets allow only 1/3/4/5 shells.
    -- A mild score bonus alone cannot guarantee complete envelopes
    -- when approved fronts span distant physical sectors.
    -- Never invent a facade: the marker is published only after its
    -- verified source is successfully mounted, and every shell retains
    -- its own native, streaming, geometry and source authentication.
    -- Complete the same real approved buildings on every Medium/High
    -- profile, including touch and GPU-pressure relief. The facade pass
    -- has already run in this LOD tick, so prioritize its authenticated
    -- resident owners before spending scarce six-MeshPart shell slots
    -- on otherwise standalone native-front buildings.
    -- Low remains strict in eligible(): never mount an unpaired shell.
    -- All source, per-device, pressure and geometry limits are unchanged.
    if tier~="Low" then
        local taken=0
        for _,candidate in ipairs(candidates) do
            if taken>=limit then break end
            if candidate.building:GetAttribute(
                "LocalApprovedDistrictFacadeMounted")==true then
                wanted[candidate.building]=candidate
                taken+=1
            end
        end
        if taken<limit then
            for _,candidate in ipairs(candidates) do
                if taken>=limit then break end
                if not wanted[candidate.building] then
                    wanted[candidate.building]=candidate
                    taken+=1
                end
            end
        end
    else
        for i=1,limit do
            wanted[candidates[i].building]=candidates[i]
        end
    end
    local obsolete={}
    for building,entry in pairs(mounted) do
        -- An existing Medium model promoted/demoted to Low must obey
        -- the same real-facade dependency, even without remounting.
        entry.requiresFacade = tier == "Low"
        if not wanted[building]
            or entry.source ~= source
            or not valid(entry,arena,district,base) then
            obsolete[#obsolete+1]=building
        end
    end
    for _,building in ipairs(obsolete) do release(building) end
    for _,chosen in ipairs(candidates) do
        if wanted[chosen.building] then
            local entry=mounted[chosen.building]
            if entry then
                -- Keep the five native volumes hidden only while their
                -- six genuine MeshParts remain alive and camera-resident.
                for native in pairs(entry.originals) do
                    if native.Parent==chosen.building then
                        native.Transparency=1
                    end
                end
            else
                mount(arena,district,base,chosen.building,chosen.door,
                    chosen.origin,chosen.natives,source,folder,
                    tier == "Low")
            end
        end
    end
end

function Kit.count()
    local n=0
    for _,entry in pairs(mounted) do
        if entry.model.Parent==bucket then n+=1 end
    end
    return n
end

-- Exact live count, not a source-inventory percentage. Scenery LOD
-- samples at most 12 mounted source records, with no extra workspace
-- traversal, frame heartbeat, mesh import or budget slot.
-- Exact 16-bit visibility census for the one active map; a bit means
-- a real owner-verified six-MeshPart sidewall remains installed, not that
-- the static server authored a native part. No new sampler or render loop.
function Kit.residentMask16()
    local mask = 0
    for building, entry in pairs(mounted) do
        local index = building:GetAttribute("DistrictIndex")
        if entry.model.Parent == bucket and building.Parent
            and building:GetAttribute(RESIDENT_MARKER) == true
            and type(index) == "number" and index % 1 == 0
            and index >= 1 and index <= 16 then
            mask = bit32.bor(mask, bit32.lshift(1, index - 1))
        end
    end
    return mask
end

function Kit.completeCount()
    local n = 0
    for building, entry in pairs(mounted) do
        if entry.model.Parent == bucket
            and building:GetAttribute(
                "LocalApprovedDistrictFacadeMounted") == true then
            n += 1
        end
    end
    return n
end

function Kit.replacedNativeCount()
    local n=0
    for _,entry in pairs(mounted) do
        if entry.model.Parent==bucket then
            for native in pairs(entry.originals) do
                if native.Parent==entry.building
                    and native.Transparency==1 then n+=1 end
            end
        end
    end
    return n
end

return Kit
