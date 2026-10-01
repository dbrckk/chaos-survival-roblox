--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterImpact = require("../../src/server/DisasterImpact")

describe("Disaster impact", function()
    it("deals maximum damage at the impact center", function()
        expect(DisasterImpact.damageForDistance(0, 8, 50)).toBe(50)
    end)

    it("falls off toward the edge without becoming zero inside the radius", function()
        local middle = DisasterImpact.damageForDistance(4, 8, 50)
        local edge = DisasterImpact.damageForDistance(8, 8, 50)

        expect(middle < 50).toBe(true)
        expect(middle > edge).toBe(true)
        expect(edge).toBe(18)
    end)

    it("deals no damage outside the configured radius", function()
        expect(DisasterImpact.damageForDistance(8.01, 8, 50)).toBe(0)
        expect(DisasterImpact.damageForDistance(100, 8, 50)).toBe(0)
    end)

    it("detects only close misses just outside the damage radius", function()
        expect(DisasterImpact.nearMissForDistance(8.1, 8, 3.5)).toBe(true)
        expect(DisasterImpact.nearMissForDistance(11.5, 8, 3.5)).toBe(true)
        expect(DisasterImpact.nearMissForDistance(8, 8, 3.5)).toBe(false)
        expect(DisasterImpact.nearMissForDistance(11.6, 8, 3.5)).toBe(false)
    end)

    it("sanitizes negative distance and damage inputs", function()
        expect(DisasterImpact.damageForDistance(-5, 8, 50)).toBe(50)
        expect(DisasterImpact.damageForDistance(0, 8, -10)).toBe(0)
    end)
end)

return nil
