--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DailyRewards = require("../../src/server/DailyRewards")

describe("Daily rewards", function()
    it("starts a new streak at day one", function()
        local claim = DailyRewards.compute(-1, 100, 0)
        expect(claim ~= nil).toBe(true)
        expect((claim :: any).Streak).toBe(1)
        expect((claim :: any).Coins).toBe(25)
        expect((claim :: any).XP).toBe(15)
    end)

    it("does not allow two claims on the same UTC day", function()
        local claim = DailyRewards.compute(100, 100, 3)
        expect(claim == nil).toBe(true)
    end)

    it("increments a consecutive streak", function()
        local claim = DailyRewards.compute(100, 101, 3)
        expect((claim :: any).Streak).toBe(4)
        expect((claim :: any).RewardIndex).toBe(4)
    end)

    it("resets after a missed day", function()
        local claim = DailyRewards.compute(100, 103, 6)
        expect((claim :: any).Streak).toBe(1)
        expect((claim :: any).RewardIndex).toBe(1)
    end)

    it("cycles the seven-day reward table without resetting the streak", function()
        local claim = DailyRewards.compute(106, 107, 7)
        expect((claim :: any).Streak).toBe(8)
        expect((claim :: any).RewardIndex).toBe(1)
    end)
end)

return nil
