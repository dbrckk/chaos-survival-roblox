--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local FirstTimeExperience = require("../../src/shared/FirstTimeExperience")

describe("First time experience", function()
    it("distinguishes the first round from the lightweight rookie window", function()
        expect(FirstTimeExperience.isFirstRound(0)).toBe(true)
        expect(FirstTimeExperience.isFirstRound(1)).toBe(true)
        expect(FirstTimeExperience.isFirstRound(2)).toBe(false)

        expect(FirstTimeExperience.isRookie(2)).toBe(true)
        expect(FirstTimeExperience.isRookie(3)).toBe(false)
    end)

    it("blocks double chaos while any contestant is on their first round", function()
        expect(FirstTimeExperience.allowDoubleChaos({1})).toBe(false)
        expect(FirstTimeExperience.allowDoubleChaos({20, 1, 8})).toBe(false)
        expect(FirstTimeExperience.allowDoubleChaos({2})).toBe(true)
        expect(FirstTimeExperience.allowDoubleChaos({2, 8, 20})).toBe(true)
    end)

    it("explains the core objective before the first vote", function()
        local text = FirstTimeExperience.coachText({
            phase = "intermission",
        }, {
            games = 0,
            practiceUses = 0,
        })
        expect(text).toBe("HOW TO PLAY  •  SURVIVE UNTIL 0  •  MOVE + JUMP  •  SHARDS = BONUS")

        local learned = FirstTimeExperience.coachText({
            phase = "intermission",
        }, {
            games = 0,
            practiceUses = 1,
        })
        expect(learned).toBe("ROUND GOAL  •  SURVIVE UNTIL 0  •  AVOID RED/ORANGE WARNINGS")
    end)

    it("states the survival goal clearly during the ready phase", function()
        local text = FirstTimeExperience.coachText({
            phase = "ready",
        }, {
            games = 1,
        })
        expect(text).toBe("ROUND GOAL  •  SURVIVE UNTIL 0  •  AVOID THE HAZARD  •  SHARDS = BONUS")
    end)

    it("prioritizes voting when vote options are open", function()
        local text = FirstTimeExperience.coachText({
            phase = "intermission",
            voteOptions = {{id = "Meteors"}},
        }, {
            games = 0,
            practiceUses = 0,
        })
        expect(text).toBe("VOTE  •  TAP THE CHAOS YOU WANT TO FACE")
    end)

    it("keeps the entire action phase clear of rookie coach overlays", function()
        for _, seconds in ipairs({20, 7, 1}) do
            local text = FirstTimeExperience.coachText({
                phase = "round",
                seconds = seconds,
            }, {
                games = 1,
                mechanicUses = 1,
                shards = 1,
            })
            expect(text == nil).toBe(true)
        end
    end)

    it("stops strong round coaching after the first game", function()
        local text = FirstTimeExperience.coachText({
            phase = "round",
            seconds = 20,
        }, {
            games = 2,
        })
        expect(text == nil).toBe(true)
    end)
end)

return nil
