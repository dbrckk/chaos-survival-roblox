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
            momentumBest = 4,
            criticalSurvival = true,
        })

        expect(#medals).toBe(6)
        expect(medals[1]).toBe("SHARD HUNTER")
        expect(medals[2]).toBe("MOBILITY ACE")
        expect(medals[3]).toBe("DAREDEVIL")
        expect(medals[4]).toBe("OVERDRIVE RIDER")
        expect(medals[5]).toBe("MOMENTUM MASTER")
        expect(medals[6]).toBe("CLUTCH")
    end)

    it("guarantees a first chaos medal on the first completed round", function()
        local medals = RoundMedals.evaluate({
            firstRound = true,
        })
        expect(#medals).toBe(1)
        expect(medals[1]).toBe("FIRST CHAOS")
    end)

    it("awards both skill medals only for server-verified parkour chains", function()
        local ace = RoundMedals.evaluate({parkourBest = 3})
        expect(#ace).toBe(1)
        expect(ace[1]).toBe("PARKOUR ACE")
        local legend = RoundMedals.evaluate({parkourBest = 7})
        expect(#legend).toBe(2)
        expect(legend[1]).toBe("PARKOUR ACE")
        expect(legend[2]).toBe("RIDGE LEGEND")
        expect(#RoundMedals.evaluate({parkourBest = 2})).toBe(0)
    end)

    it("does not award medals below thresholds", function()
        local medals = RoundMedals.evaluate({
            shards = 2,
            pads = 2,
            nearMisses = 2,
            overdriveUses = 0,
            momentumBest = 3,
            criticalSurvival = false,
        })
        expect(#medals).toBe(0)
    end)
end)

return nil
