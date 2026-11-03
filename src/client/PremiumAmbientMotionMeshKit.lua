-- Five *real*, creator-owned moving 3D industrial silhouettes.
-- All five Model asset IDs are sourced from Roblox Approved import
-- #41733818047. Never assign Model IDs as MeshPart.MeshId strings.
-- Uses the EXISTING ambient 10Hz animation owner; no RenderStepped/Heartbeat.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}

local PROFILES = {
    Classic = {id = 102850052145878, size = Vector3.new(6.6, 2.7, 4.4)},
    Towers = {id = 72210530094580, size = Vector3.new(3.5, 7.8, 3.5)},
    Crossroads = {id = 116186226477876, size = Vector3.new(5.1, 1.7, 2.3)},
    Orbital = {id = 127850230318627, size = Vector3.new(4.4, 2.8, 3.2)},
    Harbor = {id = 131294203899636, size = Vector3.new(7.5, 4.2, 5.7)},
}
local TARGET_LIMIT = {Low = 2, Medium = 4, High = 6}

local function genuineSource(variant)
    local spec = PROFILES[variant]
    if not spec then return nil end
    local root = ReplicatedStorage:FindFirstChild("ApprovedAmbientMotionTemplates")
    if not root or not root:IsA("Folder")
        or root:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = root:FindFirstChild(variant)
    if not source or not source:IsA("Model") or source.Parent ~= root
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("ApprovedAmbientMotion3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= spec.id then
        return nil
    end
    local count = 0
    for _, desc in ipairs(source:GetDescendants()) do
        if desc:IsA("BasePart") then
            if not desc:IsA("MeshPart") then return nil end
            count += 1
        elseif desc:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, bounds = source:GetBoundingBox()
    if math.min(bounds.X, bounds.Y, bounds.Z) < .5
        or math.max(bounds.X, bounds.Y, bounds.Z) > 8.0 then return nil end
    return source, spec
end

local function mount(folder, item, variant, index, source, spec)
    local native = item.part
    if not native or native.Parent ~= folder or not native:IsA("Part")
        or not native.Anchored or native.CanCollide
        or native.CanTouch or native.CanQuery then return false end

    local copy = source:Clone()
    local _, sourceBounds = copy:GetBoundingBox()
    local scale = math.min(1.85,
        spec.size.X / sourceBounds.X,
        spec.size.Y / sourceBounds.Y,
        spec.size.Z / sourceBounds.Z)
    if scale < .35 then copy:Destroy(); return false end
    local scaled = pcall(function() copy:ScaleTo(scale) end)
    if not scaled then copy:Destroy(); return false end

    local bodyFrame, bounds = copy:GetBoundingBox()
    if bounds.X > spec.size.X + .10
        or bounds.Y > spec.size.Y + .10
        or bounds.Z > spec.size.Z + .10 then
        copy:Destroy()
        return false
    end

    local pieces = {}
    for _, part in ipairs(copy:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                copy:Destroy()
                return false
            end
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("Original3DAssetId", spec.id)
            part:SetAttribute("CosmeticOnly", true)
            part:SetAttribute("ApprovedAmbientMotion3D", true)
            pieces[#pieces + 1] = part
        end
    end
    if #pieces < 1 or #pieces > 12 then copy:Destroy(); return false end

    -- Translate the actual imported geometry center into the native flight
    -- path; the Model's authoring pivot may not be at its bounding box center.
    local facing = CFrame.new(native.Position)
    if variant == "Harbor" then
        facing *= CFrame.Angles(0, math.rad(index % 2 == 0 and 180 or 0), 0)
    elseif variant == "Crossroads" then
        facing *= CFrame.Angles(0, math.rad(index > 2 and 90 or 0), 0)
    end
    local newPivot = facing * bodyFrame:ToObjectSpace(copy:GetPivot())
    copy:PivotTo(newPivot)

    copy.Name = "OriginalApprovedAmbient3D_" .. variant .. "_" .. tostring(index)
    copy:SetAttribute("Original3DAssetId", spec.id)
    copy:SetAttribute("CosmeticOnly", true)
    copy:SetAttribute("ApprovedAmbientMotion3D", true)
    copy.Parent = folder
    item.mesh = copy
    item.meshParts = pieces
    item.meshPivot = copy:GetPivot()
    item.nativeTransparency = native.Transparency
    item.glowTransparency = item.glow and item.glow.Transparency or nil

    -- Local native fallback objects remain as motion anchors but are
    -- visually replaced only AFTER all genuine MeshParts are installed.
    -- Transparency (not LocalTransparencyModifier) cannot be overridden by
    -- the existing scenery LOD, which writes local transparency modifiers.
    native.Transparency = 1
    if item.glow and item.glow.Parent then item.glow.Transparency = 1 end
    return true
end

function Kit.install(folder, tracked, variant, tier)
    local source, spec = genuineSource(variant)
    if not source or not folder or not folder:IsA("Folder") then
        return 0
    end
    local maxCount = TARGET_LIMIT[tier] or TARGET_LIMIT.Low
    local count = 0
    for index, item in ipairs(tracked) do
        if count >= maxCount then break end
        if mount(folder, item, variant, index, source, spec) then
            count += 1
        end
    end
    return count
end

function Kit.phase(item, phase, pulse)
    local mesh = item.mesh
    if not mesh or not mesh.Parent then return end
    local dim = phase == "round" and .16
        or (phase == "ready" and .06 or 0)
    local flash = math.clamp(tonumber(pulse) or 0, 0, 1)
    for _, part in ipairs(item.meshParts or {}) do
        if part.Parent then
            -- Preserve approved material colors, tactile UVs and safety.
            -- Never make the 3D machine Neon or a fake warning surface.
            part.Transparency = math.clamp(
                .055 + dim + flash * .16, 0, .40)
        end
    end
end

function Kit.move(item)
    local model = item.mesh
    if not model then return end
    if model.Parent and item.part and item.part.Parent
        and typeof(item.base) == "Vector3" then
        -- One existing 10Hz motion owner moves every source MeshPart
        -- together, maintaining the authored mechanical proportions.
        model:PivotTo(CFrame.new(item.part.Position - item.base) * item.meshPivot)
        return
    end
    -- In the unlikely event that a clone is removed while its map remains,
    -- restore the original animated prop rather than a permanently blank sky.
    if item.part and item.part.Parent then
        item.part.Transparency = item.nativeTransparency or .18
    end
    if item.glow and item.glow.Parent then
        item.glow.Transparency = item.glowTransparency or .18
    end
    item.mesh = nil
    item.meshParts = nil
end

return Kit
