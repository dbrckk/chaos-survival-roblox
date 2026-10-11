--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Rules = require("../../src/shared/LandmarkDisasterReactionRules")
local Palette = require("../../src/shared/DisasterVisuals")
local function compose(ids, phase, tier, reduced, finalRush)
    return Rules.compose(ids, phase, tier, reduced, finalRush, Palette)
end

local IDS = {
    "RisingLava", "Meteors", "LowGravity", "DisappearingPlatforms",
    "Tornado", "Freeze", "Bombs", "SpeedSurge", "Darkness",
    "ShrinkingArena", "JumpShock",
}

describe("Reactive arena landmarks during active disasters", function()
    it("covers all eleven hazards without inventing physics or duplicate visuals", function()
        for _, id in ipairs(IDS) do
            local response = compose({id}, "round", "High", false, false)
            expect(response.Active).toBe(true)
            expect(typeof(response.Accent)).toBe("Color3")
            expect(response.Motion > 0).toBe(true)
            for _, key in ipairs({
                "Heat", "Shake", "Lift", "Wind", "Pulse",
                "Drift", "Frost", "Darkness",
            }) do
                expect(response[key] >= 0 and response[key] <= 1).toBe(true)
            end
        end
        expect(compose({}, "round", "High", false, false).Active).toBe(false)
        expect(compose({"Unknown"}, "round", "High", false, false).Active).toBe(false)
        expect(compose({"Meteors"}, "waiting", "High", false, false).Active).toBe(false)
        expect(compose({"Meteors"}, "result", "High", false, false).Active).toBe(false)
    end)

    it("keeps double-chaos effects bounded and honors mobile accessibility", function()
        local medium = compose({"Tornado", "Bombs"}, "round", "Medium", false, true)
        expect(medium.Wind).toBe(1)
        expect(medium.Shake).toBe(1)
        expect(medium.Pulse > 0.7 and medium.Pulse <= 1).toBe(true)
        expect(medium.Motion > 0 and medium.Motion < 1).toBe(true)
        local high = compose({"Tornado", "Bombs"}, "round", "High", false, true)
        expect(high.Motion).toBe(1)
        local low = compose({"Tornado", "Bombs"}, "round", "Low", false, true)
        expect(low.Motion < medium.Motion).toBe(true)
        local still = compose({"Tornado", "Bombs"}, "round", "High", true, true)
        expect(still.Active).toBe(true)
        expect(still.Motion).toBe(0)
        expect(still.Tint <= 0.13).toBe(true)
        local freezing = compose({"Freeze"}, "round", "High", false, false)
        expect(freezing.Motion < high.Motion).toBe(true)
        local capped = compose({"Meteors", "Bombs", "Freeze"}, "round", "High", false, false)
        expect(capped.Frost).toBe(0)
    end)

    it("expresses subtle varied gestures while freezing all displacements in reduced motion", function()
        local windy = compose({"Tornado", "SpeedSurge"}, "round", "High", false, false)
        local quiet = compose({"Tornado", "SpeedSurge"}, "round", "High", true, false)
        for _, role in ipairs({
            "lift", "pulse", "cable", "reactorCore",
            "reactorArm", "scan", "antenna", "signal",
        }) do
            for _, t in ipairs({0, 1.7, 3.8, 12.2}) do
                local offset, bank, yaw, tint = Rules.offset(role, 2, t, windy)
                expect(typeof(offset)).toBe("Vector3")
                expect(offset.Magnitude < 1).toBe(true)
                expect(math.abs(bank) < 0.1).toBe(true)
                expect(math.abs(yaw) < 0.1).toBe(true)
                expect(tint >= 0 and tint <= 0.27).toBe(true)
                local frozen, frozenBank, frozenYaw, frozenTint =
                    Rules.offset(role, 2, t, quiet)
                expect(frozen).toBe(Vector3.zero)
                expect(frozenBank).toBe(0)
                expect(frozenYaw).toBe(0)
                expect(frozenTint <= tint).toBe(true)
            end
        end
        local still = compose({}, "waiting", "High", false, false)
        local zero, bank, yaw, tint = Rules.offset("reactorCore", 1, 3, still)
        expect(zero).toBe(Vector3.zero)
        expect(bank).toBe(0)
        expect(yaw).toBe(0)
        expect(tint).toBe(0)
    end)
end)


