--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Cosmetics = require("../../src/server/CosmeticsCatalog")

describe("Cosmetic inventory", function()
    it("exposes a valid ordered catalog", function()
        local list = Cosmetics.publicList()
        expect(#list).toBe(3)
        expect(list[1].id).toBe("trail_blue")
        expect(list[1].unlockLevel).toBe(1)
    end)

    it("unlocks cosmetics according to player level", function()
        local serialized, unlocked = Cosmetics.mergeLevelUnlocks("", 1)
        expect(serialized).toBe("trail_blue")
        expect(#unlocked).toBe(1)
        expect(Cosmetics.canEquip(serialized, "trail_blue")).toBe(true)
        expect(Cosmetics.canEquip(serialized, "trail_gold")).toBe(false)

        local upgraded = Cosmetics.mergeLevelUnlocks(serialized, 3)
        expect(Cosmetics.canEquip(upgraded, "trail_gold")).toBe(true)
        expect(Cosmetics.canEquip(upgraded, "trail_void")).toBe(false)
    end)

    it("rejects unknown or locked cosmetics", function()
        expect(Cosmetics.canEquip("trail_blue", "not_real")).toBe(false)
        expect(Cosmetics.canEquip("trail_blue", "trail_void")).toBe(false)
    end)

    it("serializes ownership deterministically", function()
        local raw = Cosmetics.serialize({
            trail_void = true,
            trail_blue = true,
            trail_gold = true,
        })
        expect(raw).toBe("trail_blue,trail_gold,trail_void")
    end)
end)

return nil
