-- Four distinct original imported 3D district facade / roofline silhouettes.
-- Reuses the one existing scenery LOD camera tick, never a new render loop.
-- All original building geometry, wayfinding signs and gameplay remain live.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PremiumDistrictFacadeMeshKit = {}
local NAMES = {"Observatory", "Freight", "Turbine", "Aerial"}
local IDS = {132020956214241, 88725004643299,
    84217436280282, 135791763112202}
local BUDGET = {
    Low = {count = 1, distance = 130},
    Medium = {count = 3, distance = 190},
    High = {count = 6, distance = 255},
}
local holder = Instance.new("Folder")
holder.Name = "ApprovedDistrictFacadesLocal"
holder.Parent = workspace
local activeArena = nil
local mounted = {}

local function clear()
    for building, entry in pairs(mounted) do
        entry.model:Destroy()
        mounted[building] = nil
    end
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
        or door.Size.Y < 4 or door.Size.Y > 5.5 then
        return nil
    end
    return slot, door
end

local function valid(entry, district)
    local slot, door = eligible(entry.building, district)
    return slot == entry.slot and door == entry.door
        and (door.CFrame.Position - entry.doorFrame.Position).Magnitude < 0.08
        and door.CFrame.LookVector:Dot(entry.doorFrame.LookVector) > 0.999
end

local function mount(building, district, slot, door, source)
    local clone = source:Clone()
    local sourceFrame, size = clone:GetBoundingBox()
    -- Source OBJ was authored with ground at Y=0 and centered X/Z.
    -- Recover the exact rotated server building origin from its own door.
    local origin = door.CFrame * CFrame.new(0.35, -4, 4.36)
    local target = origin * CFrame.new(0, size.Y * 0.5, 0)
    local pieces = 0
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
            pieces += 1
        end
    end
    if pieces < 1 or pieces > 24 then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedOriginalDistrictFacade3D"
    clone:SetAttribute("Original3DAssetId", IDS[slot])
    clone:SetAttribute("DistrictIndex", building:GetAttribute("DistrictIndex"))
    clone:SetAttribute("CosmeticOnly", true)
    clone.Parent = holder
    return {model = clone, building = building, door = door,
        doorFrame = door.CFrame, slot = slot}
end

function PremiumDistrictFacadeMeshKit.sync(arena, cameraPoint, tier, cameraReady)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        clear()
        return
    end
    local decor = arena:FindFirstChild("Decor")
    local district = decor and decor:FindFirstChild("ArenaDistrictArchitecture3D")
    if not district or not district:IsA("Folder") then
        clear()
        return
    end
    local candidates = {}
    for _, building in ipairs(district:GetChildren()) do
        local slot, door = eligible(building, district)
        if slot and template(slot) then
            local distance = (door.Position - cameraPoint).Magnitude
            if distance <= budget.distance then
                candidates[#candidates + 1] = {
                    building = building, slot = slot, door = door,
                    distance = distance,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
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
            or not valid(entry, district) then
            entry.model:Destroy()
            mounted[building] = nil
        end
    end
    for building, desired in pairs(wanted) do
        if not mounted[building] then
            mounted[building] = mount(building, district, desired.slot,
                desired.door, template(desired.slot))
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

return PremiumDistrictFacadeMeshKit
