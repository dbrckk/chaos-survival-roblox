--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaMaterialRules = require("../../src/shared/ArenaMaterialRules")
local PbrDistrictRules = require("../../src/shared/PbrDistrictRules")
local DistrictMaterialFinishKit = require("../../src/client/DistrictMaterialFinishKit")
local PremiumNearfieldPbrKit = require("../../src/client/PremiumNearfieldPbrKit")

describe("Authentic P4 nearfield 2K sculpture finishes", function()
    it("caps entire approved source Models based on device, quality and pressure", function()
        local rule = PremiumNearfieldPbrKit.budget
        expect(rule("Low", 0, true, false)).toBe(0)
        expect(rule("Medium", 0, true, false)).toBe(2)
        expect(rule("High", 0, true, false)).toBe(4)
        expect(rule("Medium", 0, false, false)).toBe(3)
        expect(rule("High", 0, false, false)).toBe(6)
        expect(rule("Medium", 1, true, false)).toBe(1)
        expect(rule("High", 1, true, false)).toBe(2)
        expect(rule("High", 2, true, false)).toBe(0)
        expect(rule("High", math.huge, true, false)).toBe(4)
        expect(rule("High", 0, true, true)).toBe(0)
        expect(rule("Untrusted", 0, false, false)).toBe(0)
    end)

    it("textures authored steel and ceramic while preserving signals and grip", function()
        local finish = PremiumNearfieldPbrKit.finishFor
        expect(finish("ARMOR_MilledShell", "Classic")).toBe("DiamondArmor")
        expect(finish("ARMOR_MilledShell", "Crossroads")).toBe("OxidizedSteel")
        expect(finish("BRUSHED_Support", "Towers")).toBe("BrushedTitanium")
        expect(finish("ALLOY_Fastener", "Orbital")).toBe("BrushedTitanium")
        expect(finish("CERAMIC_Panel", "Orbital")).toBe("ReactorCeramic")
        expect(finish("SIGNAL_Arrow", "Crossroads")).toBe(nil)
        expect(finish("GRIP_NonSlip", "Classic")).toBe(nil)
        expect(finish("CARBON_Insulator", "Towers")).toBe(nil)
        expect(finish("GLASS_Lens", "Orbital")).toBe(nil)
        expect(finish("UNKNOWN", "Classic")).toBe(nil)
    end)
end)

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

describe("Five authored PBR-safe near-field industrial service door finishes", function()
    it("creates unique bounded geometry-free door finish per arena", function()
        local designs = {
            {"Classic", "SURVEY / GRID", "SurveyGauge"},
            {"Towers", "LIFT / LOAD", "HoistReinforcement"},
            {"Crossroads", "ROUTE / XFER", "ExchangeRoute"},
            {"Orbital", "REACTOR / SEAL", "ContainmentCollar"},
            {"Harbor", "QUAY / HATCH", "QuayHatchRib"},
        }
        for _, design in ipairs(designs) do
            local door = Instance.new("Part")
            door.Name = "ServiceEntryDoor"
            door.Size = Vector3.new(4.65, 4.68, 0.18)
            door.Anchored = true
            door.Material = Enum.Material.CorrodedMetal
            door.Color = Color3.fromRGB(77, 93, 101)
            local beforeMaterial, beforeColor, beforeSize =
                door.Material, door.Color, door.Size
            local gui = DistrictMaterialFinishKit.stencil(
                door, "N-01 / CARGO",
                Color3.fromRGB(70, 195, 211),
                "High", "service-door", Enum.NormalId.Front, design[1])
            expect(gui ~= nil).toBe(true)
            if gui then
                expect(gui.Parent == door).toBe(true)
                expect(gui.MaxDistance).toBe(145)
                expect(gui.PixelsPerStud).toBe(24)
                expect(gui.AlwaysOnTop).toBe(false)
                expect(gui:FindFirstChild("ForgedDoorRecess") ~= nil)
                    .toBe(true)
                expect(gui:FindFirstChild("DistrictTechnicalBand") ~= nil)
                    .toBe(true)
                expect(gui:FindFirstChild("ServiceDoorNumberPlate") ~= nil)
                    .toBe(true)
                local tag = gui:FindFirstChild("IndustrialFamilyMark", true)
                expect(tag ~= nil).toBe(true)
                if tag then
                    expect(tag.Text).toBe(design[2])
                end
                local motif = gui:FindFirstChild(design[3] .. "1", true)
                expect(motif ~= nil).toBe(true)
                expect(gui:FindFirstChild("ForgedFastener4", true) ~= nil)
                    .toBe(true)
                -- The finish owns only GUI nodes; true geometry and
                -- approved image maps remain untouched.
                expect(#gui:GetDescendants() <= 55).toBe(true)
                for _, child in ipairs(gui:GetDescendants()) do
                    expect(child:IsA("BasePart")).toBe(false)
                    expect(child:IsA("LuaSourceContainer")).toBe(false)
                end
            end
            expect(door.Material).toBe(beforeMaterial)
            expect(door.Color).toBe(beforeColor)
            expect(door.Size).toBe(beforeSize)
            door:Destroy()
        end
    end)

    it("keeps Android Low off and Medium stencil significantly cheaper", function()
        local door = Instance.new("Part")
        door.Name = "ServiceEntryDoor"
        local low = DistrictMaterialFinishKit.stencil(
            door, "H-02", Color3.fromRGB(70, 195, 211),
            "Low", "service-door", Enum.NormalId.Front, "Harbor")
        expect(low).toBe(nil)
        expect(#door:GetChildren()).toBe(0)
        local medium = DistrictMaterialFinishKit.stencil(
            door, "H-02", Color3.fromRGB(70, 195, 211),
            "Medium", "service-door", Enum.NormalId.Front, "Harbor")
        expect(medium ~= nil).toBe(true)
        if medium then
            expect(medium.MaxDistance).toBe(115)
            expect(medium.PixelsPerStud).toBe(16)
            expect(medium:FindFirstChild("ForgedFastener2", true) ~= nil)
                .toBe(true)
            expect(medium:FindFirstChild("ForgedFastener3", true)).toBe(nil)
            expect(medium:FindFirstChild("QuayHatchRib3", true) ~= nil)
                .toBe(true)
            expect(medium:FindFirstChild("QuayHatchRib4", true)).toBe(nil)
        end
        door:Destroy()
    end)

    it("preserves preexisting simple style callers and fallback identity", function()
        local door = Instance.new("Part")
        local old = DistrictMaterialFinishKit.stencil(
            door, "LEGACY", Color3.fromRGB(72, 185, 255),
            "Medium", "service-door", Enum.NormalId.Front)
        expect(old ~= nil).toBe(true)
        if old then
            local tag = old:FindFirstChild("IndustrialFamilyMark", true)
            expect(tag ~= nil).toBe(true)
            if tag then expect(tag.Text).toBe("SURVEY / GRID") end
        end
        door:Destroy()
    end)
end)

return nil
