-- Original creator-owned PBR MaterialVariants on safe, stationary
-- cosmetic surfaces only. No Physics, SurfaceAppearance overrides or
-- client writes to protected texture maps.
--
-- Mobile graphics: per-model AND global 2K PBR budgets; draw only visible
-- near-camera architecture. Reconcile material selection incrementally
-- instead of restoring/reapplying the entire world on every map change.
local Players = game:GetService("Players")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local PbrDistrictRules = require(ReplicatedStorage.Shared.PbrDistrictRules)

local player = Players.LocalPlayer
local isTouch = UserInputService.TouchEnabled
local VARIANTS = {
    titanium = {name = "ChaosBrushedTitanium", base = Enum.Material.Foil},
    oxidized = {name = "ChaosOxidizedSteel", base = Enum.Material.CorrodedMetal},
    armor = {name = "ChaosDiamondArmor", base = Enum.Material.DiamondPlate},
    ceramic = {name = "ChaosReactorCeramic", base = Enum.Material.CeramicTiles},
}

local originals = setmetatable({}, {__mode = "k"})
-- A value here means this client owns the exact MaterialVariant and may
-- revert it if the asset leaves the target set. Never revert another writer.
local applied = setmetatable({}, {__mode = "k"})
local boundMap, boundArena, boundDecor, boundLocal = nil, nil, nil, nil
local mapAdded, mapRemoved, arenaAdded = nil, nil, nil
local decorAdded, decorRemoved = nil, nil
local localAdded, localRemoved = nil, nil
local pendingScan = false
local lastCameraPosition = nil

local function tier()
    local selected = player:GetAttribute("VfxQualityTier")
    if type(selected) ~= "string" or not VfxQuality.Tiers[selected] then
        return VfxQuality.initialTier(isTouch)
    end
    return selected
end

local function ready()
    for _, variant in pairs(VARIANTS) do
        local ok, entry = pcall(
            MaterialService.GetMaterialVariant,
            MaterialService, variant.base, variant.name
        )
        if not ok or not entry then return false end
    end
    return true
end

local function restore(part, variant)
    local saved = originals[part]
    -- If another script or Roblox streaming changed the material, do
    -- not overwrite its new state with an obsolete cosmetic snapshot.
    if part.Parent and saved and part.Material == variant.base
        and part.MaterialVariant == variant.name then
        part.Material = saved.material
        part.MaterialVariant = saved.variant
    end
    applied[part] = nil
    originals[part] = nil
end

local function report(count, budget, eligible)
    -- Client-side diagnostic counters for Android capture/QA. Avoid
    -- redundant attribute churn during stationary play and streaming.
    local metrics = {
        PbrActiveSurfaceCount = count,
        PbrActiveSurfaceBudget = budget,
        PbrVisibleCandidateCount = eligible,
    }
    for key, value in pairs(metrics) do
        if player:GetAttribute(key) ~= value then
            player:SetAttribute(key, value)
        end
    end
end

