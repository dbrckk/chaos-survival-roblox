-- UV/tangent-ready, approved 2K metallic/ceramic surface finishing of
-- creator-owned TRUE Sky Spine gateways and TRUE bridge meshes.
-- Reuses the existing 16 verified Open Cloud-owned images serialized as
-- SurfaceAppearance in default.project.json. No runtime texture writes,
-- remote assets or additional per-frame loop. Retains source material
-- factors for exact cosmetic rollback.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroundFinishes = if script and script.Parent
    and script.Parent:FindFirstChild("PremiumGroundPbrKit")
    then require(script.Parent.PremiumGroundPbrKit)
    else require("./PremiumGroundPbrKit")

local Kit = {}
local APPROVED = {
    route = 94023662427980,
    crown = 71492051540032,
}
local FAMILIES = {
    Classic = true, Towers = true, Crossroads = true,
    Orbital = true, Harbor = true,
}
local FINISHES = {
    BrushedTitanium = true, OxidizedSteel = true,
    DiamondArmor = true, ReactorCeramic = true,
}

-- A budget counts COMPLETE bridge/gateway entries, not arbitrary
-- SurfaceAppearance instances or detached 3D fragments. Desktop can
-- afford one more nearby bridge or arch than Android under no pressure.
function Kit.entryBudget(tier, pressure, touch, disabled)
    if disabled == true or tier == "Low" then return 0 end
    local n = tonumber(pressure)
    if not n or n ~= n then n = 0 end
    local stress = math.clamp(math.floor(n), 0, 2)
    if stress == 2 then return 0 end
    if tier == "High" then
        if stress == 1 then return touch == true and 0 or 1 end
        return touch == true and 1 or 2
    end
    if tier == "Medium" then
        if stress == 1 and touch == true then return 0 end
        return 1
    end
    return 0
end

local function materialFor(part, variant)
    local name = string.upper(part.Name)
    if name:find("SIGNAL", 1, true)
        or name:find("GRIP", 1, true)
        or name:find("CARBON", 1, true) then
        -- Never recolor real route directions, luminous warnings or
        -- non-slip contrasting elements with metallic 2K albedo.
        return nil
    end
    if name:find("CERAMIC", 1, true) then return "ReactorCeramic" end
    if name:find("BRUSHED", 1, true)
        or name:find("ALLOY", 1, true) then return "BrushedTitanium" end
    if name:find("ARMOR", 1, true) then
        if variant == "Crossroads" or variant == "Harbor" then
            return "OxidizedSteel"
        end
        return GroundFinishes.family(variant)
    end
    return nil
end

local function validModel(model, kind)
    if not model or not model:IsA("Model") or not model.Parent
        or model:GetAttribute("CosmeticOnly") ~= true
        or not APPROVED[kind] then return false end
    if kind == "route" then
        return model:GetAttribute("OriginalPremiumRouteAssetId")
            == APPROVED.route and model.Name == "OriginalPremiumRouteMesh"
    end
    return model:GetAttribute("Original3DAssetId") == APPROVED.crown
        and model.Name == "OriginalApprovedSkySpineCrown3D"
end

local function sourceTemplate(name)
    if not FINISHES[name] then return nil end
    local holder = ReplicatedStorage:FindFirstChild("OriginalGroundPbrTemplates")
    local src = holder and holder:FindFirstChild(name)
    if not holder or not holder:IsA("Folder") or not src
        or not src:IsA("SurfaceAppearance") or src.Parent ~= holder then
        return nil
    end
    return src
end

local function release(state)
    for _, item in ipairs(state.created) do
        item:Destroy()
    end
    for _, old in ipairs(state.originals) do
        if old.appearance then
            local part = old.part
            if part and part.Parent
                and part:IsDescendantOf(state.model) then
                if part:FindFirstChildOfClass("SurfaceAppearance") then
                    -- Never overwrite a later unrelated appearance.
                    old.appearance.Parent = state.model
                else
                    old.appearance.Parent = part
                end
            else
                old.appearance:Destroy()
            end
        end
    end
end

function Kit.detach(entry)
    if type(entry) ~= "table" then return end
    for _, state in ipairs(entry.routePbrStates or {}) do
        release(state)
    end
    entry.routePbrStates = nil
    entry.routePbrVariant = nil
    entry.routePbrKind = nil
    entry.routePbrCount = nil
end

