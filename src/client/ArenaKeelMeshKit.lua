-- Creator-owned approved Model #121436301473005, import #41669929967.
-- Genuine 3,332-triangle seven-material suspended arena undercarriage.
-- Always cosmetic: the real arena Base remains the sole solid floor.
-- Low/Medium/High keep at most 1/3/5 source-authentic 3D modules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local ASSET_ID = 121436301473005
-- Five authentic undercarriages fully cover the center and all four
-- support stations on High without leaving a primitive corner pylon.
-- One model is 3,332 triangles; five are 16,660 triangles at most.
local BUDGET = {
    Low = {count = 1, distance = 150, retention = 18},
    Medium = {count = 3, distance = 225, retention = 24},
    High = {count = 5, distance = 290, retention = 30},
}
local VARIANTS = {
    Classic = true, Towers = true, Crossroads = true,
    Orbital = true, Harbor = true,
}
-- Positions remain at least 26 studs INWARD from the real 320-stud edge.
-- One central machine and four distant mechanical fields, not 3D floor tiles.
local SLOTS = {
    {name = "CentralCore", x = 0, z = 0},
    {name = "NorthWest", x = -104, z = -104},
    {name = "NorthEast", x = 104, z = -104},
    {name = "SouthWest", x = -104, z = 104},
    {name = "SouthEast", x = 104, z = 104},
}

local bucket = Instance.new("Folder")
bucket.Name = "OriginalArenaKeelLocal"
bucket.Parent = workspace

local activeArena = nil
local observedBase = nil
local baseListeners = {}
local mounted = {}

-- The approved keel occupies these exact underfloor stations. Only when a
-- genuine sanitized owner MeshPart model is mounted do we suppress the
-- overlapping, purely decorative Roblox block fallback. Every part is
-- restored on LOD exit, disaster shrink, missing asset or stream unload.
-- This eliminates floating generic pylons protruding through premium art.
-- Towers' angled braces are placed inside their corner keel module.
-- Never hide them if the genuine MeshPart module is missing or over budget.
local NATIVE_OVERLAPS = {
    NorthWest = {"UnderSupport1", "UnderSupportGlow1", "UnderTowerBrace3"},
    NorthEast = {"UnderSupport2", "UnderSupportGlow2", "UnderTowerBrace4"},
    SouthWest = {"UnderSupport3", "UnderSupportGlow3", "UnderTowerBrace2"},
    SouthEast = {"UnderSupport4", "UnderSupportGlow4", "UnderTowerBrace1"},
}
local CENTRAL_OVERLAPS = {
    -- Outer radial halves remain as visible supports beyond the 56-stud keel.
    Orbital = {"UnderOrbitalHub",
        "UnderOrbitalInnerSpoke1", "UnderOrbitalInnerSpoke2",
        "UnderOrbitalInnerSpoke3", "UnderOrbitalInnerSpoke4",
        "UnderOrbitalInnerSpoke5", "UnderOrbitalInnerSpoke6"},
    Towers = {"UnderTowerCore", "UnderTowerCoreGlow"},
    Crossroads = {"UnderCrossroadsJunction"},
}
local hiddenNatives = {}

local function restoreNativeFallbacks()
    for part, opacity in pairs(hiddenNatives) do
        if part.Parent and part.Transparency == 1
            and not part.CanCollide and not part.CanTouch
            and not part.CanQuery then
            part.Transparency = opacity
        end
        hiddenNatives[part] = nil
    end
end

local function syncNativeFallbacks(arena)
    local nativeFolder = workspace:FindFirstChild("ArenaUnderstructureLocal")
    local desired = {}
    if nativeFolder and nativeFolder:IsA("Folder") then
        for slotName, entry in pairs(mounted) do
            if entry.model and entry.model.Parent == bucket then
                local names = slotName == "CentralCore"
                    and CENTRAL_OVERLAPS[arena:GetAttribute("VariantId")]
                    or NATIVE_OVERLAPS[slotName]
                if names then
                    for _, name in ipairs(names) do
                        local part = nativeFolder:FindFirstChild(name)
                        if part and part:IsA("Part")
                            and part.Anchored and not part.CanCollide
                            and not part.CanTouch and not part.CanQuery
                            and not part.CastShadow then
                            desired[part] = true
                        end
                    end
                end
            end
        end
    end
    for part, opacity in pairs(hiddenNatives) do
        if not desired[part] then
            if part.Parent and part.Transparency == 1
                and not part.CanCollide and not part.CanTouch
                and not part.CanQuery then
                part.Transparency = opacity
            end
            hiddenNatives[part] = nil
        end
    end
    for part in pairs(desired) do
        if hiddenNatives[part] == nil then
            hiddenNatives[part] = part.Transparency
            part.Transparency = 1
        end
    end
end

local function removeAll()
    restoreNativeFallbacks()
    for key, entry in pairs(mounted) do
        if entry.model then entry.model:Destroy() end
        mounted[key] = nil
    end
end

local function clear()
    removeAll()
    for _, c in ipairs(baseListeners) do c:Disconnect() end
    table.clear(baseListeners)
    observedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

