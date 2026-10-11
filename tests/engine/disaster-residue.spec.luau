--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterResidue = require("../../src/shared/DisasterResidue")
local AftermathSurfaceKit = require("../../src/client/AftermathSurfaceKit")
local ImpactSurfaceScarKit = require("../../src/client/ImpactSurfaceScarKit")
local VisualTheme = require("../../src/shared/VisualTheme")
local DisasterAftermathTone = require("../../src/shared/DisasterAftermathTone")

local IDS = {
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

describe("Disaster residue profiles", function()
    it("covers every disaster with a residue language", function()
        for _, id in ipairs(IDS) do
            local profile = DisasterResidue.get(id)
            expect(profile ~= nil).toBe(true)
            expect(type(profile.Kind)).toBe("string")
            expect(typeof(profile.Color)).toBe("Color3")
            expect(typeof(profile.Material)).toBe("EnumItem")
        end
    end)

    it("increases result detail budget with quality", function()
        expect(DisasterResidue.resultBudget("Low")
            < DisasterResidue.resultBudget("Medium")).toBe(true)
        expect(DisasterResidue.resultBudget("Medium")
            < DisasterResidue.resultBudget("High")).toBe(true)
    end)

    it("keeps impact scars longer at higher quality", function()
        expect(DisasterResidue.impactLifetime("Low")
            < DisasterResidue.impactLifetime("Medium")).toBe(true)
        expect(DisasterResidue.impactLifetime("Medium")
            < DisasterResidue.impactLifetime("High")).toBe(true)
    end)
end)


describe("Nine distinct non-impact aftermath silhouettes", function()
    it("creates tier-bounded unique static scars in transformed ground space", function()
        local root = Instance.new("Folder")
        local ground = CFrame.new(14, 3, -22)
            * CFrame.Angles(0, math.rad(36), 0)
        local ids = {
            "RisingLava", "LowGravity", "DisappearingPlatforms",
            "Tornado", "Freeze", "SpeedSurge", "Darkness",
            "ShrinkingArena", "JumpShock",
        }
        local signatures = {}
        for _, id in ipairs(ids) do
            local names = AftermathSurfaceKit.names(id)
            expect(#names).toBe(4)
            local signature = table.concat(names, "|")
            expect(signatures[signature] == nil).toBe(true)
            signatures[signature] = true
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local parts = AftermathSurfaceKit.build(root, id, tier, ground,
                    DisasterResidue.get(id), 1, tier, VisualTheme.arena("Classic"))
                expect(#parts).toBe(AftermathSurfaceKit.count(tier))
                for i, part in ipairs(parts) do
                    expect(string.find(part.Name, names[i], 1, true) ~= nil).toBe(true)
                    expect(part:GetAttribute("ChaosAftermathMotif")).toBe(id)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.Material == Enum.Material.Neon).toBe(false)
                    expect(ground:PointToObjectSpace(part.Position).Magnitude < 6).toBe(true)
                    part:Destroy()
                end
            end
        end
        expect(#ids).toBe(9)
        root:Destroy()
    end)

    it("refuses unknown and incomplete cases without adding geometry", function()
        local root = Instance.new("Folder")
        local ground = CFrame.new(3, 4, 8)
        local profile = DisasterResidue.get("Freeze")
        expect(#AftermathSurfaceKit.build(root, "Meteors", "High",
            ground, profile)).toBe(0)
        expect(#AftermathSurfaceKit.build(root, "Freeze", "High",
            nil, profile)).toBe(0)
        expect(#AftermathSurfaceKit.build(root, "Freeze", "High",
            ground, nil)).toBe(0)
        expect(#AftermathSurfaceKit.build(nil, "Freeze", "High",
            ground, profile)).toBe(0)
        expect(#root:GetChildren()).toBe(0)
        root:Destroy()
    end)
end)


describe("Physical aftermath settling on Android tiers", function()
    it("uses a distinct, timed material-color finish on all nine static residue types", function()
        local ids = {
            "RisingLava", "LowGravity", "DisappearingPlatforms",
            "Tornado", "Freeze", "SpeedSurge", "Darkness",
            "ShrinkingArena", "JumpShock",
        }
        local seen = {}
        for _, id in ipairs(ids) do
            local p = DisasterResidue.get(id)
            local high = DisasterResidue.settlement(id, "High", false,
                p.Color, 3.8)
            local medium = DisasterResidue.settlement(id, "Medium", false,
                p.Color, 3.8)
            expect(high ~= nil and medium ~= nil).toBe(true)
            expect(high.Color ~= p.Color).toBe(true)
            expect(high.StartAfter > 0).toBe(true)
            expect(high.StartAfter + high.Duration < 3.8 - 0.8).toBe(true)
            expect(medium.StartAfter + medium.Duration < 3.8 - 0.8).toBe(true)
            expect(high.Transparency < 1).toBe(true)
            expect(medium.Transparency < 1).toBe(true)
            local signature = string.format("%.3f/%.3f/%.3f",
                high.Color.R, high.Color.G, high.Color.B)
            expect(seen[signature] == nil).toBe(true)
            seen[signature] = true
            expect(DisasterResidue.settlement(id, "Low", false,
                p.Color, 3.8) == nil).toBe(true)
            expect(DisasterResidue.settlement(id, "High", true,
                p.Color, 3.8) == nil).toBe(true)
        end
    end)

    it("does not animate impact-only scars or malformed requests", function()
        local color = Color3.fromRGB(88, 99, 110)
        expect(DisasterResidue.settlement("Bombs", "High", false,
            color, 4) == nil).toBe(true)
        expect(DisasterResidue.settlement("Meteors", "High", false,
            color, 4) == nil).toBe(true)
        expect(DisasterResidue.settlement("Freeze", "High", false,
            nil, 4) == nil).toBe(true)
    end)
end)

