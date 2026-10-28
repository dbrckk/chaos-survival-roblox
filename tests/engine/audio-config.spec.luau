--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AudioConfig = require("../../src/shared/AudioConfig")
local AudioMixRules = require("../../src/shared/AudioMixRules")
local ImpactAudioRules = require("../../src/shared/ImpactAudioRules")

describe("Client-only spatial impact sound policy", function()
    it("scales three-dimensional impact detail down with distance and tier", function()
        for _, kind in ipairs({"Meteor", "Bomb"}) do
            local low = ImpactAudioRules.plan(kind, 20, "Low", false)
            local medium = ImpactAudioRules.plan(kind, 20, "Medium", false)
            local high = ImpactAudioRules.plan(kind, 20, "High", false)
            local middle = ImpactAudioRules.plan(kind, 60, "High", false)
            local far = ImpactAudioRules.plan(kind, 110, "High", false)
            expect(low.LayerCount).toBe(1)
            expect(medium.LayerCount).toBe(2)
            expect(high.LayerCount).toBe(3)
            expect(middle.LayerCount).toBe(2)
            expect(far.LayerCount).toBe(1)
            expect(high.MaxDistance <= 125).toBe(true)
            expect(middle.VolumeScale <= high.VolumeScale).toBe(true)
            expect(far.VolumeScale <= middle.VolumeScale).toBe(true)
            expect(high.Lifetime <= 3).toBe(true)
            expect(ImpactAudioRules.plan(kind, 130, "High", false) == nil).toBe(true)
            expect(ImpactAudioRules.plan(kind, 90, "Low", false) == nil).toBe(true)
            expect(ImpactAudioRules.plan(kind, 20, "High", true) == nil).toBe(true)
        end
    end)

    it("keeps both Double Chaos blast families audible without stacked peaks", function()
        local gate = ImpactAudioRules.gate
        local stamps = {}
        local first, firstScale = gate("Meteor", 100, stamps, "High")
        expect(first).toBe(true)
        expect(firstScale).toBe(1)
        stamps.Meteor = 100

        -- Two *different* blast signatures may occur on the same server step.
        local other, overlap = gate("Bomb", 100.02, stamps, "High")
        expect(other).toBe(true)
        expect(overlap).toBe(0.68)
        stamps.Bomb = 100.02

        local spam, volume = gate("Meteor", 100.05, stamps, "High")
        expect(spam).toBe(false)
        expect(volume).toBe(0)
        expect(gate("Bomb", 100.10, stamps, "High")).toBe(false)
        local later, full = gate("Meteor", 100.3, stamps, "High")
        expect(later).toBe(true)
        expect(full).toBe(1)

        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local last = {Bomb = 14.0}
            expect(gate("Bomb", 14.08, last, tier)).toBe(false)
            expect(gate("Meteor", 14.08, last, tier)).toBe(true)
            expect(gate("Meteor", 14.08, last, tier) == true).toBe(true)
        end
        expect(gate("Unknown", 10, stamps, "High")).toBe(false)
        expect(gate("Meteor", 0 / 0, stamps, "High")).toBe(false)
        expect(gate("Meteor", math.huge, stamps, "High")).toBe(false)
        expect(gate("Meteor", -1, stamps, "High")).toBe(false)
        expect(gate("Meteor", 10, nil, "High")).toBe(false)
    end)

    it("rejects unknown impact types and invalid listener distances", function()
        expect(ImpactAudioRules.plan("Unknown", 5, "High", false) == nil).toBe(true)
        expect(ImpactAudioRules.plan("Meteor", -1, "High", false) == nil).toBe(true)
        expect(ImpactAudioRules.plan("Meteor", nil, "High", false) == nil).toBe(true)
        expect(ImpactAudioRules.plan("Meteor", 0, "NoTier", false).LayerCount).toBe(1)
    end)
end)

