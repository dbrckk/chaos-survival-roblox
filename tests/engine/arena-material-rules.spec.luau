--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaMaterialRules = require("../../src/shared/ArenaMaterialRules")

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
            Enum.Material.Metal,
            0,
            "High"
        )).toBe(Enum.Material.SmoothPlastic)

        expect(ArenaMaterialRules.targetMaterial(
            "Orbital",
            Enum.Material.DiamondPlate,
            0,
            "High"
        )).toBe(Enum.Material.SmoothPlastic)
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
