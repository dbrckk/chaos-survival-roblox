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

    it("uses one stable 8-stud drone distance band on all mobile tiers", function()
        for _, entry in ipairs({
            {"Low", 145}, {"Medium", 215}, {"High", 300},
        }) do
            local tier, cutoff = entry[1], entry[2]
            expect(Rules.inRange(cutoff, tier, nil)).toBe(true)
            expect(Rules.inRange(cutoff + 0.1, tier, nil)).toBe(false)
            expect(Rules.inRange(cutoff + 7.9, tier, true)).toBe(true)
            expect(Rules.inRange(cutoff + 8.1, tier, true)).toBe(false)
            expect(Rules.inRange(cutoff - 7.9, tier, false)).toBe(false)
            expect(Rules.inRange(cutoff - 8.1, tier, false)).toBe(true)
        end
        expect(Rules.inRange(math.huge, "High", true)).toBe(false)
        expect(Rules.inRange(0/0, "High", true)).toBe(false)
        expect(Rules.inRange(-1, "High", true)).toBe(false)
        expect(Rules.inRange(nil, "High", true)).toBe(false)
        expect(Rules.inRange(145, "Unknown", nil)).toBe(true)
        expect(Rules.inRange(145.1, "Unknown", nil)).toBe(false)
    end)

    it("articulates nonphysical turbine and tail servos within one degree", function()
        for index = 1, 3 do
            for _, role in ipairs({"engine", "exhaust", "rotor", "tail"}) do
                for _, side in ipairs(role == "tail" and {0} or {-1, 1}) do
                    local animated = Rules.servoOffset(role, index, side, 1.37)
                    expect(animated ~= CFrame.identity).toBe(true)
                    for _, now in ipairs({0, 0.5, 1.37, 8.0, 10000}) do
                        local offset = Rules.servoOffset(role, index, side, now)
                        local limit = role == "tail" and 0.61 or 0.86
                        expect(offset.Position).toBe(Vector3.zero)
                        expect(offset.UpVector:Dot(Vector3.yAxis)
                            >= math.cos(math.rad(limit))).toBe(true)
                        local base = CFrame.new(12, 24, -8)
                            * CFrame.Angles(0, math.rad(41), 0)
                        local composed = base:ToObjectSpace(base * offset)
                        expect(composed.UpVector:Dot(offset.UpVector)
                            > 0.99999).toBe(true)
                    end
                end
            end
        end
        for index = 1, 3 do
            for _, side in ipairs({-1, 1}) do
                local engine = Rules.servoOffset("engine", index, side, 1.37)
                expect(Rules.servoOffset("exhaust", index, side, 1.37))
                    .toBe(engine)
                expect(Rules.servoOffset("rotor", index, side, 1.37))
                    .toBe(engine)
            end
        end
        expect(Rules.servoOffset("hull", 1, 0, 1))
            .toBe(CFrame.identity)
        expect(Rules.servoOffset("engine", 0, 1, 1))
            .toBe(CFrame.identity)
        expect(Rules.servoOffset("engine", 1, 0, 1))
            .toBe(CFrame.identity)
        expect(Rules.servoOffset("tail", 1, 1, 1))
            .toBe(CFrame.identity)
        for _, bad in ipairs({-1, 0/0, math.huge, -math.huge, 1e8}) do
            expect(Rules.servoOffset("engine", 1, 1, bad))
                .toBe(CFrame.identity)
        end
    end)

    it("hinges engine, exhaust and High-tier rotor as one coherent nacelle", function()
        for _, side in ipairs({-1, 1}) do
            local engine = CFrame.new(side * 1.08, -0.35, 1.65)
            local exhaust = engine * CFrame.new(0, 0, 0.90)
            local rotor = CFrame.new(side * 1.08, 0.28, 1.65)
            for _, at in ipairs({0, 1.37, 7.21}) do
                local angle = Rules.servoOffset("engine", 1, side, at)
                local pivot = engine
                local enginePose = Rules.articulatedSectionFrame(
                    "engine", 1, side, at, engine)
                local exhaustPose = Rules.articulatedSectionFrame(
                    "exhaust", 1, side, at, exhaust)
                local rotorPose = Rules.articulatedSectionFrame(
                    "rotor", 1, side, at, rotor)
                expect((enginePose.Position - pivot.Position).Magnitude < 0.0001)
                    .toBe(true)
                expect((exhaustPose.Position -
                    (pivot * angle * CFrame.new(0, 0, 0.9)).Position).Magnitude
                    < 0.0001).toBe(true)
                expect((rotorPose.Position -
                    (pivot * angle * CFrame.new(0, 0.63, 0)).Position).Magnitude
                    < 0.0001).toBe(true)
                local spatial = CFrame.new(50, 30, -17)
                    * CFrame.Angles(0, math.rad(37), 0)
                local world = spatial * rotorPose
                expect((world.Position - spatial:PointToWorldSpace(
                    rotorPose.Position)).Magnitude < 0.0001).toBe(true)
            end
        end
        local fixed = CFrame.new(1, 2, 3)
        expect(Rules.articulatedSectionFrame("hull", 1, 0, 1, fixed))
            .toBe(fixed)
        expect(Rules.articulatedSectionFrame("engine", 1, 0, 1, fixed))
            .toBe(fixed)
        expect(Rules.articulatedSectionFrame("engine", 1, 1, 1, nil))
            .toBe(CFrame.identity)
    end)

    it("keeps the delta wings attached to the moving craft while servos articulate", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.Parent = workspace
        local parent = Instance.new("Folder")
        parent.Parent = workspace
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            parent:ClearAllChildren()
            local fleet = Kit.build(parent, base, "Crossroads", tier, theme)
            local first = fleet.drones[1]
            Kit.update(fleet, 30, "round", false, theme.Accent, false,
                {"Meteors"}, true)
            Kit.update(fleet, 30.2, "round", false, theme.Accent, false,
                {"Meteors"}, true)
            local hull = first.folder:FindFirstChild("SurveyArmoredHull")
            local wingLeft = first.folder:FindFirstChild("SurveyDeltaWing-1")
            local wingRight = first.folder:FindFirstChild("SurveyDeltaWing1")
            expect(hull ~= nil and wingLeft ~= nil and wingRight ~= nil)
                .toBe(true)
            expect((hull.Position - first.root.Position).Magnitude < 50).toBe(true)
            -- Flight anchor for every 3D section matches the same
            -- authored local offset even while wing-bank animation runs.
            if tier == "Low" then
                expect(fleet.flightTime).toBe(0)
            else
                expect(fleet.flightTime > 0).toBe(true)
            end
            for _, part in ipairs({wingLeft, wingRight}) do
                local authored
                for _, section in ipairs(first.sections) do
                    if section.part == part then authored = section.frame break end
                end
                expect(authored ~= nil).toBe(true)
                -- Low never animates, so it must retain the original
                -- non-hazard frame. Medium/High integrate meteor speed
                -- into flightTime before applying the disaster sway.
                local reaction = tier ~= "Low"
                    and Rules.behavior({"Meteors"}) or nil
                if reaction then
                    reaction.Speed = 1
                end
                local worldExpected = Rules.flightFrame(
                    base, "Crossroads", first.index, first.total,
                    fleet.flightTime, reaction) * authored
                expect((part.Position - worldExpected.Position).Magnitude
                    < 0.0001).toBe(true)
                expect(math.abs(part.CFrame.UpVector:Dot(worldExpected.UpVector))
                    > 0.99).toBe(true)
            end
        end
        parent:Destroy()
        base:Destroy()
    end)

    it("retains warning-color exhausts while the shared turbine gimbal moves", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.Parent = workspace
        local parent = Instance.new("Folder")
        parent.Parent = workspace
        local danger = Color3.fromRGB(255, 90, 40)
        for _, tier in ipairs({"Medium", "High"}) do
            parent:ClearAllChildren()
            local fleet = Kit.build(parent, base, "Classic", tier, theme)
            Kit.update(fleet, 10, "round", false, danger, false, {"Meteors"}, true)
            Kit.update(fleet, 10.2, "round", false, danger, false, {"Meteors"}, true)
            for _, drone in ipairs(fleet.drones) do
                for _, item in ipairs(drone.sections) do
                    if item.role == "exhaust" then
                        expect(item.part.Color).toBe(danger)
                        expect(math.abs(item.part.Transparency - 0.22)
                            < 0.00001).toBe(true)
                    end
                end
            end
        end
        parent:Destroy()
        base:Destroy()
    end)

    it("integrates speed changes continuously and pauses without catch-up jumps", function()
        local elapsed, last = Rules.advanceClock(0, nil, 12, true, 1)
        expect(elapsed).toBe(0)
        expect(last).toBe(12)
        elapsed, last = Rules.advanceClock(elapsed, last, 12.2, true, 1.4)
        expect(math.abs(elapsed - 0.28) < 0.0001).toBe(true)
        local paused, sample = Rules.advanceClock(elapsed, last, 50, false, 1)
        expect(paused).toBe(elapsed)
        expect(sample).toBe(nil)
        local resumed, resumeSample = Rules.advanceClock(paused, sample, 100, true, 1)
        expect(resumed).toBe(paused)
        expect(resumeSample).toBe(100)
        local capped = Rules.advanceClock(0, 1, 100, true, 1.4)
        expect(capped <= 0.421).toBe(true)
        local reversed = Rules.advanceClock(elapsed, 100, 99, true, 1)
        expect(reversed).toBe(elapsed)
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
            Kit.update(fleet, 18.2, "round", false,
                Color3.fromRGB(255, 80, 40), false)
            local movingPose = first.sections[1].part.CFrame
            if tier ~= "Low" then
                expect((movingPose.Position - before).Magnitude > 1).toBe(true)
            else
                expect((movingPose.Position - before).Magnitude < 0.01).toBe(true)
            end
            Kit.update(fleet, 90, "round", true,
                Color3.fromRGB(255, 80, 40), true)
            expect(first.sections[1].part.CFrame).toBe(movingPose)
            expect(fleet.lastNow).toBe(nil)
            Kit.update(fleet, 150, "round", false,
                Color3.fromRGB(255, 80, 40), false)
            expect(first.sections[1].part.CFrame).toBe(movingPose)
            Kit.update(fleet, 150.1, "round", false,
                Color3.fromRGB(255, 80, 40), false)
            if tier ~= "Low" then
                expect((first.sections[1].part.Position - movingPose.Position).Magnitude < 3).toBe(true)
            end
            local metrics, audited = VisualBudget.collect(world)
            expect(audited).toBe(1)
            expect(metrics.Parts).toBe(count)
            expect(metrics.Lights <= 3).toBe(true)
            expect(metrics.Effects <= 3).toBe(true)
        end
        world:Destroy()
        base:Destroy()
    end)

    it("culls distant geometry and restores all three tiers without altering alpha", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.Parent = workspace
        local parent = Instance.new("Folder")
        parent.Parent = workspace
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            parent:ClearAllChildren()
            local fleet = Kit.build(parent, base, "Orbital", tier, theme)
            Kit.update(fleet, 10, "round", false, theme.Accent, false, {"Meteors"}, true)
            Kit.update(fleet, 10.2, "round", false, theme.Accent, false, {"Meteors"}, true)
            -- Capture the hazard-authored alpha after the alert update:
            -- exhaust and navigation accents legitimately change alpha.
            local original = {}
            for _, drone in ipairs(fleet.drones) do
                for _, item in ipairs(drone.sections) do
                    original[item.part] = item.part.Transparency
                end
            end
            if tier == "High" then
                expect(fleet.drones[1].light.Enabled).toBe(true)
                expect(fleet.drones[1].trail.Enabled).toBe(true)
            end
            Kit.update(fleet, 11, "round", true, theme.Accent, false, {"Meteors"}, false)
            expect(fleet.visible).toBe(false)
            for _, drone in ipairs(fleet.drones) do
                for _, item in ipairs(drone.sections) do
                    expect(item.part.LocalTransparencyModifier).toBe(1)
                    expect(item.part.Transparency).toBe(original[item.part])
                    expect(item.part.CanCollide).toBe(false)
                end
                if drone.light then
                    expect(drone.light.Enabled).toBe(false)
                    expect(drone.trail.Enabled).toBe(false)
                end
            end
            Kit.update(fleet, 12, "round", false, theme.Accent, false, {"Meteors"}, true)
            expect(fleet.visible).toBe(true)
            for _, drone in ipairs(fleet.drones) do
                for _, item in ipairs(drone.sections) do
                    expect(item.part.LocalTransparencyModifier).toBe(0)
                    expect(item.part.Transparency).toBe(original[item.part])
                end
                if drone.light then
                    expect(drone.light.Enabled).toBe(true)
                    expect(drone.trail.Enabled).toBe(true)
                end
            end
            expect(#fleet.drones).toBe(Rules.profile(tier).Drones)
        end
        parent:Destroy()
        base:Destroy()
    end)

    it("does not animate or relight a culled fleet even if reduced is false", function()
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.Parent = workspace
        local parent = Instance.new("Folder")
        parent.Parent = workspace

        for _, tier in ipairs({"Medium", "High"}) do
            parent:ClearAllChildren()
            local fleet = Kit.build(parent, base, "Classic", tier, theme)
            Kit.update(fleet, 10, "round", false, theme.Accent,
                false, {"Meteors"}, true)
            Kit.update(fleet, 10.2, "round", false, theme.Accent,
                false, {"Meteors"}, true)
            local beforeClock = fleet.flightTime
            local first = fleet.drones[1].sections[1].part
            local beforePose = first.CFrame
            expect(beforeClock > 0).toBe(true)

            -- Caller deliberately supplies reduced=false while not visible.
            Kit.update(fleet, 100, "round", false, theme.Accent,
                false, {"Meteors"}, false)
            expect(fleet.visible).toBe(false)
            expect(fleet.flightTime).toBe(beforeClock)
            expect(fleet.lastNow).toBe(nil)
            expect(first.CFrame).toBe(beforePose)
            Kit.update(fleet, 500, "round", false, theme.Accent,
                false, {"Meteors"}, false)
            expect(fleet.flightTime).toBe(beforeClock)
            expect(first.CFrame).toBe(beforePose)
            for _, drone in ipairs(fleet.drones) do
                for _, section in ipairs(drone.sections) do
                    expect(section.part.LocalTransparencyModifier).toBe(1)
                end
                if drone.light then
                    expect(drone.light.Enabled).toBe(false)
                    expect(drone.trail.Enabled).toBe(false)
                end
            end

            Kit.update(fleet, 800, "round", false, theme.Accent,
                false, {"Meteors"}, true)
            expect(fleet.flightTime).toBe(beforeClock)
            expect(first.CFrame).toBe(beforePose)
            expect(fleet.visible).toBe(true)
            expect(fleet.lastNow).toBe(800)
            for _, drone in ipairs(fleet.drones) do
                for _, section in ipairs(drone.sections) do
                    expect(section.part.LocalTransparencyModifier).toBe(0)
                end
                if drone.light then
                    expect(drone.light.Enabled).toBe(true)
                    expect(drone.trail.Enabled).toBe(true)
                end
            end
            Kit.update(fleet, 800.1, "round", false, theme.Accent,
                false, {"Meteors"}, true)
            expect(fleet.flightTime > beforeClock).toBe(true)
            expect(#fleet.drones).toBe(Rules.profile(tier).Drones)
        end
        parent:Destroy()
        base:Destroy()
    end)

    it("disables existing drone GPU effects immediately without rebuilding geometry", function()
        local base = Instance.new("Part")
        base.Parent = workspace
        local folder = Instance.new("Folder")
        folder.Parent = workspace
        local high = Kit.build(folder, base, "Classic", "High", theme)
        Kit.update(high, 20, "round", false, theme.Accent, false, {"Meteors"}, true)
        Kit.update(high, 20.2, "round", false, theme.Accent, false, {"Meteors"}, true)
        local beforePause = high.flightTime
        expect(beforePause > 0).toBe(true)
        expect(Kit.suspendEffects(high)).toBe(6)
        expect(high.lastNow).toBe(nil)
        expect(Kit.suspendEffects(high)).toBe(0)
        expect(#high.drones).toBe(3)
        local count = 0
        for _, drone in ipairs(high.drones) do
            expect(drone.light.Enabled).toBe(false)
            expect(drone.trail.Enabled).toBe(false)
            for _, part in ipairs(drone.sections) do
                expect(part.part.Parent ~= nil).toBe(true)
                count += 1
            end
        end
        expect(count).toBe(51)
        Kit.update(high, 200, "round", false, theme.Accent, false,
            {"Meteors"}, true)
        expect(high.flightTime).toBe(beforePause)
        expect(Kit.suspendEffects(high)).toBe(6)
        expect(Kit.suspendEffects(nil)).toBe(0)
        folder:ClearAllChildren()
        for _, tier in ipairs({"Low", "Medium"}) do
            local lesser = Kit.build(folder, base, "Classic", tier, theme)
            Kit.update(lesser, 20, "round", false, theme.Accent, false,
                {"Meteors"}, true)
            expect(Kit.suspendEffects(lesser)).toBe(0)
        end
        folder:Destroy()
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
