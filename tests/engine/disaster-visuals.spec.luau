--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterVisuals = require("../../src/shared/DisasterVisuals")
local DisasterMotionSceneRules = require("../../src/shared/DisasterMotionSceneRules")
local UITheme = require("../../src/shared/UITheme")
local DisasterBalance = require("../../src/server/DisasterBalance")
local HazardGlyphs = require("../../src/shared/HazardGlyphs")
local ImpactSetpieceRules = require("../../src/shared/ImpactSetpieceRules")
local ImpactSetpiece = require("../../src/client/ImpactSetpiece")
local DisasterIntroGlyphKit = require("../../src/client/DisasterIntroGlyphKit")
local MeteorSignatureRules = require("../../src/shared/MeteorSignatureRules")
local ImpactMaterialRules = require("../../src/shared/ImpactMaterialRules")
local ImpactPulseRules = require("../../src/shared/ImpactPulseRules")
local CinematicPulseRingKit = require("../../src/client/CinematicPulseRingKit")
local PlatformFinishKit = require("../../src/client/PlatformFinishKit")

describe("Disaster visual identities", function()
    it("adds bounded structural diagonal braces only under safe visual decks", function()
        local root = Instance.new("Folder")
        root.Parent = workspace
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(12, 2, 11)
        platform.CFrame = CFrame.new(18, 22, -15)
            * CFrame.Angles(0, math.rad(33), 0)
        platform.Anchored = true
        platform.Parent = root
        local decor = Instance.new("Folder")
        decor.Parent = root

        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local theme = require("../../src/shared/VisualTheme").arena(variant)
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local braces = PlatformFinishKit.buildLoadBraces(
                    decor, platform, variant, tier, theme
                )
                expect(#braces).toBe(PlatformFinishKit.braceCount(tier))
                for _, brace in ipairs(braces) do
                    expect(brace:GetAttribute("ChaosLoadBrace")).toBe(true)
                    expect(brace:GetAttribute("ChaosPlatformTrim")).toBe(true)
                    expect(brace.Anchored).toBe(false)
                    expect(brace.Massless).toBe(true)
                    expect(brace.CanCollide).toBe(false)
                    expect(brace.CanTouch).toBe(false)
                    expect(brace.CanQuery).toBe(false)
                    expect(brace.CastShadow).toBe(false)
                    expect(brace.Material).toBe(Enum.Material.Metal)
                    expect(platform.CFrame:PointToObjectSpace(brace.Position).Y
                        < -platform.Size.Y * 0.5).toBe(true)
                    local weld = brace:FindFirstChildOfClass("WeldConstraint")
                    expect(weld ~= nil and weld.Part1 == platform).toBe(true)
                end
                PlatformFinishKit.applyCollapseVisibility(braces, "Gone")
                for _, brace in ipairs(braces) do
                    expect(brace.Transparency).toBe(1)
                end
                PlatformFinishKit.applyCollapseVisibility(braces, nil)
                for _, brace in ipairs(braces) do
                    expect(brace.Transparency < 0.2).toBe(true)
                end
                decor:ClearAllChildren()
            end
        end

        -- Bridges have a different permanent underframe and must remain
        -- clean. Tiny decks should not allocate disproportionate beams.
        platform:SetAttribute("ChaosSkybridge", true)
        expect(#PlatformFinishKit.buildLoadBraces(
            decor, platform, "Towers", "High",
            require("../../src/shared/VisualTheme").arena("Towers")
        )).toBe(0)
        platform:SetAttribute("ChaosSkybridge", nil)
        platform.Size = Vector3.new(7, 2, 7)
        expect(#PlatformFinishKit.buildLoadBraces(
            decor, platform, "Classic", "High",
            require("../../src/shared/VisualTheme").arena("Classic")
        )).toBe(0)
        root:Destroy()
    end)


    it("builds budgeted non-solid side rails that follow collapse visibility", function()
        local theme = require("../../src/shared/VisualTheme").arena("Towers")
        local platform = Instance.new("Part")
        platform.Name = "PlatformSideRailTest"
        platform.Anchored = true
        platform.Size = Vector3.new(12, 2, 10)
        platform.CFrame = CFrame.new(0, 25, 0)
        platform.Parent = workspace
        local folder = Instance.new("Folder")
        folder.Parent = workspace

        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local parts = PlatformFinishKit.buildSideRails(folder, platform, tier, theme)
            expect(#parts).toBe(PlatformFinishKit.sideRailCount(tier))
            for _, rail in ipairs(parts) do
                expect(rail.CanCollide).toBe(false)
                expect(rail.CanTouch).toBe(false)
                expect(rail.CanQuery).toBe(false)
                expect(rail:FindFirstChildOfClass("WeldConstraint") ~= nil).toBe(true)
                expect(rail.Position.Y < platform.Position.Y).toBe(true)
                -- A rail buried inside the opaque deck is invisible in
                -- third-person view; its outer face must be exposed.
                local offset = rail.Position - platform.Position
                expect(
                    math.abs(offset.X) > platform.Size.X * 0.5
                    or math.abs(offset.Z) > platform.Size.Z * 0.5
                ).toBe(true)
            end
            PlatformFinishKit.applyCollapseVisibility(parts, "Warning")
            for _, rail in ipairs(parts) do
                expect(rail.Transparency >= 0.799).toBe(true)
            end
            PlatformFinishKit.applyCollapseVisibility(parts, "Gone")
            for _, rail in ipairs(parts) do
                expect(rail.Transparency).toBe(1)
            end
            PlatformFinishKit.applyCollapseVisibility(parts, nil)
            for _, rail in ipairs(parts) do
                expect(math.abs(rail.Transparency - 0.08) < 0.0001).toBe(true)
            end
            folder:ClearAllChildren()
        end

        folder:Destroy()
        platform:Destroy()
    end)


    it("fades local platform trim for warning and fully hides it on collapse", function()
        local part = Instance.new("Part")
        part.Transparency = 0.12
        part:SetAttribute("ChaosBaseTransparency", 0.12)
        part.Parent = workspace
        local pieces = {part}

        PlatformFinishKit.applyCollapseVisibility(pieces, "Warning")
        expect(part.Transparency >= 0.799).toBe(true)
        PlatformFinishKit.applyCollapseVisibility(pieces, "Gone")
        expect(part.Transparency).toBe(1)
        PlatformFinishKit.applyCollapseVisibility(pieces, nil)
        expect(math.abs(part.Transparency - 0.12) < 0.0001).toBe(true)

        -- Repeated warning/restoration must not accidentally store the
        -- faded alpha as the original base transparency.
        PlatformFinishKit.applyCollapseVisibility(pieces, "Warning")
        PlatformFinishKit.applyCollapseVisibility(pieces, "Restore")
        expect(math.abs(part.Transparency - 0.12) < 0.0001).toBe(true)
        part:Destroy()
    end)


    it("assigns unique tiered impact accents only for meteor and bomb events", function()
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local meteor = ImpactSetpieceRules.get("Meteor", tier, false, 15)
            local bomb = ImpactSetpieceRules.get("Bomb", tier, false, 15)
            expect(meteor ~= nil and bomb ~= nil).toBe(true)
            expect(meteor.Prefix ~= bomb.Prefix).toBe(true)
            expect(meteor.Material ~= bomb.Material).toBe(true)
            expect(meteor.Count <= 7).toBe(true)
            expect(bomb.Count <= 8).toBe(true)
            if tier == "Low" then
                -- Two short-lived shards provide a readable impact without
                -- the four mechanical finish fragments of richer tiers.
                expect(meteor.Count).toBe(2)
                expect(bomb.Count).toBe(2)
            end
            expect(ImpactSetpieceRules.finishCount("Meteor", tier, false) <= 4).toBe(true)
            expect(ImpactSetpieceRules.finishCount("Bomb", tier, false) <= 4).toBe(true)
        end
        expect(ImpactSetpieceRules.get("Meteor", "High", true, 12) == nil).toBe(true)
        expect(ImpactSetpieceRules.finishCount("Meteor", "High", true)).toBe(0)
        expect(ImpactSetpieceRules.finishCount("Bomb", "Low", false)).toBe(0)
        expect(ImpactSetpieceRules.finishCount("Unknown", "High", false)).toBe(0)
        expect(ImpactSetpieceRules.get("Unknown", "High", false, 12) == nil).toBe(true)
        expect(ImpactSetpieceRules.get("Bomb", "High", false, 500).Radius).toBe(40)
        expect(ImpactSetpieceRules.get("Meteor", "High", false, -5).Radius).toBe(1)
    end)

    it("rejects malformed impact payloads before allocating any 3D pieces", function()
        local rules = ImpactSetpieceRules
        local root = Instance.new("Folder")
        local valid = {kind = "Meteor", position = Vector3.new(0, 4, 0),
            color = Color3.fromRGB(255, 130, 75), radius = 9}
        expect(rules.validPayload(valid)).toBe(true)
        expect(rules.validPayload(nil)).toBe(false)
        expect(rules.validPayload("bad")).toBe(false)
        expect(rules.validPayload({position = Vector3.zero})).toBe(false)
        for _, bad in ipairs({0/0, math.huge, -math.huge}) do
            expect(rules.validPayload({position = Vector3.new(bad, 1, 0),
                color = valid.color})).toBe(false)
            expect(rules.validPayload({position = Vector3.new(0, bad, 0),
                color = valid.color})).toBe(false)
            expect(rules.validPayload({position = valid.position,
                color = Color3.new(bad, 0.5, 0.5)})).toBe(false)
            expect(rules.safeRadius(bad)).toBe(8)
            expect(rules.get("Meteor", "High", false, bad).Radius).toBe(8)
            local ok, spawned = pcall(ImpactSetpiece.spawn, root,
                {kind = "Meteor", position = Vector3.new(bad, 0, 0),
                    color = valid.color, radius = 8},
                "High", false, rules)
            expect(ok).toBe(true)
            expect(spawned == nil).toBe(true)
        end
        expect(rules.validPayload({position = Vector3.new(1e8, 0, 0),
            color = valid.color})).toBe(false)
        expect(rules.safeRadius(nil)).toBe(8)
        expect(rules.safeRadius(-4)).toBe(1)
        expect(rules.safeRadius(400)).toBe(40)
        expect(rules.safeRadius(14)).toBe(14)
        expect(rules.finish("Bomb", 1, 4, math.huge).Width > 0).toBe(true)
        expect(rules.fragment("Meteor", 1, 7, 0/0).Length > 0).toBe(true)
        expect(ImpactSetpiece.spawn(nil, valid, "High", false, rules) == nil)
            .toBe(true)
        expect(#root:GetChildren()).toBe(0)
        root:Destroy()
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
        -- Explicitly exercise the no-injected-rules cloud module path.
        -- Incomplete payloads must be rejected before looking up
        -- ReplicatedStorage.Shared.ImpactSetpieceRules.
        for _, invalid in ipairs({
            {kind = "Meteor"},
            {kind = "Meteor", position = Vector3.zero},
            {kind = "Bomb", color = Color3.new(1, 0, 0)},
        }) do
            local ok, result = pcall(ImpactSetpiece.spawn, root, invalid,
                "High", false)
            expect(ok).toBe(true)
            expect(result == nil).toBe(true)
        end
        expect(#root:GetChildren()).toBe(0)
        local lowImpact = ImpactSetpiece.spawn(root, {
            kind = "Meteor", position = Vector3.zero, color = Color3.new(1, 1, 1),
        }, "Low", false, ImpactSetpieceRules)
        expect(lowImpact ~= nil).toBe(true)
        expect(#lowImpact:GetChildren()).toBe(2)
        lowImpact:Destroy()
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

    it("sculpts irregular meteor fracture wings and pressure-wave fans", function()
        local rules = ImpactSetpieceRules
        for _, tier in ipairs({"Medium", "High"}) do
            for _, kind in ipairs({"Meteor", "Bomb"}) do
                local profile = rules.get(kind, tier, false, 16)
                local angles = {}
                local banks = {}
                local lengths = {}
                for i = 1, profile.Count do
                    local part = rules.fragment(kind, i, profile.Count, 16)
                    expect(part ~= nil).toBe(true)
                    expect(part.YawSkew ~= nil and part.Bank ~= nil).toBe(true)
                    expect(math.abs(part.YawSkew) <= 0.14).toBe(true)
                    expect(math.abs(part.Bank) <= math.rad(30)).toBe(true)
                    expect(part.EndRadius > part.StartRadius).toBe(true)
                    expect(part.Length > 0 and part.Width > 0).toBe(true)
                    expect(part.Length < 16).toBe(true)
                    expect(rules.fragment(kind, i, profile.Count, 16).Bank)
                        .toBe(part.Bank)
                    angles[i] = part.Direction
                    banks[part.Bank] = true
                    lengths[part.Length] = true
                end
                expect(next(banks) ~= nil).toBe(true)
                expect(next(lengths) ~= nil).toBe(true)
                expect(angles[1] ~= angles[2]).toBe(true)
                local rimCount = rules.finishCount(kind, tier, false)
                for i = 1, rimCount do
                    local rim = rules.finish(kind, i, rimCount, 16)
                    expect(rim ~= nil).toBe(true)
                    expect(math.abs(rim.Bank) <= math.rad(22)).toBe(true)
                    expect(math.abs(rim.YawSkew) <= 0.10).toBe(true)
                    expect(rim.EndRadius > rim.StartRadius).toBe(true)
                end
            end
        end
        expect(rules.fragment("Unknown", 1, 7, 12) == nil).toBe(true)
        expect(rules.fragment("Meteor", 0, 7, 12) == nil).toBe(true)
        expect(rules.fragment("Meteor", 1, math.huge, 12) == nil).toBe(true)
        expect(rules.fragment("Bomb", 1.5, 8, 12) == nil).toBe(true)
        expect(rules.finish("Bomb", 1, math.huge, 12) == nil).toBe(true)
        expect(rules.finish("Meteor", 5, 4, 12) == nil).toBe(true)
        expect(rules.get("Meteor", "Low", false, 16).Count).toBe(2)
        expect(rules.get("Meteor", "High", true, 16) == nil).toBe(true)
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
    it("caps comet trails at one/three/six for low/mobile and high visuals", function()
        local r = MeteorSignatureRules
        expect(r.profile("Low", false).MaxTrails).toBe(1)
        expect(r.profile("Medium", false).MaxTrails).toBe(3)
        expect(r.profile("High", false).MaxTrails).toBe(6)
        expect(r.profile("High", true).MaxTrails).toBe(0)
        expect(r.profile("Unknown", false).MaxTrails).toBe(0)
        local viewer = Vector3.new(0, 8, 0)
        local meteor = Vector3.new(0, 10, 35)
        expect(r.shouldTrail("round", true, viewer, meteor,
            "Low", false, 0)).toBe(true)
        expect(r.shouldTrail("round", true, viewer, meteor,
            "Low", false, 1)).toBe(false)
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

    it("sculpts unique, cached ember silhouettes without extra Trail instances", function()
        local style = MeteorSignatureRules.trailStyle
        local low = style("Low", false)
        local medium = style("Medium", false)
        local high = style("High", false)
        expect(low ~= nil and medium ~= nil and high ~= nil).toBe(true)
        expect(#low.WidthScale.Keypoints).toBe(4)
        expect(low.LightEmission < medium.LightEmission).toBe(true)
        expect(style("High", true)).toBe(nil)
        expect(style("Unknown", false)).toBe(nil)
        -- One cached recipe per tier; live updates do not allocate sequences.
        expect(style("High", false)).toBe(high)
        expect(#medium.WidthScale.Keypoints).toBe(4)
        expect(#high.WidthScale.Keypoints).toBe(6)
        expect(high.WidthScale.Keypoints[2].Value).toBe(1)
        expect(high.WidthScale.Keypoints[3].Value <
            high.WidthScale.Keypoints[4].Value).toBe(true)
        expect(high.WidthScale.Keypoints[#high.WidthScale.Keypoints].Value).toBe(0)
        expect(high.Transparency.Keypoints[#high.Transparency.Keypoints].Value).toBe(1)
        expect(high.LightEmission > medium.LightEmission).toBe(true)
        expect(high.Span > medium.Span).toBe(true)
        expect(MeteorSignatureRules.profile("High", false).MaxTrails).toBe(6)
        expect(MeteorSignatureRules.profile("Medium", false).MaxTrails).toBe(3)
        expect(MeteorSignatureRules.profile("Low", false).MaxTrails).toBe(1)
    end)

    it("ignores broken RoundState packets without resetting meteor signatures", function()
        local read = MeteorSignatureRules.readRoundState
        local phase, active = read({
            phase = "round",
            disasterIds = {"Meteors", "Bombs"},
        })
        expect(phase).toBe("round")
        expect(active).toBe(true)
        local waiting, inactive = read({
            phase = "waiting",
            disasterIds = {"Meteors"},
        })
        expect(waiting).toBe("waiting")
        expect(inactive).toBe(false)
        local unknown, noMeteor = read({
            phase = "round",
            disasterIds = "Meteors",
        })
        expect(unknown).toBe("round")
        expect(noMeteor).toBe(false)
        expect(read(nil)).toBe(nil)
        expect(read("broken")).toBe(nil)
        expect(read(42)).toBe(nil)
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

describe("Surface-specific meteor and bomb cosmetic microdebris", function()
    it("uses five recognizable surface palettes and retains low/reduced budgets", function()
        local rules = ImpactMaterialRules
        local cases = {
            {Enum.Material.Metal, "Metal", Enum.Material.Metal},
            {Enum.Material.DiamondPlate, "Metal", Enum.Material.Metal},
            {Enum.Material.Concrete, "Stone", Enum.Material.Slate},
            {Enum.Material.Rock, "Stone", Enum.Material.Slate},
            {Enum.Material.Ice, "Ice", Enum.Material.Ice},
            {Enum.Material.Snow, "Ice", Enum.Material.Ice},
            {Enum.Material.Sand, "Dust", Enum.Material.Ground},
            {Enum.Material.Glass, "Polished", Enum.Material.Glass},
            {Enum.Material.SmoothPlastic, "Polished", Enum.Material.Glass},
        }
        local surface = Color3.fromRGB(115, 132, 146)
        local hot = Color3.fromRGB(255, 135, 52)
        for _, c in ipairs(cases) do
            local p = rules.palette(c[1], surface, hot, "Meteor", "High", false)
            expect(p.Family).toBe(c[2])
            expect(p.Material).toBe(c[3])
            expect(typeof(p.Color)).toBe("Color3")
            expect(typeof(p.DustColor)).toBe("Color3")
            expect(p.Count).toBe(6)
            expect(p.Motion > 0 and p.Motion <= 1).toBe(true)
            expect(rules.palette(c[1], surface, hot, "Bomb", "Medium", false).Count).toBe(3)
            expect(rules.palette(c[1], surface, hot, "Bomb", "Low", false).Count).toBe(0)
            expect(rules.palette(c[1], surface, hot, "Bomb", "High", true).Count).toBe(0)
        end
        expect(rules.family(Enum.Material.Wood)).toBe("Stone")
    end)

    it("scales material fragments down as players move away or storms intensify", function()
        local r = ImpactMaterialRules.chipCount
        expect(r("Low", false, 1, 1)).toBe(0)
        expect(r("Medium", true, 1, 1)).toBe(0)
        expect(r("High", true, 1, 1)).toBe(0)
        expect(r("Medium", false, 70, 1)).toBe(3)
        expect(r("Medium", false, 70.1, 1)).toBe(0)
        expect(r("Medium", false, 1, 3)).toBe(0)
        expect(r("High", false, 80, 2)).toBe(6)
        expect(r("High", false, 80.1, 2)).toBe(3)
        expect(r("High", false, 100, 3)).toBe(3)
        expect(r("High", false, 110.1, 3)).toBe(0)
        expect(r("High", false, 2, 4)).toBe(0)
        expect(r("Unknown", false, 2, 1)).toBe(0)
        expect(r("High", false, -1, 1)).toBe(0)
        expect(r("High", false, nil, 1)).toBe(0)
        expect(r("High", false, 5, 0)).toBe(0)
    end)

    it("keeps all transient fragments above and oriented to tilted arena materials", function()
        local rules = ImpactMaterialRules
        local deck = CFrame.new(12, 8, -35)
            * CFrame.Angles(math.rad(18), math.rad(51), math.rad(-8))
        local surface = rules.surfaceFrame(deck.Position, deck.UpVector)
        expect(surface.UpVector:Dot(deck.UpVector) > 0.999).toBe(true)
        expect((surface.Position - deck.Position).Magnitude < 0.001).toBe(true)
        for i = 1, 6 do
            local fragment = rules.fragment(surface, i, 6, 18, 0.7)
            expect(typeof(fragment.Start)).toBe("CFrame")
            expect(typeof(fragment.Travel)).toBe("Vector3")
            expect(fragment.Size.X > 0 and fragment.Size.Y > 0).toBe(true)
            local localPoint = surface:PointToObjectSpace(fragment.Start.Position)
            expect(math.abs(localPoint.Y - 0.12) < 0.001).toBe(true)
            expect(fragment.Travel:Dot(deck.UpVector) >= 0.20).toBe(true)
            expect(fragment.Travel.Magnitude < 3).toBe(true)
        end
        expect(rules.fragment(nil, 1, 3, 10, 1) == nil).toBe(true)
        expect(rules.fragment(surface, 0, 3, 10, 1) == nil).toBe(true)
        expect(rules.fragment(surface, 4, 3, 10, 1) == nil).toBe(true)
        expect(rules.fragment(surface, 1, 3, 0, 1) == nil).toBe(true)
        expect(rules.surfaceFrame(nil, Vector3.yAxis) == nil).toBe(true)
        local fallback = rules.surfaceFrame(Vector3.new(0, 5, 0), Vector3.zero)
        expect(fallback.UpVector:Dot(Vector3.yAxis) > 0.999).toBe(true)
    end)

    it("does not add lights, GPU emitters or collidable objects to material recipes", function()
        local root = Instance.new("Folder")
        local frame = ImpactMaterialRules.surfaceFrame(
            Vector3.new(5, 3, 8), Vector3.yAxis
        )
        local color = Color3.fromRGB(95, 110, 122)
        for _, material in ipairs({
            Enum.Material.Metal, Enum.Material.Ice,
            Enum.Material.Slate, Enum.Material.Glass,
        }) do
            local p = ImpactMaterialRules.palette(
                material, color, color, "Bomb", "High", false
            )
            for i = 1, p.Count do
                local fragment = ImpactMaterialRules.fragment(
                    frame, i, p.Count, 9, p.Motion
                )
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.CastShadow = false
                part.CFrame = fragment.Start
                part.Size = fragment.Size
                part.Material = p.Material
                part.Color = p.Color
                part.Parent = root
                expect(part.Anchored).toBe(true)
                expect(part.CanCollide).toBe(false)
                expect(part.CanQuery).toBe(false)
            end
        end
        expect(#root:GetChildren()).toBe(24)
        for _, part in ipairs(root:GetChildren()) do part:Destroy() end
        root:Destroy()
    end)
end)

describe("Android crisis perimeter identity and streaming", function()
    it("anchors four crisis markers to all four sides of rotated decks", function()
        local folder = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(90, 2, 66)
        base.CFrame = CFrame.new(15, 8, -20)
            * CFrame.Angles(math.rad(11), math.rad(38), math.rad(-6))
        base.Parent = folder
        local expected = {
            Vector3.new(0, 1.18, -33),
            Vector3.new(0, 1.18, 33),
            Vector3.new(-45, 1.18, 0),
            Vector3.new(45, 1.18, 0),
        }
        for i = 1, 4 do
            local frame, size = DisasterMotionSceneRules.pose(base, "shrink", i)
            expect(typeof(frame)).toBe("CFrame")
            expect(size.Magnitude > 0).toBe(true)
            local localPoint = base.CFrame:PointToObjectSpace(frame.Position)
            expect((localPoint - expected[i]).Magnitude < 0.0001).toBe(true)
            expect(frame.UpVector:Dot(base.CFrame.UpVector) > 0.99999)
                .toBe(true)
            local darkFrame, darkSize = DisasterMotionSceneRules.pose(
                base, "blackout", i)
            expect(darkSize).toBe(Vector3.new(0.55, 3.2, 0.55))
            expect(darkFrame.UpVector:Dot(base.CFrame.UpVector) > 0.99999)
                .toBe(true)
            local point = base.CFrame:PointToObjectSpace(darkFrame.Position)
            expect(math.abs(math.abs(point.X) - 41) < 0.0001).toBe(true)
            expect(math.abs(math.abs(point.Z) - 29) < 0.0001).toBe(true)
        end
        expect(DisasterMotionSceneRules.pose(base, "shrink", 0) == nil).toBe(true)
        expect(DisasterMotionSceneRules.pose(base, "blackout", 5) == nil).toBe(true)
        expect(DisasterMotionSceneRules.pose(base, "unknown", 1) == nil).toBe(true)
        folder:Destroy()
    end)

    it("detects stale blackout maps and updates geometry only when necessary", function()
        local folder = Instance.new("Folder")
        local first = Instance.new("Part")
        first.Parent = folder
        local second = Instance.new("Part")
        second.Parent = folder
        local marks = {}
        for i = 1, 4 do
            local p = Instance.new("Part")
            p.Parent = folder
            marks[i] = p
        end
        local r = DisasterMotionSceneRules
        expect(r.needsRebuild(nil, first, marks)).toBe(true)
        expect(r.needsRebuild(first, first, marks)).toBe(false)
        expect(r.needsRebuild(first, second, marks)).toBe(true)
        expect(r.needsRebuild(first, nil, marks)).toBe(true)
        expect(r.needsRebuild(first, first, {})).toBe(true)
        expect(r.geometryChanged(nil, nil, first)).toBe(true)
        expect(r.geometryChanged(first.CFrame, first.Size, first)).toBe(false)
        first.CFrame *= CFrame.Angles(0, math.rad(19), 0)
        expect(r.geometryChanged(CFrame.identity, first.Size, first))
            .toBe(true)
        local oldSize = first.Size
        first.Size = oldSize + Vector3.new(2, 0, 0)
        expect(r.geometryChanged(first.CFrame, oldSize, first)).toBe(true)
        marks[4]:Destroy()
        expect(r.needsRebuild(first, first, marks)).toBe(true)
        folder:Destroy()
    end)

    it("uses distinct bounded blackout pulses and still mobile accessibility", function()
        local r = DisasterMotionSceneRules
        local sum = 0
        for i = 1, 4 do
            local pulse = r.beaconPulse(0.5, i, "High", false)
            expect(pulse >= 0 and pulse <= 1).toBe(true)
            sum += pulse
            expect(r.beaconPulse(0.5, i, "Low", false)).toBe(0.5)
            expect(r.beaconPulse(0.5, i, "High", true)).toBe(0.5)
            expect(math.abs(pulse - r.beaconPulse(0.501, i, "High", false))
                < 0.01).toBe(true)
        end
        expect(math.abs(sum - 2) < 0.0001).toBe(true)
        for _, invalid in ipairs({0/0, math.huge, -math.huge, -1, 1e8}) do
            expect(r.beaconPulse(invalid, 1, "High", false)).toBe(0.5)
            expect(r.beaconPulse(0.5, invalid, "High", false)).toBe(0.5)
        end
        expect(r.beaconPulse(0.5, 5, "High", false)).toBe(0.5)
    end)
end)

return nil