describe("Aftermath color harmony", function()
    it("defines a subdued result-only grade for all eleven hazards", function()
        for _, id in ipairs(IDS) do
            local tone = DisasterAftermathTone.combine({id})
            expect(tone ~= nil).toBe(true)
            expect(tone.Contrast >= 0 and tone.Contrast <= 0.055).toBe(true)
            expect(tone.Saturation <= 0).toBe(true)
            expect(tone.Blur >= 0 and tone.Blur <= 1.2).toBe(true)
        end
    end)

    it("mixes both Double Chaos palettes without doubling blur", function()
        local tornado = DisasterAftermathTone.combine({"Tornado"})
        local freeze = DisasterAftermathTone.combine({"Freeze"})
        local combined = DisasterAftermathTone.combine({"Tornado", "Freeze"})
        expect(combined ~= nil).toBe(true)
        expect(combined.Tint ~= tornado.Tint).toBe(true)
        expect(combined.Tint ~= freeze.Tint).toBe(true)
        expect(combined.Blur < tornado.Blur + freeze.Blur).toBe(true)
        expect(combined.Contrast <= 0.055).toBe(true)
        expect(DisasterAftermathTone.combine({"Invalid"}) == nil).toBe(true)
    end)

    it("respects Android Low and the Reduce Motion accessibility setting", function()
        local ids = {"RisingLava", "JumpShock"}
        local low = DisasterAftermathTone.presentation(ids, "Low", false)
        local medium = DisasterAftermathTone.presentation(ids, "Medium", false)
        local high = DisasterAftermathTone.presentation(ids, "High", false)
        local reduced = DisasterAftermathTone.presentation(ids, "High", true)
        expect(low ~= nil and medium ~= nil and high ~= nil and reduced ~= nil).toBe(true)
        expect(low.Blur <= medium.Blur).toBe(true)
        expect(medium.Blur <= high.Blur).toBe(true)
        expect(reduced.Blur).toBe(0)
        expect(reduced.Contrast < high.Contrast).toBe(true)
        expect(low.Hold < high.Hold).toBe(true)
    end)
end)

