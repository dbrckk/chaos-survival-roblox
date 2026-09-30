local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cosmetics = require(ReplicatedStorage.Shared.Cosmetics)

local CosmeticInventory = {}

local function split(raw)
    local set = {}
    if type(raw) ~= "string" or raw == "" then
        return set
    end

    for id in string.gmatch(raw, "[^,]+") do
        if Cosmetics.get(id) then
            set[id] = true
        end
    end
    return set
end

function CosmeticInventory.deserialize(raw)
    return split(raw)
end

function CosmeticInventory.serialize(set)
    local ids = {}
    for _, id in ipairs(Cosmetics.Order) do
        if set[id] then
            table.insert(ids, id)
        end
    end
    return table.concat(ids, ",")
end

function CosmeticInventory.unlocksForLevel(level)
    local unlocked = {}
    local numericLevel = math.max(1, tonumber(level) or 1)
    for _, id in ipairs(Cosmetics.Order) do
        local item = Cosmetics.get(id)
        if item and numericLevel >= item.UnlockLevel then
            unlocked[id] = true
        end
    end
    return unlocked
end

function CosmeticInventory.mergeLevelUnlocks(raw, level)
    local owned = split(raw)
    local levelUnlocks = CosmeticInventory.unlocksForLevel(level)
    local newlyUnlocked = {}

    for id in pairs(levelUnlocks) do
        if not owned[id] then
            owned[id] = true
            table.insert(newlyUnlocked, id)
        end
    end

    table.sort(newlyUnlocked)
    return CosmeticInventory.serialize(owned), newlyUnlocked
end

function CosmeticInventory.canEquip(raw, id)
    if id == "" then
        return true
    end
    if not Cosmetics.get(id) then
        return false
    end
    return split(raw)[id] == true
end

return CosmeticInventory