local function stillIntact(entry, models, variant)
    if entry.routePbrStates == nil
        or #entry.routePbrStates ~= #models then return false end
    for i, state in ipairs(entry.routePbrStates) do
        if state.model ~= models[i] or not state.model.Parent
            or #state.created < 1 then return false end
        local covered = {}
        for _, overlay in ipairs(state.created) do
            local part = overlay.Parent
            if not overlay:IsA("SurfaceAppearance")
                or not part or not part:IsA("MeshPart")
                or not part:IsDescendantOf(state.model)
                or overlay.Name ~= "OriginalApprovedBridgePbr2K"
                or not materialFor(part, variant)
                or covered[part] then
                return false
            end
            covered[part] = true
        end
        -- Imported MeshParts may stream in after the initial PBR mount.
        -- A late armor panel must not remain bare while the older parts
        -- keep their 2K overlays indefinitely. Rebuild the COMPLETE
        -- entry on the existing camera sample, never a partial patch.
        for _, part in ipairs(state.model:GetDescendants()) do
            if part:IsA("MeshPart") and materialFor(part, variant)
                and not covered[part] then
                return false
            end
        end
    end
    return true
end

-- Strictly verify the existing owner-created clone identity BEFORE
-- cloning the signed project PBR library. The exact same four 2K maps
-- are shared with the already-approved arena ground pipeline.
function Kit.apply(entry, kind, variant, allowed)
    if type(entry) ~= "table" or not allowed
        or not FAMILIES[variant] or not APPROVED[kind] then
        Kit.detach(entry)
        return 0
    end
    local models = {}
    local candidates = kind == "route" and entry.models
        or {entry.model}
    if type(candidates) ~= "table" then
        Kit.detach(entry)
        return 0
    end
    for _, model in ipairs(candidates) do
        if validModel(model, kind) then
            models[#models + 1] = model
        end
    end
    if #models < 1 or #models > 4
        or (kind == "crown" and #models ~= 1) then
        Kit.detach(entry)
        return 0
    end
    if entry.routePbrVariant == variant and entry.routePbrKind == kind
        and stillIntact(entry, models, variant) then
        return entry.routePbrCount
    end
    Kit.detach(entry)
    local states = {}
    local total = 0
    -- All-or-nothing per physical route: never apply a different material
    -- to half of the bridge when one template is temporarily unavailable.
    for _, model in ipairs(models) do
        local state = {model = model, created = {}, originals = {}}
        states[#states + 1] = state
        local candidatesByPart = {}
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                if not part:IsA("MeshPart") then
                    for _, existing in ipairs(states) do release(existing) end
                    return 0
                end
                local finish = materialFor(part, variant)
                if finish then
                    candidatesByPart[#candidatesByPart + 1] = {
                        part = part, finish = finish,
                    }
                end
            elseif part:IsA("LuaSourceContainer") then
                for _, existing in ipairs(states) do release(existing) end
                return 0
            end
        end
        if #candidatesByPart < 1 or #candidatesByPart > 7 then
            for _, existing in ipairs(states) do release(existing) end
            return 0
        end
        for _, item in ipairs(candidatesByPart) do
            local source = sourceTemplate(item.finish)
            if not source then
                for _, existing in ipairs(states) do release(existing) end
                return 0
            end
            local old = item.part:FindFirstChildOfClass("SurfaceAppearance")
            if old then
                old.Parent = nil
                state.originals[#state.originals + 1] = {
                    part = item.part, appearance = old,
                }
            end
            local ok, clone = pcall(function()
                local appearance = source:Clone()
                appearance.Name = "OriginalApprovedBridgePbr2K"
                appearance.Parent = item.part
                return appearance
            end)
            if not ok or not clone then
                for _, existing in ipairs(states) do release(existing) end
                return 0
            end
            state.created[#state.created + 1] = clone
            total += 1
        end
    end
    entry.routePbrStates = states
    entry.routePbrVariant = variant
    entry.routePbrKind = kind
    entry.routePbrCount = total
    return total
end

function Kit.count(entry)
    local n, materials = 0, 0
    for _, state in ipairs(entry and entry.routePbrStates or {}) do
        local genuine = 0
        for _, appearance in ipairs(state.created) do
            if appearance.Parent and appearance.Parent:IsA("MeshPart")
                and appearance.Parent:IsDescendantOf(state.model) then
                genuine += 1
            end
        end
        if genuine > 0 then
            n += 1
            materials += genuine
        end
    end
    return n, materials
end

return Kit
