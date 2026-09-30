--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterVisuals = require("../../src/shared/DisasterVisuals")

describe("Disaster visual identities", function()
    it("defines a profile for every disaster", function()
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

        for _, id in ipairs(ids) do
            local profile = DisasterVisuals.get(id)
            expect(profile ~= nil).toBe(true)
            expect(profile.Bloom > 0).toBe(true)
            expect(profile.Fov >= 70).toBe(true)
            expect(profile.Fov <= 85).toBe(true)
        end
    end)

    it("returns nil for unknown disaster combinations", function()
        expect(DisasterVisuals.combine({"NotReal"}) == nil).toBe(true)
    end)

    it("preserves a single disaster profile", function()
        local base = DisasterVisuals.get("Freeze")
        local combined = DisasterVisuals.combine({"Freeze"})

        expect(combined ~= nil).toBe(true)
        expect((combined :: any).Bloom).toBe((base :: any).Bloom)
        expect((combined :: any).Fov).toBe((base :: any).Fov)
        expect((combined :: any).Accent).toBe((base :: any).Accent)
    end)

    it("blends two disasters within safe visual limits", function()
        local combined = DisasterVisuals.combine({"RisingLava", "LowGravity"})

        expect(combined ~= nil).toBe(true)
        expect((combined :: any).Bloom <= 0.9).toBe(true)
        expect((combined :: any).Contrast <= 0.22).toBe(true)
        expect((combined :: any).Saturation <= 0.32).toBe(true)
        expect((combined :: any).Density <= 0.28).toBe(true)
        expect((combined :: any).Haze <= 1.5).toBe(true)
        expect((combined :: any).Fov <= 84).toBe(true)
    end)
end)

return nil
