--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaFocalLightingRules = require("../../src/shared/ArenaFocalLightingRules")
local ArenaLightingReadabilityRules = require("../../src/shared/ArenaLightingReadabilityRules")
local ArenaFocalFixtureKit = require("../../src/client/ArenaFocalFixtureKit")
local VisualTheme = require("../../src/shared/VisualTheme")

describe("Five-arena physically readable environment lighting", function()
    it("improves low and medium indirect environment visibility without extra instances", function()
        local low, lowExposure = ArenaLightingReadabilityRules.identityScale("Low")
        local medium, mediumExposure = ArenaLightingReadabilityRules.identityScale("Medium")
        local high, highExposure = ArenaLightingReadabilityRules.identityScale("High")
        expect(low).toBe(0.84)
        expect(medium).toBe(0.94)
        expect(high).toBe(1)
        expect(lowExposure).toBe(0.80)
        expect(mediumExposure).toBe(1)
        expect(highExposure).toBe(1)
    end)

    it("keeps readable material bounce and toned-down specular during READY and rounds", function()
        local expected = {
            Low = {ready=0.56, round=0.53, specular=0.54},
            Medium = {ready=0.54, round=0.51, specular=0.63},
            High = {ready=0.52, round=0.49, specular=0.70},
        }
        for tier, values in pairs(expected) do
            local readyExposure, readyDiffuse, _, readyDark =
                ArenaLightingReadabilityRules.disasterLighting(
                    "ready", tier, false, {"RisingLava"})
            local roundExposure, roundDiffuse, roundSpecular, roundDark =
                ArenaLightingReadabilityRules.disasterLighting(
                    "round", tier, false, {"RisingLava"})
            expect(readyExposure).toBe(0.04)
            expect(roundExposure).toBe(0.02)
            expect(readyDiffuse).toBe(values.ready)
            expect(roundDiffuse).toBe(values.round)
            expect(roundSpecular).toBe(values.specular)
            expect(readyDark).toBe(false)
            expect(roundDark).toBe(false)
            expect(roundDiffuse > 0.34).toBe(true)
        end
    end)

    it("preserves Darkness even when it is secondary in Double Chaos", function()
        local expected = {Low=0.26, Medium=0.25, High=0.24}
        for tier, limit in pairs(expected) do
            local exposure, diffuse, specular, dark =
                ArenaLightingReadabilityRules.disasterLighting(
                    "round", tier, true, {"RisingLava", "Darkness"})
            expect(exposure).toBe(-0.04)
            expect(diffuse).toBe(limit)
            expect(diffuse < 0.34).toBe(true)
            expect(specular < 0.50).toBe(true)
            expect(dark).toBe(true)
            local primaryExposure, primaryDiffuse, _, primaryDark =
                ArenaLightingReadabilityRules.disasterLighting(
                    "round", tier, false, {"Darkness"})
            expect(primaryExposure).toBe(0.02)
            expect(primaryDiffuse).toBe(limit)
            expect(primaryDark).toBe(true)
        end
        expect(ArenaLightingReadabilityRules.hasDarkness({"Darkness"})).toBe(true)
        expect(ArenaLightingReadabilityRules.hasDarkness({"Tornado", "Darkness"})).toBe(true)
        expect(ArenaLightingReadabilityRules.hasDarkness({"Tornado"})).toBe(false)
        expect(ArenaLightingReadabilityRules.hasDarkness(nil)).toBe(false)
    end)

    it("preserves the correct source owner outside disaster rounds", function()
        expect(ArenaLightingReadabilityRules.disasterLighting("result", "Low"))
            .toBe(nil)
        expect(ArenaLightingReadabilityRules.disasterLighting("waiting", "High"))
            .toBe(nil)
        local _, standardDiffuse =
            ArenaLightingReadabilityRules.disasterLighting(
                "round", "Medium", false, {"Meteors"})
        local _, doubleDiffuse =
            ArenaLightingReadabilityRules.disasterLighting(
                "round", "Medium", true, {"Meteors", "Tornado"})
        expect(doubleDiffuse < standardDiffuse).toBe(true)
        expect(doubleDiffuse >= 0.45).toBe(true)
    end)
end)

