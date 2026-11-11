-- Genuine 2K normal/roughness/metalness on the nearest owner-approved
-- nonphysical seven-group sculptures. No new texture IDs: reuse the
-- four audited creator-owned SurfaceAppearance maps already serialized
-- in default.project.json. Scenery LOD owns the only periodic call.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
-- Each permitted bucket is made by an existing validated original
-- MeshPart owner, not by scanning arbitrary descendants of Workspace.
-- Harbor's existing dock structures keep their own PBR; this shared
-- quota also covers the new approved near-camera atmospheric columns.
local SOURCES = {
    Classic = {
        {folder = "ApprovedAtmosphereColumnsLocal", id = 91626128452597},
        {folder = "ApprovedClassicBroadcastFinLocal", id = 123049626693705},
        {folder = "ApprovedOriginalIdentitySpinesLocal", id = 105555650820011},
    },
    Towers = {
        {folder = "ApprovedAtmosphereColumnsLocal", id = 107521411452905},
        {folder = "ApprovedTowersMachineryLocal", id = 72143366927826},
        {folder = "ApprovedOriginalIdentitySpinesLocal", id = 86423178125318},
    },
    Crossroads = {
        {folder = "ApprovedAtmosphereColumnsLocal", id = 93993697329658},
        {folder = "ApprovedCrossroadsEntrancePortalsLocal", id = 127067628128103},
        {folder = "ApprovedCrossroadsOpenGantryLocal", id = 90844491148907},
    },
    Orbital = {
        {folder = "ApprovedAtmosphereColumnsLocal", id = 119010829781313},
        {folder = "ApprovedOrbitalReactorLandmarksLocal", id = 104654294187035},
        {folder = "ApprovedOrbitalReactorLandmarksLocal", id = 138666009076890},
    },
    Harbor = {
        {folder = "ApprovedAtmosphereColumnsLocal", id = 76194593490199},
    },
}
local KNOWN_FINISHES = {
    DiamondArmor = true,
    OxidizedSteel = true,
    BrushedTitanium = true,
    ReactorCeramic = true,
}
local states = {}

-- Hard cap of complete seven-MeshPart Models (NOT a cap per bucket).
-- Severe pressure or graphics Low releases all extra appearance clones.
function Kit.budget(tier, pressure, touch, disabled)
    if disabled == true or tier == "Low" then return 0 end
    if tier ~= "Medium" and tier ~= "High" then return 0 end
    local load = tonumber(pressure)
    if not load or load ~= load or math.abs(load) == math.huge then load = 0 end
    local level = math.clamp(math.floor(load), 0, 2)
    if level >= 2 then return 0 end
    if tier == "Medium" then
        return level == 1 and 1 or (touch == true and 2 or 3)
    end
    if level == 1 then return touch == true and 2 or 3 end
    return touch == true and 4 or 6
end

function Kit.finishFor(partName, variant)
    local name = string.upper(tostring(partName or ""))
    -- Preserve emissive signals, dark carbon, nonslip rubber and glass.
    -- These are necessary for orientation and readable hazard warnings.
    for _, blocked in ipairs({"SIGNAL", "CARBON", "GRIP", "GLASS"}) do
        if name:find(blocked, 1, true) then return nil end
    end
    if name:find("CERAMIC", 1, true) then return "ReactorCeramic" end
    if name:find("BRUSHED", 1, true)
        or name:find("ALLOY", 1, true) then return "BrushedTitanium" end
    if name:find("ARMOR", 1, true) then
        return (variant == "Crossroads" or variant == "Harbor")
            and "OxidizedSteel" or "DiamondArmor"
    end
    return nil
end

