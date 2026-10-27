-- Four baked, reusable PBR MaterialVariants are defined in the Rojo
-- MaterialService tree. Never mutate ColorMap/NormalMap/RoughnessMap/
-- MetalnessMap at runtime: Roblox protects those properties for plugins.
-- Apply variants only to non-colliding ORIGINAL scenery already in the map.
-- Low mobile retains the authored native material; Medium is selective.
local Players = game:GetService("Players")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer

local VARIANTS = {
    titanium = {name = "ChaosBrushedTitanium", base = Enum.Material.Foil},
    oxidized = {name = "ChaosOxidizedSteel", base = Enum.Material.CorrodedMetal},
    armor = {name = "ChaosDiamondArmor", base = Enum.Material.DiamondPlate},
    ceramic = {name = "ChaosReactorCeramic", base = Enum.Material.CeramicTiles},
}
local originals = setmetatable({}, {__mode = "k"})
local applied = setmetatable({}, {__mode = "k"})
local counts = setmetatable({}, {__mode = "k"})
local decorAdded = nil
local arenaAdded = nil
local mapAdded = nil
local mapRemoved = nil
local boundMap = nil
local boundArena = nil
local boundDecor = nil

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
end

local function templatesReady()
    for _, info in pairs(VARIANTS) do
        local ok, actual = pcall(function()
            return MaterialService:GetMaterialVariant(info.base, info.name)
        end)
        if not ok or not actual then
            return false
        end
    end
    return true
end

local function originalFor(part)
    local record = originals[part]
    if not record then
        record = {material = part.Material, variant = part.MaterialVariant}
        originals[part] = record
    end
    return record
end

local function restore()
    for part in pairs(applied) do
        local original = originals[part]
        if part.Parent and original then
            part.MaterialVariant = original.variant
            part.Material = original.material
        end
        applied[part] = nil
    end
    table.clear(counts)
end

local function approvedOwner(part)
    if not part:IsA("BasePart") or part:IsA("Terrain")
        or not part.Anchored or part.CanCollide or part.CanQuery
        or part.CanTouch or part.Transparency >= 0.16
        or part.Material == Enum.Material.Neon
        or part.Material == Enum.Material.Glass
    then
        return nil
    end
    local minimum = math.min(part.Size.X, part.Size.Y, part.Size.Z)
    local longest = math.max(part.Size.X, part.Size.Y, part.Size.Z)
    if longest < 3 or minimum < 0.35 then
        return nil
    end
    local owner = part.Parent
    if not owner or not owner:IsA("Model") then
        return nil
    end
    if owner:GetAttribute("ArenaDistrictArchitecture") == true
        or owner:GetAttribute("CornerLandmarkIndex") ~= nil
        or owner.Name == "ArenaHeroArchitecture3D"
        or owner:GetAttribute("ChaosPerimeterStation") == true
    then
        return owner
    end
    return nil
end

local function materialFor(part)
    local name = part.Name:lower()
    if name:find("foundation", 1, true)
        or name:find("basalt", 1, true)
        or name:find("concrete", 1, true)
        or name:find("ballast", 1, true)
        or name:find("ceramic", 1, true)
    then
        return VARIANTS.ceramic
    end
    if name:find("armor", 1, true)
        or name:find("armour", 1, true)
        or name:find("plate", 1, true)
        or name:find("reinforce", 1, true)
        or name:find("deck", 1, true)
    then
        return VARIANTS.armor
    end
    if name:find("rust", 1, true)
        or name:find("service", 1, true)
        or name:find("support", 1, true)
        or name:find("shroud", 1, true)
        or part.Material == Enum.Material.CorrodedMetal
    then
        return VARIANTS.oxidized
    end
    return VARIANTS.titanium
end

local function apply(part)
    if applied[part] then return end
    local owner = approvedOwner(part)
    if not owner then return end
    local currentTier = tier()
    if currentTier == "Low" then return end
    local currentCount = counts[owner] or 0
    -- This caps texture use per model, rather than creating 4K textures
    -- on EVERY tiny ring segment and exhausting phone texture memory.
    local limit = currentTier == "Medium" and 6 or 16
    if currentCount >= limit then return end
    local chosen = materialFor(part)
    originalFor(part)
    part.Material = chosen.base
    part.MaterialVariant = chosen.name
    applied[part] = true
    counts[owner] = currentCount + 1
end

local function rescan()
    restore()
    if tier() == "Low" or not templatesReady() then
        return
    end
    local decor = boundDecor
    if not decor or not decor.Parent then return end
    for _, object in ipairs(decor:GetDescendants()) do
        apply(object)
    end
end

local function bindDecor(decor)
    if boundDecor == decor then return end
    if decorAdded then decorAdded:Disconnect() end
    decorAdded = nil
    restore()
    boundDecor = decor
    if decor then
        decorAdded = decor.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then apply(part) end
        end)
    end
    rescan()
end

local function bindArena(arena)
    if arena == boundArena then return end
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
    if map == boundMap then return end
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

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == boundMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rescan)
bindMap(workspace:FindFirstChild("GeneratedMap"))
