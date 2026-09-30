--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Achievements = require("../../src/server/Achievements")

describe("Achievements", function()
    it("unlocks first survival exactly once", function()
        local serialized, unlocked = Achievements.evaluate({
            Wins = 1,
            Games = 1,
            Level = 1,
            BestStreak = 1,
            DoubleChaosSurvivals = 0,
        }, "")

        expect(#unlocked).toBe(1)
        expect(unlocked[1]).toBe("FIRST_SURVIVOR")
        expect(Achievements.deserialize(serialized).FIRST_SURVIVOR).toBe(true)

        local secondSerialized, secondUnlocked = Achievements.evaluate({
            Wins = 2,
            Games = 2,
            Level = 1,
            BestStreak = 1,
            DoubleChaosSurvivals = 0,
        }, serialized)

        expect(secondSerialized).toBe(serialized)
        expect(#secondUnlocked).toBe(0)
    end)

    it("can unlock several milestones in one evaluation", function()
        local serialized, unlocked = Achievements.evaluate({
            Wins = 10,
            Games = 10,
            Level = 5,
            BestStreak = 7,
            DoubleChaosSurvivals = 3,
        }, "")

        expect(#unlocked).toBe(6)
        local owned = Achievements.deserialize(serialized)
        expect(owned.FIRST_SURVIVOR).toBe(true)
        expect(owned.VETERAN_10).toBe(true)
        expect(owned.SURVIVOR_10).toBe(true)
        expect(owned.CHAOS_TAMER).toBe(true)
        expect(owned.LEVEL_5).toBe(true)
        expect(owned.STREAK_7).toBe(true)
    end)

    it("reports capped public progress", function()
        local state = Achievements.publicState({
            Wins = 99,
            Games = 3,
            Level = 2,
            BestStreak = 1,
            DoubleChaosSurvivals = 0,
        }, "FIRST_SURVIVOR")

        local first = state.achievements[1]
        expect(first.progress).toBe(1)
        expect(first.target).toBe(1)
        expect(first.unlocked).toBe(true)

        local games = state.achievements[2]
        expect(games.progress).toBe(3)
        expect(games.target).toBe(10)
        expect(games.unlocked).toBe(false)
    end)

    it("serializes achievements in stable order", function()
        local raw = Achievements.serialize({
            STREAK_7 = true,
            FIRST_SURVIVOR = true,
            LEVEL_5 = true,
        })

        expect(raw).toBe("FIRST_SURVIVOR,LEVEL_5,STREAK_7")
    end)
end)

return nil
