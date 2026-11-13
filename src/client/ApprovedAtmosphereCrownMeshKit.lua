-- Source-approved continuous 3D forged crown for the actual Towers
-- atmosphere hub. Reuses the creator-owned Orbital torus Model only when
-- the authentic native crown, its provenance and ring topology all match.
-- Exactly one nonphysical seven-MeshPart visual, no imports or render loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local SOURCE_ID = 125070862497818
local DISTANCE = {Low = 230, Medium = 340, High = 480}
local RETENTION = 20

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedAtmosphereCrownLocal"
bucket:SetAttribute("CosmeticOnly", true)
bucket.Parent = workspace

local activeArena = nil
local entry = nil

local function restore()
    local old = entry
    if not old then return end
    entry = nil
    for _, connection in ipairs(old.connections) do
        connection:Disconnect()
    end
    if old.native.Parent == old.folder
        and old.native.Transparency == 1 then
        old.native.Transparency = old.original
    end
    old.model:Destroy()
end

bucket.ChildRemoved:Connect(function(child)
    if entry and child == entry.model then restore() end
end)

local function approvedSource()
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedOrbitalSignatureRingTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild("ReactorRing")
    if not source or not source:IsA("Model")
        or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalOrbitalSignatureTorus3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= SOURCE_ID then
        return nil
    end
    local count = 0
    local hasSignal = false
    for _, part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart")
                or part.CanCollide or part.CanTouch or part.CanQuery then
                return nil
            end
            count += 1
            if string.find(string.upper(part.Name), "SIGNAL", 1, true) then
                hasSignal = true
            end
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    -- The original source generator exports seven material-group
    -- MeshParts and a physical raised signal. No signal = keep the
    -- old navigation glow rather than silently rendering a dark crown.
    if count ~= 7 or not hasSignal then return nil end
    local _, bounds = source:GetBoundingBox()
    local dims = {bounds.X, bounds.Y, bounds.Z}
    table.sort(dims)
    if dims[1] < 1.05 or dims[1] > 1.60
        or dims[2] < 16.45 or dims[2] > 17.50
        or dims[3] < 16.45 or dims[3] > 17.50 then
        return nil
    end
    return source, holder, bounds
end

-- The Towers crown is a fixed elevated nonphysical structure; shrinking
-- the walkable floor must not revoke a verified seven-MeshPart torus.
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

local function realCrown(arena)
    if not arena or not arena:IsA("Folder")
        or arena.Name ~= "Arena"
        or arena:GetAttribute("VariantId") ~= "Towers" then
        return nil
    end
    local generated = workspace:FindFirstChild("GeneratedMap")
    if not generated or not generated:IsA("Folder")
        or arena.Parent ~= generated or generated.Parent ~= workspace then
        return nil
    end
    local base = arena:FindFirstChild("Base")
    local atmosphere = arena:FindFirstChild("Atmosphere")
    if not authenticBase(base, arena)
        or not atmosphere or not atmosphere:IsA("Folder")
        or atmosphere.Parent ~= arena
        or atmosphere:GetAttribute("VariantId") ~= "Towers"
        or atmosphere:GetAttribute("VisualVersion") ~= 2 then
        return nil
    end
    local native = atmosphere:FindFirstChild("TowerCrown")
    if not native or not native:IsA("Part")
        or native.Parent ~= atmosphere
        or native.Shape ~= Enum.PartType.Block
        or native.Material ~= Enum.Material.Neon
        or not native.Anchored or native.CanCollide
        or native.CanTouch or native.CanQuery
        or (native.Size - Vector3.new(20, .35, 20)).Magnitude > .08
        or (native.Position - (base.Position + Vector3.new(0, 22, 0)))
            .Magnitude > .12
        or native.CFrame.UpVector:Dot(Vector3.yAxis) < .999
        or (native.Transparency ~= 1
            and math.abs(native.Transparency - .42) > .025) then
        return nil
    end
    -- This is exclusively a decorative central crown. A player-owned
    -- part, an arbitrary same-name mesh or a playable arena route fails.
    return native, atmosphere, base
end

local function fits(entryToCheck)
    if entryToCheck.arena ~= activeArena
        or entryToCheck.model.Parent ~= bucket
        or entryToCheck.source.Parent ~= entryToCheck.holder
        or entryToCheck.holder.Parent ~= ReplicatedStorage
        or #entryToCheck.pieces ~= 7 then
        return false
    end
    local native, folder, base = realCrown(entryToCheck.arena)
    if native ~= entryToCheck.native
        or folder ~= entryToCheck.folder
        or base ~= entryToCheck.base
        or entryToCheck.source:GetAttribute("Original3DAssetId")
            ~= SOURCE_ID then return false end
    for _, part in ipairs(entryToCheck.pieces) do
        if not part:IsDescendantOf(entryToCheck.model)
            or part.CanCollide or part.CanTouch or part.CanQuery then
            return false
        end
    end
    return true
end