describe("Persistent independent music/effects mix", function()
    it("keeps existing players at 100 percent without breaking global mute", function()
        expect(AudioMixRules.percent(nil)).toBe(100)
        expect(AudioMixRules.percent("75")).toBe(100)
        expect(AudioMixRules.percent(math.huge)).toBe(100)
        expect(AudioMixRules.percent(0/0)).toBe(100)
        local music, effects = AudioMixRules.gains(false, nil, nil)
        expect(music).toBe(1)
        expect(effects).toBe(1)
        local mutedMusic, mutedEffects = AudioMixRules.gains(true, 100, 100)
        expect(mutedMusic).toBe(0)
        expect(mutedEffects).toBe(0)
    end)

    it("keeps buses independent and obeys safety clamping", function()
        local music, effects = AudioMixRules.gains(false, 25, 80)
        expect(music).toBe(0.25)
        expect(effects).toBe(0.8)
        local musicZero, effectsFull = AudioMixRules.gains(false, 0, 100)
        expect(musicZero).toBe(0)
        expect(effectsFull).toBe(1)
        expect(AudioMixRules.percent(-10)).toBe(0)
        expect(AudioMixRules.percent(500)).toBe(100)
        expect(AudioMixRules.percent(55.7)).toBe(56)
    end)

    it("server accepts only well-formed integral values in 0..100", function()
        for _, volume in ipairs({0, 10, 45, 90, 100}) do
            expect(AudioMixRules.validServerVolume(volume)).toBe(true)
        end
        for _, value in ipairs({-1, 101, 1.2, math.huge, -math.huge, "50", true}) do
            expect(AudioMixRules.validServerVolume(value)).toBe(false)
        end
        expect(AudioMixRules.validServerVolume(nil)).toBe(false)
        expect(AudioMixRules.validServerVolume(0/0)).toBe(false)
    end)
end)

