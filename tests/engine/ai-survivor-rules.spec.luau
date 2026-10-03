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

    it("varies temperament between rounds while keeping identity bounded", function()
        local profile = AISurvivorRules.profileForSlot(2)
        local roundA = AISurvivorRules.roundTraits(profile, 2, 4)
        local roundB = AISurvivorRules.roundTraits(profile, 2, 5)
        local repeatA = AISurvivorRules.roundTraits(profile, 2, 4)

        expect(roundA.Risk >= 0.12 and roundA.Risk <= 0.88).toBe(true)
        expect(roundA.SocialChance >= 0.06 and roundA.SocialChance <= 0.46).toBe(true)
        expect(roundA.MistakeChance >= 0.035 and roundA.MistakeChance <= 0.27).toBe(true)
        expect(roundA.PadChance >= 0.07 and roundA.PadChance <= 0.52).toBe(true)
        expect(roundA.HesitationChance >= 0.05 and roundA.HesitationChance <= 0.18).toBe(true)
        expect(roundA.ReconsiderChance >= 0.05 and roundA.ReconsiderChance <= 0.13).toBe(true)
        expect(roundA.FollowThrough >= 0.92 and roundA.FollowThrough <= 1.12).toBe(true)
        expect(roundA.DirectionBias >= -1 and roundA.DirectionBias <= 1).toBe(true)

        expect(roundA.Risk).toBe(repeatA.Risk)
        expect(roundA.SocialChance).toBe(repeatA.SocialChance)
        expect(
            roundA.Risk ~= roundB.Risk
            or roundA.SocialChance ~= roundB.SocialChance
            or roundA.DirectionBias ~= roundB.DirectionBias
        ).toBe(true)
    end)

    it("reduces optional jumps under pressure without disabling them", function()
        local calm = AISurvivorRules.freeJumpChance(0.20, 0, false)
        local pressured = AISurvivorRules.freeJumpChance(0.20, 0.8, false)
        local lowGravity = AISurvivorRules.freeJumpChance(0.20, 0, true)
        local pressuredLowGravity = AISurvivorRules.freeJumpChance(0.20, 0.8, true)

        expect(calm).toBe(0.20)
        expect(pressured < calm).toBe(true)
        expect(pressured >= 0.04).toBe(true)
        expect(lowGravity > calm).toBe(true)
        expect(pressuredLowGravity < lowGravity).toBe(true)
    end)

    it("smooths ordinary steering but keeps urgent steering direct", function()
        local previous = Vector3.new(1, 0, 0)
        local desired = Vector3.new(0, 0, 1)

        local smooth = AISurvivorRules.steeredDirection(previous, desired, false)
        local urgent = AISurvivorRules.steeredDirection(previous, desired, true)

        expect(smooth.X > 0).toBe(true)
        expect(smooth.Z > 0).toBe(true)
        expect((urgent - desired.Unit).Magnitude < 0.001).toBe(true)
    end)

    it("only inserts a turn pause for sharp non-urgent reversals", function()
        local forward = Vector3.new(0, 0, -1)
        local reverse = Vector3.new(0, 0, 1)
        local side = Vector3.new(1, 0, 0)

        local reversalPause = AISurvivorRules.turnPauseSeconds(
            forward,
            reverse,
            false,
            0
        )
        expect(reversalPause > 0).toBe(true)
        expect(
            AISurvivorRules.turnPauseSeconds(forward, reverse, true, 0)
        ).toBe(0)
        expect(
            AISurvivorRules.turnPauseSeconds(forward, side, false, 0)
        ).toBe(0)

        local pressuredPause = AISurvivorRules.turnPauseSeconds(
            forward,
            reverse,
            false,
            0.8
        )
        expect(pressuredPause < reversalPause).toBe(true)
    end)

    it("narrows route and pad choice width as risk falls", function()
        expect(AISurvivorRules.routeChoiceWidth(0.20, 8)).toBe(1)
        expect(AISurvivorRules.routeChoiceWidth(0.50, 8)).toBe(2)
        expect(AISurvivorRules.routeChoiceWidth(0.80, 8)).toBe(3)
        expect(AISurvivorRules.routeChoiceWidth(0.80, 2)).toBe(2)

        expect(AISurvivorRules.padChoiceWidth(0.40, 4)).toBe(1)
        expect(AISurvivorRules.padChoiceWidth(0.75, 4)).toBe(2)
        expect(AISurvivorRules.padChoiceWidth(0.75, 1)).toBe(1)
    end)

    it("increases bounded survival pressure as health and round danger worsen", function()
        local healthy = AISurvivorRules.survivalPressure(100, 100, false, false)
        local wounded = AISurvivorRules.survivalPressure(45, 100, false, false)
        local critical = AISurvivorRules.survivalPressure(20, 100, true, true)

        expect(healthy).toBe(0)
        expect(wounded > healthy).toBe(true)
        expect(critical > wounded).toBe(true)
        expect(critical <= 0.82).toBe(true)
    end)

    it("becomes more cautious under pressure without becoming perfect", function()
        local base = {
            Risk = 0.60,
            SocialChance = 0.30,
            MistakeChance = 0.16,
            PadChance = 0.25,
            HesitationChance = 0.10,
            ReconsiderChance = 0.08,
            FollowThrough = 1.0,
            DirectionBias = 0.4,
        }

        local calm = AISurvivorRules.pressuredTraits(base, 0)
        local pressured = AISurvivorRules.pressuredTraits(base, 0.8)

        expect(calm.Risk).toBe(base.Risk)
        expect(pressured.Risk < calm.Risk).toBe(true)
        expect(pressured.SocialChance < calm.SocialChance).toBe(true)
        expect(pressured.MistakeChance < calm.MistakeChance).toBe(true)
        expect(pressured.MistakeChance >= 0.03).toBe(true)
        expect(pressured.PadChance > calm.PadChance).toBe(true)
        expect(pressured.HesitationChance < calm.HesitationChance).toBe(true)
        expect(pressured.ReconsiderChance > calm.ReconsiderChance).toBe(true)
        expect(pressured.DirectionBias).toBe(base.DirectionBias)
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
