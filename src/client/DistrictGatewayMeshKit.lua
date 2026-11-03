-- Genuine creator-owned 3D industrial gate artwork, mounted only over
-- authenticated district service entries. Existing server doors, district
-- silhouettes, hazard paint, AI navigation and physics are untouched.
-- Shares scenery-lod.client.lua's only camera/quality scheduler.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DistrictGatewayMeshKit = {}
local APPROVED_ID = 137284215564363
local TEMPLATE_NAME = "OriginalDistrictGate"
local BUDGET = {
    Low = {count = 1, distance = 112, retention = 16},
    Medium = {count = 2, distance = 180, retention = 22},
    High = {count = 4, distance = 245, retention = 28},
}

local folder = Instance.new("Folder")
folder.Name = "OriginalDistrictGatewaysLocal"
folder.Parent = workspace

local mounted = {}
local activeArena = nil

local function permittedStructure(model, district)
    if not model or not model:IsA("Model")
        or model.Parent ~= district
        or not district or not district:IsA("Folder")
        or district.Name ~= "ArenaDistrictArchitecture3D"
        or model:GetAttribute("ArenaDistrictArchitecture") ~= true
        or model:GetAttribute("SourceIsOriginal") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("FacadeVisualVersion") ~= 1 then
        return nil
    end
    local index = model:GetAttribute("DistrictIndex")
    if type(index) ~= "number" or index % 1 ~= 0
        or index < 1 or index > 16 then
        return nil
    end
    local door = model:FindFirstChild("ServiceEntryDoor")
    if not door or not door:IsA("Part")
        or door.Parent ~= model
        or door.Size.X < 4 or door.Size.X > 5.5
        or door.Size.Y < 4 or door.Size.Y > 5.5
        or door.Size.Z < 0.15 or door.Size.Z > 0.30
        or door.CanCollide or door.CanTouch or door.CanQuery then
        return nil
    end
    return door
end

local function template()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedDistrictGatewayTemplates")
    if not holder or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local model = holder:FindFirstChild(TEMPLATE_NAME)
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("DistrictGatewayTemplate") ~= true
        or model:GetAttribute("Original3DAssetId") ~= APPROVED_ID then
        return nil
    end
    local meshCount = 0
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not descendant:IsA("MeshPart") then return nil end
            meshCount += 1
        elseif descendant:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if meshCount == 0 or meshCount > 24 then return nil end
    local _, size = model:GetBoundingBox()
    if size.X < 6 or size.X > 18
        or size.Y < 7 or size.Y > 18
        or size.Z <= 0 or size.Z > 8 then
        return nil
    end
    return model
end

local function hide(entry)
    for _, part in ipairs(entry.pieces) do
        if part.Parent and part.LocalTransparencyModifier ~= 1 then
            part.LocalTransparencyModifier = 1
        end
    end
end

local function isStillValid(entry, district)
    return permittedStructure(entry.structure, district) == entry.door
        and entry.door.Parent == entry.structure
        and (entry.door.CFrame.Position - entry.doorFrame.Position).Magnitude < 0.08
        and entry.door.CFrame.LookVector:Dot(entry.doorFrame.LookVector) > 0.999
        and entry.door.CFrame.RightVector:Dot(entry.doorFrame.RightVector) > 0.999
end

local function restore(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    if entry.model then entry.model:Destroy() end
end

local function clear()
    for structure, entry in pairs(mounted) do
        restore(entry)
        mounted[structure] = nil
    end
    folder:ClearAllChildren()
end

local function mount(structure, door, district, source)
    local clone = source:Clone()
    local _, bounds = clone:GetBoundingBox()
    -- A true architectural arch must wrap the 4.65 x 4.68 service entry,
    -- without spanning a playable skybridge or becoming a phantom door.
    local scale = math.min(10.8 / bounds.X, 11.8 / bounds.Y, 1)
    if scale < 0.55 then clone:Destroy(); return nil end
    if not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local sourceFrame, size = clone:GetBoundingBox()
    if size.X < 5.5 or size.X > 11
        or size.Y < 6 or size.Y > 12
        or size.Z > 6.7 then
        clone:Destroy()
        return nil
    end

    -- The original door's transform is authored as
    -- origin * CFrame.new(-0.35, 4, -4.36). Keep the imported arch ahead
    -- of the door, with its base at the REAL existing arena floor.
    local buildingOrigin = door.CFrame * CFrame.new(0.35, -4, 4.36)
    local target = buildingOrigin
        * CFrame.new(0, size.Y * 0.5 + 0.10, -6.15)
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

    clone.Name = "ApprovedOriginalDistrictGateway3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("Original3DAssetId", APPROVED_ID)
    clone:SetAttribute("DistrictIndex", structure:GetAttribute("DistrictIndex"))
    clone.WorldPivot = target
    clone.Parent = folder

    local entry = {
        structure = structure,
        door = door,
        doorFrame = door.CFrame,
        model = clone,
        pieces = pieces,
        connections = {},
    }
    local function onDoorChanged()
        -- A streamed/rebuilt/relocated facade must never leave floating
        -- imported artwork; hide immediately, dispose at next LOD tick.
        if not isStillValid(entry, district) then hide(entry) end
    end
    entry.connections[#entry.connections + 1] =
        door:GetPropertyChangedSignal("CFrame"):Connect(onDoorChanged)
    entry.connections[#entry.connections + 1] =
        door.AncestryChanged:Connect(onDoorChanged)
    entry.connections[#entry.connections + 1] =
        structure.AncestryChanged:Connect(onDoorChanged)
    onDoorChanged()
    return entry
end

-- Invoked solely from the existing 0.65/0.90-second scenery LOD owner.
function DistrictGatewayMeshKit.sync(arena, cameraPoint, tier, cameraReady, cameraLook)
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

    local look = typeof(cameraLook) == "Vector3"
        and Vector3.new(cameraLook.X, 0, cameraLook.Z)
        or Vector3.zero
    local facing = look.Magnitude > 0.2
    if facing then look = look.Unit end

    local candidates = {}
    for _, structure in ipairs(district:GetChildren()) do
        local door = permittedStructure(structure, district)
        if door then
            local delta = door.Position - cameraPoint
            local distance = delta.Magnitude
            local resident = mounted[structure] ~= nil
            if distance <= budget.distance + (resident and budget.retention or 0) then
                local score = distance - (resident and budget.retention * 0.65 or 0)
                local horizontal = Vector3.new(delta.X, 0, delta.Z)
                if facing and horizontal.Magnitude > 32
                    and horizontal.Unit:Dot(look) < -0.1 then
                    score += 80
                end
                candidates[#candidates + 1] = {
                    structure = structure,
                    door = door,
                    distance = distance,
                    score = score,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.structure.Name < b.structure.Name
    end)

    local source = template()
    local wanted = {}
    if source then
        for i = 1, math.min(#candidates, budget.count) do
            wanted[candidates[i].structure] = candidates[i].door
        end
    end
    for structure, entry in pairs(mounted) do
        if wanted[structure] ~= entry.door
            or not isStillValid(entry, district) then
            restore(entry)
            mounted[structure] = nil
        end
    end
    for structure, door in pairs(wanted) do
        if not mounted[structure] then
            mounted[structure] = mount(structure, door, district, source)
        end
    end
end

function DistrictGatewayMeshKit.count()
    local total = 0
    for _, entry in pairs(mounted) do
        if entry.model and entry.model.Parent then total += 1 end
    end
    return total
end

return DistrictGatewayMeshKit
