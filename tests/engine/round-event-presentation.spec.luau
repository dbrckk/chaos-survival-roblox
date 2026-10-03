--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundEventPresentation = require("../../src/shared/RoundEventPresentation")

describe("Round event presentation", function()
    it("mixes double-chaos accent colors", function()
        local colors = {
            A = Color3.fromRGB(255, 0, 0),
            B = Color3.fromRGB(0, 0, 255),
        }
        local color = RoundEventPresentation.accent({"A", "B"}, function(id)
            return colors[id]
        end)

        expect(math.abs(color.R - 0.5) < 0.01).toBe(true)
        expect(math.abs(color.B - 0.5) < 0.01).toBe(true)
    end)

    it("presents single chaos as chaos live without solo prefix", function()
        local main, sub = RoundEventPresentation.roundTitle({
            title = "SOLO RUSH: Meteor Shower",
            doubleChaos = false,
        })
        expect(main).toBe("CHAOS LIVE")
        expect(sub).toBe("Meteor Shower")
    end)

    it("presents double chaos as a fusion reveal", function()
        local main, sub = RoundEventPresentation.roundTitle({
            title = "CHAOS FUSION: Storm Core",
            doubleChaos = true,
            fusionName = "Storm Core",
        })
        expect(main).toBe("CHAOS FUSION")
        expect(sub).toBe("Storm Core")
    end)

    it("only returns ready countdown values inside the last three seconds", function()
        expect(RoundEventPresentation.countdownValue({
            phase = "ready",
            seconds = 3,
        }, "ready")).toBe(3)

        expect(RoundEventPresentation.countdownValue({
            phase = "ready",
            seconds = 1,
        }, "ready")).toBe(1)

        expect(RoundEventPresentation.countdownValue({
            phase = "ready",
            seconds = 4,
        }, "ready") == nil).toBe(true)

        expect(RoundEventPresentation.countdownValue({
            phase = "round",
            seconds = 3,
        }, "ready") == nil).toBe(true)
    end)

    it("keeps final rush above all other transition priorities", function()
        expect(
            RoundEventPresentation.priority("finalRush")
                > RoundEventPresentation.priority("roundStart")
        ).toBe(true)
        expect(
            RoundEventPresentation.priority("roundStart")
                > RoundEventPresentation.priority("fusion")
        ).toBe(true)
        expect(
            RoundEventPresentation.priority("fusion")
                > RoundEventPresentation.priority("overdrive")
        ).toBe(true)
        expect(
            RoundEventPresentation.priority("overdrive")
                > RoundEventPresentation.priority("readyCountdown")
        ).toBe(true)
    end)
end)

return nil
