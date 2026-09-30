--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Cosmetics = require("../../src/server/CosmeticsCatalog")

describe("Cosmetic inventory", function()
    it("exposes the expanded ordered catalog", function()
        local list = Cosmetics.publicList()
        expect(#list).toBe(11)
        expect(list[1].id).toBe("trail_blue")
        expect(list[1].unlockLevel).toBe(1)
        expect(list[4].id).toBe("trail_plasma")
        expect(list[4].coinPrice).toBe(450)
        expect(list[10].premiumKey).toBe("supporter")
        expect(list[11].premiumKey).toBe("neon_pack")
    end)

    it("unlocks level cosmetics without granting shop items", function()
        local serialized, unlocked = Cosmetics.mergeLevelUnlocks("", 1)
        expect(serialized).toBe("trail_blue")
        expect(#unlocked).toBe(1)
        expect(Cosmetics.canEquip(serialized, "trail_blue")).toBe(true)
        expect(Cosmetics.canEquip(serialized, "trail_gold")).toBe(false)
        expect(Cosmetics.canEquip(serialized, "trail_plasma")).toBe(false)

        local upgraded = Cosmetics.mergeLevelUnlocks(serialized, 5)
        expect(Cosmetics.canEquip(upgraded, "trail_gold")).toBe(true)
        expect(Cosmetics.canEquip(upgraded, "trail_void")).toBe(true)
        expect(Cosmetics.canEquip(upgraded, "aura_cosmic")).toBe(false)
    end)

    it("validates coin purchases server-side", function()
        local canBuy = Cosmetics.canBuy("trail_blue", "trail_plasma", 450)
        expect(canBuy).toBe(true)

        local insufficient, reason = Cosmetics.canBuy("trail_blue", "trail_plasma", 449)
        expect(insufficient).toBe(false)
        expect(reason).toBe("insufficient_coins")

        local owned, ownedReason = Cosmetics.canBuy("trail_blue,trail_plasma", "trail_plasma", 9999)
        expect(owned).toBe(false)
        expect(ownedReason).toBe("owned")

        local premium, premiumReason = Cosmetics.canBuy("trail_blue", "aura_supporter", 9999)
        expect(premium).toBe(false)
        expect(premiumReason).toBe("not_for_sale")
    end)

    it("adds purchased cosmetics deterministically", function()
        local raw = Cosmetics.buy("trail_blue", "aura_solar")
        expect(raw).toBe("trail_blue,aura_solar")
        expect(Cosmetics.canEquip(raw, "aura_solar")).toBe(true)
    end)

    it("rejects unknown or locked cosmetics", function()
        expect(Cosmetics.canEquip("trail_blue", "not_real")).toBe(false)
        expect(Cosmetics.canEquip("trail_blue", "trail_void")).toBe(false)
    end)

    it("serializes ownership deterministically", function()
        local raw = Cosmetics.serialize({
            aura_cosmic = true,
            trail_void = true,
            trail_blue = true,
            trail_plasma = true,
            trail_gold = true,
        })
        expect(raw).toBe("trail_blue,trail_gold,trail_void,trail_plasma,aura_cosmic")
    end)
end)

return nil
