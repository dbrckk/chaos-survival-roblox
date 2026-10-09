--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaVariants = require("../../src/server/ArenaVariants")
local ArenaMechanics = require("../../src/server/ArenaMechanics")
local FluxRelayRules = require("../../src/shared/FluxRelayRules")
local GridCircuitRules = require("../../src/shared/GridCircuitRules")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
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

    it("offers an optional clockwise four-node Grid Circuit on Classic", function()
        local rules = GridCircuitRules
        expect(rules.Count).toBe(4)
        expect(#rules.Offsets).toBe(4)
        expect(rules.Window).toBe(20)
        expect(rules.next(1)).toBe(2)
        expect(rules.next(4)).toBe(1)
        expect(rules.next(0) == nil).toBe(true)
        expect(rules.next(5) == nil).toBe(true)

        local first, changed = rules.advance(nil, 3, 100)
        expect(changed).toBe(true)
        expect(first.step).toBe(1)
        expect(first.nextNode).toBe(4)
        expect(first.expiresAt).toBe(120)
        local wrong, bad = rules.advance(first, 2, 102)
        expect(bad).toBe(false)
        expect(wrong).toBe(first)

        local same, replayed = rules.advance(first, 3, 103)
        expect(replayed).toBe(false)
        expect(same).toBe(first)
        local second, changed2 = rules.advance(first, 4, 105)
        expect(changed2).toBe(true)
        expect(second.step).toBe(2)
        expect(second.nextNode).toBe(1)
        local third = rules.advance(second, 1, 109)
        expect(third.step).toBe(3)
        expect(third.nextNode).toBe(2)
        local fourth = rules.advance(third, 2, 114)
        expect(fourth.completed).toBe(true)
        expect(fourth.step).toBe(4)
        expect(fourth.nextNode).toBe(0)

        local repeated, advanced = rules.advance(fourth, 3, 115)
        expect(advanced).toBe(false)
        expect(repeated).toBe(fourth)
        local expired = rules.advance(first, 4, 121)
        expect(expired.step).toBe(1)
        expect(expired.nextNode).toBe(1)
        local invalid, ignored = rules.advance(nil, -1, 100)
        expect(invalid == nil and ignored == false).toBe(true)
        expect(rules.advance(nil, 1, nil) == nil).toBe(true)
    end)

    it("rejects inactive, distant or dead Grid Circuit touch events", function()
        local r = GridCircuitRules
        expect(r.eligible(true, true, 100, 1, 0, 9, 8)).toBe(true)
        expect(r.eligible(false, true, 100, 1, 0, 9, 8)).toBe(false)
        expect(r.eligible(true, false, 100, 1, 0, 9, 8)).toBe(false)
        expect(r.eligible(true, true, 0, 1, 0, 9, 8)).toBe(false)
        expect(r.eligible(true, true, 100, 8, 0, 9, 8)).toBe(false)
        expect(r.eligible(true, true, 100, 1, 7, 9, 8)).toBe(false)
        expect(r.eligible(true, true, 100, 1, 0, 7, 8)).toBe(false)
        expect(r.eligible(true, true, 100, 0, 0, 9, 8)).toBe(true)
    end)

    it("spawns four passive Grid Circuit nodes above Classic ground without blockers", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local ctx = {
            Active = function() return true end,
            IsContestantActive = function() return false end,
            Cleanup = {},
            Contestants = {},
        }
        local mechanic = ArenaMechanics.start(ctx, "Classic")
        expect(mechanic ~= nil).toBe(true)
        local arena = root:FindFirstChild("Arena")
        local base = arena and arena:FindFirstChild("Base")
        local mechanics = arena and arena:FindFirstChild("Mechanics")
        local circuit = mechanics and mechanics:FindFirstChild("GridCircuit")
        expect(circuit ~= nil).toBe(true)
        expect(#(circuit :: Folder):GetChildren()).toBe(4)
        for index = 1, 4 do
            local node = circuit:FindFirstChild("GridCircuitNode" .. index)
            expect(node ~= nil).toBe(true)
            expect(node:IsA("BasePart")).toBe(true)
            expect(node:GetAttribute("GridCircuitIndex")).toBe(index)
            expect(node.Anchored).toBe(true)
            expect(node.CanCollide).toBe(false)
            expect(node.CanTouch).toBe(true)
            expect(node.CanQuery).toBe(false)
            expect(node.Transparency).toBe(1)
            expect((node.Position - (base.Position
                + GridCircuitRules.Offsets[index]
                + Vector3.new(0, 3.3, 0))).Magnitude < 0.001).toBe(true)
            -- All four stations remain above the smallest shrinking floor.
            expect(math.abs(node.Position.X - base.Position.X) <= 17).toBe(true)
            expect(math.abs(node.Position.Z - base.Position.Z) <= 17).toBe(true)
        end
        root:Destroy()
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
            expect(result.X < 0).toBe(true)
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
        hit.Position = first.Position
        hit.Parent = bot
        bot.Parent = workspace
        local epoch = first:GetAttribute("FluxCycleEpoch")
        local ready = {}
        -- Oversized accessory contacts never activate a distant body.
        hit.Position = first.Position + Vector3.new(20, 0, 0)
        expect(CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 9, epoch + 0.5, Config.ArenaCenter)).toBe(false)
        hit.Position = first.Position
        local ok = CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 10, epoch + 0.5, Config.ArenaCenter)
        expect(ok).toBe(true)
        expect(type(first:GetAttribute("FluxTriggeredAt"))).toBe("number")
        expect(CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 11, epoch + 0.6, Config.ArenaCenter)).toBe(false)
        hit.Position = second.Position
        expect(CrossroadsFluxRelay.tryTrigger(ctx, second, hit,
            ready, epoch, 14, epoch + 4.5, Config.ArenaCenter)).toBe(true)
        hit.Position = first.Position
        bot:SetAttribute("AISurvivorInRound", false)
        expect(CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 22, epoch + 8.5, Config.ArenaCenter)).toBe(false)
        expect(#events).toBe(0)

        bot:Destroy()
        root:Destroy()
    end)

    it("advances Helix mastery across different lanes without farming one ramp", function()
        local r = OrbitalHelix
        expect(r.ChainCap).toBe(3)
        expect(r.ChainWindow > 2 * r.FlowCooldown).toBe(true)

        local one = r.advanceChain(nil, 1, 10)
        expect(one.tier).toBe(1)
        expect(one.lane).toBe(1)
        local repeated = r.advanceChain(one, 1, 15)
        expect(repeated.tier).toBe(1)
        expect(repeated.at).toBe(10)

        local two = r.advanceChain(repeated, 3, 16)
        expect(two.tier).toBe(2)
        local three = r.advanceChain(two, 5, 22)
        expect(three.tier).toBe(3)
        expect(r.advanceChain(three, 7, 27).tier).toBe(3)
        expect(r.advanceChain(three, 7, 43).tier).toBe(1)
        expect(r.advanceChain(three, 0, 23).tier).toBe(0)
        expect(r.advanceChain(three, 9, 23).tier).toBe(0)
        expect(r.advanceChain(three, nil, 23).tier).toBe(0)
        expect(r.advanceChain(three, 1, nil).tier).toBe(0)
        expect(r.advanceChain(three, 1, 19).tier).toBe(1)
    end)

    it("credits only controlled inward Helix Flow passes without automatic physics boosts", function()
        local root = MapBuilder.build(Config, "Orbital", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local ramps = arena and arena:FindFirstChild("HelixCircuit")
        expect(ramps ~= nil).toBe(true)

        local mechanicUses = 0
        local ctx = {
            Active = function() return true end,
            IsContestantActive = function() return false end,
            Cleanup = {},
            OnArenaMechanicUsed = function()
                mechanicUses += 1
            end,
        }
        local definition = ArenaMechanics.start(ctx, "Orbital")
        expect(definition ~= nil).toBe(true)
        local mechanics = arena:FindFirstChild("Mechanics")
        local flow = mechanics and mechanics:FindFirstChild("HelixFlow")
        expect(flow ~= nil).toBe(true)
        expect(#(flow :: Folder):GetChildren()).toBe(8)

        for _, sensor in ipairs(flow:GetChildren()) do
            expect(sensor:IsA("BasePart")).toBe(true)
            expect(sensor.Transparency).toBe(1)
            expect(sensor.CanCollide).toBe(false)
            expect(sensor.CanTouch).toBe(true)
            expect(sensor.CanQuery).toBe(false)
            local weld = sensor:FindFirstChild("HelixFlowFollowRamp")
            expect(weld ~= nil).toBe(true)
            expect(weld.Part0:GetAttribute("OrbitalHelixRamp")).toBe(true)
            expect(weld.Part1).toBe(sensor)
        end

        expect(OrbitalHelix.inwardFlow(Vector3.new(15, 0, 0), Vector3.new(1, 0, 0))).toBe(true)
        expect(OrbitalHelix.inwardFlow(Vector3.new(-15, 0, 0), Vector3.new(1, 0, 0))).toBe(false)
        expect(OrbitalHelix.inwardFlow(Vector3.new(2, 0, 0), Vector3.new(1, 0, 0))).toBe(false)
        expect(OrbitalHelix.inwardFlow(nil, Vector3.new(1, 0, 0))).toBe(false)

        local bot = Instance.new("Model")
        bot.Name = "HelixFlowRegressionBot"
        bot:SetAttribute("AISurvivor", true)
        bot:SetAttribute("AISurvivorInRound", true)
        local hum = Instance.new("Humanoid")
        hum.Parent = bot
        local body = Instance.new("Part")
        body.Name = "HumanoidRootPart"
        body.Size = Vector3.new(2, 2, 1)
        body.Anchored = false
        body.CanCollide = false
        body.Parent = bot
        bot.Parent = workspace

        local first = flow:FindFirstChild("HelixFlowTrigger1")
        local ramp = ramps:FindFirstChild("HelixRamp1")
        body.CFrame = first.CFrame
        local currentSpeed = ramp.CFrame.LookVector * 17
        body.AssemblyLinearVelocity = currentSpeed

        local cooldown = {}
        expect(OrbitalHelix.tryFlow(ctx, first, body, cooldown, 10)).toBe(true)
        expect(first:GetAttribute("HelixFlowTier")).toBe(1)
        expect(ctx.HelixChains[bot].tier).toBe(1)
        expect(OrbitalHelix.tryFlow(ctx, first, body, cooldown, 11)).toBe(false)
        expect(mechanicUses).toBe(0)

        bot:SetAttribute("AISurvivorInRound", false)
        expect(OrbitalHelix.tryFlow(ctx, first, body, cooldown, 20)).toBe(false)

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
