--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local SoloRules = require("../../src/server/SoloRules")

describe("Solo Rush", function()
    it("activates for one player with shorter pacing", function()
        local rules = SoloRules.resolve(Config, 1)

        expect(rules.Solo).toBe(true)
        expect(rules.IntermissionSeconds < Config.IntermissionSeconds).toBe(true)
        expect(rules.VoteSeconds < Config.VoteSeconds).toBe(true)
        expect(rules.ReadySeconds <= Config.ReadySeconds).toBe(true)
        expect(rules.ReadySeconds >= 1).toBe(true)
        expect(rules.RoundSeconds < Config.RoundSeconds).toBe(true)
        expect(rules.PostRoundSeconds < Config.PostRoundSeconds).toBe(true)
    end)

    it("returns to normal rules when a second player is present", function()
        local rules = SoloRules.resolve(Config, 2)

        expect(rules.Solo).toBe(false)
        expect(rules.IntermissionSeconds).toBe(Config.IntermissionSeconds)
        expect(rules.VoteSeconds).toBe(Config.VoteSeconds)
        expect(rules.ReadySeconds).toBe(Config.ReadySeconds)
        expect(rules.RoundSeconds).toBe(Config.RoundSeconds)
        expect(rules.PostRoundSeconds).toBe(Config.PostRoundSeconds)
        expect(rules.WinCoinMultiplier).toBe(1)
        expect(rules.WinXPMultiplier).toBe(1)
    end)

    it("grants a meaningful solo survival bonus", function()
        local rules = SoloRules.resolve(Config, 1)
        local coins = SoloRules.reward(Config.WinCoins, rules.WinCoinMultiplier)
        local xp = SoloRules.reward(Config.WinXP, rules.WinXPMultiplier)

        expect(coins > Config.WinCoins).toBe(true)
        expect(xp > Config.WinXP).toBe(true)
        expect(coins).toBe(35)
        expect(xp).toBe(38)
    end)

    it("keeps solo Double Chaos cadence controlled", function()
        local rules = SoloRules.resolve(Config, 1)

        expect(rules.DoubleChaosEvery >= 3).toBe(true)
        expect(rules.DoubleChaosChance <= Config.DoubleChaosChance).toBe(true)
    end)
end)

return nil
