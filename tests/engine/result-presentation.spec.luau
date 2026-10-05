--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ResultPresentation = require("../../src/shared/ResultPresentation")

describe("Result presentation", function()
    it("prioritizes master over clutch", function()
        expect(ResultPresentation.kind({
            survived = true,
            criticalSurvival = true,
            challengeCompleted = true,
            momentumBest = 4,
        })).toBe("master")
    end)

    it("promotes critical survival to a distinct result", function()
        local feedback = {
            survived = true,
            criticalSurvival = true,
            challengeCompleted = false,
            momentumBest = 1,
        }
        expect(ResultPresentation.kind(feedback)).toBe("clutch")
        expect(ResultPresentation.title(feedback)).toBe("CLUTCH SURVIVAL!")
        expect(ResultPresentation.worldLabel(feedback, true)).toBe("CLUTCH SURVIVAL")
    end)

    it("keeps ordinary survival and elimination distinct", function()
        expect(ResultPresentation.kind({survived = true})).toBe("survived")
        expect(ResultPresentation.title({survived = true})).toBe("SURVIVED!")
        expect(ResultPresentation.kind({survived = false})).toBe("eliminated")
        expect(ResultPresentation.title({survived = false})).toBe("ELIMINATED")
    end)

    it("explains known elimination causes", function()
        local meteorTitle, meteorTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "Meteor",
        })
        expect(meteorTitle).toBe("HIT BY METEOR")
        expect(string.find(meteorTip, "orange warning circle", 1, true) ~= nil).toBe(true)
        expect(ResultPresentation.title({
            survived = false,
            eliminationCause = "Meteor",
        })).toBe("HIT BY METEOR")

        local platformTitle, platformTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "DisappearingPlatforms",
        })
        expect(platformTitle).toBe("PLATFORM COLLAPSED")
        expect(string.find(platformTip, "flashing platforms", 1, true) ~= nil).toBe(true)

        local shrinkTitle, shrinkTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "ShrinkingArena",
        })
        expect(shrinkTitle).toBe("CAUGHT BY THE SHRINK")
        expect(string.find(shrinkTip, "center", 1, true) ~= nil).toBe(true)

        local fallTitle, fallTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "Fall",
        })
        expect(fallTitle).toBe("FELL FROM THE ARENA")
        expect(string.find(fallTip, "shorter jumps", 1, true) ~= nil).toBe(true)
    end)

    it("falls back to useful generic elimination guidance", function()
        local title, tip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "Unknown",
        })
        expect(title).toBe("ELIMINATED")
        expect(#tip > 10).toBe(true)
    end)

    it("orders presentation intensity by result importance", function()
        local master = ResultPresentation.intensity({
            survived = true,
            challengeCompleted = true,
            momentumBest = 4,
        })
        local clutch = ResultPresentation.intensity({
            survived = true,
            criticalSurvival = true,
        })
        local survived = ResultPresentation.intensity({survived = true})
        local eliminated = ResultPresentation.intensity({survived = false})

        expect(master > clutch).toBe(true)
        expect(clutch > survived).toBe(true)
        expect(survived > eliminated).toBe(true)
    end)
end)

return nil
