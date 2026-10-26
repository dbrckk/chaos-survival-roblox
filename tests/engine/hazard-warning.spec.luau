--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local HazardWarning = require("../../src/server/HazardWarning")
local Localization = require("../../src/shared/CoreLocalization")
local WarningSignatures = require("../../src/shared/HazardWarningSignatureRules")
local BombChargeRules = require("../../src/shared/BombChargeRules")
local BombChargeKit = require("../../src/client/BombChargeKit")
local FrozenArmorKit = require("../../src/client/FrozenArmorKit")

describe("Hazard warning metadata", function()
    it("publishes bounded animation metadata on warning parts", function()
        local part = Instance.new("Part")
        HazardWarning.configure(part, "Meteor", 0.9, 5.5, 16)

        expect(part:GetAttribute("WarningKind")).toBe("Meteor")
        expect(part:GetAttribute("WarningDuration")).toBe(0.9)
        expect(part:GetAttribute("WarningStartSize")).toBe(5.5)
        expect(part:GetAttribute("WarningEndSize")).toBe(16)

        local startedAt = tonumber(part:GetAttribute("WarningStartedAt"))
        expect(startedAt ~= nil).toBe(true)
        expect(math.abs((startedAt :: number) - workspace:GetServerTimeNow()) < 1).toBe(true)

        part:Destroy()
    end)

    it("keeps the meteor warning through the falling projectile until impact", function()
        local lead = HazardWarning.impactLeadDuration(0.9, 0.5)
        expect(math.abs(lead - 1.4) < 0.001).toBe(true)
        expect(HazardWarning.impactLeadDuration(-2, 0.5) >= 0.55).toBe(true)
        expect(HazardWarning.impactLeadDuration(0.9, -1)).toBe(0.9)
        expect(HazardWarning.impactLeadDuration(nil, nil)).toBe(0.05)

        local marker = Instance.new("Part")
        marker.Name = "MeteorWarning"
        HazardWarning.configure(marker, "Meteor", lead, 5.5, 16)
        local started = marker:GetAttribute("WarningStartedAt")
        -- A 0.9-second pre-fall warning must still be present at the
        -- midpoint of the subsequent 0.5-second projectile descent.
        local inFlight = WarningSignatures.snapshot(marker, started + 1.1)
        expect(inFlight ~= nil).toBe(true)
        expect(inFlight.Progress > 0.75 and inFlight.Progress < 0.85).toBe(true)
        expect(WarningSignatures.snapshot(marker, started + lead + 0.01)).toBe(nil)
        marker:Destroy()
    end)

    it("covers rectangular arena corners with global warnings", function()
        local diameter = HazardWarning.coverageDiameter(Vector3.new(104, 2, 104), 6)
        local half = diameter * 0.5
        local cornerDistance = Vector2.new(52, 52).Magnitude

        expect(half > cornerDistance).toBe(true)
    end)

    it("waits for late attributes instead of inventing a 0.05-second warning", function()
        local part = Instance.new("Part")
        part.Name = "MeteorWarning"
        part:SetAttribute("WarningKind", "Meteor")
        expect(WarningSignatures.snapshot(part, 100)).toBe(nil)

        part:SetAttribute("WarningDuration", 0.9)
        part:SetAttribute("WarningStartSize", 5.5)
        part:SetAttribute("WarningEndSize", 16)
        expect(WarningSignatures.snapshot(part, 100)).toBe(nil)

        part:SetAttribute("WarningStartedAt", 99.5)
        local snapshot = WarningSignatures.snapshot(part, 100)
        expect(snapshot ~= nil).toBe(true)
        expect(snapshot.Kind).toBe("Meteor")
        expect(snapshot.Duration).toBe(0.9)
        expect(snapshot.StartSize).toBe(5.5)
        expect(snapshot.EndSize).toBe(16)
        expect(snapshot.Progress > 0.5 and snapshot.Progress < 0.6).toBe(true)
        expect(WarningSignatures.snapshot(part, 100.5)).toBe(nil)

        part:SetAttribute("WarningKind", "Bomb")
        expect(WarningSignatures.snapshot(part, 100)).toBe(nil)
        part:Destroy()
    end)

    it("rejects expired or malformed replicated warnings before creating graphics", function()
        local part = Instance.new("Part")
        part.Name = "BombWarning"
        HazardWarning.configure(part, "Bomb", 1.25, 5.5, 16)
        local now = workspace:GetServerTimeNow()
        expect(WarningSignatures.snapshot(part, now) ~= nil).toBe(true)
        expect(WarningSignatures.snapshot(part, now + 2)).toBe(nil)

        part:SetAttribute("WarningStartSize", 0)
        expect(WarningSignatures.snapshot(part, now)).toBe(nil)
        part:SetAttribute("WarningStartSize", 5.5)
        part:SetAttribute("WarningDuration", "invalid")
        expect(WarningSignatures.snapshot(part, now)).toBe(nil)
        part:SetAttribute("WarningDuration", 1.25)
        part.Name = "UnrelatedPart"
        expect(WarningSignatures.snapshot(part, now)).toBe(nil)
        part.Name = "FreezeWarning"
        expect(WarningSignatures.snapshot(part, now)).toBe(nil)
        expect(WarningSignatures.snapshot(nil, now)).toBe(nil)
        part:Destroy()
    end)

    it("sanitizes invalid durations and sizes", function()
        local part = Instance.new("Part")
        HazardWarning.configure(part, "Bomb", -2, -5, 0)

        expect((part:GetAttribute("WarningDuration") :: number) >= 0.05).toBe(true)
        expect((part:GetAttribute("WarningStartSize") :: number) >= 0.1).toBe(true)
        expect((part:GetAttribute("WarningEndSize") :: number) >= 0.1).toBe(true)

        part:Destroy()
    end)
end)

