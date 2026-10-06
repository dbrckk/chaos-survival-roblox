--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AudioConfig = require("../../src/shared/AudioConfig")

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
