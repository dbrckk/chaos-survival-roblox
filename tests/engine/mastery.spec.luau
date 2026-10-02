--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Mastery = require("../../src/server/Mastery")

describe("Arena and disaster mastery", function()
    it("serializes mastery deterministically", function()
        local raw = Mastery.serialize({
            Meteors = 12,
            Classic = 7,
            Tornado = 3,
        })
        expect(raw).toBe("Classic=7;Meteors=12;Tornado=3")
        expect(Mastery.points(raw, "Meteors")).toBe(12)
    end)

    it("adds participation and survival progress", function()
        local raw, first = Mastery.add("", "Classic", Mastery.roundGain(false))
        expect(first).toBe(1)

        local upgraded, second = Mastery.add(raw, "Classic", Mastery.roundGain(true))
        expect(second).toBe(4)
        expect(Mastery.points(upgraded, "Classic")).toBe(4)
    end)

    it("exposes clear long-term tiers", function()
        local rookie = Mastery.state(0)
        expect(rookie.tier).toBe("ROOKIE")
        expect(rookie.nextTier).toBe("BRONZE")
        expect(rookie.nextPoints).toBe(3)

        local silver = Mastery.state(11)
        expect(silver.tier).toBe("SILVER")
        expect(silver.nextTier).toBe("GOLD")
        expect(silver.remaining).toBe(7)

        local elite = Mastery.state(50)
        expect(elite.tier).toBe("ELITE")
        expect(elite.maxed).toBe(true)
    end)
end)

return nil
