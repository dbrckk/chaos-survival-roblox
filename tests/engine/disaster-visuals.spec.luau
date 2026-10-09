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
local MeteorSignatureRules = require("../../src/shared/MeteorSignatureRules")
local ImpactPulseRules = require("../../src/shared/ImpactPulseRules")
local CinematicPulseRingKit = require("../../src/client/CinematicPulseRingKit")

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
                expect(ImpactSetpieceRules.finishCount("Meteor", tier, false) <= 4).toBe(true)
                expect(ImpactSetpieceRules.finishCount("Bomb", tier, false) <= 4).toBe(true)
            end
        end
        expect(ImpactSetpieceRules.get("Meteor", "High", true, 12) == nil).toBe(true)
        expect(ImpactSetpieceRules.finishCount("Meteor", "High", true)).toBe(0)
        expect(ImpactSetpieceRules.finishCount("Bomb", "Low", false)).toBe(0)
        expect(ImpactSetpieceRules.finishCount("Unknown", "High", false)).toBe(0)
        expect(ImpactSetpieceRules.get("Unknown", "High", false, 12) == nil).toBe(true)
        expect(ImpactSetpieceRules.get("Bomb", "High", false, 500).Radius).toBe(40)
        expect(ImpactSetpieceRules.get("Meteor", "High", false, -5).Radius).toBe(1)
    end)

    it("builds non-colliding meteor shards and bomb spokes with bounded geometry", function()
        local root = Instance.new("Folder")
        for _, case in ipairs({
            {kind = "Meteor", class = "WedgePart", name = "MeteorShard",
                finish = "MeteorCraterRim", count = 7, finishClass = "WedgePart"},
            {kind = "Bomb", class = "Part", name = "BombPressureSpoke",
                finish = "BombPressureArc", count = 8, finishClass = "Part"},
        }) do
            local parts = ImpactSetpiece.spawn(root, {
                kind = case.kind,
                position = Vector3.new(0, 5, 0),
                color = Color3.fromRGB(255, 130, 75),
                radius = 11,
            }, "High", false, ImpactSetpieceRules)
            expect(parts ~= nil).toBe(true)
            expect(#parts:GetChildren()).toBe(case.count + 4)
            local shards = 0
            local finishes = 0
            for _, child in ipairs(parts:GetChildren()) do
                if string.find(child.Name, case.name, 1, true) then
                    shards += 1
                    expect(child.ClassName).toBe(case.class)
                else
                    finishes += 1
                    expect(string.find(child.Name, case.finish, 1, true) ~= nil).toBe(true)
                    expect(child.ClassName).toBe(case.finishClass)
                    expect(child.Material == Enum.Material.Neon).toBe(false)
                end
                expect(child.Anchored).toBe(true)
                expect(child.CanCollide).toBe(false)
                expect(child.CanTouch).toBe(false)
                expect(child.CanQuery).toBe(false)
                expect(child.Size.Magnitude > 0).toBe(true)
            end
            expect(shards).toBe(case.count)
            expect(finishes).toBe(4)
            parts:Destroy()
        end
        expect(ImpactSetpiece.spawn(root, {kind = "Meteor"}, "High", false) == nil).toBe(true)
        expect(ImpactSetpiece.spawn(root, {
            kind = "Meteor", position = Vector3.zero, color = Color3.new(1, 1, 1),
        }, "Low", false, ImpactSetpieceRules) == nil).toBe(true)
        root:Destroy()
    end)

    it("keeps mechanical impact finish paths within deterministic material budgets", function()
        for _, kind in ipairs({"Meteor", "Bomb"}) do
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local total = ImpactSetpieceRules.finishCount(kind, tier, false)
                if tier == "Low" then
                    expect(total).toBe(0)
                elseif tier == "Medium" then
                    expect(total).toBe(2)
                else
                    expect(total).toBe(4)
                end
                for i = 1, total do
                    local fragment = ImpactSetpieceRules.finish(kind, i, total, 17)
                    expect(fragment.Direction.Magnitude > 0.99).toBe(true)
                    expect(fragment.EndRadius > fragment.StartRadius).toBe(true)
                    expect(fragment.Lift >= 0).toBe(true)
                    expect(fragment.Height > 0 and fragment.Width > 0).toBe(true)
                end
            end
        end
        expect(ImpactSetpieceRules.finish("Unknown", 1, 4, 20) == nil).toBe(true)
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

describe("Bounded active meteor signatures", function()
    it("caps comet trails at zero/three/six for low/mobile and high visuals", function()
        local r = MeteorSignatureRules
        expect(r.profile("Low", false).MaxTrails).toBe(0)
        expect(r.profile("Medium", false).MaxTrails).toBe(3)
        expect(r.profile("High", false).MaxTrails).toBe(6)
        expect(r.profile("High", true).MaxTrails).toBe(0)
        expect(r.profile("Unknown", false).MaxTrails).toBe(0)
        local viewer = Vector3.new(0, 8, 0)
        local meteor = Vector3.new(0, 10, 35)
        expect(r.shouldTrail("round", true, viewer, meteor,
            "Medium", false, 0)).toBe(true)
        expect(r.shouldTrail("round", true, viewer, meteor,
            "Medium", false, 3)).toBe(false)
        expect(r.shouldTrail("round", true, viewer, meteor,
            "High", false, 5)).toBe(true)
        expect(r.shouldTrail("round", true, viewer, meteor,
            "High", false, 6)).toBe(false)
        expect(r.shouldTrail("round", true, viewer,
            Vector3.new(0, 0, 150), "Medium", false, 0)).toBe(false)
        expect(r.shouldTrail("round", true, viewer,
            Vector3.new(0, 0, 150), "High", false, 0)).toBe(true)
        expect(r.shouldTrail("round", false, viewer, meteor,
            "High", false, 0)).toBe(false)
        expect(r.shouldTrail("waiting", true, viewer, meteor,
            "High", false, 0)).toBe(false)
        expect(r.shouldTrail("round", true, viewer, meteor,
            "High", true, 0)).toBe(false)
        expect(r.shouldTrail("round", true, nil, meteor,
            "High", false, 0)).toBe(false)
    end)

    it("orders only valid, live meteor parts by camera proximity", function()
        local folder = Instance.new("Folder")
        local children = {}
        for _, data in ipairs({
            {"RoundMeteor", 55}, {"RoundMeteor", 5}, {"RoundMeteor", 25},
            {"OtherHazard", 1}, {"RoundMeteor", 100},
        }) do
            local part = Instance.new("Part")
            part.Name = data[1]
            part.Position = Vector3.new(data[2], 0, 0)
            part.Parent = folder
            table.insert(children, part)
        end
        local ordered = MeteorSignatureRules.orderedCandidates(children, Vector3.zero)
        expect(#ordered).toBe(4)
        expect(ordered[1].Distance).toBe(5)
        expect(ordered[2].Distance).toBe(25)
        expect(ordered[3].Distance).toBe(55)
        expect(ordered[4].Distance).toBe(100)
        expect(#MeteorSignatureRules.orderedCandidates(children, nil)).toBe(0)
        expect(#MeteorSignatureRules.orderedCandidates(nil, Vector3.zero)).toBe(0)
        folder:Destroy()
    end)
end)

describe("Hollow kinetic shockwaves in dense meteor and bomb impacts", function()
    it("limits wave bursts by tier, nearest distance, reduction and concurrency", function()
        local rules = ImpactPulseRules
        expect(rules.profile("Low", false).Concurrent).toBe(2)
        expect(rules.profile("Medium", false).Concurrent).toBe(3)
        expect(rules.profile("High", false).Concurrent).toBe(4)
        expect(rules.profile("High", true).Concurrent).toBe(1)
        expect(rules.pulse("Low", false, 45, 2, "Bomb") ~= nil).toBe(true)
        expect(rules.pulse("Low", false, 45, 3, "Bomb") == nil).toBe(true)
        expect(rules.pulse("Medium", false, 104, 3, "Meteor") ~= nil).toBe(true)
        expect(rules.pulse("Medium", false, 106, 1, "Meteor") == nil).toBe(true)
        expect(rules.pulse("High", false, 140, 4, "Bomb") ~= nil).toBe(true)
        expect(rules.pulse("High", false, 141, 1, "Bomb") == nil).toBe(true)
        expect(rules.pulse("High", false, 50, 5, "Bomb") == nil).toBe(true)
        expect(rules.pulse("High", true, 30, 1, "Bomb") ~= nil).toBe(true)
        expect(rules.pulse("High", true, 50, 1, "Bomb") == nil).toBe(true)
        expect(rules.pulse("High", false, nil, 1, "Bomb") == nil).toBe(true)
        expect(rules.pulse("High", false, 5, 1, "Unsupported") == nil).toBe(true)
        local meteor = rules.pulse("High", false, 16, 1, "Meteor")
        local bomb = rules.pulse("High", false, 16, 1, "Bomb")
        expect(meteor.Name ~= bomb.Name).toBe(true)
        expect(meteor.Duration < bomb.Duration).toBe(true)
        expect(meteor.Scale < bomb.Scale).toBe(true)
    end)

    it("builds strictly hollow and non-physical shockwaves within a multi-impact budget", function()
        local folder = Instance.new("Folder")
        local frame = CFrame.new(10, 4, 12)
        local color = Color3.fromRGB(255, 128, 70)
        local count = 0
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local recipe = ImpactPulseRules.pulse(tier, false, 12, 1, "Meteor")
            local pieces = CinematicPulseRingKit.emit(
                folder, recipe.Name, frame, color, 1, 22 * recipe.Scale,
                recipe.Duration, tier, false, recipe.Alpha
            )
            expect(#pieces).toBe(CinematicPulseRingKit.segmentCount(tier))
            for _, part in ipairs(pieces) do
                expect(part:IsA("Part")).toBe(true)
                expect(part.Shape).toBe(Enum.PartType.Block)
                expect(part.CanCollide).toBe(false)
                expect(part.CanTouch).toBe(false)
                expect(part.CanQuery).toBe(false)
                expect(part.CastShadow).toBe(false)
                expect(part.Size.Y < 0.08).toBe(true)
                expect(part.Transparency >= 0.25).toBe(true)
                part:Destroy()
            end
            count += 1
        end
        expect(count).toBe(3)
        expect(#folder:GetChildren()).toBe(0)
        folder:Destroy()
    end)
end)

return nil
