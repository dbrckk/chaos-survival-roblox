--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local CharacterPolishRules = require("../../src/shared/CharacterPolishRules")
local TrailRules = require("../../src/shared/CharacterMotionTrailRules")

describe("Character polish rules", function()
    it("keeps the local player more readable than remote characters", function()
        local localOutline = CharacterPolishRules.outlineTransparency(
            "High",
            "round",
            true,
            false,
            false
        )
        local remoteOutline = CharacterPolishRules.outlineTransparency(
            "High",
            "round",
            false,
            false,
            false
        )
        expect(localOutline < remoteOutline).toBe(true)
    end)

    it("keeps ai silhouettes subtler than the local player", function()
        local localOutline = CharacterPolishRules.outlineTransparency(
            "Medium",
            "ready",
            true,
            false,
            false
        )
        local aiOutline = CharacterPolishRules.outlineTransparency(
            "Medium",
            "ready",
            false,
            true,
            false
        )
        expect(localOutline < aiOutline).toBe(true)
    end)

    it("disables fill and most extra lighting on low quality", function()
        expect(CharacterPolishRules.fillTransparency(
            "Low",
            "round",
            true,
            false
        )).toBe(1)
        expect(CharacterPolishRules.lightBrightness(
            "Low",
            "round",
            true,
            false
        )).toBe(0)
    end)

    it("reduces trail persistence for accessibility and final rush", function()
        local normal = CharacterPolishRules.trailLifetime("High", false, false)
        local reduced = CharacterPolishRules.trailLifetime("High", true, false)
        local rush = CharacterPolishRules.trailLifetime("High", false, true)

        expect(reduced < normal).toBe(true)
        expect(rush < normal).toBe(true)
        expect(rush <= 0.13).toBe(true)
    end)

    it("attenuates spectators and eliminated players during the round", function()
        local active = CharacterPolishRules.outlineTransparency(
            "High",
            "round",
            false,
            false,
            false,
            true
        )
        local inactive = CharacterPolishRules.outlineTransparency(
            "High",
            "round",
            false,
            false,
            false,
            false
        )

        expect(inactive > active).toBe(true)
        expect(inactive >= 0.94).toBe(true)
        expect(CharacterPolishRules.lightBrightness(
            "High",
            "round",
            false,
            false,
            false
        )).toBe(0)
    end)

    it("suppresses extra character lighting during final rush", function()
        expect(CharacterPolishRules.lightBrightness(
            "High",
            "round",
            true,
            true
        )).toBe(0)
    end)
end)


describe("Human momentum ribbon GPU and accessibility policy", function()
    it("culls by tier and camera distance, including ReduceMotion", function()
        local r = TrailRules
        expect(r.visible("round", false, false, 1, "High", false, 90)).toBe(true)
        expect(r.visible("round", false, false, 1, "High", false, 90.1)).toBe(false)
        expect(r.visible("round", false, false, 1, "Medium", false, 60)).toBe(true)
        expect(r.visible("round", false, false, 1, "Medium", false, 61)).toBe(false)
        expect(r.visible("round", false, false, 1, "Low", false, 0)).toBe(false)
        expect(r.visible("round", false, false, 1, "High", true, 0)).toBe(false)
        expect(r.visible("round", false, false, 1, "Unknown", false, 0)).toBe(false)
        expect(r.visible("round", false, false, 1, "High", false, nil)).toBe(false)
    end)
    it("suppresses airborne, idle, pre-round and final rush ribbons", function()
        local r = TrailRules
        expect(r.visible("ready", false, false, 1, "High", false, 0)).toBe(false)
        expect(r.visible("round", true, false, 1, "High", false, 0)).toBe(false)
        expect(r.visible("round", false, true, 1, "High", false, 0)).toBe(false)
        expect(r.visible("round", false, false, 0.82, "High", false, 0)).toBe(false)
        expect(r.visible("round", false, false, 0.83, "High", false, 0)).toBe(true)
        local highLife, highWidth = r.style("High")
        local medLife, medWidth = r.style("Medium")
        local lowLife, lowWidth = r.style("Low")
        expect(highLife > medLife and medLife > lowLife).toBe(true)
        expect(highWidth > medWidth and medWidth > lowWidth).toBe(true)
        expect(highLife <= 0.14 and highWidth <= 0.34).toBe(true)
        expect(lowLife).toBe(0)
        expect(lowWidth).toBe(0)
    end)
end)

return nil
