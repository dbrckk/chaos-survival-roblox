--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local MovementAssistRules = require("../../src/shared/MovementAssistRules")

describe("Movement assist rules", function()
    it("allows a short coyote jump after leaving the floor", function()
        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.05,
            Enum.HumanoidStateType.Freefall,
            true
        )).toBe(true)

        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.15,
            Enum.HumanoidStateType.Freefall,
            true
        )).toBe(false)
    end)

    it("does not turn a normal jump into a double jump", function()
        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.04,
            Enum.HumanoidStateType.Jumping,
            true
        )).toBe(false)
    end)

    it("never adds a second jump while already grounded", function()
        expect(MovementAssistRules.canCoyoteJump(
            true,
            0,
            Enum.HumanoidStateType.Running,
            true
        )).toBe(false)
    end)

    it("respects disabled or blocked jump states", function()
        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.04,
            Enum.HumanoidStateType.Seated,
            true
        )).toBe(false)

        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.04,
            Enum.HumanoidStateType.Freefall,
            false
        )).toBe(false)
    end)

    it("respects the active Roblox jump mode and Freeze Pulse disable", function()
        local enabled = MovementAssistRules.jumpEnabled
        expect(enabled(100, true, 50, 0, true)).toBe(true)
        expect(enabled(100, false, 0, 7.2, true)).toBe(true)
        -- The inactive control can remain at its previous nonzero default.
        expect(enabled(100, true, 0, 7.2, true)).toBe(false)
        expect(enabled(100, false, 50, 0, true)).toBe(false)
        expect(enabled(100, true, 50, 7.2, false)).toBe(false)
        expect(enabled(0, true, 50, 7.2, true)).toBe(false)
        expect(enabled(100, true, math.huge, 7.2, true)).toBe(false)
        expect(enabled(100, false, 50, 0 / 0, true)).toBe(false)
    end)

    it("keeps the buffered jump window short and deterministic", function()
        local expires = MovementAssistRules.bufferUntil(10)
        expect(math.abs(expires - 10.12) < 0.001).toBe(true)
        expect(MovementAssistRules.bufferActive(10.08, expires)).toBe(true)
        expect(MovementAssistRules.bufferActive(10.13, expires)).toBe(false)
    end)
end)

return nil
