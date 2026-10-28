-- Physically based materials on approved, stationary, non-colliding
-- cosmetic architecture. The game physics/alerts stay completely untouched.
-- Reuses four baked Roblox MaterialService MaterialVariants; do not attempt
-- plugin-protected runtime writes to individual PBR texture maps.
local Players = game:GetService("Players")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local PbrDistrictRules = require(ReplicatedStorage.Shared.PbrDistrictRules)

local player = Players.LocalPlayer
local VARIANTS = {
    titanium = {name = "ChaosBrushedTitanium", base = Enum.Material.Foil},
    oxidized = {name = "ChaosOxidizedSteel", base = Enum.Material.CorrodedMetal},
    armor = {name = "ChaosDiamondArmor", base = Enum.Material.DiamondPlate},
    ceramic = {name = "ChaosReactorCeramic", base = Enum.Material.CeramicTiles},
}

local originals = setmetatable({}, {__mode = "k"})
local applied = setmetatable({}, {__mode = "k"})
local boundMap, boundArena, boundDecor, boundLocal = nil, nil, nil, nil
local mapAdded, mapRemoved, arenaAdded = nil, nil, nil
local decorAdded, decorRemoved = nil, nil
local localAdded, localRemoved = nil, nil
local pendingScan = false

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
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

local function restore()
    for part in pairs(applied) do
        local saved = originals[part]
        if part.Parent and saved then
            -- Restore base before variant. Setting a different base material
            -- can clear the old variant; restoring the variant last is safe.
            part.Material = saved.material
            part.MaterialVariant = saved.variant
        end
        applied[part] = nil
    end
end

local function scan()
    restore()
    local limit = PbrDistrictRules.limit(tier())
    if limit == 0 or not ready() then return end

    -- Four playable sector setpieces live in a separate client-owned root.
    -- Earlier PBR code scanned only GeneratedMap.Decor, leaving these actual
    -- near-player hero structures with plain native Roblox materials.
    local groups = {}
    local function collect(root)
        if not root or not root.Parent then return end
        for _, part in ipairs(root:GetDescendants()) do
            if PbrDistrictRules.eligiblePart(part) then
                local owner = part.Parent
                if PbrDistrictRules.eligibleOwner(owner) then
                    local entries = groups[owner]
                    if not entries then
                        entries = {}
                        groups[owner] = entries
                    end
                    entries[#entries + 1] = part
                end
            end
        end
    end

    collect(boundDecor)
    collect(boundLocal)

    for _, parts in pairs(groups) do
        table.sort(parts, function(a, b)
            local priorityA = PbrDistrictRules.priority(a)
            local priorityB = PbrDistrictRules.priority(b)
            if priorityA ~= priorityB then
                return priorityA > priorityB
            end
            return a.Name < b.Name
        end)
        for index = 1, math.min(limit, #parts) do
            local part = parts[index]
            local key = PbrDistrictRules.materialKey(part.Name, part.Material)
            local chosen = VARIANTS[key]
            if chosen then
                local saved = originals[part]
                if not saved then
                    saved = {material = part.Material, variant = part.MaterialVariant}
                    originals[part] = saved
                end
                part.Material = chosen.base
                part.MaterialVariant = chosen.name
                applied[part] = true
            end
        end
    end
end

-- Event coalescing avoids rescanning after every Part built in the same
-- frame; no RenderStepped/Heartbeat/poller or new network requests.
local function schedule()
    if pendingScan then return end
    pendingScan = true
    task.defer(function()
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
            if child.Name == "Decor" then
                bindDecor(child)
            end
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
