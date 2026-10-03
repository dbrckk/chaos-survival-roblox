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
