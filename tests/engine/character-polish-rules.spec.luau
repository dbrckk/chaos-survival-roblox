--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local CharacterPolishRules = require("../../src/shared/CharacterPolishRules")

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

    it("suppresses extra character lighting during final rush", function()
        expect(CharacterPolishRules.lightBrightness(
            "High",
            "round",
            true,
            true
        )).toBe(0)
    end)
end)

return nil
