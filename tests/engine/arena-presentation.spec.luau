--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaPresentation = require("../../src/shared/ArenaPresentation")
local VisualTheme = require("../../src/shared/VisualTheme")
local MapVisualReadiness = require("../../src/shared/MapVisualReadiness")
local ArenaSignatureKit = require("../../src/client/ArenaSignatureKit")
local ArenaDetailKit = require("../../src/client/ArenaDetailKit")
local PlatformFinishKit = require("../../src/client/PlatformFinishKit")
local ArenaEdgeFinishKit = require("../../src/client/ArenaEdgeFinishKit")
local ArenaSilhouetteAccentKit = require("../../src/client/ArenaSilhouetteAccentKit")
local ArenaDeckFinishKit = require("../../src/client/ArenaDeckFinishKit")
local ArenaFloorFollowerKit = require("../../src/client/ArenaFloorFollowerKit")
local ArenaSceneryFrames = require("../../src/shared/ArenaSceneryFrames")
local MobileReadabilityKit = require("../../src/client/MobileReadabilityKit")
local IdentityMotionRules = require("../../src/shared/ArenaIdentityMotionRules")
local IdentityMotionReadiness = require("../../src/shared/ArenaIdentityMotionReadiness")

local CENTER = Vector3.new(0, 0, 0)

local function planarUnit(vector)
    local flat = Vector3.new(vector.X, 0, vector.Z)
    return flat.Magnitude > 0.001 and flat.Unit or Vector3.zero
end

