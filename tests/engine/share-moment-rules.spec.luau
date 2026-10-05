--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ShareMomentRules = require("../../src/shared/ShareMomentRules")

describe("Share moment rules", function()
    it("prioritizes last survivor over other highlights", function()
        expect(ShareMomentRules.reason({
            survived = true,
            challengeCompleted = true,
            momentumBest = 5,
            doubleChaos = true,
        }, {
            phase = "result",
            survivorsAlive = 1,
        })).toBe("last_survivor")
    end)

    it("offers sharing only for meaningful successful results", function()
        expect(ShareMomentRules.reason({
            survived = true,
            challengeCompleted = true,
            momentumBest = 4,
        }, {
            phase = "result",
            survivorsAlive = 3,
        })).toBe("master")

        expect(ShareMomentRules.reason({
            survived = true,
            doubleChaos = true,
        }, {
            phase = "result",
            survivorsAlive = 2,
        })).toBe("double_chaos")

        expect(ShareMomentRules.reason({
            survived = true,
            criticalSurvival = true,
        }, {
            phase = "result",
            survivorsAlive = 2,
        })).toBe("clutch")

        expect(ShareMomentRules.reason({
            survived = true,
            crewRounds = 3,
        }, {
            phase = "result",
            survivorsAlive = 2,
        })).toBe("crew")
    end)

    it("does not interrupt ordinary results or active rounds", function()
        expect(ShareMomentRules.shouldShow({
            survived = true,
        }, {
            phase = "result",
            survivorsAlive = 4,
        }, 2)).toBe(false)

        expect(ShareMomentRules.shouldShow({
            survived = true,
            criticalSurvival = true,
        }, {
            phase = "round",
            survivorsAlive = 1,
        }, 2)).toBe(false)

        expect(ShareMomentRules.shouldShow({
            survived = false,
            doubleChaos = true,
        }, {
            phase = "result",
            survivorsAlive = 2,
        }, 2)).toBe(false)
    end)

    it("requires at least one completed game and sanitizes launch reasons", function()
        expect(ShareMomentRules.shouldShow({
            survived = true,
            criticalSurvival = true,
        }, {
            phase = "result",
            survivorsAlive = 2,
        }, 0)).toBe(false)

        expect(ShareMomentRules.launchReason("master")).toBe("master")
        expect(ShareMomentRules.launchReason("anything")).toBe("highlight")
    end)
end)

return nil
