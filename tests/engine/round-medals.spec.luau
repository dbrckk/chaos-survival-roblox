--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundMedals = require("../../src/server/RoundMedals")

describe("Round medals", function()
    it("awards style medals from round actions", function()
        local medals = RoundMedals.evaluate({
            shards = 3,
            pads = 3,
            nearMisses = 3,
            overdriveUses = 1,
            criticalSurvival = true,
        })

        expect(#medals).toBe(5)
        expect(medals[1]).toBe("SHARD HUNTER")
        expect(medals[2]).toBe("MOBILITY ACE")
        expect(medals[3]).toBe("DAREDEVIL")
        expect(medals[4]).toBe("OVERDRIVE RIDER")
        expect(medals[5]).toBe("CLUTCH")
    end)

    it("does not award medals below thresholds", function()
        local medals = RoundMedals.evaluate({
            shards = 2,
            pads = 2,
            nearMisses = 2,
            overdriveUses = 0,
            criticalSurvival = false,
        })
        expect(#medals).toBe(0)
    end)
end)

return nil
