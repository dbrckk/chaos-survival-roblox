--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local VfxQuality = require("../../src/shared/VfxQuality")

describe("Adaptive VFX quality", function()
    it("degrades progressively under sustained low frame rate", function()
        expect(VfxQuality.nextTier("High", 60)).toBe("High")
        expect(VfxQuality.nextTier("High", 40)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 30)).toBe("Low")
    end)

    it("uses hysteresis when recovering performance", function()
        expect(VfxQuality.nextTier("Low", 40)).toBe("Low")
        expect(VfxQuality.nextTier("Low", 45)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 50)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 55)).toBe("High")
    end)

    it("scales particle budgets predictably", function()
        expect(VfxQuality.particleCount("High", 20, 4)).toBe(20)
        expect(VfxQuality.particleCount("Medium", 20, 4)).toBe(14)
        expect(VfxQuality.particleCount("Low", 20, 4)).toBe(9)
        expect(VfxQuality.particleCount("Low", 2, 4)).toBe(4)
    end)

    it("exposes bounded quality scales", function()
        for _, tierName in ipairs({"High", "Medium", "Low"}) do
            local tier = VfxQuality.get(tierName)
            expect(tier.Scale > 0).toBe(true)
            expect(tier.Scale <= 1).toBe(true)
            expect(tier.ParticleScale > 0).toBe(true)
            expect(tier.ParticleScale <= 1).toBe(true)
            expect(tier.UpdateInterval > 0).toBe(true)
        end

        expect(VfxQuality.get("Low").UpdateInterval > VfxQuality.get("High").UpdateInterval).toBe(true)
    end)
end)

return nil
