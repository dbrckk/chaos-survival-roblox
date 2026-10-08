--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterVisuals = require("../../src/shared/DisasterVisuals")
local UITheme = require("../../src/shared/UITheme")
local DisasterBalance = require("../../src/server/DisasterBalance")
local HazardGlyphs = require("../../src/shared/HazardGlyphs")
local ImpactSetpieceRules = require("../../src/shared/ImpactSetpieceRules")
local ImpactSetpiece = require("../../src/client/ImpactSetpiece")
local DisasterIntroGlyphKit = require("../../src/client/DisasterIntroGlyphKit")

describe("Disaster visual identities", function()
    it("assigns unique tiered impact accents only for meteor and bomb events", function()
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local meteor = ImpactSetpieceRules.get("Meteor", tier, false, 15)
            local bomb = ImpactSetpieceRules.get("Bomb", tier, false, 15)
            if tier == "Low" then
                expect(meteor == nil and bomb == nil).toBe(true)
            else
                expect(meteor ~= nil and bomb ~= nil).toBe(true)
                expect(meteor.Prefix ~= bomb.Prefix).toBe(true)
                expect(meteor.Material ~= bomb.Material).toBe(true)
                expect(meteor.Count <= 7).toBe(true)
                expect(bomb.Count <= 8).toBe(true)
            end
        end
        expect(ImpactSetpieceRules.get("Meteor", "High", true, 12) == nil).toBe(true)
        expect(ImpactSetpieceRules.get("Unknown", "High", false, 12) == nil).toBe(true)
        expect(ImpactSetpieceRules.get("Bomb", "High", false, 500).Radius).toBe(40)
        expect(ImpactSetpieceRules.get("Meteor", "High", false, -5).Radius).toBe(1)
    end)

    it("builds non-colliding meteor shards and bomb spokes with bounded geometry", function()
        local root = Instance.new("Folder")
        for _, case in ipairs({
            {kind = "Meteor", class = "WedgePart", name = "MeteorShard", count = 7},
            {kind = "Bomb", class = "Part", name = "BombPressureSpoke", count = 8},
        }) do
            local parts = ImpactSetpiece.spawn(root, {
                kind = case.kind,
                position = Vector3.new(0, 5, 0),
                color = Color3.fromRGB(255, 130, 75),
                radius = 11,
            }, "High", false, ImpactSetpieceRules)
            expect(parts ~= nil).toBe(true)
            expect(#parts:GetChildren()).toBe(case.count)
            for _, child in ipairs(parts:GetChildren()) do
                expect(child.ClassName).toBe(case.class)
                expect(child.Anchored).toBe(true)
                expect(child.CanCollide).toBe(false)
                expect(child.CanTouch).toBe(false)
                expect(child.CanQuery).toBe(false)
                expect(child.Size.Magnitude > 0).toBe(true)
                expect(string.find(child.Name, case.name, 1, true) ~= nil).toBe(true)
            end
            parts:Destroy()
        end
        expect(ImpactSetpiece.spawn(root, {kind = "Meteor"}, "High", false) == nil).toBe(true)
        expect(ImpactSetpiece.spawn(root, {
            kind = "Meteor", position = Vector3.zero, color = Color3.new(1, 1, 1),
        }, "Low", false, ImpactSetpieceRules) == nil).toBe(true)
        root:Destroy()
    end)

    it("keeps radial debris trajectories stable and physically bounded", function()
        for _, kind in ipairs({"Meteor", "Bomb"}) do
            for i = 1, 8 do
                local fragment = ImpactSetpieceRules.fragment(kind, i, 8, 25)
                expect(math.abs(fragment.Direction.Magnitude - 1) < 0.001).toBe(true)
                expect(fragment.EndRadius > fragment.StartRadius).toBe(true)
                expect(fragment.Lift >= 0).toBe(true)
                expect(fragment.Width > 0 and fragment.Length > 0).toBe(true)
            end
        end
    end)

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

describe("Eleven physical disaster intro glyphs", function()
    it("builds distinct bounded non-colliding marks at Low Medium and High", function()
        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 80)
        base.CFrame = CFrame.new(18, 5, -26)
            * CFrame.Angles(0, math.rad(27), 0)
        local variants = {
            "RisingLava", "Meteors", "LowGravity",
            "DisappearingPlatforms", "Tornado", "Freeze", "Bombs",
            "SpeedSurge", "Darkness", "ShrinkingArena", "JumpShock",
        }
        local signatures = {}
        for _, id in ipairs(variants) do
            local recipe = HazardGlyphs.get(id)
            local signature = ""
            for _, seg in ipairs(recipe) do
                signature ..= string.format("%.2f/%.2f/%.2f/%.2f;",
                    seg.X, seg.Y, seg.Width, seg.Rotation)
            end
            expect(signatures[signature] == nil).toBe(true)
            signatures[signature] = true
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local one = DisasterIntroGlyphKit.build(parent, base, id, tier, 1,
                    HazardGlyphs, DisasterVisuals)
                local two = DisasterIntroGlyphKit.build(parent, base, id, tier, 2,
                    HazardGlyphs, DisasterVisuals)
                expect(one ~= nil and two ~= nil).toBe(true)
                expect(one.folder.Name).toBe("ChaosDisasterIntro_" .. id)
                local expected = 1 + DisasterIntroGlyphKit.strokeCount(tier, #recipe)
                    + (tier == "High" and 2 or 0)
                expect(#one.parts).toBe(expected)
                expect(#two.parts).toBe(expected)
                expect((one.frame.Position - two.frame.Position).Magnitude > 20).toBe(true)
                local origin = base.CFrame:PointToObjectSpace(one.frame.Position)
                expect(origin.Z < -base.Size.Z * 0.5).toBe(true)
                for _, instance in ipairs(one.parts) do
                    expect(instance:GetAttribute("ChaosIntroSymbol")).toBe(true)
                    expect(instance.Anchored).toBe(true)
                    expect(instance.CanCollide).toBe(false)
                    expect(instance.CanTouch).toBe(false)
                    expect(instance.CanQuery).toBe(false)
                    if tier == "Low" then
                        expect(instance.Material == Enum.Material.Neon).toBe(false)
                    end
                end
                one.folder:Destroy()
                two.folder:Destroy()
            end
        end
        expect(#variants).toBe(11)
        parent:Destroy()
        base:Destroy()
    end)

    it("rejects unknown glyphs or invalid parent and signal slot", function()
        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        expect(DisasterIntroGlyphKit.build(parent, base, "Missing", "High", 1,
            HazardGlyphs, DisasterVisuals) == nil).toBe(true)
        expect(DisasterIntroGlyphKit.build(parent, base, "Bombs", "Low", 3,
            HazardGlyphs, DisasterVisuals) == nil).toBe(true)
        expect(DisasterIntroGlyphKit.build(parent, nil, "Bombs", "Low", 1,
            HazardGlyphs, DisasterVisuals) == nil).toBe(true)
        expect(DisasterIntroGlyphKit.build(nil, base, "Bombs", "Low", 1,
            HazardGlyphs, DisasterVisuals) == nil).toBe(true)
        parent:Destroy()
        base:Destroy()
    end)
end)

return nil
