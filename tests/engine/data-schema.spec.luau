--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DataSchema = require("../../src/server/DataSchema")

describe("Player data schema", function()
    it("provides independent defaults", function()
        local a = DataSchema.cloneDefaults()
        local b = DataSchema.cloneDefaults()

        a.Coins = 999
        expect(b.Coins).toBe(0)
        expect(a.DataVersion).toBe(DataSchema.Version)
    end)

    it("normalizes legacy data while preserving valid fields", function()
        local data = DataSchema.normalize({
            Coins = 125,
            XP = 900,
            Wins = 4,
            Games = 11,
            OwnedCosmetics = "trail_blue",
            EquippedCosmetic = "trail_blue",
            UnlockedAchievements = "FIRST_SURVIVOR",
        })

        expect(data.Coins).toBe(125)
        expect(data.XP).toBe(900)
        expect(data.Wins).toBe(4)
        expect(data.Games).toBe(11)
        expect(data.OwnedCosmetics).toBe("trail_blue")
        expect(data.EquippedTrail).toBe("trail_blue")
        expect(data.EquippedAura).toBe("")
        expect(data.UnlockedAchievements).toBe("FIRST_SURVIVOR")
        expect(data.DataVersion).toBe(DataSchema.Version)
        expect(data.Level).toBe(DataSchema.levelForXP(900))
    end)

    it("migrates legacy aura equipment into the aura slot", function()
        local data = DataSchema.normalize({
            OwnedCosmetics = "aura_emerald",
            EquippedCosmetic = "aura_emerald",
        })

        expect(data.EquippedTrail).toBe("")
        expect(data.EquippedAura).toBe("aura_emerald")
        expect(data.DataVersion).toBe(DataSchema.Version)
    end)

    it("rejects invalid types and clamps negative counters", function()
        local data = DataSchema.normalize({
            Coins = -50,
            XP = -200,
            Wins = -3,
            Games = "bad",
            DailyStreak = -4,
        })

        expect(data.Coins).toBe(0)
        expect(data.XP).toBe(0)
        expect(data.Wins).toBe(0)
        expect(data.Games).toBe(0)
        expect(data.DailyStreak).toBe(0)
        expect(data.Level).toBe(1)
    end)

    it("builds a safe snapshot from attributes", function()
        local values = {
            Coins = 75,
            XP = 400,
            Games = 9,
            Quest1Claimed = true,
            OwnedCosmetics = "trail_blue,trail_gold,aura_emerald",
            EquippedTrail = "trail_gold",
            EquippedAura = "aura_emerald",
            ArenaMastery = "Classic=7",
            DisasterMastery = "Meteors=12",
            WeeklyChallengeWeek = 2800,
            Weekly1Id = "PLAY_20",
            Weekly1Progress = 7,
            Weekly1Claimed = false,
        }

        local snapshot = DataSchema.snapshot(function(key)
            return values[key]
        end)

        expect(snapshot.Coins).toBe(75)
        expect(snapshot.XP).toBe(400)
        expect(snapshot.Level).toBe(DataSchema.levelForXP(400))
        expect(snapshot.Games).toBe(9)
        expect(snapshot.Quest1Claimed).toBe(true)
        expect(snapshot.OwnedCosmetics).toBe("trail_blue,trail_gold,aura_emerald")
        expect(snapshot.EquippedTrail).toBe("trail_gold")
        expect(snapshot.EquippedAura).toBe("aura_emerald")
        expect(snapshot.ArenaMastery).toBe("Classic=7")
        expect(snapshot.DisasterMastery).toBe("Meteors=12")
        expect(snapshot.WeeklyChallengeWeek).toBe(2800)
        expect(snapshot.Weekly1Id).toBe("PLAY_20")
        expect(snapshot.Weekly1Progress).toBe(7)
        expect(snapshot.Weekly1Claimed).toBe(false)
        expect(snapshot.DataVersion).toBe(DataSchema.Version)
    end)

    it("uses bounded exponential retry delays", function()
        expect(DataSchema.retryDelay(1)).toBe(0.5)
        expect(DataSchema.retryDelay(2)).toBe(1)
        expect(DataSchema.retryDelay(3)).toBe(2)
        expect(DataSchema.retryDelay(4)).toBe(4)
        expect(DataSchema.retryDelay(8)).toBe(8)
    end)
end)

return nil