describe("Ground-correct meteor/bomb aftermath in active rounds", function()
    it("uses all five material scar languages without additional effects", function()
        local families = {
            {Enum.Material.Metal, "Metal", Enum.Material.Metal},
            {Enum.Material.Slate, "Stone", Enum.Material.Slate},
            {Enum.Material.Ground, "Dust", Enum.Material.Ground},
            {Enum.Material.Ice, "Ice", Enum.Material.Ice},
            {Enum.Material.Glass, "Polished", Enum.Material.Glass},
        }
        local source = Color3.fromRGB(96, 114, 125)
        for _, expected in ipairs(families) do
            local material = expected[1]
            for _, kind in ipairs({"Meteor", "Bomb"}) do
                local recipe = ImpactSurfaceScarKit.recipe(
                    kind, "High", material, source,
                    Color3.fromRGB(255, 145, 85), false
                )
                expect(recipe ~= nil).toBe(true)
                expect(recipe.Family).toBe(expected[2])
                expect(recipe.Material).toBe(expected[3])
                expect(typeof(recipe.Color)).toBe("Color3")
                expect(recipe.CrackCount).toBe(5)
                expect(recipe.Alpha >= 0.30 and recipe.Alpha <= 0.76).toBe(true)
                expect(recipe.Signature == "FacetedCrater"
                    or recipe.Signature == "PressureScorch").toBe(true)
            end
        end
        expect(ImpactSurfaceScarKit.recipe("Unknown", "High",
            Enum.Material.Metal, source, source, false) == nil).toBe(true)
        expect(ImpactSurfaceScarKit.family(Enum.Material.Wood)).toBe("Stone")
    end)

    it("maintains the previous 1/4/6 total-part budget across tiers and slopes", function()
        local parent = Instance.new("Folder")
        local ground = CFrame.new(15, 6, 21)
            * CFrame.Angles(math.rad(14), math.rad(42), math.rad(-8))
        local source = Color3.fromRGB(92, 98, 111)
        local center = Color3.fromRGB(200, 105, 60)
        for _, kind in ipairs({"Meteor", "Bomb"}) do
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local parts = ImpactSurfaceScarKit.build(
                    parent, ground, kind, tier, Enum.Material.Slate,
                    source, center, 13, false
                )
                local expected = tier == "Low" and 1
                    or (tier == "Medium" and 4 or 6)
                expect(#parts).toBe(expected)
                expect(parts[1].Name).toBe(kind == "Meteor"
                    and "ImpactFacetedCrater" or "ImpactPressureScorch")
                expect(parts[1]:IsA(kind == "Meteor" and "WedgePart" or "Part"))
                    .toBe(true)
                for _, part in ipairs(parts) do
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part:GetAttribute("ImpactScarFamily")).toBe("Stone")
                    expect((part.Position - ground.Position).Magnitude <= 14)
                        .toBe(true)
                    expect(part.Size.Magnitude > 0).toBe(true)
                    part:Destroy()
                end
            end
        end
        expect(#parent:GetChildren()).toBe(0)
        local still = ImpactSurfaceScarKit.build(
            parent, ground, "Meteor", "High", Enum.Material.Ice,
            source, center, 12, true
        )
        expect(#still).toBe(1)
        still[1]:Destroy()
        expect(#ImpactSurfaceScarKit.build(parent, nil, "Meteor",
            "High", Enum.Material.Ice, source, center, 12, false)).toBe(0)
        expect(#ImpactSurfaceScarKit.build(nil, ground, "Meteor",
            "High", Enum.Material.Ice, source, center, 12, false)).toBe(0)
        expect(#ImpactSurfaceScarKit.build(parent, ground, "Unknown",
            "High", Enum.Material.Ice, source, center, 12, false)).toBe(0)
        parent:Destroy()
    end)

    it("bounds per-camera range before any raycast and handles accessibility", function()
        local visible = ImpactSurfaceScarKit.visible
        expect(visible("round", "Meteor", "Low", 64)).toBe(true)
        expect(visible("round", "Meteor", "Low", 65)).toBe(false)
        expect(visible("round", "Bomb", "Medium", 108)).toBe(true)
        expect(visible("round", "Bomb", "Medium", 109)).toBe(false)
        expect(visible("round", "Meteor", "High", 150)).toBe(true)
        expect(visible("round", "Meteor", "High", 151)).toBe(false)
        expect(visible("round", "Meteor", "Unexpected", 65)).toBe(false)
        expect(visible("ready", "Meteor", "High", 1)).toBe(false)
        expect(visible("round", "Unknown", "High", 1)).toBe(false)
        expect(visible("round", "Bomb", "High", nil)).toBe(false)
        local c = Color3.fromRGB(80, 95, 110)
        expect(ImpactSurfaceScarKit.settlement("Low", false, c, 5) == nil).toBe(true)
        expect(ImpactSurfaceScarKit.settlement("High", true, c, 5) == nil).toBe(true)
        expect(ImpactSurfaceScarKit.settlement("High", false, nil, 5) == nil).toBe(true)
        local cooling = ImpactSurfaceScarKit.settlement("High", false, c, 5.5)
        expect(cooling ~= nil).toBe(true)
        expect(cooling.StartAfter > 0).toBe(true)
        expect(cooling.StartAfter + cooling.Duration < 5.5 - 0.8).toBe(true)
        expect(cooling.Color ~= c).toBe(true)
        expect(cooling.Transparency >= 0.6 and cooling.Transparency < 1)
            .toBe(true)
    end)

    it("emits deterministic crack recipes for crater and bomb pressure language", function()
        for _, kind in ipairs({"Meteor", "Bomb"}) do
            local names = {}
            for i = 1, 5 do
                local first = ImpactSurfaceScarKit.crack(
                    i, 5, 12, kind, "Stone"
                )
                local again = ImpactSurfaceScarKit.crack(
                    i, 5, 12, kind, "Stone"
                )
                expect(first.Name).toBe(kind == "Meteor"
                    and "RimFacet" or "PressureCut")
                expect(first.Wedge).toBe(kind == "Meteor")
                expect(first.Offset).toBe(again.Offset)
                expect(first.Angle).toBe(again.Angle)
                expect(first.Size).toBe(again.Size)
                expect(first.Size.X > 0 and first.Size.Z > 0).toBe(true)
                names[first.Name .. i] = true
            end
            expect(ImpactSurfaceScarKit.crack(0, 5, 12, kind, "Stone") == nil)
                .toBe(true)
            expect(ImpactSurfaceScarKit.crack(1, 0, 12, kind, "Stone") == nil)
                .toBe(true)
        end
        expect(ImpactSurfaceScarKit.crack(1, 5, 12, "Invalid", "Ice") == nil)
            .toBe(true)
    end)
end)

return nil
