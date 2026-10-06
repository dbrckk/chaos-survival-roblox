--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterImpact = require("../../src/server/DisasterImpact")

describe("Disaster impact", function()
    it("deals maximum damage at the impact center", function()
        expect(DisasterImpact.damageForDistance(0, 8, 50)).toBe(50)
    end)

    it("falls off toward the edge without becoming zero inside the radius", function()
        local middle = DisasterImpact.damageForDistance(4, 8, 50)
        local edge = DisasterImpact.damageForDistance(8, 8, 50)

        expect(middle < 50).toBe(true)
        expect(middle > edge).toBe(true)
        expect(edge).toBe(18)
    end)

    it("deals no damage outside the configured radius", function()
        expect(DisasterImpact.damageForDistance(8.01, 8, 50)).toBe(0)
        expect(DisasterImpact.damageForDistance(100, 8, 50)).toBe(0)
    end)

    it("detects only close misses just outside the damage radius", function()
        expect(DisasterImpact.nearMissForDistance(8.1, 8, 3.5)).toBe(true)
        expect(DisasterImpact.nearMissForDistance(11.5, 8, 3.5)).toBe(true)
        expect(DisasterImpact.nearMissForDistance(8, 8, 3.5)).toBe(false)
        expect(DisasterImpact.nearMissForDistance(11.6, 8, 3.5)).toBe(false)
    end)

    it("applies radial damage to active AI survivor proxies", function()
        local function fakeProxy(name, position)
            local character = Instance.new("Model")
            character.Name = name .. "Character"

            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Position = position
            root.Anchored = true
            root.Parent = character

            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.Parent = character
            character.Parent = workspace

            return {
                UserId = -1,
                Name = name,
                IsAISurvivor = true,
                Character = character,
            }, character, humanoid
        end

        local activeBot, activeCharacter, activeHumanoid = fakeProxy(
            "ActiveBot",
            Vector3.new(0, 3, 0)
        )
        local inactiveBot, inactiveCharacter, inactiveHumanoid = fakeProxy(
            "InactiveBot",
            Vector3.new(0, 3, 0)
        )

        local reportedKind = nil
        local reportedDamage = 0
        local hits = DisasterImpact.applyRadialDamage({
            HazardContestants = {activeBot, inactiveBot},
            IsContestantActive = function(subject)
                return subject == activeBot
            end,
            OnHazardDamage = function(subject, kind, damage)
                if subject == activeBot then
                    reportedKind = kind
                    reportedDamage = damage
                end
            end,
        }, Vector3.new(0, 3, 0), 8, 50, "Meteor")

        expect(hits).toBe(1)
        expect(activeHumanoid.Health).toBe(50)
        expect(inactiveHumanoid.Health).toBe(100)
        expect(reportedKind).toBe("Meteor")
        expect(reportedDamage).toBe(50)

        activeCharacter:Destroy()
        inactiveCharacter:Destroy()
    end)

    it("records a fatal hazard cause before applying lethal damage", function()
        local character = Instance.new("Model")
        character.Name = "FatalImpactCharacter"

        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Position = Vector3.new(0, 3, 0)
        root.Anchored = true
        root.Parent = character

        local humanoid = Instance.new("Humanoid")
        humanoid.MaxHealth = 20
        humanoid.Health = 20
        humanoid.Parent = character
        character.Parent = workspace

        local subject = {
            UserId = 123,
            Name = "FatalImpactSubject",
            Character = character,
        }

        local healthWhenCauseRecorded = nil
        local reportedKind = nil

        local hits = DisasterImpact.applyRadialDamage({
            HazardContestants = {subject},
            IsContestantActive = function()
                return true
            end,
            OnHazardDamage = function(_, kind)
                reportedKind = kind
                healthWhenCauseRecorded = humanoid.Health
            end,
        }, Vector3.new(0, 3, 0), 8, 50, "Meteor")

        expect(hits).toBe(1)
        expect(reportedKind).toBe("Meteor")
        expect(healthWhenCauseRecorded).toBe(20)
        expect(humanoid.Health).toBe(0)

        character:Destroy()
    end)

    it("sanitizes negative distance and damage inputs", function()
        expect(DisasterImpact.damageForDistance(-5, 8, 50)).toBe(50)
        expect(DisasterImpact.damageForDistance(0, 8, -10)).toBe(0)
    end)
end)

return nil
