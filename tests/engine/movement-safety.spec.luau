--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local MovementSafety = require("../../src/server/MovementSafety")

describe("Movement safety", function()
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
