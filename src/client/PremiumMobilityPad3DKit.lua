-- Local sculpture around the real touch sensor. The top face remains
-- unobstructed so the native glow, direction cues and status label stay visible.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LobbyMeshPreload = require(script.Parent.LobbyMeshPreload)

local Kit = {}
local APPROVED = 126298311664881
local SOURCE_FOLDER = "ApprovedTowersSignatureBridgeTemplates"
local SOURCE_MODEL = "ForgedBridge"
local SOURCE_REGION = "SweptCrossbeam"
local MODEL_MARKER = "OriginalTowersSignatureBridge3D"

local holder = Instance.new("Folder")
holder.Name = "OriginalMobilityPadHardwareLocal"
holder:SetAttribute("CosmeticOnly", true)
holder.Parent = workspace

local mounted = {}
local geometryReady

local function sourceNodes()
    local folder = ReplicatedStorage:FindFirstChild(SOURCE_FOLDER)
    local model = folder and folder:FindFirstChild(SOURCE_MODEL)
    return folder, model, model and model:FindFirstChild(SOURCE_REGION)
end

local function genuineSource()
    local folder, model, source = sourceNodes()
    if not folder or not folder:IsA("Folder") or folder:GetAttribute("OwnerVerified") ~= true
        or not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute(MODEL_MARKER) ~= true
        or model:GetAttribute("Original3DAssetId") ~= APPROVED
        or not source or not source:IsA("MeshPart") or not source.Archivable
        or source.MeshId == "" or source.CanCollide or source.CanTouch or source.CanQuery then
        return nil
    end
    local size = source.Size
    if math.abs(math.max(size.X, size.Z) - 40.64) >= 0.30
        or math.abs(math.min(size.X, size.Z) - 5.96) >= 0.20
        or math.abs(size.Y - 3.1108) >= 0.18 then return nil end
    return source
end

local function genuinePad(pad)
    if not pad or not pad:IsA("Part")
        or not pad.Parent or pad.Parent.Name ~= "Mechanics"
        or not pad.Anchored or not pad.CanTouch
        or pad.CanCollide or pad.CanQuery
        or pad:GetAttribute("ArenaMobilityPad") ~= true
        or pad.Size.X < 6.3 or pad.Size.X > 6.7
        or pad.Size.Z < 6.3 or pad.Size.Z > 6.7
    then return false end
    local index = pad:GetAttribute("ArenaMobilityPadIndex")
    if type(index) ~= "number" or index % 1 ~= 0
        or index < 1 or index > 8 then return false end
    local arena = pad.Parent.Parent
    local map = arena and arena.Parent
    return arena and arena.Name == "Arena"
        and map and map.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == map
        and map:FindFirstChild("Arena") == arena
        and arena:GetAttribute("VariantId") ~= nil
end

local function removePad(pad)
    local entry = mounted[pad]
    if not entry then return end
    mounted[pad] = nil
    for _, connection in ipairs(entry.connections) do connection:Disconnect() end
    entry.model:Destroy()
end

local function repaint(pad, entry, color)
    local metal = color:Lerp(Color3.fromRGB(30, 39, 53), 0.65)
    local cap = color:Lerp(Color3.fromRGB(45, 56, 70), 0.46)
    for index, piece in ipairs(entry.pieces) do
        piece.Color = index <= 2 and cap or metal
        piece.Transparency = pad.Transparency
    end
end

local function layout(pad, entry)
    local size = pad.Size
    local frame = pad.CFrame
    local width = 0.38
    local protrusion = 0.07
    -- Leave the complete top face clear even as the sensor moves. End
    -- caps overhang the side rails slightly and hide the corner joints.
    local top = size.Y * 0.5 - 0.02
    local height = 0.24
    local centerY = top - height * 0.5
    local offset = size * 0.5 + Vector3.new(protrusion, 0, protrusion)
    local longAxisX = entry.longAxisX
    for index, piece in ipairs(entry.pieces) do
        local endCap = index <= 2
        local side = index % 2 == 0 and 1 or -1
        local length = endCap and (offset.X * 2 + width) or (offset.Z * 2 - width)
        local pose = frame * CFrame.new(endCap and 0 or side * offset.X,
            centerY, endCap and side * offset.Z or 0)
        local rotate = longAxisX ~= endCap
        piece.CFrame = rotate and pose * CFrame.Angles(0, math.pi * 0.5, 0) or pose
        piece.Size = longAxisX and Vector3.new(length, height, width)
            or Vector3.new(width, height, length)
    end
end

