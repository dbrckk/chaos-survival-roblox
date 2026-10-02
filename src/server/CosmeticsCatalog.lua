local Cosmetics = {}

Cosmetics.Definitions = {
    trail_blue = {
        Id = "trail_blue",
        Name = "Blue Pulse",
        Kind = "trail",
        UnlockLevel = 1,
        Rarity = "Common",
        Collection = "Core Pulse",
        ColorA = Color3.fromRGB(70, 170, 255),
        ColorB = Color3.fromRGB(170, 225, 255),
    },
    trail_gold = {
        Id = "trail_gold",
        Name = "Golden Rush",
        Kind = "trail",
        UnlockLevel = 3,
        Rarity = "Rare",
        Collection = "Core Pulse",
        ColorA = Color3.fromRGB(255, 185, 45),
        ColorB = Color3.fromRGB(255, 235, 125),
    },
    trail_void = {
        Id = "trail_void",
        Name = "Void Rift",
        Kind = "trail",
        UnlockLevel = 5,
        Rarity = "Epic",
        Collection = "Void",
        ColorA = Color3.fromRGB(145, 70, 255),
        ColorB = Color3.fromRGB(235, 120, 255),
    },
    trail_plasma = {
        Id = "trail_plasma",
        Name = "Plasma Wake",
        Kind = "trail",
        CoinPrice = 450,
        Rarity = "Rare",
        Collection = "Neon Circuit",
        ColorA = Color3.fromRGB(30, 255, 210),
        ColorB = Color3.fromRGB(80, 120, 255),
    },
    trail_inferno = {
        Id = "trail_inferno",
        Name = "Inferno",
        Kind = "trail",
        CoinPrice = 850,
        Rarity = "Epic",
        Collection = "Inferno",
        ColorA = Color3.fromRGB(255, 65, 30),
        ColorB = Color3.fromRGB(255, 190, 35),
    },
    trail_prism = {
        Id = "trail_prism",
        Name = "Prism Shift",
        Kind = "trail",
        CoinPrice = 1400,
        Rarity = "Legendary",
        Collection = "Prism",
        ColorA = Color3.fromRGB(255, 70, 210),
        ColorB = Color3.fromRGB(70, 235, 255),
    },
    aura_emerald = {
        Id = "aura_emerald",
        Name = "Emerald Core",
        Kind = "aura",
        CoinPrice = 650,
        Rarity = "Rare",
        Collection = "Elemental Core",
        ColorA = Color3.fromRGB(45, 255, 145),
        ColorB = Color3.fromRGB(150, 255, 205),
    },
    aura_solar = {
        Id = "aura_solar",
        Name = "Solar Crown",
        Kind = "aura",
        CoinPrice = 1100,
        Rarity = "Epic",
        Collection = "Solar",
        ColorA = Color3.fromRGB(255, 180, 35),
        ColorB = Color3.fromRGB(255, 245, 150),
    },
    aura_cosmic = {
        Id = "aura_cosmic",
        Name = "Cosmic Storm",
        Kind = "aura",
        CoinPrice = 1800,
        Rarity = "Legendary",
        Collection = "Cosmic",
        ColorA = Color3.fromRGB(115, 80, 255),
        ColorB = Color3.fromRGB(255, 85, 220),
    },
    aura_supporter = {
        Id = "aura_supporter",
        Name = "Founder Glow",
        Kind = "aura",
        PremiumKey = "supporter",
        Rarity = "Premium",
        Collection = "Founder",
        ColorA = Color3.fromRGB(255, 115, 190),
        ColorB = Color3.fromRGB(255, 225, 120),
    },
    trail_neon = {
        Id = "trail_neon",
        Name = "Hyper Neon",
        Kind = "trail",
        PremiumKey = "neon_pack",
        Rarity = "Premium",
        Collection = "Hyper Neon",
        ColorA = Color3.fromRGB(65, 255, 245),
        ColorB = Color3.fromRGB(255, 70, 230),
    },
}

Cosmetics.Order = {
    "trail_blue",
    "trail_gold",
    "trail_void",
    "trail_plasma",
    "trail_inferno",
    "trail_prism",
    "aura_emerald",
    "aura_solar",
    "aura_cosmic",
    "aura_supporter",
    "trail_neon",
}

function Cosmetics.get(id)
    return Cosmetics.Definitions[id]
end

function Cosmetics.publicList()
    local result = {}
    for _, id in ipairs(Cosmetics.Order) do
        local item = Cosmetics.Definitions[id]
        table.insert(result, {
            id = item.Id,
            name = item.Name,
            kind = item.Kind,
            unlockLevel = item.UnlockLevel,
            coinPrice = item.CoinPrice,
            premiumKey = item.PremiumKey,
            rarity = item.Rarity or "Common",
            collection = item.Collection or "Core",
        })
    end
    return result
end

function Cosmetics.deserialize(raw)
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

function Cosmetics.serialize(set)
    local ids = {}
    for _, id in ipairs(Cosmetics.Order) do
        if set[id] then
            table.insert(ids, id)
        end
    end
    return table.concat(ids, ",")
end

function Cosmetics.mergeLevelUnlocks(raw, level)
    local owned = Cosmetics.deserialize(raw)
    local numericLevel = math.max(1, tonumber(level) or 1)
    local newlyUnlocked = {}

    for _, id in ipairs(Cosmetics.Order) do
        local item = Cosmetics.get(id)
        if item and item.UnlockLevel and numericLevel >= item.UnlockLevel and not owned[id] then
            owned[id] = true
            table.insert(newlyUnlocked, id)
        end
    end

    return Cosmetics.serialize(owned), newlyUnlocked
end

function Cosmetics.canEquip(raw, id)
    if id == "" then
        return true
    end
    if not Cosmetics.get(id) then
        return false
    end
    return Cosmetics.deserialize(raw)[id] == true
end

function Cosmetics.canBuy(raw, id, coins)
    local item = Cosmetics.get(id)
    if not item or not item.CoinPrice or item.CoinPrice <= 0 then
        return false, "not_for_sale"
    end

    if Cosmetics.deserialize(raw)[id] then
        return false, "owned"
    end

    if math.max(0, tonumber(coins) or 0) < item.CoinPrice then
        return false, "insufficient_coins"
    end

    return true, nil
end

function Cosmetics.buy(raw, id)
    local owned = Cosmetics.deserialize(raw)
    owned[id] = true
    return Cosmetics.serialize(owned)
end

return Cosmetics
