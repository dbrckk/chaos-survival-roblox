--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local SurvivalFeedback = require("../../src/server/SurvivalFeedback")
local CharacterReactionRules = require("../../src/shared/CharacterReactionRules")
local CharacterReactionVisuals = require("../../src/client/CharacterReactionVisuals")

describe("Survival feedback", function()
    it("marks living players at or below twenty percent health as critical", function()
        expect(SurvivalFeedback.isCriticalHealth(20, 100)).toBe(true)
        expect(SurvivalFeedback.isCriticalHealth(1, 100)).toBe(true)
        expect(SurvivalFeedback.isCriticalHealth(20.1, 100)).toBe(false)
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

    it("excludes lobby late-joiners and eliminated players from cinematic reactions", function()
        expect(CharacterReactionRules.humanEligible(true, false)).toBe(true)
        expect(CharacterReactionRules.humanEligible(true, nil)).toBe(true)
        expect(CharacterReactionRules.humanEligible(false, false)).toBe(false)
        expect(CharacterReactionRules.humanEligible(nil, nil)).toBe(false)
        expect(CharacterReactionRules.humanEligible(true, true)).toBe(false)
    end)

    it("recognizes direct land-to-run transitions while clearing airborne time", function()
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.Landed)).toBe(true)
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.Running)).toBe(true)
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.RunningNoPhysics)).toBe(true)
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.Freefall)).toBe(false)
        expect(CharacterReactionRules.isLandingTransition(Enum.HumanoidStateType.Jumping)).toBe(false)
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