local function sourceAppearance(family)
    if not KNOWN_FINISHES[family] then return nil end
    local holder = ReplicatedStorage:FindFirstChild("OriginalGroundPbrTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage then return nil end
    local original = holder:FindFirstChild(family)
    if original and original:IsA("SurfaceAppearance")
        and original.Parent == holder then return original end
    return nil
end

local function piecesFor(model, folder, id, variant)
    if not model:IsA("Model") or model.Parent ~= folder
        or model:GetAttribute("Original3DAssetId") ~= id
        or model:GetAttribute("CosmeticOnly") ~= true then return nil end
    local pieces = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return nil end
            pieces[#pieces + 1] = part
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if #pieces ~= 7 then return nil end
    local any = false
    for _, part in ipairs(pieces) do
        if Kit.finishFor(part.Name, variant) then any = true end
    end
    return any and pieces or nil
end

local function release(model)
    local state = states[model]
    if not state then return end
    states[model] = nil
    -- Delete OUR clones before returning original glTF factor appearances.
    for _, overlay in ipairs(state.created) do
        overlay:Destroy()
    end
    for _, item in ipairs(state.originals) do
        local appearance, part = item.appearance, item.part
        if appearance and appearance.Parent ~= nil then
            appearance.Parent = nil
        end
        if appearance and part and part:IsDescendantOf(model) then
            if not part:FindFirstChildOfClass("SurfaceAppearance") then
                appearance.Parent = part
            elseif model.Parent then
                -- Another writer installed a new appearance: do not
                -- take ownership of it, retain the old one off-surface.
                appearance.Parent = model
            else
                appearance:Destroy()
            end
        elseif appearance then
            appearance:Destroy()
        end
    end
end

local function intact(model, state, pieces, variant)
    if not model.Parent or state.variant ~= variant
        or #state.created == 0 then return false end
    local covered = {}
    for _, overlay in ipairs(state.created) do
        local parent = overlay.Parent
        if not parent or not parent:IsA("MeshPart")
            or not parent:IsDescendantOf(model)
            or overlay.Name ~= "OriginalNearfieldPbr2K"
            or parent:FindFirstChildOfClass("SurfaceAppearance") ~= overlay
            or covered[parent] then return false end
        covered[parent] = true
    end
    for _, part in ipairs(pieces) do
        if Kit.finishFor(part.Name, variant) and not covered[part] then
            return false
        end
    end
    return true
end

local function install(model, pieces, variant)
    local state = {variant = variant, created = {}, originals = {}}
    states[model] = state
    -- Abort the whole model on an engine error or missing original atlas.
    -- Never keep a half-finished 3D sculpture with arbitrary mixed maps.
    local success = pcall(function()
        for _, part in ipairs(pieces) do
            local family = Kit.finishFor(part.Name, variant)
            if family then
                local template = sourceAppearance(family)
                if not template then error("Approved nearfield PBR template missing") end
                local original = part:FindFirstChildOfClass("SurfaceAppearance")
                if original then
                    original.Parent = nil
                    state.originals[#state.originals + 1] = {
                        part = part, appearance = original,
                    }
                end
                local overlay = template:Clone()
                state.created[#state.created + 1] = overlay
                overlay.Name = "OriginalNearfieldPbr2K"
                overlay.Parent = part
            end
        end
        if #state.created == 0 then error("No authored steel/ceramic surface") end
    end)
    if not success then
        release(model)
        return false
    end
    return true
end

function Kit.reconcile(arena, cameraPoint, cameraReady, tier, touch, pressure, disabled)
    local variant = arena and arena:GetAttribute("VariantId")
    local permitted = SOURCES[variant]
    local budget = Kit.budget(tier, pressure, touch, disabled)
    local generated = workspace:FindFirstChild("GeneratedMap")
    if not arena or not arena:IsA("Folder") or arena.Name ~= "Arena"
        or not generated or arena.Parent ~= generated
        or not permitted or cameraReady ~= true
        or typeof(cameraPoint) ~= "Vector3" then
        budget = 0
    end

    local candidates = {}
    if budget > 0 then
        local scanned = {}
        for _, spec in ipairs(permitted) do
            local folder = workspace:FindFirstChild(spec.folder)
            if folder and folder:IsA("Folder") and folder.Parent == workspace
                and folder:GetAttribute("CosmeticOnly") == true then
                for _, model in ipairs(folder:GetChildren()) do
                    if not scanned[model] then
                        local pieces = piecesFor(model, folder, spec.id, variant)
                        if pieces then
                            -- Orbital uses TWO distinct approved source IDs
                            -- inside the same bucket; only deduplicate a
                            -- model once its matching ID was verified.
                            scanned[model] = true
                            local position = model:GetPivot().Position
                            local distance = (position - cameraPoint).Magnitude
                            if distance <= (tier == "High" and 245 or 175) then
                                candidates[#candidates + 1] = {
                                    model = model, pieces = pieces,
                                    distance = distance,
                                }
                            end
                        end
                    end
                end
            end
        end
        table.sort(candidates, function(a, b)
            if a.distance ~= b.distance then return a.distance < b.distance end
            return a.model:GetFullName() < b.model:GetFullName()
        end)
    end

    local selected = {}
    for i = 1, math.min(#candidates, budget) do
        local item = candidates[i]
        selected[item.model] = item
    end
    -- Reclaim GPU overlays BEFORE applying to new candidates, including
    -- when streaming, rotation, graphics pressure or user PBR opt-out
    -- makes an old object stale.
    for model in pairs(states) do
        if not selected[model] then release(model) end
    end
    local models, surfaces = 0, 0
    for model, item in pairs(selected) do
        local state = states[model]
        if state and not intact(model, state, item.pieces, variant) then
            release(model)
            state = nil
        end
        if not state and install(model, item.pieces, variant) then
            state = states[model]
        end
        if state then
            models += 1
            surfaces += #state.created
        end
    end
    return models, surfaces
end

return Kit