local function mount(arena, source, holder, dimensions)
    if entry then return end
    local native, folder, base = realCrown(arena)
    if not native then return end
    local clone = source:Clone()
    local thinAxis
    if dimensions.X < dimensions.Y and dimensions.X < dimensions.Z then
        thinAxis = "X"
    elseif dimensions.Y < dimensions.X and dimensions.Y < dimensions.Z then
        thinAxis = "Y"
    elseif dimensions.Z < dimensions.X and dimensions.Z < dimensions.Y then
        thinAxis = "Z"
    end
    if not thinAxis then clone:Destroy(); return end
    local major = math.max(dimensions.X, dimensions.Y, dimensions.Z)
    local scale = 19.45 / major
    if scale < 1.08 or scale > 1.21
        or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return
    end
    local frame, bounds = clone:GetBoundingBox()
    local ordered = {bounds.X, bounds.Y, bounds.Z}
    table.sort(ordered)
    if ordered[1] < 1.15 or ordered[1] > 1.90
        or ordered[2] < 18.75 or ordered[2] > 19.90
        or ordered[3] < 18.75 or ordered[3] > 19.90 then
        clone:Destroy()
        return
    end
    -- Original torus lies in XY with a Z normal; lay it horizontally in
    -- XZ for the real elevated Towers hub. Never modify its MeshId/UVs.
    local rotation = thinAxis == "Z" and CFrame.Angles(math.pi*.5,0,0)
        or thinAxis == "X" and CFrame.Angles(0,0,math.pi*.5)
        or CFrame.identity
    local target = CFrame.new(native.Position)*rotation
    local pieces = {}
    local signalCount = 0
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return
            end
            part.CFrame = target*frame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("CosmeticOnly", true)
            part:SetAttribute("Original3DAssetId", SOURCE_ID)
            if string.find(string.upper(part.Name), "SIGNAL", 1, true) then
                part.Color = native.Color
                part.Material = Enum.Material.Neon
                signalCount += 1
            end
            pieces[#pieces + 1] = part
        end
    end
    if #pieces ~= 7 or signalCount < 1
        or source.Parent ~= holder or not realCrown(arena) then
        clone:Destroy()
        return
    end
    clone.Name = "ApprovedTowersAtmosphereCrown3D"
    clone:SetAttribute("Original3DAssetId", SOURCE_ID)
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OriginalAtmosphereCrown3D", true)
    clone.Parent = bucket
    local newEntry = {
        arena = arena, base = base, folder = folder, native = native,
        source = source, holder = holder, model = clone,
        original = native.Transparency, pieces = pieces,
        connections = {},
    }
    entry = newEntry
    if not fits(newEntry) then restore(); return end
    native.Transparency = 1
    local function check()
        if entry == newEntry and not fits(newEntry) then restore() end
    end
    for _, object in ipairs({native, folder, arena, source, clone}) do
        newEntry.connections[#newEntry.connections + 1] =
            object.AncestryChanged:Connect(check)
    end
    newEntry.connections[#newEntry.connections + 1] =
        native:GetPropertyChangedSignal("CFrame"):Connect(check)
    newEntry.connections[#newEntry.connections + 1] =
        native:GetPropertyChangedSignal("Size"):Connect(check)
    for _, signal in ipairs({
        base:GetPropertyChangedSignal("Size"),
        base:GetPropertyChangedSignal("Anchored"),
        base:GetPropertyChangedSignal("CanCollide"),
        base:GetAttributeChangedSignal("OriginalSizeX"),
        base:GetAttributeChangedSignal("OriginalSizeZ"),
        base.AncestryChanged,
    }) do
        newEntry.connections[#newEntry.connections + 1] = signal:Connect(check)
    end
    newEntry.connections[#newEntry.connections + 1] =
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    newEntry.connections[#newEntry.connections + 1] =
        clone.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
end

function Kit.sync(arena, cameraPoint, tier, cameraReady, pressure)
    if arena ~= activeArena then
        restore()
        activeArena = arena
    end
    local level = tonumber(pressure)
    if not level or level ~= level or math.abs(level) == math.huge then
        level = 2
    end
    level = math.clamp(math.floor(level), 0, 2)
    local quality = DISTANCE[tier]
    if not quality or not cameraReady
        or typeof(cameraPoint) ~= "Vector3"
        or (level >= 1 and tier ~= "High") or level >= 2 then
        restore()
        return
    end
    local native = realCrown(arena)
    if not native then restore();return end
    if (cameraPoint - native.Position).Magnitude
        > quality + (entry and RETENTION or 0) then
        restore()
        return
    end
    local source, holder, dimensions = approvedSource()
    if not source then restore();return end
    if entry and (entry.source ~= source or not fits(entry)) then
        restore()
    end
    if not entry then mount(arena, source, holder, dimensions) end
    if entry then entry.native.Transparency = 1 end
end

function Kit.count()
    return entry and fits(entry) and 1 or 0
end

function Kit.replacedNativeCount()
    return Kit.count() == 1 and entry.native.Transparency == 1
        and 1 or 0
end

return Kit
