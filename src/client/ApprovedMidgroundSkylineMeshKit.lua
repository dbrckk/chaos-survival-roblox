-- Reuse four genuine, owner-approved district architecture MeshPart sources
-- as distinct outboard skyline structures in Classic Grid and Crossroads.
-- Never invent a Roblox asset, collider, playable route or client network load.
-- The EXISTING scenery-lod sampler owns all residency / mobile pressure.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpatialMidgroundSelectionRules = if script and script.Parent
    and script.Parent.Parent and script.Parent.Parent.Parent
    and ReplicatedStorage:FindFirstChild("Shared")
    and ReplicatedStorage.Shared:FindFirstChild("SpatialMidgroundSelectionRules")
    then require(ReplicatedStorage.Shared.SpatialMidgroundSelectionRules)
    else require("../shared/SpatialMidgroundSelectionRules")

local Kit = {}
local SOURCE_IDS = {
    Observatory = 132020956214241,
    Freight = 88725004643299,
    Turbine = 84217436280282,
    Aerial = 135791763112202,
}
local PROFILES = {
    Classic = {
        prefix = "ClassicBroadcastMass",
        source = {"Observatory", "Aerial", "Turbine", "Freight"},
        sizes = {
            Vector3.new(16, 10, 18), Vector3.new(16, 13, 20),
            Vector3.new(28, 8, 10), Vector3.new(24, 15, 9),
        },
    },
    Crossroads = {
        prefix = "CrossroadsTransitMass",
        source = {"Freight", "Aerial", "Observatory", "Turbine"},
        sizes = {
            Vector3.new(30, 7, 10), Vector3.new(34, 8, 10),
            Vector3.new(10, 7, 34), Vector3.new(10, 8, 30),
        },
    },
}
local BUDGET = {
    Low = {count=1, distance=230, retention=24},
    Medium = {count=2, distance=300, retention=32},
    High = {count=4, distance=405, retention=44},
}

local folder = Instance.new("Folder")
folder.Name = "OriginalMidgroundSkylineLocal"
folder:SetAttribute("CosmeticOnly", true)
folder.Parent = workspace
local activeArena = nil
local mounted = {}

