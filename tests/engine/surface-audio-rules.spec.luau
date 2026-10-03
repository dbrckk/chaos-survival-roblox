--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local SurfaceAudioRules = require("../../src/shared/SurfaceAudioRules")

describe("Surface audio rules", function()
    it("gives the four arena floor materials distinct spectral profiles", function()
        local classic = SurfaceAudioRules.profile(Enum.Material.DiamondPlate)
        local towers = SurfaceAudioRules.profile(Enum.Material.Metal)
        local crossroads = SurfaceAudioRules.profile(Enum.Material.Slate)
        local orbital = SurfaceAudioRules.profile(Enum.Material.SmoothPlastic)

        expect(classic.Mid ~= towers.Mid or classic.High ~= towers.High).toBe(true)
        expect(crossroads.Low > orbital.Low).toBe(true)
        expect(orbital.High > crossroads.High).toBe(true)
    end)

    it("keeps all effect values inside safe Roblox ranges", function()
        for _, material in ipairs({
            Enum.Material.DiamondPlate,
            Enum.Material.Metal,
            Enum.Material.Slate,
            Enum.Material.SmoothPlastic,
            Enum.Material.Ice,
            Enum.Material.Concrete,
        }) do
            local profile = SurfaceAudioRules.profile(material)
            expect(profile.Low >= -20 and profile.Low <= 10).toBe(true)
            expect(profile.Mid >= -20 and profile.Mid <= 10).toBe(true)
            expect(profile.High >= -20 and profile.High <= 10).toBe(true)
            expect(profile.Wet >= -80 and profile.Wet <= 10).toBe(true)
            expect(profile.Decay >= 0.1 and profile.Decay <= 20).toBe(true)
        end
    end)

    it("falls back to a neutral treatment for unknown materials", function()
        local profile = SurfaceAudioRules.profile(Enum.Material.Grass)
        expect(profile.Low).toBe(0)
        expect(profile.Mid).toBe(0)
        expect(profile.High).toBe(0)
    end)
end)

return nil