local function mount(pad, source, color)
    local model = Instance.new("Model")
    model.Name = "AuthenticMobilityPad3D_" .. tostring(pad:GetAttribute("ArenaMobilityPadIndex"))
    model:SetAttribute("CosmeticOnly", true)
    local entry = {model = model, source = source, meshId = source.MeshId,
        longAxisX = source.Size.X > source.Size.Z, pieces = {}, connections = {}}
    for index = 1, 4 do
        local piece = source:Clone()
        if not piece then
            model:Destroy()
            return
        end
        piece:ClearAllChildren()
        piece.Name = (index <= 2 and "ForgedEndCap" or "ForgedSideRail") .. index
        piece.TextureID = ""
        piece.MaterialVariant = ""
        piece.Material = Enum.Material.Metal
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece.LocalTransparencyModifier = 0
        piece:SetAttribute("CosmeticOnly", true)
        piece:SetAttribute("Original3DAssetId", APPROVED)
        piece:SetAttribute("OriginalMobilityPadHousing3D", true)
        piece.Parent = model
        entry.pieces[index] = piece
    end
    layout(pad, entry)
    repaint(pad, entry, color)
    local function follow()
        if genuinePad(pad) then layout(pad, entry) else removePad(pad) end
    end
    entry.connections = {
        pad:GetPropertyChangedSignal("CFrame"):Connect(follow),
        pad:GetPropertyChangedSignal("Size"):Connect(follow),
        pad:GetPropertyChangedSignal("Transparency"):Connect(function()
            for _, piece in ipairs(entry.pieces) do piece.Transparency = pad.Transparency end
        end),
        pad.AncestryChanged:Connect(function()
            if not genuinePad(pad) then removePad(pad) end
        end),
        model.DescendantRemoving:Connect(function(piece)
            if piece:IsA("MeshPart") then removePad(pad) end
        end),
    }
    mounted[pad] = entry
    model.Parent = holder
end

function Kit.watchSource(onChanged)
    geometryReady = LobbyMeshPreload.new(onChanged)
    local connections = {}
    local pending = false
    local function bind()
        for _, connection in ipairs(connections) do connection:Disconnect() end
        table.clear(connections)
        local folder, model, source = sourceNodes()
        if folder then
            connections[#connections + 1] = folder:GetAttributeChangedSignal("OwnerVerified"):Connect(onChanged)
        end
        if model then
            for _, attr in ipairs({"OwnerVerified", "CosmeticOnly", MODEL_MARKER, "Original3DAssetId"}) do
                connections[#connections + 1] = model:GetAttributeChangedSignal(attr):Connect(onChanged)
            end
        end
        if source and source:IsA("MeshPart") then
            for _, property in ipairs({"MeshId", "Size", "Archivable", "CanCollide", "CanTouch", "CanQuery"}) do
                connections[#connections + 1] = source:GetPropertyChangedSignal(property):Connect(onChanged)
            end
        end
        onChanged()
    end
    local function onSourceTreeChanged(item)
        local folder, model = sourceNodes()
        local relevant = (item.Name == SOURCE_FOLDER and item.Parent == ReplicatedStorage)
            or (folder and item.Name == SOURCE_MODEL and item.Parent == folder)
            or (model and item.Name == SOURCE_REGION and item.Parent == model)
        if not relevant or pending then return end
        pending = true
        task.defer(function()
            pending = false
            bind()
        end)
    end
    ReplicatedStorage.DescendantAdded:Connect(onSourceTreeChanged)
    ReplicatedStorage.DescendantRemoving:Connect(onSourceTreeChanged)
    bind()
end

function Kit.sync(pads, tier, rawPressure, touch)
    local source = genuineSource()
    local pressure = math.clamp(
        math.floor(tonumber(rawPressure) or 0), 0, 2)
    local quota = tier == "High" and (touch and 3 or 4)
        or (tier == "Medium" and 2 or 0)
    if pressure == 1 then
        quota = math.floor(quota * 0.5)
    elseif pressure == 2 then
        quota = 0
    end
    if quota > 0 and (not source or not geometryReady or not geometryReady(source)) then
        quota = 0
    end

    local camera = workspace.CurrentCamera
    local origin = camera and camera.CFrame.Position
        or Vector3.zero
    local candidates = {}
    for pad in pairs(pads) do
        if genuinePad(pad) then
            candidates[#candidates+1] = {
                pad = pad, distance = (pad.Position - origin).Magnitude,
                index = pad:GetAttribute("ArenaMobilityPadIndex"),
            }
        end
    end
    table.sort(candidates, function(a, b)
        if a.distance == b.distance then return a.index < b.index end
        return a.distance < b.distance
    end)

    -- Evict stale map rigs, withdrawn approvals and pressure excesses
    -- BEFORE mounting more. An approved source replaced under the same
    -- name is not the same source identity.
    local desired = {}
    for i = 1, math.min(quota, #candidates) do
        desired[candidates[i].pad] = true
    end
    local sourceAlongX = source and source.Size.X > source.Size.Z
    local obsolete = {}
    for pad, entry in pairs(mounted) do
        if not desired[pad] or entry.source ~= source
            or entry.model.Parent ~= holder
            or entry.meshId ~= source.MeshId
            or entry.longAxisX ~= sourceAlongX
            or not genuinePad(pad) then
            obsolete[#obsolete+1] = pad
        end
    end
    for _, pad in ipairs(obsolete) do removePad(pad) end

    for i = 1, math.min(quota, #candidates) do
        local pad = candidates[i].pad
        local color = pads[pad].hardwareColor or pad.Color
        local entry = mounted[pad]
        if entry then repaint(pad, entry, color) else mount(pad, source, color) end
    end
    local count = 0
    for _ in pairs(mounted) do count += 1 end
    return count
end

function Kit.clear()
    for pad in pairs(mounted) do removePad(pad) end
end

return Kit
