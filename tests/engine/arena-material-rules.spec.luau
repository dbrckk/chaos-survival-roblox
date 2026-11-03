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

        -- Reuse this existing material ownership regression case to
        -- establish genuine 2K relief on newly authored I-beam faces.
        -- No broader imported MeshPart/foreign model can enter the pool.
        local owned = Instance.new("Model")
        owned:SetAttribute("Original3DAssetId", 95878714550124)
        owned:SetAttribute("CosmeticOnly", true)
        owned:SetAttribute("ChaosDistantScenery", true)
        owned:SetAttribute("OriginalFoundationBuilt", true)
        local steel = Instance.new("Part")
        steel.Name = "OriginalChassisFrontIBeam"
        steel.Size = Vector3.new(18, 0.52, 0.68)
        steel.Anchored = true
        steel.CanCollide = false
        steel.CanTouch = false
        steel.CanQuery = false
        steel.Material = Enum.Material.DiamondPlate
        steel:SetAttribute("OriginalFoundationVisual", true)
        steel.Parent = owned
        expect(PbrDistrictRules.eligibleOwner(owned)).toBe(true)
        expect(PbrDistrictRules.eligiblePart(steel)).toBe(true)
        expect(PbrDistrictRules.materialKey(steel.Name, steel.Material, owned))
            .toBe("armor")
        -- High/Medium owner quotas were already 2/1. The two real I-beams
        -- must outrank the flat original foundation in those very slots,
        -- otherwise the new PBR relief is eligible but never rendered.
        local flat = Instance.new("Part")
        flat.Name = "FoundationShoulder"
        flat.Size = Vector3.new(29, 0.62, 13)
        flat.Material = Enum.Material.Metal
        flat.Anchored = true
        flat.CanCollide = false
        flat.CanTouch = false
        flat.CanQuery = false
        flat:SetAttribute("OriginalFoundationVisual", true)
        flat.Parent = owned
        expect(PbrDistrictRules.eligiblePart(flat)).toBe(true)
        expect(PbrDistrictRules.priority(steel) > PbrDistrictRules.priority(flat))
            .toBe(true)
        expect(PbrDistrictRules.ownerLimit("Medium", owned)).toBe(1)
        expect(PbrDistrictRules.ownerLimit("High", owned)).toBe(2)
        flat:Destroy()
        steel:SetAttribute("OriginalFoundationVisual", false)
        expect(PbrDistrictRules.eligiblePart(steel)).toBe(false)
        steel:SetAttribute("OriginalFoundationVisual", true)
        steel.Name = "OriginalTaperedLoadButtress1"
        expect(PbrDistrictRules.eligiblePart(steel)).toBe(false)
        steel.Name = "OriginalChassisFrontIBeam"
        owned:SetAttribute("Original3DAssetId", 0)
        expect(PbrDistrictRules.eligibleOwner(owned)).toBe(false)
        expect(PbrDistrictRules.eligiblePart(steel)).toBe(false)
        owned:Destroy()
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
