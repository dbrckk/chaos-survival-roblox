--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local IdentityMotionRules = require("../../src/shared/ArenaIdentityMotionRules")
local IdentityMotionReadiness = require("../../src/shared/ArenaIdentityMotionReadiness")

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
        local part = Instance.new("MeshPart")
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
        local crown = Instance.new("MeshPart")
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
