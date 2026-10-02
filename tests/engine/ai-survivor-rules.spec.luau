--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AISurvivorRules = require("../../src/server/AISurvivorRules")

describe("AI survivor rules", function()
    it("fills a small server toward four visible participants", function()
        expect(AISurvivorRules.desiredBotCount(0)).toBe(0)
        expect(AISurvivorRules.desiredBotCount(1)).toBe(3)
        expect(AISurvivorRules.desiredBotCount(2)).toBe(2)
        expect(AISurvivorRules.desiredBotCount(3)).toBe(1)
        expect(AISurvivorRules.desiredBotCount(4)).toBe(0)
        expect(AISurvivorRules.desiredBotCount(9)).toBe(0)
    end)

    it("rotates distinct behavior profiles", function()
        expect(AISurvivorRules.profileForSlot(1).Id).toBe("Cautious")
        expect(AISurvivorRules.profileForSlot(2).Id).toBe("Balanced")
        expect(AISurvivorRules.profileForSlot(3).Id).toBe("Bold")
        expect(AISurvivorRules.profileForSlot(4).Id).toBe("Cautious")
    end)

    it("delays reactions instead of granting perfect reflexes", function()
        expect(AISurvivorRules.reactionReady(10, 10.19, 0.20)).toBe(false)
        expect(AISurvivorRules.reactionReady(10, 10.20, 0.20)).toBe(true)
        expect(AISurvivorRules.reactionReady(10, 10.50, 0.34)).toBe(true)
    end)

    it("produces stable vote choices inside the available range", function()
        local index = AISurvivorRules.voteIndex(3, 3, 7)
        expect(index >= 1).toBe(true)
        expect(index <= 3).toBe(true)
        expect(AISurvivorRules.voteIndex(3, 3, 7)).toBe(index)
    end)
end)

return nil
