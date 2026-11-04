-- Authored 2K OpenGL-normal, roughness, metalness and albedo maps on
-- the ACTUAL UV/tangent-ready 2,976-triangle imported ground MeshParts.
-- Templates are serialized by Rojo, not constructed/written by a script:
-- SurfaceAppearance texture-map properties require plugin security.
-- Independent owner-approval audit: Roblox Open Cloud #40682190586.
-- Changes cosmetics only, never server floor, hazards or physics.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local SOURCE_ID = 72507987666671
local HOLDER = "OriginalGroundPbrTemplates"
local MATERIAL = {
    Classic = "DiamondArmor",
    Towers = "BrushedTitanium",
    Crossroads = "OxidizedSteel",
    Orbital = "ReactorCeramic",
    Harbor = "OxidizedSteel",
}
local APPROVED = {
    BrushedTitanium = true,
    OxidizedSteel = true,
    DiamondArmor = true,
    ReactorCeramic = true,
}

function Kit.family(variant)
    return MATERIAL[variant] or MATERIAL.Classic
end

-- Exact ceiling of original PBR-UV-model tiles, not SurfaceAppearance
-- instances. Each imported material group may have ONE cloned template.
-- The same four sets of 2K image IDs are shared between all copies.
-- Android High has 6 primary PBR islands / Medium 2 / Low 0. Desktop
-- gets 12 / 4. Existing FPS/Parts backpressure reclaims them first.
function Kit.tileBudget(tier, pressure, touch, disabled)
    if disabled == true or tier == "Low" then return 0 end
    local value = tonumber(pressure)
    if value == nil or value ~= value then value = 0 end
    local level = math.clamp(math.floor(value), 0, 2)
    if tier == "High" then
        if level == 2 then return 1 end
        if level == 1 then return touch == true and 3 or 6 end
        return touch == true and 6 or 12
    end
    if tier == "Medium" then
        if level == 2 then return 0 end
        if level == 1 then return 1 end
        return touch == true and 2 or 4
    end
    return 0
end

local function template(name)
    if not APPROVED[name] then return nil end
    local holder = ReplicatedStorage:FindFirstChild(HOLDER)
    if not holder or not holder:IsA("Folder") then return nil end
    local child = holder:FindFirstChild(name)
    if not child or not child:IsA("SurfaceAppearance")
        or child.Parent ~= holder then return nil end
    -- Runtime cannot read/write PluginSecurity maps. The 16 exact
    -- approved creator-owned Image URLs are exclusively serialized in
    -- default.project.json and statically compared to Open Cloud audit.
    return child
end

local function finishForPart(variant, part)
    local name = string.upper(part.Name)
    -- Preserve original contrasting non-slip and luminous signaling
    -- material groups (not gameplay hazard telegraphs, which are separate).
    if string.find(name, "SIGNAL", 1, true)
        or string.find(name, "CARBON", 1, true)
        or string.find(name, "GRIP", 1, true) then
        return nil
    end
    if string.find(name, "CERAMIC", 1, true) then
        return "ReactorCeramic"
    end
    if string.find(name, "BRUSHED", 1, true)
        or string.find(name, "ALLOY", 1, true) then
        return "BrushedTitanium"
    end
    if string.find(name, "ARMOR", 1, true)
        and variant ~= "Crossroads" and variant ~= "Harbor" then
        return "DiamondArmor"
    end
    return Kit.family(variant)
end

function Kit.detach(entry)
    if type(entry) ~= "table" then return end
    -- Always destroy OUR optional 2K templates, including a streamed-out
    -- clone that no longer has Parent. No retained GPU objects or leaked
    -- SurfaceAppearance instances after a map/quality/pressure change.
    for _, attached in ipairs(entry.originalPbr or {}) do
        if attached then attached:Destroy() end
    end
    -- Some Roblox glTF imports add a SurfaceAppearance even for untextured
    -- metallic/roughness FACTORS. On premium close-up, swap that original
    -- appearance for our real audited 4-map 2K atlas; NEVER destroy it.
    -- Exact source appearance is returned if the player turns PBR off,
    -- a model streams out or frame pressure rises.
    for _, source in ipairs(entry.originalPbrReplaced or {}) do
        local part, appearance = source.part, source.appearance
        if appearance and part and entry.model
            and part:IsDescendantOf(entry.model) then
            appearance.Parent = part
        elseif appearance then
            appearance:Destroy()
        end
    end
    entry.originalPbr = nil
    entry.originalPbrReplaced = nil
    entry.originalPbrVariant = nil
    entry.originalPbrCount = nil
end

local function intact(entry)
    if type(entry.originalPbr) ~= "table" or #entry.originalPbr == 0 then
        return false
    end
    for _, appearance in ipairs(entry.originalPbr) do
        if not appearance or not appearance.Parent
            or not appearance.Parent:IsA("MeshPart")
            or not appearance.Parent:IsDescendantOf(entry.model) then
            return false
        end
    end
    return true
end

-- Only verified models from PremiumGroundMeshKit.mount may enter.
-- No trust in user-injected Folder names or arbitrary imported assets.
-- Returns genuine SurfaceAppearance count (0 if unavailable). All
-- install errors rollback without leaving half-textured originals.
function Kit.attach(entry, variant)
    if type(entry) ~= "table" or not entry.model
        or not entry.model:IsA("Model")
        or entry.model:GetAttribute("OriginalGroundMeshId") ~= SOURCE_ID
        or entry.model:GetAttribute("CosmeticOnly") ~= true
        or not entry.model.Parent
        or not entry.ground or not entry.ground.Parent
        or entry.ground:GetAttribute("OriginalGroundFinish") ~= true
        or type(entry.pieces) ~= "table" then
        Kit.detach(entry)
        return 0
    end

    if entry.originalPbrVariant == variant and intact(entry) then
        return #entry.originalPbr
    end
    Kit.detach(entry)
    entry.originalPbr = {}
    entry.originalPbrReplaced = {}
    for _, piece in ipairs(entry.pieces) do
        if not piece:IsA("MeshPart")
            or not piece:IsDescendantOf(entry.model) then
            Kit.detach(entry)
            return 0
        end
        local materialName = finishForPart(variant, piece)
        if materialName then
            local ref = template(materialName)
            if not ref then
                Kit.detach(entry)
                return 0
            end
            -- Imported glTF without explicit source texture images may
            -- still carry one engine-created SurfaceAppearance for its
            -- material factors. Preserve EXACT original instance, swap
            -- only on this authenticated local 3D clone, and restore
            -- on rollback; never overwrite PluginSecurity texture fields.
            local old = piece:FindFirstChildOfClass("SurfaceAppearance")
            if old then
                old.Parent = nil
                entry.originalPbrReplaced[#entry.originalPbrReplaced+1] = {
                    part = piece, appearance = old,
                }
            end
            local ok, appearance = pcall(function()
                local clone = ref:Clone()
                clone.Name = "OriginalApprovedGroundPbr2K"
                clone.Parent = piece
                return clone
            end)
            if not ok or not appearance then
                Kit.detach(entry)
                return 0
            end
            entry.originalPbr[#entry.originalPbr+1] = appearance
        end
    end
    if #entry.originalPbr < 1 then
        Kit.detach(entry)
        return 0
    end
    entry.originalPbrVariant = variant
    entry.originalPbrCount = #entry.originalPbr
    return #entry.originalPbr
end

return Kit
