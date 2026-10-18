--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterImpact = require("../../src/server/DisasterImpact")
local HazardImpactAudience = require("../../src/shared/HazardImpactAudience")
local RisingLava = require("../../src/server/Disasters/RisingLava")

describe("Disaster impact", function()
    it("routes nearby impacts to active players and visible events to spectators", function()
        local p = Vector3.new(0, 0, 0)
        local a = HazardImpactAudience
        expect(a.shouldSend(p, Vector3.new(100, 0, 0), true, false, 180)).toBe(true)
        expect(a.shouldSend(p, Vector3.new(181, 0, 0), true, false, 180)).toBe(false)
        expect(a.shouldSend(p, Vector3.new(1000, 0, 0), true, true, 180)).toBe(true)
        expect(a.shouldSend(p, nil, false, false, 180)).toBe(true)
        expect(a.shouldSend(p, nil, nil, nil, 180)).toBe(true)
        expect(a.shouldSend(p, nil, true, false, 180)).toBe(false)
        expect(a.shouldSend(nil, nil, false, true, 180)).toBe(false)
        expect(a.shouldSend(p, Vector3.new(180, 0, 0), true, false, 180)).toBe(true)
    end)

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
        local reportedDamage = nil

        local hits = DisasterImpact.applyRadialDamage({
            HazardContestants = {subject},
            IsContestantActive = function()
                return true
            end,
            OnHazardDamage = function(_, kind, damage)
                reportedKind = kind
                reportedDamage = damage
                healthWhenCauseRecorded = humanoid.Health
            end,
        }, Vector3.new(0, 3, 0), 8, 50, "Meteor")

        expect(hits).toBe(1)
        expect(reportedKind).toBe("Meteor")
        expect(reportedDamage).toBe(20)
        expect(healthWhenCauseRecorded).toBe(20)
        expect(humanoid.Health).toBe(0)

        character:Destroy()
    end)

    it("clamps lethal falloff damage to remaining health", function()
        local character = Instance.new("Model")
        character.Name = "FalloffFatalImpactCharacter"

        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Position = Vector3.new(4, 3, 0)
        root.Anchored = true
        root.Parent = character

        local humanoid = Instance.new("Humanoid")
        humanoid.MaxHealth = 12
        humanoid.Health = 12
        humanoid.Parent = character
        character.Parent = workspace

        local subject = {
            UserId = 456,
            Name = "FalloffFatalImpactSubject",
            Character = character,
        }

        local reportedDamage = nil
        local healthWhenReported = nil
        local hits = DisasterImpact.applyRadialDamage({
            HazardContestants = {subject},
            IsContestantActive = function()
                return true
            end,
            OnHazardDamage = function(_, _, damage)
                reportedDamage = damage
                healthWhenReported = humanoid.Health
            end,
        }, Vector3.new(0, 3, 0), 8, 50, "Bombs")

        expect(hits).toBe(1)
        expect(reportedDamage).toBe(12)
        expect(healthWhenReported).toBe(12)
        expect(humanoid.Health).toBe(0)

        character:Destroy()
    end)

    it("stops a blast when a previous hit ends the round", function()
        local function makeSubject(name, position)
            local character = Instance.new("Model")
            character.Name = name
            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Anchored = true
            root.Position = position
            root.Parent = character
            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.Parent = character
            character.Parent = workspace
            return {Character = character}, humanoid, character
        end

        local first, firstHum, firstModel = makeSubject(
            "FirstImpactSurvivor", Vector3.new(0, 3, 0)
        )
        local second, secondHum, secondModel = makeSubject(
            "NextImpactSurvivor", Vector3.new(0, 3, 0)
        )
        local near, nearHum, nearModel = makeSubject(
            "NearMissSurvivor", Vector3.new(9, 3, 0)
        )
        local active = true
        local notified = 0
        local nearMisses = 0
        local ctx = {
            HazardContestants = {first, second, near},
            Active = function() return active end,
            IsContestantActive = function() return true end,
            OnHazardDamage = function(subject)
                notified += 1
                if subject == first then
                    -- Simulate a round-ending scoring/elimination callback.
                    active = false
                end
            end,
            OnHazardNearMiss = function()
                nearMisses += 1
            end,
        }

        local hits = DisasterImpact.applyRadialDamage(
            ctx, Vector3.new(0, 3, 0), 8, 50, "Bomb"
        )
        expect(hits).toBe(1)
        expect(notified).toBe(1)
        expect(nearMisses).toBe(0)
        expect(firstHum.Health).toBe(50)
        expect(secondHum.Health).toBe(100)
        expect(nearHum.Health).toBe(100)

        -- A stale post-round call must not damage or award near misses.
        hits = DisasterImpact.applyRadialDamage(
            ctx, Vector3.new(0, 3, 0), 8, 50, "Bomb"
        )
        expect(hits).toBe(0)
        expect(notified).toBe(1)
        expect(nearMisses).toBe(0)

        -- Normal active-round behavior, including near misses, is unchanged.
        active = true
        ctx.OnHazardDamage = function()
            notified += 1
        end
        hits = DisasterImpact.applyRadialDamage(
            ctx, Vector3.new(0, 3, 0), 8, 50, "Bomb"
        )
        expect(hits).toBe(2)
        expect(nearMisses).toBe(1)

        firstModel:Destroy()
        secondModel:Destroy()
        nearModel:Destroy()
    end)

    it("never treats nonfinite physics distances as direct hits or near misses", function()
        local nan = 0 / 0
        local infinity = math.huge

        for _, invalid in ipairs({nan, infinity, -infinity}) do
            expect(DisasterImpact.damageForDistance(invalid, 8, 50)).toBe(0)
            expect(DisasterImpact.nearMissForDistance(invalid, 8, 3.5)).toBe(false)
        end

        expect(DisasterImpact.damageForDistance(0, nan, 50)).toBe(50)
        expect(DisasterImpact.damageForDistance(0, infinity, 50)).toBe(50)
        expect(DisasterImpact.damageForDistance(0, 8, nan)).toBe(0)
        expect(DisasterImpact.damageForDistance(0, 8, infinity)).toBe(0)
        expect(DisasterImpact.damageForDistance(0, 8, -infinity)).toBe(0)
        expect(DisasterImpact.nearMissForDistance(9, 8, nan)).toBe(false)
        expect(DisasterImpact.nearMissForDistance(9, 8, infinity)).toBe(false)
        expect(DisasterImpact.nearMissForDistance(9, 8, 3.5)).toBe(true)
    end)

    it("refuses stale lava deaths when eligibility or fatal attribution ends the round", function()
        local character = Instance.new("Model")
        character.Name = "LavaRoundOwnershipSubject"
        local humanoid = Instance.new("Humanoid")
        humanoid.MaxHealth = 100
        humanoid.Health = 100
        humanoid.Parent = character
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Anchored = true
        root.Size = Vector3.new(2, 2, 1)
        root.Position = Vector3.new(0, 4.4, 0)
        root.Parent = character
        character.Parent = workspace

        local lava = Instance.new("Part")
        lava.Name = "LavaRoundOwnershipProbe"
        lava.Anchored = true
        lava.Position = Vector3.zero
        lava.Size = Vector3.new(20, 4, 20)
        lava.Parent = workspace

        local subject = {Character = character}
        local active = true
        local ctx = {
            Active = function() return active end,
            IsContestantActive = function()
                active = false
                return true
            end,
        }
        -- A yielded eligibility callback can end the round even if it
        -- initially reports that the player was eligible.
        expect(RisingLava.contactIsLethal(
            ctx, subject, character, humanoid, lava
        )).toBe(false)

        -- Respawning inside an eligibility callback invalidates the old rig.
        active = true
        local replacement = Instance.new("Model")
        ctx.IsContestantActive = function()
            subject.Character = replacement
            return true
        end
        expect(RisingLava.contactIsLethal(
            ctx, subject, character, humanoid, lava
        )).toBe(false)

        subject.Character = character
        ctx.IsContestantActive = function() return true end
        expect(RisingLava.contactIsLethal(
            ctx, subject, character, humanoid, lava
        )).toBe(true)

        lava:Destroy()
        replacement:Destroy()

        -- Exercise the actual rising-lava worker as well as the helper.
        -- A scoring callback may close the phase before the old worker
        -- reaches Humanoid.Health=0. No stale damage is permitted.
        local cleanup = {}
        local causes = 0
        root.Position = Vector3.new(0, -5, 0)
        active = true
        RisingLava.start({
            Config = {ArenaCenter = Vector3.zero, RoundSeconds = 0.2},
            RoundSeconds = 0.2,
            Cleanup = cleanup,
            Active = function() return active end,
            HazardContestants = {subject},
            IsContestantActive = function() return true end,
            OnFatalHazard = function()
                causes += 1
                active = false
            end,
        })
        task.wait(0.2)
        expect(causes).toBe(1)
        expect(humanoid.Health).toBe(100)

        active = false
        for _, instance in ipairs(cleanup) do
            if instance and instance.Parent then instance:Destroy() end
        end
        character:Destroy()
    end)

    it("sanitizes negative distance and damage inputs", function()
        expect(DisasterImpact.damageForDistance(-5, 8, 50)).toBe(50)
        expect(DisasterImpact.damageForDistance(0, 8, -10)).toBe(0)
    end)
end)

return nil
