--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local MovementSafety = require("../../src/server/MovementSafety")
local PhaseDashRules = require("../../src/shared/PhaseDashRules")

describe("Movement safety", function()
    it("gives every active survivor one free bounded Phase Dash", function()
        local rules = PhaseDashRules
        expect(rules.canActivate("round", true, false, 100, true, 10, 9)).toBe(true)
        expect(rules.canActivate("round", true, false, 100, true, 10, 10)).toBe(true)
        expect(rules.canActivate("round", true, false, 100, true, 10, 11)).toBe(false)
        expect(rules.canActivate("ready", true, false, 100, true, 10, 0)).toBe(false)
        expect(rules.canActivate("result", true, false, 100, true, 10, 0)).toBe(false)
        expect(rules.canActivate("round", false, false, 100, true, 10, 0)).toBe(false)
        expect(rules.canActivate("round", true, true, 100, true, 10, 0)).toBe(false)
        expect(rules.canActivate("round", true, false, 0, true, 10, 0)).toBe(false)
        expect(rules.canActivate("round", true, false, 100, false, 10, 0)).toBe(false)
        expect(rules.nextReadyAt(10)).toBe(10 + rules.Cooldown)
        expect(rules.Cooldown >= 7).toBe(true)
    end)

    it("limits Phase Dash movement and never trusts arbitrary client vectors", function()
        local rules = PhaseDashRules
        local direction = rules.direction(
            Vector3.new(2, 5, 0), Vector3.new(0, 0, -1)
        )
        expect(math.abs(direction.Magnitude - 1) < 0.001).toBe(true)
        expect(direction.Y).toBe(0)

        local idle = rules.direction(Vector3.zero, Vector3.new(1, 0, 0))
        expect(idle).toBe(Vector3.new(1, 0, 0))

        for _, initial in ipairs({
            Vector3.zero,
            Vector3.new(85, 120, 85),
            Vector3.new(-95, -180, 20),
        }) do
            local result = rules.velocity(initial, Vector3.new(5, 0, -2), Vector3.zero)
            expect(Vector3.new(result.X, 0, result.Z).Magnitude
                <= rules.MaxHorizontalSpeed + 0.001).toBe(true)
            expect(result.Y >= -52 and result.Y <= 48).toBe(true)
        end

        local boosted = rules.velocity(Vector3.zero, Vector3.new(1, 0, 0), nil)
        expect(boosted.X > 25).toBe(true)
        expect(boosted.Y >= 2).toBe(true)
    end)

    it("bounds horizontal disaster velocity", function()
        local velocity = MovementSafety.addImpulse(
            Vector3.new(90, 0, -90),
            Vector3.new(30, 0, 30),
            62,
            -55,
            58
        )

        local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
        expect(horizontal.Magnitude <= 62.001).toBe(true)
    end)

    it("bounds vertical disaster velocity in both directions", function()
        local upward = MovementSafety.addImpulse(
            Vector3.new(0, 55, 0),
            Vector3.new(0, 30, 0),
            62,
            -55,
            58
        )
        expect(upward.Y).toBe(58)

        local downward = MovementSafety.addImpulse(
            Vector3.new(0, -50, 0),
            Vector3.new(0, -30, 0),
            62,
            -55,
            58
        )
        expect(downward.Y).toBe(-55)
    end)

    it("handles inverted vertical bounds defensively", function()
        local velocity = MovementSafety.clampVelocity(
            Vector3.new(0, 100, 0),
            62,
            58,
            -55
        )
        expect(velocity.Y).toBe(58)
    end)
end)

return nil
