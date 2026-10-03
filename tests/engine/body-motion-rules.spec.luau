--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local BodyMotionRules = require("../../src/shared/BodyMotionRules")

describe("Body motion rules", function()
    it("keeps stride off while idle or airborne", function()
        local idleWeight, idleFrequency = BodyMotionRules.stride(1, true, false)
        expect(idleWeight).toBe(0)
        expect(idleFrequency).toBe(0)

        local airWeight, airFrequency = BodyMotionRules.stride(16, false, false)
        expect(airWeight).toBe(0)
        expect(airFrequency).toBe(0)
    end)

    it("scales stride with speed and SpeedSurge", function()
        local walkWeight, walkFrequency = BodyMotionRules.stride(8, true, false)
        local runWeight, runFrequency = BodyMotionRules.stride(17, true, false)
        local surgeWeight, surgeFrequency = BodyMotionRules.stride(17, true, true)

        expect(runWeight > walkWeight).toBe(true)
        expect(runFrequency > walkFrequency).toBe(true)
        expect(surgeWeight >= runWeight).toBe(true)
        expect(surgeFrequency > runFrequency).toBe(true)
    end)

    it("only adds braking pose during meaningful deceleration", function()
        expect(BodyMotionRules.brakeWeight(120, true)).toBe(0)
        expect(BodyMotionRules.brakeWeight(-75, true) > 0).toBe(true)
        expect(BodyMotionRules.brakeWeight(-300, true)).toBe(1)
        expect(BodyMotionRules.brakeWeight(-300, false)).toBe(0)
    end)

    it("detects turn direction and severity", function()
        local rightSigned, rightSeverity = BodyMotionRules.turnResponse(
            Vector3.new(0, 0, -1),
            Vector3.new(1, 0, 0)
        )
        local leftSigned, leftSeverity = BodyMotionRules.turnResponse(
            Vector3.new(0, 0, -1),
            Vector3.new(-1, 0, 0)
        )
        local _, reverseSeverity = BodyMotionRules.turnResponse(
            Vector3.new(0, 0, -1),
            Vector3.new(0, 0, 1)
        )

        expect(rightSigned ~= 0).toBe(true)
        expect(leftSigned ~= 0).toBe(true)
        expect(rightSigned * leftSigned < 0).toBe(true)
        expect(math.abs(rightSeverity - 0.5) < 0.01).toBe(true)
        expect(math.abs(leftSeverity - 0.5) < 0.01).toBe(true)
        expect(reverseSeverity).toBe(1)
    end)

    it("uses a grounded pre-round anticipation stance without fighting movement", function()
        expect(BodyMotionRules.readyStance("waiting", true, 0)).toBe(0)
        expect(BodyMotionRules.readyStance("ready", false, 0)).toBe(0)
        expect(BodyMotionRules.readyStance("ready", true, 0)).toBe(1)
        expect(BodyMotionRules.readyStance("ready", true, 6)).toBe(0.5)
        expect(BodyMotionRules.readyStance("ready", true, 12)).toBe(0)
    end)

    it("reduces motion consistently when accessibility is enabled", function()
        expect(BodyMotionRules.motionScale(false)).toBe(1)
        expect(BodyMotionRules.motionScale(true)).toBe(0.18)
    end)
end)

return nil
