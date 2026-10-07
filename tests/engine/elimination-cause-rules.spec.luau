--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local EliminationCauseRules = require("../../src/server/EliminationCauseRules")

describe("Elimination cause rules", function()
    it("accepts only recent real hazard contacts", function()
        expect(EliminationCauseRules.recentHazardKind({
            kind = "Tornado",
            at = 10,
        }, 12, 2.25)).toBe("Tornado")

        expect(EliminationCauseRules.recentHazardKind({
            kind = "JumpShock",
            at = 10,
        }, 12.26, 2.25)).toBe(nil)

        expect(EliminationCauseRules.recentHazardKind({
            kind = "Tornado",
            at = 13,
        }, 12, 2.25)).toBe(nil)
    end)

    it("does not credit impulse hazards merely because they are active", function()
        expect(EliminationCauseRules.fallbackFallCause({
            Tornado = true,
        })).toBe("Fall")

        expect(EliminationCauseRules.fallbackFallCause({
            JumpShock = true,
        })).toBe("Fall")

        expect(EliminationCauseRules.fallbackFallCause({
            Tornado = true,
            JumpShock = true,
        })).toBe("Fall")
    end)

    it("keeps structural and continuous fall fallbacks", function()
        expect(EliminationCauseRules.fallbackFallCause({
            LowGravity = true,
        })).toBe("LowGravity")

        expect(EliminationCauseRules.fallbackFallCause({
            DisappearingPlatforms = true,
        })).toBe("DisappearingPlatforms")

        expect(EliminationCauseRules.fallbackFallCause({
            ShrinkingArena = true,
        })).toBe("ShrinkingArena")

        expect(EliminationCauseRules.fallbackFallCause({})).toBe("Fall")
    end)
end)

return nil