describe("Audio configuration", function()
    it("uses a low-volume looping background track", function()
        local lobby = AudioConfig.Music.Lobby
        expect(type(lobby.SoundId)).toBe("string")
        expect(string.find(lobby.SoundId, "rbxasset") ~= nil).toBe(true)
        expect(lobby.Volume > 0).toBe(true)
        expect(lobby.Volume <= 0.2).toBe(true)
        expect(lobby.Looped).toBe(true)
    end)

    it("defines all critical gameplay cues", function()
        local required = {
            "UISelect",
            "Vote",
            "Countdown",
            "Ready",
            "RoundStart",
            "DoubleChaos",
            "LastSurvivor",
            "Survived",
            "Eliminated",
            "Hit",
            "Reward",
            "LevelUp",
        }

        for _, name in ipairs(required) do
            local cue = AudioConfig.Sfx[name]
            expect(cue ~= nil).toBe(true)
            expect(type(cue.SoundId)).toBe("string")
            expect((cue.Volume or 0) > 0).toBe(true)
            expect((cue.Volume or 0) <= 0.7).toBe(true)
        end
    end)

    it("keeps composite cue layers valid", function()
        local requiredComposite = {
            "Ready",
            "RoundStart",
            "DoubleChaos",
            "FinalRush",
            "Survived",
            "Eliminated",
            "LevelUp",
            "MasterRound",
            "GoldenShard",
        }

        for _, cueName in ipairs(requiredComposite) do
            local layers = AudioConfig.Composite[cueName]
            expect(type(layers)).toBe("table")
            expect(#layers >= 2).toBe(true)

            for _, layer in ipairs(layers) do
                expect(type(layer.Sound)).toBe("string")
                expect(AudioConfig.Sfx[layer.Sound] ~= nil).toBe(true)
                expect((tonumber(layer.Delay) or 0) >= 0).toBe(true)
                expect((tonumber(layer.VolumeScale) or 1) > 0).toBe(true)
            end
        end
    end)

    it("gives every disaster accent a layered signature", function()
        for _, cueName in pairs(AudioConfig.DisasterAccent) do
            local layers = AudioConfig.Composite[cueName]
            expect(type(layers)).toBe("table")
            expect(#layers >= 2).toBe(true)

            for _, layer in ipairs(layers) do
                expect(AudioConfig.Sfx[layer.Sound] ~= nil).toBe(true)
                expect((tonumber(layer.VolumeScale) or 1) > 0).toBe(true)
            end
        end
    end)

    it("keeps every disaster primary cue audibly distinguishable", function()
        local seenCueNames = {}
        local entries = {}

        for disasterId, cueName in pairs(AudioConfig.DisasterAccent) do
            expect(type(disasterId)).toBe("string")
            expect(type(cueName)).toBe("string")
            expect(seenCueNames[cueName] == nil).toBe(true)
            seenCueNames[cueName] = disasterId

            local cue = AudioConfig.Sfx[cueName]
            expect(cue ~= nil).toBe(true)

            table.insert(entries, {
                disasterId = disasterId,
                cueName = cueName,
                soundId = cue.SoundId,
                playbackSpeed = tonumber(cue.PlaybackSpeed) or 1,
            })
        end

        expect(#entries).toBe(11)

        for i = 1, #entries do
            for j = i + 1, #entries do
                local a = entries[i]
                local b = entries[j]

                if a.soundId == b.soundId then
                    -- Shared stock source files are acceptable only when their
                    -- primary pitch identity stays clearly separated.
                    expect(math.abs(a.playbackSpeed - b.playbackSpeed) >= 0.12).toBe(true)
                end
            end
        end
    end)

    it("keeps mobility pad feedback layered but bounded", function()
        local layers = AudioConfig.Composite.MobilityPad
        expect(type(layers)).toBe("table")
        expect(#layers >= 2).toBe(true)
        expect(#layers <= 4).toBe(true)
        for _, layer in ipairs(layers) do
            expect(AudioConfig.Sfx[layer.Sound] ~= nil).toBe(true)
        end
    end)

    it("keeps spectral cue treatments within safe effect ranges", function()
        for cueName, treatment in pairs(AudioConfig.Treatment or {}) do
            expect(AudioConfig.Sfx[cueName] ~= nil).toBe(true)

            local eq = treatment.EQ
            if eq then
                expect((tonumber(eq.Low) or 0) >= -20).toBe(true)
                expect((tonumber(eq.Low) or 0) <= 10).toBe(true)
                expect((tonumber(eq.Mid) or 0) >= -20).toBe(true)
                expect((tonumber(eq.Mid) or 0) <= 10).toBe(true)
                expect((tonumber(eq.High) or 0) >= -20).toBe(true)
                expect((tonumber(eq.High) or 0) <= 10).toBe(true)
            end

            local reverb = treatment.Reverb
            if reverb then
                expect((tonumber(reverb.Wet) or -24) >= -80).toBe(true)
                expect((tonumber(reverb.Wet) or -24) <= 10).toBe(true)
                expect((tonumber(reverb.Dry) or 0) >= -80).toBe(true)
                expect((tonumber(reverb.Dry) or 0) <= 10).toBe(true)
                expect((tonumber(reverb.Decay) or 0.5) >= 0.1).toBe(true)
                expect((tonumber(reverb.Decay) or 0.5) <= 20).toBe(true)
                expect((tonumber(reverb.Density) or 0.7) >= 0).toBe(true)
                expect((tonumber(reverb.Density) or 0.7) <= 1).toBe(true)
                expect((tonumber(reverb.Diffusion) or 0.8) >= 0).toBe(true)
                expect((tonumber(reverb.Diffusion) or 0.8) <= 1).toBe(true)
            end
        end
    end)

    it("uses deterministic disaster loop priorities", function()
        local seen = {}
        for disasterId, cueName in pairs(AudioConfig.DisasterLoop) do
            local priority = AudioConfig.DisasterLoopPriority[disasterId]
            expect(type(priority)).toBe("number")
            expect(priority > 0).toBe(true)
            expect(seen[priority] == nil).toBe(true)
            seen[priority] = disasterId

            local cue = AudioConfig.Sfx[cueName]
            expect(cue ~= nil).toBe(true)
            expect(cue.Looped).toBe(true)
        end
    end)

    it("keeps double-chaos accent layering deliberately lightweight", function()
        local policy = AudioConfig.DoubleChaosAccent
        expect(type(policy)).toBe("table")
        expect((tonumber(policy.VolumeScale) or 0) > 0).toBe(true)
        expect((tonumber(policy.VolumeScale) or 1) <= 0.60).toBe(true)
        expect((tonumber(policy.PitchVariance) or 0) >= 0).toBe(true)
        expect((tonumber(policy.PitchVariance) or 1) <= 0.04).toBe(true)
        expect((tonumber(policy.StaggerSeconds) or 0) >= 0.03).toBe(true)
        expect((tonumber(policy.StaggerSeconds) or 1) <= 0.10).toBe(true)
    end)

    it("keeps disaster ambience crossfades short and readable", function()
        local seconds = tonumber(AudioConfig.LoopCrossfadeSeconds) or 0
        expect(seconds >= 0.05).toBe(true)
        expect(seconds <= 0.40).toBe(true)
    end)

    it("only maps disaster loops to loopable sounds", function()
        for _, cueName in pairs(AudioConfig.DisasterLoop) do
            local cue = AudioConfig.Sfx[cueName]
            expect(cue ~= nil).toBe(true)
            expect(cue.Looped).toBe(true)
        end
    end)
end)

return nil
