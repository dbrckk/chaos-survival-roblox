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

return nil
