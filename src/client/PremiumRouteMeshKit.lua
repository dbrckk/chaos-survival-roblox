-- True creator-owned imported 3D MeshPart route art. Not Roblox Parts.
-- Authoritative collision, movement, danger notices and game mechanics remain
-- the original server platforms. This module owns ONLY local cosmetic clones.
-- Reuse scenery-lod.client.lua's existing 0.65/0.90s camera/quality sampler;
-- no additional render loop, remote, client asset fetch or studio dependency.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PremiumRouteMeshKit = {}

local ASSETS = {
    PremiumJumpDeck = 98478693994864,
    PremiumSkybridgeModule = 94023662427980,
}
local BUDGET = {
    Low = {decks = 2, bridges = 1, segments = 1, distance = 100},
    Medium = {decks = 5, bridges = 1, segments = 3, distance = 170},
    High = {decks = 9, bridges = 2, segments = 5, distance = 245},
}

local folder = Instance.new("Folder")
folder.Name = "PremiumRouteMeshLocal"
folder.Parent = workspace

local mounted = {}
local activeArena = nil
local watchedBase = nil
local baseChanged = nil

local function restore(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for _, model in ipairs(entry.models) do
        model:Destroy()
    end
    local panel = entry.panel
    if panel and panel.Parent then
        panel.LocalTransparencyModifier = entry.originalPanelAlpha
    end
end

local function clearMounted()
    for platform, entry in pairs(mounted) do
        restore(entry)
        mounted[platform] = nil
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

local function safePlatform(platform, initialSize)
    if not platform or not platform.Parent or not platform:IsA("BasePart")
        or not platform.CanCollide or platform.Transparency >= 0.75 then
        return false
    end
    local phase = platform:GetAttribute("CollapsePhase")
    if phase ~= nil and phase ~= "Normal" and phase ~= "Safe" then
        -- Warning and Gone must reveal the ORIGINAL gameplay hazard paint.
        return false
    end
    if initialSize and (math.abs(platform.Size.X - initialSize.X) >= 0.09
        or math.abs(platform.Size.Z - initialSize.Z) >= 0.09) then
        -- No false safe 3D bridge/deck during independent shrinking routes.
        return false
    end
    return true
end

local function getTemplate(name)
    local templates = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not templates or templates:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local model = templates:FindFirstChild(name)
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("Original3DAssetId") ~= ASSETS[name] then
        return nil
    end
    return model
end

local function addModel(entry, platform, template, offset, scale, yaw)
    if not template or scale <= 0 then return false end
    local clone = template:Clone()
    local ok = pcall(function() clone:ScaleTo(scale) end)
    if not ok then clone:Destroy(); return false end
    local initialFrame, dimensions = clone:GetBoundingBox()
    if dimensions.X <= 0 or dimensions.Y <= 0 or dimensions.Z <= 0
        or dimensions.X > 30 or dimensions.Z > 30 then
        clone:Destroy()
        return false
    end
    -- The top of the original mesh sits 0.11 studs above the physical top,
    -- matching the existing non-colliding 0.10-stud native panel paint.
    -- This is NOT a substitute for any authoritative walkable surface.
    local localOffset = typeof(offset) == "Vector3"
        and offset or Vector3.new(offset, 0, 0)
    local target = platform.CFrame
        * CFrame.new(localOffset.X,
            platform.Size.Y * 0.5 + 0.11 - dimensions.Y * 0.5,
            localOffset.Z)
        * CFrame.Angles(0, yaw, 0)

    local parts = {}
    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CFrame = target * initialFrame:ToObjectSpace(descendant.CFrame)
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.CastShadow = false
            descendant.Massless = true
            parts[#parts + 1] = descendant
        end
    end
    if #parts == 0 or #parts > 24 then
        clone:Destroy()
        return false
    end
    clone.Name = "OriginalPremiumRouteMesh"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OriginalPremiumRouteAssetId",
        template:GetAttribute("Original3DAssetId"))
    clone.Parent = folder
    for _, piece in ipairs(parts) do
        local weld = Instance.new("WeldConstraint")
        weld.Name = "OriginalRouteMeshCosmeticWeld"
        weld.Part0 = platform
        weld.Part1 = piece
        weld.Parent = piece
    end
    entry.models[#entry.models + 1] = clone
    return true
end

local function syncVisibility(entry, platform)
    local safe = safePlatform(platform, entry.initialSize)
    -- Never hide the live platform itself or move the gameplay part.
    -- A warning immediately reveals the server-owned native surface.
    for _, model in ipairs(entry.models) do
        for _, piece in ipairs(model:GetDescendants()) do
            if piece:IsA("BasePart") then
                local wanted = safe and 0 or 1
                if piece.LocalTransparencyModifier ~= wanted then
                    piece.LocalTransparencyModifier = wanted
                end
            end
        end
    end
    if entry.panel and entry.panel.Parent then
        local desired = safe and 1 or entry.originalPanelAlpha
        if entry.panel.LocalTransparencyModifier ~= desired then
            entry.panel.LocalTransparencyModifier = desired
        end
    end
end

local function mount(platform, template, count)
    local _, bounds = template:GetBoundingBox()
    if bounds.X < 3 or bounds.Y < 0.1 or bounds.Z < 3 then
        return nil
    end
    local isBridge = platform:GetAttribute("ChaosSkybridge") == true
    local width = math.min(platform.Size.X, platform.Size.Z)
    local length = math.max(platform.Size.X, platform.Size.Z)
    local countToMount = isBridge and count or 1
    local segment = length / countToMount
    local scale = if isBridge then math.min(
        width * 0.91 / bounds.Z, segment * 0.88 / bounds.X, 1.10)
        else math.min(
            platform.Size.X * 0.93 / bounds.X,
            platform.Size.Z * 0.93 / bounds.Z, 1.28)
    if scale < 0.46 then return nil end
    local entry = {
        models = {},
        connections = {},
        initialSize = platform.Size,
        count = countToMount,
        panel = nil,
        originalPanelAlpha = 0,
    }
    local yaw = isBridge and (platform.Size.Z > platform.Size.X
        and math.pi * 0.5 or 0) or 0

    for i = 1, countToMount do
        local offset = isBridge
            and ((i - 0.5) * segment - length * 0.5)
            or 0
        -- The imported module's X axis is rotated into the actual long
        -- bridge axis; the tile translation follows that SAME axis.
        -- No fake physical Part is introduced for the orientation change.
        local modelOffset = isBridge and platform.Size.Z > platform.Size.X
            and Vector3.new(0, 0, offset) or offset
        local before = #entry.models
        if not addModel(entry, platform, template, modelOffset, scale, yaw)
            or #entry.models == before then
            for _, model in ipairs(entry.models) do model:Destroy() end
            return nil
        end
    end

    local index = tonumber(platform.Name:match("^Platform(%d+)$")
        or platform.Name:match("^Skybridge(%d+)$"))
    local arena = platform.Parent and platform.Parent.Parent
    local decor = arena and arena:FindFirstChild("Decor")
    local panel = decor and index and decor:FindFirstChild("PlatformPanel" .. index)
    if panel and panel:IsA("BasePart") then
        entry.panel = panel
        entry.originalPanelAlpha = panel.LocalTransparencyModifier
    end
    local function refresh()
        if platform.Parent then
            syncVisibility(entry, platform)
        end
    end
    for _, prop in ipairs({"CanCollide", "Transparency", "Size"}) do
        entry.connections[#entry.connections + 1] =
            platform:GetPropertyChangedSignal(prop):Connect(refresh)
    end
    entry.connections[#entry.connections + 1] =
        platform:GetAttributeChangedSignal("CollapsePhase"):Connect(refresh)
    refresh()
    return entry
end

local function eligible(platform, cameraPoint, maxDistance)
    if not safePlatform(platform) then return nil end
    local isBridge = platform:GetAttribute("ChaosSkybridge") == true
        and platform.Name:match("^Skybridge%d+$") ~= nil
    local isDeck = platform.Name:match("^Platform%d+$") ~= nil
    if not isBridge and not isDeck then return nil end
    local width, length = math.min(platform.Size.X, platform.Size.Z),
        math.max(platform.Size.X, platform.Size.Z)
    if width < (isBridge and 3.8 or 8) or width > 26 then return nil end
    if not isBridge and length / width > 1.85 then return nil end
    local dist = (cameraPoint - platform.Position).Magnitude
    if dist > maxDistance then return nil end
    return {platform = platform, bridge = isBridge, distance = dist}
end

-- Called BY the existing LOD scheduler, not a new time-based loop.
function PremiumRouteMeshKit.sync(arena, cameraPoint, quality, cameraReady)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[quality] or BUDGET.Low
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        clearMounted()
        return
    end
    local base = arena:FindFirstChild("Base")
    local platforms = arena:FindFirstChild("Platforms")
    if not base or not base:IsA("BasePart") or not platforms
        or not platforms:IsA("Folder") then
        clearMounted()
        return
    end
    if base ~= watchedBase then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase = base
        -- Resize is an immediate hazard; don't wait for the next 0.65s LOD
        -- cycle to hide cosmetic meshes from nonexistent jumpable ground.
        baseChanged = base:GetPropertyChangedSignal("Size"):Connect(function()
            if base.Size.X < 318 or base.Size.Z < 318 then
                clearMounted()
            end
        end)
    end
    if base.Size.X < 318 or base.Size.Z < 318 then
        clearMounted()
        return
    end

    local decks, bridges = {}, {}
    for _, platform in ipairs(platforms:GetChildren()) do
        if platform:IsA("BasePart") then
            local item = eligible(platform, cameraPoint, budget.distance)
            if item then
                local bucket = item.bridge and bridges or decks
                bucket[#bucket + 1] = item
            end
        end
    end
    local function byDistance(a, b)
        if a.distance == b.distance then
            return a.platform.Name < b.platform.Name
        end
        return a.distance < b.distance
    end
    table.sort(decks, byDistance)
    table.sort(bridges, byDistance)

    local wanted = {}
    local deckTemplate = getTemplate("PremiumJumpDeck")
    local bridgeTemplate = getTemplate("PremiumSkybridgeModule")
    if deckTemplate then
        for i = 1, math.min(#decks, budget.decks) do
            wanted[decks[i].platform] = {template = deckTemplate, count = 1}
        end
    end
    if bridgeTemplate then
        for i = 1, math.min(#bridges, budget.bridges) do
            local span = math.max(bridges[i].platform.Size.X,
                bridges[i].platform.Size.Z)
            local count = math.min(budget.segments,
                math.max(1, math.floor(span / 9.5)))
            wanted[bridges[i].platform] = {
                template = bridgeTemplate, count = count,
            }
        end
    end

    for platform, entry in pairs(mounted) do
        local desired = wanted[platform]
        if not desired or desired.count ~= entry.count then
            restore(entry)
            mounted[platform] = nil
        end
    end
    for platform, desired in pairs(wanted) do
        if not mounted[platform] then
            mounted[platform] = mount(platform, desired.template, desired.count)
        end
    end
end

function PremiumRouteMeshKit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        n += #entry.models
    end
    return n
end

return PremiumRouteMeshKit
