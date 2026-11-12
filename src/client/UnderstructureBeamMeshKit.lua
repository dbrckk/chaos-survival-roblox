-- Authentic Roblox owner-approved seven-material 3,072-triangle underdeck
-- Model #84582262145054, already in the server's sanitized route inventory.
-- Replace only MARKED nonphysical understructure beam segments. Native
-- cosmetic parts remain exact fallbacks if import, quality or streaming fails.
-- Driven solely by the existing scenery-lod.client.lua sampler.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local ASSET_ID = 84582262145054
-- Each approved chassis instance is exactly 3,072 source triangles and
-- at most seven real MeshParts. Cap residency rather than stamping more
-- native blocks: Android Low stays at one, Medium four, High twelve.
-- High therefore draws at most 36,864 chassis triangles / 84 MeshParts.
-- Models share one verified source mesh package and remain camera-ranked.
local BUDGET = {
    Low = {count = 1, distance = 140, retention = 14},
    Medium = {count = 4, distance = 225, retention = 22},
    High = {count = 12, distance = 290, retention = 25},
}
local VARIANTS = {Classic = true, Crossroads = true, Towers = true, Harbor = true, Orbital = true}

local bucket = Instance.new("Folder")
bucket.Name = "OriginalUnderstructureBeamsLocal"
bucket.Parent = workspace

local activeArena = nil
local watchedBase = nil
local baseConnections = {}
local mounted = {}

-- A missing original source Part, streamed MeshPart or budget-evicted
-- clone must NEVER leave an invisible native understructure. Release its
-- exact owner before destroying the model so callbacks cannot recurse.
local function release(name)
    local entry=mounted[name]
    if not entry then return end
    mounted[name]=nil
    for _,conn in ipairs(entry.connections or {}) do
        conn:Disconnect()
    end
    if entry.native and entry.native.Parent
        and entry.native:GetAttribute("OriginalUnderstructureBeam") == true
        and not entry.native.CanCollide and not entry.native.CanTouch
        and not entry.native.CanQuery
        and entry.native.Transparency == 1 then
        entry.native.Transparency=entry.originalTransparency
    end
    if entry.model then entry.model:Destroy() end
end

