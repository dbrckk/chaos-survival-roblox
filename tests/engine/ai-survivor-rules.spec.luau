--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AISurvivorRules = require("../../src/server/AISurvivorRules")

describe("AI survivor rules", function()
    it("fills a small server toward four visible participants", function()
        expect(AISurvivorRules.desiredBotCount(0)).toBe(0)
        expect(AISurvivorRules.desiredBotCount(1)).toBe(3)
        expect(AISurvivorRules.desiredBotCount(2)).toBe(2)
        expect(AISurvivorRules.desiredBotCount(3)).toBe(1)
        expect(AISurvivorRules.desiredBotCount(4)).toBe(0)
        expect(AISurvivorRules.desiredBotCount(9)).toBe(0)
    end)

    it("rotates distinct behavior profiles", function()
        expect(AISurvivorRules.profileForSlot(1).Id).toBe("Cautious")
        expect(AISurvivorRules.profileForSlot(2).Id).toBe("Balanced")
        expect(AISurvivorRules.profileForSlot(3).Id).toBe("Bold")
        expect(AISurvivorRules.profileForSlot(4).Id).toBe("Cautious")
    end)

    it("keeps human-like behavior traits bounded and varied", function()
        local cautious = AISurvivorRules.profileForSlot(1)
        local balanced = AISurvivorRules.profileForSlot(2)
        local bold = AISurvivorRules.profileForSlot(3)

        for _, profile in ipairs({cautious, balanced, bold}) do
            expect(profile.MistakeChance >= 0 and profile.MistakeChance <= 0.30).toBe(true)
            expect(profile.SocialChance >= 0 and profile.SocialChance <= 0.40).toBe(true)
        end

        expect(cautious.MistakeChance < bold.MistakeChance).toBe(true)
        expect(cautious.SocialChance < bold.SocialChance).toBe(true)
    end)

    it("uses mobility pads more often when arena topology calls for them", function()
        local base = 0.20

        expect(AISurvivorRules.padInterest(base, "Classic", true, false)).toBe(base)
        expect(AISurvivorRules.padInterest(base, "Towers", true, false) > base).toBe(true)
        expect(AISurvivorRules.padInterest(base, "Towers", false, false)).toBe(base)
        expect(AISurvivorRules.padInterest(base, "Orbital", false, false) > base).toBe(true)
        expect(AISurvivorRules.padInterest(base, "Crossroads", false, false) > base).toBe(true)
        expect(AISurvivorRules.padInterest(base, "Classic", false, true) > base).toBe(true)
        expect(AISurvivorRules.padInterest(0.70, "Towers", true, true)).toBe(0.72)
    end)

    it("rejects unreachable vertical targets without a pad route", function()
        expect(AISurvivorRules.reachableElevation(3, 10, "Classic")).toBe(true)
        expect(AISurvivorRules.reachableElevation(3, 11, "Classic")).toBe(false)
        expect(AISurvivorRules.reachableElevation(3, 11.4, "Towers")).toBe(true)
        expect(AISurvivorRules.reachableElevation(3, 12, "Towers")).toBe(false)
        expect(AISurvivorRules.reachableElevation(12, 6, "Towers")).toBe(true)
    end)

    it("preserves plausible route continuity per arena", function()
        local center = Vector3.zero

        expect(
            AISurvivorRules.routeContinuity(
                "Orbital",
                Vector3.new(29, 0, 0),
                Vector3.new(29, 0, 12),
                center,
                0.2
            ) > 0
        ).toBe(true)
        expect(
            AISurvivorRules.routeContinuity(
                "Orbital",
                Vector3.new(29, 0, 0),
                Vector3.new(29, 0, -12),
                center,
                0.2
            ) < 0
        ).toBe(true)

        expect(
            AISurvivorRules.routeContinuity(
                "Towers",
                Vector3.new(28, 0, 28),
                Vector3.new(25, 8, 25),
                center,
                0
            ) > AISurvivorRules.routeContinuity(
                "Towers",
                Vector3.new(28, 0, 28),
                Vector3.new(-25, 8, -25),
                center,
                0
            )
        ).toBe(true)

        expect(
            AISurvivorRules.routeContinuity(
                "Crossroads",
                Vector3.new(24, 0, 2),
                Vector3.new(-20, 0, 1),
                center,
                0
            ) > AISurvivorRules.routeContinuity(
                "Crossroads",
                Vector3.new(24, 0, 2),
                Vector3.new(20, 0, 20),
                center,
                0
            )
        ).toBe(true)
    end)

    it("gives each arena a distinct route affinity", function()
        local center = Vector3.zero

        expect(
            AISurvivorRules.routeAffinity("Orbital", Vector3.new(29, 0, 0), center)
            > AISurvivorRules.routeAffinity("Orbital", Vector3.zero, center)
        ).toBe(true)

        expect(
            AISurvivorRules.routeAffinity("Crossroads", Vector3.new(30, 0, 0), center)
            > AISurvivorRules.routeAffinity("Crossroads", Vector3.new(20, 0, 20), center)
        ).toBe(true)

        expect(
            AISurvivorRules.routeAffinity("Towers", Vector3.new(28, 0, 28), center)
            > AISurvivorRules.routeAffinity("Towers", Vector3.new(28, 0, 0), center)
        ).toBe(true)

        expect(
            AISurvivorRules.routeAffinity("Classic", Vector3.new(24, 0, 0), center)
            > AISurvivorRules.routeAffinity("Classic", Vector3.zero, center)
        ).toBe(true)
    end)

    it("rejects collapsing or non-solid platform targets", function()
        expect(AISurvivorRules.platformAvailable(true, 0, nil)).toBe(true)
        expect(AISurvivorRules.platformAvailable(true, 0.2, "Warning")).toBe(false)
        expect(AISurvivorRules.platformAvailable(true, 1, "Gone")).toBe(false)
        expect(AISurvivorRules.platformAvailable(false, 0, nil)).toBe(false)
        expect(AISurvivorRules.platformAvailable(true, 0.95, nil)).toBe(false)
    end)

    it("delays reactions instead of granting perfect reflexes", function()
        expect(AISurvivorRules.reactionReady(10, 10.19, 0.20)).toBe(false)
        expect(AISurvivorRules.reactionReady(10, 10.20, 0.20)).toBe(true)
        expect(AISurvivorRules.reactionReady(10, 10.50, 0.34)).toBe(true)
    end)

    it("produces stable vote choices inside the available range", function()
        local index = AISurvivorRules.voteIndex(3, 3, 7)
        expect(index >= 1).toBe(true)
        expect(index <= 3).toBe(true)
        expect(AISurvivorRules.voteIndex(3, 3, 7)).toBe(index)
    end)
end)

return nil
