--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Cosmetics = require("../../src/server/CosmeticsCatalog")
local EffectStyles = require("../../src/server/CosmeticEffectStyles")

describe("Cosmetic inventory", function()
    it("exposes the expanded ordered catalog", function()
        local list = Cosmetics.publicList()
        expect(#list).toBe(25)
        expect(list[1].id).toBe("trail_blue")
        expect(list[1].unlockLevel).toBe(1)
        expect(list[4].id).toBe("trail_plasma")
        expect(list[4].coinPrice).toBe(450)
        expect(list[10].premiumKey).toBe("supporter")
        expect(list[11].premiumKey).toBe("supporter")
        expect(list[12].premiumKey).toBe("neon_pack")
        expect(list[13].premiumKey).toBe("neon_pack")
        expect(list[1].rarity).toBe("Common")
        expect(list[6].rarity).toBe("Legendary")
        expect(list[10].collection).toBe("Founder")
        expect(list[14].arenaMasteryId).toBe("Classic")
        expect(list[14].arenaMasteryPoints).toBe(18)
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

    it("unlocks arena mastery cosmetics at GOLD", function()
        local raw, unlocked = Cosmetics.mergeMasteryUnlocks(
            "trail_blue",
            "Classic=18;Towers=17;Crossroads=36;Orbital=9"
        )

        expect(Cosmetics.canEquip(raw, "trail_gridmaster")).toBe(true)
        expect(Cosmetics.canEquip(raw, "trail_nexus")).toBe(true)
        expect(Cosmetics.canEquip(raw, "aura_towercore")).toBe(false)
        expect(Cosmetics.canEquip(raw, "aura_orbital")).toBe(false)
        expect(#unlocked).toBe(2)

        local secondRaw, secondUnlocked = Cosmetics.mergeMasteryUnlocks(raw, "Classic=36;Towers=18;Crossroads=36;Orbital=18")
        expect(Cosmetics.canEquip(secondRaw, "aura_towercore")).toBe(true)
        expect(Cosmetics.canEquip(secondRaw, "aura_orbital")).toBe(true)
        expect(#secondUnlocked).toBe(2)
    end)

    it("awards advanced arena cosmetics only after saved mastery thresholds", function()
        local initial, early = Cosmetics.mergeMasteryUnlocks(
            "", "Classic=95;Towers=95;Crossroads=95;Orbital=95"
        )
        expect(#early).toBe(4) -- Original four GOLD arena rewards.
        expect(Cosmetics.canEquip(initial, "trail_meteorflare")).toBe(false)
        expect(Cosmetics.canEquip(initial, "aura_stormglass")).toBe(false)
        expect(Cosmetics.canEquip(initial, "aura_parallax")).toBe(false)

        local mythic, unlocked = Cosmetics.mergeMasteryUnlocks(
            initial, "Classic=96;Towers=96;Crossroads=96;Orbital=96"
        )
        expect(#unlocked).toBe(4)
        expect(Cosmetics.canEquip(mythic, "trail_meteorflare")).toBe(true)
        expect(Cosmetics.canEquip(mythic, "aura_stormglass")).toBe(true)
        expect(Cosmetics.canEquip(mythic, "trail_shardstep")).toBe(true)
        expect(Cosmetics.canEquip(mythic, "aura_voidwake")).toBe(true)
        expect(Cosmetics.canEquip(mythic, "aura_coremonarch")).toBe(false)

        local ascendant, late = Cosmetics.mergeMasteryUnlocks(
            mythic, "Classic=192;Towers=192;Crossroads=192;Orbital=192"
        )
        expect(#late).toBe(4)
        expect(Cosmetics.canEquip(ascendant, "aura_coremonarch")).toBe(true)
        expect(Cosmetics.canEquip(ascendant, "trail_thunderline")).toBe(true)
        expect(Cosmetics.canEquip(ascendant, "aura_parallax")).toBe(true)
        expect(Cosmetics.canEquip(ascendant, "trail_stargazer")).toBe(true)
        local unchanged, none = Cosmetics.mergeMasteryUnlocks(
            ascendant, "Classic=192;Towers=192;Crossroads=192;Orbital=192"
        )
        expect(unchanged).toBe(ascendant)
        expect(#none).toBe(0)
        local canBuy, why = Cosmetics.canBuy("", "trail_meteorflare", 999999)
        expect(canBuy).toBe(false)
        expect(why).toBe("not_for_sale")
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


    it("summarizes collection completion and collector milestones", function()
        local state = Cosmetics.collectionState("trail_blue,trail_gold,trail_plasma,trail_prism")

        expect(state.owned).toBe(4)
        expect(state.total).toBe(25)
        expect(state.completedCollections >= 1).toBe(true)
        expect(state.totalCollections >= 4).toBe(true)
        expect(state.nextMilestone).toBe(6)
        expect(state.maxed).toBe(false)

        local complete = Cosmetics.collectionState(Cosmetics.serialize({
            trail_blue = true,
            trail_gold = true,
            trail_void = true,
            trail_plasma = true,
            trail_inferno = true,
            trail_prism = true,
            aura_emerald = true,
            aura_solar = true,
            aura_cosmic = true,
            aura_supporter = true,
            trail_founder = true,
            trail_neon = true,
            aura_neon = true,
            trail_gridmaster = true,
            aura_towercore = true,
            trail_nexus = true,
            aura_orbital = true,
            trail_meteorflare = true,
            aura_stormglass = true,
            trail_shardstep = true,
            aura_voidwake = true,
            aura_coremonarch = true,
            trail_thunderline = true,
            aura_parallax = true,
            trail_stargazer = true,
        }))
        expect(complete.owned).toBe(25)
        expect(complete.maxed).toBe(true)
        expect(complete.nextMilestone).toBe(nil)
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


describe("Premium earned cosmetic visual signatures", function()
    it("uses distinct trail shapes without extra particles or pay-to-win upgrades", function()
        local expected = {
            trail_meteorflare = "Meteorflare",
            trail_shardstep = "Shardstep",
            trail_thunderline = "Thunderline",
            trail_stargazer = "Stargazer",
        }
        local uniqueWidths = {}
        for id, signature in pairs(expected) do
            local item = Cosmetics.get(id)
            expect(item.Signature).toBe(signature)
            expect(item.Kind).toBe("trail")
            expect(item.CoinPrice == nil).toBe(true)
            expect(item.PremiumKey == nil).toBe(true)
            expect(item.ArenaMasteryPoints >= 96).toBe(true)
            local recipe = EffectStyles.trail(item)
            expect(recipe ~= nil).toBe(true)
            expect(recipe.Lifetime >= 0.3 and recipe.Lifetime <= 0.65).toBe(true)
            expect(recipe.LightEmission >= 0.75 and recipe.LightEmission <= 1).toBe(true)
            expect(#recipe.WidthScale.Keypoints >= 5).toBe(true)
            expect(#recipe.Color.Keypoints >= 4).toBe(true)
            expect(uniqueWidths[recipe.WidthScale] == nil).toBe(true)
            uniqueWidths[recipe.WidthScale] = true
        end
        local basic = EffectStyles.trail(Cosmetics.get("trail_blue"))
        expect(basic.Lifetime).toBe(0.48)
        expect(#basic.Color.Keypoints).toBe(2)
        expect(#basic.WidthScale.Keypoints).toBe(3)
        expect(EffectStyles.trail(nil)).toBe(nil)
    end)

    it("assigns original bounded aura timing with a single emitter per item", function()
        local expected = {
            aura_stormglass = "Stormglass",
            aura_voidwake = "Voidwake",
            aura_coremonarch = "CoreMonarch",
            aura_parallax = "Parallax",
        }
        local sizes = {}
        for id, signature in pairs(expected) do
            local item = Cosmetics.get(id)
            expect(item.Signature).toBe(signature)
            expect(item.Kind).toBe("aura")
            expect(item.CoinPrice == nil).toBe(true)
            expect(item.PremiumKey == nil).toBe(true)
            local recipe = EffectStyles.aura(item)
            expect(recipe.Rate >= 10 and recipe.Rate <= 20).toBe(true)
            expect(recipe.Lifetime.Min > 0).toBe(true)
            expect(recipe.Lifetime.Max < 2).toBe(true)
            expect(recipe.Speed.Max <= 3).toBe(true)
            expect(recipe.Brightness <= 1.1).toBe(true)
            expect(#recipe.Color.Keypoints).toBe(3)
            expect(sizes[recipe.Size] == nil).toBe(true)
            sizes[recipe.Size] = true
        end
        local basic = EffectStyles.aura(Cosmetics.get("aura_emerald"))
        expect(basic.Rate).toBe(18)
        expect(basic.Brightness).toBe(0.85)
        expect(#basic.Color.Keypoints).toBe(2)
        expect(EffectStyles.aura(nil)).toBe(nil)
    end)
end)


return nil
