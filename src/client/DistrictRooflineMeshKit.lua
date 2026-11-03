-- Creator-owned, approved 3D *MeshPart* architectural facade and roofline art.
-- 4 distinct source-authored UV/tangent models, one per district profile.
-- These are client-only cosmetics, NEVER the authoritative server buildings,
-- hazard labels, physics, bots, spawn pads, or walkable routes.
-- Uses the EXISTING 0.65/0.90-second scenery LOD owner; no extra frame loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DistrictRooflineMeshKit = {}
local NAMES = {
    [1] = "DistrictObservatory",
    [2] = "DistrictFreight",
    [3] = "DistrictTurbine",
    [4] = "DistrictAerial",
}
local IDS = {
    DistrictObservatory = 132020956214241,
    DistrictFreight = 88725004643299,
    DistrictTurbine = 84217436280282,
    DistrictAerial = 135791763112202,
}
local BUDGET = {
    Low = {count = 1, distance = 115, retention = 18},
    Medium = {count = 2, distance = 185, retention = 22},
    High = {count = 4, distance = 260, retention = 28},
}

local folder = Instance.new("Folder")
folder.Name = "OriginalDistrictRooflinesLocal"
folder.Parent = workspace

local mounted = {}
local activeArena = nil
local watchedBase = nil
local baseChanged = nil

local function originalDoor(structure, district)
    if not structure or not structure:IsA("Model")
        or not district or not district:IsA("Folder")
        or district.Name ~= "ArenaDistrictArchitecture3D"
        or structure.Parent ~= district
        or structure:GetAttribute("ArenaDistrictArchitecture") ~= true
        or structure:GetAttribute("SourceIsOriginal") ~= true
        or structure:GetAttribute("CosmeticOnly") ~= true
        or structure:GetAttribute("FacadeVisualVersion") ~= 1 then
        return nil
    end
    local index = structure:GetAttribute("DistrictIndex")
    local slot = structure:GetAttribute("DistrictProfile")
    if type(index) ~= "number" or index ~= math.floor(index)
        or index < 1 or index > 16
        or type(slot) ~= "number" or not NAMES[slot] then
        return nil
    end
    local door = structure:FindFirstChild("ServiceEntryDoor")
    if not door or not door:IsA("Part") or door.Parent ~= structure
        or door.CanCollide or door.CanTouch or door.CanQuery
        or door.Size.X < 4 or door.Size.X > 5.5
        or door.Size.Y < 4 or door.Size.Y > 5.5
        or door.Size.Z < 0.15 or door.Size.Z > 0.30
        or door.Transparency >= 0.7
        or door:GetAttribute("SceneryLodHidden") == true
        or door.LocalTransparencyModifier >= 0.95 then
        return nil
    end
    return door
end

local function verifiedSource(name)
    local holder = ReplicatedStorage:FindFirstChild("ApprovedDistrictRooflineTemplates")
    if not holder or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local template = holder:FindFirstChild(name)
    if not template or not template:IsA("Model")
        or template:GetAttribute("OwnerVerified") ~= true
        or template:GetAttribute("CosmeticOnly") ~= true
        or template:GetAttribute("DistrictRoofline3D") ~= true
        or template:GetAttribute("Original3DAssetId") ~= IDS[name] then
        return nil
    end
    local count = 0
    for _, instance in ipairs(template:GetDescendants()) do
        if instance:IsA("BasePart") then
            if not instance:IsA("MeshPart") then return nil end
            count += 1
        elseif instance:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 24 then return nil end
    local _, size = template:GetBoundingBox()
    if size.X < 10 or size.X > 34
        or size.Y < 17 or size.Y > 50
        or size.Z < 1 or size.Z > 24 then
        return nil
    end
    return template
end

local function hide(entry)
    for _, mesh in ipairs(entry.pieces) do
        if mesh.Parent and mesh.LocalTransparencyModifier ~= 1 then
            mesh.LocalTransparencyModifier = 1
        end
    end
end

local function safe(entry, district, base)
    return base and base.Parent and base:IsA("BasePart")
        and base.Size.X >= 318 and base.Size.Z >= 318
        and originalDoor(entry.structure, district) == entry.door
        and (entry.door.CFrame.Position - entry.originalFrame.Position).Magnitude < 0.09
        and entry.door.CFrame.RightVector:Dot(entry.originalFrame.RightVector) > 0.999
        and entry.door.CFrame.LookVector:Dot(entry.originalFrame.LookVector) > 0.999
end

