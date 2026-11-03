-- Actual creator-owned 3D low-profile service/arena floor sculptures.
-- Existing server Base, platform colliders, hazard paint, warnings and
-- shrinking rules are untouched. Source receipts: #41736767816.
-- Every imported MeshPart becomes a DIRECT child of the existing
-- ArenaSurfaceReliefLocal owner for the current shrink-follow snapshot.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}

local PROFILES = {
    Essential = {
        id = 71267601603297,
        prefix = "EssentialDeckPlate",
        suffix = "^(%d+)$",
        overlay = "EssentialDeckInset",
    },
    Classic = {
        id = 102746904688141,
        prefix = "ClassicReliefHatch",
        suffix = "^(%d+)$",
        overlay = "ClassicReliefHatchInset",
    },
    Towers = {
        id = 74708751016233,
        prefix = "TowerReliefRib",
        suffix = "^(%d+)$",
        overlay = "TowerReliefRibLens",
    },
    Crossroads = {
        id = 84038993323581,
        prefix = "CrossroadsRumble",
        suffix = "^(%d+_%d+)$",
    },
    Orbital = {
        id = 123089585720736,
        prefix = "OrbitalReliefSegment",
        suffix = "^(%d+)$",
        overlay = "OrbitalReliefGlow",
    },
    Harbor = {
        id = 94830155055482,
        prefix = "HarborDeckCargoCleat",
        suffix = "^(%d+)$",
        overlay = "HarborDeckLoadLine",
    },
}
-- Low six real plate Models; Medium covers all sixteen Crossroads strips;
-- High can cover all twenty-eight original Crossroads rumble-strip modules.
-- Each imported Model contains exactly seven real material MeshParts.
local RESIDENCY = {Low = 6, Medium = 16, High = 28}

local function genuineSource(name)
    local spec = PROFILES[name]
    if not spec then return nil end
    local holder = ReplicatedStorage:FindFirstChild("ApprovedFloorReliefTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(name)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OriginalFloorRelief3D") ~= true
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("Original3DAssetId") ~= spec.id then return nil end
    local count = 0
    for _, obj in ipairs(source:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not obj:IsA("MeshPart") then return nil end
            count += 1
        elseif obj:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, bounds = source:GetBoundingBox()
    if bounds.X < 2.7 or bounds.X > 12
        or bounds.Z < .45 or bounds.Z > 5.5
        or bounds.Y < .06 or bounds.Y > .75 then return nil end
    return source, spec
end

local function nearbyFallback(folder, anchor, spec, suffix)
    local native = {anchor}
    if spec.overlay then
        local aux = folder:FindFirstChild(spec.overlay .. suffix)
        if aux and aux:IsA("BasePart")
            and aux.Parent == folder and aux.Anchored
            and not aux.CanCollide and not aux.CanTouch
            and not aux.CanQuery then
            native[#native + 1] = aux
        end
    end
    return native
end

local function installOne(folder, anchor, suffix, source, spec)
    if not anchor or anchor.Parent ~= folder
        or not anchor:IsA("Part") or not anchor.Anchored
        or anchor.CanCollide or anchor.CanTouch or anchor.CanQuery
        or anchor.Transparency >= .75 then return false end

    local native = nearbyFallback(folder, anchor, spec, suffix)
    local clone = source:Clone()
    local _, rawBounds = clone:GetBoundingBox()
    local long = math.max(anchor.Size.X, anchor.Size.Z)
    local short = math.min(anchor.Size.X, anchor.Size.Z)
    local sourceLong = math.max(rawBounds.X, rawBounds.Z)
    local sourceShort = math.min(rawBounds.X, rawBounds.Z)
    if sourceShort < .4 or sourceLong < 2.5 then
        clone:Destroy()
        return false
    end
    local scale = math.min(1.12,
        long * .97 / sourceLong,
        short * .94 / sourceShort)
    if scale < .62 then clone:Destroy(); return false end
    if not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return false
    end
    local sourceFrame, bounds = clone:GetBoundingBox()
    if bounds.Y > .55 or bounds.X > long * 1.03
        or bounds.Z > long * 1.03 then
        clone:Destroy()
        return false
    end

    local yaw = anchor.Size.X < anchor.Size.Z and math.pi * .5 or 0
    -- The highest sculpted point remains essentially flush with the
    -- *existing* native plate's top: never cover a danger warning/cue.
    local frame = anchor.CFrame
        * CFrame.new(0, anchor.Size.Y * .5 - bounds.Y * .5 + .006, 0)
        * CFrame.Angles(0, yaw, 0)

    local pieces = {}
    for _, obj in ipairs(clone:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not obj:IsA("MeshPart") then
                clone:Destroy()
                return false
            end
            obj.CFrame = frame * sourceFrame:ToObjectSpace(obj.CFrame)
            obj.Anchored = true
            obj.Massless = true
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
            obj.CastShadow = false
            obj:SetAttribute("Original3DAssetId", spec.id)
            obj:SetAttribute("OriginalFloorRelief3D", true)
            obj:SetAttribute("CosmeticOnly", true)
            pieces[#pieces + 1] = obj
        end
    end
    if #pieces < 1 or #pieces > 12 then clone:Destroy(); return false end

    -- Source is completely validated before changing native visibility.
    -- Direct folder children are crucial: ArenaFloorFollowerKit captures
    -- only direct BaseParts, and must shrink these meshes with the Base.
    for ordinal, obj in ipairs(pieces) do
        obj.Name = "ApprovedOriginalFloor3D_" .. anchor.Name
            .. "_" .. tostring(ordinal)
        obj.Parent = folder
    end
    clone:Destroy()

    for _, obj in ipairs(native) do
        obj.Transparency = 1
    end
    return true
end

function Kit.install(folder, variant, tier, cameraPoint)
    local name = tier == "Low" and "Essential" or variant
    local source, spec = genuineSource(name)
    if not folder or not folder:IsA("Folder") or not source then return 0 end
    local candidates = {}
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Part")
            and obj.Name:sub(1, #spec.prefix) == spec.prefix then
            local suffix = obj.Name:sub(#spec.prefix + 1)
            if suffix:match(spec.suffix) then
                candidates[#candidates + 1] = {
                    anchor = obj,
                    suffix = suffix,
                    distance = typeof(cameraPoint) == "Vector3"
                        and (cameraPoint - obj.Position).Magnitude or math.huge,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.distance == b.distance then
            return a.anchor.Name < b.anchor.Name
        end
        return a.distance < b.distance
    end)
    local count = 0
    for _, item in ipairs(candidates) do
        if count >= (RESIDENCY[tier] or RESIDENCY.Low) then break end
        if installOne(folder, item.anchor, item.suffix, source, spec) then
            count += 1
        end
    end
    return count
end

return Kit
