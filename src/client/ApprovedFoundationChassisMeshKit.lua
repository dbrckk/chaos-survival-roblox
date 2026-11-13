-- Creator-owned, approved industrial chassis replace primitive foundation
-- boxes under the authentic exterior MeshParts. No new Roblox asset upload,
-- physics, per-frame worker, marketplace content or network fetch.
-- The already-existing scenery LOD loop drives every transition.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local CHASSIS_ID = 84582262145054
local EXTERIOR_ASSETS = {
    [102992487644269] = true, [119468460691888] = true,
    [137284215564363] = true, [95926792159328] = true,
    [95878714550124] = true, [135985134195364] = true,
}
-- A full, genuinely triangulated 3,072-triangle package only near-camera.
-- One ORIGINAL 7-MeshPart chassis on healthy Low, directly under one
-- real approved exterior foundation near the camera. Unlike legacy
-- Medium/High child clones, Low's model is owned by a census-visible local
-- Folder and removed under the first graphics pressure tier.
local LIMITS = {
    Low = {count = 1, distance = 128},
    Medium = {count = 1, distance = 215},
    High = {count = 2, distance = 300},
}
local bucket = Instance.new("Folder")
bucket.Name = "ApprovedFoundationChassisLocal"
bucket:SetAttribute("CosmeticOnly", true)
bucket.Parent = workspace

local mounted = {}
local activeArena = nil
local watchedBase = nil
local baseConnections = {}

local function restore(entry)
    for _, connection in ipairs(entry.connections or {}) do
        connection:Disconnect()
    end
    for part, alpha in pairs(entry.native) do
        if part.Parent == entry.owner and part.Transparency == 1
            and part:GetAttribute("OriginalFoundationVisual") == true
            and not part.CanCollide and not part.CanTouch
            and not part.CanQuery then
            part.Transparency = alpha
        end
    end
    if entry.mesh then entry.mesh:Destroy() end
end

local function unmount(owner)
    local entry = mounted[owner]
    if not entry then return end
    mounted[owner] = nil
    restore(entry)
end

