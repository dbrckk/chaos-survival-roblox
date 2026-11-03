--!strict
-- Exactly one original creator-approved 3D portal outside the real lobby
-- arena gate. Native GateLeft/Right/Top and its animated SurfaceGui stay
-- authoritative and unobscured. Entirely event-driven: zero frame loops.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ASSET_ID = 136009650118642
local folder = Instance.new("Folder")
folder.Name = "OriginalLobbyGate3DLocal"
folder.Parent = workspace

local mounted = nil
local watched = {}
local listeners = {}
local reconcile

local function clear()
    if mounted then
        mounted.model:Destroy()
        mounted = nil
    end
    folder:ClearAllChildren()
    if player:GetAttribute("LocalOriginalLobbyGateMeshCount") ~= 0 then
        player:SetAttribute("LocalOriginalLobbyGateMeshCount", 0)
    end
end

local function watch(key, instance, filter)
    if watched[key] == instance then return end
    if listeners[key] then
        for _, connection in ipairs(listeners[key]) do
            connection:Disconnect()
        end
    end
    watched[key] = instance
    listeners[key] = {}
    if not instance then return end
    for _, event in ipairs({instance.ChildAdded, instance.ChildRemoved}) do
        local connection = event:Connect(function(child)
            if filter(child) then task.defer(reconcile) end
        end)
        listeners[key][#listeners[key] + 1] = connection
    end
end

local function authoritativeTop(decor)
    if not decor or not decor:IsA("Folder") then return nil end
    local top = decor:FindFirstChild("ArenaGateTop")
    local left = decor:FindFirstChild("ArenaGateLeft")
    local right = decor:FindFirstChild("ArenaGateRight")
    if not top or not top:IsA("BasePart")
        or top.Parent ~= decor or not left or not right
        or not left:IsA("BasePart") or not right:IsA("BasePart")
        or left.Parent ~= decor or right.Parent ~= decor
        or math.abs(top.Size.X - 23) > 0.1
        or math.abs(top.Size.Y - 3) > 0.1
        or math.abs(left.Position.X - right.Position.X) < 18
        or (top.Position - (left.Position + right.Position) * 0.5).Y < 5 then
        return nil
    end
    return top
end

local function approvedTemplate(templates)
    if not templates or not templates:IsA("Folder")
        or templates:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = templates:FindFirstChild("OriginalLobbyGate")
    if not source or not source:IsA("Model")
        or source.Parent ~= templates
        or source:GetAttribute("Original3DAssetId") ~= ASSET_ID
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("GenuineLobbyGate3D") ~= true then
        return nil
    end
    local count = 0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = source:GetBoundingBox()
    if math.max(size.X, size.Z) < 24
        or math.max(size.X, size.Z) > 28
        or math.min(size.X, size.Z) < 4
        or math.min(size.X, size.Z) > 8
        or size.Y < 18 or size.Y > 22 then
        return nil
    end
    return source
end

local function mount(source, top)
    local clone = source:Clone()
    local sourceFrame, bounds = clone:GetBoundingBox()
    -- Real native top: Center=(LobbyCenter + (0,13,+27)).
    -- Source OBJ: floor at Y=0, apex at Y~20, X-width ~26.
    local groundFrame = top.CFrame * CFrame.new(0, -13, 0)
    local upright = bounds.X < bounds.Z
        and CFrame.Angles(0, math.pi * 0.5, 0)
        or CFrame.new()
    local target = groundFrame * upright * CFrame.new(0, bounds.Y * 0.5, 0)
    local pieces = 0
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
            pieces += 1
        end
    end
    if pieces < 1 or pieces > 12 then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedOriginalSculptedLobbyPortal3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("Original3DAssetId", ASSET_ID)
    clone.WorldPivot = target
    clone.Parent = folder
    return {
        model = clone,
        source = source,
        top = top,
        topFrame = top.CFrame,
        pieces = pieces,
    }
end

reconcile = function()
    local generated = workspace:FindFirstChild("GeneratedMap")
    watch("map", generated, function(child)
        return child.Name == "Lobby"
    end)
    local lobby = generated and generated:FindFirstChild("Lobby")
    watch("lobby", lobby, function(child)
        return child.Name == "Decor"
    end)
    local decor = lobby and lobby:FindFirstChild("Decor")
    watch("decor", decor, function(child)
        return child.Name == "ArenaGateTop"
            or child.Name == "ArenaGateLeft"
            or child.Name == "ArenaGateRight"
    end)
    local templates = ReplicatedStorage:FindFirstChild("PremiumLobbyGateMeshTemplates")
    watch("templates", templates, function(child)
        return child.Name == "OriginalLobbyGate"
    end)

    local source = approvedTemplate(templates)
    local top = authoritativeTop(decor)
    if not source or not top then
        clear()
        return
    end
    if mounted and mounted.model.Parent == folder
        and mounted.source == source and mounted.top == top
        and top.CFrame == mounted.topFrame then
        return
    end
    clear()
    mounted = mount(source, top)
    if mounted and player:GetAttribute("LocalOriginalLobbyGateMeshCount")
        ~= mounted.pieces then
        player:SetAttribute("LocalOriginalLobbyGateMeshCount", mounted.pieces)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then task.defer(reconcile) end
end)
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then task.defer(reconcile) end
end)
ReplicatedStorage.ChildAdded:Connect(function(child)
    if child.Name == "PremiumLobbyGateMeshTemplates" then
        task.defer(reconcile)
    end
end)
ReplicatedStorage.ChildRemoved:Connect(function(child)
    if child.Name == "PremiumLobbyGateMeshTemplates" then
        task.defer(reconcile)
    end
end)

reconcile()
