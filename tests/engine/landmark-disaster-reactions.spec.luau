--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Rules = require("../../src/shared/LandmarkDisasterReactionRules")

local IDS = {
    "RisingLava", "Meteors", "LowGravity", "DisappearingPlatforms",
    "Tornado", "Freeze", "Bombs", "SpeedSurge", "Darkness",
    "ShrinkingArena", "JumpShock",
}

describe("Reactive arena landmarks during active disasters", function()
    it("covers all eleven hazards without inventing physics or duplicate visuals", function()
        for _, id in ipairs(IDS) do
            local response = Rules.compose({id}, "round", "High", false, false)
            expect(response.Active).toBe(true)
            expect(typeof(response.Accent)).toBe("Color3")
            expect(response.Motion).toBeGreaterThan(0)
            for _, key in ipairs({
                "Heat", "Shake", "Lift", "Wind", "Pulse",
                "Drift", "Frost", "Darkness",
            }) do
                expect(response[key] >= 0 and response[key] <= 1).toBe(true)
            end
        end
        expect(Rules.compose({}, "round", "High", false, false).Active).toBe(false)
        expect(Rules.compose({"Unknown"}, "round", "High", false, false).Active).toBe(false)
        expect(Rules.compose({"Meteors"}, "waiting", "High", false, false).Active).toBe(false)
        expect(Rules.compose({"Meteors"}, "result", "High", false, false).Active).toBe(false)
    end)

    it("keeps double-chaos effects bounded and honors mobile accessibility", function()
        local medium = Rules.compose({"Tornado", "Bombs"}, "round", "Medium", false, true)
        expect(medium.Wind).toBe(1)
        expect(medium.Shake).toBe(1)
        expect(medium.Pulse > 0.7 and medium.Pulse <= 1).toBe(true)
        expect(medium.Motion > 0 and medium.Motion < 1).toBe(true)
        local high = Rules.compose({"Tornado", "Bombs"}, "round", "High", false, true)
        expect(high.Motion).toBe(1)
        local low = Rules.compose({"Tornado", "Bombs"}, "round", "Low", false, true)
        expect(low.Motion < medium.Motion).toBe(true)
        local still = Rules.compose({"Tornado", "Bombs"}, "round", "High", true, true)
        expect(still.Active).toBe(true)
        expect(still.Motion).toBe(0)
        expect(still.Tint <= 0.13).toBe(true)
        local freezing = Rules.compose({"Freeze"}, "round", "High", false, false)
        expect(freezing.Motion < high.Motion).toBe(true)
        local capped = Rules.compose({"Meteors", "Bombs", "Freeze"}, "round", "High", false, false)
        expect(capped.Frost).toBe(0)
    end)

    it("expresses subtle varied gestures while freezing all displacements in reduced motion", function()
        local windy = Rules.compose({"Tornado", "SpeedSurge"}, "round", "High", false, false)
        local quiet = Rules.compose({"Tornado", "SpeedSurge"}, "round", "High", true, false)
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
        local still = Rules.compose({}, "waiting", "High", false, false)
        local zero, bank, yaw, tint = Rules.offset("reactorCore", 1, 3, still)
        expect(zero).toBe(Vector3.zero)
        expect(bank).toBe(0)
        expect(yaw).toBe(0)
        expect(tint).toBe(0)
    end)
end)

return nil
