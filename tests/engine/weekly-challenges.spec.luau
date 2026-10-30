--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local WeeklyChallenges = require("../../src/server/WeeklyChallenges")

describe("Weekly challenges", function()
    it("selects two deterministic challenges per week", function()
        local a = WeeklyChallenges.selectForWeek(2800, 2)
        local b = WeeklyChallenges.selectForWeek(2800, 2)

        expect(#a).toBe(2)
        expect(a[1]).toBe(b[1])
        expect(a[2]).toBe(b[2])
        expect(a[1] ~= a[2]).toBe(true)
    end)

    it("changes selection across weeks", function()
        local a = WeeklyChallenges.selectForWeek(2800, 2)
        local b = WeeklyChallenges.selectForWeek(2801, 2)
        expect(a[1] ~= b[1] or a[2] ~= b[2]).toBe(true)
    end)

    it("advances only matching events", function()
        local progress, completed = WeeklyChallenges.applyProgress(
            "PLAY_20",
            4,
            "survive_round",
            1
        )
        expect(progress).toBe(4)
        expect(completed).toBe(false)

        progress, completed = WeeklyChallenges.applyProgress(
            "PLAY_20",
            19,
            "play_round",
            1
        )
        expect(progress).toBe(20)
        expect(completed).toBe(true)
    end)

    it("caps batch progress and completes once", function()
        local progress, completed = WeeklyChallenges.applyProgress(
            "EARN_500",
            470,
            "coins_earned",
            80
        )
        expect(progress).toBe(500)
        expect(completed).toBe(true)

        local secondProgress, secondCompleted = WeeklyChallenges.applyProgress(
            "EARN_500",
            progress,
            "coins_earned",
            80
        )
        expect(secondProgress).toBe(500)
        expect(secondCompleted).toBe(false)
    end)

    it("rewards eight verified three-jump rounds, never mere participation", function()
        local id = "PARKOUR_8"
        local def = WeeklyChallenges.definition(id)
        expect(def.Event).toBe("parkour_ace")
        expect(def.Target).toBe(8)
        local noProgress, noReward = WeeklyChallenges.applyProgress(
            id, 7, "play_round", 20
        )
        expect(noProgress).toBe(7)
        expect(noReward).toBe(false)
        local completed, claim = WeeklyChallenges.applyProgress(
            id, 7, "parkour_ace", 1
        )
        expect(completed).toBe(8)
        expect(claim).toBe(true)
        local capped, duplicate = WeeklyChallenges.applyProgress(
            id, completed, "parkour_ace", 9
        )
        expect(capped).toBe(8)
        expect(duplicate).toBe(false)
    end)

    it("uses a stable seven day bucket", function()
        expect(WeeklyChallenges.weekNumber(0)).toBe(0)
        expect(WeeklyChallenges.weekNumber(604799)).toBe(0)
        expect(WeeklyChallenges.weekNumber(604800)).toBe(1)
    end)
end)

return nil