local function removeAll()
    local keys={}
    for key in pairs(mounted) do keys[#keys+1]=key end
    for _,key in ipairs(keys) do release(key) end
end

bucket.ChildRemoved:Connect(function(child)
    for name,entry in pairs(mounted) do
        if entry.model==child then
            release(name)
            break
        end
    end
end)

local function clear()
    removeAll()
    for _, connection in ipairs(baseConnections) do connection:Disconnect() end
    table.clear(baseConnections)
    watchedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

local function validArena(arena, base)
    return arena ~= nil and arena:IsA("Folder")
        and VARIANTS[arena:GetAttribute("VariantId")] == true
        and base and base:IsA("BasePart")
        and base.Name == "Base" and base.Parent == arena
        and base.Anchored and base.CanCollide
        and base.Size.X >= 318 and base.Size.X <= 322
        and base.Size.Z >= 318 and base.Size.Z <= 322
        and base.Size.Y >= 1 and base.Size.Y <= 5
end

local function sourceTemplate()
    local holder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not holder or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild("OriginalUnderdeckChassis")
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("PremiumUnderdeck3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= ASSET_ID then
        return nil
    end
    local count = 0
    for _, descendant in ipairs(source:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not descendant:IsA("MeshPart") then return nil end
            count += 1
        elseif descendant:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = source:GetBoundingBox()
    local length = math.max(size.X, size.Z)
    local width = math.min(size.X, size.Z)
    if length < 22 or length > 25 or width < 8 or width > 12
        or size.Y < 3 or size.Y > 8 then
        return nil
    end
    return source, size, count
end

local function safeCandidate(part, folder)
    return part ~= nil and part:IsA("Part") and part.Parent == folder
        and part:GetAttribute("OriginalUnderstructureBeam") == true
        and (part.Name:match("^UnderClassicBeam[XY]%d+$") ~= nil
            or part.Name:match("^UnderCrossroadsBeam[NEWS]%d+$") ~= nil
            or part.Name:match("^UnderTowersBeam[XY]%d+$") ~= nil
            or part.Name:match("^UnderHarborBeam[XY]%d+$") ~= nil
            or part.Name:match("^UnderOrbitalBeam%d+$") ~= nil
            or part.Name:match("^UnderOrbitalOuterSpoke%d+$") ~= nil
            or part.Name:match("^UnderRibBeam%d+_%d+$") ~= nil
            or part.Name:match("^UnderClassicDataBay[LR]$") ~= nil)
        and part.Anchored and not part.CanCollide
        and not part.CanTouch and not part.CanQuery
        and part.Size.Y >= 1 and part.Size.Y <= 3
        and math.max(part.Size.X, part.Size.Z) >= 22
        and math.max(part.Size.X, part.Size.Z) <= 25
end

local function mount(native, source, bounds)
    local clone = source:Clone()
    local sourceFrame = clone:GetBoundingBox()
    -- Original imported asset may be rotated 90 degrees by Roblox. Match
    -- the real segment orientation without altering any server geometry.
    local originalAlongX = bounds.X > bounds.Z
    local nativeAlongX = native.Size.X > native.Size.Z
    local yaw = originalAlongX == nativeAlongX and 0 or math.pi * .5
    local center = native.CFrame * CFrame.new(
        0, native.Size.Y * .5 - bounds.Y * .5 - .17, 0
    ) * CFrame.Angles(0, yaw, 0)
    local count = 0
    for _, piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            count += 1
            piece.CFrame = center * sourceFrame:ToObjectSpace(piece.CFrame)
            piece.Anchored = true
            piece.Massless = true
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece.CastShadow = false
        end
    end
    if count < 1 or count > 12 then clone:Destroy(); return nil end
    clone.Name = "OriginalApprovedUnderstructure3D_" .. native.Name
    clone:SetAttribute("Original3DAssetId", ASSET_ID)
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OriginalUnderstructure3D", true)
    clone.Parent = bucket
    local originalTransparency = native.Transparency
    native.Transparency = 1
    local name=native.Name
    local entry={
        model=clone,native=native,source=source,
        originalTransparency=originalTransparency,connections={},
    }
    -- Exact source and native ancestry events: no polling or new frame
    -- connection, immediate safe fallback when streaming removes geometry.
    entry.connections[#entry.connections+1]=
        native.AncestryChanged:Connect(function()
            local sourceFolder=workspace:FindFirstChild("ArenaUnderstructureLocal")
            if mounted[name]==entry
                and (native.Parent==nil or not sourceFolder
                    or not safeCandidate(native,sourceFolder)) then
                release(name)
            end
        end)
    entry.connections[#entry.connections+1]=
        source.AncestryChanged:Connect(function()
            if mounted[name]==entry and not source.Parent then
                release(name)
            end
        end)
    entry.connections[#entry.connections+1]=
        source.DescendantRemoving:Connect(function(child)
            if mounted[name]==entry and child:IsA("MeshPart") then
                release(name)
            end
        end)
    entry.connections[#entry.connections+1]=
        clone.DescendantRemoving:Connect(function(child)
            if mounted[name]==entry and child:IsA("MeshPart") then
                release(name)
            end
        end)
    return entry
end

function Kit.sync(arena, cameraPoint, tier, cameraReady, pressure)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local cap=budget.count
    -- Understructure is optional: on mobile Low the FIRST backpressure
    -- step releases its one 3K-triangle chassis, not server-owned beams.
    if tier=="Low" and stress>=1 then cap=0 end
    if not arena or not cameraReady
        or typeof(cameraPoint) ~= "Vector3" then
        removeAll()
        return
    end
    local base = arena:FindFirstChild("Base")
    local folder = workspace:FindFirstChild("ArenaUnderstructureLocal")
    if not validArena(arena, base) or not folder
        or not folder:IsA("Folder") then
        removeAll()
        return
    end
    if watchedBase ~= base then
        for _, connection in ipairs(baseConnections) do connection:Disconnect() end
        table.clear(baseConnections)
        watchedBase = base
        -- Shrink and map-unload restore the actual native fallback BEFORE
        -- the next LOD tick; no phantom decorative platform can remain.
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("Size"):Connect(removeAll)
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("CFrame"):Connect(removeAll)
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("CanCollide"):Connect(removeAll)
        baseConnections[#baseConnections + 1] =
            base.AncestryChanged:Connect(removeAll)
    end
    local source, bounds, pieces = sourceTemplate()
    if not source or (tier=="Low" and pieces~=7) then
        removeAll()
        return
    end
    local ranked = {}
    for _, part in ipairs(folder:GetChildren()) do
        if safeCandidate(part, folder) then
            local distance = (cameraPoint - part.Position).Magnitude
            local retained = mounted[part.Name] ~= nil
            if distance <= budget.distance
                + (retained and budget.retention or 0) then
                ranked[#ranked + 1] = {
                    native = part,
                    score = distance - (retained and budget.retention * .6 or 0),
                }
            end
        end
    end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        return a.native.Name < b.native.Name
    end)
    local wanted = {}
    for i = 1, math.min(#ranked, cap) do
        wanted[ranked[i].native.Name] = ranked[i].native
    end
    local evicted={}
    for name,entry in pairs(mounted) do
        if wanted[name]~=entry.native or entry.model.Parent~=bucket
            or entry.source~=source
            or not safeCandidate(entry.native,folder) then
            evicted[#evicted+1]=name
        end
    end
    for _,name in ipairs(evicted) do release(name) end
    for name, native in pairs(wanted) do
        if not mounted[name] then
            mounted[name] = mount(native, source, bounds)
        end
    end
end

function Kit.reset()
    clear()
end

function Kit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model and entry.model.Parent == bucket then n += 1 end
    end
    return n
end

return Kit
