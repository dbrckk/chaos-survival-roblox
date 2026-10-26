--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Rules = require("../../src/shared/MeteorSignatureRules")
local Sculpt = require("../../src/client/MeteorCoreSculptKit")

describe("Premium meteor rock silhouettes on Android", function()
    it("provides a strict one/three/five facet budget without changing impact data", function()
        expect(Rules.corePlateCount("Low")).toBe(1)
        expect(Rules.corePlateCount("Medium")).toBe(3)
        expect(Rules.corePlateCount("High")).toBe(5)
        expect(Rules.corePlateCount("Unknown")).toBe(0)
        expect(Rules.corePlateCount(nil)).toBe(0)
        expect(Rules.corePlate(1, 0, 7)).toBe(nil)
        expect(Rules.corePlate(1, 6, 7)).toBe(nil)
        expect(Rules.corePlate(1.5, 5, 7)).toBe(nil)
        expect(Rules.corePlate(6, 5, 7)).toBe(nil)
        expect(Rules.corePlate(1, 5, 0 / 0)).toBe(nil)
        expect(Rules.corePlate(1, 5, math.huge)).toBe(nil)
        expect(Rules.corePlate(1, 5, 0)).toBe(nil)
        expect(Rules.corePlate(1, 5, 7).Material).toBe(Enum.Material.Basalt)
        expect(Rules.corePlate(3, 5, 7).Material).toBe(Enum.Material.Neon)
        expect(Rules.corePlate(3, 5, 7).Size.X
            < Rules.corePlate(1, 5, 7).Size.X).toBe(true)
        expect(Rules.corePlate(2, 5, 7).Transform
            ~= Rules.corePlate(1, 5, 7).Transform).toBe(true)
    end)

    it("keeps storm effects bounded and fully disabled in reduced motion", function()
        local viewer = Vector3.new(0, 5, 0)
        local near = Vector3.new(0, 5, 20)
        local far = Vector3.new(0, 5, 300)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local profile = Rules.profile(tier, false)
            expect(profile.MaxTrails > 0).toBe(true)
            expect(Rules.shouldTrail("round", true, viewer, near,
                tier, false, 0)).toBe(true)
            expect(Rules.shouldTrail("round", true, viewer, near,
                tier, false, profile.MaxTrails)).toBe(false)
            expect(Rules.shouldTrail("round", true, viewer, far,
                tier, false, 0)).toBe(false)
            expect(Rules.shouldTrail("round", true, viewer, near,
                tier, true, 0)).toBe(false)
            expect(Rules.trailStyle(tier, true)).toBe(nil)
            expect(Rules.profile(tier, true).MaxTrails).toBe(0)
        end
        expect(Rules.shouldTrail("waiting", true, viewer, near,
            "High", false, 0)).toBe(false)
        expect(Rules.shouldTrail("round", false, viewer, near,
            "High", false, 0)).toBe(false)
    end)

    it("welds collisionless facets to the server-owned moving core", function()
        local meteor = Instance.new("Part")
        meteor.Name = "RoundMeteor"
        meteor.Shape = Enum.PartType.Ball
        meteor.Size = Vector3.new(7, 7, 7)
        meteor.Anchored = true
        meteor.CFrame = CFrame.new(14, 32, -11)
            * CFrame.Angles(0.1, 0.45, -0.2)
        meteor.Parent = workspace

        local plates = Sculpt.build(meteor, "High", Rules)
        expect(#plates).toBe(5)
        for index, plate in ipairs(plates) do
            expect(plate:IsA("WedgePart")).toBe(true)
            expect(plate.Parent).toBe(meteor)
            expect(plate.Anchored).toBe(false)
            expect(plate.Massless).toBe(true)
            expect(plate.CanCollide).toBe(false)
            expect(plate.CanTouch).toBe(false)
            expect(plate.CanQuery).toBe(false)
            expect(plate.CastShadow).toBe(false)
            local weld = plate:FindFirstChildOfClass("WeldConstraint")
            expect(weld ~= nil).toBe(true)
            if weld then
                expect(weld.Part0).toBe(meteor)
                expect(weld.Part1).toBe(plate)
            end
            local expectedFrame = meteor.CFrame
                * Rules.corePlate(index, 5, meteor.Size.X).Transform
            expect((plate.Position - expectedFrame.Position).Magnitude < 0.01)
                .toBe(true)
        end
        expect(meteor.Anchored).toBe(true)
        expect(meteor.Shape).toBe(Enum.PartType.Ball)

        -- Live Android quality downgrades must dispose of old welds and
        -- geometry before creating the cheaper one-facet silhouette.
        Sculpt.clear(plates)
        expect(#meteor:GetChildren()).toBe(0)
        local low = Sculpt.build(meteor, "Low", Rules)
        expect(#low).toBe(1)
        Sculpt.clear(low)
        expect(#meteor:GetChildren()).toBe(0)
        meteor:Destroy()
    end)

    it("never adds geometry for invalid sources or unknown quality", function()
        local folder = Instance.new("Folder")
        folder.Parent = workspace
        expect(#Sculpt.build(nil, "High", Rules)).toBe(0)
        expect(#Sculpt.build(folder, "High", Rules)).toBe(0)
        expect(#Sculpt.build(folder, "High", nil)).toBe(0)

        local meteor = Instance.new("Part")
        meteor.Parent = folder
        expect(#Sculpt.build(meteor, "Unknown", Rules)).toBe(0)
        expect(#meteor:GetChildren()).toBe(0)
        Sculpt.clear(nil)
        folder:Destroy()
    end)
end)

return nil
