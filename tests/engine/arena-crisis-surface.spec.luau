--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Rules = require("../../src/shared/ArenaCrisisSurfaceRules")
local Palette = require("../../src/shared/DisasterVisuals")
local function profile(ids, phase, tier, reduced, finalRush)
    return Rules.profile(ids, phase, tier, reduced, finalRush, Palette)
end

local function colorDistance(a, b)
    return math.abs(a.R - b.R) + math.abs(a.G - b.G)
        + math.abs(a.B - b.B)
end

local DISASTERS = {
    "RisingLava", "Meteors", "LowGravity", "DisappearingPlatforms",
    "Tornado", "Freeze", "Bombs", "SpeedSurge", "Darkness",
    "ShrinkingArena", "JumpShock",
}

describe("Material-safe reactive arena surface, lighting and spatial audio", function()
    it("covers all 11 disaster palettes with small, bounded detail tint amounts", function()
        local original = Color3.fromRGB(90, 112, 140)
        for _, id in ipairs(DISASTERS) do
            local response = profile({id}, "round", "High", false, false)
            expect(response.Active).toBe(true)
            expect(typeof(response.Primary)).toBe("Color3")
            expect(response.Secondary == nil).toBe(true)
            expect(response.MaxTint > 0 and response.MaxTint <= 0.28).toBe(true)
            expect(response.LightTint >= 0 and response.LightTint <= 0.20).toBe(true)
            expect(response.Wave >= 0 and response.Wave < 0.18).toBe(true)
            expect(response.PitchShift >= -0.05 and response.PitchShift <= 0.05).toBe(true)
            for _, material in ipairs({
                Enum.Material.Neon, Enum.Material.Metal,
                Enum.Material.DiamondPlate, Enum.Material.Glass,
            }) do
                local color = Rules.shade(
                    original, material, "TowerRing1", 2, response, 13.7
                )
                expect(typeof(color)).toBe("Color3")
                expect(color.R >= 0 and color.R <= 1).toBe(true)
                expect(color.G >= 0 and color.G <= 1).toBe(true)
                expect(color.B >= 0 and color.B <= 1).toBe(true)
            end
        end
    end)

    it("keeps deck repair seams subtle and lets hazard telegraphs dominate Final Rush", function()
        local original = Color3.fromRGB(80, 93, 108)
        local crisis = profile({"Meteors"}, "round", "High", false, false)
        local seam = Rules.shade(original, Enum.Material.Neon, "PanelSeam4", 4, crisis, 0)
        local center = Rules.shade(original, Enum.Material.Neon, "OrbitalSurfaceArc4", 4, crisis, 0)
        expect(colorDistance(seam, original) < colorDistance(center, original)).toBe(true)
        local repair = Rules.shade(original, Enum.Material.Neon, "RepairPlate4", 4, crisis, 0)
        expect(colorDistance(repair, original) < colorDistance(center, original)).toBe(true)
        local rush = profile({"Meteors"}, "round", "High", false, true)
        expect(rush.MaxTint <= 0.11).toBe(true)
        expect(rush.LightTint <= 0.08).toBe(true)
        expect(colorDistance(
            Rules.shade(original, Enum.Material.Neon, "OrbitalSurfaceArc4", 4, rush, 0),
            original
        ) < colorDistance(center, original)).toBe(true)
    end)

    it("blends Double Chaos accents in alternating decorative strips", function()
        local response = profile({"Meteors", "Freeze"}, "round", "High", false, false)
        expect(typeof(response.Secondary)).toBe("Color3")
        local original = Color3.fromRGB(77, 79, 83)
        local a = Rules.shade(original, Enum.Material.Neon, "TowerRing1", 1, response, 0)
        local b = Rules.shade(original, Enum.Material.Neon, "TowerRing2", 2, response, 0)
        expect(a ~= b).toBe(true)
        expect(response.PitchShift > -0.05 and response.PitchShift < 0.05).toBe(true)
        local waiting = profile({"Meteors"}, "ready", "High", false, false)
        local result = profile({"Meteors"}, "result", "High", false, false)
        expect(waiting.Active).toBe(false)
        expect(result.Active).toBe(false)
        expect(Rules.shade(original, Enum.Material.Neon, "TowerRing1", 1, waiting, 3)).toBe(original)
        expect(Rules.shade(original, Enum.Material.Neon, "TowerRing1", 1, result, 3)).toBe(original)
    end)

    it("freezes pulse on Low and ReduceMotion while preserving readable weak color", function()
        local original = Color3.fromRGB(116, 126, 136)
        local low = profile({"JumpShock"}, "round", "Low", false, false)
        local reduced = profile({"JumpShock"}, "round", "High", true, false)
        local normal = profile({"JumpShock"}, "round", "High", false, false)
        expect(low.Static).toBe(true)
        expect(reduced.Static).toBe(true)
        expect(low.Wave).toBe(0)
        expect(reduced.Wave).toBe(0)
        expect(low.MaxTint < normal.MaxTint).toBe(true)
        expect(reduced.MaxTint < normal.MaxTint).toBe(true)
        local lowEarly = Rules.shade(
            original, Enum.Material.Metal, "RepairPlate1", 1, low, 1.2
        )
        local lowLate = Rules.shade(
            original, Enum.Material.Metal, "RepairPlate1", 1, low, 50
        )
        expect(lowEarly).toBe(lowLate)
        local stillEarly = Rules.shade(
            original, Enum.Material.Neon, "TowerRing1", 1, reduced, 1.2
        )
        local stillLate = Rules.shade(
            original, Enum.Material.Neon, "TowerRing1", 1, reduced, 50
        )
        expect(stillEarly).toBe(stillLate)
        local moving = Rules.shade(original, Enum.Material.Neon, "TowerRing1", 1, normal, 1.2)
        local other = Rules.shade(original, Enum.Material.Neon, "TowerRing1", 1, normal, 50)
        expect(moving ~= other).toBe(true)
    end)

    it("restores untinted spotlight colors and ambience pitch after round", function()
        local baseColor = Color3.fromRGB(220, 190, 125)
        local basePitch = 0.62
        local waiting = profile({"Darkness"}, "waiting", "Medium", false, false)
        local dark = profile({"Darkness"}, "round", "Medium", false, false)
        local freezing = profile({"Freeze"}, "round", "Medium", false, false)
        local aggressive = profile({"Meteors"}, "round", "Medium", false, false)
        local idleLight, idleBrightness = Rules.light(baseColor, 0.9, 1, waiting)
        expect(idleLight).toBe(baseColor)
        expect(idleBrightness).toBe(0.9)
        local lightColor, lightBrightness = Rules.light(baseColor, 0.9, 1, dark)
        expect(lightColor ~= baseColor).toBe(true)
        expect(lightBrightness < 0.9).toBe(true)
        expect(lightBrightness >= 0).toBe(true)
        expect(Rules.audio(basePitch, waiting)).toBe(basePitch)
        expect(Rules.audio(basePitch, dark) < basePitch).toBe(true)
        expect(Rules.audio(basePitch, freezing) < basePitch).toBe(true)
        expect(Rules.audio(basePitch, aggressive) > basePitch).toBe(true)
        expect(Rules.audio(1.6, aggressive) <= 1.4).toBe(true)
        expect(profile({"Unknown"}, "round", "High", false, false).Active).toBe(false)
        expect(profile({}, "round", "High", false, false).Active).toBe(false)
    end)
end)

return nil
