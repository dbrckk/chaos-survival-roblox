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
        local tinted = original.baseColor:Lerp(hazard.Accent, 0.13)
        expect((Vector3.new(piece.Color.R, piece.Color.G, piece.Color.B)
            - Vector3.new(tinted.R, tinted.G, tinted.B)).Magnitude < 0.0001)
            .toBe(true)
        expect(piece.CanCollide).toBe(false)
        expect(piece.CanTouch).toBe(false)
        expect(piece.CanQuery).toBe(false)
        expect(Budget.applyStillPose(piece, original, nil)).toBe(true)
        expect((Vector3.new(piece.Color.R, piece.Color.G, piece.Color.B)
            - Vector3.new(original.baseColor.R, original.baseColor.G,
                original.baseColor.B)).Magnitude < 0.0001).toBe(true)
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
