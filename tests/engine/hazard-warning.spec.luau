--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local HazardWarning = require("../../src/server/HazardWarning")
local Localization = require("../../src/shared/CoreLocalization")
local WarningSignatures = require("../../src/shared/HazardWarningSignatureRules")

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

    it("uses localized danger actions and never falsely instructs JumpShock players to jump", function()
        local label = WarningSignatures.label
        expect(label("Meteor", "en-us", Localization)).toBe("DODGE")
        expect(label("Meteor", "fr-fr", Localization)).toBe("ESQUIVE")
        expect(label("Bomb", "en-us", Localization)).toBe("MOVE OUT")
        expect(label("Bomb", "fr-fr", Localization)).toBe("ÉCARTE-TOI")
        expect(label("Freeze", "en-us", Localization)).toBe("FREEZE")
        expect(label("Freeze", "fr-fr", Localization)).toBe("GEL")
        expect(label("JumpShock", "en-us", Localization)).toBe("SHOCKWAVE")
        expect(label("JumpShock", "fr-fr", Localization)).toBe("ONDE DE CHOC")
        expect(label("JumpShock", "en-us", Localization) ~= "JUMP").toBe(true)
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

return nil
