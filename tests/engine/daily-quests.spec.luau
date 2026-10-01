--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DailyQuests = require("../../src/server/DailyQuests")

describe("Daily quests", function()
    it("selects exactly three deterministic quests for a day", function()
        local a = DailyQuests.selectForDay(12345, 3)
        local b = DailyQuests.selectForDay(12345, 3)

        expect(#a).toBe(3)
        expect(a[1]).toBe(b[1])
        expect(a[2]).toBe(b[2])
        expect(a[3]).toBe(b[3])
        expect(a[1] ~= a[2]).toBe(true)
        expect(a[2] ~= a[3]).toBe(true)
    end)

    it("advances only quests matching the event", function()
        local progress, completed = DailyQuests.applyProgress("PLAY_3", 0, "survive_round", 1)
        expect(progress).toBe(0)
        expect(completed).toBe(false)

        progress, completed = DailyQuests.applyProgress("PLAY_3", 0, "play_round", 1)
        expect(progress).toBe(1)
        expect(completed).toBe(false)
    end)

    it("caps progress at the target and completes once", function()
        local progress, completed = DailyQuests.applyProgress("PLAY_3", 2, "play_round", 1)
        expect(progress).toBe(3)
        expect(completed).toBe(true)

        local secondProgress, secondCompleted = DailyQuests.applyProgress("PLAY_3", progress, "play_round", 1)
        expect(secondProgress).toBe(3)
        expect(secondCompleted).toBe(false)
    end)

    it("handles coin progress in batches", function()
        local progress, completed = DailyQuests.applyProgress("EARN_75", 50, "coins_earned", 25)
        expect(progress).toBe(75)
        expect(completed).toBe(true)
    end)

    it("tracks chaos shard collection independently", function()
        local progress, completed = DailyQuests.applyProgress("COLLECT_6", 5, "collect_shard", 1)
        expect(progress).toBe(6)
        expect(completed).toBe(true)

        local unrelated, unrelatedCompleted = DailyQuests.applyProgress("COLLECT_6", 0, "survive_round", 1)
        expect(unrelated).toBe(0)
        expect(unrelatedCompleted).toBe(false)
    end)
end)

return nil
