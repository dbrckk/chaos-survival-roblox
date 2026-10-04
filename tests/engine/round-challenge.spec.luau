--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundChallenge = require("../../src/server/RoundChallenge")

describe("Round challenge", function()
    it("rotates deterministic challenge types across rounds", function()
        expect(RoundChallenge.forRound(1).Id).toBe("SHARD_HUNT")
        expect(RoundChallenge.forRound(2).Id).toBe("MOBILITY_MASTER")
        expect(RoundChallenge.forRound(3).Id).toBe("DANGER_DANCE")
        expect(RoundChallenge.forRound(4).Id).toBe("MOMENTUM_3")
        expect(RoundChallenge.forRound(5).Id).toBe("FLOW_CHAIN")
        expect(RoundChallenge.forRound(6).Id).toBe("MIX_IT_UP")
        expect(RoundChallenge.forRound(7).Id).toBe("SHARD_HUNT")
    end)

    it("uses survival itself as the newcomer challenge", function()
        local first = RoundChallenge.forContext(42, true)
        expect(first.Id).toBe("FIRST_SURVIVAL")
        expect(first.Metric).toBe("survive")
        expect(first.Target).toBe(1)
        expect(RoundChallenge.progress(first, 0, 0, 0, 0, 0, false)).toBe(0)
        expect(RoundChallenge.progress(first, 0, 0, 0, 0, 0, true)).toBe(1)
        expect(RoundChallenge.completed(first, 0, 0, 0, 0, 0, true)).toBe(true)

        expect(RoundChallenge.forContext(1, false).Id).toBe("SHARD_HUNT")
    end)

    it("reads only the metric required by the challenge", function()
        local shard = RoundChallenge.Definitions[1]
        local pads = RoundChallenge.Definitions[2]
        local danger = RoundChallenge.Definitions[3]
        local momentum = RoundChallenge.Definitions[4]
        local flow = RoundChallenge.Definitions[5]
        local variety = RoundChallenge.Definitions[6]

        expect(RoundChallenge.progress(shard, 2, 99, 99, 99, 0)).toBe(2)
        expect(RoundChallenge.progress(pads, 99, 1, 99, 99, 0)).toBe(1)
        expect(RoundChallenge.progress(danger, 99, 99, 1, 99, 0)).toBe(1)
        expect(RoundChallenge.progress(momentum, 99, 99, 99, 3, 0)).toBe(3)
        expect(RoundChallenge.progress(flow, 0, 0, 0, 0, 2)).toBe(1)
        expect(RoundChallenge.progress(flow, 9, 9, 9, 9, 0)).toBe(0)
        expect(RoundChallenge.progress(variety, 1, 1, 0, 0, 0)).toBe(2)
        expect(RoundChallenge.progress(variety, 0, 0, 1, 2, 0)).toBe(2)
    end)

    it("clamps progress and reports completion", function()
        local shard = RoundChallenge.Definitions[1]
        expect(RoundChallenge.progress(shard, 999, 0, 0)).toBe(shard.Target)
        expect(RoundChallenge.completed(shard, 1, 0, 0)).toBe(false)
        expect(RoundChallenge.completed(shard, 2, 0, 0)).toBe(true)
    end)
end)

return nil
