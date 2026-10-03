--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterBalance = require("../../src/server/DisasterBalance")

describe("Disaster balance", function()
    it("blocks high-friction Double Chaos pairs", function()
        expect(DisasterBalance.compatible("Freeze", "SpeedSurge")).toBe(false)
        expect(DisasterBalance.compatible("Freeze", "Tornado")).toBe(false)
        expect(DisasterBalance.compatible("Tornado", "JumpShock")).toBe(false)
        expect(DisasterBalance.compatible("SpeedSurge", "DisappearingPlatforms")).toBe(false)
        expect(DisasterBalance.compatible("Freeze", "Meteors")).toBe(false)
        expect(DisasterBalance.compatible("Freeze", "Bombs")).toBe(false)
        expect(DisasterBalance.compatible("Freeze", "RisingLava")).toBe(false)
        expect(DisasterBalance.compatible("Freeze", "DisappearingPlatforms")).toBe(false)
        expect(DisasterBalance.compatible("Freeze", "ShrinkingArena")).toBe(false)
        expect(DisasterBalance.compatible("JumpShock", "ShrinkingArena")).toBe(false)
    end)

    it("allows distinct fairer combinations", function()
        expect(DisasterBalance.compatible("Meteors", "Darkness")).toBe(true)
        expect(DisasterBalance.compatible("Bombs", "LowGravity")).toBe(true)
        expect(DisasterBalance.compatible("RisingLava", "Darkness")).toBe(true)
        expect(DisasterBalance.compatible("Freeze", "Darkness")).toBe(true)
        expect(DisasterBalance.compatible("Freeze", "LowGravity")).toBe(true)
    end)

    it("keeps compatibility symmetric", function()
        expect(DisasterBalance.compatible("Freeze", "Meteors")).toBe(false)
        expect(DisasterBalance.compatible("Meteors", "Freeze")).toBe(false)
        expect(DisasterBalance.compatible("JumpShock", "ShrinkingArena")).toBe(false)
        expect(DisasterBalance.compatible("ShrinkingArena", "JumpShock")).toBe(false)
    end)

    it("never combines a disaster with itself", function()
        expect(DisasterBalance.compatible("Meteors", "Meteors")).toBe(false)
    end)

    it("keeps at least two safe fusion partners for every disaster", function()
        local ids = {
            "RisingLava",
            "Meteors",
            "LowGravity",
            "DisappearingPlatforms",
            "Tornado",
            "Freeze",
            "Bombs",
            "SpeedSurge",
            "Darkness",
            "ShrinkingArena",
            "JumpShock",
        }

        for _, primary in ipairs(ids) do
            local compatible = 0
            for _, candidate in ipairs(ids) do
                if DisasterBalance.compatible(primary, candidate) then
                    compatible += 1
                end
            end
            expect(compatible >= 2).toBe(true)
        end
    end)

    it("uses gentler profiles for low-population sessions", function()
        local solo = DisasterBalance.mobileProfile(1)
        local multi = DisasterBalance.mobileProfile(6)

        expect(solo.MeteorWarningSeconds > multi.MeteorWarningSeconds).toBe(true)
        expect(solo.MeteorDamage <= multi.MeteorDamage).toBe(true)
        expect(solo.BombDamage <= multi.BombDamage).toBe(true)
        expect(solo.MeteorRadius).toBe(multi.MeteorRadius)
        expect(solo.BombRadius).toBe(multi.BombRadius)
        expect(solo.FreezeSeconds <= multi.FreezeSeconds).toBe(true)
        expect(solo.TornadoForce <= multi.TornadoForce).toBe(true)
        expect(solo.SpeedMultiplier <= multi.SpeedMultiplier).toBe(true)
    end)

    it("filters incompatible candidates", function()
        local pool = {
            {Id = "Freeze"},
            {Id = "SpeedSurge"},
            {Id = "Tornado"},
            {Id = "Meteors"},
            {Id = "Darkness"},
        }

        local filtered = DisasterBalance.filterCompatible("Freeze", pool)
        local ids = {}
        for _, d in ipairs(filtered) do
            ids[d.Id] = true
        end

        expect(ids.Freeze == nil).toBe(true)
        expect(ids.SpeedSurge == nil).toBe(true)
        expect(ids.Tornado == nil).toBe(true)
        expect(ids.Meteors == nil).toBe(true)
        expect(ids.Darkness).toBe(true)
    end)
end)

return nil
