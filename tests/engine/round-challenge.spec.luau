--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundChallenge = require("../../src/server/RoundChallenge")

describe("Round challenge", function()
    it("rotates deterministic challenge types across rounds", function()
        expect(RoundChallenge.forRound(1).Id).toBe("SHARD_HUNT")
        expect(RoundChallenge.forRound(2).Id).toBe("MOBILITY_MASTER")
        expect(RoundChallenge.forRound(3).Id).toBe("DANGER_DANCE")
        expect(RoundChallenge.forRound(4).Id).toBe("SHARD_HUNT")
    end)

    it("reads only the metric required by the challenge", function()
        local shard = RoundChallenge.Definitions[1]
        local pads = RoundChallenge.Definitions[2]
        local danger = RoundChallenge.Definitions[3]

        expect(RoundChallenge.progress(shard, 2, 99, 99)).toBe(2)
        expect(RoundChallenge.progress(pads, 99, 1, 99)).toBe(1)
        expect(RoundChallenge.progress(danger, 99, 99, 1)).toBe(1)
    end)

    it("clamps progress and reports completion", function()
        local shard = RoundChallenge.Definitions[1]
        expect(RoundChallenge.progress(shard, 999, 0, 0)).toBe(shard.Target)
        expect(RoundChallenge.completed(shard, 1, 0, 0)).toBe(false)
        expect(RoundChallenge.completed(shard, 2, 0, 0)).toBe(true)
    end)
end)

return nil
