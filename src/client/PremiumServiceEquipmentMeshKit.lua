-- True owner-imported MeshParts for five near-camera service prop families.
-- Native primitive fallbacks remain untouched unless a verified Model
-- is fully mounted. Every MeshPart is a DIRECT ArenaServicePropsLocal child,
-- so both existing scenery LOD and shrink-follow snapshots include them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}

local PROFILES = {
    Classic = {anchor = "ClassicCameraTripod", id = 108954400662606,
        width = 2.5, height = 3.75, depth = 2.7, radius = 5.0},
    Towers = {anchor = "TowerMaintenanceCrate", id = 106083832432833,
        width = 3.6, height = 2.6, depth = 3.0, radius = 5.0},
    Crossroads = {anchor = "CrossroadsBollard", id = 94223777350022,
        width = 1.55, height = 2.7, depth = 1.55, radius = 5.0},
    Orbital = {anchor = "OrbitalServiceCanister", id = 127295681925871,
        width = 2.7, height = 3.45, depth = 2.7, radius = 5.0},
    Harbor = {anchor = "HarborMooringFooting", id = 137255432266916,
        width = 3.6, height = 2.0, depth = 2.9, radius = 5.0},
}
local QUOTA = {Low = 1, Medium = 2, High = 4}

local function trustedTemplate(variant)
    local profile = PROFILES[variant]
    if not profile then return nil end
    local holder = ReplicatedStorage:FindFirstChild("ApprovedServiceEquipmentTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(variant)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalService3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= profile.id then
        return nil
    end
    local pieces = 0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then return nil end
            pieces += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if pieces < 1 or pieces > 12 then return nil end
    local _, bounds = source:GetBoundingBox()
    if math.min(bounds.X, bounds.Y, bounds.Z) < .65
        or math.max(bounds.X, bounds.Y, bounds.Z) > 6 then return nil end
    return source
end

local function nearbyNative(folder, anchor, radius)
    local parts = {}
    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("BasePart") and part.Anchored
            and not part.CanCollide and not part.CanTouch
            and not part.CanQuery
            and (part.Position - anchor.Position).Magnitude <= radius then
            parts[#parts + 1] = part
        end
    end
    return parts
end

local function install(folder, variant, index, anchor, profile, source)
    local group = nearbyNative(folder, anchor, profile.radius)
    if #group < 2 or #group > 18 then return false end

    local copy = source:Clone()
    local _, sourceSize = copy:GetBoundingBox()
    local factor = math.min(1.12, profile.width / sourceSize.X,
        profile.height / sourceSize.Y, profile.depth / sourceSize.Z)
    if factor < .45 then copy:Destroy(); return false end
    if not pcall(function() copy:ScaleTo(factor) end) then
        copy:Destroy()
        return false
    end
    local sourceFrame, bounds = copy:GetBoundingBox()
    if bounds.X > profile.width + .1 or bounds.Y > profile.height + .1
        or bounds.Z > profile.depth + .1 then
        copy:Destroy()
        return false
    end
    local target
    if variant == "Orbital" then
        -- Existing horizontal cylindrical reactor orientation is intentional.
        target = anchor.CFrame
    else
        local bottom = anchor.Position - anchor.CFrame.UpVector
            * (anchor.Size.Y * .5)
        target = CFrame.new(bottom + anchor.CFrame.UpVector * (bounds.Y * .5))
            * anchor.CFrame.Rotation
    end
    local meshes = {}
    for _, part in ipairs(copy:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                copy:Destroy()
                return false
            end
            part.CFrame = target * sourceFrame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("Original3DAssetId", profile.id)
            part:SetAttribute("CosmeticOnly", true)
            part:SetAttribute("OriginalService3D", true)
            meshes[#meshes + 1] = part
        end
    end
    if #meshes < 1 or #meshes > 12 then copy:Destroy(); return false end
    -- No native component is hidden before every MeshPart is prepared.
    -- Transfer into the existing tiered, shrink-aware folder atomically.
    for ordinal, part in ipairs(meshes) do
        part.Name = "ApprovedOriginalService3D_" .. variant
            .. "_" .. tostring(index) .. "_" .. tostring(ordinal)
        part.Parent = folder
    end
    copy:Destroy()
    for _, part in ipairs(group) do
        part.Transparency = 1
        for _, gui in ipairs(part:GetChildren()) do
            if gui:IsA("SurfaceGui") then gui.Enabled = false end
        end
    end
    return true
end

function Kit.replace(folder, variant, tier, cameraPoint)
    local profile = PROFILES[variant]
    local source = trustedTemplate(variant)
    if not folder or not folder:IsA("Folder") or not source or not profile then
        return 0
    end
    local anchors = {}
    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("Part") and part.Name:match(
            "^" .. profile.anchor .. "%d+$") then
            local index = tonumber(part.Name:match("(%d+)$"))
            if index and part.Anchored and not part.CanCollide
                and not part.CanTouch and not part.CanQuery then
                anchors[#anchors + 1] = {index = index, part = part,
                    distance = cameraPoint
                        and (part.Position - cameraPoint).Magnitude or math.huge}
            end
        end
    end
    table.sort(anchors, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.index < b.index
    end)
    local mounted = 0
    for _, item in ipairs(anchors) do
        if mounted >= (QUOTA[tier] or QUOTA.Low) then break end
        if install(folder, variant, item.index, item.part, profile, source) then
            mounted += 1
        end
    end
    return mounted
end

return Kit
