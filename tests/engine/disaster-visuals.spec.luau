--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterVisuals = require("../../src/shared/DisasterVisuals")
local UITheme = require("../../src/shared/UITheme")
local DisasterBalance = require("../../src/server/DisasterBalance")
local HazardGlyphs = require("../../src/shared/HazardGlyphs")

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

    it("defines a bounded procedural glyph for every disaster", function()
        for id in pairs(DisasterVisuals.Profiles) do
            local recipe = HazardGlyphs.get(id)
            expect(recipe ~= nil).toBe(true)
            expect(#(recipe :: any) >= 3).toBe(true)
            expect(#(recipe :: any) <= 8).toBe(true)

            for _, segment in ipairs(recipe :: any) do
                expect(segment.X >= 0 and segment.X <= 1).toBe(true)
                expect(segment.Y >= 0 and segment.Y <= 1).toBe(true)
                expect(segment.Width > 0 and segment.Width <= 1).toBe(true)
                expect(segment.Height > 0 and segment.Height <= 1).toBe(true)
                expect(math.abs(segment.Rotation or 0) <= 180).toBe(true)
            end
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

    it("applies blackout brightness without darkening unrelated profiles", function()
        local blackout = DisasterVisuals.combine({"Darkness"})
        local lava = DisasterVisuals.combine({"RisingLava"})

        expect(blackout ~= nil).toBe(true)
        expect(lava ~= nil).toBe(true)
        expect((blackout :: any).Brightness < 0).toBe(true)
        expect((lava :: any).Brightness).toBe(0)
    end)

    it("blends blackout brightness for double chaos", function()
        local combined = DisasterVisuals.combine({"Darkness", "RisingLava"})
        expect(combined ~= nil).toBe(true)

        local brightness = (combined :: any).Brightness
        expect(brightness < 0).toBe(true)
        expect(brightness > -0.28).toBe(true)
    end)

    it("keeps every allowed Double Chaos pair visually distinct and bounded", function()
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

        local testedPairs = 0

        local function accentDistance(a, b)
            local dr = (a.R - b.R) * 255
            local dg = (a.G - b.G) * 255
            local db = (a.B - b.B) * 255
            return math.sqrt((dr * dr) + (dg * dg) + (db * db))
        end

        for i = 1, #ids do
            for j = i + 1, #ids do
                local aId = ids[i]
                local bId = ids[j]

                if DisasterBalance.compatible(aId, bId) then
                    local a = DisasterVisuals.get(aId)
                    local b = DisasterVisuals.get(bId)
                    local combined = DisasterVisuals.combine({aId, bId})

                    expect(a ~= nil).toBe(true)
                    expect(b ~= nil).toBe(true)
                    expect(combined ~= nil).toBe(true)

                    -- Prevent two simultaneously playable hazards from collapsing
                    -- into nearly the same primary warning/accent language.
                    expect(accentDistance((a :: any).Accent, (b :: any).Accent) >= 60).toBe(true)

                    local uiA = UITheme.disasterAccent(aId)
                    local uiB = UITheme.disasterAccent(bId)
                    expect(accentDistance(uiA, uiB) >= 50).toBe(true)

                    expect((combined :: any).Bloom <= 0.9).toBe(true)
                    expect((combined :: any).Contrast <= 0.22).toBe(true)
                    expect((combined :: any).Saturation <= 0.32).toBe(true)
                    expect((combined :: any).Density <= 0.28).toBe(true)
                    expect((combined :: any).Haze <= 1.5).toBe(true)
                    expect((combined :: any).Fov <= 84).toBe(true)

                    testedPairs += 1
                end
            end
        end

        expect(testedPairs >= 40).toBe(true)
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
