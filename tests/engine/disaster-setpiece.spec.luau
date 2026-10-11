--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterSetpiece = require("../../src/shared/DisasterSetpiece")
local DisasterIntroMotionKit = require("../../src/client/DisasterIntroMotionKit")

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

describe("Disaster setpiece profiles", function()
    it("covers all eleven disasters", function()
        for _, id in ipairs(IDS) do
            local profile = DisasterSetpiece.get(id)
            expect(profile ~= nil).toBe(true)
            expect(type(profile.Kind)).toBe("string")
            expect(typeof(profile.Color)).toBe("Color3")
            expect(typeof(profile.Secondary)).toBe("Color3")
        end
    end)

    it("preserves order for double chaos", function()
        local profiles = DisasterSetpiece.forIds({"Meteors", "Freeze"})
        expect(#profiles).toBe(2)
        expect(profiles[1].Kind).toBe("skyfall")
        expect(profiles[2].Kind).toBe("freeze")
    end)
end)


describe("Deck-aligned disaster introduction motion", function()
    it("gives five hazards separate recognisable signatures and tiered part counts", function()
        local kinds = {"freeze", "blast", "void", "collapse", "shock"}
        local profiles = {Low = 2, Medium = 4, High = 6}
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            expect(DisasterIntroMotionKit.count(tier)).toBe(profiles[tier])
            local root = Instance.new("Folder")
            local deck = CFrame.new(16, 10, -22)
                * CFrame.Angles(math.rad(12), math.rad(37), math.rad(-6))
            local primary = Color3.fromRGB(65, 165, 250)
            local secondary = Color3.fromRGB(205, 240, 255)
            for _, kind in ipairs(kinds) do
                local strokes = DisasterIntroMotionKit.emit(
                    root, kind, deck, 88, primary, secondary,
                    tier, true, 0.45
                )
                expect(#strokes).toBe(profiles[tier])
                for i, stroke in ipairs(strokes) do
                    expect(stroke:IsA("BasePart")).toBe(true)
                    expect(stroke:IsA("WedgePart") or stroke:IsA("Part")).toBe(true)
                    expect(stroke:GetAttribute("ChaosDisasterIntro")).toBe(kind)
                    expect(stroke.Anchored).toBe(true)
                    expect(stroke.CanCollide).toBe(false)
                    expect(stroke.CanTouch).toBe(false)
                    expect(stroke.CanQuery).toBe(false)
                    expect(stroke.CastShadow).toBe(false)
                    expect(stroke.Size.Y <= 0.08).toBe(true)
                    expect(stroke.Transparency >= 0.25).toBe(true)
                    expect(math.abs(stroke.CFrame.UpVector:Dot(deck.UpVector))
                        > 0.99).toBe(true)
                    expect(stroke:IsA("WedgePart")).toBe(kind == "freeze")
                    stroke:Destroy()
                end
            end
            root:Destroy()
        end
        expect(DisasterIntroMotionKit.count("Unknown")).toBe(0)
    end)

    it("distinguishes expansion, contraction and crystal signatures", function()
        local k = DisasterIntroMotionKit
        local outwards = {}
        for _, kind in ipairs({"freeze", "blast", "void", "collapse", "shock"}) do
            local recipe = k.recipe(kind, 1, 6, 100)
            expect(recipe.Kind).toBe(kind)
            expect(recipe.Size.X > 0 and recipe.Size.Y <= 0.08).toBe(true)
            expect(recipe.Size.Z <= 0.40).toBe(true)
            expect(recipe.Finish.Magnitude <= 55).toBe(true)
            expect(recipe.Start.Magnitude <= 55).toBe(true)
            outwards[kind] = recipe.Finish.X - recipe.Start.X
        end
        expect(outwards.freeze > 0).toBe(true)
        expect(outwards.blast > 0).toBe(true)
        expect(outwards.shock > 0).toBe(true)
        expect(outwards.void < 0).toBe(true)
        expect(outwards.collapse < 0).toBe(true)
        expect(k.recipe("invalid", 1, 6, 100) == nil).toBe(true)
        expect(k.recipe("freeze", 0, 6, 100) == nil).toBe(true)
        expect(k.recipe("freeze", 1, 7, 100) == nil).toBe(true)
        expect(k.recipe("freeze", 1, 6, 0) == nil).toBe(true)
    end)

    it("rejects incomplete input without creating visual pieces", function()
        local parent = Instance.new("Folder")
        local color = Color3.new(1, 1, 1)
        local k = DisasterIntroMotionKit
        expect(#k.emit(parent, "freeze", CFrame.new(), 64, color, color,
            "Unknown", false, 0.8)).toBe(0)
        expect(#k.emit(parent, "bad", CFrame.new(), 64, color, color,
            "High", false, 0.8)).toBe(0)
        expect(#k.emit(parent, "freeze", nil, 64, color, color,
            "High", false, 0.8)).toBe(0)
        expect(#k.emit(parent, "freeze", CFrame.new(), 0, color, color,
            "High", false, 0.8)).toBe(0)
        expect(#k.emit(parent, "freeze", CFrame.new(), 64, color, color,
            "High", false, 0)).toBe(0)
        expect(#parent:GetChildren()).toBe(0)
        parent:Destroy()
    end)
end)

return nil
