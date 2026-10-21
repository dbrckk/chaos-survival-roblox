--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local SurvivalFeedback = require("../../src/server/SurvivalFeedback")
local CharacterReactionRules = require("../../src/shared/CharacterReactionRules")
local CharacterReactionVisuals = require("../../src/client/CharacterReactionVisuals")
local CharacterReactionRigRegistry = require("../../src/client/CharacterReactionRigRegistry")

describe("Survival feedback", function()
    it("marks living players at or below twenty percent health as critical", function()
        expect(SurvivalFeedback.isCriticalHealth(20, 100)).toBe(true)
        expect(SurvivalFeedback.isCriticalHealth(1, 100)).toBe(true)
        expect(SurvivalFeedback.isCriticalHealth(20.1, 100)).toBe(false)
    end)

    it("restores health only for living humans between rounds, matching AI starts", function()
        local humanoid = Instance.new("Humanoid")
        humanoid.MaxHealth = 135
        humanoid.Health = 17
        expect(SurvivalFeedback.isCriticalHealth(
            humanoid.Health, humanoid.MaxHealth
        )).toBe(true)
        expect(SurvivalFeedback.restoreForNextRound(humanoid)).toBe(true)
        expect(humanoid.Health).toBe(135)
        expect(SurvivalFeedback.isCriticalHealth(
            humanoid.Health, humanoid.MaxHealth
        )).toBe(false)

        -- Dead rigs must respawn normally rather than get resurrected at
        -- the arena teleport. Invalid inputs cannot crash the round loop.
        humanoid.Health = 0
        expect(SurvivalFeedback.restoreForNextRound(humanoid)).toBe(false)
        expect(humanoid.Health).toBe(0)
        expect(SurvivalFeedback.restoreForNextRound(nil)).toBe(false)
        expect(SurvivalFeedback.restoreForNextRound("player")).toBe(false)
        local part = Instance.new("Part")
        expect(SurvivalFeedback.restoreForNextRound(part)).toBe(false)
        part:Destroy()
        humanoid:Destroy()
    end)

    it("does not mark invalid or dead health states as critical", function()
        expect(SurvivalFeedback.isCriticalHealth(0, 100)).toBe(false)
        expect(SurvivalFeedback.isCriticalHealth(10, 0)).toBe(false)
        expect(SurvivalFeedback.isCriticalHealth(-5, 100)).toBe(false)
    end)
end)

