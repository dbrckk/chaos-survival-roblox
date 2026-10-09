--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaVariants = require("../../src/server/ArenaVariants")
local ArenaMechanics = require("../../src/server/ArenaMechanics")
local FluxRelayRules = require("../../src/shared/FluxRelayRules")
local CrossroadsFluxRelay = require("../../src/server/CrossroadsFluxRelay")
local MovementSafety = require("../../src/server/MovementSafety")
local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")

describe("Arena mechanics", function()
    it("defines one mobility mechanic for every playable arena", function()
        local seenNames = {}

        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)
            expect(mechanic ~= nil).toBe(true)
            expect(type(mechanic.Name)).toBe("string")
            expect(type(mechanic.Hint)).toBe("string")
            expect(#mechanic.Name >= 4).toBe(true)
            expect(#mechanic.Hint >= 24).toBe(true)
            expect(#mechanic.Hint <= 96).toBe(true)
            expect(seenNames[mechanic.Name] == nil).toBe(true)
            seenNames[mechanic.Name] = true
        end
    end)

    it("provides multiple telegraphed mobility choices per arena", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)
            expect(#mechanic.Pads >= 4).toBe(true)

            for _, pad in ipairs(mechanic.Pads) do
                expect(typeof(pad.offset)).toBe("Vector3")
                expect(typeof(pad.impulse)).toBe("Vector3")
                expect(pad.impulse.Magnitude >= 20).toBe(true)
                expect(pad.impulse.Magnitude <= 60).toBe(true)
            end
        end
    end)

    it("alternates charged return lanes with a clear standby window", function()
        local r = FluxRelayRules
        expect(#r.Offsets).toBe(4)
        expect(r.Period).toBe(8)
        expect(r.ChargeDuration < r.Period * 0.5).toBe(true)
        for index = 1, 4 do
            expect(typeof(r.Offsets[index])).toBe("Vector3")
        end
        expect(r.offsetFor(1)).toBe(r.offsetFor(3))
        expect(r.offsetFor(2)).toBe(r.offsetFor(4))
        expect(r.offsetFor(1) ~= r.offsetFor(2)).toBe(true)

        local epoch = 100
        expect(r.charged(100.5, epoch, r.offsetFor(1))).toBe(true)
        expect(r.charged(100.5, epoch, r.offsetFor(3))).toBe(true)
        expect(r.charged(100.5, epoch, r.offsetFor(2))).toBe(false)
        expect(r.charged(104.5, epoch, r.offsetFor(1))).toBe(false)
        expect(r.charged(104.5, epoch, r.offsetFor(2))).toBe(true)
        expect(r.charged(108.5, epoch, r.offsetFor(1))).toBe(true)
        expect(r.viableRoute(100.5, epoch, 0, 10, 16)).toBe(true)
        expect(r.viableRoute(103.0, epoch, 0, 10, 16)).toBe(false)
        expect(r.viableRoute(100.5, epoch, 0, 30, 16)).toBe(false)
        expect(r.viableRoute(100.5, nil, 0, 10, 16)).toBe(false)
        expect(r.viableRoute(100.5, epoch, nil, 10, 16)).toBe(false)
    end)

    it("requires an alive eligible runner, charged gate and elapsed cooldown", function()
        local r = FluxRelayRules
        expect(r.canTrigger(true, true, 100, 101, 100, 0, 10, 9)).toBe(true)
        expect(r.canTrigger(true, true, 100, 101, 100, 0, 10, 11)).toBe(false)
        expect(r.canTrigger(false, true, 100, 101, 100, 0, 10, 0)).toBe(false)
        expect(r.canTrigger(true, false, 100, 101, 100, 0, 10, 0)).toBe(false)
        expect(r.canTrigger(true, true, 0, 101, 100, 0, 10, 0)).toBe(false)
        expect(r.canTrigger(true, true, 100, 104, 100, 0, 10, 0)).toBe(false)
        expect(r.nextAllowed(10)).toBe(13.5)
    end)

    it("redirects the runner toward the hub without exceeding safe speed", function()
        local rules = FluxRelayRules
        local center = Vector3.new(0, 0, 0)
        local gate = Vector3.new(34, 4, 0)
        local normal = rules.velocity(Vector3.new(26, -18, 12), gate, center, false)
        local boosted = rules.velocity(Vector3.new(26, -18, 12), gate, center, true)
        expect(normal.X < 0).toBe(true)
        expect(boosted.X < normal.X).toBe(true)
        for _, velocity in ipairs({
            Vector3.new(200, 100, 200),
            Vector3.new(-150, -100, 99),
            Vector3.zero,
        }) do
            local result = rules.velocity(velocity, gate, center, true)
            expect(Vector3.new(result.X, 0, result.Z).Magnitude <= 54.001).toBe(true)
            expect(result.Y >= -52 and result.Y <= 58).toBe(true)
        end
    end)

    it("spawns four invisible live flux triggers beside Crossroads launch pads", function()
        local root = MapBuilder.build(Config, "Crossroads", ArenaVariants)
        local events = {}
        local ctx = {
            Active = function() return true end,
            IsContestantActive = function() return false end,
            Cleanup = {},
            OnArenaMechanicUsed = function() table.insert(events, "human") end,
        }
        local result = ArenaMechanics.start(ctx, "Crossroads")
        expect(result ~= nil).toBe(true)
        local arena = root:FindFirstChild("Arena")
        local mechanics = arena and arena:FindFirstChild("Mechanics")
        local relays = mechanics and mechanics:FindFirstChild("FluxRelays")
        expect(relays ~= nil).toBe(true)
        expect(#(relays :: Folder):GetChildren()).toBe(4)

        local first = relays:FindFirstChild("FluxRelay1")
        local second = relays:FindFirstChild("FluxRelay2")
        expect(first ~= nil).toBe(true)
        expect(second ~= nil).toBe(true)
        expect(first:GetAttribute("FluxRelayIndex")).toBe(1)
        expect(second:GetAttribute("FluxRelayIndex")).toBe(2)
        for _, obj in ipairs(relays:GetChildren()) do
            expect(obj:IsA("BasePart")).toBe(true)
            expect(obj.CanCollide).toBe(false)
            expect(obj.CanTouch).toBe(true)
            expect(obj.CanQuery).toBe(false)
            expect(obj.Transparency).toBe(1)
        end

        local bot = Instance.new("Model")
        bot.Name = "TestFluxSurvivor"
        bot:SetAttribute("AISurvivor", true)
        bot:SetAttribute("AISurvivorInRound", true)
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = bot
        local hit = Instance.new("Part")
        hit.Name = "HumanoidRootPart"
        hit.Anchored = true
        hit.Parent = bot
        bot.Parent = workspace
        local epoch = first:GetAttribute("FluxCycleEpoch")
        local ready = {}
        local ok = CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 10, epoch + 0.5, Config.ArenaCenter)
        expect(ok).toBe(true)
        expect(type(first:GetAttribute("FluxTriggeredAt"))).toBe("number")
        expect(CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 11, epoch + 0.6, Config.ArenaCenter)).toBe(false)
        expect(CrossroadsFluxRelay.tryTrigger(ctx, second, hit,
            ready, epoch, 14, epoch + 4.5, Config.ArenaCenter)).toBe(true)
        bot:SetAttribute("AISurvivorInRound", false)
        expect(CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 22, epoch + 8.5, Config.ArenaCenter)).toBe(false)
        expect(#events).toBe(0)

        bot:Destroy()
        root:Destroy()
    end)

    it("keeps ambient pad particles client-side", function()
        MapBuilder.build(Config, "Classic", ArenaVariants)

        local cleanup = {}
        local ctx = {
            Config = Config,
            Cleanup = cleanup,
            OnCleanup = {},
            Active = function() return true end,
            Contestants = {},
            IsContestantActive = function() return false end,
        }

        local result = ArenaMechanics.start(ctx, "Classic")
        expect(result ~= nil).toBe(true)

        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local mechanics = arena and arena:FindFirstChild("Mechanics")
        expect(mechanics ~= nil).toBe(true)
        expect(mechanics and mechanics:FindFirstChildWhichIsA("ParticleEmitter", true) == nil).toBe(true)

        for _, object in ipairs(cleanup) do
            if object and object.Parent then
                object:Destroy()
            end
        end
        if generated then
            generated:Destroy()
        end
    end)

    it("reads live pad impulse attributes with a safe fallback", function()
        local pad = Instance.new("Part")
        pad:SetAttribute("ImpulseX", 12)
        pad:SetAttribute("ImpulseY", 34)
        pad:SetAttribute("ImpulseZ", -8)

        local live = ArenaMechanics.readPadImpulse(pad, Vector3.new(1, 2, 3))
        expect(live).toBe(Vector3.new(12, 34, -8))

        pad:SetAttribute("ImpulseY", nil)
        local fallback = ArenaMechanics.readPadImpulse(pad, Vector3.new(1, 2, 3))
        expect(fallback).toBe(Vector3.new(12, 2, -8))

        pad:Destroy()
    end)

    it("boosts pad impulses during overdrive without mutating the base vector", function()
        local base = Vector3.new(20, 10, -12)
        local normal = ArenaMechanics.impulseFor(base, false)
        local boosted = ArenaMechanics.impulseFor(base, true)

        expect((normal - base).Magnitude < 0.001).toBe(true)
        expect((boosted - (base * 1.28)).Magnitude < 0.001).toBe(true)
        expect((base - Vector3.new(20, 10, -12)).Magnitude < 0.001).toBe(true)
    end)

    it("reduces mobility-pad cooldown during final rush", function()
        expect(ArenaMechanics.cooldownFor(false)).toBe(1.1)
        expect(ArenaMechanics.cooldownFor(true)).toBe(0.65)
    end)

    it("uses the shared movement safety contract for pad impulses", function()
        local current = Vector3.new(90, 80, -95)
        local impulse = Vector3.new(46, 55, 46)

        local padVelocity = ArenaMechanics.safeVelocity(current, impulse)
        local sharedVelocity = MovementSafety.addImpulse(current, impulse, 60, -52, 58)

        expect((padVelocity - sharedVelocity).Magnitude < 0.001).toBe(true)
    end)

    it("clamps stacked disaster velocity before applying pad motion", function()
        local velocity = ArenaMechanics.safeVelocity(
            Vector3.new(90, 80, -95),
            Vector3.new(46, 55, 46)
        )

        local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
        expect(horizontal.Magnitude <= 60.001).toBe(true)
        expect(velocity.Y).toBe(58)

        local falling = ArenaMechanics.safeVelocity(
            Vector3.new(0, -90, 0),
            Vector3.new(0, 8, 0)
        )
        expect(falling.Y).toBe(-52)
    end)

    it("keeps mobility impulses non-lethal and bounded", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)

            for _, pad in ipairs(mechanic.Pads) do
                expect(pad.impulse.Y >= 0).toBe(true)
                expect(math.abs(pad.impulse.X) <= 50).toBe(true)
                expect(math.abs(pad.impulse.Z) <= 50).toBe(true)
                expect(pad.impulse.Y <= 55).toBe(true)
            end
        end
    end)
end)

return nil
