--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local BodyMotionRules = require("../../src/shared/BodyMotionRules")
local LocomotionDynamics = require("../../src/shared/LocomotionDynamics")

describe("Body motion rules", function()
    it("differentiates starting sprint and braking with released input", function()
        local launch, noBrake = LocomotionDynamics.acceleration(12, 2, 0.10, true)
        local noLaunch, braking = LocomotionDynamics.acceleration(8, 20, 0.10, true)
        expect(launch > 0).toBe(true)
        expect(noBrake).toBe(0)
        expect(noLaunch).toBe(0)
        expect(braking > 0).toBe(true)
        local airborneLaunch, airborneBrake = LocomotionDynamics.acceleration(4, 20, 0.10, false)
        expect(airborneLaunch).toBe(0)
        expect(airborneBrake).toBe(0)
        local invalidLaunch, invalidBrake = LocomotionDynamics.acceleration(10, 0, 0, true)
        expect(invalidLaunch).toBe(0)
        expect(invalidBrake).toBe(0)
    end)

    it("stays responsive to sharp corner cuts and 180-degree turnarounds", function()
        local sign, weight = LocomotionDynamics.cut(
            Vector3.new(0, 0, -1), Vector3.new(1, 0, 0), 18, true
        )
        expect(math.abs(sign) > 0.3).toBe(true)
        expect(weight > 0.3 and weight < 0.8).toBe(true)
        local reverse, reverseWeight = LocomotionDynamics.cut(
            Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), 18, true
        )
        expect(math.abs(reverse) > 0.9).toBe(true)
        expect(reverseWeight).toBe(1)
        local idle, idleWeight = LocomotionDynamics.cut(
            Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), 0, true
        )
        expect(idle).toBe(0)
        expect(idleWeight).toBe(0)
        local air, _ = LocomotionDynamics.cut(
            Vector3.new(0, 0, -1), Vector3.new(0, 0, 1), 18, false
        )
        expect(air).toBe(0)
    end)

    it("adds planted footsteps and safe airborne reach without forcing physics", function()
        expect(LocomotionDynamics.footPlant(0, 1, true)).toBe(1)
        expect(LocomotionDynamics.footPlant(math.pi / 2, 1, true)).toBe(0)
        expect(LocomotionDynamics.footPlant(0, 1, false)).toBe(0)
        expect(LocomotionDynamics.footPlant(0, 0, true)).toBe(0)
        local ascent, descent = LocomotionDynamics.flight(25, false, false)
        expect(ascent > 0).toBe(true)
        expect(descent).toBe(0)
        local downAscent, downBrace = LocomotionDynamics.flight(-28, false, false)
        expect(downAscent).toBe(0)
        expect(downBrace > 0).toBe(true)
        local moonAscent = LocomotionDynamics.flight(25, false, true)
        expect(moonAscent < ascent).toBe(true)
        local landReach, landBrace = LocomotionDynamics.flight(-35, true, false)
        expect(landReach).toBe(0)
        expect(landBrace).toBe(0)
    end)

    it("scales expressive movement to graphics quality and accessibility settings", function()
        expect(LocomotionDynamics.profile("High", false)).toBe(1)
        expect(LocomotionDynamics.profile("Low", false) < LocomotionDynamics.profile("Medium", false)).toBe(true)
        expect(LocomotionDynamics.profile("Medium", false) < LocomotionDynamics.profile("High", false)).toBe(true)
        expect(LocomotionDynamics.profile("High", true) <= 0.10).toBe(true)
    end)

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