describe("Arena focal lighting rules", function()
    it("keeps focal lights disabled on low quality", function()
        expect(ArenaFocalLightingRules.sourceCount("Low")).toBe(0)
        expect(ArenaFocalLightingRules.sourceCount("Medium")).toBe(2)
        expect(ArenaFocalLightingRules.sourceCount("High")).toBe(3)
    end)

    it("uses restrained physical housings with no extra light sources", function()
        expect(ArenaFocalLightingRules.fixtureParts("Low")).toBe(0)
        expect(ArenaFocalLightingRules.fixtureParts("Medium")).toBe(1)
        expect(ArenaFocalLightingRules.fixtureParts("High")).toBe(2)
        local low = ArenaFocalLightingRules.fixtureParts("Low")
            * ArenaFocalLightingRules.sourceCount("Low")
        local high = ArenaFocalLightingRules.fixtureParts("High")
            * ArenaFocalLightingRules.sourceCount("High")
        expect(low).toBe(0)
        expect(high <= 6).toBe(true)
    end)

    it("defines three focal candidates for every arena", function()
        for _, id in ipairs({"Classic", "Towers", "Crossroads", "Orbital", "Harbor"}) do
            local definitions = ArenaFocalLightingRules.definitions(id)
            expect(#definitions >= 3).toBe(true)
            expect(definitions[1].Range > 0).toBe(true)
            expect(definitions[1].Angle > 0).toBe(true)
            -- A real tilted and shrinking rectangular deck changes
            -- spotlight placement, not the number of GPU light sources.
            local base = CFrame.new(12, 20, -8)
                * CFrame.Angles(math.rad(12), math.rad(24), math.rad(-8))
            local largeSize = Vector3.new(146, 3.5, 102)
            local smallSize = Vector3.new(82, 3.5, 58)
            local start = ArenaFocalLightingRules.anchorFrame(
                base, largeSize, definitions[1]
            )
            local shrunk = ArenaFocalLightingRules.anchorFrame(
                base, smallSize, definitions[1]
            )
            local expected = Vector3.new(
                math.clamp(definitions[1].Offset.X, -1, 1) * 73 * 0.62,
                definitions[1].Offset.Y,
                math.clamp(definitions[1].Offset.Z, -1, 1) * 51 * 0.62
            )
            expect(typeof(start)).toBe("CFrame")
            expect(typeof(shrunk)).toBe("CFrame")
            expect((base:PointToObjectSpace(start.Position) - expected).Magnitude
                < 0.001).toBe(true)
            expect(start.Position ~= shrunk.Position).toBe(true)
            expect(ArenaFocalLightingRules.anchorFrame(nil, largeSize,
                definitions[1]) == nil).toBe(true)
            -- Existing fixtures must illuminate an actual reachable
            -- 320-stud arena surface instead of aiming past their range.
            for _, fixture in ipairs(definitions) do
                local frame = ArenaFocalLightingRules.anchorFrame(
                    CFrame.identity, Vector3.new(320, 3.5, 320), fixture)
                local target = Vector3.new(
                    math.clamp(fixture.Offset.X, -1, 1) * 160 * 0.42,
                    4,
                    math.clamp(fixture.Offset.Z, -1, 1) * 160 * 0.42
                )
                expect(typeof(frame)).toBe("CFrame")
                expect((frame.Position - target).Magnitude
                    <= fixture.Range * 0.73).toBe(true)
                expect(math.abs(frame.Position.X) <= 160).toBe(true)
                expect(math.abs(frame.Position.Z) <= 160).toBe(true)
                expect(frame.LookVector:Dot(
                    (target - frame.Position).Unit) > 0.999).toBe(true)
            end
        end
    end)

    it("does not retween unchanged lights on round countdown ticks", function()
        local changed = ArenaFocalLightingRules.visualStateChanged
        expect(changed("ready", false, {"Meteors"}, "ready", false,
            {"Meteors"})).toBe(false)
        expect(changed("round", false, {"Meteors", "Bombs"},
            "round", false, {"Meteors", "Bombs"})).toBe(false)
        expect(changed("round", false, {"Meteors"},
            "round", true, {"Meteors"})).toBe(true)
        expect(changed("ready", false, {"Meteors"},
            "round", false, {"Meteors"})).toBe(true)
        expect(changed("round", false, {"Meteors"},
            "round", false, {"Bombs"})).toBe(true)
        expect(changed("round", false, {"Meteors"},
            "round", false, {"Meteors", "Bombs"})).toBe(true)
        expect(changed("round", false, {"Meteors", "Bombs"},
            "round", false, {"Bombs", "Meteors"})).toBe(true)
        expect(changed("waiting", false, nil, "waiting", false, {})).toBe(false)
        expect(changed("waiting", false, false, "waiting", false,
            "unexpected")).toBe(false)
    end)

    it("suppresses decorative lighting during high gameplay pressure", function()
        local ready = ArenaFocalLightingRules.phaseScale("ready", false)
        local round = ArenaFocalLightingRules.phaseScale("round", false)
        local rush = ArenaFocalLightingRules.phaseScale("round", true)

        expect(round < ready).toBe(true)
        expect(rush < round).toBe(true)
        expect(ArenaFocalLightingRules.phaseScale("waiting", false)).toBe(0)
    end)
end)


describe("Motivated physical focal light fixtures", function()
    it("uses five noncolliding identities with mobile tier limits", function()
        local parent = Instance.new("Folder")
        local anchor = Instance.new("Part")
        anchor.CFrame = CFrame.new(12, 20, -18)
            * CFrame.Angles(math.rad(15), math.rad(39), math.rad(-12))
        anchor.Parent = parent
        local seen = {}
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital", "Harbor"}) do
            local names = ArenaFocalFixtureKit.names(variant)
            expect(#names).toBe(2)
            expect(seen[names[1]] == nil).toBe(true)
            seen[names[1]] = true
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local parts = ArenaFocalFixtureKit.build(
                    parent, anchor, variant, tier, VisualTheme.arena(variant), 7
                )
                expect(#parts).toBe(ArenaFocalLightingRules.fixtureParts(tier))
                for i, part in ipairs(parts) do
                    expect(part.Name).toBe(names[i] .. "7")
                    expect(part:GetAttribute("ChaosFocalFixture")).toBe(true)
                    expect(part:GetAttribute("ArenaVariant")).toBe(variant)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part.Material == Enum.Material.Neon).toBe(false)
                    expect((part.Position - anchor.Position).Magnitude < 2).toBe(true)
                    expect(#part:GetChildren()).toBe(0)
                    part:Destroy()
                end
            end
        end
        expect(#parent:GetChildren()).toBe(1)
        anchor:Destroy()
        parent:Destroy()
    end)
    it("does not create orphaned or invalid pieces", function()
        local parent = Instance.new("Folder")
        local anchor = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaFocalFixtureKit.build(nil, anchor, "Classic", "High", theme, 1)).toBe(0)
        expect(#ArenaFocalFixtureKit.build(parent, nil, "Classic", "High", theme, 1)).toBe(0)
        expect(#ArenaFocalFixtureKit.build(parent, anchor, "Unknown", "High", theme, 1)).toBe(0)
        expect(#ArenaFocalFixtureKit.build(parent, anchor, "Classic", "Unknown", theme, 1)).toBe(0)
        expect(#ArenaFocalFixtureKit.build(parent, anchor, "Classic", "High", nil, 1)).toBe(0)
        expect(#ArenaFocalFixtureKit.build(parent, anchor, "Classic", "High", theme, 0)).toBe(0)
        expect(#parent:GetChildren()).toBe(0)
        anchor:Destroy()
        parent:Destroy()
    end)
end)

return nil
