--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterResidue = require("../../src/shared/DisasterResidue")

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

return nil
