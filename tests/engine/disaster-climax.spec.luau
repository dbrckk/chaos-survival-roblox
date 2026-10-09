--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterClimax = require("../../src/shared/DisasterClimax")
local Signature = require("../../src/client/DisasterClimaxSignatureKit")

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

describe("Disaster climax progression", function()
    it("covers every disaster with a unique climax profile", function()
        local kinds = {}
        for _, id in ipairs(IDS) do
            local profile = DisasterClimax.get(id)
            expect(profile ~= nil).toBe(true)
            expect(type(profile.Kind)).toBe("string")
            expect(typeof(profile.Color)).toBe("Color3")
            expect(typeof(profile.Secondary)).toBe("Color3")
            kinds[profile.Kind] = true
        end
        expect(#IDS).toBe(11)
        expect(next(kinds) ~= nil).toBe(true)
    end)

    it("progresses through surge and critical stages from intensity", function()
        expect(DisasterClimax.stageFor(0.90, false, false)).toBe(0)
        expect(DisasterClimax.stageFor(0.98, false, false)).toBe(1)
        expect(DisasterClimax.stageFor(1.06, false, false)).toBe(2)
    end)

    it("promotes overdrive to the critical visual stage", function()
        expect(DisasterClimax.stageFor(0.90, false, true)).toBe(2)
        expect(DisasterClimax.stageFor(1.02, false, true)).toBe(2)
    end)

    it("always gives final rush the highest climax stage", function()
        expect(DisasterClimax.stageFor(0.88, true, false)).toBe(3)
        expect(DisasterClimax.stageFor(1.12, true, true)).toBe(3)
    end)
end)

describe("Distinct frost and electric climax silhouettes", function()
    it("offers different geometric recipes without opaque circular discs", function()
        for _, kind in ipairs({"freeze", "shock"}) do
            for _, stage in ipairs({1, 2, 3}) do
                for _, tier in ipairs({"Low", "Medium", "High"}) do
                    local count = Signature.count(tier, false)
                    expect(count == 2 or count == 4 or count == 6).toBe(true)
                    for index = 1, count do
                        local recipe = Signature.recipe(kind, index, count, 140, stage)
                        expect(recipe ~= nil).toBe(true)
                        expect(recipe.Kind).toBe(kind)
                        expect(recipe.Wedge).toBe(kind == "freeze")
                        expect(recipe.Material).toBe(kind == "freeze"
                            and Enum.Material.Ice or Enum.Material.Neon)
                        expect(recipe.Size.X > 0 and recipe.Size.Y < 0.20).toBe(true)
                        expect(recipe.GoalSize.X > 0 and recipe.GoalSize.Y < 0.20).toBe(true)
                        expect(recipe.Start.Magnitude < recipe.Finish.Magnitude).toBe(true)
                        expect(recipe.Transparency >= 0.25).toBe(true)
                    end
                end
            end
        end
        expect(Signature.count("Low", true)).toBe(2)
        expect(Signature.count("High", true)).toBe(2)
        expect(Signature.count("Invalid", false)).toBe(0)
        expect(Signature.recipe("unknown", 1, 4, 100, 1) == nil).toBe(true)
        expect(Signature.recipe("freeze", 0, 4, 100, 1) == nil).toBe(true)
        expect(Signature.recipe("freeze", 5, 4, 100, 1) == nil).toBe(true)
        expect(Signature.recipe("freeze", 1, 4, 0, 1) == nil).toBe(true)
        expect(Signature.recipe("freeze", 1, 4, 100, 0) == nil).toBe(true)
    end)

    it("keeps the fragments anchored to the local pitched deck in Roblox", function()
        local root = Instance.new("Folder")
        local deck = CFrame.new(24, 14, -18)
            * CFrame.Angles(math.rad(18), math.rad(45), math.rad(-11))
        local primary = Color3.fromRGB(90, 190, 255)
        local secondary = Color3.fromRGB(205, 245, 255)
        for _, kind in ipairs({"freeze", "shock"}) do
            for _, quality in ipairs({"Low", "Medium", "High"}) do
                local result = Signature.emit(root, kind, deck, 100, 2,
                    primary, secondary, quality, false)
                expect(#result).toBe(Signature.count(quality, false))
                for index, part in ipairs(result) do
                    expect(part:IsA(kind == "freeze" and "WedgePart" or "Part"))
                        .toBe(true)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part:GetAttribute("ChaosClimaxSignature")).toBe(kind)
                    expect(part.Shape == Enum.PartType.Cylinder).toBe(false)
                    local localPosition = deck:PointToObjectSpace(part.Position)
                    expect(math.abs(localPosition.Y - (kind == "freeze" and 0.20 or 0.15))
                        < 0.10).toBe(true)
                    expect(part.Color).toBe(index % 2 == 0 and secondary or primary)
                    part:Destroy()
                end
            end
            local quiet = Signature.emit(root, kind, deck, 100, 3,
                primary, secondary, "High", true)
            expect(#quiet).toBe(2)
            for _, part in ipairs(quiet) do
                part:Destroy()
            end
        end
        expect(#root:GetChildren()).toBe(0)
        expect(#Signature.emit(root, "invalid", deck, 100, 2,
            primary, secondary, "High", false)).toBe(0)
        expect(#Signature.emit(root, "freeze", nil, 100, 2,
            primary, secondary, "High", false)).toBe(0)
        root:Destroy()
    end)
end)

return nil