describe("Arena presentation", function()
    it("shrinks center wayfinding paint but leaves pad-owned route indicators untouched", function()
        local root = Instance.new("Folder")
        root.Parent = workspace
        local base = Instance.new("Part")
        base.Anchored = true
        base.Size = Vector3.new(100, 2, 80)
        base.CFrame = CFrame.new(12, 7, -17)
            * CFrame.Angles(0, math.rad(35), 0)
        base.Parent = root
        local visuals = Instance.new("Folder")
        visuals.Parent = root

        local center = Instance.new("Part")
        center.Name = "CenterGridX"
        center.Size = Vector3.new(24, 0.05, 0.18)
        center.CFrame = base.CFrame * CFrame.new(18, 1.2, -12)
        center.Parent = visuals
        local route = Instance.new("Part")
        route.Name = "RouteChevronL1"
        route.Size = Vector3.new(1.7, 0.05, 0.18)
        route.CFrame = base.CFrame * CFrame.new(-28, 1.5, 22)
        route.Parent = visuals
        local initialRoute = route.CFrame
        local initialRouteSize = route.Size

        local snapshot = ArenaFloorFollowerKit.capture(base, visuals, {
            namePrefix = "Center",
        })
        expect(snapshot ~= nil and #snapshot.parts == 1).toBe(true)
        base.Size = Vector3.new(50, 2, 40)
        expect(ArenaFloorFollowerKit.apply(snapshot)).toBe(1)
        local expected = base.CFrame * CFrame.new(9, 1.2, -6)
        expect((center.Position - expected.Position).Magnitude < 0.005).toBe(true)
        expect(math.abs(center.Size.X - 12) < 0.005).toBe(true)
        expect(route.CFrame).toBe(initialRoute)
        expect(route.Size).toBe(initialRouteSize)

        base.Size = Vector3.new(100, 2, 80)
        ArenaFloorFollowerKit.apply(snapshot)
        local disconnect = ArenaFloorFollowerKit.bind(base, visuals, {
            namePrefix = "Center",
        })
        base.Size = Vector3.new(75, 2, 60)
        task.wait(0.06)
        expect(math.abs(center.Size.X - 18) < 0.005).toBe(true)
        expect(route.CFrame).toBe(initialRoute)
        disconnect()
        local stopped = center.CFrame
        base.Size = Vector3.new(50, 2, 40)
        task.wait(0.06)
        expect(center.CFrame).toBe(stopped)
        root:Destroy()
    end)


    it("moves rigid visual machinery inward without shrinking its parts", function()
        local root = Instance.new("Folder")
        root.Parent = workspace
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 80)
        base.CFrame = CFrame.new(30, 10, -14) * CFrame.Angles(0, math.rad(25), 0)
        base.Parent = root

        local props = Instance.new("Folder")
        props.Parent = root
        local crate = Instance.new("Part")
        crate.Size = Vector3.new(3.6, 2.2, 2.8)
        crate.CFrame = base.CFrame * CFrame.new(38, 1.2, -25)
        crate.Parent = props
        local nameplate = Instance.new("Part")
        nameplate.Size = Vector3.new(1.8, 0.15, 0.22)
        nameplate.CFrame = crate.CFrame * CFrame.new(0, 1.2, 0)
        nameplate.Parent = props

        local snapshot = ArenaFloorFollowerKit.capture(base, props, {
            preserveSize = true,
        })
        expect(snapshot.preserveSize).toBe(true)
        base.Size = Vector3.new(45, 2, 36)
        expect(ArenaFloorFollowerKit.apply(snapshot)).toBe(2)
        local expected = base.CFrame * CFrame.new(38 * 0.45, 1.2, -25 * 0.45)
        expect((crate.Position - expected.Position).Magnitude < 0.005).toBe(true)
        expect((crate.Size - Vector3.new(3.6, 2.2, 2.8)).Magnitude < 0.005)
            .toBe(true)
        expect((nameplate.Size - Vector3.new(1.8, 0.15, 0.22)).Magnitude < 0.005)
            .toBe(true)

        base.Size = Vector3.new(100, 2, 80)
        expect(ArenaFloorFollowerKit.apply(snapshot)).toBe(2)
        expect((crate.Position - (base.CFrame * CFrame.new(38, 1.2, -25)).Position)
            .Magnitude < 0.005).toBe(true)

        local disconnect = ArenaFloorFollowerKit.bind(base, props, {preserveSize = true})
        base.Size = Vector3.new(65, 2, 52)
        task.wait(0.06)
        expect((crate.Position - (base.CFrame * CFrame.new(38 * 0.65, 1.2, -25 * 0.65)).Position)
            .Magnitude < 0.005).toBe(true)
        expect((crate.Size - Vector3.new(3.6, 2.2, 2.8)).Magnitude < 0.005).toBe(true)
        disconnect()
        root:Destroy()
    end)


    it("keeps local 3D deck paint aligned with a shrinking rotated base", function()
        local root = Instance.new("Folder")
        root.Parent = workspace
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 80)
        base.CFrame = CFrame.new(11, 4, -9) * CFrame.Angles(0, math.rad(28), 0)
        base.Anchored = true
        base.Parent = root

        local localArt = Instance.new("Folder")
        localArt.Parent = root
        local panel = Instance.new("Part")
        panel.Size = Vector3.new(12, 0.10, 5)
        local relativePanel = CFrame.new(30, 1.16, -20)
            * CFrame.Angles(0, math.rad(45), 0)
        panel.CFrame = base.CFrame * relativePanel
        panel.CanCollide = false
        panel.Anchored = true
        panel.Transparency = 0.42
        panel.Parent = localArt

        local wedge = Instance.new("WedgePart")
        wedge.Size = Vector3.new(5.6, 0.12, 3.2)
        local relativeWedge = CFrame.new(-25, 1.16, 10)
            * CFrame.Angles(0, math.rad(-30), 0)
        wedge.CFrame = base.CFrame * relativeWedge
        wedge.CanCollide = false
        wedge.Anchored = true
        wedge.Parent = localArt

        expect(ArenaFloorFollowerKit.capture(nil, nil) == nil).toBe(true)
        expect(ArenaFloorFollowerKit.apply(nil)).toBe(0)
        local snapshot = ArenaFloorFollowerKit.capture(base, localArt)
        expect(#snapshot.parts).toBe(2)

        base.Size = Vector3.new(65, 2, 40)
        expect(ArenaFloorFollowerKit.apply(snapshot)).toBe(2)
        local panelExpected = base.CFrame
            * CFrame.new(19.5, 1.16, -10)
            * CFrame.Angles(0, math.rad(45), 0)
        local wedgeExpected = base.CFrame
            * CFrame.new(-16.25, 1.16, 5)
            * CFrame.Angles(0, math.rad(-30), 0)
        expect((panel.Position - panelExpected.Position).Magnitude < 0.005)
            .toBe(true)
        expect((wedge.Position - wedgeExpected.Position).Magnitude < 0.005)
            .toBe(true)
        expect(math.abs(panel.Size.X - 7.8) < 0.005).toBe(true)
        expect(math.abs(panel.Size.Z - 2.5) < 0.005).toBe(true)
        expect(math.abs(wedge.Size.X - 3.64) < 0.005).toBe(true)
        expect(math.abs(panel.Size.Y - 0.10) < 0.005).toBe(true)
        expect(math.abs(panel.Transparency - 0.42) < 0.001).toBe(true)
        expect(panel.CanCollide).toBe(false)
        expect(#localArt:GetChildren()).toBe(2)

        base.Size = Vector3.new(100, 2, 80)
        ArenaFloorFollowerKit.apply(snapshot)
        expect((panel.Position - (base.CFrame * relativePanel).Position).Magnitude
            < 0.005).toBe(true)
        expect((panel.Size - Vector3.new(12, 0.10, 5)).Magnitude
            < 0.005).toBe(true)

        -- The actual Size listener updates without a RenderStepped loop,
        -- and a disconnected listener never mutates orphaned artwork.
        local disconnect = ArenaFloorFollowerKit.bind(base, localArt)
        base.Size = Vector3.new(75, 2, 60)
        task.wait(0.06)
        expect(math.abs(panel.Size.X - 9) < 0.005).toBe(true)
        disconnect()
        local stoppedSize = panel.Size
        base.Size = Vector3.new(50, 2, 40)
        task.wait(0.06)
        expect(panel.Size).toBe(stoppedSize)

        root:Destroy()
    end)

    it("faces Classic spawns toward the arena center", function()
        local spawn = Vector3.new(30, 3, -30)
        local cf = ArenaPresentation.spawnCFrame("Classic", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)
        expect(cf.LookVector:Dot(inward) > 0.98).toBe(true)
    end)

    it("frames Towers inward while targeting elevated structure", function()
        local spawn = Vector3.new(-32, 3, -32)
        local target = ArenaPresentation.lookTarget("Towers", spawn, CENTER)
        local cf = ArenaPresentation.spawnCFrame("Towers", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)

        expect(target.Y > CENTER.Y + 8).toBe(true)
        expect(cf.LookVector:Dot(inward) > 0.90).toBe(true)
    end)

    it("aligns Crossroads spawns with a cardinal lane", function()
        local spawn = Vector3.new(36, 3, 18)
        local cf = ArenaPresentation.spawnCFrame("Crossroads", spawn, CENTER)
        expect(math.abs(cf.LookVector.X) > 0.98).toBe(true)
        expect(math.abs(cf.LookVector.Z) < 0.05).toBe(true)
    end)

    it("frames Orbital spawns along the ring instead of straight inward", function()
        local spawn = Vector3.new(35, 3, 0)
        local cf = ArenaPresentation.spawnCFrame("Orbital", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)
        local tangent = Vector3.new(0, 0, 1)

        expect(cf.LookVector:Dot(tangent) > 0.80).toBe(true)
        expect(cf.LookVector:Dot(inward) > 0.15).toBe(true)
    end)

    it("always returns a planar stable spawn orientation", function()
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local cf = ArenaPresentation.spawnCFrame(
                variant,
                Vector3.new(-30, 3, 30),
                CENTER
            )
            expect(math.abs(cf.LookVector.Y) < 0.001).toBe(true)
            expect(cf.LookVector.Magnitude > 0.99).toBe(true)
        end
    end)
end)

describe("Kinetic arena signatures", function()
    it("parses malformed arena round state without losing the cosmetic listener", function()
        local rules = IdentityMotionRules
        for _, payload in ipairs({false, 7, "invalid", function() end}) do
            local phase, finalRush = rules.roundSnapshot(payload)
            expect(phase).toBe("waiting")
            expect(finalRush).toBe(false)
        end
        local missingPhase, missingRush = rules.roundSnapshot({})
        expect(missingPhase).toBe("waiting")
        expect(missingRush).toBe(false)
        local round, rushing = rules.roundSnapshot({phase = "round", finalRush = true})
        expect(round).toBe("round")
        expect(rushing).toBe(true)
        local ready, quiet = rules.roundSnapshot({phase = "ready", finalRush = true})
        expect(ready).toBe("ready")
        expect(quiet).toBe(false)
        local result, resultRush = rules.roundSnapshot({phase = "result", finalRush = false})
        expect(result).toBe("result")
        expect(resultRush).toBe(false)
        local falseRush, falseFlag = rules.roundSnapshot({phase = "round", finalRush = 1})
        expect(falseRush).toBe("round")
        expect(falseFlag).toBe(false)
    end)

    it("reuses only live signatures with identical arena and VFX inputs", function()
        local root = Instance.new("Folder")
        local otherParent = Instance.new("Folder")
        local base = Instance.new("Part")
        local replacedBase = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        replacedBase.Size = base.Size

        local built = ArenaSignatureKit.build(
            root, base, "Classic", "Medium", VisualTheme
        )
        local matches = ArenaSignatureKit.matches
        expect(matches(built, base, "Classic", "Medium", root)).toBe(true)
        expect(matches(built, base, "Classic", "High", root)).toBe(false)
        expect(matches(built, base, "Orbital", "Medium", root)).toBe(false)
        expect(matches(built, replacedBase, "Classic", "Medium", root)).toBe(false)
        expect(matches(built, base, "Classic", "Medium", otherParent)).toBe(false)
        expect(matches(nil, base, "Classic", "Medium", root)).toBe(false)

        built.folder:Destroy()
        expect(matches(built, base, "Classic", "Medium", root)).toBe(false)
        replacedBase:Destroy()
        base:Destroy()
        otherParent:Destroy()
        root:Destroy()
    end)

    it("returns every kinetic part to its distinct authored pose in Reduce Motion", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local bundle = ArenaSignatureKit.build(root, base, variant, tier, VisualTheme)
                local partCount = #bundle.parts
                -- Exercise moving and partially settled poses before
                -- switching accessibility mode while a round is active.
                ArenaSignatureKit.update(bundle, 3.7, false, 1, 1)
                ArenaSignatureKit.update(bundle, 3.7, false, 1, 0.36)
                ArenaSignatureKit.update(bundle, 21.6, true, 1)
                local ringCount = 0
                for _, entry in ipairs(bundle.animated) do
                    local part = entry.part
                    expect(part.CFrame).toBe(entry.restCFrame)
                    expect(part.Size).toBe(entry.restSize)
                    expect(part.Color).toBe(entry.color)
                    expect(part.Transparency).toBe(entry.transparency)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    if entry.role == "ring" then
                        ringCount += 1
                        -- A ring segment's rest pose is offset from its
                        -- shared rotation pivot. Never collapse its geometry.
                        expect((part.Position - entry.frame.Position).Magnitude > 2)
                            .toBe(true)
                    end
                end
                if variant == "Orbital" then
                    expect(ringCount >= 6).toBe(true)
                end
                ArenaSignatureKit.update(bundle, 8.9, true, 0)
                for _, entry in ipairs(bundle.animated) do
                    expect(entry.part.CFrame).toBe(entry.restCFrame)
                end
                expect(#bundle.parts).toBe(partCount)
                bundle.folder:Destroy()
            end
        end
        base:Destroy()
        root:Destroy()
    end)

    it("eases Final Rush kinetic signatures without new pieces or flashing", function()
        local motionRate = ArenaSignatureKit.motionRate
        expect(motionRate(0)).toBe(1)
        expect(motionRate(1) > 1.30 and motionRate(1) <= 1.32).toBe(true)
        expect(motionRate(0.5) > 1 and motionRate(0.5) < motionRate(1)).toBe(true)
        expect(motionRate(-20)).toBe(1)
        expect(motionRate(20)).toBe(motionRate(1))
        for _, invalid in ipairs({math.huge, -math.huge, 0 / 0, "fast"}) do
            expect(motionRate(invalid)).toBe(1)
        end

        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        for _, arenaId in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local built = ArenaSignatureKit.build(
                root, base, arenaId, "High", VisualTheme
            )
            local n = #built.parts
            local foundation = built.folder:FindFirstChild("SignatureFoundationLight")
            expect(foundation ~= nil).toBe(true)
            ArenaSignatureKit.update(built, 1.25, false, 0)
            local restingPulse = foundation.Transparency
            ArenaSignatureKit.update(built, 1.25, false, 1)
            expect(foundation.Transparency < restingPulse).toBe(true)
            expect(#built.parts).toBe(n)

            if arenaId == "Orbital" then
                local heart = built.folder:FindFirstChild("OrbitalGyroscopeHeart")
                ArenaSignatureKit.update(built, 1.25, false, 0)
                local normalSize = heart.Size.X
                ArenaSignatureKit.update(built, 1.25, false, 1)
                expect(heart.Size.X > normalSize).toBe(true)
            elseif arenaId == "Crossroads" then
                local signal = built.folder:FindFirstChild("CrossroadAnimatedSignal1")
                ArenaSignatureKit.update(built, 1.25, false, 0)
                local normalTransparency = signal.Transparency
                ArenaSignatureKit.update(built, 1.25, false, 1)
                expect(signal.Transparency <= normalTransparency).toBe(true)
            end

            -- Reduced-motion always returns to the same authored rest pose,
            -- regardless of Final Rush and without added flashes.
            ArenaSignatureKit.update(built, 9, true, 1)
            local stillColor = foundation.Color
            local stillTransparency = foundation.Transparency
            ArenaSignatureKit.update(built, 22, true, 0)
            expect(foundation.Transparency).toBe(stillTransparency)
            expect(foundation.Color).toBe(stillColor)
            built.folder:Destroy()
        end
        base:Destroy()
        root:Destroy()
    end)

    it("builds four genuinely different tier-aware scenic monuments", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.CFrame = CFrame.new(0, 0, 0)
        local ids = {
            {"Classic", "ClassicRadarSweep"},
            {"Towers", "TowerAnimatedLift"},
            {"Crossroads", "CrossroadAnimatedSignal1"},
            {"Orbital", "OrbitalGyroscopeHeart"},
        }
        for _, entry in ipairs(ids) do
            local variant = entry[1]
            local signature = entry[2]
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local built = ArenaSignatureKit.build(root, base, variant, tier, VisualTheme)
                expect(built.folder:FindFirstChild(signature) ~= nil).toBe(true)
                expect(#built.parts <= built.profile.MaxParts).toBe(true)
                expect(#built.animated >= 1).toBe(true)
                for _, part in ipairs(built.parts) do
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                end
                built.folder:Destroy()
            end
        end
        base:Destroy()
        root:Destroy()
    end)


    it("adds an arena-specific silhouette beyond a generic pillar or neon bar", function()
        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(110, 2, 110)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local signatures = {
                Classic = "ClassicGoniometerArc1",
                Towers = "TowerTensionTruss-1_1",
                Crossroads = "CrossroadRouteChevron-1_1",
                Orbital = "OrbitalContainmentPylon1",
            }
            for arenaId, motif in pairs(signatures) do
                local bundle = ArenaSignatureKit.build(parent, base, arenaId, tier, VisualTheme)
                expect(bundle.folder:FindFirstChild(motif) ~= nil).toBe(true)
                expect(#bundle.parts > 12).toBe(true)
                expect(#bundle.parts <= bundle.profile.MaxParts).toBe(true)
                for _, item in ipairs(bundle.parts) do
                    expect(item.Anchored).toBe(true)
                    expect(item.CanCollide).toBe(false)
                    expect(item.CanTouch).toBe(false)
                    expect(item.CanQuery).toBe(false)
                end
                bundle.folder:Destroy()
            end
        end
        base:Destroy()
        parent:Destroy()
    end)

    it("articulates identifiable four-map machine details without extra effects or collisions", function()
        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        local details = {
            Classic = "ClassicTrackingVane1",
            Towers = "TowerHydraulicPiston-1",
            Crossroads = "CrossroadSemaphoreArm1",
            Orbital = "OrbitalIrisShutter1",
        }
        for variant, name in pairs(details) do
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local built = ArenaSignatureKit.build(parent, base, variant, tier, VisualTheme)
                local component = built.folder:FindFirstChild(name)
                if tier == "Low" then
                    expect(component == nil).toBe(true)
                else
                    expect(component ~= nil).toBe(true)
                    expect(component:IsA("BasePart")).toBe(true)
                    local rest = component.CFrame
                    local sizeAtRest = component.Size
                    local originalPartCount = #built.parts
                    ArenaSignatureKit.update(built, 2.5, false, 1)
                    expect(component.CFrame ~= rest).toBe(true)
                    -- The low-work animation loop never allocates anything.
                    expect(#built.parts).toBe(originalPartCount)
                    ArenaSignatureKit.update(built, 14, true, 1)
                    expect(component.CFrame).toBe(rest)
                    expect(component.Size).toBe(sizeAtRest)
                    ArenaSignatureKit.update(built, 4, true, 0)
                    expect(component.CFrame).toBe(rest)
                end
                expect(#built.parts <= built.profile.MaxParts).toBe(true)
                for _, part in ipairs(built.parts) do
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                end
                built.folder:Destroy()
            end
        end
        base:Destroy()
        parent:Destroy()
    end)

    it("eases four mechanical signatures into their original result poses", function()
        local settle = ArenaSignatureKit.settleAmount
        expect(settle(0, 0.72)).toBe(1)
        expect(math.abs(settle(0.36, 0.72) - 0.5) < 0.0001).toBe(true)
        expect(settle(0.72, 0.72)).toBe(0)
        expect(settle(10, 0.72)).toBe(0)
        for _, invalid in ipairs({math.huge, -math.huge, 0 / 0, "oops"}) do
            expect(settle(invalid, 0.72)).toBe(0)
        end
        expect(settle(0.36, 0)).toBe(0)
        expect(settle(0.36, math.huge)).toBe(0)

        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        local variantParts = {
            Classic = "ClassicTrackingVane1",
            Towers = "TowerHydraulicPiston-1",
            Crossroads = "CrossroadSemaphoreArm1",
            Orbital = "OrbitalIrisShutter1",
        }
        for variant, name in pairs(variantParts) do
            local built = ArenaSignatureKit.build(parent, base, variant, "High", VisualTheme)
            local part = built.folder:FindFirstChild(name)
            local rest, restSize = part.CFrame, part.Size
            local count = #built.parts
            ArenaSignatureKit.update(built, 2.5, false, 1, 1)
            local animatedPose = part.CFrame
            expect(animatedPose ~= rest).toBe(true)

            ArenaSignatureKit.update(built, 2.5, false, 1, 0.5)
            expect(part.CFrame ~= animatedPose).toBe(true)
            expect(part.CFrame ~= rest).toBe(true)
            ArenaSignatureKit.update(built, 2.5, false, 1, 0)
            expect(part.CFrame).toBe(rest)
            expect(part.Size).toBe(restSize)
            expect(#built.parts).toBe(count)
            -- Reduced-motion must take effect immediately, not run a
            -- cosmetic settle which the player deliberately disabled.
            ArenaSignatureKit.update(built, 9, true, 1)
            expect(part.CFrame).toBe(rest)
            expect(part.Size).toBe(restSize)
            built.folder:Destroy()
        end
        base:Destroy()
        parent:Destroy()
    end)

    it("keeps the hydraulic piston physically under the animated lift", function()
        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        for _, tier in ipairs({"Medium", "High"}) do
            local built = ArenaSignatureKit.build(parent, base, "Towers", tier, VisualTheme)
            local cabin = built.folder:FindFirstChild("TowerAnimatedLift")
            for _, t in ipairs({0, 1.6, 4, 6.7, 9.5}) do
                ArenaSignatureKit.update(built, t, false, 0.5)
                for _, name in ipairs({"TowerHydraulicPiston-1", "TowerHydraulicPiston1"}) do
                    local piston = built.folder:FindFirstChild(name)
                    expect(piston ~= nil).toBe(true)
                    local lower = piston.Position.Y - piston.Size.Y * 0.5
                    local upper = piston.Position.Y + piston.Size.Y * 0.5
                    expect(math.abs(upper - (cabin.Position.Y - cabin.Size.Y * 0.5)) < 0.005).toBe(true)
                    expect(math.abs(lower - (base.Position.Y + base.Size.Y * 0.5 + 0.7 + 1.7)) < 0.005).toBe(true)
                    expect(piston.Size.Y >= 0.40 and piston.Size.Y <= 4.61).toBe(true)
                end
            end
            built.folder:Destroy()
        end
        base:Destroy()
        parent:Destroy()
    end)

    it("animates original tower counterweights opposite the lift and restores accessibility pose", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local built = ArenaSignatureKit.build(root, base, "Towers", tier, VisualTheme)
            local lift = built.folder:FindFirstChild("TowerAnimatedLift")
            local left = built.folder:FindFirstChild("TowerCounterweight-1")
            local right = built.folder:FindFirstChild("TowerCounterweight1")
            expect(lift ~= nil and left ~= nil and right ~= nil).toBe(true)
            local liftFrame, leftFrame, rightFrame = lift.CFrame, left.CFrame, right.CFrame
            ArenaSignatureKit.update(built, 2.5, false)
            local liftDelta = lift.Position.Y - liftFrame.Position.Y
            local leftDelta = left.Position.Y - leftFrame.Position.Y
            local rightDelta = right.Position.Y - rightFrame.Position.Y
            expect(liftDelta > 0).toBe(true)
            expect(leftDelta < 0 and rightDelta < 0).toBe(true)
            expect(math.abs(leftDelta) <= 1.401).toBe(true)
            expect(math.abs(rightDelta - leftDelta) < 0.0001).toBe(true)
            ArenaSignatureKit.update(built, 9, true)
            expect(lift.CFrame).toBe(liftFrame)
            expect(left.CFrame).toBe(leftFrame)
            expect(right.CFrame).toBe(rightFrame)
            built.folder:Destroy()
        end
        base:Destroy()
        root:Destroy()
    end)

    it("keeps tower geometry finite when an invalid animation clock arrives", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        local built = ArenaSignatureKit.build(root, base, "Towers", "Low", VisualTheme)
        ArenaSignatureKit.update(built, 0, true)
        local cabin = built.folder:FindFirstChild("TowerAnimatedLift")
        local weight = built.folder:FindFirstChild("TowerCounterweight1")
        local cabinFrame, weightFrame = cabin.CFrame, weight.CFrame
        for _, invalid in ipairs({math.huge, -math.huge, 0 / 0, -5, 1e8, "not-a-time"}) do
            ArenaSignatureKit.update(built, invalid, false)
            expect(cabin.CFrame).toBe(cabinFrame)
            expect(weight.CFrame).toBe(weightFrame)
        end
        built.folder:Destroy()
        base:Destroy()
        root:Destroy()
    end)

    it("freezes motion predictably for mobile accessibility", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local built = ArenaSignatureKit.build(root, base, variant, "Medium", VisualTheme)
            local animated = built.animated[1].part
            ArenaSignatureKit.update(built, 1, true)
            local frozenCF = animated.CFrame
            local frozenTransparency = animated.Transparency
            ArenaSignatureKit.update(built, 10, true)
            expect(animated.CFrame).toBe(frozenCF)
            expect(animated.Transparency).toBe(frozenTransparency)
            ArenaSignatureKit.update(built, 2, false)
            expect(
                animated.CFrame ~= frozenCF
                    or animated.Transparency ~= frozenTransparency
                    or variant == "Orbital"
            ).toBe(true)
            built.folder:Destroy()
        end
        base:Destroy()
        root:Destroy()
    end)
end)


describe("Late-replicated visual map readiness", function()
    it("rebuilds only when the target floor or arena base actually arrives", function()
        local generated = Instance.new("Folder")
        local calls = 0
        local sawBase = false
        local active = MapVisualReadiness.watch(generated, "Arena", "Base", function(base)
            calls += 1
            sawBase = base ~= nil
        end)
        expect(calls).toBe(1)
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        expect(calls).toBe(2)
        expect(sawBase).toBe(false)
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Parent = arena
        expect(calls).toBe(3)
        expect(sawBase).toBe(true)
        arena:SetAttribute("VariantId", "Orbital")
        expect(calls).toBe(4)
        expect(MapVisualReadiness.part(generated, "Arena", "Base")).toBe(base)
        base:Destroy()
        expect(calls).toBe(5)
        expect(sawBase).toBe(false)
        active()
        local replacement = Instance.new("Part")
        replacement.Name = "Base"
        replacement.Parent = arena
        expect(calls).toBe(5)
        generated:Destroy()

        -- During streaming, an old Arena and its fully constructed
        -- replacement can overlap under the same GeneratedMap. The
        -- watcher must follow the same canonical child as part().
        local swapping = Instance.new("Folder")
        local callsOnSwap = 0
        local currentBase = nil
        local stopSwap = MapVisualReadiness.watch(
            swapping, "Arena", "Base", function(part)
                callsOnSwap += 1
                currentBase = part
            end
        )
        local oldArena = Instance.new("Folder")
        oldArena.Name = "Arena"
        oldArena.Parent = swapping
        local oldBase = Instance.new("Part")
        oldBase.Name = "Base"
        oldBase.Parent = oldArena
        expect(currentBase).toBe(oldBase)

        local nextArena = Instance.new("Folder")
        nextArena.Name = "Arena"
        local nextBase = Instance.new("Part")
        nextBase.Name = "Base"
        nextBase.Parent = nextArena
        local beforeOverlap = callsOnSwap
        nextArena.Parent = swapping
        -- Roblox does not promise which identically named sibling
        -- FindFirstChild selects. The watcher must always agree with it.
        local overlapBase = MapVisualReadiness.part(swapping, "Arena", "Base")
        expect(currentBase).toBe(overlapBase)
        if overlapBase == oldBase then
            expect(callsOnSwap).toBe(beforeOverlap)
        else
            expect(overlapBase).toBe(nextBase)
            expect(callsOnSwap).toBe(beforeOverlap + 1)
        end

        local beforeRemoval = callsOnSwap
        oldArena.Parent = nil
        expect(MapVisualReadiness.part(swapping, "Arena", "Base")).toBe(nextBase)
        expect(currentBase).toBe(nextBase)
        expect(callsOnSwap).toBe(
            beforeRemoval + (if overlapBase == oldBase then 1 else 0)
        )
        nextArena:SetAttribute("VariantId", "Orbital")
        expect(callsOnSwap).toBe(
            beforeRemoval + (if overlapBase == oldBase then 2 else 1)
        )
        nextBase:Destroy()
        expect(currentBase == nil).toBe(true)
        stopSwap()
        local beforeDispose = callsOnSwap
        nextArena:SetAttribute("VariantId", "Crossroads")
        expect(callsOnSwap).toBe(beforeDispose)
        oldArena:Destroy()
        swapping:Destroy()
    end)

    it("rebuilds understructure when Base and VariantId replicate late", function()
        local generated = Instance.new("Folder")
        local events = {}
        local function record(base)
            local arena = generated:FindFirstChild("Arena")
            table.insert(events, {
                present = base ~= nil,
                variant = arena and arena:GetAttribute("VariantId") or nil,
            })
        end

        local disconnect = MapVisualReadiness.watch(
            generated, "Arena", "Base", record
        )
        expect(#events).toBe(1)
        expect(events[#events].present).toBe(false)

        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        expect(#events).toBe(2)
        expect(events[#events].present).toBe(false)

        -- A client may get the Base before the correct arena attribute.
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Parent = arena
        expect(#events).toBe(3)
        expect(events[#events].present).toBe(true)
        arena:SetAttribute("VariantId", "Towers")
        expect(#events).toBe(4)
        expect(events[#events].variant).toBe("Towers")

        base:Destroy()
        expect(events[#events].present).toBe(false)
        local replacement = Instance.new("Part")
        replacement.Name = "Base"
        replacement.Parent = arena
        expect(events[#events].present).toBe(true)

        disconnect()
        local before = #events
        arena:SetAttribute("VariantId", "Orbital")
        replacement:Destroy()
        expect(#events).toBe(before)
        generated:Destroy()
    end)

    it("tracks mobile mobility-pad markers and impulses that replicate late", function()
        local mechanics = Instance.new("Folder")
        local events = 0
        local dispose = MapVisualReadiness.watchChildrenAttributes(
            mechanics,
            {"ArenaMobilityPad", "ImpulseX", "ImpulseY", "ImpulseZ"},
            function()
                events += 1
            end
        )
        expect(events).toBe(1)

        local pad = Instance.new("Part")
        pad.Name = "MobilityPad"
        pad.Parent = mechanics
        expect(events).toBe(2)
        -- A replicated part can arrive before the attribute that marks it.
        pad:SetAttribute("ArenaMobilityPad", true)
        expect(events).toBe(3)
        pad:SetAttribute("ImpulseX", 18)
        pad:SetAttribute("ImpulseY", 24)
        pad:SetAttribute("ImpulseZ", -7)
        expect(events).toBe(6)

        local unrelated = Instance.new("Folder")
        unrelated.Parent = mechanics
        expect(events).toBe(6)
        unrelated:Destroy()
        expect(events).toBe(6)

        pad.Parent = nil
        expect(events).toBe(7)
        pad:SetAttribute("ImpulseX", 99)
        expect(events).toBe(7)
        pad:Destroy()

        local replacement = Instance.new("Part")
        replacement:SetAttribute("ArenaMobilityPad", true)
        replacement:SetAttribute("ImpulseZ", 11)
        replacement.Parent = mechanics
        expect(events).toBe(8)
        dispose()
        replacement:SetAttribute("ImpulseZ", 20)
        replacement:Destroy()
        expect(events).toBe(8)
        mechanics:Destroy()
    end)

    it("detects a lobby floor that appears after its parent model", function()
        local generated = Instance.new("Folder")
        local calls = 0
        local current = nil
        local dispose = MapVisualReadiness.watch(generated, "Lobby", "Floor", function(floor)
            calls += 1
            current = floor
        end)
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = generated
        local floor = Instance.new("Part")
        floor.Name = "Floor"
        floor.Parent = lobby
        expect(calls).toBe(3)
        expect(current).toBe(floor)
        lobby:Destroy()
        expect(current == nil).toBe(true)
        dispose()
        generated:Destroy()
    end)
end)


describe("Arena architectural secondary motifs", function()
    it("keeps each arena uniquely recognizable across both prop scales", function()
        local root = Instance.new("Folder")
        local host = Instance.new("Part")
        host.Size = Vector3.new(6, 8, 5)
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            for _, role in ipairs({"Service", "Midground"}) do
                local names = ArenaDetailKit.names(variant, role)
                expect(names ~= nil).toBe(true)
                expect(#names).toBe(3)
                for _, tier in ipairs({"Low", "Medium", "High"}) do
                    local built = ArenaDetailKit.build(root, role, variant, host, tier,
                        VisualTheme.arena(variant))
                    expect(#built).toBe(ArenaDetailKit.count(tier))
                    for i, part in ipairs(built) do
                        expect(part.Name).toBe(names[i])
                        expect(part.Anchored).toBe(true)
                        expect(part.CanCollide).toBe(false)
                        expect(part.CanQuery).toBe(false)
                        expect(part.CanTouch).toBe(false)
                        expect(part:GetAttribute("ChaosVisualMotif")).toBe(true)
                        part:Destroy()
                    end
                end
            end
        end
        host:Destroy()
        root:Destroy()
    end)

    it("does not create geometry without a valid parent, host and arena", function()
        local folder = Instance.new("Folder")
        local host = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaDetailKit.build(folder, "Service", "Unknown", host, "High", theme)).toBe(0)
        expect(#ArenaDetailKit.build(folder, "Service", "Classic", nil, "High", theme)).toBe(0)
        expect(#ArenaDetailKit.build(folder, "Service", "Classic", host, "High", nil)).toBe(0)
        host:Destroy()
        folder:Destroy()
    end)
end)


describe("Streaming-independent platform identity", function()
    it("sorts late-replicated platforms naturally, independent of arrival order", function()
        local folder = Instance.new("Folder")
        local names = {"Platform10", "Platform3", "Platform1", "Platform2"}
        local parts = {}
        for _, name in ipairs(names) do
            local part = Instance.new("Part")
            part.Name = name
            part.Parent = folder
            parts[name] = part
        end
        local decoration = Instance.new("Folder")
        decoration.Name = "NotAPlatform"
        decoration.Parent = folder

        local ordered = PlatformFinishKit.orderedPlatforms(folder)
        expect(#ordered).toBe(4)
        expect(ordered[1]).toBe(parts.Platform1)
        expect(ordered[2]).toBe(parts.Platform2)
        expect(ordered[3]).toBe(parts.Platform3)
        expect(ordered[4]).toBe(parts.Platform10)

        -- Rejoining / streaming out and back must not change which
        -- platforms get the odd-numbered Low-tier visual budget.
        parts.Platform2.Parent = nil
        parts.Platform2.Parent = folder
        local again = PlatformFinishKit.orderedPlatforms(folder)
        for index, part in ipairs(ordered) do
            expect(again[index]).toBe(part)
        end

        expect(#PlatformFinishKit.orderedPlatforms(nil)).toBe(0)
        folder:Destroy()
    end)

    it("keeps Low-tier subset stable before earlier platforms stream in", function()
        local folder = Instance.new("Folder")
        local two = Instance.new("Part")
        two.Name = "Platform2"
        two.Parent = folder
        local ten = Instance.new("Part")
        ten.Name = "Skybridge10"
        ten.Parent = folder

        -- A client might first receive only these even-numbered Parts.
        local before = PlatformFinishKit.orderedPlatforms(folder)
        expect(#before).toBe(2)
        for _, platform in ipairs(before) do
            expect(PlatformFinishKit.visualIndex(platform, 1) % 2).toBe(0)
        end

        local one = Instance.new("Part")
        one.Name = "Platform1"
        one.Parent = folder
        local three = Instance.new("Part")
        three.Name = "Skybridge3"
        three.Parent = folder
        local after = PlatformFinishKit.orderedPlatforms(folder)
        local selected = {}
        for index, platform in ipairs(after) do
            local visualIndex = PlatformFinishKit.visualIndex(platform, index)
            if visualIndex % 2 == 1 then
                selected[platform.Name] = true
            end
        end
        expect(selected.Platform1).toBe(true)
        expect(selected.Skybridge3).toBe(true)
        expect(selected.Platform2 == nil).toBe(true)
        expect(selected.Skybridge10 == nil).toBe(true)

        local unexpected = Instance.new("Part")
        unexpected.Name = "CustomPad"
        expect(PlatformFinishKit.visualIndex(unexpected, 5)).toBe(5)
        unexpected:Destroy()
        folder:Destroy()
    end)

    it("breaks duplicate platform names by stable position", function()
        local folder = Instance.new("Folder")
        local right = Instance.new("Part")
        right.Name = "MovingPlatform"
        right.Position = Vector3.new(15, 1, 0)
        right.Parent = folder
        local left = Instance.new("Part")
        left.Name = "MovingPlatform"
        left.Position = Vector3.new(-15, 1, 0)
        left.Parent = folder
        local ordered = PlatformFinishKit.orderedPlatforms(folder)
        expect(ordered[1]).toBe(left)
        expect(ordered[2]).toBe(right)
        folder:Destroy()
    end)
end)

describe("Moving platform premium trim kit", function()
    it("scales Classic's welded route paint with actual shrinking geometry", function()
        local root = Instance.new("Folder")
        root.Parent = workspace
        local deck = Instance.new("Part")
        deck.Name = "Platform1"
        deck.Size = Vector3.new(10, 2, 10)
        deck.CFrame = CFrame.new(22, 12, 12)
        deck.Anchored = true
        deck:SetAttribute("RouteTier", 3)
        deck.Parent = root
        local visuals = Instance.new("Folder")
        visuals.Parent = root
        local pieces = PlatformFinishKit.build(
            visuals, deck, "Classic", "High", VisualTheme.arena("Classic")
        )
        expect(#pieces > 0).toBe(true)
        local first = pieces[1]
        local weld = first:FindFirstChild("ChaosPlatformTrimWeld")
        expect(weld ~= nil and weld:IsA("Weld")).toBe(true)
        expect(weld.Part1).toBe(deck)
        local firstSize = first.Size
        local firstOffset = deck.CFrame:ToObjectSpace(first.CFrame).Position

        local snapshot = PlatformFinishKit.captureRouteFootprint(deck, pieces)
        expect(snapshot ~= nil).toBe(true)
        expect(#snapshot.entries).toBe(#pieces)
        deck.Size = Vector3.new(4.5, 2, 4.5)
        expect(PlatformFinishKit.applyRouteFootprint(snapshot)).toBe(#pieces)
        expect(math.abs(first.Size.X - firstSize.X * 0.45) < 0.01).toBe(true)
        expect(math.abs(first.Size.Z - firstSize.Z * 0.45) < 0.01).toBe(true)
        expect((weld.C1.Position
            - Vector3.new(firstOffset.X * 0.45,
                firstOffset.Y, firstOffset.Z * 0.45)).Magnitude < 0.01)
            .toBe(true)

        deck.Size = Vector3.new(10, 2, 10)
        PlatformFinishKit.applyRouteFootprint(snapshot)
        expect((first.Size - firstSize).Magnitude < 0.005).toBe(true)
        expect((weld.C1.Position - firstOffset).Magnitude < 0.01).toBe(true)

        -- Resizing remains bounded and event-driven: no per-frame polling.
        local disconnect = PlatformFinishKit.bindRouteFootprint(deck, pieces)
        deck.Size = Vector3.new(7, 2, 7)
        task.wait(0.06)
        expect(math.abs(first.Size.X - firstSize.X * 0.7) < 0.01)
            .toBe(true)
        disconnect()
        local frozen = first.Size
        deck.Size = Vector3.new(5, 2, 5)
        task.wait(0.06)
        expect((first.Size - frozen).Magnitude < 0.005).toBe(true)
        root:Destroy()
    end)

    it("shrinks client-painted Tower skybridge bands with real bridge spans", function()
        local root = Instance.new("Folder")
        root.Parent = workspace
        local platform = Instance.new("Part")
        platform.Name = "Skybridge18"
        platform.Size = Vector3.new(58, 2, 7)
        platform.Anchored = true
        platform.CFrame = CFrame.new(22, 14, -19)
            * CFrame.Angles(0, math.rad(27), 0)
        platform:SetAttribute("ChaosSkybridge", true)
        platform.Parent = root

        local visual = Instance.new("Folder")
        visual.Parent = root
        local theme = VisualTheme.arena("Towers")
        local rails = PlatformFinishKit.buildSideRails(
            visual, platform, "High", theme
        )
        local paint = PlatformFinishKit.build(
            visual, platform, "Towers", "High", theme
        )
        local armor = PlatformFinishKit.buildArmor(
            visual, platform, "Towers", "High", theme
        )
        local pieces = {}
        for _, family in ipairs({rails, paint, armor}) do
            for _, piece in ipairs(family) do
                table.insert(pieces, piece)
            end
        end
        expect(#rails).toBe(4)
        for _, part in ipairs(pieces) do
            local joint = part:FindFirstChild("ChaosPlatformTrimWeld")
            expect(joint ~= nil and joint:IsA("Weld")).toBe(true)
            expect(joint.Part0).toBe(part)
            expect(joint.Part1).toBe(platform)
        end
        local originalRailSize = rails[1].Size
        local originalRigidSize = armor[1].Size
        local endBefore = platform.CFrame:PointToObjectSpace(rails[3].Position)
        local snapshot = PlatformFinishKit.captureSkybridgeFootprint(
            platform, pieces
        )
        expect(snapshot ~= nil).toBe(true)
        expect(#snapshot.entries).toBe(#pieces)

        platform.Size = Vector3.new(29, 2, 7)
        expect(PlatformFinishKit.applySkybridgeFootprint(snapshot))
            .toBe(#pieces)
        local function assertNear(label, actual, expected, tolerance)
            if math.abs(actual - expected) >= tolerance then
                error("Skybridge " .. label .. ": actual=" .. tostring(actual)
                    .. " expected=" .. tostring(expected))
            end
        end
        assertNear("rail span", rails[1].Size.X,
            originalRailSize.X * 0.5, 0.005)
        assertNear("rigid armor", armor[1].Size.X,
            originalRigidSize.X, 0.005)
        assertNear("rail end", platform.CFrame:PointToObjectSpace(rails[3].Position).X,
            endBefore.X * 0.5, 0.01)
        expect(math.abs(rails[1].Size.X - originalRailSize.X * 0.5)
            < 0.005).toBe(true)
        expect((armor[1].Size - originalRigidSize).Magnitude < 0.005)
            .toBe(true)
        local endAfter = platform.CFrame:PointToObjectSpace(rails[3].Position)
        expect(math.abs(endAfter.X - endBefore.X * 0.5) < 0.01)
            .toBe(true)
        for _, piece in ipairs(pieces) do
            expect(piece.CanCollide).toBe(false)
            expect(piece.CanTouch).toBe(false)
            expect(piece.CanQuery).toBe(false)
        end

        -- A disconnected watcher stops responding to future bridge resizes.
        platform.Size = Vector3.new(58, 2, 7)
        PlatformFinishKit.applySkybridgeFootprint(snapshot)
        local disconnect = PlatformFinishKit.bindSkybridgeFootprint(
            platform, pieces
        )
        platform.Size = Vector3.new(43.5, 2, 7)
        task.wait(0.06)
        assertNear("size listener", rails[1].Size.X,
            originalRailSize.X * 0.75, 0.005)
        expect(math.abs(rails[1].Size.X - originalRailSize.X * 0.75)
            < 0.005).toBe(true)
        disconnect()
        local sizeBeforeStop = rails[1].Size
        platform.Size = Vector3.new(29, 2, 7)
        task.wait(0.06)
        expect((rails[1].Size - sizeBeforeStop).Magnitude < 0.005)
            .toBe(true)

        root:Destroy()
    end)


    it("creates four distinctive, bounded, non-colliding welded motifs", function()
        local parent = Instance.new("Folder")
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(12, 2, 12)
        platform.Parent = workspace
        -- The server panel has its upper face at physicalTop + 0.105.
        -- Local glyph geometry must be ABOVE it or it vanishes beneath
        -- the authoritative floor finish on Android.
        local surfaceY = PlatformFinishKit.surfacePaintOffset(platform, 0.05)
        expect(surfaceY - 0.025 > platform.Size.Y * 0.5 + 0.105).toBe(true)
        -- The animated amber outline is even thinner than the paint,
        -- so its 0.06-high bars must clear the exact same surface.
        local warningY = PlatformFinishKit.surfacePaintOffset(platform, 0.06)
        expect(warningY - 0.03 > platform.Size.Y * 0.5 + 0.105).toBe(true)
        -- MapBuilder adds PlatformPanel even to permanent Tower skybridges;
        -- the local glyph must clear the actual panel there as well.
        platform:SetAttribute("ChaosSkybridge", true)
        local bridgePaintY = PlatformFinishKit.surfacePaintOffset(platform, 0.05)
        expect(bridgePaintY - 0.025 > platform.Size.Y * 0.5 + 0.105).toBe(true)
        expect(math.abs(bridgePaintY - surfaceY) < 0.0001).toBe(true)
        platform:SetAttribute("ChaosSkybridge", nil)
        expect(math.abs(
            PlatformFinishKit.surfacePaintOffset(platform, 0.05) - surfaceY
        ) < 0.0001).toBe(true)
        expect(PlatformFinishKit.surfacePaintOffset(nil, 0.05) == nil).toBe(true)
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local names = PlatformFinishKit.names(variant)
            expect(#names).toBe(3)
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local built = PlatformFinishKit.build(parent, platform, variant,
                    tier, VisualTheme.arena(variant))
                expect(#built).toBe(PlatformFinishKit.count(tier))
                for index, item in ipairs(built) do
                    expect(item.Name).toBe(names[index])
                    expect(item:GetAttribute("ChaosPlatformTrim")).toBe(true)
                    expect(item.Massless).toBe(true)
                    expect(item.Anchored).toBe(false)
                    expect(item.CanCollide).toBe(false)
                    expect(item.CanTouch).toBe(false)
                    expect(item.CanQuery).toBe(false)
                    if variant ~= "Towers" and index <= 2 then
                        local deckRelative = platform.CFrame:PointToObjectSpace(item.Position)
                        -- The lowest face of paint must clear the panel.
                        expect(deckRelative.Y - item.Size.Y * 0.5
                            > platform.Size.Y * 0.5 + 0.105).toBe(true)
                    end
                    local weld = item:FindFirstChild("ChaosPlatformTrimWeld")
                    expect(weld ~= nil).toBe(true)
                    expect(weld.Part0).toBe(item)
                    expect(weld.Part1).toBe(platform)
                    expect(typeof(item:GetAttribute("ChaosBaseTransparency")))
                        .toBe("number")
                    local baseline = item.Transparency
                    PlatformFinishKit.applyCollapseVisibility({item}, "Gone")
                    expect(item.Transparency).toBe(1)
                    PlatformFinishKit.applyCollapseVisibility({item}, nil)
                    expect(item.Transparency).toBe(baseline)
                    item:Destroy()
                end

                local armor = PlatformFinishKit.buildArmor(
                    parent, platform, variant, tier, VisualTheme.arena(variant)
                )
                expect(#armor).toBe(PlatformFinishKit.armorCount(tier))
                for _, plate in ipairs(armor) do
                    expect(plate:IsA("WedgePart")).toBe(true)
                    expect(plate:GetAttribute("ChaosPlatformTrim")).toBe(true)
                    expect(plate:GetAttribute("ChaosArmorCorner") ~= nil).toBe(true)
                    expect(plate.Anchored).toBe(false)
                    expect(plate.Massless).toBe(true)
                    expect(plate.CanCollide).toBe(false)
                    expect(plate.CanTouch).toBe(false)
                    expect(plate.CanQuery).toBe(false)
                    local weld = plate:FindFirstChild("ChaosPlatformTrimWeld")
                    expect(weld ~= nil and weld.Part1 == platform).toBe(true)
                    local offset = platform.CFrame:PointToObjectSpace(plate.Position)
                    expect(math.abs(offset.X) < platform.Size.X * 0.5 + 1).toBe(true)
                    expect(math.abs(offset.Z) < platform.Size.Z * 0.5 + 1).toBe(true)
                    -- Raised wedges must be readable above the inset,
                    -- but stay INSIDE the real floor collision outline:
                    -- no fake walkable ledges at a disaster drop.
                    expect(offset.Y + plate.Size.Y * 0.5
                        > platform.Size.Y * 0.5 + 0.105).toBe(true)
                    expect(math.abs(offset.X) + plate.Size.X * 0.5
                        < platform.Size.X * 0.5).toBe(true)
                    expect(math.abs(offset.Z) + plate.Size.Z * 0.5
                        < platform.Size.Z * 0.5).toBe(true)
                end

                PlatformFinishKit.applyCollapseVisibility(armor, "Gone")
                for _, plate in ipairs(armor) do
                    expect(plate.Transparency).toBe(1)
                end
                PlatformFinishKit.applyCollapseVisibility(armor, "Warning")
                for _, plate in ipairs(armor) do
                    -- The amber collapse warning must stay visible through
                    -- client-only welded armor, including after Gone.
                    expect(plate.Transparency >= 0.799).toBe(true)
                end
                PlatformFinishKit.applyCollapseVisibility(armor, nil)
                for _, plate in ipairs(armor) do
                    expect(math.abs(plate.Transparency - 0.04) < 0.0001).toBe(true)
                    plate:Destroy()
                end
            end
        end
        platform:Destroy()
        parent:Destroy()
    end)

    it("refuses unexpected variants and invalid platform parents", function()
        local container = Instance.new("Folder")
        local base = Instance.new("Part")
        expect(#PlatformFinishKit.build(container, base, "NotAnArena", "High",
            VisualTheme.arena("Classic"))).toBe(0)
        expect(#PlatformFinishKit.build(container, nil, "Classic", "High",
            VisualTheme.arena("Classic"))).toBe(0)
        expect(#PlatformFinishKit.build(nil, base, "Classic", "High",
            VisualTheme.arena("Classic"))).toBe(0)
        expect(#PlatformFinishKit.buildArmor(container, base, "NotAnArena", "High",
            VisualTheme.arena("Classic"))).toBe(0)
        expect(#PlatformFinishKit.buildArmor(nil, base, "Classic", "High",
            VisualTheme.arena("Classic"))).toBe(0)
        expect(#PlatformFinishKit.buildArmor(container, base, "Classic", "Low",
            VisualTheme.arena("Classic"))).toBe(0)
        base:Destroy()
        container:Destroy()
    end)
end)
 

describe("Premium arena perimeter geometry", function()
    it("keeps the four outboard edge silhouettes distinct at every graphics tier", function()
        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 80)
        base.CFrame = CFrame.new(21, 13, -17)
            * CFrame.Angles(0, math.rad(31), 0)
        local seen = {}
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local names = ArenaEdgeFinishKit.names(variant)
            expect(#names).toBe(3)
            expect(seen[names[1]] == nil).toBe(true)
            seen[names[1]] = true
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local built = ArenaEdgeFinishKit.build(
                    parent, base, variant, tier, VisualTheme.arena(variant))
                expect(#built).toBe(ArenaEdgeFinishKit.count(tier) * 4)
                local north = parent:FindFirstChild(names[1] .. "North")
                expect(north ~= nil).toBe(true)
                local offset = base.CFrame:PointToObjectSpace(north.Position)
                expect(offset.Z < -base.Size.Z * 0.5).toBe(true)
                for _, item in ipairs(built) do
                    expect(item:GetAttribute("ChaosEdgeFinish")).toBe(true)
                    expect(item.Anchored).toBe(true)
                    expect(item.CanCollide).toBe(false)
                    expect(item.CanTouch).toBe(false)
                    expect(item.CanQuery).toBe(false)
                    if tier == "Low" then
                        expect(item.Material == Enum.Material.Neon).toBe(false)
                    end
                    item:Destroy()
                end
            end
        end
        parent:Destroy()
        base:Destroy()
    end)

    it("does not generate unmanaged edge geometry for invalid inputs", function()
        local holder = Instance.new("Folder")
        local base = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaEdgeFinishKit.build(holder, base, "Unknown", "High", theme)).toBe(0)
        expect(#ArenaEdgeFinishKit.build(holder, nil, "Classic", "High", theme)).toBe(0)
        expect(#ArenaEdgeFinishKit.build(nil, base, "Classic", "High", theme)).toBe(0)
        holder:Destroy()
        base:Destroy()
    end)
end)


describe("Arena skyline visual identity", function()
    it("keeps four distinct outboard silhouettes readable from Low to High", function()
        local holder = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 3, 84)
        base.CFrame = CFrame.new(27, 14, -34)
            * CFrame.Angles(0, math.rad(34), 0)
        local primaryNames = {}
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local names = ArenaSilhouetteAccentKit.names(variant)
            expect(#names).toBe(4)
            expect(primaryNames[names[1]] == nil).toBe(true)
            primaryNames[names[1]] = true
            for _, tierName in ipairs({"Low", "Medium", "High"}) do
                local built = ArenaSilhouetteAccentKit.build(
                    holder, base, variant, tierName, VisualTheme.arena(variant))
                expect(#built).toBe(ArenaSilhouetteAccentKit.count(tierName))
                for i, part in ipairs(built) do
                    expect(part.Name).toBe(names[i])
                    expect(part:GetAttribute("ChaosSilhouetteAccent")).toBe(true)
                    expect(part:GetAttribute("ArenaVariant")).toBe(variant)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part.Size.X > 0 and part.Size.Y > 0 and part.Size.Z > 0).toBe(true)
                    local relative = base.CFrame:PointToObjectSpace(part.Position)
                    expect(
                        math.abs(relative.X) > base.Size.X * 0.5
                            or math.abs(relative.Z) > base.Size.Z * 0.5
                    ).toBe(true)
                    if tierName == "Low" then
                        expect(part.Material == Enum.Material.Neon).toBe(false)
                    end
                    part:Destroy()
                end
            end
        end
        expect(ArenaSilhouetteAccentKit.count("Low")).toBe(3)
        expect(ArenaSilhouetteAccentKit.count("Medium")).toBe(3)
        expect(ArenaSilhouetteAccentKit.count("High")).toBe(4)
        holder:Destroy()
        base:Destroy()
    end)

    it("keeps Crossroads service beam aligned with rotated and tilted pylons", function()
        local left = Instance.new("Part")
        local right = Instance.new("Part")
        for _, frame in ipairs({
            CFrame.new(0, 12, 0),
            CFrame.new(21, 18, -9) * CFrame.Angles(0, math.rad(53), 0),
            CFrame.new(-15, 24, 36)
                * CFrame.Angles(math.rad(13), math.rad(-37), math.rad(8)),
        }) do
            left.CFrame = frame * CFrame.new(-63, 7.2, 12)
            right.CFrame = frame * CFrame.new(-63, 5.2, 18)
            local actual = ArenaSilhouetteAccentKit.crossroadsBeamFrame(left, right)
            local expected = frame * CFrame.new(-63, 10, 15)
                * CFrame.Angles(math.rad(9), 0, 0)
            expect((actual.Position - expected.Position).Magnitude < 0.001).toBe(true)
            expect(actual.LookVector:Dot(expected.LookVector) > 0.9999).toBe(true)
            expect(actual.UpVector:Dot(expected.UpVector) > 0.9999).toBe(true)
            expect(actual.RightVector:Dot(expected.RightVector) > 0.9999).toBe(true)
        end
        left:Destroy()
        right:Destroy()
    end)

    it("keeps static outboard 3D landmarks registered to a moving arena", function()
        local root = Instance.new("Folder")
        local scenery = Instance.new("Folder")
        scenery.Name = "ArenaSilhouetteBreakupLocal"
        scenery.Parent = root
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(110, 3, 90)
        base.CFrame = CFrame.new(9, 14, 22)
        base.Parent = root

        for _, tier in ipairs({"Low", "Medium", "High"}) do
            for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
                local pieces = ArenaSilhouetteAccentKit.build(
                    scenery, base, variant, tier, VisualTheme.arena(variant)
                )
                local expectedCount = ArenaSilhouetteAccentKit.count(tier)
                expect(#pieces).toBe(expectedCount)
                local relativeFrames = {}
                for index, part in ipairs(pieces) do
                    relativeFrames[index] = base.CFrame:ToObjectSpace(part.CFrame)
                end
                local following = ArenaSilhouetteAccentKit.follow(scenery, base)
                expect(following ~= nil and following.Connected).toBe(true)
                base.CFrame = CFrame.new(41, 28, -19)
                    * CFrame.Angles(math.rad(4), math.rad(57), math.rad(-7))
                task.wait()
                expect(#scenery:GetChildren()).toBe(expectedCount)
                for index, part in ipairs(pieces) do
                    local expectedFrame = base.CFrame * relativeFrames[index]
                    expect((part.Position - expectedFrame.Position).Magnitude < 0.001)
                        .toBe(true)
                    expect(part.CFrame.LookVector:Dot(expectedFrame.LookVector) > 0.9999)
                        .toBe(true)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                end
                -- ShrinkingArena can reassign the same base CFrame during
                -- its size-only updates. The outboard pose must remain exact.
                local previousFrame = base.CFrame
                local previousPieceFrames = {}
                for index, part in ipairs(pieces) do
                    previousPieceFrames[index] = part.CFrame
                end
                base.Size = Vector3.new(78, 3, 63)
                base.CFrame = previousFrame
                task.wait()
                for index, part in ipairs(pieces) do
                    expect(part.CFrame).toBe(previousPieceFrames[index])
                end
                following:Disconnect()
                expect(following.Connected).toBe(false)
                local retained = pieces[1].CFrame
                base.CFrame = CFrame.new(-23, 20, 61)
                task.wait()
                expect(pieces[1].CFrame).toBe(retained)
                scenery:ClearAllChildren()
            end
        end
        expect(ArenaSilhouetteAccentKit.follow(scenery, base) == nil).toBe(true)
        expect(ArenaSilhouetteAccentKit.follow(nil, base) == nil).toBe(true)
        expect(ArenaSilhouetteAccentKit.follow(scenery, nil) == nil).toBe(true)
        base:Destroy()
        root:Destroy()
    end)

    it("ignores unexpected inputs without creating scenery", function()
        local folder = Instance.new("Folder")
        local base = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaSilhouetteAccentKit.build(nil, base, "Classic", "High", theme)).toBe(0)
        expect(#ArenaSilhouetteAccentKit.build(folder, nil, "Classic", "High", theme)).toBe(0)
        expect(#ArenaSilhouetteAccentKit.build(folder, base, "Unexpected", "High", theme)).toBe(0)
        expect(#ArenaSilhouetteAccentKit.build(folder, base, "Classic", "Unknown", theme)).toBe(0)
        expect(#ArenaSilhouetteAccentKit.build(folder, base, "Classic", "High", nil)).toBe(0)
        expect(#folder:GetChildren()).toBe(0)
        base:Destroy()
        folder:Destroy()
    end)
end)


describe("Arena premium deck material finishes", function()
    it("preserves four physically distinct floor recipes in rotated arenas", function()
        local folder = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(112, 3, 92)
        base.CFrame = CFrame.new(31, 18, -16)
            * CFrame.Angles(math.rad(9), math.rad(36), math.rad(-5))
        local observedNames = {}
        local firstMaterials = {}
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local names = ArenaDeckFinishKit.names(variant)
            expect(#names).toBe(6)
            expect(observedNames[names[1]] == nil).toBe(true)
            observedNames[names[1]] = true
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local generated = ArenaDeckFinishKit.build(
                    folder, base, variant, tier, VisualTheme.arena(variant))
                expect(#generated).toBe(ArenaDeckFinishKit.count(tier))
                for index, part in ipairs(generated) do
                    expect(part.Name).toBe(names[index])
                    expect(part:GetAttribute("ChaosDeckFinish")).toBe(true)
                    expect(part:GetAttribute("ArenaVariant")).toBe(variant)
                    expect(part:GetAttribute("SurfaceBaseColor")).toBe(part.Color)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part.Material == Enum.Material.Neon).toBe(false)
                    local localPosition = base.CFrame:PointToObjectSpace(part.Position)
                    expect(math.abs(localPosition.X) < base.Size.X * 0.5).toBe(true)
                    expect(math.abs(localPosition.Z) < base.Size.Z * 0.5).toBe(true)
                    expect(localPosition.Y > base.Size.Y * 0.5 + 0.13).toBe(true)
                    expect(part.CFrame.UpVector:Dot(base.CFrame.UpVector) > 0.98).toBe(true)
                    if index == 1 then
                        firstMaterials[variant] = part.Material
                    end
                    part:Destroy()
                end
            end
        end
        expect(firstMaterials.Classic).toBe(Enum.Material.Metal)
        expect(firstMaterials.Towers).toBe(Enum.Material.CorrodedMetal)
        expect(firstMaterials.Crossroads).toBe(Enum.Material.Concrete)
        expect(firstMaterials.Orbital).toBe(Enum.Material.Metal)
        expect(ArenaDeckFinishKit.count("Low")).toBe(2)
        expect(ArenaDeckFinishKit.count("Medium")).toBe(4)
        expect(ArenaDeckFinishKit.count("High")).toBe(6)
        expect(#folder:GetChildren()).toBe(0)
        base:Destroy()
        folder:Destroy()
    end)

    it("rejects invalid deck inputs before allocating geometry", function()
        local folder = Instance.new("Folder")
        local base = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaDeckFinishKit.build(nil, base, "Classic", "High", theme)).toBe(0)
        expect(#ArenaDeckFinishKit.build(folder, nil, "Classic", "High", theme)).toBe(0)
        expect(#ArenaDeckFinishKit.build(folder, base, "Unknown", "High", theme)).toBe(0)
        expect(#ArenaDeckFinishKit.build(folder, base, "Classic", "Unknown", theme)).toBe(0)
        expect(#ArenaDeckFinishKit.build(folder, base, "Classic", "High", nil)).toBe(0)
        expect(#folder:GetChildren()).toBe(0)
        base:Destroy()
        folder:Destroy()
    end)
end)


describe("Rotated cinematic arena scenery frames", function()
    it("keeps the environment and moving craft aligned to a tilted map", function()
        local base = Instance.new("Part")
        base.CFrame = CFrame.new(37, 14, -22)
            * CFrame.Angles(math.rad(11), math.rad(36), math.rad(-6))
        local offset = Vector3.new(67, 25, -88)
        local position = ArenaSceneryFrames.point(base, offset)
        local frame = ArenaSceneryFrames.frame(base, offset, math.rad(31))
        local localPoint = base.CFrame:PointToObjectSpace(position)
        expect((localPoint - offset).Magnitude < 0.0001).toBe(true)
        expect((frame.Position - position).Magnitude < 0.0001).toBe(true)
        expect(frame.UpVector:Dot(base.CFrame.UpVector) > 0.999).toBe(true)
        expect(frame.LookVector:Dot(base.CFrame.LookVector) < 0.99).toBe(true)
        base:Destroy()
    end)
end)


describe("Touch decor streamed-subtree readability", function()
    it("dims nested Neon and lights without compounding quality changes", function()
        local holder = Instance.new("Folder")
        local nested = Instance.new("Model")
        local glow = Instance.new("Part")
        glow.Name = "DecorativeNeon"
        glow.Material = Enum.Material.Neon
        glow.Parent = nested
        local edge = Instance.new("Part")
        edge.Name = "EdgeSafetyGlow"
        edge.Material = Enum.Material.Neon
        edge.Parent = nested
        local lamp = Instance.new("PointLight")
        lamp.Brightness = 5
        lamp.Parent = glow
        nested.Parent = holder
        local baselines = setmetatable({}, {__mode = "k"})

        -- A populated Model arrives as one streamed subtree.
        -- Mobile ornamental neon is deliberately dimmer than in v68,
        -- but edge lanes stay visible and light baselines never compound.
        MobileReadabilityKit.applyTree(nested, "Low", baselines)
        expect(math.abs(glow.LocalTransparencyModifier - 0.28) < 0.0001).toBe(true)
        -- Roblox stores this property as a float; 0.07 may round slightly upward.
        expect(math.abs(edge.LocalTransparencyModifier - 0.07) < 0.0001).toBe(true)
        expect(math.abs(lamp.Brightness - 2.9) < 0.0001).toBe(true)
        MobileReadabilityKit.applyTree(nested, "High", baselines)
        expect(math.abs(glow.LocalTransparencyModifier - 0.13) < 0.0001).toBe(true)
        expect(math.abs(lamp.Brightness - 3.7) < 0.0001).toBe(true)
        MobileReadabilityKit.applyTree(nested, "Low", baselines)
        expect(math.abs(lamp.Brightness - 2.9) < 0.0001).toBe(true)

        local streamed = Instance.new("Folder")
        local newLight = Instance.new("SpotLight")
        newLight.Brightness = 10
        newLight.Parent = streamed
        streamed.Parent = nested
        MobileReadabilityKit.applyTree(streamed, "Medium", baselines)
        expect(math.abs(newLight.Brightness - 6.6) < 0.0001).toBe(true)
        expect(baselines[lamp]).toBe(5)
        expect(baselines[newLight]).toBe(10)
        holder:Destroy()
    end)
    it("does not reveal LOD-hidden Neon on mobile tier changes", function()
        local holder = Instance.new("Folder")
        local glow = Instance.new("Part")
        glow.Name = "AmbientNeon"
        glow.Material = Enum.Material.Neon
        glow.LocalTransparencyModifier = 1
        glow:SetAttribute("SceneryLodHidden", true)
        glow.Parent = holder
        local edge = Instance.new("Part")
        edge.Name = "EdgeSafetyGlow"
        edge.Material = Enum.Material.Neon
        edge.LocalTransparencyModifier = 1
        edge:SetAttribute("SceneryLodHidden", true)
        edge.Parent = holder
        local lamp = Instance.new("PointLight")
        lamp.Brightness = 5
        lamp.Enabled = false
        lamp.Parent = glow
        local baselines = setmetatable({}, {__mode = "k"})

        MobileReadabilityKit.applyTree(holder, "Low", baselines)
        expect(glow.LocalTransparencyModifier).toBe(1)
        expect(edge.LocalTransparencyModifier).toBe(1)
        expect(lamp.Enabled).toBe(false)
        expect(math.abs(lamp.Brightness - 2.9) < 0.0001).toBe(true)

        MobileReadabilityKit.applyTree(holder, "High", baselines)
        expect(glow.LocalTransparencyModifier).toBe(1)
        expect(edge.LocalTransparencyModifier).toBe(1)
        expect(lamp.Enabled).toBe(false)

        -- The LOD owner has now restored visibility and its own baseline.
        glow:SetAttribute("SceneryLodHidden", false)
        edge:SetAttribute("SceneryLodHidden", false)
        glow.LocalTransparencyModifier = 0
        edge.LocalTransparencyModifier = 0
        MobileReadabilityKit.applyTree(holder, "Medium", baselines)
        expect(math.abs(glow.LocalTransparencyModifier - 0.21) < 0.0001).toBe(true)
        expect(math.abs(edge.LocalTransparencyModifier - 0.07) < 0.0001).toBe(true)
        expect(lamp.Enabled).toBe(false)
        expect(math.abs(lamp.Brightness - 3.3) < 0.0001).toBe(true)
        holder:Destroy()
    end)
    it("reapplies touch tint at LOD reveal and disconnects stale observers", function()
        local folder = Instance.new("Folder")
        local glow = Instance.new("Part")
        glow.Name = "DecorativeNeon"
        glow.Material = Enum.Material.Neon
        glow.Parent = folder
        local edge = Instance.new("Part")
        edge.Name = "EdgeSafetyGlow"
        edge.Material = Enum.Material.Neon
        edge.Parent = folder
        local baselines = setmetatable({}, {__mode = "k"})
        local callbacks = 0
        local function attach(part)
            return MobileReadabilityKit.watchLodReturn(part, function(revealed)
                callbacks += 1
                MobileReadabilityKit.applyInstance(revealed, "Medium", baselines)
            end)
        end
        local disconnectGlow = attach(glow)
        local disconnectEdge = attach(edge)

        -- LOD hides a part after recording its own baseline. Touch
        -- readability must never override that full invisibility.
        glow:SetAttribute("SceneryLodHidden", true)
        edge:SetAttribute("SceneryLodHidden", true)
        glow.LocalTransparencyModifier = 1
        edge.LocalTransparencyModifier = 1
        MobileReadabilityKit.applyTree(folder, "High", baselines)
        expect(glow.LocalTransparencyModifier).toBe(1)
        expect(edge.LocalTransparencyModifier).toBe(1)
        expect(callbacks).toBe(0)

        -- The LOD controller restores its modifier *before* revealing.
        glow.LocalTransparencyModifier = 0
        edge.LocalTransparencyModifier = 0
        glow:SetAttribute("SceneryLodHidden", false)
        edge:SetAttribute("SceneryLodHidden", false)
        expect(callbacks).toBe(2)
        expect(math.abs(glow.LocalTransparencyModifier - 0.21) < 0.0001)
            .toBe(true)
        expect(math.abs(edge.LocalTransparencyModifier - 0.07) < 0.0001)
            .toBe(true)
        glow:SetAttribute("SceneryLodHidden", true)
        glow.LocalTransparencyModifier = 1
        expect(callbacks).toBe(2)

        disconnectGlow:Disconnect()
        disconnectEdge:Disconnect()
        glow.LocalTransparencyModifier = 0
        glow:SetAttribute("SceneryLodHidden", false)
        expect(callbacks).toBe(2)
        expect(glow.LocalTransparencyModifier).toBe(0)
        folder:Destroy()
    end)
end)


describe("Android arena streaming decor watcher", function()
    it("keeps the canonical arena during overlapping streamed replacements", function()
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = workspace
        local original = Instance.new("Folder")
        original.Name = "Arena"
        original.Parent = generated
        local originalDecor = Instance.new("Folder")
        originalDecor.Name = "Decor"
        originalDecor.Parent = original
        local shown = nil
        local delivered = 0
        local disconnect = MobileReadabilityKit.watch(generated, function(decor)
            shown = decor
            delivered += 1
        end)
        expect(shown).toBe(originalDecor)

        -- A new arena is built while the live one is still canonical.
        -- Never swap to an unfinished incoming Decor or hide the old one.
        local replacement = Instance.new("Folder")
        replacement.Name = "Arena"
        replacement.Parent = generated
        local replacementDecor = Instance.new("Folder")
        replacementDecor.Name = "Decor"
        replacementDecor.Parent = replacement
        task.wait(0.06)
        expect(shown).toBe(originalDecor)

        -- Removing the canonical arena selects its already-constructed
        -- successor, without treating old Decor mutations as live.
        original.Parent = nil
        task.wait(0.06)
        expect(shown).toBe(replacementDecor)
        originalDecor.Parent = nil
        task.wait(0.06)
        expect(shown).toBe(replacementDecor)

        -- The disposer must stop both container and current-arena watches.
        local before = delivered
        disconnect()
        replacementDecor.Parent = nil
        replacement.Parent = nil
        task.wait(0.06)
        expect(delivered).toBe(before)
        expect(shown).toBe(replacementDecor)
        original:Destroy()
        replacement:Destroy()
        generated:Destroy()
    end)
end)

describe("Android arena identity ornament motion", function()
    it("eases in mechanical ornaments without stealing hazard cue priority", function()
        local rules = IdentityMotionRules
        for _, phase in ipairs({"ready", "round", "result"}) do
            expect(rules.phaseEnvelope(phase, 0)).toBe(0)
            expect(rules.phaseEnvelope(phase, -1)).toBe(0)
            expect(rules.phaseEnvelope(phase, "0.3")).toBe(0)
            expect(rules.phaseEnvelope(phase, 0 / 0)).toBe(0)
            local middle = rules.phaseEnvelope(phase, 0.17)
            local full = rules.phaseEnvelope(phase, 0.34)
            expect(middle > 0).toBe(true)
            expect(middle < full).toBe(true)
            expect(math.abs(middle - full * 0.5) < 0.0001).toBe(true)
            expect(rules.phaseEnvelope(phase, 1.5)).toBe(full)
        end
        expect(rules.phaseEnvelope("round", 2)).toBe(1)
        expect(rules.phaseEnvelope("ready", 2)).toBe(0.68)
        expect(rules.phaseEnvelope("result", 2)).toBe(0.46)
        -- Active-to-active transitions ease from their actual previous pose.
        expect(rules.phaseEnvelope("round", 0, 0.68)).toBe(0.68)
        expect(math.abs(rules.phaseEnvelope("round", 0.17, 0.68) - 0.84)
            < 0.0001).toBe(true)
        expect(rules.phaseEnvelope("round", 0.34, 0.68)).toBe(1)
        expect(rules.phaseEnvelope("result", 0, 1)).toBe(1)
        expect(math.abs(rules.phaseEnvelope("result", 0.17, 1) - 0.73)
            < 0.0001).toBe(true)
        expect(math.abs(rules.phaseEnvelope("result", 0.34, 1) - 0.46)
            < 0.0001).toBe(true)
        -- Early interruptions retain the previous fractional strength.
        expect(rules.phaseEnvelope("round", 0, 0.27)).toBe(0.27)
        expect(rules.phaseEnvelope("round", 0.34, 0.27)).toBe(1)
        expect(rules.phaseEnvelope("waiting", 0, 1)).toBe(0)
        for _, phase in ipairs({"waiting", "unknown", "vote", ""}) do
            expect(rules.phaseEnvelope(phase, 10)).toBe(0)
        end
        -- Reduced motion and tier budgets still gate the whole presentation.
        expect(rules.motionScale("High", true)
            * rules.phaseEnvelope("round", 1)).toBe(0)
        expect(rules.motionScale("Low", false)
            * rules.phaseEnvelope("round", 1)).toBe(0.38)
    end)

    it("eases Final Rush visual focus without altering accessibility gates", function()
        local rules = IdentityMotionRules
        expect(rules.focusTarget("round", true)).toBe(0.38)
        expect(rules.focusTarget("round", false)).toBe(1)
        expect(rules.focusTarget("ready", true)).toBe(1)
        expect(rules.focusTarget("result", true)).toBe(1)
        expect(rules.focusTarget("waiting", true)).toBe(1)
        expect(rules.focusTarget("round", nil)).toBe(1)

        expect(rules.focusEnvelope(1, 0.38, 0)).toBe(1)
        expect(math.abs(rules.focusEnvelope(1, 0.38, 0.225) - 0.69)
            < 0.0001).toBe(true)
        expect(rules.focusEnvelope(1, 0.38, 0.45)).toBe(0.38)
        expect(rules.focusEnvelope(1, 0.38, 1)).toBe(0.38)
        expect(rules.focusEnvelope(0.38, 1, 0)).toBe(0.38)
        expect(math.abs(rules.focusEnvelope(0.38, 1, 0.225) - 0.69)
            < 0.0001).toBe(true)
        expect(rules.focusEnvelope(0.38, 1, 0.45)).toBe(1)

        local mid = rules.focusEnvelope(1, 0.38, 0.225)
        expect(rules.focusEnvelope(mid, 1, 0)).toBe(mid)
        expect(rules.focusEnvelope(mid, 1, 0.45)).toBe(1)
        expect(rules.focusEnvelope(1, 0.38, -1)).toBe(1)
        expect(rules.focusEnvelope(1, 0.38, 0/0)).toBe(1)
        expect(rules.focusEnvelope(math.huge, 0.38, 0)).toBe(1)
        expect(rules.focusEnvelope(1, math.huge, 0.45)).toBe(1)

        local low = rules.motionScale("Low", false)
            * rules.phaseEnvelope("round", 1)
            * rules.focusEnvelope(1, rules.focusTarget("round", true), 1)
        expect(math.abs(low - 0.1444) < 0.0001).toBe(true)
        expect(rules.motionScale("High", true)
            * rules.focusEnvelope(1, 0.38, 1)).toBe(0)
    end)

    it("restores LOD-hidden identity decor and eases streamed motion from rest", function()
        local rules = IdentityMotionRules
        expect(rules.resumeEnvelope(0)).toBe(0)
        expect(rules.resumeEnvelope(-1)).toBe(0)
        expect(rules.resumeEnvelope("0.24")).toBe(0)
        expect(rules.resumeEnvelope(0/0)).toBe(0)
        expect(rules.resumeEnvelope(math.huge)).toBe(0)
        expect(rules.resumeEnvelope(-math.huge)).toBe(0)
        expect(math.abs(rules.resumeEnvelope(0.24) - 0.5) < 0.0001)
            .toBe(true)
        expect(rules.resumeEnvelope(0.48)).toBe(1)
        expect(rules.resumeEnvelope(2)).toBe(1)
        expect(math.abs(rules.motionScale("Low", false)
            * rules.resumeEnvelope(0.24) - 0.19) < 0.0001).toBe(true)
        expect(rules.motionScale("High", true)
            * rules.resumeEnvelope(2)).toBe(0)

        local holder = Instance.new("Folder")
        local part = Instance.new("Part")
        part.Parent = holder
        local baseline = {
            baseCFrame = CFrame.new(7, 9, -2)
                * CFrame.Angles(0, math.rad(30), 0),
            baseColor = Color3.fromRGB(42, 170, 235),
            baseTransparency = 0.31,
        }
        part.CFrame = baseline.baseCFrame * CFrame.new(0, 1.2, 0)
        part.Color = Color3.new(1, 1, 1)
        part.Transparency = 0.65
        part.LocalTransparencyModifier = 0.42
        part:SetAttribute("SceneryLodHidden", true)
        expect(rules.shouldUpdate(part)).toBe(false)
        expect(rules.restorePose(part, baseline)).toBe(true)
        expect((part.CFrame.Position - baseline.baseCFrame.Position).Magnitude
            < 0.0001).toBe(true)
        expect(part.CFrame.RightVector:Dot(baseline.baseCFrame.RightVector)
            > 0.99999).toBe(true)
        expect(part.Color).toBe(baseline.baseColor)
        expect(math.abs(part.Transparency - baseline.baseTransparency) < 1e-5)
            .toBe(true)
        -- Scenery LOD alone owns the local visibility modifier.
        expect(math.abs(part.LocalTransparencyModifier - 0.42) < 1e-5)
            .toBe(true)
        expect(part:GetAttribute("SceneryLodHidden")).toBe(true)

        part:SetAttribute("SceneryLodHidden", false)
        expect(rules.shouldUpdate(part)).toBe(true)
        expect(rules.restorePose(part, {})).toBe(false)
        part.Parent = nil
        expect(rules.restorePose(part, baseline)).toBe(false)
        part:Destroy()
        holder:Destroy()
    end)

    it("keeps authored tier scales and fully disables continuous ReduceMotion", function()
        expect(IdentityMotionRules.motionScale("Low", false)).toBe(0.38)
        expect(IdentityMotionRules.motionScale("Medium", false)).toBe(0.68)
        expect(IdentityMotionRules.motionScale("High", false)).toBe(1)
        expect(IdentityMotionRules.motionScale("Unknown", false)).toBe(0.38)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            expect(IdentityMotionRules.motionScale(tier, true)).toBe(0)
            expect(IdentityMotionRules.interval(tier, true, true, true)).toBe(0.60)
        end
    end)

    it("sleeps when inactive or no identity pieces have replicated", function()
        expect(IdentityMotionRules.interval("Low", false, true, true)).toBe(0.16)
        expect(IdentityMotionRules.interval("Medium", false, true, true)).toBe(0.09)
        expect(IdentityMotionRules.interval("High", false, true, true)).toBe(0.09)
        expect(IdentityMotionRules.interval("High", false, false, true)).toBe(0.60)
        expect(IdentityMotionRules.interval("High", false, true, false)).toBe(0.60)
    end)

    it("does not write to far-away or removed decor", function()
        local root = Instance.new("Folder")
        local part = Instance.new("Part")
        part.Parent = root
        expect(IdentityMotionRules.shouldUpdate(part)).toBe(true)
        part:SetAttribute("SceneryLodHidden", true)
        expect(IdentityMotionRules.shouldUpdate(part)).toBe(false)
        part:SetAttribute("SceneryLodHidden", false)
        expect(IdentityMotionRules.shouldUpdate(part)).toBe(true)
        part.Parent = nil
        expect(IdentityMotionRules.shouldUpdate(part)).toBe(false)
        expect(IdentityMotionRules.shouldUpdate(nil)).toBe(false)
        part:Destroy()
        root:Destroy()
    end)

    it("uses eight distinct bounded 3D micro-motions with stable original frames", function()
        local cases = {
            {"Classic", "GridMarkerGlow1"},
            {"Classic", "ClassicBroadcastGlow1"},
            {"Towers", "TowerBand1_1"},
            {"Towers", "TowerMachineryCap1"},
            {"Towers", "TowerAntenna1"},
            {"Crossroads", "CrossroadGate1"},
            {"Crossroads", "CrossroadSignal1"},
            {"Orbital", "OrbitalReactorNode1"},
        }
        local base = CFrame.new(19, 8, -7)
            * CFrame.Angles(math.rad(7), math.rad(45), math.rad(-5))
        for _, entry in ipairs(cases) do
            local variant, name = entry[1], entry[2]
            local high = IdentityMotionRules.ornamentOffset(
                variant, name, 1.37, 1, 1
            )
            local low = IdentityMotionRules.ornamentOffset(
                variant, name, 1.37, 1, 0.38
            )
            expect(high ~= nil).toBe(true)
            expect(low ~= nil).toBe(true)
            local function distanceFromRest(cf)
                return cf.Position.Magnitude
                    + (cf.RightVector - Vector3.new(1, 0, 0)).Magnitude
                    + (cf.UpVector - Vector3.new(0, 1, 0)).Magnitude
            end
            expect(distanceFromRest(high) > distanceFromRest(low)).toBe(true)
            expect(high.Position.Magnitude <= 0.181).toBe(true)
            expect(low.Position.Magnitude <= high.Position.Magnitude + 0.0001)
                .toBe(true)
            local localPose = base:ToObjectSpace(base * high)
            expect((localPose.Position - high.Position).Magnitude < 0.0001)
                .toBe(true)
            expect((localPose.UpVector - high.UpVector).Magnitude < 0.0001)
                .toBe(true)
            -- No accumulation: evaluating the same time always yields the
            -- same local transform, independent of the prior animation frame.
            local repeatPose = IdentityMotionRules.ornamentOffset(
                variant, name, 1.37, 1, 1)
            expect((repeatPose.Position - high.Position).Magnitude < 0.0001)
                .toBe(true)
            expect(repeatPose.RightVector:Dot(high.RightVector) > 0.99999)
                .toBe(true)
            -- A long but realistic session remains a valid finite pose.
            expect(IdentityMotionRules.ornamentOffset(
                variant, name, 4097.37, 1, 1) ~= nil).toBe(true)
        end
        expect(IdentityMotionRules.ornamentOffset(
            "Towers", "TowerBand1_1", 1, 1, 1) ~= nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Orbital", "OrbitalCrown1", 1, 1, 1) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "RoundMeteor", 1, 1, 1) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", 1, 1, 0) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", math.huge, 1, 1) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", 10000001, 1, 1) == nil).toBe(true)
        for _, bad in ipairs({math.huge, -math.huge, 0/0}) do
            expect(IdentityMotionRules.ornamentOffset(
                "Classic", "GridMarkerGlow1", 1, bad, 1) == nil).toBe(true)
            expect(IdentityMotionRules.ornamentOffset(
                "Classic", "GridMarkerGlow1", 1, 1, bad) == nil).toBe(true)
        end
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", 1, 65, 1) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", 1, 1.5, 1) == nil).toBe(true)
    end)

    it("watches only the named direct-decor ornaments in each arena", function()
        local valid = {
            Classic = {"GridMarkerGlow1", "ClassicBroadcastGlow4"},
            Towers = {"TowerBand4_3", "TowerMachineryCap2", "TowerAntenna1"},
            Crossroads = {"CrossroadGate3", "CrossroadSignal4"},
            Orbital = {"OrbitalCrown1", "OrbitalCrown12", "OrbitalReactorNode8"},
        }
        for variant, names in pairs(valid) do
            for _, name in ipairs(names) do
                expect(IdentityMotionRules.isIdentityPart(variant, name)).toBe(true)
            end
        end
        for _, invalid in ipairs({
            {"Classic", "GridMarkerGlow5"},
            {"Towers", "TowerBand5_1"},
            {"Towers", "TowerBand3_4"},
            {"Crossroads", "CrossroadSignal8"},
            {"Orbital", "OrbitalCrown13"},
            {"Orbital", "OrbitalReactorNode0"},
            {"Orbital", "RoundMeteor"},
            {"Unknown", "OrbitalCrown1"},
        }) do
            expect(IdentityMotionRules.isIdentityPart(invalid[1], invalid[2]))
                .toBe(false)
        end
        expect(IdentityMotionRules.isIdentityPart("Orbital", nil)).toBe(false)
    end)
    it("recovers late Arena/Decor, variant swaps and streamed identity parts", function()
        local generated = Instance.new("Folder")
        local count = 0
        local observedArena, observedDecor, observedVariant = nil, nil, nil
        local disconnect = IdentityMotionReadiness.watch(generated, function(arena, decor, variant)
            count += 1
            observedArena, observedDecor, observedVariant = arena, decor, variant
        end, IdentityMotionRules.isIdentityPart)
        expect(count).toBe(1)
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        expect(observedArena).toBe(arena)
        expect(observedDecor == nil).toBe(true)
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        expect(observedDecor).toBe(decor)
        expect(observedVariant).toBe("Classic")

        local beforeUnrelated = count
        local unrelated = Instance.new("Part")
        unrelated.Name = "RoundMeteor"
        unrelated.Parent = decor
        expect(count).toBe(beforeUnrelated)
        local identity = Instance.new("Part")
        identity.Name = "GridMarkerGlow1"
        identity.Parent = decor
        expect(count).toBe(beforeUnrelated + 1)
        identity.Parent = nil
        expect(count).toBe(beforeUnrelated + 2)

        arena:SetAttribute("VariantId", "Orbital")
        expect(observedVariant).toBe("Orbital")
        local crown = Instance.new("Part")
        crown.Name = "OrbitalCrown12"
        crown.Parent = decor
        local afterCrown = count
        expect(afterCrown > beforeUnrelated + 2).toBe(true)

        decor.Parent = nil
        expect(observedDecor == nil).toBe(true)
        local afterDetach = count
        local stale = Instance.new("Part")
        stale.Name = "OrbitalReactorNode1"
        stale.Parent = decor
        expect(count).toBe(afterDetach)

        local freshDecor = Instance.new("Folder")
        freshDecor.Name = "Decor"
        freshDecor.Parent = arena
        expect(observedDecor).toBe(freshDecor)
        local freshNode = Instance.new("Part")
        freshNode.Name = "OrbitalReactorNode8"
        freshNode.Parent = freshDecor
        expect(count > afterDetach + 1).toBe(true)

        arena.Parent = nil
        expect(observedArena == nil).toBe(true)
        local afterArenaGone = count
        local orphan = Instance.new("Part")
        orphan.Name = "OrbitalCrown1"
        orphan.Parent = freshDecor
        expect(count).toBe(afterArenaGone)

        local replacement = Instance.new("Folder")
        replacement.Name = "Arena"
        replacement:SetAttribute("VariantId", "Towers")
        replacement.Parent = generated
        expect(observedArena).toBe(replacement)
        expect(observedVariant).toBe("Towers")
        disconnect()
        local afterDisconnect = count
        local replacementDecor = Instance.new("Folder")
        replacementDecor.Name = "Decor"
        replacementDecor.Parent = replacement
        expect(count).toBe(afterDisconnect)
        generated:Destroy()
        arena:Destroy()
        decor:Destroy()
        identity:Destroy()
    end)

end)

return nil
