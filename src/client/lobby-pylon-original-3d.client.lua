-- Four genuine creator-approved 3D columns replace the lobby's faceted
-- WedgePart corner pylons. Physical 2.2x10 pylons, player movement and
-- their separately animated PylonGlow/PointLights remain server-owned.
-- No client asset requests, new lights, pathing, or RenderStepped loops.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local SOURCE_ID = 91626128452597 -- older genuine open-detail fallback
local ENCLOSED_ID = 75945454705246 -- Approved source #41825253849

local PYLON_OFFSETS = {
    Vector3.new(-31, 5, -31),
    Vector3.new(31, 5, -31),
    Vector3.new(-31, 5, 31),
    Vector3.new(31, 5, 31),
}

local folder = Instance.new("Folder")
folder.Name = "OriginalLobbyPylons3DLocal"
folder.Parent = workspace

local active = nil
local watched = {}
local listeners = {}
local scheduled = false
local restoringOwn = false
local reconcile

local function budget()
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"),
        UserInputService.TouchEnabled).Name
    local p = tonumber(player:GetAttribute("OptionalVfxPressure"))
    if not p or p ~= p then p = 0 end
    p = math.clamp(math.floor(p), 0, 2)
    if tier == "Low" then return 0 end
    if tier == "Medium" then
        return p == 0 and 4 or (p == 1 and 2 or 0)
    end
    return p < 2 and 4 or 2
end

-- The new original source has a fully CLOSED 2.84 x 10.36 x 2.84
-- chamfered octagonal body, with a .16 bevel. Its smallest inner square
-- still encloses the ENTIRE 2.2x10x2.2 native rectangular collision box.
-- Exact creator-approved Model ID, safe server-sanitized template, bounding
-- and MeshPart checks are all REQUIRED before hiding native collision art.
local function approvedShell()
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedLobbyPylonShellTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild("LobbyPylonShell")
    if not model or not model:IsA("Model") or model.Parent ~= holder
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalLobbyPylonShell3D") ~= true
        or model:GetAttribute("EnclosesCollider") ~= true
        or model:GetAttribute("Original3DAssetId") ~= ENCLOSED_ID then
        return nil
    end
    local count = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = model:GetBoundingBox()
    if size.Y < 10.25 or size.Y > 10.75
        or math.min(size.X, size.Z) < 3.40
        or math.max(size.X, size.Z) > 4.05 then return nil end
    return model, count, size
end

local function approved()
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedLargeStructureTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild("Classic")
    if not model or not model:IsA("Model") or model.Parent ~= holder
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalLargeStructure3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= SOURCE_ID then return nil end
    local count = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = model:GetBoundingBox()
    if size.Y < 13.4 or size.Y > 15.1
        or math.min(size.X, size.Z) < 1.5
        or math.max(size.X, size.Z) > 2.8 then return nil end
    return model, count, size
end

