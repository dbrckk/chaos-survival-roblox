--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Layout = require("../../src/shared/DisasterAtmosphereLayout")

describe("Slope-correct live disaster atmosphere", function()
    it("positions hazard beacons relative to the tilted deck rather than world Y", function()
        local frame = CFrame.new(14, 20, -11)
            * CFrame.Angles(math.rad(15), math.rad(42), math.rad(-9))
        local size = Vector3.new(90, 5, 78)
        local p = Layout.point(frame, size, math.pi * 0.5, 35, 0.8)
        local localPoint = frame:PointToObjectSpace(p)
        expect(math.abs(localPoint.X) < 0.001).toBe(true)
        expect(math.abs(localPoint.Y - 3.3) < 0.001).toBe(true)
        expect(math.abs(localPoint.Z - 35) < 0.001).toBe(true)
        local lower = Layout.point(frame, size, 0, 15, 0.8)
        local higher = Layout.point(frame, size, 0, 15, 4.8)
        local diff = higher - lower
        expect(math.abs(diff.Unit:Dot(frame.UpVector)) > 0.999).toBe(true)
        expect(math.abs(diff.Magnitude - 4) < 0.001).toBe(true)
    end)

    it("keeps atmospheric shafts upright relative to the arena deck", function()
        local frame = CFrame.new(9, 4, 21)
            * CFrame.Angles(math.rad(21), math.rad(-31), math.rad(6))
        local size = Vector3.new(80, 4, 80)
        local cf = Layout.beamFrame(frame, size, math.rad(110), 40, 28)
        expect(typeof(cf)).toBe("CFrame")
        expect(cf.UpVector:Dot(frame.UpVector) > 0.999).toBe(true)
        local expected = Layout.point(frame, size, math.rad(110), 40, 18)
        expect((cf.Position - expected).Magnitude < 0.001).toBe(true)
        expect(Layout.point(nil, size, 0, 10, 2) == nil).toBe(true)
        expect(Layout.point(frame, nil, 0, 10, 2) == nil).toBe(true)
        expect(Layout.beamFrame(nil, size, 0, 10, 20) == nil).toBe(true)
    end)

    it("keeps all cinematic perimeter markers on a shrinking and tilted floor", function()
        local frame = CFrame.new(-19, 22, 41)
            * CFrame.Angles(math.rad(13), math.rad(32), math.rad(-11))
        local size = Vector3.new(96, 4, 80)
        local originalRadius = Layout.perimeterRadius(size)
        expect(math.abs(originalRadius - 96 * 0.52) < 0.001).toBe(true)
        expect(Layout.perimeterRadius(nil) == nil).toBe(true)
        expect(Layout.perimeterRadius(size, -1) == nil).toBe(true)
        expect(Layout.beaconFrame(nil, size, 0) == nil).toBe(true)
        expect(Layout.orbitalCoreFrame(nil) == nil).toBe(true)

        for _, scale in ipairs({1, 0.78, 0.55, 0.35}) do
            -- Server ShrinkingArena keeps Base.CFrame but scales X and Z.
            -- Correct ornaments must travel toward the same true new edge.
            local shrunk = Vector3.new(size.X * scale, size.Y, size.Z * scale)
            local radius = Layout.perimeterRadius(shrunk)
            expect(math.abs(radius - originalRadius * scale) < 0.001)
                .toBe(true)
            for index = 1, 8 do
                local angle = ((index - 1) / 8) * math.pi * 2
                local beaconFrame = Layout.beaconFrame(frame, shrunk, angle)
                expect(typeof(beaconFrame)).toBe("CFrame")
                local localPosition = frame:PointToObjectSpace(beaconFrame.Position)
                expect(math.abs(localPosition.X - math.cos(angle) * radius)
                    < 0.001).toBe(true)
                expect(math.abs(localPosition.Z - math.sin(angle) * radius)
                    < 0.001).toBe(true)
                expect(math.abs(localPosition.Y - (shrunk.Y * 0.5 + 0.8))
                    < 0.001).toBe(true)
                expect(beaconFrame.UpVector:Dot(frame.UpVector) > 0.999)
                    .toBe(true)

                local shaftRadius = Layout.perimeterRadius(shrunk, 0.52 * 1.08)
                local shaft = Layout.beamFrame(
                    frame, shrunk, angle, shaftRadius, 42
                )
                local shaftLocal = frame:PointToObjectSpace(shaft.Position)
                expect(math.abs(shaftLocal.X - math.cos(angle) * shaftRadius)
                    < 0.001).toBe(true)
                expect(math.abs(shaftLocal.Z - math.sin(angle) * shaftRadius)
                    < 0.001).toBe(true)
            end
            -- High-tier Orbital core aura follows tilt, but not horizontal
            -- floor shrink: it remains centered on the reactor.
            local core = Layout.orbitalCoreFrame(frame)
            expect((frame:PointToObjectSpace(core.Position)
                - Vector3.new(0, 13, 0)).Magnitude < 0.001).toBe(true)
        end

        local rotated = frame * CFrame.Angles(0, math.rad(18), 0)
        expect((Layout.beaconFrame(rotated, size, 0).Position
            - Layout.beaconFrame(frame, size, 0).Position).Magnitude > 8)
            .toBe(true)
        expect((Layout.orbitalCoreFrame(rotated).Position
            - Layout.orbitalCoreFrame(frame).Position).Magnitude < 0.001)
            .toBe(true)
    end)

    it("creates no ambient hazard props in a lobby with no active disaster", function()
        expect(Layout.beaconCount("Low", true)).toBe(4)
        expect(Layout.beaconCount("Medium", true)).toBe(6)
        expect(Layout.beaconCount("High", true)).toBe(8)
        expect(Layout.beaconCount("High", false)).toBe(0)
        expect(Layout.beaconCount("Medium", false)).toBe(0)
        expect(Layout.beaconCount("Unknown", true)).toBe(0)

        -- Zero client GPU instances in the lobby: no 30 Hz wakeups.
        expect(Layout.updateCadence(false, 1 / 30)).toBe(0.50)
        expect(Layout.updateCadence(false, 1 / 15)).toBe(0.50)
        -- Active hazards keep the exact authored High/Medium/Low cadence.
        for _, cadence in ipairs({1 / 30, 1 / 24, 1 / 15}) do
            expect(Layout.updateCadence(true, cadence)).toBe(cadence)
        end
        expect(math.abs(Layout.updateCadence(true, nil) - 1 / 30) < 0.001)
            .toBe(true)
        expect(math.abs(Layout.updateCadence(true, -1) - 1 / 30) < 0.001)
            .toBe(true)

        -- Distance LOD must pause invisible cosmetic motion only.
        -- On reentry, exact same Part is animated again, no reallocation.
        local folder = Instance.new("Folder")
        folder.Parent = workspace
        local beacon = Instance.new("Part")
        beacon.Parent = folder
        expect(Layout.shouldAnimate(beacon)).toBe(true)
        beacon:SetAttribute("SceneryLodHidden", true)
        expect(Layout.shouldAnimate(beacon)).toBe(false)
        beacon:SetAttribute("SceneryLodHidden", false)
        expect(Layout.shouldAnimate(beacon)).toBe(true)
        beacon.Parent = nil
        expect(Layout.shouldAnimate(beacon)).toBe(false)
        expect(Layout.shouldAnimate(nil)).toBe(false)
        beacon:Destroy()
        folder:Destroy()
    end)
end)

return nil
