--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local SurvivalFeedback = require("../../src/server/SurvivalFeedback")

describe("Survival feedback", function()
    it("marks living players at or below twenty percent health as critical", function()
        expect(SurvivalFeedback.isCriticalHealth(20, 100)).toBe(true)
        expect(SurvivalFeedback.isCriticalHealth(1, 100)).toBe(true)
        expect(SurvivalFeedback.isCriticalHealth(20.1, 100)).toBe(false)
    end)

    it("does not mark invalid or dead health states as critical", function()
        expect(SurvivalFeedback.isCriticalHealth(0, 100)).toBe(false)
        expect(SurvivalFeedback.isCriticalHealth(10, 0)).toBe(false)
        expect(SurvivalFeedback.isCriticalHealth(-5, 100)).toBe(false)
    end)
end)

return nil
