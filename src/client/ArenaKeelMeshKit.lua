-- Creator-owned approved Model #121436301473005, import #41669929967.
-- Genuine 3,332-triangle seven-material suspended arena undercarriage.
-- Always cosmetic: the real arena Base remains the sole solid floor.
-- Low/Medium/High keep at most 1/2/4 source-authentic 3D modules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local ASSET_ID = 121436301473005
local BUDGET = {
    Low = {count = 1, distance = 150, retention = 18},
    Medium = {count = 2, distance = 220, retention = 24},
    High = {count = 4, distance = 290, retention = 30},
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

local function removeAll()
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
        and base.Size.X >= 318 and base.Size.Z >= 318
        and base.Size.X <= 322 and base.Size.Z <= 322
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
end

function Kit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model and entry.model.Parent == bucket then n += 1 end
    end
    return n
end

return Kit
