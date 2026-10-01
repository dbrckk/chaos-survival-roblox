--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundCollectibles = require("../../src/server/RoundCollectibles")

describe("Round collectibles", function()
    it("keeps the shard reward cosmetic-economy only and small", function()
        expect(RoundCollectibles.reward()).toBe(1)
    end)

    it("scales active shard pressure conservatively", function()
        expect(RoundCollectibles.maxActive(1, true)).toBe(1)
        expect(RoundCollectibles.maxActive(2, false)).toBe(1)
        expect(RoundCollectibles.maxActive(4, false)).toBe(2)
        expect(RoundCollectibles.maxActive(8, false)).toBe(3)
        expect(RoundCollectibles.maxActive(30, false)).toBe(3)
    end)

    it("uses a readable cadence for a short survival round", function()
        expect(RoundCollectibles.InitialDelay >= 3).toBe(true)
        expect(RoundCollectibles.SpawnInterval >= 6).toBe(true)
    end)
end)

return nil