describe("Character cinematic reactions", function()
    it("makes spectator-safe reaction budget progressively more expressive", function()
        local low = CharacterReactionRules.profile("Low", false)
        local medium = CharacterReactionRules.profile("Medium", false)
        local high = CharacterReactionRules.profile("High", false)
        expect(low.Dodge).toBe(0)
        expect(low.Shock).toBe(0)
        expect(low.Landing).toBe(0)
        expect(medium.Dodge < high.Dodge).toBe(true)
        expect(medium.Shock <= high.Shock).toBe(true)
        expect(medium.Landing <= high.Landing).toBe(true)
        expect(high.MaxReactors <= 3).toBe(true)
        expect(CharacterReactionRules.profile("High", true).Dodge).toBe(0)
        expect(CharacterReactionRules.profile("High", true).Shock).toBe(0)
        expect(CharacterReactionRules.profile("High", true).Landing).toBe(0)
        expect(CharacterReactionRules.profile("Unknown", false).Dodge).toBe(0)
    end)

    it("activates only for living round participants", function()
        expect(CharacterReactionRules.isActive("round", 100)).toBe(true)
        expect(CharacterReactionRules.isActive("round", 0)).toBe(false)
        expect(CharacterReactionRules.isActive("waiting", 100)).toBe(false)
        expect(CharacterReactionRules.isActive("result", 100)).toBe(false)
    end)

    it("derives bounded danger and landing intensities", function()
        local r = CharacterReactionRules
        expect(r.dodgeStrength(nil, 10)).toBe(0)
        expect(r.dodgeStrength(2, 0)).toBe(0)
        expect(r.dodgeStrength(0, 10)).toBe(1)
        expect(r.dodgeStrength(15, 10) >= 0.25).toBe(true)
        expect(r.airShockStrength(0, 12)).toBe(0)
        expect(r.airShockStrength(12, 12) > 0).toBe(true)
        expect(r.airShockStrength(40, 12)).toBe(0)
        expect(r.airShockStrength(13, 12) <= 1).toBe(true)
        expect(r.landingStrength(0.4)).toBe(0)
        expect(r.landingStrength(0.8) > 0).toBe(true)
        expect(r.landingStrength(10)).toBe(1)
    end)

    it("keeps malformed hazard inputs from producing reaction intensities", function()
        local r = CharacterReactionRules
        local valid = Vector3.new(12, 8, -4)
        expect(r.validPosition(valid)).toBe(true)
        expect(r.validPosition(nil)).toBe(false)
        expect(r.validPosition("8, 4, 2")).toBe(false)
        for _, bad in ipairs({0/0, math.huge, -math.huge}) do
            expect(r.dodgeStrength(bad, 10)).toBe(0)
            expect(r.dodgeStrength(3, bad)).toBe(0)
            expect(r.airShockStrength(bad, 10)).toBe(0)
            expect(r.airShockStrength(12, bad)).toBe(0)
            expect(r.landingStrength(bad)).toBe(0)
            expect(r.cooldownReady(bad, nil, 0.5)).toBe(false)
            expect(r.validPosition(Vector3.new(bad, 4, -7))).toBe(false)
        end
        expect(r.validPosition(Vector3.new(1e8, 0, 0))).toBe(false)
        -- Existing finite strength, cooldown and default radius rules remain.
        expect(r.dodgeStrength(0, 10)).toBe(1)
        expect(r.airShockStrength(12, nil) >= 0).toBe(true)
        expect(r.airShockStrength(12, 12) > 0).toBe(true)
        expect(r.landingStrength(1) > 0).toBe(true)
        expect(r.cooldownReady(10, -math.huge, 0.8)).toBe(true)
        expect(r.cooldownReady(10.1, 10, 0.8)).toBe(false)
        expect(r.cooldownReady(10.9, 10, 0.8)).toBe(true)
    end)

    it("builds real curved beams without any extra physical character parts", function()
        local model = Instance.new("Model")
        model.Name = "ReactiveTestAvatar"
        model.Parent = workspace
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        local active = {}
        local visual = CharacterReactionVisuals
        expect(visual.burst(root, "Dodge", "Meteor", 2, 0.9, active)).toBe(2)
        expect(visual.burst(root, "Shock", "Bomb", 1, 0.6, active)).toBe(1)
        expect(visual.burst(root, "Landing", "", 2, 0.8, active)).toBe(2)
        local beamCount = 0
        local attachmentCount = 0
        local partCount = 0
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("Beam") then
                beamCount += 1
                expect(child.Attachment0 ~= nil and child.Attachment1 ~= nil).toBe(true)
                expect(child.Segments >= 4).toBe(true)
                expect(child.Width0 > 0 and child.Width0 < 0.20).toBe(true)
            elseif child:IsA("Attachment") then
                attachmentCount += 1
            elseif child:IsA("BasePart") then
                partCount += 1
            end
        end
        expect(beamCount).toBe(5)
        expect(attachmentCount).toBe(10)
        expect(partCount).toBe(0)
        expect(visual.burst(root, "Dodge", "Meteor", 50, 1, active)).toBe(3)
        expect(visual.activeBeams(active)).toBe(8)
        expect(visual.burst(root, "Shock", "Bomb", 3, 1, active)).toBe(3)
        expect(visual.burst(root, "Shock", "Bomb", 3, 1, active)).toBe(1)
        expect(visual.activeBeams(active)).toBe(12)
        expect(visual.burst(root, "Dodge", "Meteor", 3, 1, active)).toBe(0)
        expect(visual.burst(nil, "Dodge", "Meteor", 1, 1, active)).toBe(0)
        model:Destroy()
    end)

    it("rejects invalid reaction numbers without allocating Beam or Attachment", function()
        local model = Instance.new("Model")
        model.Parent = workspace
        local root = Instance.new("Part")
        root.Parent = model
        local active = {}
        local visual = CharacterReactionVisuals
        for _, invalid in ipairs({math.huge, -math.huge, 0/0}) do
            expect(visual.signature("Dodge", "Meteor", invalid, 0.8) == nil)
                .toBe(true)
            expect(visual.signature("Shock", "Bomb", 1, invalid) == nil)
                .toBe(true)
            expect(visual.burst(root, "Dodge", "Meteor", invalid, 0.8, active))
                .toBe(0)
            expect(visual.burst(root, "Shock", "Bomb", 2, invalid, active))
                .toBe(0)
        end
        for _, index in ipairs({0, -1, 4, 1.5, 1e8}) do
            expect(visual.signature("Landing", "", index, 1) == nil)
                .toBe(true)
        end
        expect(visual.burst(root, "Landing", "", nil, 0.8, active)).toBe(0)
        expect(visual.burst(root, "Landing", "", 2, nil, active)).toBe(0)
        expect(visual.activeBeams(active)).toBe(0)
        expect(#root:GetChildren()).toBe(0)
        -- Existing finite 0..1 intensity and capped count still work.
        expect(visual.burst(root, "Dodge", "Meteor", 50, 0.9, active))
            .toBe(3)
        expect(visual.activeBeams(active)).toBe(3)
        model:Destroy()
    end)

    it("falls back from invalid explosion vectors without malformed CFrames", function()
        local root = CFrame.new(8, 2, -5)
        for _, source in ipairs({
            Vector3.new(0/0, 1, 0),
            Vector3.new(math.huge, 0, 0),
            Vector3.new(0, -math.huge, 0),
        }) do
            local offset, directed = CharacterReactionVisuals.shockOrientation(
                root, source)
            expect(directed).toBe(false)
            expect((offset.Position - Vector3.zero).Magnitude < 0.0001)
                .toBe(true)
        end
    end)

    it("uses different physical silhouettes for meteor ejections and bomb pressure", function()
        local visual = CharacterReactionVisuals
        local meteor = visual.signature("Shock", "Meteor", 1, 0.8)
        local bomb = visual.signature("Shock", "Bomb", 1, 0.8)
        local dodge = visual.signature("Dodge", "Meteor", 2, 0.8)
        local landing = visual.signature("Landing", "", 1, 0.8)
        expect(meteor ~= nil and bomb ~= nil and dodge ~= nil and landing ~= nil).toBe(true)
        expect(meteor.Finish.Y - meteor.Start.Y > 1.0).toBe(true)
        expect(bomb.Finish.Y - bomb.Start.Y < 0.25).toBe(true)
        expect(math.abs(bomb.Finish.X) > math.abs(meteor.Finish.X)).toBe(true)
        expect(meteor.Curve1 ~= bomb.Curve1).toBe(true)
        expect(meteor.Color ~= bomb.Color).toBe(true)
        expect(landing.Finish.Y < landing.Start.Y).toBe(true)
        expect(landing.Emission < meteor.Emission).toBe(true)
        expect(dodge.Lifetime > bomb.Lifetime).toBe(true)
        for _, design in ipairs({meteor, bomb, dodge, landing}) do
            expect(design.Lifetime > 0 and design.Lifetime < 0.5).toBe(true)
            expect(design.Width > 0 and design.Width < 0.2).toBe(true)
            expect(design.Segments >= 6 and design.Segments <= 8).toBe(true)
        end
        expect(visual.signature("Unknown", "Bomb", 1, 1) == nil).toBe(true)
    end)

    it("orients explosion ribbons away from impacts even for a rotated avatar", function()
        local model = Instance.new("Model")
        model.Parent = workspace
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.CFrame = CFrame.new(20, 10, -12)
            * CFrame.Angles(0, math.rad(63), 0)
        root.Parent = model
        local source = root.Position + Vector3.new(-12, 0, 6)
        local turn, directed = CharacterReactionVisuals.shockOrientation(
            root.CFrame, source
        )
        expect(directed).toBe(true)
        local away = Vector3.new(12, 0, -6).Unit
        local worldForward = root.CFrame:VectorToWorldSpace(turn.LookVector)
        expect(worldForward:Dot(away) > 0.999).toBe(true)
        expect(select(2, CharacterReactionVisuals.shockOrientation(
            root.CFrame, root.Position
        ))).toBe(false)
        expect(select(2, CharacterReactionVisuals.shockOrientation(
            root.CFrame, nil
        ))).toBe(false)

        local active = {}
        expect(CharacterReactionVisuals.burst(root, "Shock", "Bomb", 2,
            0.8, active, source)).toBe(2)
        local displacement = Vector3.zero
        local beams = 0
        for _, item in ipairs(root:GetChildren()) do
            if item:IsA("Beam") then
                expect(item:GetAttribute("ChaosReactionDirectional")).toBe(true)
                expect(item:GetAttribute("ChaosReactionKind")).toBe("Bomb")
                local a = item.Attachment0.Position
                local b = item.Attachment1.Position
                displacement += root.CFrame:VectorToWorldSpace(b - a)
                beams += 1
            end
        end
        expect(beams).toBe(2)
        expect(displacement.Unit:Dot(away) > 0.80).toBe(true)
        model:Destroy()
    end)

    it("gives meteor dodges an upward streak and bomb dodges a low swept profile", function()
        local meteor = CharacterReactionVisuals.signature("Dodge", "Meteor", 1, 0.9)
        local bomb = CharacterReactionVisuals.signature("Dodge", "Bomb", 1, 0.9)
        local general = CharacterReactionVisuals.signature("Dodge", "Unknown", 1, 0.9)
        expect(meteor.Finish.Y > bomb.Finish.Y + 1).toBe(true)
        expect(math.abs(bomb.Finish.X) > math.abs(meteor.Finish.X)).toBe(true)
        expect(bomb.Curve0 ~= meteor.Curve0).toBe(true)
        expect(general ~= nil).toBe(true)
        expect(meteor.Lifetime).toBe(bomb.Lifetime)
        for _, item in ipairs({meteor, bomb, general}) do
            expect(item.Width < 0.20).toBe(true)
            expect(item.Lifetime < 0.50).toBe(true)
            expect(item.Segments <= 8).toBe(true)
        end
    end)

    it("marks reaction beams for in-Studio visual and audio synchronization audits", function()
        local model = Instance.new("Model")
        model.Parent = workspace
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        local active = {}
        expect(CharacterReactionVisuals.burst(root, "Shock", "Meteor", 1,
            0.7, active)).toBe(1)
        for _, item in ipairs(root:GetChildren()) do
            if item:IsA("Beam") then
                expect(item:GetAttribute("ChaosReactionMode")).toBe("Shock")
                expect(item:GetAttribute("ChaosReactionKind")).toBe("Meteor")
                expect(item.FaceCamera).toBe(true)
                expect(item:IsA("BasePart")).toBe(false)
            end
        end
        expect(CharacterReactionVisuals.burst(root, "Wrong", "Meteor", 1,
            0.7, active)).toBe(0)
        model:Destroy()
    end)

    it("excludes lobby late-joiners and eliminated players from cinematic reactions", function()
        expect(CharacterReactionRules.humanEligible(true, false)).toBe(true)
        expect(CharacterReactionRules.humanEligible(true, nil)).toBe(true)
        expect(CharacterReactionRules.humanEligible(false, false)).toBe(false)
        expect(CharacterReactionRules.humanEligible(nil, nil)).toBe(false)
        expect(CharacterReactionRules.humanEligible(true, true)).toBe(false)
    end)

    it("binds cinematic landing reactions after pre-workspace CharacterAdded", function()
        local calls = 0
        local registry = CharacterReactionRigRegistry.new(function()
            calls += 1
        end)
        local rig = Instance.new("Model")
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = rig
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = rig
        expect(registry.watch(rig)).toBe(true)
        expect(registry.watch(rig)).toBe(false)
        expect(registry.count()).toBe(1)
        expect(registry.rig(rig) == nil).toBe(true)

        rig.Parent = workspace
        task.wait()
        local activeRoot, activeHumanoid = registry.rig(rig)
        expect(activeRoot).toBe(root)
        expect(activeHumanoid).toBe(humanoid)
        registry.clearAirborne()
        expect(registry.rig(rig)).toBe(root)

        rig.Parent = nil
        task.wait()
        expect(registry.count()).toBe(0)
        expect(registry.rig(rig) == nil).toBe(true)
        rig.Parent = workspace
        task.wait()
        expect(registry.rig(rig) == nil).toBe(true)
        expect(registry.watch(rig)).toBe(true)
        expect(registry.rig(rig)).toBe(root)
        registry.stop(rig)
        expect(registry.count()).toBe(0)
        expect(calls).toBe(0) -- no fabricated Humanoid StateChanged
        rig:Destroy()
    end)

    it("does not follow models temporarily parented outside workspace", function()
        local registry = CharacterReactionRigRegistry.new(function() end)
        local holder = Instance.new("Folder")
        local rig = Instance.new("Model")
        rig.Parent = holder
        expect(registry.watch(rig)).toBe(false)
        expect(registry.count()).toBe(0)
        holder:Destroy()
    end)

    it("rebinds streamed character roots and drops old Humanoid events", function()
        local calls = 0
        local lastRoot = nil
        local registry = CharacterReactionRigRegistry.new(function(model, root)
            calls += 1
            lastRoot = root
        end)
        local model = Instance.new("Model")
        model.Name = "DelayedCinematicSurvivor"
        model.Parent = workspace
        expect(registry.watch(model)).toBe(true)
        expect(registry.watch(model)).toBe(false)
        expect(registry.count()).toBe(1)
        expect(registry.rig(model) == nil).toBe(true)
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = model
        expect(registry.rig(model) == nil).toBe(true)
        local firstRoot = Instance.new("Part")
        firstRoot.Name = "HumanoidRootPart"
        firstRoot.Parent = model
        local bound, boundHumanoid = registry.rig(model)
        expect(bound).toBe(firstRoot)
        expect(boundHumanoid).toBe(humanoid)
        -- Streaming one component out unbinds the old state listener.
        firstRoot.Parent = nil
        expect(registry.rig(model) == nil).toBe(true)
        local secondRoot = Instance.new("Part")
        secondRoot.Name = "HumanoidRootPart"
        secondRoot.Parent = model
        expect(registry.rig(model)).toBe(secondRoot)
        expect(registry.count()).toBe(1)
        -- A Humanoid swap similarly invalidates old airborne history.
        humanoid.Parent = nil
        expect(registry.rig(model) == nil).toBe(true)
        local replacement = Instance.new("Humanoid")
        replacement.Parent = model
        local currentRoot, currentHumanoid = registry.rig(model)
        expect(currentRoot).toBe(secondRoot)
        expect(currentHumanoid).toBe(replacement)
        -- Late replication isn't discarded after an arbitrary 8s TTL;
        -- the model itself owns the listener until it is detached.
        registry.clearAirborne()
        expect(registry.rig(model)).toBe(secondRoot)
        registry.stop(model)
        expect(registry.count()).toBe(0)
        expect(registry.rig(model) == nil).toBe(true)
        expect(registry.watch(model)).toBe(true)
        model.Parent = nil
        expect(registry.count()).toBe(0)
        model.Parent = workspace
        expect(registry.watch(model)).toBe(true)
        model:Destroy()
        expect(registry.count()).toBe(0)
        expect(calls).toBe(0)
        expect(lastRoot == nil).toBe(true)
        firstRoot:Destroy()
        humanoid:Destroy()
    end)

    it("releases partial rigs and safely re-registers late Humanoids", function()
        local registry = CharacterReactionRigRegistry.new(function() end)
        local model = Instance.new("Model")
        model.Parent = workspace
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Parent = model
        expect(registry.watch(model)).toBe(true)
        expect(registry.rig(model) == nil).toBe(true)
        registry.stop(model)
        expect(registry.count()).toBe(0)
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = model
        expect(registry.rig(model) == nil).toBe(true)
        expect(registry.watch(model)).toBe(true)
        local bound, boundHumanoid = registry.rig(model)
        expect(bound).toBe(root)
        expect(boundHumanoid).toBe(humanoid)
        model:Destroy()
        expect(registry.count()).toBe(0)
    end)

    it("recognizes direct land-to-run transitions while clearing airborne time", function()
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.Landed)).toBe(true)
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.Running)).toBe(true)
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.RunningNoPhysics)).toBe(true)
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.Freefall)).toBe(false)
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.Jumping)).toBe(false)
    end)

    it("only commits character VFX cooldowns after visible Beam emission", function()
        local rules = CharacterReactionRules
        local previous = 10
        expect(rules.cooldownAfterEmission(previous, 11, 0)).toBe(previous)
        expect(rules.cooldownAfterEmission(previous, 11, -1)).toBe(previous)
        expect(rules.cooldownAfterEmission(previous, 11, 0/0)).toBe(previous)
        expect(rules.cooldownAfterEmission(previous, 11, math.huge))
            .toBe(previous)
        expect(rules.cooldownAfterEmission(previous, 11, 1.5))
            .toBe(previous)
        expect(rules.cooldownAfterEmission(previous, 0/0, 1))
            .toBe(previous)
        expect(rules.cooldownAfterEmission(previous, math.huge, 1))
            .toBe(previous)
        expect(rules.cooldownAfterEmission(previous, 11, 1)).toBe(11)
        expect(rules.cooldownAfterEmission(previous, 11, 3)).toBe(11)
        expect(rules.cooldownReady(11.1, previous, 0.8)).toBe(true)
        local committed = rules.cooldownAfterEmission(previous, 11, 2)
        expect(rules.cooldownReady(11.1, committed, 0.8)).toBe(false)
        expect(rules.cooldownReady(11.9, committed, 0.8)).toBe(true)
        expect(rules.cooldownAfterEmission(nil, 11, 0) == nil).toBe(true)
        expect(rules.cooldownAfterEmission(nil, 11, 1)).toBe(11)
    end)

    it("throttles rapid duplicate events without permanent locks", function()
        local r = CharacterReactionRules
        expect(r.cooldownReady(10, nil, 1)).toBe(true)
        expect(r.cooldownReady(10.5, 10, 1)).toBe(false)
        expect(r.cooldownReady(11.1, 10, 1)).toBe(true)
        expect(r.cooldownReady(nil, 10, 1)).toBe(false)
    end)
end)

return nil