local function unmountAll()
    local owners = {}
    for owner in pairs(mounted) do owners[#owners + 1] = owner end
    for _, owner in ipairs(owners) do unmount(owner) end
end

-- A budget/streaming owner can remove a Low clone before the next LOD
-- sample; never leave eleven server foundation blocks invisible.
bucket.ChildRemoved:Connect(function(child)
    for owner, entry in pairs(mounted) do
        if entry.mesh == child then
            unmount(owner)
            break
        end
    end
end)

local function clear()
    unmountAll()
    for _, connection in ipairs(baseConnections) do
        connection:Disconnect()
    end
    table.clear(baseConnections)
    watchedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

local function template()
    local holder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild("OriginalUnderdeckChassis")
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("PremiumUnderdeck3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= CHASSIS_ID then
        return nil
    end
    local count = 0
    for _, part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return nil end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = source:GetBoundingBox()
    if math.max(size.X, size.Z) < 22
        or math.max(size.X, size.Z) > 25
        or math.min(size.X, size.Z) < 8
        or math.min(size.X, size.Z) > 12
        or size.Y < 3 or size.Y > 8 then
        return nil
    end
    return source, size, count
end

-- A narrow 24x10 original is NOT a legitimate substitute for a square
-- pedestal: before masking its 4-11 native Parts check uniform-scale
-- coverage on both world-horizontal axes. This is a Low-only requirement.
local function fitFoundation(shoulder, sourceSize)
    local longAxisX = sourceSize.X > sourceSize.Z
    local nativeLongX = shoulder.Size.X > shoulder.Size.Z
    local yaw = longAxisX == nativeLongX and 0 or math.pi * .5
    local sx = yaw == 0 and sourceSize.X or sourceSize.Z
    local sz = yaw == 0 and sourceSize.Z or sourceSize.X
    local scale = math.min(1.35,
        shoulder.Size.X * .93 / sx, shoulder.Size.Z * .93 / sz)
    local covers = scale >= .48
        and sx * scale >= shoulder.Size.X * .80
        and sz * scale >= shoulder.Size.Z * .78
    return yaw, scale, covers
end

-- Foundations remain fixed outside the original 320-stud arena. The
-- gameplay floor shrinks independently; authenticate its initial footprint.
local function authenticBase(base, arena)
    if not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return false end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    return typeof(sx) == "number" and typeof(sz) == "number"
        and sx >= 318 and sz >= 318
        and base.Size.X > 0 and base.Size.Z > 0
        and base.Size.X <= sx + .2 and base.Size.Z <= sz + .2
end

local function safeOwner(arena, owner, base)
    local decor = arena and arena:FindFirstChild("Decor")
    local folder = decor and decor:FindFirstChild("Original3DScenery")
    if not authenticBase(base, arena)
        or not folder or not folder:IsA("Folder")
        or not owner or not owner:IsA("Model") or owner.Parent ~= folder
        or owner:GetAttribute("CosmeticOnly") ~= true
        or owner:GetAttribute("ChaosDistantScenery") ~= true
        or owner:GetAttribute("OriginalFoundationBuilt") ~= true
        or not EXTERIOR_ASSETS[owner:GetAttribute("Original3DAssetId")] then
        return nil
    end
    local shoulder = owner:FindFirstChild("FoundationShoulder")
    local groundPad = owner:FindFirstChild("FoundationGroundPad")
    if not shoulder or not shoulder:IsA("Part")
        or not groundPad or not groundPad:IsA("Part")
        or shoulder.Parent ~= owner or groundPad.Parent ~= owner
        or not shoulder.Anchored or shoulder.CanCollide
        or shoulder.CanTouch or shoulder.CanQuery
        or not groundPad.Anchored or groundPad.CanCollide
        or groundPad.CanTouch or groundPad.CanQuery
        or shoulder:GetAttribute("OriginalFoundationVisual") ~= true
        or groundPad:GetAttribute("OriginalFoundationVisual") ~= true
        or shoulder:GetAttribute("SceneryLodHidden") == true
        or shoulder.LocalTransparencyModifier >= .95
        or shoulder.Size.X < 6 or shoulder.Size.Z < 5 then
        return nil
    end
    return shoulder
end

local function mount(owner, shoulder, source, sourceSize, tier)
    local yaw, scale, covers = fitFoundation(shoulder, sourceSize)
    if scale < .48 or (tier == "Low" and not covers) then return nil end
    local clone = source:Clone()
    local ok = pcall(function() clone:ScaleTo(scale) end)
    if not ok then clone:Destroy(); return nil end
    local sourceFrame, bounds = clone:GetBoundingBox()
    if bounds.Y < 1.4 or bounds.Y > 10.8 then
        clone:Destroy()
        return nil
    end
    -- The source is an open-frame understructure, not an extra platform.
    -- Its highest point meets the old FoundationShoulder upper surface.
    local target = shoulder.CFrame
        * CFrame.new(0, shoulder.Size.Y * .5 - bounds.Y * .5, 0)
        * CFrame.Angles(0, yaw, 0)
    local count = 0
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            count += 1
            part.CFrame = target * sourceFrame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.Massless = true
        end
    end
    if count < 1 or count > 12
        or (tier == "Low" and count ~= 7) then
        clone:Destroy()
        return nil
    end
    local native = {}
    for _, part in ipairs(owner:GetChildren()) do
        if part:IsA("BasePart")
            and part:GetAttribute("OriginalFoundationVisual") == true
            and part.Anchored and not part.CanCollide
            and not part.CanTouch and not part.CanQuery then
            native[part] = part.Transparency
        end
    end
    -- Never hide just part of an incomplete/streaming foundation.
    if not owner:FindFirstChild("FoundationInset")
        or not owner:FindFirstChild("FoundationBallast")
        or not owner:FindFirstChild("FoundationGroundPad") then
        clone:Destroy()
        return nil
    end
    local foundationCount = 0
    for _ in pairs(native) do foundationCount += 1 end
    if foundationCount < 4
        or (tier == "Low" and
            (owner:GetAttribute("OriginalFoundationPieceCount") ~= 11
                or foundationCount ~= 11)) then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedSculptedFoundation3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OriginalFoundationMesh3D", true)
    clone:SetAttribute("Original3DAssetId", CHASSIS_ID)
    clone.WorldPivot = target
    -- The Low cosmetic must appear in the shared Android census.
    -- Medium/High keep their existing original-model parent/Lod wiring.
    local parent = tier == "Low" and bucket or owner
    clone.Parent = parent
    local entry = {owner = owner, mesh = clone, shoulder = shoulder,
        frame = shoulder.CFrame, size = shoulder.Size, native = native,
        parent = parent, source = source, connections = {}}
    mounted[owner] = entry
    for part in pairs(native) do part.Transparency = 1 end
    if tier == "Low" then
        local function invalid()
            if mounted[owner] ~= entry then return end
            if owner.Parent == nil or shoulder.Parent ~= owner
                or source.Parent == nil or clone.Parent ~= bucket
                or shoulder:GetAttribute("SceneryLodHidden") == true
                or shoulder.LocalTransparencyModifier >= .95 then
                unmount(owner)
            end
        end
        entry.connections[#entry.connections + 1] =
            owner.AncestryChanged:Connect(invalid)
        entry.connections[#entry.connections + 1] =
            shoulder.AncestryChanged:Connect(invalid)
        entry.connections[#entry.connections + 1] =
            source.AncestryChanged:Connect(invalid)
        entry.connections[#entry.connections + 1] =
            shoulder:GetAttributeChangedSignal("SceneryLodHidden"):Connect(invalid)
        entry.connections[#entry.connections + 1] =
            shoulder:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(invalid)
        entry.connections[#entry.connections + 1] =
            source.DescendantRemoving:Connect(function(part)
                if part:IsA("MeshPart") then unmount(owner) end
            end)
        entry.connections[#entry.connections + 1] =
            clone.DescendantRemoving:Connect(function(part)
                if part:IsA("MeshPart") then unmount(owner) end
            end)
    end
    return entry
end

function Kit.sync(arena, imported, cameraPoint, tier, cameraReady, pressure)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local limits = LIMITS[tier] or LIMITS.Low
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    local cap = limits.count
    if tier == "Low" and stress >= 1 then cap = 0 end
    local base = arena and arena:FindFirstChild("Base")
    if not cameraReady or typeof(cameraPoint) ~= "Vector3"
        or not arena or not authenticBase(base, arena) then
        unmountAll()
        return
    end
    if watchedBase ~= base then
        for _, connection in ipairs(baseConnections) do
            connection:Disconnect()
        end
        table.clear(baseConnections)
        watchedBase = base
        local function revokeInvalidBase()
            if not authenticBase(base, arena) then
                unmountAll()
            end
        end
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("Size"):Connect(revokeInvalidBase)
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("CFrame"):Connect(unmountAll)
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("CanCollide"):Connect(revokeInvalidBase)
        baseConnections[#baseConnections + 1] =
            base.AncestryChanged:Connect(revokeInvalidBase)
        baseConnections[#baseConnections + 1] =
            base:GetAttributeChangedSignal("OriginalSizeX"):Connect(revokeInvalidBase)
        baseConnections[#baseConnections + 1] =
            base:GetAttributeChangedSignal("OriginalSizeZ"):Connect(revokeInvalidBase)
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("Anchored"):Connect(revokeInvalidBase)
    end
    local source, sourceSize, parts = template()
    local wanted = {}
    -- On Low only verified seven-piece original material packages count.
    if source and cap > 0 and (tier ~= "Low" or parts == 7) then
        -- Imported is already camera-sorted by the authoritative LOD
        -- owner. No second scene traversal, render loop or asset request.
        for _, owner in ipairs(imported or {}) do
            if #wanted >= cap then break end
            local shoulder = safeOwner(arena, owner, base)
            if shoulder and (tier ~= "Low"
                or select(3, fitFoundation(shoulder, sourceSize)))
                and (shoulder.Position - cameraPoint).Magnitude
                    <= limits.distance then
                wanted[#wanted + 1] = {owner = owner, shoulder = shoulder}
            end
        end
    end
    local approved = {}
    for _, entry in ipairs(wanted) do approved[entry.owner] = entry.shoulder end
    for owner, entry in pairs(mounted) do
        local shoulder = approved[owner]
        if not shoulder or shoulder ~= entry.shoulder
            or entry.mesh.Parent ~= entry.parent or entry.source ~= source
            or (shoulder.CFrame.Position - entry.frame.Position).Magnitude > .08
            or shoulder.CFrame.LookVector:Dot(entry.frame.LookVector) < .999
            or (shoulder.Size - entry.size).Magnitude > .08 then
            unmount(owner)
        end
    end
    if source then
        for _, entry in ipairs(wanted) do
            if not mounted[entry.owner] then
                mount(entry.owner, entry.shoulder,
                    source, sourceSize, tier)
            end
        end
    end
end

function Kit.count()
    local n = 0
    for owner, entry in pairs(mounted) do
        if entry and entry.mesh.Parent == entry.parent then n += 1 end
    end
    return n
end

return Kit
