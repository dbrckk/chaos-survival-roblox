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
        expect(math.abs(Rules.silhouette("Classic").Wing.X - 3.9) < 0.0001).toBe(true)
        expect(math.abs(Rules.silhouette("Towers").Wing.X - 2.75) < 0.0001).toBe(true)
        expect(math.abs(Rules.silhouette("Crossroads").Wing.X - 4.75) < 0.0001).toBe(true)
        expect(math.abs(Rules.silhouette("Orbital").Wing.X - 5.2) < 0.0001).toBe(true)
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

    it("keeps wide rotated arenas clear throughout every patrol orbit", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(500, 2, 300)
        base.CFrame = CFrame.new(24, 10, -60) * CFrame.Angles(0, math.rad(33), 0)
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            for slot = 1, 3 do
                for step = 0, 31 do
                    local frame = Rules.flightFrame(base, variant, slot, 3, step * 2,
                        Rules.behavior({"Meteors"}))
                    local point = base.CFrame:PointToObjectSpace(frame.Position)
                    local outside = math.abs(point.X) > base.Size.X * 0.5 + 8
                        or math.abs(point.Z) > base.Size.Z * 0.5 + 8
                    expect(outside).toBe(true)
                end
            end
        end
        base:Destroy()
    end)

    it("uses distinct disaster animation reactions without changing collision bounds", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.Parent = workspace
        local normal = Rules.flightFrame(base, "Towers", 1, 2, 6)
        local storm = Rules.flightFrame(base, "Towers", 1, 2, 6,
            Rules.behavior({"Tornado"}))
        local lava = Rules.flightFrame(base, "Towers", 1, 2, 6,
            Rules.behavior({"RisingLava"}))
        expect((storm.Position - normal.Position).Magnitude > 0.4).toBe(true)
        expect(lava.Position.Y - normal.Position.Y).toBe(7)
        local frozen = Rules.behavior({"Freeze"})
        expect(frozen.Speed < 0.5).toBe(true)
        local lowGravity = Rules.behavior({"LowGravity"})
        expect(lowGravity.Climb).toBe(4)
        expect(lowGravity.Speed < 1).toBe(true)
        local meteor = Rules.behavior({"Meteors"})
        expect(meteor.Sway > 1).toBe(true)
        local danger = Rules.behavior({"Tornado", "RisingLava"})
        expect(danger.Bank > 2).toBe(true)
        expect(danger.Climb).toBe(7)
        base:Destroy()
    end)

    it("builds tier-bounded physical silhouettes with zero collision or touch", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.Parent = workspace
        local world = Instance.new("Folder")
        world.Name = "AerialSurveyTestWorld"
        world.Parent = workspace
        local parent = Instance.new("Folder")
        parent.Name = "AerialSurveyLocal"
        parent.Parent = world
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
            local metrics, audited = VisualBudget.collect(world)
            expect(audited).toBe(1)
            expect(metrics.Parts).toBe(count)
            expect(metrics.Lights <= 3).toBe(true)
            expect(metrics.Effects <= 3).toBe(true)
        end
        world:Destroy()
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
