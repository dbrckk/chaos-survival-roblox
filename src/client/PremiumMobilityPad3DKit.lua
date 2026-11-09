-- P4: CREATOR-APPROVED 3D MOBILE MOBILITY PAD HOUSINGS.
-- Real BasePart pads remain SERVER-owned and touchable. Only use the
-- already imported / authenticated original CornerGuard sculpture:
-- AssetService-approved original 102215174919938. Never create MeshIds.
-- Model stays a cosmetic clone with no collision, queries or scripting.
-- Tier/pressure lifecycle is driven by arena-pad-ambient's existing
-- event watchers; there is NO new render loop or workspace scanner.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local APPROVED = 102215174919938
local holder = Instance.new("Folder")
holder.Name = "OriginalMobilityPadHardwareLocal"
holder:SetAttribute("CosmeticOnly", true)
holder.Parent = workspace

local mounted = {}

local function genuineSource()
    local parent = ReplicatedStorage:FindFirstChild(
        "ApprovedFloorReliefTemplates")
    if not parent or not parent:IsA("Folder")
        or parent.Parent ~= ReplicatedStorage
        or parent:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = parent:FindFirstChild("CornerGuard")
    if not source or source.Parent ~= parent or not source:IsA("Model")
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalFloorRelief3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= APPROVED
    then return nil end

    local count = 0
    for _, object in ipairs(source:GetDescendants()) do
        if object:IsA("BasePart") then
            if not object:IsA("MeshPart") or object.CanCollide
                or object.CanTouch or object.CanQuery then
                return nil
            end
            count += 1
        elseif object:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = source:GetBoundingBox()
    if size.X < 4.7 or size.X > 5.6
        or size.Z < 4.7 or size.Z > 5.6
        or size.Y < 0.24 or size.Y > 0.56 then
        return nil
    end
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
        and map.Parent == workspace
        and arena:GetAttribute("VariantId") ~= nil
end

local function removePad(pad)
    local entry = mounted[pad]
    if not entry then return end
    mounted[pad] = nil
    if entry.connection then entry.connection:Disconnect() end
    if entry.meshConnection then entry.meshConnection:Disconnect() end
    if entry.model.Parent then entry.model:Destroy() end
end

local function removeAll()
    local keys = {}
    for pad in pairs(mounted) do keys[#keys+1] = pad end
    for _, pad in ipairs(keys) do removePad(pad) end
end

local function mount(pad, source)
    if not genuinePad(pad) or not source or mounted[pad] then return false end
    local copy = source:Clone()
    local frame, bounds = copy:GetBoundingBox()
    -- Floor sculpture is 5.2×5.2 studs: keep it inside the actual
    -- 6.5-stud physical square. Don't extend above .44 studs, where it
    -- would visually suggest a jump obstacle where none exists.
    local scale = math.min(1.08,
        pad.Size.X * 0.88 / math.max(bounds.X, 0.01),
        pad.Size.Z * 0.88 / math.max(bounds.Z, 0.01),
        0.44 / math.max(bounds.Y, 0.01))
    if scale < 0.68 or not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return false
    end
    frame, bounds = copy:GetBoundingBox()
    if bounds.X > pad.Size.X * 0.89
        or bounds.Z > pad.Size.Z * 0.89
        or bounds.Y > 0.45 then
        copy:Destroy()
        return false
    end

    -- Genuine 3D sits flush on the pad surface, which still supplies its
    -- authentic arena color, glow and physical touch. Keep all original
    -- materials and mesh silhouettes; never stretch/rebuild vertices.
    local target = pad.CFrame * CFrame.new(
        0, pad.Size.Y * 0.5 + bounds.Y * 0.5 - 0.055, 0)
    local pieces = 0
    for _, part in ipairs(copy:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                copy:Destroy()
                return false
            end
            part.CFrame = target * frame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("CosmeticOnly", true)
            part:SetAttribute("Original3DAssetId", APPROVED)
            part:SetAttribute("OriginalMobilityPadHousing3D", true)
            pieces += 1
        end
    end
    if pieces < 1 or pieces > 12
        or not genuinePad(pad) or not source.Parent then
        copy:Destroy()
        return false
    end
    copy.Name = "AuthenticMobilityPad3D_"
        .. tostring(pad:GetAttribute("ArenaMobilityPadIndex"))
    copy:SetAttribute("CosmeticOnly", true)
    copy.Parent = holder
    local entry = {model = copy, source = source, connection = nil}
    mounted[pad] = entry
    entry.connection = pad.AncestryChanged:Connect(function()
        if not genuinePad(pad) then removePad(pad) end
    end)
    -- A streamed/externally removed piece cannot leave a half-finished
    -- metal shell hiding the gameplay marker; discard the broken clone.
    entry.meshConnection = copy.DescendantRemoving:Connect(function(part)
        if part:IsA("MeshPart") then removePad(pad) end
    end)
    return true
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
    if not source then quota = 0 end

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
    local obsolete = {}
    for pad, entry in pairs(mounted) do
        if not desired[pad] or entry.source ~= source
            or entry.model.Parent ~= holder
            or not genuinePad(pad) then
            obsolete[#obsolete+1] = pad
        end
    end
    for _, pad in ipairs(obsolete) do removePad(pad) end

    if source then
        for i = 1, math.min(quota, #candidates) do
            mount(candidates[i].pad, source)
        end
    end
    local count = 0
    for _ in pairs(mounted) do count += 1 end
    return count
end

function Kit.clear()
    removeAll()
end

return Kit
