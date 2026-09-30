local Cosmetics = {}

Cosmetics.Definitions = {
    trail_blue = {
        Id = "trail_blue",
        Name = "Blue Pulse",
        Kind = "trail",
        UnlockLevel = 1,
        ColorA = Color3.fromRGB(70, 170, 255),
        ColorB = Color3.fromRGB(170, 225, 255),
    },
    trail_gold = {
        Id = "trail_gold",
        Name = "Golden Rush",
        Kind = "trail",
        UnlockLevel = 3,
        ColorA = Color3.fromRGB(255, 185, 45),
        ColorB = Color3.fromRGB(255, 235, 125),
    },
    trail_void = {
        Id = "trail_void",
        Name = "Void Rift",
        Kind = "trail",
        UnlockLevel = 5,
        ColorA = Color3.fromRGB(145, 70, 255),
        ColorB = Color3.fromRGB(235, 120, 255),
    },
}

Cosmetics.Order = {"trail_blue", "trail_gold", "trail_void"}

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
        })
    end
    return result
end

return Cosmetics
