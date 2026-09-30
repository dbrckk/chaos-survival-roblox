--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundIntensity = require("../../src/server/RoundIntensity")

describe("Round intensity director", function()
    it("ramps smoothly through a normal round", function()
        local start = RoundIntensity.factor(0, 40, false, false)
        local middle = RoundIntensity.factor(20, 40, false, false)
        local finish = RoundIntensity.factor(40, 40, false, false)

        expect(start).toBe(0.92)
        expect(middle > start).toBe(true)
        expect(finish > middle).toBe(true)
        expect(finish).toBe(1.22)
    end)

    it("caps escalation for solo and double chaos", function()
        expect(RoundIntensity.factor(40, 40, true, false)).toBe(1.14)
        expect(RoundIntensity.factor(40, 40, false, true)).toBe(1.10)
        expect(RoundIntensity.factor(40, 40, true, true)).toBe(1.06)
    end)

    it("clamps progress and spawn delay", function()
        expect(RoundIntensity.progress(-10, 40)).toBe(0)
        expect(RoundIntensity.progress(100, 40)).toBe(1)
        expect(RoundIntensity.spawnDelay(1, 2, 0.6)).toBe(0.6)
        expect(RoundIntensity.spawnDelay(1, 0.5, 0.2)).toBe(2)
    end)
end)

return nil