local function validTargets(count)
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local floor = lobby and lobby:FindFirstChild("Floor")
    local decor = lobby and lobby:FindFirstChild("Decor")
    local architecture = decor and decor:FindFirstChild("OriginalLobbyArchitecture")
    if not floor or not floor:IsA("BasePart")
        or not decor or not decor:IsA("Folder")
        or not architecture or not architecture:IsA("Folder")
        or floor.Size.X < 72 or floor.Size.X > 76 then return nil end
    local result = {}
    for i = 1, count do
        local native = decor:FindFirstChild("Pylon" .. tostring(i))
        local legacy = architecture:FindFirstChild(
            "MachinedLobbyPylon" .. tostring(i))
        if not native or not native:IsA("BasePart")
            or native.Parent ~= decor or not native.Anchored
            or not native.CanCollide or native.Size.Y < 9.8
            or native.Size.Y > 10.2 or native.Size.X < 2.1
            or native.Size.X > 2.3 or native.Size.Z < 2.1
            or native.Size.Z > 2.3
            or (native.Position -
                (floor.Position + PYLON_OFFSETS[i])).Magnitude > 0.8
            or not legacy or not legacy:IsA("Model")
            or legacy.Parent ~= architecture then return nil end
        local obsolete = {}
        for _, item in ipairs(legacy:GetDescendants()) do
            if item:IsA("BasePart") then
                if not item.Anchored or item.CanCollide
                    or item.CanTouch or item.CanQuery then return nil end
                obsolete[#obsolete + 1] = item
            elseif item:IsA("LuaSourceContainer") then return nil end
        end
        if #obsolete ~= 4 then return nil end
        result[i] = {native = native, obsolete = obsolete}
    end
    return result
end

local function restore()
    restoringOwn = true
    if active then
        for item, alpha in pairs(active.hidden) do
            if item.Parent then item.LocalTransparencyModifier = alpha end
        end
        active = nil
    end
    folder:ClearAllChildren()
    restoringOwn = false
    if player:GetAttribute("LocalOriginalLobbyPylon3DCount") ~= 0 then
        player:SetAttribute("LocalOriginalLobbyPylon3DCount", 0)
    end
    if player:GetAttribute("LocalOriginalLobbyPylonMeshPartCount") ~= 0 then
        player:SetAttribute("LocalOriginalLobbyPylonMeshPartCount", 0)
    end
    if player:GetAttribute("LocalOriginalLobbyPylonFullShellCount") ~= 0 then
        player:SetAttribute("LocalOriginalLobbyPylonFullShellCount", 0)
    end
end

local function stageColumn(template, sourceSize, partCount,
    target, index, enclosed)
    local clone = template:Clone()
    local frame, bounds
    local stretchX, stretchZ = 1, 1
    local aim = target.native.CFrame
    if enclosed then
        -- Original imported shell already has exact final proportions:
        -- scaling X/Z again would INVALIDATE its guaranteed enclosure.
        frame, bounds = clone:GetBoundingBox()
        if bounds.Y < 10.25 or bounds.Y > 10.75
            or math.min(bounds.X, bounds.Z) < 3.40
            or math.max(bounds.X, bounds.Z) > 4.05 then
            clone:Destroy()
            return nil
        end
        -- Four facade faces look inward toward the central lobby.
        -- Keep the rectangular enclosing core present at EVERY angle.
        local offset = PYLON_OFFSETS[index]
        aim = aim * CFrame.Angles(
            0, math.atan2(offset.X, offset.Z), 0)
    else
        -- Reversible older original column during late moderation/CDN.
        -- It has an open hourglass core; the native obstacle stays visible.
        if not pcall(function()
            clone:ScaleTo(target.native.Size.Y * 1.012 / sourceSize.Y)
        end) then clone:Destroy(); return nil end
        frame, bounds = clone:GetBoundingBox()
        stretchX = math.max(1, (target.native.Size.X + 0.32) / bounds.X)
        stretchZ = math.max(1, (target.native.Size.Z + 0.32) / bounds.Z)
        if stretchX > 2.65 or stretchZ > 2.65
            or bounds.Y < 10 or bounds.Y > 10.5 then
            clone:Destroy()
            return nil
        end
    end
    local pieces = 0
    for _, mesh in ipairs(clone:GetDescendants()) do
        if mesh:IsA("MeshPart") then
            local relative = frame:ToObjectSpace(mesh.CFrame)
            if enclosed then
                mesh.CFrame = aim * relative
            else
                local rot = relative - relative.Position
                mesh.Size = Vector3.new(
                    mesh.Size.X * stretchX, mesh.Size.Y, mesh.Size.Z * stretchZ)
                local pos = relative.Position
                mesh.CFrame = aim
                    * CFrame.new(pos.X * stretchX, pos.Y, pos.Z * stretchZ)
                    * rot
            end
            mesh.Anchored = true
            mesh.Massless = true
            mesh.CanCollide = false
            mesh.CanTouch = false
            mesh.CanQuery = false
            mesh.CastShadow = false
            mesh:SetAttribute("OriginalLobbyPylon3D", true)
            mesh:SetAttribute("Original3DAssetId",
                enclosed and ENCLOSED_ID or SOURCE_ID)
            mesh:SetAttribute("OriginalEnclosingLobbyPylon3D", enclosed)
            pieces += 1
        end
    end
    if pieces ~= partCount then clone:Destroy(); return nil end
    clone.Name = (enclosed and "ApprovedOriginalEnclosedLobbyPylon3D_"
        or "ApprovedOriginalMachinedLobbyColumn_") .. tostring(index)
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("EnclosesCollider", enclosed)
    clone:SetAttribute("Original3DAssetId",
        enclosed and ENCLOSED_ID or SOURCE_ID)
    return clone
end

local function schedule()
    if scheduled then return end
    scheduled = true
    task.defer(function()
        scheduled = false
        reconcile()
    end)
end

local function watch(key, parent, relevant)
    if watched[key] == parent then return end
    for _, connection in ipairs(listeners[key] or {}) do
        connection:Disconnect()
    end
    listeners[key] = {}
    watched[key] = parent
    if not parent then return end
    for _, signal in ipairs({parent.ChildAdded, parent.ChildRemoved}) do
        listeners[key][#listeners[key] + 1] = signal:Connect(function(child)
            if relevant(child.Name) then schedule() end
        end)
    end
end

reconcile = function()
    local generated = workspace:FindFirstChild("GeneratedMap")
    watch("map", generated, function(name) return name == "Lobby" end)
    local lobby = generated and generated:FindFirstChild("Lobby")
    watch("lobby", lobby, function(name)
        return name == "Decor" or name == "Floor"
    end)
    local decor = lobby and lobby:FindFirstChild("Decor")
    watch("decor", decor, function(name)
        return name == "OriginalLobbyArchitecture"
            or name:match("^Pylon%d+$") ~= nil
    end)
    local architecture = decor and decor:FindFirstChild(
        "OriginalLobbyArchitecture")
    watch("architecture", architecture, function(name)
        return name:match("^MachinedLobbyPylon%d+$") ~= nil
    end)
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedLargeStructureTemplates")
    watch("templates", holder, function(name) return name == "Classic" end)
    local shellHolder = ReplicatedStorage:FindFirstChild(
        "ApprovedLobbyPylonShellTemplates")
    watch("shellTemplates", shellHolder, function(name)
        return name == "LobbyPylonShell"
    end)

    local count = budget()
    local template, partCount, sourceSize = approvedShell()
    local enclosed = template ~= nil
    if not template then
        template, partCount, sourceSize = approved()
    end
    local targets = count > 0 and validTargets(count) or nil
    if count == 0 or not template or not targets then
        restore()
        return
    end

    -- No repeated cloning merely because the server sends an unrelated
    -- decor child. A real tier/source/target change does replace the art.
    if active and active.source == template and active.count == count
        and active.enclosed == enclosed then
        local unchanged = true
        for i = 1, count do
            local entry = active.targets[i]
            if not entry or entry.native ~= targets[i].native
                or entry.legacy ~= targets[i].obsolete[1].Parent
                or not active.models[i]
                or active.models[i].Parent ~= folder then
                unchanged = false
                break
            end
            local actualMeshes = 0
            for _, part in ipairs(active.models[i]:GetDescendants()) do
                if part:IsA("MeshPart") then actualMeshes += 1 end
            end
            if actualMeshes ~= partCount then
                unchanged = false
                break
            end
        end
        if unchanged then return end
    end

    restore()
    local staged = {}
    for i = 1, count do
        local model = stageColumn(template, sourceSize, partCount,
            targets[i], i, enclosed)
        if not model then
            for _, other in ipairs(staged) do other:Destroy() end
            return
        end
        staged[#staged + 1] = model
    end

    -- Hide obsolete nonphysical native trims once REAL art is ready.
    -- The approved CLOSED source contains the entire physical obstacle
    -- (including four extreme rectangular corners), so its native core
    -- may finally be fully hidden client-side. Older open-column fallback
    -- keeps the core 50% visible: never create an invisible player blocker.
    local hidden = {}
    for i, model in ipairs(staged) do
        model.Parent = folder
        local target = targets[i]
        for _, item in ipairs(target.obsolete) do
            hidden[item] = item.LocalTransparencyModifier
            item.LocalTransparencyModifier = 1
        end
        hidden[target.native] = target.native.LocalTransparencyModifier
        target.native.LocalTransparencyModifier = enclosed and 1 or 0.50
    end
    local records = {}
    for i, target in ipairs(targets) do
        records[i] = {
            native = target.native,
            legacy = target.obsolete[1].Parent,
        }
    end
    active = {
        source = template, targets = records, models = staged,
        hidden = hidden, count = count, enclosed = enclosed,
    }
    player:SetAttribute("LocalOriginalLobbyPylon3DCount", count)
    player:SetAttribute("LocalOriginalLobbyPylonMeshPartCount",
        count * partCount)
    player:SetAttribute("LocalOriginalLobbyPylonFullShellCount",
        enclosed and count or 0)
end

folder.DescendantRemoving:Connect(function(item)
    if not restoringOwn and item:IsA("MeshPart")
        and item:GetAttribute("OriginalLobbyPylon3D") == true then
        schedule()
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then schedule() end
end)
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then schedule() end
end)
ReplicatedStorage.ChildAdded:Connect(function(child)
    if child.Name == "ApprovedLargeStructureTemplates"
        or child.Name == "ApprovedLobbyPylonShellTemplates" then
        schedule()
    end
end)
ReplicatedStorage.ChildRemoved:Connect(function(child)
    if child.Name == "ApprovedLargeStructureTemplates"
        or child.Name == "ApprovedLobbyPylonShellTemplates" then
        schedule()
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(schedule)
player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(schedule)

reconcile()
