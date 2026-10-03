--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaSpatialAudioRules = require("../../src/shared/ArenaSpatialAudioRules")

describe("Arena spatial audio rules", function()
    it("defines a profile for every arena", function()
        for _, id in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local profile = ArenaSpatialAudioRules.profile(id)
            expect(type(profile.Bed)).toBe("string")
            expect(type(profile.Secondary)).toBe("string")
            expect(profile.Volume > 0).toBe(true)
            expect(profile.Radius > 0).toBe(true)
        end
    end)

    it("scales source count with quality", function()
        expect(ArenaSpatialAudioRules.sourceCount("Low")).toBe(1)
        expect(ArenaSpatialAudioRules.sourceCount("Medium")).toBe(2)
        expect(ArenaSpatialAudioRules.sourceCount("High")).toBe(3)
    end)

    it("ducks ambience as round pressure rises", function()
        local normal = ArenaSpatialAudioRules.phaseScale("round", false, false)
        local overdrive = ArenaSpatialAudioRules.phaseScale("round", true, false)
        local finalRush = ArenaSpatialAudioRules.phaseScale("round", true, true)

        expect(overdrive < normal).toBe(true)
        expect(finalRush < overdrive).toBe(true)
    end)

    it("mutes arena ambience while the player is in the lobby", function()
        expect(ArenaSpatialAudioRules.phaseScale("waiting", false, false)).toBe(0)
        expect(ArenaSpatialAudioRules.phaseScale("intermission", false, false)).toBe(0)
    end)

    it("keeps higher tiers audible across a wider arena", function()
        local _, lowMax = ArenaSpatialAudioRules.rolloff("Low")
        local _, mediumMax = ArenaSpatialAudioRules.rolloff("Medium")
        local _, highMax = ArenaSpatialAudioRules.rolloff("High")

        expect(lowMax < mediumMax).toBe(true)
        expect(mediumMax < highMax).toBe(true)
    end)
end)

return nil
