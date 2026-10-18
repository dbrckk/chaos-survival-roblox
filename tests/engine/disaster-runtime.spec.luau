--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local DisasterBalance = require("../../src/server/DisasterBalance")
local MovementSafety = require("../../src/server/MovementSafety")
local RisingLava = require("../../src/server/Disasters/RisingLava")
local Tornado = require("../../src/server/Disasters/Tornado")

local disasters = {
    {id = "RisingLava", module = require("../../src/server/Disasters/RisingLava")},
    {id = "Meteors", module = require("../../src/server/Disasters/Meteors")},
    {id = "LowGravity", module = require("../../src/server/Disasters/LowGravity")},
    {id = "DisappearingPlatforms", module = require("../../src/server/Disasters/DisappearingPlatforms")},
    {id = "Tornado", module = require("../../src/server/Disasters/Tornado")},
    {id = "Freeze", module = require("../../src/server/Disasters/Freeze")},
    {id = "Bombs", module = require("../../src/server/Disasters/Bombs")},
    {id = "SpeedSurge", module = require("../../src/server/Disasters/SpeedSurge")},
    {id = "Darkness", module = require("../../src/server/Disasters/Darkness")},
    {id = "ShrinkingArena", module = require("../../src/server/Disasters/ShrinkingArena")},
    {id = "JumpShock", module = require("../../src/server/Disasters/JumpShock")},
}

local function runCleanup(cleanup, onCleanup)
    for _, callback in ipairs(onCleanup) do
        pcall(callback)
    end

    for _, object in ipairs(cleanup) do
        if object and object.Parent then
            object:Destroy()
        end
    end
end

