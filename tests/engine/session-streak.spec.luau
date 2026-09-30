--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local SessionStreak = require("../../src/server/SessionStreak")

describe("Session survival streak", function()
    it("increments consecutive survivals", function()
        local current, best = SessionStreak.update(0, 0, true)
        expect(current).toBe(1)
        expect(best).toBe(1)

        current, best = SessionStreak.update(current, best, true)
        expect(current).toBe(2)
        expect(best).toBe(2)
    end)

    it("resets current streak after elimination but preserves best", function()
        local current, best = SessionStreak.update(4, 4, false)
        expect(current).toBe(0)
        expect(best).toBe(4)
    end)

    it("does not reduce an existing best streak", function()
        local current, best = SessionStreak.update(1, 6, true)
        expect(current).toBe(2)
        expect(best).toBe(6)
    end)
end)

describe("Session streak rewards", function()
    it("starts rewards on the second consecutive survival", function()
        expect(SessionStreak.bonusCoins(0)).toBe(0)
        expect(SessionStreak.bonusCoins(1)).toBe(0)
        expect(SessionStreak.bonusCoins(2)).toBe(2)
        expect(SessionStreak.bonusCoins(3)).toBe(4)
    end)

    it("caps streak bonus to protect the economy", function()
        expect(SessionStreak.bonusCoins(6)).toBe(10)
        expect(SessionStreak.bonusCoins(20)).toBe(10)
    end)
end)

return nil