local function authentic(arena, base)
    return arena ~= nil and arena:IsA("Folder")
        and VARIANTS[arena:GetAttribute("VariantId")] == true
        and base ~= nil and base:IsA("BasePart")
        and base.Name == "Base" and base.Parent == arena
        and base.Anchored and base.CanCollide
        and typeof(base:GetAttribute("OriginalSizeX")) == "number"
        and typeof(base:GetAttribute("OriginalSizeZ")) == "number"
        and base:GetAttribute("OriginalSizeX") >= 318
        and base:GetAttribute("OriginalSizeZ") >= 318
        and base.Size.X > 0 and base.Size.Z > 0
        and base.Size.X <= base:GetAttribute("OriginalSizeX") + .2
        and base.Size.Z <= base:GetAttribute("OriginalSizeZ") + .2
        and base.Size.Y >= 1 and base.Size.Y <= 5
end

local function template()
    local holder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not holder or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild("OriginalArenaKeel")
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("PremiumArenaKeel3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= ASSET_ID then
        return nil
    end
    local count = 0
    for _, piece in ipairs(source:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then return nil end
            count += 1
        elseif piece:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, bounds = source:GetBoundingBox()
    if bounds.Y < 14 or bounds.Y > 20
        or bounds.X < 52 or bounds.X > 60
        or bounds.Z < 52 or bounds.Z > 60 then
        return nil
    end
    return source, bounds
end

local function mount(slot, base, source, bounds)
    local clone = source:Clone()
    local originalFrame = clone:GetBoundingBox()
    -- The source art origin is its center; align its TOP below the bottom
    -- of the true collision floor, leaving no phantom walkable decking.
    local target = base.CFrame * CFrame.new(slot.x,
        -base.Size.Y * 0.5 - bounds.Y * 0.5 - 0.09, slot.z)
    local n = 0
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then clone:Destroy(); return nil end
            n += 1
            part.CFrame = target * originalFrame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
        end
    end
    if n < 1 or n > 12 then clone:Destroy(); return nil end
    clone.Name = "OriginalApprovedArenaKeel_" .. slot.name
    clone:SetAttribute("Original3DAssetId", ASSET_ID)
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("PremiumArenaKeel3D", true)
    clone.Parent = bucket
    return {model = clone, baseSize = base.Size, baseCFrame = base.CFrame}
end

function Kit.sync(arena, cameraPoint, tier, cameraReady)
    if activeArena ~= arena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    if not cameraReady or not arena
        or typeof(cameraPoint) ~= "Vector3" then
        removeAll()
        return
    end
    local base = arena:FindFirstChild("Base")
    if not authentic(arena, base) then
        removeAll()
        return
    end
    if observedBase ~= base then
        for _, c in ipairs(baseListeners) do c:Disconnect() end
        table.clear(baseListeners)
        observedBase = base
        -- Instant removal on shrink/rotation. No stale full-width 3D ghost
        -- after a disaster; no polling, per-part events or RenderStepped.
        baseListeners[#baseListeners + 1] =
            base:GetPropertyChangedSignal("Size"):Connect(removeAll)
        baseListeners[#baseListeners + 1] =
            base:GetPropertyChangedSignal("CFrame"):Connect(removeAll)
        baseListeners[#baseListeners + 1] =
            base:GetPropertyChangedSignal("CanCollide"):Connect(removeAll)
        baseListeners[#baseListeners + 1] =
            base.AncestryChanged:Connect(removeAll)
    end
    local source, bounds = template()
    if not source then
        removeAll()
        return
    end
    local ranked = {}
    for _, slot in ipairs(SLOTS) do
        local location = base.CFrame:PointToWorldSpace(
            Vector3.new(slot.x, -base.Size.Y * 0.5 - bounds.Y * 0.5, slot.z))
        local distance = (cameraPoint - location).Magnitude
        local retained = mounted[slot.name] ~= nil
        if distance <= budget.distance + (retained and budget.retention or 0) then
            ranked[#ranked + 1] = {
                slot = slot, score = distance - (retained and budget.retention * 0.6 or 0),
            }
        end
    end
    table.sort(ranked, function(a, b)
        if a.score == b.score then return a.slot.name < b.slot.name end
        return a.score < b.score
    end)
    local wanted = {}
    for i = 1, math.min(budget.count, #ranked) do
        wanted[ranked[i].slot.name] = ranked[i].slot
    end
    for key, entry in pairs(mounted) do
        if not wanted[key] or entry.model.Parent ~= bucket
            or not authentic(arena, base)
            or (entry.baseSize - base.Size).Magnitude > 0.01
            or (entry.baseCFrame.Position - base.CFrame.Position).Magnitude > 0.01
            or entry.baseCFrame.LookVector:Dot(base.CFrame.LookVector) < .999
            or entry.baseCFrame.RightVector:Dot(base.CFrame.RightVector) < .999 then
            entry.model:Destroy()
            mounted[key] = nil
        end
    end
    for key, slot in pairs(wanted) do
        if not mounted[key] then
            mounted[key] = mount(slot, base, source, bounds)
        end
    end
    syncNativeFallbacks(arena)
end

function Kit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model and entry.model.Parent == bucket then n += 1 end
    end
    return n
end

return Kit