describe("Hero landmark animation scheduling and accessibility", function()
    local Budget = require("../../src/shared/HeroMotionBudgetRules")

    it("preserves tier motion and cadence while falling back conservatively", function()
        expect(Budget.motionScale("Low", false)).toBe(0.18)
        expect(Budget.motionScale("Medium", false)).toBe(0.62)
        expect(Budget.motionScale("High", false)).toBe(1)
        expect(Budget.interval("Low", false, true)).toBe(0.16)
        expect(Budget.interval("Medium", false, true)).toBe(0.09)
        expect(Budget.interval("High", false, true)).toBe(0.055)
        expect(Budget.motionScale("Unknown", false)).toBe(0.18)
        expect(Budget.interval("Unknown", false, true)).toBe(0.16)
    end)

    it("eases streamed, LOD-restored and accessibility-resumed 3D motion", function()
        expect(Budget.resumeEnvelope(0)).toBe(0)
        expect(Budget.resumeEnvelope(-1)).toBe(0)
        expect(Budget.resumeEnvelope("0.24")).toBe(0)
        expect(Budget.resumeEnvelope(0/0)).toBe(0)
        expect(Budget.resumeEnvelope(math.huge)).toBe(0)
        expect(Budget.resumeEnvelope(-math.huge)).toBe(0)
        expect(math.abs(Budget.resumeEnvelope(0.24) - 0.5) < 0.0001)
            .toBe(true)
        expect(Budget.resumeEnvelope(0.48)).toBe(1)
        expect(Budget.resumeEnvelope(2)).toBe(1)

        local base = CFrame.new(7, 12, -4)
            * CFrame.Angles(math.rad(12), math.rad(32), 0)
        local travel = 5.2
        local rest = base * CFrame.new(0, travel * Budget.resumeEnvelope(0), 0)
        local mid = base * CFrame.new(0, travel * Budget.resumeEnvelope(0.24), 0)
        local full = base * CFrame.new(0, travel * Budget.resumeEnvelope(0.48), 0)
        expect((rest.Position - base.Position).Magnitude < 0.0001).toBe(true)
        expect(math.abs((mid.Position - base.Position).Magnitude - travel / 2)
            < 0.0001).toBe(true)
        expect(math.abs((full.Position - base.Position).Magnitude - travel)
            < 0.0001).toBe(true)
        -- Tier and accessibility budgets still dominate the envelope.
        expect(Budget.motionScale("High", true)
            * Budget.resumeEnvelope(1)).toBe(0)
        expect(Budget.motionScale("Low", false)
            * Budget.resumeEnvelope(1)).toBe(0.18)
    end)

    it("animates authored antenna vanes and transit shutters without 3D drift", function()
        local base = CFrame.new(15, 7, -12)
            * CFrame.Angles(math.rad(14), math.rad(31), math.rad(-8))
        for _, entry in ipairs({
            {"antenna", 1}, {"antenna", 2},
            {"signal", 1}, {"signal", 2}, {"signal", 3},
        }) do
            local role, index = entry[1], entry[2]
            local high = Budget.signatureOffset(role, index, 1.37, 1)
            local low = Budget.signatureOffset(role, index, 1.37, 0.18)
            local still = Budget.signatureOffset(role, index, 1.37, 0)
            expect(high ~= nil).toBe(true)
            expect(low ~= nil).toBe(true)
            expect(still ~= nil).toBe(true)
            local function motion(cf)
                return cf.Position.Magnitude
                    + (cf.UpVector - Vector3.new(0, 1, 0)).Magnitude
            end
            expect(motion(high) > motion(low)).toBe(true)
            expect(motion(low) > motion(still)).toBe(true)
            expect(motion(still) < 0.00001).toBe(true)
            expect(high.Position.Magnitude <= 0.086).toBe(true)
            local localPose = base:ToObjectSpace(base * high)
            expect((localPose.Position - high.Position).Magnitude < 0.0001)
                .toBe(true)
            expect(localPose.UpVector:Dot(high.UpVector) > 0.99999).toBe(true)
            local repeatPose = Budget.signatureOffset(role, index, 1.37, 1)
            expect((repeatPose.Position - high.Position).Magnitude < 0.0001)
                .toBe(true)
            expect(repeatPose.RightVector:Dot(high.RightVector) > 0.99999)
                .toBe(true)
        end
        expect(Budget.signatureOffset("lift", 1, 1, 1) == nil).toBe(true)
        expect(Budget.signatureOffset("antenna", 3, 1, 1) == nil).toBe(true)
        expect(Budget.signatureOffset("signal", 4, 1, 1) == nil).toBe(true)
        expect(Budget.signatureOffset("signal", 0, 1, 1) == nil).toBe(true)
        expect(Budget.signatureOffset("signal", 1.5, 1, 1) == nil).toBe(true)
        expect(Budget.signatureOffset("signal", 1, math.huge, 1) == nil).toBe(true)
        expect(Budget.signatureOffset("signal", 1, 0/0, 1) == nil).toBe(true)
        expect(Budget.signatureOffset("signal", 1, 1, -1) == nil).toBe(true)
        expect(Budget.signatureOffset("signal", 1, 1, math.huge) == nil).toBe(true)
        expect(Budget.signatureOffset("signal", 1, 1, 0/0) == nil).toBe(true)
    end)

    it("counterbalances the Towers crane cable without adding moving physics", function()
        local base = CFrame.new(10, 12, -6)
            * CFrame.Angles(math.rad(11), math.rad(37), 0)
        local t = 1.37
        local high = Budget.craneCounterweightOffset(t, 1)
        local medium = Budget.craneCounterweightOffset(t, 0.62)
        local low = Budget.craneCounterweightOffset(t, 0.18)
        local still = Budget.craneCounterweightOffset(t, 0)
        local cable = CFrame.Angles(0, 0,
            math.sin(t * 0.72) * math.rad(3.2))
        expect(high.Position.X * math.sin(t * 0.72) < 0).toBe(true)
        expect(high.UpVector.X * cable.UpVector.X < 0).toBe(true)
        expect(math.abs(high.Position.X) <= 0.28).toBe(true)
        expect(math.abs(high.Position.X) > math.abs(medium.Position.X)).toBe(true)
        expect(math.abs(medium.Position.X) > math.abs(low.Position.X)).toBe(true)
        expect((still.Position - Vector3.zero).Magnitude < 0.00001).toBe(true)
        expect(still.UpVector:Dot(Vector3.yAxis) > 0.99999).toBe(true)
        for _, clock in ipairs({0, 0.4, 2.1, 50, 10000}) do
            local offset = Budget.craneCounterweightOffset(clock, 1)
            expect(offset.Position.Magnitude <= 0.281).toBe(true)
            local composed = base * offset
            local repeated = base * Budget.craneCounterweightOffset(clock, 1)
            expect((composed.Position - repeated.Position).Magnitude < 0.0001)
                .toBe(true)
            expect(composed.UpVector:Dot(repeated.UpVector) > 0.99999)
                .toBe(true)
        end
        for _, invalid in ipairs({-1, math.huge, -math.huge, 1e8}) do
            local rest = Budget.craneCounterweightOffset(invalid, 1)
            expect(rest.Position.Magnitude < 0.00001).toBe(true)
        end
        expect(Budget.craneCounterweightOffset(0/0, 1).Position.Magnitude)
            .toBe(0)
        expect(Budget.craneCounterweightOffset(t, 0/0).Position.Magnitude)
            .toBe(0)
        expect(Budget.craneCounterweightOffset(t, math.huge).Position.Magnitude)
            .toBe(0)
        expect(Budget.craneCounterweightOffset(t, -1).Position.Magnitude)
            .toBe(0)
        expect(Budget.motionScale("High", true)).toBe(0)
    end)

    it("precesses Orbital reactor core only above Low, with bounded local 3D motion", function()
        local Budget = require("../../src/shared/HeroMotionBudgetRules")
        local base = CFrame.new(12, 19, -8)
            * CFrame.Angles(math.rad(9), math.rad(31), math.rad(-7))
        local t = 1.37
        local low = Budget.reactorCoreOffset(t, Budget.motionScale("Low", false))
        local medium = Budget.reactorCoreOffset(t, Budget.motionScale("Medium", false))
        local high = Budget.reactorCoreOffset(t, Budget.motionScale("High", false))
        expect(low.Position.Magnitude < 0.00001).toBe(true)
        expect(low.UpVector:Dot(Vector3.yAxis) > 0.99999).toBe(true)
        expect(medium.Position.Magnitude > 0).toBe(true)
        expect(high.Position.Magnitude > medium.Position.Magnitude).toBe(true)
        for _, clock in ipairs({0, 0.6, 1.37, 8, 4097.37}) do
            for _, strength in ipairs({0, 0.18, 0.62, 1}) do
                local offset = Budget.reactorCoreOffset(clock, strength)
                expect(offset.Position.Magnitude <= 0.101).toBe(true)
                expect(offset.UpVector:Dot(Vector3.yAxis)
                    >= math.cos(math.rad(1.61))).toBe(true)
                local relative = base:ToObjectSpace(base * offset)
                expect((relative.Position - offset.Position).Magnitude < 0.0001)
                    .toBe(true)
                local repeated = Budget.reactorCoreOffset(clock, strength)
                expect((repeated.Position - offset.Position).Magnitude < 0.0001)
                    .toBe(true)
                expect(repeated.UpVector:Dot(offset.UpVector) > 0.99999)
                    .toBe(true)
            end
        end
        for _, bad in ipairs({-1, math.huge, -math.huge, 1e8, -1e8, 0/0}) do
            expect(Budget.reactorCoreOffset(bad, 1).Position.Magnitude)
                .toBe(0)
            expect(Budget.reactorCoreOffset(t, bad).Position.Magnitude)
                .toBe(0)
        end
        expect(Budget.reactorCoreOffset(t, Budget.motionScale("High", true))
            .Position.Magnitude).toBe(0)
        expect(Budget.reactorCoreOffset(t, 0.18 * Budget.resumeEnvelope(0.24))
            .Position.Magnitude).toBe(0)
        -- A Medium/High -> Low switch must return to rest, not leave
        -- the previous moving core frame suspended.
        expect(Budget.reactorCoreOffset(t, 0.18).UpVector:Dot(Vector3.yAxis)
            > 0.99999).toBe(true)
    end)

    it("articulates existing service antenna and stages subtle service Neon", function()
        local base = CFrame.new(12, 7, -5)
            * CFrame.Angles(math.rad(9), math.rad(48), 0)
        local now = 1.37
        local high = Budget.serviceAntennaOffset(now, 1)
        local medium = Budget.serviceAntennaOffset(now, 0.62)
        local rest = Budget.serviceAntennaOffset(now, 0)
        expect(high.Position.Magnitude < 0.00001).toBe(true)
        expect(high.RightVector:Dot(Vector3.xAxis) >= math.cos(math.rad(1.16)))
            .toBe(true)
        local function sweep(frame)
            return (frame.LookVector - Vector3.new(0, 0, -1)).Magnitude
        end
        expect(sweep(high) > sweep(medium)).toBe(true)
        expect(sweep(medium) > sweep(rest)).toBe(true)
        expect(sweep(rest) < 0.00001).toBe(true)
        local first = base * high
        local again = base * Budget.serviceAntennaOffset(now, 1)
        expect((first.Position - again.Position).Magnitude < 0.0001)
            .toBe(true)
        expect(first.LookVector:Dot(again.LookVector) > 0.99999)
            .toBe(true)
        for _, bad in ipairs({-1, math.huge, -math.huge, 1e8}) do
            expect(Budget.serviceAntennaOffset(bad, 1).Position.Magnitude)
                .toBe(0)
        end
        expect(sweep(Budget.serviceAntennaOffset(0/0, 1)) < 0.00001)
            .toBe(true)
        expect(sweep(Budget.serviceAntennaOffset(now, 0/0)) < 0.00001)
            .toBe(true)
        expect(Budget.motionScale("High", true)).toBe(0)

        local distinct = {}
        for i = 1, 3 do
            distinct[i] = Budget.servicePulse("closureBar", i, 0)
            expect(distinct[i] >= 0 and distinct[i] <= 1).toBe(true)
            for _, t in ipairs({0, now, 13.7, 4097.3}) do
                local a = Budget.servicePulse("closureBar", i, t)
                expect(a >= 0 and a <= 1).toBe(true)
                expect(math.abs(a - Budget.servicePulse("closureBar", i, t + 0.001))
                    < 0.01).toBe(true)
            end
        end
        expect(math.abs(distinct[1] + distinct[2] + distinct[3] - 1.5)
            < 0.0001).toBe(true)
        expect(Budget.servicePulse("dockGlow", 1, now) > 0).toBe(true)
        expect(Budget.servicePulse("dockGlow", 1, now) <= 1).toBe(true)
        expect(Budget.servicePulse("dockGlow", 2, now)).toBe(0)
        expect(Budget.servicePulse("closureBar", 4, now)).toBe(0)
        expect(Budget.servicePulse("unknown", 1, now)).toBe(0)
        expect(Budget.servicePulse("closureBar", 1, -1)).toBe(0)
        expect(Budget.servicePulse("closureBar", 1, math.huge)).toBe(0)
        expect(Budget.servicePulse("closureBar", 1, 0/0)).toBe(0)
    end)

    it("crossfades three transit lights without hard on-off frame jumps", function()
        local phase = {}
        for i = 1, 3 do
            phase[i] = Budget.signalPulse(0, i)
            expect(phase[i] >= 0 and phase[i] <= 1).toBe(true)
            for _, t in ipairs({0, 0.42, 1.37, 9.1, 4097.37}) do
                local glow = Budget.signalPulse(t, i)
                expect(glow >= 0 and glow <= 1).toBe(true)
                expect(math.abs(glow - Budget.signalPulse(t, i)) < 0.000001)
                    .toBe(true)
                expect(math.abs(glow - Budget.signalPulse(t + 0.001, i)) < 0.01)
                    .toBe(true)
            end
        end
        expect(math.abs(phase[1] + phase[2] + phase[3] - 1.5) < 0.0001)
            .toBe(true)
        expect(math.abs(phase[1] - phase[2]) > 0.1).toBe(true)
        expect(Budget.signalPulse(math.huge, 1)).toBe(0)
        expect(Budget.signalPulse(0/0, 1)).toBe(0)
        expect(Budget.signalPulse(1, 0)).toBe(0)
        expect(Budget.signalPulse(1, 4)).toBe(0)
        expect(Budget.signalPulse(1, 1.5)).toBe(0)
    end)

    it("stops all continuous displacement with ReduceMotion and idles without scenery", function()
        for _, tier in ipairs({"Low", "Medium", "High", "Unknown"}) do
            expect(Budget.motionScale(tier, true)).toBe(0)
            expect(Budget.interval(tier, true, true)).toBe(0.24)
        end
        expect(Budget.interval("High", false, false)).toBe(0.50)
        expect(Budget.interval("Low", true, false)).toBe(0.50)
    end)


    it("retains a bounded static hazard accent without any motion pulses", function()
        local active = compose({"Meteors", "Bombs"}, "round", "High", true, false)
        expect(Budget.staticTint(active, true)).toBe(0.13)
        expect(Budget.staticTint(active, false)).toBe(0)
        expect(Budget.staticTint(compose({}, "waiting", "High", true, false), true))
            .toBe(0)
        expect(Budget.staticTint({Active=true, Tint=1}, true)).toBe(0.13)
        expect(Budget.staticTint({Active=true, Tint=-1}, true)).toBe(0)
        expect(Budget.staticTint({Active=true, Tint=0/0}, true)).toBe(0)
        expect(Budget.staticTint({Active=true, Tint=math.huge}, true)).toBe(0)
        expect(Budget.staticTint(nil, true)).toBe(0)
    end)

    it("restores nonphysical 3D hero art to its baseline with static hazard color", function()
        local parent = Instance.new("Folder")
        local piece = Instance.new("WedgePart")
        piece.Parent = parent
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        local original = {
            baseCFrame = CFrame.new(12, 8, -11)
                * CFrame.Angles(math.rad(12), math.rad(46), math.rad(-5)),
            baseSize = Vector3.new(1.5, 3.1, 2.2),
            baseTransparency = 0.32,
            baseColor = Color3.fromRGB(60, 150, 240),
        }
        piece.CFrame = CFrame.new(-9, 13, 5)
        piece.Size = Vector3.new(6, 6, 6)
        piece.Transparency = 0.7
        piece.Color = Color3.fromRGB(255, 255, 255)
        local hazard = compose({"Meteors"}, "round", "High", true, false)
        expect(Budget.applyStillPose(piece, original, hazard)).toBe(true)
        expect((piece.CFrame.Position - original.baseCFrame.Position)
            .Magnitude < 0.001).toBe(true)
        expect(piece.CFrame.LookVector:Dot(original.baseCFrame.LookVector)
            > 0.99999).toBe(true)
        expect((piece.Size - original.baseSize).Magnitude < 0.001).toBe(true)
        expect(math.abs(piece.Transparency - 0.32) < 0.0001).toBe(true)
        -- BasePart.Color may quantize channels to 8-bit in the live engine.
        local tinted = original.baseColor:Lerp(hazard.Accent, 0.13)
        expect((Vector3.new(piece.Color.R, piece.Color.G, piece.Color.B)
            - Vector3.new(tinted.R, tinted.G, tinted.B)).Magnitude < 0.01)
            .toBe(true)
        expect(piece.CanCollide).toBe(false)
        expect(piece.CanTouch).toBe(false)
        expect(piece.CanQuery).toBe(false)
        expect(Budget.applyStillPose(piece, original, nil)).toBe(true)
        expect((Vector3.new(piece.Color.R, piece.Color.G, piece.Color.B)
            - Vector3.new(original.baseColor.R, original.baseColor.G,
                original.baseColor.B)).Magnitude < 0.01).toBe(true)
        expect(Budget.applyStillPose(piece, {}, hazard)).toBe(false)
        piece.Parent = nil
        expect(Budget.applyStillPose(piece, original, hazard)).toBe(false)
        piece:Destroy()
        parent:Destroy()
    end)

    it("composes local 3D hero movement with hazard offset without drift", function()
        local frame = CFrame.new(14, 8, -11)
            * CFrame.Angles(math.rad(14), math.rad(35), math.rad(-9))
        local moving = frame * CFrame.Angles(0, 0, math.rad(3))
        local shift = Vector3.new(0.18, 0.22, -0.08)
        local composed = Budget.reactiveFrame(moving, shift,
            math.rad(1.6), math.rad(-1.1))
        local expected = moving * CFrame.new(shift)
            * CFrame.Angles(0, math.rad(1.6), math.rad(-1.1))
        expect((composed.Position - expected.Position).Magnitude < 0.0001)
            .toBe(true)
        expect(composed.LookVector:Dot(expected.LookVector) > 0.99999)
            .toBe(true)
        local reset = Budget.reactiveFrame(moving, Vector3.zero, 0, 0)
        expect((reset.Position - moving.Position).Magnitude < 0.0001)
            .toBe(true)
        expect(reset.LookVector:Dot(moving.LookVector) > 0.99999)
            .toBe(true)
    end)

    it("restores static landmark tint once after hazards without idle color writes", function()
        for _, role in ipairs({
            "lift", "pulse", "cable", "craneWeight", "reactorArm",
            "antenna", "opsAntenna", "dockGlow", "closureBar",
            "scan", "signal", "reactorCore",
        }) do
            expect(Budget.shouldRestoreBaseColor(role, false)).toBe(false)
            expect(Budget.shouldRestoreBaseColor(role, nil)).toBe(false)
            expect(Budget.shouldRestoreBaseColor(role, true))
                .toBe(role ~= "signal" and role ~= "reactorCore")
        end
        local part = Instance.new("Part")
        local baseColor = Color3.fromRGB(30, 80, 140)
        local disasterColor = Color3.fromRGB(255, 90, 40)
        part.Color = disasterColor
        local hadReaction = true
        if Budget.shouldRestoreBaseColor("closureBar", hadReaction) then
            part.Color = baseColor
        end
        hadReaction = false
        expect(part.Color).toBe(baseColor)
        expect(Budget.shouldRestoreBaseColor("closureBar", hadReaction))
            .toBe(false)
        part:Destroy()
    end)

    it("does not animate LOD-hidden or detached client-only landmark parts", function()
        local folder = Instance.new("Folder")
        local part = Instance.new("Part")
        part.Parent = folder
        expect(Budget.shouldUpdate(part)).toBe(true)
        part:SetAttribute("SceneryLodHidden", true)
        expect(Budget.shouldUpdate(part)).toBe(false)
        part:SetAttribute("SceneryLodHidden", false)
        expect(Budget.shouldUpdate(part)).toBe(true)
        part.Parent = nil
        expect(Budget.shouldUpdate(part)).toBe(false)
        expect(Budget.shouldUpdate(nil)).toBe(false)
        part:Destroy()
        folder:Destroy()
    end)
end)

return nil