local function scan()
    local selectedTier = tier()
    local ownerLimit = PbrDistrictRules.limit(selectedTier)
    local budget = PbrDistrictRules.globalLimit(selectedTier, isTouch)
    local camera = workspace.CurrentCamera
    local cameraPosition = camera and camera.CFrame.Position or nil
    lastCameraPosition = cameraPosition

    local targets = {}
    local eligibleCount = 0
    if budget > 0 and ownerLimit > 0 and ready() then
        -- Scenery LOD owns the hidden state; this pass only inspects it.
        -- Both server arena Decor and four client-authored playable
        -- district models share ONE per-client budget.
        local groups = {}
        local function collect(root)
            if not root or not root.Parent then return end
            for _, part in ipairs(root:GetDescendants()) do
                local old = applied[part]
                local ownedName = old and old.name or nil
                local ownedStillIntact = old
                    and part.Material == old.base
                    and part.MaterialVariant == old.name
                if old and not ownedStillIntact then
                    -- Preserve ownership boundaries; never reclaim an
                    -- authored external variant after a streaming update.
                    applied[part] = nil
                    originals[part] = nil
                elseif PbrDistrictRules.eligiblePart(part, ownedName)
                    and PbrDistrictRules.withinDistance(
                        part, cameraPosition, selectedTier, isTouch
                    ) then
                    local owner = part.Parent
                    if PbrDistrictRules.eligibleOwner(owner) then
                        local entries = groups[owner]
                        if not entries then
                            entries = {}
                            groups[owner] = entries
                        end
                        entries[#entries + 1] = part
                        eligibleCount += 1
                    end
                end
            end
        end

        collect(boundDecor)
        collect(boundLocal)

        local ranked = {}
        local function score(part)
            return PbrDistrictRules.selectionPriority(
                part, cameraPosition, applied[part] ~= nil)
        end
        for _, parts in pairs(groups) do
            table.sort(parts, function(a, b)
                local sa, sb = score(a), score(b)
                return sa == sb and a.Name < b.Name or sa > sb
            end)
            for i = 1, math.min(ownerLimit, #parts) do
                local part = parts[i]
                local original = originals[part]
                local baseMaterial = original and original.material
                    or part.Material
                local key = PbrDistrictRules.materialKey(part.Name, baseMaterial)
                local chosen = VARIANTS[key]
                if chosen then
                    ranked[#ranked + 1] = {
                        part = part,
                        score = score(part),
                        variant = chosen,
                    }
                end
            end
        end

        table.sort(ranked, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            if a.part.Name ~= b.part.Name then
                return a.part.Name < b.part.Name
            end
            return a.part:GetFullName() < b.part:GetFullName()
        end)
        for i = 1, math.min(budget, #ranked) do
            local entry = ranked[i]
            targets[entry.part] = entry.variant
        end
    end

    -- Diff only: an unchanged selection keeps its PBR variant and texture
    -- binding. No repeated Material/MaterialVariant writes or GPU churn.
    for part, variant in pairs(applied) do
        if targets[part] ~= variant then
            restore(part, variant)
        end
    end

    local count = 0
    for part, chosen in pairs(targets) do
        count += 1
        if not applied[part] then
            originals[part] = {
                material = part.Material,
                variant = part.MaterialVariant,
            }
            part.Material = chosen.base
            part.MaterialVariant = chosen.name
            applied[part] = chosen
        end
    end
    report(count, budget, eligibleCount)
end

-- Collapse same-frame streaming spikes into one diff reconciliation.
-- A short delay allows a newly replicated Model's children to arrive.
local function schedule()
    if pendingScan then return end
    pendingScan = true
    task.delay(0.12, function()
        pendingScan = false
        scan()
    end)
end

local function bindDecor(decor)
    if boundDecor == decor then return end
    if decorAdded then decorAdded:Disconnect() end
    if decorRemoved then decorRemoved:Disconnect() end
    decorAdded, decorRemoved = nil, nil
    boundDecor = decor
    if decor then
        decorAdded = decor.DescendantAdded:Connect(schedule)
        decorRemoved = decor.DescendantRemoving:Connect(schedule)
    end
    schedule()
end

local function bindArena(arena)
    if boundArena == arena then return end
    if arenaAdded then arenaAdded:Disconnect() end
    arenaAdded = nil
    boundArena = arena
    bindDecor(arena and arena:FindFirstChild("Decor"))
    if arena then
        arenaAdded = arena.ChildAdded:Connect(function(child)
            if child.Name == "Decor" then bindDecor(child) end
        end)
    end
end

local function bindMap(map)
    if boundMap == map then return end
    if mapAdded then mapAdded:Disconnect() end
    if mapRemoved then mapRemoved:Disconnect() end
    mapAdded, mapRemoved = nil, nil
    boundMap = map
    bindArena(map and map:FindFirstChild("Arena"))
    if map then
        mapAdded = map.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then bindArena(child) end
        end)
        mapRemoved = map.ChildRemoved:Connect(function(child)
            if child == boundArena then
                bindArena(map:FindFirstChild("Arena"))
            end
        end)
    end
end

local function bindLocal(folder)
    if boundLocal == folder then return end
    if localAdded then localAdded:Disconnect() end
    if localRemoved then localRemoved:Disconnect() end
    localAdded, localRemoved = nil, nil
    boundLocal = folder
    if folder then
        localAdded = folder.DescendantAdded:Connect(schedule)
        localRemoved = folder.DescendantRemoving:Connect(schedule)
    end
    schedule()
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    elseif child.Name == "DistrictSectorSetpiecesLocal" then
        bindLocal(workspace:FindFirstChild("DistrictSectorSetpiecesLocal"))
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == boundMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    elseif child == boundLocal then
        bindLocal(workspace:FindFirstChild("DistrictSectorSetpiecesLocal"))
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(schedule)
bindMap(workspace:FindFirstChild("GeneratedMap"))
bindLocal(workspace:FindFirstChild("DistrictSectorSetpiecesLocal"))
schedule()

-- Follow movement with one slow sampling loop, never RenderStepped/
-- Heartbeat. Also reclaim a capped active surface if scenery LOD hides it
-- or an external source changes its material; no per-Part listeners.
local function staleSelection(position, selectedTier)
    for part, variant in pairs(applied) do
        if not part.Parent
            or not PbrDistrictRules.visible(part)
            or not PbrDistrictRules.withinDistance(
                part, position, selectedTier, isTouch)
            or part.Material ~= variant.base
            or part.MaterialVariant ~= variant.name then
            return true
        end
    end
    return false
end

task.spawn(function()
    while task.wait(isTouch and 1.7 or 2.2) do
        local selectedTier = tier()
        if selectedTier ~= "Low" and (boundDecor or boundLocal) then
            local current = workspace.CurrentCamera
            local position = current and current.CFrame.Position
            if position and (not lastCameraPosition
                or (position - lastCameraPosition).Magnitude >= 32
                or staleSelection(position, selectedTier)) then
                schedule()
            end
        end
    end
end)
