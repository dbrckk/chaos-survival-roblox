--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Rules = require("../../src/shared/AerialSurveyRules")
local Kit = require("../../src/client/AerialSurveyKit")
local VisualBudget = require("../../src/shared/VisualBudgetRules")

local theme = {
    Structure = Color3.fromRGB(40, 55, 70),
    Detail = Color3.fromRGB(120, 146, 172),
    Secondary = Color3.fromRGB(255, 170, 90),
    Accent = Color3.fromRGB(90, 225, 255),
}

describe("Aerial survey fleet: 3D art, motion and mobile performance", function()
    it("reduces drone/part count strictly across mobile quality tiers", function()
        local low = Rules.profile("Low")
        local medium = Rules.profile("Medium")
        local high = Rules.profile("High")
        expect(low.Drones).toBe(1)
        expect(medium.Drones).toBe(2)
        expect(high.Drones).toBe(3)
        expect(low.MaxParts).toBe(6)
        expect(medium.MaxParts).toBe(22)
        expect(high.MaxParts).toBe(51)
        expect(Rules.animated("round", "High", false)).toBe(true)
        expect(Rules.animated("round", "Low", false)).toBe(false)
        expect(Rules.animated("round", "High", true)).toBe(false)
        expect(Rules.animated("waiting", "High", false)).toBe(false)
    end)

    it("keeps flights outside playable arena and statically freezes accessible motion", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.CFrame = CFrame.new(10, 1, -20)
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local start = Rules.flightFrame(base, variant, 1, 3, 0)
            local moved = Rules.flightFrame(base, variant, 1, 3, 12)
            local localP = base.CFrame:PointToObjectSpace(start.Position)
            expect(math.abs(localP.X) > base.Size.X * 0.5
                or math.abs(localP.Z) > base.Size.Z * 0.5).toBe(true)
            expect((start.Position - moved.Position).Magnitude > 5).toBe(true)
        end
        base:Destroy()
    end)

    it("builds tier-bounded physical silhouettes with zero collision or touch", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.Parent = workspace
        local parent = Instance.new("Folder")
        parent.Parent = workspace
        parent.Name = "AerialSurveyLocal"
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            parent:ClearAllChildren()
            local fleet = Kit.build(parent, base, "Towers", tier, theme)
            expect(#fleet.drones).toBe(Rules.profile(tier).Drones)
            local count = 0
            for _, descendant in ipairs(parent:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    count += 1
                    expect(descendant.Anchored).toBe(true)
                    expect(descendant.CanCollide).toBe(false)
                    expect(descendant.CanQuery).toBe(false)
                    expect(descendant.CanTouch).toBe(false)
                    expect(descendant.CastShadow).toBe(false)
                end
            end
            expect(count).toBe(Rules.profile(tier).MaxParts)
            local first = fleet.drones[1]
            local before = first.sections[1].part.Position
            Kit.update(fleet, 18, "round", false,
                Color3.fromRGB(255, 80, 40), false)
            if tier ~= "Low" then
                expect((first.sections[1].part.Position - before).Magnitude > 1).toBe(true)
            else
                expect((first.sections[1].part.Position - before).Magnitude < 0.01).toBe(true)
            end
            Kit.update(fleet, 18, "round", true,
                Color3.fromRGB(255, 80, 40), true)
            expect((first.sections[1].part.Position - before).Magnitude < 0.01).toBe(true)
            local metrics, audited = VisualBudget.collect(parent)
            expect(audited).toBe(1)
            expect(metrics.Parts).toBe(count)
            expect(metrics.Lights <= 3).toBe(true)
            expect(metrics.Effects <= 3).toBe(true)
        end
        parent:Destroy()
        base:Destroy()
    end)

    it("maps round hazards and final rush to a readable, non-damaging warning", function()
        expect(Rules.alert("waiting", {"Meteors"}, true)).toBe("standby")
        expect(Rules.alert("round", {"Meteors"}, false)).toBe("hazard")
        expect(Rules.alert("round", {}, true)).toBe("critical")
        expect(Rules.alert("round", {}, false)).toBe("patrol")
    end)
end)

return nil
