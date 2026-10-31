--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaMaterialRules = require("../../src/shared/ArenaMaterialRules")
local PbrDistrictRules = require("../../src/shared/PbrDistrictRules")

describe("PBR protection for original Harbor timber", function()
    it("leaves wood and plank faces out of the metallic 2K candidate pool", function()
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Size = Vector3.new(10, 2, 7)
        for _, material in ipairs({Enum.Material.Wood, Enum.Material.WoodPlanks}) do
            part.Material = material
            expect(PbrDistrictRules.eligiblePart(part)).toBe(false)
        end
        part.Material = Enum.Material.Metal
        expect(PbrDistrictRules.eligiblePart(part)).toBe(true)
        part:Destroy()
    end)
end)

describe("Arena material rules", function()
    it("leaves all materials unchanged on low quality", function()
        expect(ArenaMaterialRules.targetMaterial(
            "Towers",
            Enum.Material.Metal,
            0,
            "Low"
        )).toBe(Enum.Material.Metal)
    end)

    it("gives each arena a distinct secondary material language", function()
        expect(ArenaMaterialRules.targetMaterial(
            "Classic",
            Enum.Material.Metal,
            0,
            "High"
        )).toBe(Enum.Material.DiamondPlate)

        expect(ArenaMaterialRules.targetMaterial(
            "Towers",
            Enum.Material.Metal,
            0,
            "High"
        )).toBe(Enum.Material.CorrodedMetal)

        expect(ArenaMaterialRules.targetMaterial(
            "Crossroads",
            Enum.Material.Metal,
            0,
            "High"
        )).toBe(Enum.Material.Concrete)

        expect(ArenaMaterialRules.targetMaterial(
            "Orbital",
            Enum.Material.SmoothPlastic,
            0,
            "High"
        )).toBe(Enum.Material.Metal)
    end)

    it("only swaps the deterministic budgeted fraction", function()
        expect(ArenaMaterialRules.targetMaterial(
            "Classic",
            Enum.Material.Metal,
            99,
            "High"
        )).toBe(Enum.Material.Metal)

        expect(ArenaMaterialRules.targetMaterial(
            "Classic",
            Enum.Material.Metal,
            25,
            "Medium"
        )).toBe(Enum.Material.Metal)
    end)
end)

return nil