describe("Premium frost and electric warning silhouettes", function()
    it("restyles one platform highlight when automatic mobile quality changes", function()
        local style = WarningSignatures.platformHighlightStyle
        local low = style("Low")
        local high = style("High")
        expect(low.FillTransparency).toBe(0.92)
        expect(low.OutlineTransparency).toBe(0.36)
        expect(high.FillTransparency).toBe(0.84)
        expect(high.OutlineTransparency).toBe(0.18)
        expect(style("Medium")).toBe(high)
        expect(style("Invalid")).toBe(high)
        expect(style("Low")).toBe(low)

        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = high.FillTransparency
        highlight.OutlineTransparency = high.OutlineTransparency
        -- Restyling is an in-place property update, not a replacement.
        highlight.FillTransparency = low.FillTransparency
        highlight.OutlineTransparency = low.OutlineTransparency
        -- Highlight uses 32-bit float storage, while Luau recipe numbers
        -- are 64-bit. Check the visible precision rather than bit-exactness.
        expect(math.abs(highlight.FillTransparency - low.FillTransparency) < 0.0001).toBe(true)
        expect(math.abs(highlight.OutlineTransparency - low.OutlineTransparency) < 0.0001).toBe(true)
        highlight.FillTransparency = high.FillTransparency
        highlight.OutlineTransparency = high.OutlineTransparency
        expect(math.abs(highlight.FillTransparency - high.FillTransparency) < 0.0001).toBe(true)
        expect(math.abs(highlight.OutlineTransparency - high.OutlineTransparency) < 0.0001).toBe(true)
        highlight:Destroy()
    end)

    it("provides tier-bounded outlines and a smaller reduced-motion budget", function()
        local count = WarningSignatures.count
        expect(count("Freeze", "Low", false)).toBe(4)
        expect(count("Freeze", "Medium", false)).toBe(6)
        expect(count("Freeze", "High", false)).toBe(8)
        expect(count("Freeze", "High", true)).toBe(2)
        expect(count("JumpShock", "Low", false)).toBe(1)
        expect(count("JumpShock", "Medium", false)).toBe(3)
        expect(count("JumpShock", "High", false)).toBe(4)
        expect(count("JumpShock", "High", true)).toBe(1)
        expect(count("Unknown", "High", false)).toBe(0)
        expect(count("Freeze", "Unknown", false)).toBe(4)
    end)

    it("draws a genuinely hollow, collisionless world-space warning contour", function()
        local GroundOutline = require("../../src/client/HazardGroundOutlineKit")
        local decor = Instance.new("Folder")
        local meteor = GroundOutline.create(decor, "Meteor")
        expect(meteor ~= nil).toBe(true)
        expect(meteor.part.Transparency).toBe(1)
        expect(meteor.part.CanCollide).toBe(false)
        expect(meteor.part.CanTouch).toBe(false)
        expect(meteor.part.CanQuery).toBe(false)
        expect(meteor.canvas.Face).toBe(Enum.NormalId.Top)
        expect(meteor.outer.Parent.BackgroundTransparency).toBe(1)
        expect(meteor.inner.Parent.BackgroundTransparency).toBe(1)

        GroundOutline.update(
            meteor, Vector3.new(8, 2, -5), 16, 0.25, false, 0.5, "High"
        )
        expect(meteor.part.Size.X > 16).toBe(true)
        expect(meteor.part.Size.X < 20).toBe(true)
        -- Roblox stores Part.Size components in 32-bit floats.
        expect(math.abs(meteor.part.Size.Y - 0.08) < 0.001).toBe(true)
        expect(meteor.inner.Enabled).toBe(true)
        expect(meteor.ticks[1].Visible).toBe(true)

        local initialWidth = meteor.part.Size.X
        GroundOutline.update(
            meteor, Vector3.new(8, 2, -5), 16, 0.25, true, 0.9, "Low"
        )
        expect(meteor.inner.Enabled).toBe(false)
        expect(meteor.ticks[1].Visible).toBe(false)
        expect(meteor.part.Size.X ~= initialWidth).toBe(true)

        local bomb = GroundOutline.create(decor, "Bomb")
        expect(bomb ~= nil).toBe(true)
        expect(bomb.outer.Color ~= meteor.outer.Color).toBe(true)
        GroundOutline.destroy(meteor)
        GroundOutline.destroy(bomb)
        expect(#decor:GetChildren()).toBe(0)
        decor:Destroy()
    end)

    it("keeps reduced-motion outlines static and rejects malformed sizing", function()
        local GroundOutline = require("../../src/client/HazardGroundOutlineKit")
        expect(GroundOutline.recipe("Other", 16, 0, false, 0.5, "High")).toBe(nil)
        expect(GroundOutline.recipe("Meteor", 0, 0, false, 0.5, "High")).toBe(nil)
        expect(GroundOutline.recipe("Bomb", math.huge, 0, false, 0.5, "High")).toBe(nil)
        local huge = GroundOutline.recipe("Meteor", 1e8, 3, false, 0.5, "Low")
        expect(huge.Diameter <= 270).toBe(true)
        expect(huge.OuterTransparency < 1).toBe(true)
        local still = GroundOutline.recipe("Bomb", 16, 0.3, true, 0.1, "High")
        local other = GroundOutline.recipe("Bomb", 16, 0.3, true, 0.9, "High")
        expect(still.Diameter).toBe(other.Diameter)
        expect(still.OuterTransparency).toBe(other.OuterTransparency)
    end)

    it("shows a static full impact footprint with ReduceMotion enabled", function()
        local diameter = WarningSignatures.visualDiameter
        expect(diameter(5.5, 16, 0, false)).toBe(5.5)
        expect(diameter(5.5, 16, 0.5, false)).toBe(10.75)
        expect(diameter(5.5, 16, 1, false)).toBe(16)
        expect(diameter(5.5, 16, 0, true)).toBe(16)
        expect(diameter(5.5, 16, 0.5, true)).toBe(16)
        expect(diameter(5.5, 16, 1, true)).toBe(16)
        expect(diameter(5.5, 16, 5, false)).toBe(16)
        expect(diameter(0, 16, 0, true)).toBe(nil)
        expect(diameter(5.5, math.huge, 0, true)).toBe(nil)
        expect(diameter(5.5, 0 / 0, 0, false)).toBe(nil)

        local outline = require("../../src/client/HazardGroundOutlineKit")
        local first = outline.recipe("Meteor", 16, 0, true, 0, "High")
        local last = outline.recipe("Meteor", 16, 1, true, 1, "High")
        expect(first.Diameter).toBe(last.Diameter)
        expect(first.OuterTransparency).toBe(last.OuterTransparency)
        expect(first.InnerTransparency).toBe(last.InnerTransparency)
        expect(first.TicksVisible).toBe(false)
        local animated = outline.recipe("Meteor", 16, 1, false, 0.7, "High")
        expect(animated.OuterTransparency > first.OuterTransparency).toBe(true)
    end)

    it("uses the correct initial diameter for late-joining warning viewers", function()
        -- The local Part and contour must agree immediately, even before
        -- the first 30 Hz render update on a slower Android device.
        local diameter = WarningSignatures.visualDiameter
        local startSize, endSize, elapsedFraction = 5.5, 16, 0.75
        local initial = diameter(startSize, endSize, elapsedFraction, false)
        expect(math.abs(initial - 13.375) < 0.001).toBe(true)
        expect(diameter(startSize, endSize, elapsedFraction, true)).toBe(16)

        -- Global JumpShock also starts at its replicated elapsed fraction;
        -- it must not flash an 8-stud cylinder on a 150-stud arena.
        expect(diameter(8, 150, 0.75, false)).toBe(114.5)
        expect(diameter(8, 150, 0.75, true)).toBe(150)
    end)

    it("starts late-arriving bomb and meteor signatures at the remaining warning time", function()
        local window = WarningSignatures.window
        local remaining, progress = window(100, 1.25, 100)
        expect(remaining).toBe(1.25)
        expect(progress).toBe(0)

        local halfRemaining, halfProgress = window(100, 1.25, 100.625)
        expect(math.abs(halfRemaining - 0.625) < 0.001).toBe(true)
        expect(math.abs(halfProgress - 0.5) < 0.001).toBe(true)
        local over, done = window(100, 1.25, 102)
        expect(over).toBe(0)
        expect(done).toBe(1)
        expect(window(nil, 1.25, 100)).toBe(nil)
        expect(window(100, 0, 100)).toBe(nil)
        expect(window(100, 1, nil)).toBe(nil)
        expect(window(100, 1, math.huge)).toBe(nil)
        expect(window(100, 1, 0 / 0)).toBe(nil)
        local capped = window(100, 50, 100)
        expect(capped).toBe(2.5)
    end)

    it("guides escape using final radius and actual 3D damage distance", function()
        local clearance = WarningSignatures.escapeClearance
        local impact = Vector3.new(0, 0, 0)
        -- The initial MeteorWarning disc is 5.5 studs, but the final
        -- radius is 8 studs. A player 7 studs away is NOT safe.
        expect(clearance(Vector3.new(7, 0, 0), impact, 16)).toBe(-1)
        expect(clearance(Vector3.new(7, 50, 0), impact, 16) > 40).toBe(true)
        -- In the Towers arena a player on a raised deck may be outside
        -- the 3D blast while still directly above the visual ground disc.
        expect(clearance(Vector3.new(0, 10, 0), impact, 16)).toBe(2)
        expect(clearance(Vector3.new(10, 0, 0), impact, 16)).toBe(2)
        expect(clearance(Vector3.new(0, 0, 0), impact, 16)).toBe(-8)
        expect(clearance(nil, impact, 16)).toBe(nil)
        expect(clearance(impact, nil, 16)).toBe(nil)
        expect(clearance(impact, impact, 0)).toBe(nil)
        expect(clearance(impact, impact, math.huge)).toBe(nil)
    end)

    it("keeps a usable escape direction at the exact center of an impact", function()
        local direction = WarningSignatures.escapeDirection
        local impact = Vector3.new(10, 1.2, -4)
        local facing = Vector3.new(0, 0, -1)

        local center = direction(Vector3.new(10, 1.2, -4), impact, facing)
        expect(center).toBe(facing)

        -- Characters can be above or below the marker: the horizontal
        -- radial escape is still undefined, so use the facing fallback.
        local elevated = direction(Vector3.new(10, 13, -4), impact, facing)
        expect(elevated).toBe(facing)

        -- Outside the marker center, actual escape direction takes precedence
        -- over orientation, including the minimum 0.15-stud threshold.
        local outward = direction(Vector3.new(13, 1.2, -4), impact, facing)
        expect(outward).toBe(Vector3.new(1, 0, 0))
        expect(direction(Vector3.new(10.2, 1.2, -4), impact, facing)).toBe(
            Vector3.new(1, 0, 0)
        )

        expect(direction(Vector3.new(10, 1.2, -4), impact, nil)).toBe(nil)
        expect(direction(Vector3.new(10, 1.2, -4), impact, Vector3.yAxis)).toBe(nil)
        expect(direction(nil, impact, facing)).toBe(nil)
        expect(direction(impact, nil, facing)).toBe(nil)
    end)

    it("bounds concurrent warning silhouettes across graphics tiers", function()
        local limit = WarningSignatures.activeLimit
        expect(limit("Low", false)).toBe(6)
        expect(limit("Medium", false)).toBe(10)
        expect(limit("High", false)).toBe(14)
        expect(limit("High", true)).toBe(4)
        expect(limit("Low", true)).toBe(4)
        expect(limit("Invalid", false)).toBe(6)
    end)

    it("keeps ice and shock signatures distinct at all warning stages", function()
        for _, kind in ipairs({"Freeze", "JumpShock"}) do
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local count = WarningSignatures.count(kind, tier, false)
                for index = 1, count do
                    local early = WarningSignatures.recipe(
                        kind, index, count, 150, 0
                    )
                    local late = WarningSignatures.recipe(
                        kind, index, count, 150, 1
                    )
                    expect(early ~= nil and late ~= nil).toBe(true)
                    expect(early.Wedge).toBe(kind == "Freeze")
                    expect(early.Material).toBe(
                        kind == "Freeze" and Enum.Material.Glass
                            or Enum.Material.Neon
                    )
                    expect(typeof(early.Color)).toBe("Color3")
                    expect(typeof(early.SecondaryColor)).toBe("Color3")
                    expect(early.Secondary).toBe(index % 2 == 0)
                    expect(early.Size.X >= 1 and early.Size.X <= 12).toBe(true)
                    expect(early.Size.Y > 0 and early.Size.Y < 0.2).toBe(true)
                    expect(early.Offset.Y >= 0.10 and early.Offset.Y <= 0.20).toBe(true)
                    expect(early.Size.X <= late.Size.X).toBe(true)
                    expect(early.Transparency <= late.Transparency).toBe(true)
                    expect(late.Transparency < 0.95).toBe(true)
                end
            end
        end
    end)

    it("places warnings in the rotated deck frame without moving server hazard", function()
        local pos = Vector3.new(10, 4, -7)
        local deck = CFrame.new(24, 6, 15)
            * CFrame.Angles(math.rad(14), math.rad(55), math.rad(-9))
        local frame = WarningSignatures.frame(pos, deck)
        expect(frame.Position).toBe(pos)
        expect(frame.UpVector:Dot(deck.UpVector) > 0.999).toBe(true)
        for _, kind in ipairs({"Freeze", "JumpShock"}) do
            local count = WarningSignatures.count(kind, "High", false)
            for index = 1, count do
                local style = WarningSignatures.recipe(kind, index, count, 100, 0.4)
                local cf = frame * CFrame.new(style.Offset) * style.Rotation
                expect(typeof(cf)).toBe("CFrame")
                local localPoint = frame:PointToObjectSpace(cf.Position)
                expect((localPoint - style.Offset).Magnitude < 0.001).toBe(true)
                local part = Instance.new(style.Wedge and "WedgePart" or "Part")
                part.Size = style.Size
                part.CFrame = cf
                part.Material = style.Material
                part.Anchored = true
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.CastShadow = false
                expect(part.Size.Z < 0.5).toBe(true)
                expect(part.Anchored).toBe(true)
                expect(part.CanCollide).toBe(false)
                part:Destroy()
            end
        end
        expect(WarningSignatures.frame(pos, nil).Position).toBe(pos)
        expect(WarningSignatures.frame(nil, deck) == nil).toBe(true)
    end)

    it("guides timed Jump Shock dodges in English and French", function()
        local label = WarningSignatures.label
        local prompt = WarningSignatures.jumpPrompt
        expect(label("Meteor", "en-us", Localization)).toBe("DODGE")
        expect(label("Meteor", "fr-fr", Localization)).toBe("ESQUIVE")
        expect(label("Bomb", "en-us", Localization)).toBe("MOVE OUT")
        expect(label("Bomb", "fr-fr", Localization)).toBe("ÉCARTE-TOI")
        expect(label("Freeze", "en-us", Localization)).toBe("FREEZE")
        expect(label("Freeze", "fr-fr", Localization)).toBe("GEL")
        expect(label("JumpShock", "en-us", Localization)).toBe("GET READY")
        expect(label("JumpShock", "fr-fr", Localization)).toBe("PRÉPARE-TOI")
        expect(prompt(1.05, "en-us", Localization)).toBe("GET READY")
        expect(prompt(0.43, "fr-fr", Localization)).toBe("PRÉPARE-TOI")
        expect(prompt(0.42, "en-us", Localization)).toBe("JUMP!")
        expect(prompt(0.35, "fr-fr", Localization)).toBe("SAUTE !")
        expect(prompt(0.1, "en-us", Localization)).toBe("JUMP!")
        expect(prompt(0, "en-us", Localization) == nil).toBe(true)
        expect(prompt(-1, "fr-fr", Localization) == nil).toBe(true)
        expect(prompt(nil, "en-us", Localization) == nil).toBe(true)
        expect(prompt(math.huge, "en-us", Localization) == nil).toBe(true)
        expect(prompt(0 / 0, "en-us", Localization) == nil).toBe(true)
        expect(Localization.hazardAction("en-us", "JumpShock")).toBe("TIME YOUR JUMP")
        expect(Localization.hazardAction("fr-fr", "JumpShock")).toBe("SAUTE AU BON MOMENT")
        expect(label("Unknown", "fr-fr", Localization) == nil).toBe(true)
        expect(label("Freeze", "en-us", nil)).toBe("FREEZE")
    end)

    it("adapts live shock warning geometry counts across quality and ReduceMotion", function()
        local count = WarningSignatures.count
        local transitions = {
            {"High", false, 4},
            {"Medium", false, 3},
            {"Low", false, 1},
            {"High", true, 1},
            {"High", false, 4},
        }
        for _, entry in ipairs(transitions) do
            expect(count("JumpShock", entry[1], entry[2])).toBe(entry[3])
            for i = 1, entry[3] do
                local design = WarningSignatures.recipe(
                    "JumpShock", i, entry[3], 70, 0.55
                )
                expect(design ~= nil).toBe(true)
                expect(design.Wedge).toBe(false)
                expect(design.Material).toBe(Enum.Material.Neon)
            end
        end
        expect(count("JumpShock", "Invalid", true)).toBe(1)
    end)

    it("rejects malformed stroke requests and clamps oversized arena markers", function()
        local recipe = WarningSignatures.recipe
        expect(recipe("Other", 1, 3, 100, 0) == nil).toBe(true)
        expect(recipe("Freeze", 0, 4, 100, 0) == nil).toBe(true)
        expect(recipe("Freeze", 5, 4, 100, 0) == nil).toBe(true)
        expect(recipe("Freeze", 1, 0, 100, 0) == nil).toBe(true)
        expect(recipe("Freeze", 1, 9, 100, 0) == nil).toBe(true)
        expect(recipe("Freeze", 1, 4, 0, 0) == nil).toBe(true)
        local huge = recipe("JumpShock", 1, 4, 10000, 0.5)
        expect(huge.Size.X <= 12).toBe(true)
        local before = recipe("Freeze", 1, 4, 150, -1)
        local after = recipe("Freeze", 1, 4, 150, 2)
        expect(before.Transparency < after.Transparency).toBe(true)
    end)
end)

describe("Bomb Rain visible 3D charge anticipation", function()
    it("budgets a legible charge silhouette for all Android tiers", function()
        for _, case in ipairs({
            {tier = "Low", count = 1, distance = 65, maxActive = 2},
            {tier = "Medium", count = 3, distance = 100, maxActive = 3},
            {tier = "High", count = 5, distance = 125, maxActive = 4},
        }) do
            local profile = BombChargeRules.profile(case.tier, false)
            expect(profile.Count).toBe(case.count)
            expect(profile.MaxDistance).toBe(case.distance)
            expect(profile.MaxActive).toBe(case.maxActive)
            expect(BombChargeRules.profile(case.tier, true).Count).toBe(1)
            expect(BombChargeRules.visible(case.tier, case.distance, 1)).toBe(true)
            expect(BombChargeRules.visible(case.tier, case.distance + 1, 1)).toBe(false)
            expect(BombChargeRules.visible(case.tier, 2, case.maxActive)).toBe(true)
            expect(BombChargeRules.visible(case.tier, 2, case.maxActive + 1)).toBe(false)
        end
        expect(BombChargeRules.visible("High", 0 / 0, 1)).toBe(false)
        expect(BombChargeRules.visible("High", math.huge, 1)).toBe(false)
        expect(BombChargeRules.visible("High", -1, 1)).toBe(false)
        expect(BombChargeRules.visible("High", 4, 0)).toBe(false)
        expect(BombChargeRules.visible("High", 4, 1.5)).toBe(false)
        expect(BombChargeRules.recipe(1, 5, 0 / 0, false)).toBe(nil)
        expect(BombChargeRules.recipe(1, 6, 0.5, false)).toBe(nil)
        expect(BombChargeRules.recipe(6, 5, 0.5, false)).toBe(nil)
        expect(BombChargeRules.recipe(1, 5, 0.5, false).Shape).toBe("Ball")
        expect(BombChargeRules.recipe(2, 5, 0.5, false).Shape).toBe("Wedge")
        expect(BombChargeRules.recipe(4, 5, 0.5, false).Material)
            .toBe(Enum.Material.Neon)
    end)

    it("moves toward the actual detonation time but stays static for reduced motion", function()
        local early = BombChargeRules.recipe(1, 5, 0, false)
        local late = BombChargeRules.recipe(1, 5, 0.95, false)
        expect(early.Transform.Position.Y > late.Transform.Position.Y + 4)
            .toBe(true)
        local reducedEarly = BombChargeRules.recipe(1, 1, 0, true)
        local reducedLate = BombChargeRules.recipe(1, 1, 0.95, true)
        expect(reducedEarly.Transform).toBe(reducedLate.Transform)
        expect(reducedEarly.Size).toBe(reducedLate.Size)
    end)

    it("creates no-collision client parts and reuses them during a warning", function()
        local marker = Instance.new("Part")
        marker.Name = "BombWarning"
        marker.Anchored = true
        marker.Position = Vector3.new(16, 2, -9)
        marker.Parent = workspace

        local folder = Instance.new("Folder")
        folder.Parent = workspace
        local viewer = Vector3.new(16, 6, -9)
        local state = {parts = {}}
        BombChargeKit.sync(
            state, marker, folder, "High", false, 0, viewer, 1, BombChargeRules
        )
        expect(#state.parts).toBe(5)
        expect(#folder:GetChildren()).toBe(5)
        local core = state.parts[1]
        local originalHeight = core.Position.Y
        expect(core.Shape).toBe(Enum.PartType.Ball)
        for _, piece in ipairs(state.parts) do
            expect(piece.Anchored).toBe(true)
            expect(piece.CanCollide).toBe(false)
            expect(piece.CanTouch).toBe(false)
            expect(piece.CanQuery).toBe(false)
            expect(piece.CastShadow).toBe(false)
            expect(piece.Parent).toBe(folder)
        end
        BombChargeKit.sync(
            state, marker, folder, "High", false, 0.85, viewer, 1, BombChargeRules
        )
        expect(state.parts[1]).toBe(core)
        expect(core.Position.Y < originalHeight - 3).toBe(true)
        expect(#folder:GetChildren()).toBe(5)

        BombChargeKit.sync(
            state, marker, folder, "Low", false, 0.86, viewer, 1, BombChargeRules
        )
        expect(#state.parts).toBe(1)
        expect(state.parts[1]).toBe(core)
        expect(#folder:GetChildren()).toBe(1)
        BombChargeKit.sync(
            state, marker, folder, "High", true, 0.1, viewer, 1, BombChargeRules
        )
        local reducedPose = core.CFrame
        BombChargeKit.sync(
            state, marker, folder, "High", true, 0.9, viewer, 1, BombChargeRules
        )
        expect(core.CFrame).toBe(reducedPose)

        BombChargeKit.sync(
            state, marker, folder, "High", false, 0.9,
            Vector3.new(1000, 0, 0), 1, BombChargeRules
        )
        expect(#state.parts).toBe(0)
        expect(#folder:GetChildren()).toBe(0)
        BombChargeKit.sync(
            state, marker, folder, "Medium", false, 0.4, viewer, 1, BombChargeRules
        )
        expect(#state.parts).toBe(3)
        marker:Destroy()
        BombChargeKit.sync(
            state, marker, folder, "Medium", false, 0.4, viewer, 1, BombChargeRules
        )
        expect(#state.parts).toBe(0)
        expect(#folder:GetChildren()).toBe(0)
        BombChargeKit.clear(state)
        BombChargeKit.clear(nil)
        folder:Destroy()
    end)
end)


describe("Tiered frost armor for frozen R6 and R15 avatars", function()
    it("clamps local ice facets to phone budgets and accessibility mode", function()
        expect(FrozenArmorKit.count("Low", false)).toBe(1)
        expect(FrozenArmorKit.count("Medium", false)).toBe(3)
        expect(FrozenArmorKit.count("High", false)).toBe(5)
        expect(FrozenArmorKit.count("High", true)).toBe(1)
        expect(FrozenArmorKit.count("Unknown", false)).toBe(0)
        expect(#FrozenArmorKit.build(nil, "High", false)).toBe(0)
        FrozenArmorKit.clear(nil)
    end)

    it("uses non-physical torso welds on both avatar rigs and cleans up", function()
        for _, torsoName in ipairs({"UpperTorso", "Torso"}) do
            local character = Instance.new("Model")
            character.Name = "FrozenAvatarTest"
            character.Parent = workspace
            local torso = Instance.new("Part")
            torso.Name = torsoName
            torso.Anchored = true
            torso.Size = Vector3.new(2, 2.3, 1)
            torso.CFrame = CFrame.new(13, 20, -8)
            torso.Parent = character

            local high = FrozenArmorKit.build(character, "High", false)
            expect(#high).toBe(5)
            expect(#torso:GetChildren()).toBe(5)
            for _, facet in ipairs(high) do
                expect(facet:IsA("WedgePart")).toBe(true)
                expect(facet.Parent).toBe(torso)
                expect(facet.Anchored).toBe(false)
                expect(facet.Massless).toBe(true)
                expect(facet.CanCollide).toBe(false)
                expect(facet.CanTouch).toBe(false)
                expect(facet.CanQuery).toBe(false)
                expect(facet.CastShadow).toBe(false)
                local weld = facet:FindFirstChildOfClass("WeldConstraint")
                expect(weld ~= nil).toBe(true)
                if weld then
                    expect(weld.Part0).toBe(torso)
                    expect(weld.Part1).toBe(facet)
                end
            end

            FrozenArmorKit.clear(high)
            expect(#torso:GetChildren()).toBe(0)
            local mobile = FrozenArmorKit.build(character, "Medium", false)
            expect(#mobile).toBe(3)
            FrozenArmorKit.clear(mobile)
            local reduced = FrozenArmorKit.build(character, "High", true)
            expect(#reduced).toBe(1)
            FrozenArmorKit.clear(reduced)
            expect(#torso:GetChildren()).toBe(0)
            character:Destroy()
        end
    end)
end)

return nil
