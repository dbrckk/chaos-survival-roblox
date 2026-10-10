--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local BodyMotionRules = require("../../src/shared/BodyMotionRules")
local BotMotionPresentationRules = require("../../src/shared/BotMotionPresentationRules")
local LocomotionDynamics = require("../../src/shared/LocomotionDynamics")
local GroundFx = require("../../src/client/LocomotionGroundFx")

describe("Body motion rules", function()
    it("differentiates starting sprint and braking with released input", function()
        local launch, noBrake = LocomotionDynamics.acceleration(12, 2, 0.10, true)
        local noLaunch, braking = LocomotionDynamics.acceleration(8, 20, 0.10, true)
        expect(launch > 0).toBe(true)
        expect(noBrake).toBe(0)
        expect(noLaunch).toBe(0)
        expect(braking > 0).toBe(true)
        -- A hard stop may leap directly from sprint speed to zero in one
        -- low-FPS sample or after collision: the skid must not disappear.
        local hardStopLaunch, hardStopSkid =
            LocomotionDynamics.acceleration(0, 20, 0.11, true)
        expect(hardStopLaunch).toBe(0)
        expect(hardStopSkid > 0.7).toBe(true)
        local settledLaunch, settledStop =
            LocomotionDynamics.acceleration(0, 0, 0.11, true)
        expect(settledLaunch).toBe(0)
        expect(settledStop).toBe(0)
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

    it("classifies only major grounded movements into a short floor accent", function()
        local r = LocomotionDynamics
        local skid, strength = r.groundCue(0.7, 0.95, 0.9, "High", false, "round")
        expect(skid).toBe("Skid")
        expect(strength > 0.9).toBe(true)
        local pivot = r.groundCue(0.10, 0.1, -0.9, "Medium", false, "round")
        expect(pivot).toBe("Pivot")
        local sprint = r.groundCue(0.9, 0, 0, "Medium", false, "round")
        expect(sprint).toBe("Launch")
        for _, data in ipairs({
            {"Low", false, "round"},
            {"High", true, "round"},
            {"High", false, "waiting"},
        }) do
            local nothing, quiet = r.groundCue(1, 1, 1, data[1], data[2], data[3])
            expect(nothing == nil).toBe(true)
            expect(quiet).toBe(0)
        end
        local noCue = r.groundCue(0.1, 0.1, 0.1, "High", false, "round")
        expect(noCue == nil).toBe(true)
    end)

    it("creates only bounded non-colliding transient ground geometry", function()
        local root = Instance.new("Folder")
        local cf = CFrame.new(0, 2, 0)
        for _, style in ipairs({"Launch", "Skid", "Pivot"}) do
            local high = GroundFx.build(root, cf, style, 0.9, "High")
            local medium = GroundFx.build(root, cf, style, 0.9, "Medium")
            expect(high ~= nil).toBe(true)
            expect(#high:GetChildren()).toBe(4)
            expect(#medium:GetChildren()).toBe(2)
            for _, child in ipairs(high:GetChildren()) do
                expect(child:IsA("BasePart")).toBe(true)
                expect(child.CanCollide).toBe(false)
                expect(child.CanTouch).toBe(false)
                expect(child.CanQuery).toBe(false)
                expect(child.Anchored).toBe(true)
            end
            high:Destroy()
            medium:Destroy()
        end
        expect(GroundFx.build(root, cf, "Skid", 1, "Low") == nil).toBe(true)
        expect(GroundFx.build(root, cf, "Other", 1, "High") == nil).toBe(true)
        root:Destroy()
    end)

    it("authors three distinct 3D ground signatures without increasing the GPU budget", function()
        local surface = Instance.new("Folder")
        for _, tier in ipairs({"Medium", "High"}) do
            local count = tier == "High" and 4 or 2
            for _, kind in ipairs({"Launch", "Skid", "Pivot"}) do
                local fx = GroundFx.build(surface, CFrame.new(5, 1, -3),
                    kind, 0.9, tier)
                expect(#fx:GetChildren()).toBe(count)
                for index, piece in ipairs(fx:GetChildren()) do
                    local sig = GroundFx.signature(kind, index, 0.9, tier)
                    expect(sig ~= nil).toBe(true)
                    expect(piece.ClassName).toBe(sig.Class)
                    expect(piece.Material).toBe(sig.Material)
                    expect(piece.Size).toBe(sig.Size)
                    expect(piece.CastShadow).toBe(false)
                    expect(piece.CanCollide).toBe(false)
                    expect(piece.CanTouch).toBe(false)
                    expect(piece.CanQuery).toBe(false)
                    expect(piece.Transparency >= 0.25).toBe(true)
                    if tier == "Medium" then
                        expect(piece.Material == Enum.Material.Neon).toBe(false)
                    end
                end
                if kind == "Skid" then
                    expect(fx:GetChildren()[1]:IsA("Part")).toBe(true)
                    expect(fx:GetChildren()[1].Material).toBe(Enum.Material.Metal)
                else
                    expect(fx:GetChildren()[1]:IsA("WedgePart")).toBe(true)
                end
                fx:Destroy()
            end
            expect(GroundFx.signature("Launch", count + 1, 1, tier) == nil).toBe(true)
        end
        expect(GroundFx.signature("Launch", 1, 1, "Low") == nil).toBe(true)
        expect(GroundFx.signature("Invalid", 1, 1, "High") == nil).toBe(true)
        expect(GroundFx.signature("Skid", 1.5, 1, "High") == nil).toBe(true)
        expect(GroundFx.signature("Skid", 0, 1, "High") == nil).toBe(true)
        expect(#surface:GetChildren()).toBe(0)
        surface:Destroy()
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


describe("Directional character impact and cinematic AI footwork", function()
    it("reacts to the physical explosion side without rotating the avatar or applying force", function()
        local base = CFrame.new(20, 8, -14)
            * CFrame.Angles(0, math.rad(72), 0)
        local right = base.RightVector
        local forward = base.LookVector
        local strength, rightward, forwardward = BodyMotionRules.blastResponse(
            base, base.Position - right * 6, 8
        )
        expect(strength > 0 and strength < 1).toBe(true)
        expect(rightward > 0.99).toBe(true)
        expect(math.abs(forwardward) < 0.01).toBe(true)

        local _, leftward = BodyMotionRules.blastResponse(
            base, base.Position + right * 6, 8
        )
        expect(leftward < -0.99).toBe(true)
        local _, _, forwardReaction = BodyMotionRules.blastResponse(
            base, base.Position - forward * 5, 8
        )
        expect(forwardReaction > 0.99).toBe(true)
        local _, _, backwardReaction = BodyMotionRules.blastResponse(
            base, base.Position + forward * 5, 8
        )
        expect(backwardReaction < -0.99).toBe(true)
        local farIntensity = BodyMotionRules.blastResponse(
            base, base.Position + Vector3.new(200, 0, 0), 8
        )
        expect(farIntensity).toBe(0)
        local zeroIntensity, zeroSide, zeroForward = BodyMotionRules.blastResponse(
            base, base.Position, 8
        )
        expect(zeroIntensity).toBe(1)
        expect(zeroSide).toBe(0)
        expect(zeroForward).toBe(0)
        expect(BodyMotionRules.blastResponse(nil, base.Position, 8)).toBe(0)
        expect(BodyMotionRules.blastResponse(base, nil, 8)).toBe(0)
    end)

    it("culls far AI trails without flicker or extra instances", function()
        local visible = BotMotionPresentationRules.trailVisible
        expect(visible("Low", false, "round", true, 1, 5, false)).toBe(false)
        expect(visible("Medium", false, "round", true, 1, 40, false)).toBe(true)
        expect(visible("High", false, "round", true, 1, 95, false)).toBe(true)
        expect(visible("Medium", false, "round", true, 1, 70, false)).toBe(false)
        expect(visible("Medium", false, "round", true, 1, 70, true)).toBe(true)
        expect(visible("High", false, "round", true, 1, 100, false)).toBe(false)
        expect(visible("High", false, "round", true, 1, 100, true)).toBe(true)
        expect(visible("High", false, "round", true, 1, 108, true)).toBe(false)
        expect(visible("High", true, "round", true, 1, 5, true)).toBe(false)
        expect(visible("High", false, "ready", true, 1, 5, true)).toBe(false)
        expect(visible("High", false, "round", false, 1, 5, true)).toBe(false)
        expect(visible("High", false, "round", true, 0.3, 5, true)).toBe(false)
        expect(visible("High", false, "round", true, 1, -1, true)).toBe(false)
        expect(visible("High", false, "round", true, 1, nil, true)).toBe(false)
    end)

    it("creates only nearby, meaningful AI launch, skid and pivot cues", function()
        local rules = {
            profile = BotMotionPresentationRules.profile,
            trailAccent = BotMotionPresentationRules.trailAccent,
            cue = function(v, before, dt, grounded, tier, reduced, phase, distance)
                return BotMotionPresentationRules.cue(
                    v, before, dt, grounded, tier, reduced, phase, distance,
                    LocomotionDynamics
                )
            end,
        }
        expect(rules.profile("Low", false).MaxPerScan).toBe(0)
        expect(rules.profile("Medium", false).Range).toBe(54)
        expect(rules.profile("High", false).Range).toBe(78)
        expect(rules.profile("High", true).MaxPerScan).toBe(0)
        expect(rules.profile("High", false).Cooldown > 1).toBe(true)
        expect(rules.trailAccent("Launch")).toBe(Color3.fromRGB(83, 222, 255))
        expect(rules.trailAccent("Skid")).toBe(Color3.fromRGB(255, 156, 83))
        expect(rules.trailAccent("Pivot")).toBe(Color3.fromRGB(187, 105, 255))
        expect(rules.trailAccent("Unknown") == nil).toBe(true)

        local launch, launchStrength = rules.cue(
            Vector3.new(17, 0, 0), Vector3.new(3, 0, 0),
            0.08, true, "High", false, "round", 10
        )
        expect(launch).toBe("Launch")
        expect(launchStrength > 0.78).toBe(true)
        local skid, skidStrength = rules.cue(
            Vector3.new(3, 0, 0), Vector3.new(18, 0, 0),
            0.08, true, "High", false, "round", 10
        )
        expect(skid).toBe("Skid")
        expect(skidStrength > 0.78).toBe(true)
        local pivot, pivotStrength = rules.cue(
            Vector3.new(-17, 0, 0), Vector3.new(17, 0, 0),
            0.08, true, "High", false, "round", 10
        )
        expect(pivot).toBe("Pivot")
        expect(pivotStrength > 0.78).toBe(true)
        for _, scenario in ipairs({
            {true, "Low", false, "round", 10},
            {true, "High", true, "round", 10},
            {true, "High", false, "ready", 10},
            {true, "High", false, "round", 110},
            {false, "High", false, "round", 10},
        }) do
            local inactive = rules.cue(
                Vector3.new(17, 0, 0), Vector3.new(3, 0, 0),
                0.08, scenario[1], scenario[2], scenario[3],
                scenario[4], scenario[5]
            )
            expect(inactive == nil).toBe(true)
        end
        expect(rules.cue(nil, Vector3.zero, 0.08, true,
            "High", false, "round", 10) == nil).toBe(true)
        expect(rules.cue(Vector3.zero, Vector3.zero, 0,
            true, "High", false, "round", 10) == nil).toBe(true)
        expect(rules.cue(Vector3.new(3, 0, 0), Vector3.new(3, 0, 0),
            0.08, true, "High", false, "round", 10) == nil).toBe(true)
    end)
end)

return nil
