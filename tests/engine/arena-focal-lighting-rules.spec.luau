--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaFocalLightingRules = require("../../src/shared/ArenaFocalLightingRules")
local ArenaFocalFixtureKit = require("../../src/client/ArenaFocalFixtureKit")
local VisualTheme = require("../../src/shared/VisualTheme")

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
        for _, id in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local definitions = ArenaFocalLightingRules.definitions(id)
            expect(#definitions >= 3).toBe(true)
            expect(definitions[1].Range > 0).toBe(true)
            expect(definitions[1].Angle > 0).toBe(true)
        end
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
    it("uses four noncolliding identities with mobile tier limits", function()
        local parent = Instance.new("Folder")
        local anchor = Instance.new("Part")
        anchor.CFrame = CFrame.new(12, 20, -18)
            * CFrame.Angles(math.rad(15), math.rad(39), math.rad(-12))
        anchor.Parent = parent
        local seen = {}
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
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