local function template(name)
    local holder = ReplicatedStorage:FindFirstChild("ApprovedDistrictFacadeTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild(name)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("DistrictFacade3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= SOURCE_IDS[name] then
        return nil
    end
    local n = 0
    for _, part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return nil end
            n += 1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if n < 1 or n > 24 then return nil end
    local _, size = source:GetBoundingBox()
    if size.X < 8 or size.X > 31 or size.Y < 12
        or size.Y > 48 or size.Z < 3 or size.Z > 28 then return nil end
    return source, n
end

-- Outboard buildings never move with the shrinking gameplay floor.
-- Preserve their original perimeter while rejecting forged/expanded bases.
local function originalFootprint(base, arena)
    if not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return nil end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    if typeof(sx) ~= "number" or typeof(sz) ~= "number"
        or sx < 318 or sz < 318
        or base.Size.X <= 0 or base.Size.Z <= 0
        or base.Size.X > sx + .2 or base.Size.Z > sz + .2 then
        return nil
    end
    return sx, sz
end

local function genuineArena(arena)
    if not arena or not arena:IsA("Folder") then return nil end
    local variant = tostring(arena:GetAttribute("VariantId"))
    local profile = PROFILES[variant]
    local generated = workspace:FindFirstChild("GeneratedMap")
    if not profile or not generated or arena.Parent ~= generated then
        return nil
    end
    local base = arena:FindFirstChild("Base")
    local mid = workspace:FindFirstChild("ArenaMidgroundMassLocal")
    if not originalFootprint(base, arena)
        or not mid or not mid:IsA("Folder") or mid.Parent ~= workspace then
        return nil
    end
    return profile, base, mid, variant
end

local function nativeBody(body, base, mid, profile, variant, index)
    local originalX, originalZ = originalFootprint(base, base and base.Parent)
    if not originalX or not body or not body:IsA("BasePart") or body.Parent ~= mid
        or body.Name ~= profile.prefix .. index
        or body:GetAttribute("OriginalMidgroundSkylineIndex") ~= index
        or body:GetAttribute("OriginalMidgroundSkylineVariant") ~= variant
        or not body.Anchored or body.CanCollide or body.CanTouch
        or body.CanQuery then return false end
    if (body.Size - profile.sizes[index]).Magnitude > 0.15 then
        return false
    end
    -- All these buildings are genuinely OUTSIDE the original playable
    -- arena. Neither source art nor its old block may obscure a landing.
    local relative = base.CFrame:PointToObjectSpace(body.Position)
    local outsideX = math.abs(relative.X) -
        (originalX + body.Size.X) * 0.5
    local outsideZ = math.abs(relative.Z) -
        (originalZ + body.Size.Z) * 0.5
    return math.max(outsideX, outsideZ) >= 18
end

local function valid(entry)
    if not entry or not entry.model or entry.model.Parent ~= folder
        or not entry.arena or entry.arena ~= activeArena
        or entry.arena.Parent ~= workspace:FindFirstChild("GeneratedMap")
        or entry.base.Parent ~= entry.arena
        or entry.mid.Parent ~= workspace
        or entry.source.Parent ~= entry.sourceHolder
        or entry.sourceHolder.Parent ~= ReplicatedStorage
        or not nativeBody(entry.body, entry.base, entry.mid,
            entry.profile, entry.variant, entry.index)
        or (entry.body.Position - entry.bodyPosition).Magnitude > 0.15
        or entry.body.CFrame.LookVector:Dot(entry.bodyLook) < 0.999 then
        return false
    end
    for _, part in ipairs(entry.pieces) do
        if not part or not part:IsDescendantOf(entry.model) then return false end
    end
    return #entry.pieces >= 1 and #entry.pieces <= 24
end

local function reconcile(entry)
    local visible = valid(entry)
    for _, part in ipairs(entry.pieces) do
        if part.Parent then
            part.LocalTransparencyModifier = visible and 0 or 1
        end
    end
    for native, original in pairs(entry.native) do
        if native.Parent == entry.mid
            and native:GetAttribute("OriginalMidgroundSkylineIndex")
                == entry.index
            and native:GetAttribute("OriginalMidgroundSkylineVariant")
                == entry.variant then
            if visible then
                native.Transparency = 1
            elseif native.Transparency == 1 then
                native.Transparency = original
            end
        end
    end
end

local function unmount(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    -- Restore the native structures BEFORE removing the authentic art.
    for native, original in pairs(entry.native) do
        if native.Parent == entry.mid and native.Transparency == 1
            and native:GetAttribute("OriginalMidgroundSkylineIndex")
                == entry.index
            and native:GetAttribute("OriginalMidgroundSkylineVariant")
                == entry.variant then
            native.Transparency = original
        end
    end
    entry.model:Destroy()
end

local function clear()
    for body, entry in pairs(mounted) do
        unmount(entry)
        mounted[body] = nil
    end
end

local function mount(arena, base, mid, profile, variant, body, index, source)
    if not nativeBody(body, base, mid, profile, variant, index) then
        return nil
    end
    local clone = source:Clone()
    local _, originalSize = clone:GetBoundingBox()
    local longest = math.max(originalSize.X, originalSize.Z)
    local targetWidth = math.max(body.Size.X, body.Size.Z) * 1.02
    local scale = targetWidth / longest
    -- Do not turn a verified building into a paper-thin or huge billboard.
    if scale < 0.40 or scale > 2.60
        or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local frame, bounds = clone:GetBoundingBox()
    if bounds.Y < body.Size.Y * 0.80 or bounds.Y > 78
        or math.max(bounds.X, bounds.Z) > targetWidth * 1.12
        or math.min(bounds.X, bounds.Z) < 1.5 then
        clone:Destroy()
        return nil
    end
    local nativeMajorX = body.Size.X >= body.Size.Z
    local sourceMajorX = bounds.X >= bounds.Z
    local yaw = nativeMajorX == sourceMajorX and 0 or math.pi * 0.5
    local target = body.CFrame
        * CFrame.new(0, (bounds.Y - body.Size.Y) * 0.5, 0)
        * CFrame.Angles(0, yaw, 0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
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
    if #pieces < 1 or #pieces > 24 then
        clone:Destroy()
        return nil
    end
    local native = {}
    local nativeCount = 0
    for _, part in ipairs(mid:GetChildren()) do
        if part:IsA("BasePart")
            and part:GetAttribute("OriginalMidgroundSkylineIndex") == index
            and part:GetAttribute("OriginalMidgroundSkylineVariant")
                == variant then
            if not part.Anchored or part.CanCollide or part.CanTouch
                or part.CanQuery then
                clone:Destroy()
                return nil
            end
            native[part] = part.Transparency
            nativeCount += 1
        end
    end
    -- Low has one macro-detail; only require body + that one motif.
    if nativeCount < 2 or native[body] == nil then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedMidground_" .. variant .. "_" .. index
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("Original3DAssetId", SOURCE_IDS[profile.source[index]])
    clone:SetAttribute("OriginalMidgroundSkylineVariant", variant)
    clone:SetAttribute("OriginalMidgroundSkylineIndex", index)
    clone.Parent = folder
    local entry = {
        arena=arena, base=base, mid=mid, body=body, profile=profile,
        variant=variant, index=index, source=source,
        sourceHolder=source.Parent, model=clone, pieces=pieces,
        native=native, bodyPosition=body.Position,
        bodyLook=body.CFrame.LookVector, connections={},
    }
    local function changed()
        if not valid(entry) then reconcile(entry) end
    end
    entry.connections[#entry.connections + 1] =
        body.AncestryChanged:Connect(changed)
    entry.connections[#entry.connections + 1] =
        body:GetPropertyChangedSignal("CFrame"):Connect(changed)
    entry.connections[#entry.connections + 1] =
        body:GetPropertyChangedSignal("Size"):Connect(changed)
    entry.connections[#entry.connections + 1] =
        base:GetPropertyChangedSignal("Size"):Connect(changed)
    entry.connections[#entry.connections + 1] =
        base:GetPropertyChangedSignal("CFrame"):Connect(changed)
    entry.connections[#entry.connections + 1] =
        base:GetAttributeChangedSignal("OriginalSizeX"):Connect(changed)
    entry.connections[#entry.connections + 1] =
        base:GetAttributeChangedSignal("OriginalSizeZ"):Connect(changed)
    entry.connections[#entry.connections + 1] =
        base:GetPropertyChangedSignal("CanCollide"):Connect(changed)
    entry.connections[#entry.connections + 1] =
        base:GetPropertyChangedSignal("Anchored"):Connect(changed)
    entry.connections[#entry.connections + 1] =
        mid.AncestryChanged:Connect(changed)
    entry.connections[#entry.connections + 1] =
        source.AncestryChanged:Connect(changed)
    entry.connections[#entry.connections + 1] =
        clone.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then
                task.defer(reconcile, entry)
            end
        end)
    reconcile(entry)
    if not valid(entry) then
        unmount(entry)
        return nil
    end
    return entry
end

function Kit.sync(arena, cameraPoint, tier, cameraReady, cameraLook, pressure)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local profile, base, mid, variant = genuineArena(arena)
    local budget = BUDGET[tier] or BUDGET.Low
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    local cap = budget.count
    if tier == "Low" then
        cap = stress == 0 and 1 or 0
    elseif tier == "Medium" then
        cap = stress == 0 and 2 or (stress == 1 and 1 or 0)
    elseif tier == "High" then
        cap = stress == 0 and 4 or (stress == 1 and 2 or 0)
    end
    if not profile or not cameraReady or cap == 0
        or typeof(cameraPoint) ~= "Vector3" then
        clear()
        return
    end
    local candidates = {}
    for index = 1, 4 do
        local body = mid:FindFirstChild(profile.prefix .. index)
        local approved = template(profile.source[index])
        if approved and nativeBody(body, base, mid, profile, variant, index) then
            local distance = (body.Position - cameraPoint).Magnitude
            local previous = mounted[body] ~= nil
            if distance <= budget.distance
                + (previous and budget.retention or 0) then
                local score = distance -
                    (previous and budget.retention * 0.65 or 0)
                if typeof(cameraLook) == "Vector3"
                    and cameraLook.Magnitude > 0.5 and distance > 40 then
                    local direction = (body.Position - cameraPoint).Unit
                    score -= math.min(45, distance * 0.17) *
                        direction:Dot(cameraLook.Unit)
                end
                candidates[#candidates + 1] = {
                    body=body, source=approved, index=index, score=score,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.score == b.score then return a.index < b.index end
        return a.score < b.score
    end)
    -- Closest actual source-authenticated hero first; remaining
    -- same-budget slots go to genuinely separated outboard districts.
    -- Avoid concentrating two premium models beside one camera corner.
    local wanted = SpatialMidgroundSelectionRules.choose(candidates, cap)
    for body, entry in pairs(mounted) do
        local choice = wanted[body]
        if not choice or entry.source ~= choice.source
            or not valid(entry) then
            unmount(entry)
            mounted[body] = nil
        else
            reconcile(entry)
        end
    end
    for body, choice in pairs(wanted) do
        if not mounted[body] then
            mounted[body] = mount(arena, base, mid, profile,
                variant, body, choice.index, choice.source)
        end
    end
end

function Kit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if valid(entry) then n += 1 end
    end
    return n
end

function Kit.replacedNativeCount()
    local n = 0
    for _, entry in pairs(mounted) do
        if valid(entry) then
            for native in pairs(entry.native) do
                if native.Parent == entry.mid
                    and native.Transparency == 1 then
                    n += 1
                end
            end
        end
    end
    return n
end

return Kit
