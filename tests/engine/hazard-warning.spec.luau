--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local HazardWarning = require("../../src/server/HazardWarning")
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
