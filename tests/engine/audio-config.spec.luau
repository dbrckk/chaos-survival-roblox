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

    it("only maps disaster loops to loopable sounds", function()
        for _, cueName in pairs(AudioConfig.DisasterLoop) do
            local cue = AudioConfig.Sfx[cueName]
            expect(cue ~= nil).toBe(true)
            expect(cue.Looped).toBe(true)
        end
    end)
end)

return nil