local function restore(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    entry.model:Destroy()
end

local function clearMounted()
    for structure, entry in pairs(mounted) do
        restore(entry)
        mounted[structure] = nil
    end
end

local function clear()
    clearMounted()
    if baseChanged then baseChanged:Disconnect() end
    baseChanged = nil
    watchedBase = nil
    activeArena = nil
    folder:ClearAllChildren()
end

local function mount(structure, door, district, base, template)
    -- Source profile coordinates were authored in the exact same local
    -- axes as ArenaDistrictArchitecture.fixture. Keep the front entrance
    -- physically open: do not create a cosmetic opaque slab over the door.
    local sourceFrame, size = template:GetBoundingBox()
    local slot = structure:GetAttribute("DistrictProfile")
    local origin = door.CFrame * CFrame.new(0.35, -4.0, 4.36)
    -- Slot 2 owns the canonical four-sector wayfinding sign at z=-3.5.
    -- Recess its actual freight facade 3.3 studs so no imported front
    -- crosshead can obscure the existing readable navigation sign.
    local centerDepth = slot == 2 and 1.3 or -2.0
    local target = origin * CFrame.new(0, size.Y * 0.5 + 0.05, centerDepth)
    local clone = template:Clone()
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame = target * sourceFrame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            pieces[#pieces + 1] = part
        end
    end
    if #pieces == 0 or #pieces > 24 then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedOriginalDistrictRoofline3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("DistrictProfile", slot)
    clone:SetAttribute("Original3DAssetId", IDS[NAMES[slot]])
    clone.WorldPivot = target
    clone.Parent = folder

    local entry = {
        structure = structure,
        door = door,
        model = clone,
        originalFrame = door.CFrame,
        pieces = pieces,
        connections = {},
    }
    local function sourceChanged()
        -- Streamed/destroyed/repositioned buildings cannot leave 3D
        -- ghost facades: hide this real mesh immediately, dispose next tick.
        if not safe(entry, district, base) then hide(entry) end
    end
    for _, prop in ipairs({"CFrame", "Size", "Transparency"}) do
        entry.connections[#entry.connections + 1] =
            door:GetPropertyChangedSignal(prop):Connect(sourceChanged)
    end
    entry.connections[#entry.connections + 1] =
        door.AncestryChanged:Connect(sourceChanged)
    entry.connections[#entry.connections + 1] =
        structure.AncestryChanged:Connect(sourceChanged)
    sourceChanged()
    return entry
end

-- Called only by scenery-lod.client.lua's existing camera sampler AFTER
-- its own native building LOD. Zero other loops, remotes, raycasts or asset
-- downloads, and no modifications to the server collision/hazard surfaces.
function DistrictRooflineMeshKit.sync(arena, cameraPoint, tier, cameraReady, cameraLook)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        clearMounted()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    local district = decor and decor:FindFirstChild("ArenaDistrictArchitecture3D")
    if not base or not base:IsA("BasePart")
        or not district or not district:IsA("Folder")
        or base.Size.X < 318 or base.Size.Z < 318 then
        clearMounted()
        return
    end
    if base ~= watchedBase then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase = base
        -- The very first shrink step immediately removes all imported
        -- architecture even before the next Android LOD sample.
        baseChanged = base:GetPropertyChangedSignal("Size"):Connect(function()
            if base.Size.X < 318 or base.Size.Z < 318 then
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
    for _, structure in ipairs(district:GetChildren()) do
        local door = originalDoor(structure, district)
        if door then
            local name = NAMES[structure:GetAttribute("DistrictProfile")]
            local model = verifiedSource(name)
            if model then
                local delta = door.Position - cameraPoint
                local distance = delta.Magnitude
                local resident = mounted[structure] ~= nil
                if distance <= budget.distance
                    + (resident and budget.retention or 0) then
                    local priority = distance
                        - (resident and budget.retention * 0.6 or 0)
                    local horizontal = Vector3.new(delta.X, 0, delta.Z)
                    if hasFacing and horizontal.Magnitude > 42
                        and horizontal.Unit:Dot(look) < -0.15 then
                        priority += 85
                    end
                    candidates[#candidates + 1] = {
                        structure = structure, door = door, template = model,
                        distance = distance, priority = priority,
                    }
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.structure.Name < b.structure.Name
    end)

    local wanted = {}
    for i = 1, math.min(#candidates, budget.count) do
        local c = candidates[i]
        wanted[c.structure] = c
    end
    for structure, entry in pairs(mounted) do
        if not wanted[structure] or not safe(entry, district, base) then
            restore(entry)
            mounted[structure] = nil
        end
    end
    for structure, candidate in pairs(wanted) do
        if not mounted[structure] then
            mounted[structure] = mount(structure, candidate.door,
                district, base, candidate.template)
        end
    end
end

function DistrictRooflineMeshKit.count()
    local total = 0
    for _, entry in pairs(mounted) do
        if entry.model.Parent then total += 1 end
    end
    return total
end

return DistrictRooflineMeshKit