describe("Headless disaster playtest", function()
    it("never offers a safe tornado eye or launches outside its 42-stud radius", function()
        local center = Vector3.new(0, 0, 0)
        local eye, eyeStrength = Tornado.impulseAt(
            center, center, 17, 1
        )
        expect(eye ~= nil).toBe(true)
        expect(eyeStrength).toBe(1)
        expect(eye.X > 0 and eye.Y > 0).toBe(true)
        expect(eye.Z).toBe(0)

        for _, distance in ipairs({0.001, 0.5, 1.99, 2, 2.01, 12, 36}) do
            local impulse, strength = Tornado.impulseAt(
                Vector3.new(distance, 5, 0), center, 17, 1
            )
            expect(impulse ~= nil).toBe(true)
            expect(strength > 0 and strength <= 1).toBe(true)
            expect(impulse.Y > 0).toBe(true)
            expect(impulse.X == impulse.X and impulse.Y == impulse.Y
                and impulse.Z == impulse.Z).toBe(true)
        end

        local nearBoundary, boundaryStrength = Tornado.impulseAt(
            Vector3.new(41.9, 0, 0), center, 17, 1
        )
        expect(nearBoundary ~= nil).toBe(true)
        expect(boundaryStrength > 0 and boundaryStrength < 0.01)
            .toBe(true)
        local outside, outsideStrength = Tornado.impulseAt(
            Vector3.new(42, 0, 0), center, 17, 1
        )
        expect(outside == nil).toBe(true)
        expect(outsideStrength).toBe(0)
        expect(Tornado.impulseAt(Vector3.new(60, 0, 0), center, 17, 1)
            == nil).toBe(true)
        expect(Tornado.impulseAt(nil, center, 17, 1) == nil).toBe(true)

        local boosted = MovementSafety.addImpulse(
            Vector3.new(60, 55, 0), eye, 62, -55, 58
        )
        expect(Vector3.new(boosted.X, 0, boosted.Z).Magnitude <= 62)
            .toBe(true)
        expect(boosted.Y <= 58).toBe(true)
    end)

    it("ignores accessory-only lava contact and late round callbacks", function()
        local character = Instance.new("Model")
        character.Name = "LavaContactSubject"
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Anchored = true
        root.Size = Vector3.new(2, 2, 1)
        root.Position = Vector3.new(0, 8, 0)
        root.Parent = character

        -- A long accessory can touch first while the avatar's feet and
        -- torso remain well above the actual rising surface.
        local accessory = Instance.new("Part")
        accessory.Name = "LongAccessory"
        accessory.Anchored = true
        accessory.Position = Vector3.new(0, 2, 0)
        accessory.Parent = character
        character.Parent = workspace

        local lava = Instance.new("Part")
        lava.Name = "LavaContactProbe"
        lava.Anchored = true
        lava.Size = Vector3.new(20, 4, 20)
        lava.Position = Vector3.zero
        lava.Parent = workspace

        local subject = {Character = character}
        local active = true
        local eligible = true
        local ctx = {
            Active = function() return active end,
            IsContestantActive = function() return eligible end,
        }
        local lethal = RisingLava.contactIsLethal

        expect(lethal(ctx, subject, character, humanoid, lava)).toBe(false)

        root.Position = Vector3.new(0, 4.4, 0)
        expect(lethal(ctx, subject, character, humanoid, lava)).toBe(true)

        eligible = false
        expect(lethal(ctx, subject, character, humanoid, lava)).toBe(false)
        eligible = true
        active = false
        expect(lethal(ctx, subject, character, humanoid, lava)).toBe(false)
        active = true

        root.Position = Vector3.new(40, 4.4, 0)
        expect(lethal(ctx, subject, character, humanoid, lava)).toBe(false)
        root.Position = Vector3.new(0, 4.4, 0)

        local replaced = Instance.new("Model")
        subject.Character = replaced
        expect(lethal(ctx, subject, character, humanoid, lava)).toBe(false)
        subject.Character = character

        humanoid.Health = 0
        expect(lethal(ctx, subject, character, humanoid, lava)).toBe(false)

        replaced:Destroy()
        lava:Destroy()
        character:Destroy()
    end)

    it("reports real tornado knockback contacts", function()
        MapBuilder.build(Config, "Classic", ArenaVariants)

        local active = true
        local cleanup = {}
        local onCleanup = {}
        local contactKind = nil

        local character = Instance.new("Model")
        character.Name = "TornadoContactSubject"

        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.Anchored = true
        root.CanCollide = false
        root.Position = Config.ArenaCenter + Vector3.new(12, 3, 0)
        root.Parent = character

        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        character.Parent = workspace

        local subject = {
            Character = character,
        }

        local ctx = {
            Config = Config,
            RoundSeconds = 1,
            Cleanup = cleanup,
            OnCleanup = onCleanup,
            Active = function()
                return active
            end,
            HazardContestants = {subject},
            Contestants = {subject},
            IsContestantActive = function()
                return true
            end,
            BalanceProfile = DisasterBalance.mobileProfile(1),
            Intensity = function()
                return 1
            end,
            OnHazardContact = function(target, kind)
                if target == subject then
                    contactKind = kind
                end
            end,
        }

        local tornado = require("../../src/server/Disasters/Tornado")
        local ok, err = pcall(tornado.start, ctx)
        expect(ok).toBe(true)

        local deadline = os.clock() + 0.75
        while contactKind == nil and os.clock() < deadline do
            task.wait(0.05)
        end

        expect(contactKind).toBe("Tornado")

        -- The center was previously immune because dist > 2 excluded it.
        contactKind = nil
        root.Position = Config.ArenaCenter
        local centerDeadline = os.clock() + 0.75
        while contactKind == nil and os.clock() < centerDeadline do
            task.wait(0.05)
        end
        expect(contactKind).toBe("Tornado")

        active = false
        runCleanup(cleanup, onCleanup)
        character:Destroy()

        local generated = workspace:FindFirstChild("GeneratedMap")
        if generated then
            generated:Destroy()
        end

        if not ok then
            error("Tornado contact runtime failed: " .. tostring(err))
        end
    end)

    it("reports real jump shock knockback contacts without timer delay", function()
        local character = Instance.new("Model")
        character.Name = "JumpShockContactSubject"

        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.Anchored = true
        root.CanCollide = false
        root.Parent = character

        local humanoid = Instance.new("Humanoid")
        humanoid.Health = 100
        humanoid.Parent = character
        character.Parent = workspace

        local subject = {
            Character = character,
        }
        local contactKind = nil

        local jumpShock = require("../../src/server/Disasters/JumpShock")
        local applied = jumpShock.applyShock({
            IsContestantActive = function()
                return true
            end,
            OnHazardContact = function(target, kind)
                if target == subject then
                    contactKind = kind
                end
            end,
        }, subject, 8)

        expect(applied).toBe(true)
        expect(contactKind).toBe("JumpShock")

        character:Destroy()
    end)

    it("rejects late Jump Shock impulses after a round closes", function()
        local jumpShock = require("../../src/server/Disasters/JumpShock")
        local character = Instance.new("Model")
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Anchored = true
        root.Parent = character
        character.Parent = workspace
        local subject = {Character = character}
        local contacts = 0

        local active = false
        local ctx = {
            Active = function() return active end,
            IsContestantActive = function() return true end,
            OnHazardContact = function() contacts += 1 end,
        }
        expect(jumpShock.applyShock(ctx, subject, 8)).toBe(false)
        expect(contacts).toBe(0)

        -- An eligibility hook can synchronously close the round during
        -- a shock iteration. Re-check phase after calling that hook.
        active = true
        ctx.IsContestantActive = function()
            active = false
            return true
        end
        expect(jumpShock.applyShock(ctx, subject, 8)).toBe(false)
        expect(contacts).toBe(0)

        active = true
        ctx.IsContestantActive = function() return true end
        expect(jumpShock.applyShock(ctx, subject, 8)).toBe(true)
        expect(contacts).toBe(1)
        character:Destroy()
    end)

    it("suppresses Meteor and Bomb visual callbacks when damage ends the round", function()
        -- Each effect runs in the actual Roblox DataModel. The first
        -- damage notification closes the round; no late impact FX may
        -- be sent to the lobby or a newly-started round.
        local cases = {
            {
                module = require("../../src/server/Disasters/Bombs"),
                markerName = "BombWarning",
                profile = {BombWarningSeconds = 0.4, BombRadius = 8, BombDamage = 50},
            },
            {
                module = require("../../src/server/Disasters/Meteors"),
                markerName = "MeteorWarning",
                profile = {MeteorWarningSeconds = 0.4, MeteorRadius = 8, MeteorDamage = 50},
            },
        }

        for _, case in ipairs(cases) do
            local character = Instance.new("Model")
            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.Parent = character
            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Size = Vector3.new(2, 2, 1)
            root.Anchored = true
            root.Parent = character
            character.Parent = workspace

            local subject = {Character = character}
            local active = true
            local damageEvents = 0
            local visualEvents = 0
            local cleanup = {}
            case.module.start({
                Config = Config,
                Cleanup = cleanup,
                Active = function() return active end,
                HazardContestants = {subject},
                IsContestantActive = function() return true end,
                BalanceProfile = case.profile,
                OnHazardDamage = function()
                    damageEvents += 1
                    active = false
                end,
                OnHazardImpact = function()
                    visualEvents += 1
                end,
            })

            local marker = nil
            local deadline = os.clock() + 1
            repeat
                marker = workspace:FindFirstChild(case.markerName)
                if marker then break end
                task.wait(0.02)
            until os.clock() >= deadline

            if marker then
                root.Position = marker.Position + Vector3.new(0, 1, 0)
            end
            local impactDeadline = os.clock() + 2
            while active and os.clock() < impactDeadline do
                task.wait(0.03)
            end

            active = false
            runCleanup(cleanup, {})
            character:Destroy()

            expect(marker ~= nil).toBe(true)
            expect(damageEvents).toBe(1)
            expect(visualEvents).toBe(0)
        end
    end)

    it("retains an actual meteor ground warning during projectile descent", function()
        local meteorDisaster = require("../../src/server/Disasters/Meteors")
        local active = true
        local cleanup = {}
        local impacts = 0
        meteorDisaster.start({
            Config = Config,
            Cleanup = cleanup,
            Active = function() return active end,
            BalanceProfile = {
                MeteorWarningSeconds = 0.20,
                MeteorRadius = 8,
                MeteorDamage = 50,
            },
            Contestants = {},
            HazardContestants = {},
            OnHazardImpact = function(_, _, _, kind)
                if kind == "Meteor" then
                    impacts += 1
                    active = false
                end
            end,
        })

        local marker = nil
        local markerDeadline = os.clock() + 1.0
        repeat
            marker = workspace:FindFirstChild("MeteorWarning")
            if marker then break end
            task.wait(0.02)
        until os.clock() >= markerDeadline

        if not marker then
            active = false
            runCleanup(cleanup, {})
            expect(false).toBe(true)
            return
        end
        local lead = marker:GetAttribute("WarningDuration")
        expect(type(lead)).toBe("number")
        expect(math.abs(lead - 0.70) < 0.01).toBe(true)

        -- The 0.20-second pre-fall timer has already passed; impact is
        -- still 0.5 seconds away, so the actual marker must survive.
        task.wait(0.34)
        expect(marker.Parent).toBe(workspace)
        expect(impacts).toBe(0)

        local deadline = os.clock() + 1.30
        while impacts == 0 and os.clock() < deadline do
            task.wait(0.03)
        end
        expect(impacts).toBe(1)
        task.wait(0.04)
        expect(marker.Parent).toBe(nil)

        active = false
        runCleanup(cleanup, {})
    end)

    it("starts and cleans every disaster inside a real Roblox DataModel", function()
        local originalGravity = workspace.Gravity

        for _, entry in ipairs(disasters) do
            MapBuilder.build(Config, "Classic", ArenaVariants)

            local active = true
            local cleanup = {}
            local onCleanup = {}

            local ctx = {
                Config = Config,
                RoundSeconds = 1,
                Cleanup = cleanup,
                OnCleanup = onCleanup,
                Active = function()
                    return active
                end,
                Contestants = {},
                BalanceProfile = DisasterBalance.mobileProfile(1),
            }

            local ok, err = pcall(entry.module.start, ctx)
            expect(ok).toBe(true)

            task.wait(0.08)
            active = false
            runCleanup(cleanup, onCleanup)
            task.wait(0.02)

            expect(workspace.Gravity).toBe(originalGravity)

            local root = workspace:FindFirstChild("GeneratedMap")
            expect(root ~= nil).toBe(true)
            expect((root :: Folder):FindFirstChild("Arena") ~= nil).toBe(true)

            local lava = workspace:FindFirstChild("RoundLava")
            expect(lava == nil).toBe(true)

            if not ok then
                error(entry.id .. " runtime failed: " .. tostring(err))
            end
        end

        local generated = workspace:FindFirstChild("GeneratedMap")
        if generated then
            generated:Destroy()
        end
    end)
end)

return nil
