--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaSpatialAudioRules = require("../../src/shared/ArenaSpatialAudioRules")
local ArenaVariants = require("../../src/server/ArenaVariants")
local AudioConfig = require("../../src/shared/AudioConfig")
local MapVisualReadiness = require("../../src/shared/MapVisualReadiness")

describe("Arena spatial audio rules", function()
    it("defines a profile for every arena", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local profile = ArenaSpatialAudioRules.profile(id)
            expect(type(profile.Bed)).toBe("string")
            expect(type(profile.Secondary)).toBe("string")
            expect(profile.Volume > 0).toBe(true)
            expect(profile.Radius > 0).toBe(true)
        end
    end)

    it("gives Storm Harbor a bounded, distinct shore-wind soundscape", function()
        local harbor = ArenaSpatialAudioRules.profile("Harbor")
        local classic = ArenaSpatialAudioRules.profile("Classic")
        expect(harbor ~= classic).toBe(true)
        expect(harbor.Bed).toBe("Wind")
        expect(harbor.Secondary).toBe("LowGravity")
        expect(harbor.Pitch ~= classic.Pitch).toBe(true)
        expect(harbor.EQ.Low ~= classic.EQ.Low).toBe(true)
        expect(harbor.Reverb.Decay ~= classic.Reverb.Decay).toBe(true)
        expect(AudioConfig.Sfx[harbor.Bed] ~= nil).toBe(true)
        expect(AudioConfig.Sfx[harbor.Secondary] ~= nil).toBe(true)
        expect(harbor.Volume > 0 and harbor.Volume <= 0.085).toBe(true)
        expect(harbor.SecondaryVolume > 0
            and harbor.SecondaryVolume <= 0.032).toBe(true)
        expect(harbor.Radius >= 44 and harbor.Radius <= 62).toBe(true)
        expect(ArenaSpatialAudioRules.profile("nonexistent")).toBe(classic)
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

    it("keeps spatial ambience silent when accessibility audio is muted", function()
        expect(ArenaSpatialAudioRules.muteScale(false)).toBe(1)
        expect(ArenaSpatialAudioRules.muteScale(nil)).toBe(1)
        expect(ArenaSpatialAudioRules.muteScale(true)).toBe(0)
    end)

    it("restores ambience readiness when Arena and Base replicate late", function()
        local generated = Instance.new("Folder")
        local observed = nil
        local events = 0
        local disconnect = MapVisualReadiness.watch(generated, "Arena", "Base", function(base)
            observed = base
            events += 1
        end)

        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        task.wait()

        local base = Instance.new("Part")
        base.Name = "Base"
        base.Parent = arena
        task.wait()
        expect(observed == base).toBe(true)

        local beforeVariant = events
        arena:SetAttribute("VariantId", "Orbital")
        task.wait()
        expect(events > beforeVariant).toBe(true)
        expect(observed == base).toBe(true)

        base:Destroy()
        task.wait()
        expect(observed == nil).toBe(true)

        disconnect()
        local beforeDisconnect = events
        arena:SetAttribute("VariantId", "Towers")
        task.wait()
        expect(events).toBe(beforeDisconnect)
        generated:Destroy()
    end)

end)

return nil
