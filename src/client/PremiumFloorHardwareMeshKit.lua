-- Original Roblox creator-owned sculpted 3D micro-machinery for the
-- LAST THREE primitive floor-detail families (corner wedges, circular
-- fasteners, Harbor tie-downs), without changing any server collider.
-- Owner-created/import receipts: 41740585965 and 41740889677.
-- Follows the single ArenaFloorFollowerKit Base.Size snapshot, no loops.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}

local PROFILES = {
    CornerGuard = {
        id = 102215174919938,
        pattern = "^ReliefCornerBevel(%d+)$",
        overlay = "ReliefCornerLens",
        width = 5.2,
        height = .43,
        minSize = Vector3.new(4.7, .24, 4.7),
        maxSize = Vector3.new(5.6, .56, 5.6),
        quality = "High",
        max = 4,
    },
    AnchorBolt = {
        -- Actual owner-created Model is 10× authoring scale. The .4-stud
        -- version's unknown HTTP 500 result is NEVER claimed as approved.
        id = 92226531849432,
        pattern = "^ReliefFastener(%d+)$",
        width = .44,
        height = .22,
        minSize = Vector3.new(3.1, 1.5, 3.1),
        maxSize = Vector3.new(6.1, 3.0, 6.1),
        quality = "Medium",
        max = 12,
        worldUp = true,
    },
    HarborTie = {
        id = 135412901717584,
        pattern = "^HarborQuayTieDown(%d+)$",
        width = 1.1,
        height = .35,
        minSize = Vector3.new(.90, .21, .90),
        maxSize = Vector3.new(1.25, .52, 1.25),
        quality = "High",
        max = 4,
    },
}
local ORDER = {"CornerGuard", "AnchorBolt", "HarborTie"}

local function genuineTemplate(kind)
    local spec = PROFILES[kind]
    local holder = ReplicatedStorage:FindFirstChild("ApprovedFloorReliefTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(kind)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("Original3DAssetId") ~= spec.id
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalFloorRelief3D") ~= true then
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
    local a, b = spec.minSize, spec.maxSize
    if size.X < a.X or size.Y < a.Y or size.Z < a.Z
        or size.X > b.X or size.Y > b.Y or size.Z > b.Z then
        return nil
    end
    return source
end

local function nativePart(folder, name)
    local part = folder:FindFirstChild(name)
    if part and part.Parent == folder and part:IsA("BasePart")
        and part.Anchored and not part.CanCollide
        and not part.CanTouch and not part.CanQuery then
        return part
    end
    return nil
end

local function installOne(folder, base, kind, spec, source, anchor, suffix)
    if anchor.Parent ~= folder or not anchor.Anchored
        or anchor.CanCollide or anchor.CanTouch or anchor.CanQuery
        or anchor.Transparency >= .95 then return false end
    if kind == "CornerGuard" and not anchor:IsA("WedgePart") then
        return false
    end
    if kind ~= "CornerGuard" and not anchor:IsA("Part") then
        return false
    end

    local copy = source:Clone()
    local _, originalBounds = copy:GetBoundingBox()
    local scale = math.min(1.10,
        spec.width * .99 / math.max(originalBounds.X, originalBounds.Z),
        spec.height / originalBounds.Y)
    -- Large authored anchor scales down to .10 Roblox studs/authoring stud.
    -- All other models are within 1.1× of their actual in-game dimensions.
    if scale < (spec.worldUp and .07 or .7) then
        copy:Destroy()
        return false
    end
    if not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return false
    end
    local center, bounds = copy:GetBoundingBox()
    if bounds.X > spec.width + .025
        or bounds.Z > spec.width + .025
        or bounds.Y > spec.height + .025 then
        copy:Destroy()
        return false
    end

    -- Native Roblox cylinder fasteners are rotated 90 degrees around Z;
    -- the genuine bolt's modeled shank must remain world-up, not sideways.
    local anchored
    if spec.worldUp then
        anchored = CFrame.new(anchor.Position) * base.CFrame.Rotation
    else
        anchored = anchor.CFrame
    end
    local target = anchored
        * CFrame.new(0, anchor.Size.Y * .5 - bounds.Y * .5 + .006, 0)
    local mesh = {}
    for _, part in ipairs(copy:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                copy:Destroy()
                return false
            end
            part.CFrame = target * center:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("CosmeticOnly", true)
            part:SetAttribute("OriginalFloorHardware3D", true)
            part:SetAttribute("Original3DAssetId", spec.id)
            mesh[#mesh + 1] = part
        end
    end
    if #mesh == 0 or #mesh > 12 then
        copy:Destroy()
        return false
    end

    -- Every genuine MeshPart must be a direct child of the already budgeted
    -- floor Folder: the SINGLE shrink follower captures direct BaseParts.
    -- Hide a native corner Lens *only* if the real replacement is complete.
    for index, part in ipairs(mesh) do
        part.Name = "ApprovedOriginalHardware3D_" .. kind
            .. "_" .. suffix .. "_" .. tostring(index)
        part.Parent = folder
    end
    copy:Destroy()
    anchor.Transparency = 1
    if spec.overlay then
        local overlay = nativePart(folder, spec.overlay .. suffix)
        if overlay then overlay.Transparency = 1 end
    end
    return true
end

local function qualityAllows(kind, tier, variant)
    if tier == "Low" then return false end
    if kind == "CornerGuard" then return tier == "High" end
    if kind == "HarborTie" then
        return variant == "Harbor" and tier == "High"
    end
    return tier == "Medium" or tier == "High"
end

function Kit.install(folder, base, variant, tier, camera)
    if not folder or not folder:IsA("Folder")
        or not base or not base:IsA("BasePart") then return 0 end
    local total = 0
    for _, kind in ipairs(ORDER) do
        if not qualityAllows(kind, tier, variant) then continue end
        local source = genuineTemplate(kind)
        if not source then continue end
        local spec = PROFILES[kind]
        local candidates = {}
        for _, part in ipairs(folder:GetChildren()) do
            local suffix = part.Name:match(spec.pattern)
            if suffix and part:IsA("BasePart")
                and part.Parent == folder then
                candidates[#candidates + 1] = {
                    part = part,
                    suffix = suffix,
                    distance = typeof(camera) == "Vector3"
                        and (camera - part.Position).Magnitude or math.huge,
                }
            end
        end
        table.sort(candidates, function(a,b)
            if a.distance == b.distance then
                return tonumber(a.suffix) < tonumber(b.suffix)
            end
            return a.distance < b.distance
        end)
        local count = 0
        local limit = kind == "AnchorBolt" and
            (tier == "Medium" and 6 or 12) or spec.max
        for _, entry in ipairs(candidates) do
            if count >= limit then break end
            if installOne(folder, base, kind, spec, source,
                entry.part, entry.suffix) then
                count += 1
            end
        end
        total += count
    end
    return total
end

return Kit
