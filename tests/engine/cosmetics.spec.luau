--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cosmetics = require(ReplicatedStorage.Shared.Cosmetics)
local CosmeticInventory = require("../../src/server/CosmeticInventory")

describe("Cosmetic inventory", function()
    it("exposes a valid ordered catalog", function()
        local list = Cosmetics.publicList()
        expect(#list).toBe(3)
        expect(list[1].id).toBe("trail_blue")
        expect(list[1].unlockLevel).toBe(1)
    end)

    it("unlocks cosmetics according to player level", function()
        local serialized, unlocked = CosmeticInventory.mergeLevelUnlocks("", 1)
        expect(serialized).toBe("trail_blue")
        expect(#unlocked).toBe(1)
        expect(CosmeticInventory.canEquip(serialized, "trail_blue")).toBe(true)
        expect(CosmeticInventory.canEquip(serialized, "trail_gold")).toBe(false)

        local upgraded = CosmeticInventory.mergeLevelUnlocks(serialized, 3)
        expect(CosmeticInventory.canEquip(upgraded, "trail_gold")).toBe(true)
        expect(CosmeticInventory.canEquip(upgraded, "trail_void")).toBe(false)
    end)

    it("rejects unknown or locked cosmetics", function()
        expect(CosmeticInventory.canEquip("trail_blue", "not_real")).toBe(false)
        expect(CosmeticInventory.canEquip("trail_blue", "trail_void")).toBe(false)
    end)

    it("serializes ownership deterministically", function()
        local raw = CosmeticInventory.serialize({
            trail_void = true,
            trail_blue = true,
            trail_gold = true,
        })
        expect(raw).toBe("trail_blue,trail_gold,trail_void")
    end)
end)

return nil
