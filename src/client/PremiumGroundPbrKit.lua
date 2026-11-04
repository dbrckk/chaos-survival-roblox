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
    for _, attached in ipairs(entry.originalPbr or {}) do
        if attached and attached.Parent then attached:Destroy() end
    end
    entry.originalPbr = nil
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
            or appearance.Parent.Parent ~= entry.model then
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
    local work = {}
    for _, piece in ipairs(entry.pieces) do
        if not piece:IsA("MeshPart") or piece.Parent ~= entry.model then
            for _, appearance in ipairs(work) do appearance:Destroy() end
            return 0
        end
        if not piece:FindFirstChildOfClass("SurfaceAppearance") then
            local materialName = finishForPart(variant, piece)
            local ref = materialName and template(materialName)
            if materialName and not ref then
                for _, appearance in ipairs(work) do appearance:Destroy() end
                return 0
            end
            if ref then
                local ok, appearance = pcall(function()
                    local clone = ref:Clone()
                    clone.Name = "OriginalApprovedGroundPbr2K"
                    clone.Parent = piece
                    return clone
                end)
                if not ok or not appearance then
                    for _, item in ipairs(work) do item:Destroy() end
                    return 0
                end
                work[#work + 1] = appearance
            end
        end
    end
    if #work < 1 then return 0 end
    entry.originalPbr = work
    entry.originalPbrVariant = variant
    entry.originalPbrCount = #work
    return #work
end

return Kit
