--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterResidue = require("../../src/shared/DisasterResidue")
local AftermathSurfaceKit = require("../../src/client/AftermathSurfaceKit")
local VisualTheme = require("../../src/shared/VisualTheme")

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

return nil
