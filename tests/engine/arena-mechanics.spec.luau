--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaVariants = require("../../src/server/ArenaVariants")
local ArenaMechanics = require("../../src/server/ArenaMechanics")
local ArenaDistrictTransit = require("../../src/server/ArenaDistrictTransit")
local DistrictSignalRush = require("../../src/server/DistrictSignalRush")
local FluxRelayRules = require("../../src/shared/FluxRelayRules")
local GridCircuitRules = require("../../src/shared/GridCircuitRules")
local SkyrailSlipstream = require("../../src/server/SkyrailSlipstream")
local SkybridgePressure = require("../../src/server/SkybridgePressure")
local GridCircuitService = require("../../src/server/GridCircuitService")
local ClassicGridSweep = require("../../src/server/ClassicGridSweep")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
local CrossroadsFluxRelay = require("../../src/server/CrossroadsFluxRelay")
local CrossroadsSwitchyard = require("../../src/server/CrossroadsSwitchyard")
local MovementSafety = require("../../src/server/MovementSafety")
local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local PlatformVisualRules = require("../../src/shared/DisappearingPlatformVisualRules")

describe("Arena mechanics", function()
    it("tracks only collapsing parts owned by the current platform folder", function()
        local rules = PlatformVisualRules
        local old = Instance.new("Folder")
        local current = Instance.new("Folder")
        local part = Instance.new("Part")
        part.Parent = current
        expect(rules.ownsPart(part, current)).toBe(true)
        expect(rules.shouldDisplay(part, current)).toBe(false)

        part:SetAttribute("CollapsePhase", "Warning")
        expect(rules.shouldDisplay(part, current)).toBe(true)
        part:SetAttribute("CollapsePhase", "Gone")
        expect(rules.shouldDisplay(part, current)).toBe(true)
        part:SetAttribute("CollapsePhase", "Restored")
        expect(rules.shouldDisplay(part, current)).toBe(false)

        part:SetAttribute("CollapsePhase", "Warning")
        expect(rules.shouldDisplay(part, old)).toBe(false)
        part.Parent = old
        expect(rules.shouldDisplay(part, current)).toBe(false)
        expect(rules.shouldDisplay(part, old)).toBe(true)
        part.Parent = nil
        expect(rules.shouldDisplay(part, old)).toBe(false)
        expect(rules.shouldDisplay(nil, current)).toBe(false)
        expect(rules.shouldDisplay(part, nil)).toBe(false)

        part:Destroy()
        old:Destroy()
        current:Destroy()
    end)

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

    it("only advertises live arena challenges and avoids forced-motion disaster stacking", function()
        expect(SkybridgePressure.canComplete({RoundEndsAt = 30}, 23.5)).toBe(true)
        expect(SkybridgePressure.canComplete({RoundEndsAt = 30}, 24)).toBe(false)
        expect(ClassicGridSweep.canComplete({RoundEndsAt = 30}, 24)).toBe(true)
        expect(ClassicGridSweep.canComplete({RoundEndsAt = 30}, 25)).toBe(false)
        expect(ClassicGridSweep.canComplete({}, 99)).toBe(true)
        expect(SkybridgePressure.canComplete({}, 99)).toBe(true)

        local forbidden = {
            {id = "Classic", danger = "Freeze", dynamic = "GridSweep"},
            {id = "Towers", danger = "Tornado", dynamic = "SkybridgePressure"},
            {id = "Crossroads", danger = "SpeedSurge", dynamic = "JunctionSwitchyard"},
            {id = "Orbital", danger = "LowGravity", dynamic = "HelixPulse"},
        }
        for _, setting in ipairs(forbidden) do
            local base = ArenaMechanics.BaselineHints[setting.id]
            local advanced = ArenaMechanics.get(setting.id).Hint
            expect(type(base)).toBe("string")
            expect(#base <= 96 and #base >= 24).toBe(true)
            expect(base ~= advanced).toBe(true)
            expect(ArenaMechanics.effectiveHint(setting.id, false)).toBe(base)
            expect(ArenaMechanics.effectiveHint(setting.id, true)).toBe(advanced)

            -- Directly pass a conflicting round to ensure the individual
            -- mechanics reject it even if a caller misconfigures flags.
            local generated = MapBuilder.build(Config, setting.id, ArenaVariants)
            local ctx = {
                Active = function() return true end,
                IsContestantActive = function() return false end,
                Cleanup = {},
                OnCleanup = {},
                Contestants = {},
                RoundNumber = 4,
                ActiveDisasters = {[setting.danger] = true},
                EnableClassicGridSweep = true,
                EnableSkybridgePressure = true,
                EnableJunctionSwitchyard = true,
                EnableOrbitalPulse = true,
            }
            local result = ArenaMechanics.start(ctx, setting.id)
            local arena = generated:FindFirstChild("Arena")
            local mechanics = arena:FindFirstChild("Mechanics")
            expect(result.hint).toBe(base)
            expect(result.dynamicStarted).toBe(false)
            expect(mechanics:GetAttribute("MechanicHint")).toBe(base)
            expect(mechanics:GetAttribute("DynamicRouteActive")).toBe(false)
            if setting.id == "Classic" then
                expect(mechanics:FindFirstChild("GridCircuit") ~= nil).toBe(true)
                expect(mechanics:FindFirstChild("GridSweep") == nil).toBe(true)
            elseif setting.id == "Towers" then
                expect(mechanics:FindFirstChild("SkyrailSlipstream") ~= nil).toBe(true)
                expect(#ctx.OnCleanup).toBe(0)
            elseif setting.id == "Crossroads" then
                expect(mechanics:FindFirstChild("FluxRelays") ~= nil).toBe(true)
                expect(mechanics:FindFirstChild("JunctionSwitchyard") == nil).toBe(true)
            else
                expect(mechanics:FindFirstChild("HelixFlow") ~= nil).toBe(true)
                expect(ctx.HelixPulseClaims == nil).toBe(true)
            end
            generated:Destroy()

            -- No base mechanic is accidentally hidden when an optional
            -- dynamic skill actually starts in a compatible round.
            local liveMap = MapBuilder.build(Config, setting.id, ArenaVariants)
            ctx.ActiveDisasters = {Meteors = true}
            ctx.OnCleanup = {}
            ctx.Cleanup = {}
            local live = ArenaMechanics.start(ctx, setting.id)
            local liveMechanics = liveMap:FindFirstChild("Arena")
                :FindFirstChild("Mechanics")
            expect(live.hint).toBe(advanced)
            expect(live.dynamicStarted).toBe(true)
            expect(liveMechanics:GetAttribute("MechanicHint")).toBe(advanced)
            expect(liveMechanics:GetAttribute("DynamicRouteActive")).toBe(true)
            for _, cleanup in ipairs(ctx.OnCleanup) do cleanup() end
            liveMap:Destroy()
        end
        expect(ArenaMechanics.effectiveHint("Unknown", true) == nil).toBe(true)
    end)

    it("sets bounded compass-arrow detail tiers and consistent clockwise neighbors", function()
        expect(GridCircuitRules.routeChevrons("High")).toBe(3)
        expect(GridCircuitRules.routeChevrons("Medium")).toBe(2)
        expect(GridCircuitRules.routeChevrons("Low")).toBe(0)
        expect(GridCircuitRules.routeChevrons("Unknown")).toBe(0)
        for index = 1, 4 do
            local nextIndex = GridCircuitRules.next(index)
            expect(GridCircuitRules.previous(nextIndex)).toBe(index)
        end
        expect(GridCircuitRules.previous(0) == nil).toBe(true)
        expect(GridCircuitRules.previous(5) == nil).toBe(true)
    end)

    it("warns, pulses and restores nonlethal Classic floor rows in live engine", function()
        local sweep = ClassicGridSweep
        expect(sweep.indexFor(1, 0)).toBe(1)
        expect(sweep.indexFor(1, 1)).toBe(2)
        expect(sweep.indexFor(1, 4)).toBe(1)
        expect(sweep.indexFor(3, 0)).toBe(3)
        expect(sweep.allowed({
            EnableClassicGridSweep = true,
            Active = function() return true end,
            OnCleanup = {},
            ActiveDisasters = {Freeze = true},
        })).toBe(false)
        expect(sweep.allowed({
            EnableClassicGridSweep = false,
            Active = function() return true end,
            OnCleanup = {},
        })).toBe(false)

        local map = MapBuilder.build(Config, "Classic", ArenaVariants)
        local running = true
        local cleanup = {}
        local ctx = {
            EnableClassicGridSweep = true,
            Active = function() return running end,
            ActiveDisasters = {Meteors = true},
            RoundNumber = 1,
            OnCleanup = cleanup,
            Cleanup = {},
            Contestants = {},
            IsContestantActive = function() return true end,
        }
        local mechanic = ArenaMechanics.start(ctx, "Classic")
        expect(mechanic ~= nil).toBe(true)
        local arena = map:FindFirstChild("Arena")
        local mechanics = arena:FindFirstChild("Mechanics")
        local circuit = mechanics:FindFirstChild("GridCircuit")
        expect(#circuit:GetChildren()).toBe(4)
        local folder = mechanics:FindFirstChild("GridSweep")
        expect(folder ~= nil).toBe(true)
        expect(#folder:GetChildren()).toBe(4)
        expect(#cleanup).toBe(1)
        local negativeX = folder:FindFirstChild("GridSweepBand1")
        local negativeZ = folder:FindFirstChild("GridSweepBand2")
        local positiveX = folder:FindFirstChild("GridSweepBand3")
        expect(negativeX.CanCollide).toBe(false)
        expect(negativeX.CanTouch).toBe(false)
        expect(negativeX.CanQuery).toBe(false)
        expect(negativeX.Size.X < negativeX.Size.Z).toBe(true)
        expect(negativeZ.Size.Z < negativeZ.Size.X).toBe(true)
        expect(sweep.velocity(Vector3.zero, negativeX).X > 0).toBe(true)
        expect(sweep.velocity(Vector3.zero, positiveX).X < 0).toBe(true)
        expect(sweep.velocity(Vector3.zero, negativeZ).Z > 0).toBe(true)

        local bot = Instance.new("Model")
        bot.Name = "ClassicSweepRegressionBot"
        bot:SetAttribute("AISurvivor", true)
        bot:SetAttribute("AISurvivorInRound", true)
        local hum = Instance.new("Humanoid")
        hum.Parent = bot
        local body = Instance.new("Part")
        body.Name = "HumanoidRootPart"
        body.Size = Vector3.new(2, 2, 1)
        body.CanCollide = false
        body.Parent = bot
        bot.Parent = workspace
        body.Position = negativeX.Position + Vector3.new(0, 2.5, 0)
        body.AssemblyLinearVelocity = Vector3.zero
        local subject = {Character = bot}
        local once = {}

        expect(sweep.inside(body.Position, negativeX)).toBe(true)
        expect(sweep.inside(
            body.Position + Vector3.new(0, 5.5, 0), negativeX
        )).toBe(false)
        sweep.setPhase(negativeX, "Warning", workspace:GetServerTimeNow())
        expect(negativeX:GetAttribute("GridSweepPhase")).toBe("Warning")
        expect(sweep.apply(ctx, negativeX, subject, once)).toBe(false)
        sweep.setPhase(negativeX, "Pulse")
        expect(sweep.apply(ctx, negativeX, subject, once)).toBe(true)
        expect(once[subject]).toBe(true)
        expect(body.AssemblyLinearVelocity.X > 16).toBe(true)
        expect(sweep.apply(ctx, negativeX, subject, once)).toBe(false)

        -- A high platform or successful jump must never be affected.
        body.Position = negativeX.Position + Vector3.new(0, 8, 0)
        expect(sweep.apply(ctx, negativeX, subject, {})).toBe(false)
        body.Position = negativeX.Position + Vector3.new(0, 2.5, 0)
        sweep.setPhase(negativeX, nil)
        expect(sweep.apply(ctx, negativeX, subject, {})).toBe(false)

        running = false
        for _, finish in ipairs(cleanup) do finish() end
        for index = 1, 4 do
            local band = folder:FindFirstChild("GridSweepBand" .. index)
            expect(band:GetAttribute("GridSweepPhase") == nil).toBe(true)
            expect(math.abs(band.Transparency - 0.92) < 0.0001).toBe(true)
        end
        expect(arena:FindFirstChild("Base").CanCollide).toBe(true)
        bot:Destroy()
        map:Destroy()
    end)

    it("builds four welded Skyrail Slipstream checkpoints on permanent Tower bridges", function()
        local root = MapBuilder.build(Config, "Towers", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local ctx = {
            Active = function() return true end,
            IsContestantActive = function() return false end,
            Cleanup = {},
            Contestants = {},
        }
        local mechanic = ArenaMechanics.start(ctx, "Towers")
        expect(mechanic ~= nil).toBe(true)
        local folder = arena:FindFirstChild("Mechanics")
            :FindFirstChild("SkyrailSlipstream")
        expect(folder ~= nil).toBe(true)
        expect(#folder:GetChildren()).toBe(4)
        for _, sensor in ipairs(folder:GetChildren()) do
            local weld = sensor:FindFirstChild("SkyrailFollowBridge")
            expect(weld ~= nil).toBe(true)
            expect(weld.Part1).toBe(sensor)
            expect(weld.Part0:GetAttribute("ChaosSkybridge")).toBe(true)
            expect(sensor.Anchored).toBe(false)
            expect(sensor.Transparency).toBe(1)
            expect(sensor.CanCollide).toBe(false)
            expect(sensor.CanQuery).toBe(false)
            expect(sensor.CanTouch).toBe(true)
            expect((sensor.Position - (weld.Part0.CFrame
                * CFrame.new(0, weld.Part0.Size.Y * 0.5 + 2.1, 0)).Position
            ).Magnitude < 0.01).toBe(true)
        end
        -- Real engine integration: the authoritative bridge disappears
        -- together with server-authored trims, then fully restores.
        local bridge = arena:FindFirstChild("Platforms"):FindFirstChild("Skybridge18")
        local pressure = SkybridgePressure
        local snapshot = pressure.snapshot(bridge, arena:FindFirstChild("Decor"))
        expect(#snapshot.details >= 4).toBe(true)
        expect(pressure.allowed({
            Active = function() return true end,
            OnCleanup = {},
            EnableSkybridgePressure = true,
            ActiveDisasters = {ShrinkingArena = true},
        })).toBe(false)
        expect(pressure.allowed({
            Active = function() return true end,
            OnCleanup = {},
            EnableSkybridgePressure = false,
        })).toBe(false)
        pressure.setPhase(snapshot, "Warning", workspace:GetServerTimeNow())
        expect(bridge:GetAttribute("CollapsePhase")).toBe("Warning")
        expect(bridge.CanCollide).toBe(true)
        expect(bridge.Material).toBe(Enum.Material.Neon)
        pressure.setPhase(snapshot, "Gone")
        expect(bridge.CanCollide).toBe(false)
        expect(bridge.Transparency).toBe(1)
        for _, entry in ipairs(snapshot.details) do
            expect(entry.part.Transparency).toBe(1)
        end
        pressure.setPhase(snapshot, nil)
        expect(bridge:GetAttribute("CollapsePhase") == nil).toBe(true)
        expect(bridge.CanCollide).toBe(snapshot.canCollide)
        expect(bridge.Material).toBe(snapshot.material)
        expect(bridge.Color).toBe(snapshot.color)
        for _, entry in ipairs(snapshot.details) do
            expect(entry.part.Transparency).toBe(entry.transparency)
        end
        root:Destroy()
    end)

    it("authorizes a running survivor bot once, not an outsider or repeated touch", function()
        local rootMap = MapBuilder.build(Config, "Towers", ArenaVariants)
        local arena = rootMap:FindFirstChild("Arena")
        local ctx = {
            Active = function() return true end,
            IsContestantActive = function() return false end,
            Cleanup = {},
            Contestants = {},
        }
        ArenaMechanics.start(ctx, "Towers")
        local sensor = arena:FindFirstChild("Mechanics")
            :FindFirstChild("SkyrailSlipstream")
            :FindFirstChild("SkyrailSlipstreamTriggerSkybridge18")
        expect(sensor ~= nil).toBe(true)
        local bridge = arena:FindFirstChild("Platforms")
            :FindFirstChild("Skybridge18")
        expect(bridge ~= nil).toBe(true)

        local bot = Instance.new("Model")
        bot.Name = "SkyrailRegressionBot"
        bot:SetAttribute("AISurvivor", true)
        bot:SetAttribute("AISurvivorInRound", true)
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = bot
        local body = Instance.new("Part")
        body.Name = "HumanoidRootPart"
        body.Size = Vector3.new(2, 2, 1)
        body.Anchored = false
        body.CanCollide = false
        body.Parent = bot
        bot.Parent = workspace
        body.CFrame = sensor.CFrame
        local along = bridge.Size.X > bridge.Size.Z
            and bridge.CFrame.RightVector or bridge.CFrame.LookVector
        body.AssemblyLinearVelocity = along * 17

        local cooldown = {}
        expect(SkyrailSlipstream.tryTrigger(
            ctx, sensor, bridge, body, cooldown, 10
        )).toBe(true)
        expect(type(sensor:GetAttribute("SkyrailUsedAt"))).toBe("number")
        expect(type(bridge:GetAttribute("SkyrailUsedAt"))).toBe("number")
        expect(sensor:GetAttribute("SkyrailFlowTier")).toBe(1)
        expect(ctx.SkyrailChainStates[bot].tier).toBe(1)
        expect(bridge:GetAttribute("SkyrailRunDirection")).toBe(1)
        expect(sensor:GetAttribute("SkyrailRunDirection")).toBe(1)
        expect((cooldown[bot] or 0) > 14).toBe(true)
        expect(SkyrailSlipstream.tryTrigger(
            ctx, sensor, bridge, body, cooldown, 11
        )).toBe(false)

        bot:SetAttribute("AISurvivorInRound", false)
        expect(SkyrailSlipstream.tryTrigger(
            ctx, sensor, bridge, body, cooldown, 20
        )).toBe(false)
        bot:Destroy()
        rootMap:Destroy()
    end)

    it("scales Skyrail impulse by physical bridge span and ranks only different crossings", function()
        local r = SkyrailSlipstream
        expect(r.boostForSpan(49, 0)).toBe(12)
        expect(r.boostForSpan(18, 0) < 4).toBe(true)
        expect(r.boostForSpan(18, 0) > 2).toBe(true)
        expect(r.boostForSpan(18, 7)).toBe(0)
        expect(r.boostForSpan(18, 7, 1)).toBe(0)
        expect(r.boostForSpan(18, 7, -1) > 7).toBe(true)
        expect(r.boostForSpan(18, 7, -1) < 8).toBe(true)
        expect(r.boostForSpan(4, 0)).toBe(0)
        expect(r.boostForSpan(nil, 0)).toBe(0)
        expect(r.ComboCap).toBe(3)
        local first, good = r.advanceChain(nil, "Skybridge18", 10)
        expect(good).toBe(true)
        expect(first.tier).toBe(1)
        local again, repeated = r.advanceChain(first, "Skybridge18", 15)
        expect(repeated).toBe(false)
        expect(again).toBe(first)
        local second = r.advanceChain(first, "Skybridge19", 19)
        expect(second.tier).toBe(2)
        local replay, replayAdvanced = r.advanceChain(second, "Skybridge18", 21)
        expect(replayAdvanced).toBe(false)
        expect(replay).toBe(second)
        expect(replay.at).toBe(19)
        local third = r.advanceChain(second, "Skybridge20", 24)
        expect(third.tier).toBe(3)
        local capped, capAdvanced = r.advanceChain(third, "Skybridge21", 25)
        expect(capped.tier).toBe(3)
        expect(capAdvanced).toBe(false)
        expect(capped.visited.Skybridge18).toBe(true)
        expect(capped.visited.Skybridge21).toBe(true)
        local sameState = r.advanceChain(capped, "Skybridge21", 26)
        expect(sameState).toBe(capped)
        local expiredReplay = r.advanceChain(second, "Skybridge18", 40)
        expect(expiredReplay.tier).toBe(1)
        local expired = r.advanceChain(second, "Skybridge20", 40)
        expect(expired.tier).toBe(1)
        expect(r.advanceChain(nil, "Unknown", 10) == nil).toBe(true)
        expect(r.advanceChain(nil, "Skybridge18", nil) == nil).toBe(true)
        local short = r.velocity(Vector3.new(17, 3, 0),
            Vector3.xAxis, r.boostForSpan(18, 0))
        expect(short.X > 19).toBe(true)
        expect(short.X < 22).toBe(true)
    end)

    it("limits Skyrail impulse speed and rejects off-axis or stationary movement", function()
        local x = Instance.new("Part")
        x.Size = Vector3.new(49, 1, 4.5)
        local z = Instance.new("Part")
        z.Size = Vector3.new(4.5, 1, 49)
        expect(SkyrailSlipstream.direction(x, Vector3.new(15, 0, 0))).toBe(Vector3.xAxis)
        expect(SkyrailSlipstream.direction(x, Vector3.new(-15, 0, 0))).toBe(-Vector3.xAxis)
        expect(SkyrailSlipstream.direction(x, Vector3.new(0, 0, 18)) == nil).toBe(true)
        expect(SkyrailSlipstream.direction(x, Vector3.new(6, 0, 0)) == nil).toBe(true)
        local direction = SkyrailSlipstream.direction(z, Vector3.new(0, 0, -18))
        expect(direction ~= nil).toBe(true)
        expect(math.abs(direction.Z)).toBe(1)
        local nextVelocity = SkyrailSlipstream.velocity(
            Vector3.new(38, 15, 0), Vector3.xAxis
        )
        expect(nextVelocity.X).toBe(42)
        expect(nextVelocity.Y).toBe(15)
        expect(SkyrailSlipstream.Cooldown >= 4).toBe(true)
        x:Destroy()
        z:Destroy()
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

    it("lets in-round AI complete Grid Circuit with no human rewards", function()
        local generated = MapBuilder.build(Config, "Classic", ArenaVariants)
        local arena = generated:FindFirstChild("Arena")
        local mechanics = Instance.new("Folder")
        mechanics.Name = "Mechanics"
        mechanics.Parent = arena

        local credited = 0
        local ctx = {
            Active = function() return true end,
            IsContestantActive = function() return false end,
            Contestants = {},
            OnArenaMechanicUsed = function()
                credited += 1
            end,
        }
        local nodes = GridCircuitService.start(ctx, mechanics, Config.ArenaCenter)
        expect(nodes ~= nil).toBe(true)

        local bot = Instance.new("Model")
        bot.Name = "ClassicGridCircuitBot"
        bot:SetAttribute("AISurvivor", true)
        bot:SetAttribute("AISurvivorInRound", true)
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = bot
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.Anchored = true
        root.Parent = bot
        bot.Parent = workspace

        local state = {}
        local ready = {}
        for i = 1, 4 do
            local sensor = nodes:FindFirstChild("GridCircuitNode" .. i)
            expect(sensor ~= nil).toBe(true)
            root.Position = sensor.Position
            expect(GridCircuitService.tryTouch(ctx, sensor, root, state,
                ready, i * 2, 100 + i * 2)).toBe(true)
            expect(bot:GetAttribute("GridCircuitStep")).toBe(i)
            if i < 4 then
                expect(bot:GetAttribute("GridCircuitNext")).toBe(i + 1)
            end
        end
        expect(bot:GetAttribute("GridCircuitComplete")).toBe(true)
        expect(credited).toBe(0)

        -- A dead or out-of-round NPC cannot claim a second completion.
        bot:SetAttribute("AISurvivorInRound", false)
        local first = nodes:FindFirstChild("GridCircuitNode1")
        root.Position = first.Position
        expect(GridCircuitService.tryTouch(ctx, first, root, state,
            ready, 20, 120)).toBe(false)

        bot:Destroy()
        generated:Destroy()
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
        expect(first:GetAttribute("FluxWeaveTier")).toBe(1)
        expect(ctx.FluxWeaveStates[bot].tier).toBe(1)
        expect(CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 11, epoch + 0.6, Config.ArenaCenter)).toBe(false)
        hit.Position = second.Position
        expect(CrossroadsFluxRelay.tryTrigger(ctx, second, hit,
            ready, epoch, 14, epoch + 4.5, Config.ArenaCenter)).toBe(true)
        expect(second:GetAttribute("FluxWeaveTier")).toBe(2)
        expect(ctx.FluxWeaveStates[bot].tier).toBe(2)
        hit.Position = first.Position
        bot:SetAttribute("AISurvivorInRound", false)
        expect(CrossroadsFluxRelay.tryTrigger(ctx, first, hit,
            ready, epoch, 22, epoch + 8.5, Config.ArenaCenter)).toBe(false)
        expect(#events).toBe(0)

        bot:Destroy()
        root:Destroy()
    end)

    it("runs a real Crossroads junction with intentional sideways steering", function()
        local rules = CrossroadsSwitchyard
        expect(rules.pair(1, 0)).toBe(1)
        expect(rules.pair(1, 1)).toBe(0)
        expect(rules.pair(2, 0)).toBe(0)
        expect(rules.activeLane(1, 1)).toBe(true)
        expect(rules.activeLane(3, 1)).toBe(true)
        expect(rules.activeLane(2, 1)).toBe(false)
        expect(rules.activeLane(4, 0)).toBe(true)

        local xAxis = Vector3.xAxis
        local forward = rules.tangentVelocity(
            Vector3.new(-9, 0, 13), xAxis
        )
        expect(forward).toBe(Vector3.zAxis)
        expect(rules.tangentVelocity(
            Vector3.new(-40, 0, 2), xAxis) == nil).toBe(true)
        expect(rules.tangentVelocity(
            Vector3.new(-7, 0, 3), xAxis) == nil).toBe(true)
        expect(rules.tangentVelocity(
            Vector3.new(0, 0, -13), xAxis)).toBe(-Vector3.zAxis)
        expect(rules.tangentVelocity(
            Vector3.new(13, 0, 0), Vector3.zAxis)).toBe(Vector3.xAxis)
        local launched = rules.velocity(
            Vector3.new(-9, 4, 13), forward
        )
        expect(launched.Z > 32).toBe(true)
        expect(launched.Y).toBe(4)
        local capped = rules.velocity(
            Vector3.new(30, 95, 80), Vector3.zAxis
        )
        expect(Vector3.new(capped.X, 0, capped.Z).Magnitude <= 48.01).toBe(true)
        expect(capped.Y).toBe(58)

        local map = MapBuilder.build(Config, "Crossroads", ArenaVariants)
        local enabled = true
        local cleanups = {}
        local ctx = {
            Active = function() return enabled end,
            EnableJunctionSwitchyard = true,
            RoundNumber = 1,
            Cleanup = {},
            OnCleanup = cleanups,
            IsContestantActive = function() return false end,
        }
        ArenaMechanics.start(ctx, "Crossroads")
        local arena = map:FindFirstChild("Arena")
        local mechanics = arena:FindFirstChild("Mechanics")
        local switches = mechanics:FindFirstChild("JunctionSwitchyard")
        expect(switches ~= nil).toBe(true)
        local pads = {}
        for index = 1, 4 do
            local pad = switches:FindFirstChild("JunctionSwitch" .. index)
            expect(pad ~= nil).toBe(true)
            expect(pad.CanCollide).toBe(false)
            expect(pad.CanTouch).toBe(true)
            expect(pad.Transparency).toBe(1)
            expect(pad:GetAttribute("JunctionActive")).toBe(index % 2 == 1)
            local marker = switches:FindFirstChild("JunctionRouteSign" .. index)
            expect(marker.Enabled).toBe(index % 2 == 1)
            pads[index] = pad
        end

        local bot = Instance.new("Model")
        bot.Name = "JunctionRegressionBot"
        bot:SetAttribute("AISurvivor", true)
        bot:SetAttribute("AISurvivorInRound", true)
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = bot
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.Anchored = false
        root.CanCollide = false
        root.Parent = bot
        bot.Parent = workspace
        root.Position = pads[1].Position
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 13)
        local ready = {}
        local claimed = {}
        expect(rules.tryTrigger(ctx, pads[2], root, ready, claimed, 10)).toBe(false)
        expect(rules.tryTrigger(ctx, pads[1], root, ready, claimed, 10)).toBe(true)
        expect(claimed[bot][1]).toBe(true)
        expect(root.AssemblyLinearVelocity.Z > 30).toBe(true)
        expect(type(pads[1]:GetAttribute("JunctionTriggeredAt"))).toBe("number")
        expect(rules.tryTrigger(ctx, pads[1], root, ready, claimed, 20)).toBe(false)

        root.Position = pads[3].Position + Vector3.new(18, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, -13)
        expect(rules.tryTrigger(ctx, pads[3], root, ready, claimed, 24)).toBe(false)
        root.Position = pads[3].Position
        expect(rules.tryTrigger(ctx, pads[3], root, ready, claimed, 24)).toBe(true)
        expect(claimed[bot][3]).toBe(true)

        enabled = false
        for _, cleanup in ipairs(cleanups) do cleanup() end
        for index, pad in ipairs(pads) do
            expect(pad:GetAttribute("JunctionActive") == nil).toBe(true)
            expect(switches:FindFirstChild("JunctionRouteSign" .. index).Enabled)
                .toBe(false)
        end
        expect(rules.tryTrigger(ctx, pads[1], root, ready, claimed, 40)).toBe(false)
        bot:Destroy()
        map:Destroy()
    end)

    it("requires alternating Flux Relay pairs and three unique gates for Flux Master", function()
        local r = FluxRelayRules
        expect(r.WeaveCap).toBe(3)
        expect(r.WeaveWindow >= 8).toBe(true)
        local first, yes = r.advanceWeave(nil, 1, 10)
        expect(yes).toBe(true)
        expect(first.tier).toBe(1)
        expect(first.visited[1]).toBe(true)
        expect(r.nextParity(first)).toBe(0)
        expect(r.nextParity(nil)).toBe(-1)
        expect(r.displayProgress(0, 0, 110)).toBe(0)
        local activeRank, seconds = r.displayProgress(2, 122, 116.1)
        expect(activeRank).toBe(2)
        expect(seconds).toBe(6)
        local expiredRank, expiredSeconds = r.displayProgress(2, 122, 123)
        expect(expiredRank).toBe(0)
        expect(expiredSeconds).toBe(0)
        local masterRank, masterSeconds = r.displayProgress(3, 0, 140)
        expect(masterRank).toBe(3)
        expect(masterSeconds).toBe(0)
        expect(r.displayProgress(1, nil, 144)).toBe(0)
        local same, no = r.advanceWeave(first, 3, 11)
        expect(no).toBe(false)
        expect(same).toBe(first)
        local second, yes2 = r.advanceWeave(first, 2, 15)
        expect(yes2).toBe(true)
        expect(second.tier).toBe(2)
        expect(r.nextParity(second)).toBe(1)
        local repeatOld, oldAdvanced = r.advanceWeave(second, 1, 18)
        expect(oldAdvanced).toBe(false)
        expect(repeatOld).toBe(second)
        local repeatPair, pairAdvanced = r.advanceWeave(second, 4, 18)
        expect(pairAdvanced).toBe(false)
        expect(repeatPair).toBe(second)
        local third, yes3 = r.advanceWeave(second, 3, 19)
        expect(yes3).toBe(true)
        expect(third.tier).toBe(3)
        expect(r.nextParity(third)).toBe(-1)
        expect(third.visited[1] and third.visited[2] and third.visited[3]).toBe(true)
        local capped, beyond = r.advanceWeave(third, 4, 20)
        expect(beyond).toBe(false)
        expect(capped).toBe(third)
        local expired = r.advanceWeave(second, 1, 28)
        expect(expired.tier).toBe(1)
        expect(expired.lane).toBe(1)
        expect(r.advanceWeave(nil, 0, 3) == nil).toBe(true)
        expect(r.advanceWeave(nil, 5, 3) == nil).toBe(true)
        expect(r.advanceWeave(nil, 1, nil) == nil).toBe(true)
    end)

    it("advances Helix mastery across different lanes without farming one ramp", function()
        local r = OrbitalHelix
        expect(r.ChainCap).toBe(3)
        expect(r.ChainWindow > 2 * r.FlowCooldown).toBe(true)
        expect(r.pulsePair(1, 0)).toBe(1)
        expect(r.pulsePair(1, 1)).toBe(2)
        expect(r.pulsePair(5, 0)).toBe(1)
        expect(r.pulsePair(3, 3)).toBe(2)
        expect(r.pulseActive(1, 1)).toBe(true)
        expect(r.pulseActive(5, 1)).toBe(true)
        expect(r.pulseActive(2, 1)).toBe(false)
        expect(r.pulseActive(0, 1)).toBe(false)
        local boosted = r.pulseVelocity(
            Vector3.new(18, 4, 0), Vector3.xAxis
        )
        expect(boosted.X > 24 and boosted.X < 26).toBe(true)
        expect(boosted.Y).toBe(4)
        local bounded = r.pulseVelocity(
            Vector3.new(80, 76, 0), Vector3.xAxis
        )
        expect(bounded.X <= r.PulseSpeedCap).toBe(true)
        expect(bounded.Y).toBe(58)

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

        -- Rebuild a real Orbital map with the optional live pulse enabled;
        -- its ordinary Flow sensors should still have exactly eight lanes.
        root:Destroy()
        bot:SetAttribute("AISurvivorInRound", true)
        local pulseMap = MapBuilder.build(Config, "Orbital", ArenaVariants)
        local pulseArena = pulseMap:FindFirstChild("Arena")
        local live = true
        local pulseCtx = {
            Active = function() return live end,
            IsContestantActive = function() return false end,
            EnableOrbitalPulse = true,
            RoundNumber = 5,
            Cleanup = {},
            OnCleanup = {},
            OnArenaMechanicUsed = function()
                mechanicUses += 1
            end,
        }
        ArenaMechanics.start(pulseCtx, "Orbital")
        local pulseRamps = pulseArena:FindFirstChild("HelixCircuit")
        local pulseFlow = pulseArena:FindFirstChild("Mechanics")
            :FindFirstChild("HelixFlow")
        expect(#(pulseFlow :: Folder):GetChildren()).toBe(8)
        for lane = 1, 8 do
            local charged = lane == 1 or lane == 5
            expect(pulseRamps:FindFirstChild("HelixRamp" .. lane)
                :GetAttribute("HelixPulseActive")).toBe(charged)
            expect(pulseFlow:FindFirstChild("HelixFlowTrigger" .. lane)
                :GetAttribute("HelixPulseActive")).toBe(charged)
        end
        local trigger = pulseFlow:FindFirstChild("HelixFlowTrigger1")
        local activeRamp = pulseRamps:FindFirstChild("HelixRamp1")
        body.CFrame = trigger.CFrame
        body.AssemblyLinearVelocity = activeRamp.CFrame.LookVector * 17
        local pulseReady = {}
        expect(OrbitalHelix.tryFlow(
            pulseCtx, trigger, body, pulseReady, 30
        )).toBe(true)
        expect(trigger:GetAttribute("HelixPulseAward")).toBe(true)
        expect(body.AssemblyLinearVelocity.Magnitude > 22).toBe(true)
        expect(pulseCtx.HelixPulseClaims[bot][1]).toBe(true)
        body.AssemblyLinearVelocity = activeRamp.CFrame.LookVector * 17
        expect(OrbitalHelix.tryFlow(
            pulseCtx, trigger, body, pulseReady, 35
        )).toBe(true)
        expect(trigger:GetAttribute("HelixPulseAward")).toBe(false)
        expect(body.AssemblyLinearVelocity.Magnitude < 19).toBe(true)

        local idleTrigger = pulseFlow:FindFirstChild("HelixFlowTrigger2")
        local idleRamp = pulseRamps:FindFirstChild("HelixRamp2")
        body.CFrame = idleTrigger.CFrame
        body.AssemblyLinearVelocity = idleRamp.CFrame.LookVector * 17
        expect(OrbitalHelix.tryFlow(
            pulseCtx, idleTrigger, body, pulseReady, 41
        )).toBe(true)
        expect(idleTrigger:GetAttribute("HelixPulseAward")).toBe(false)

        live = false
        for _, cleanup in ipairs(pulseCtx.OnCleanup) do cleanup() end
        for lane = 1, 8 do
            expect(pulseRamps:FindFirstChild("HelixRamp" .. lane)
                :GetAttribute("HelixPulseActive") == nil).toBe(true)
            expect(pulseFlow:FindFirstChild("HelixFlowTrigger" .. lane)
                :GetAttribute("HelixPulseActive") == nil).toBe(true)
        end
        expect(activeRamp.CanCollide).toBe(true)
        bot:Destroy()
        pulseMap:Destroy()
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

    it("builds usable, server-owned two-way district transit in all four live arenas", function()
        local human = Instance.new("Humanoid")
        local root = Instance.new("Part")
        root.Size = Vector3.new(2, 2, 1)
        for _, id in ipairs(ArenaVariants.Order) do
            local map = MapBuilder.build(Config, id, ArenaVariants)
            local arena = map:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local cleanup = {}
            local ctx = {
                Active = function() return true end,
                EnableDistrictTransit = true,
                IsContestantActive = function() return true end,
                ActiveDisasters = {Meteors = true},
                Cleanup = cleanup,
            }
            expect(ArenaDistrictTransit.start(ctx)).toBe(8)
            local folder = arena:FindFirstChild("DistrictTransit")
            expect(folder ~= nil and folder:IsA("Folder")).toBe(true)
            expect(folder:GetAttribute("ServerAuthoritative")).toBe(true)
            expect(folder:GetAttribute("TransitStationCount")).toBe(8)
            for route = 1, 4 do
                for _, outer in ipairs({false, true}) do
                    local name = "Transit" .. route .. (outer and "Outer" or "Hub")
                    local station = folder:FindFirstChild(name)
                    expect(station ~= nil and station:IsA("Model")).toBe(true)
                    expect(station:GetAttribute("TransitRoute")).toBe(route)
                    expect(station:GetAttribute("TransitOuter")).toBe(outer)
                    local headerPart = station:FindFirstChild("TransitHeader")
                    expect(headerPart ~= nil).toBe(true)
                    local prompt = headerPart:FindFirstChildWhichIsA("ProximityPrompt")
                    expect(prompt ~= nil).toBe(true)
                    expect(prompt.HoldDuration >= 0.4).toBe(true)
                    for _, item in ipairs(station:GetDescendants()) do
                        if item:IsA("BasePart") then
                            expect(item.CanCollide).toBe(false)
                            expect(item.CanQuery).toBe(false)
                            expect(item.CanTouch).toBe(false)
                        end
                    end
                    local arrival = ArenaDistrictTransit.arrival(
                        arena, base, route, outer, human, root
                    )
                    expect(arrival ~= nil).toBe(true)
                    if arrival then
                        local edge = base.Size.X * 0.5
                        expect(math.abs(arrival.X - base.Position.X)
                            < edge - 4).toBe(true)
                        expect(math.abs(arrival.Z - base.Position.Z)
                            < edge - 4).toBe(true)
                    end
                end
            end
            for _, disposable in ipairs(cleanup) do
                if disposable.Parent then disposable:Destroy() end
            end
            map:Destroy()
        end
        local inactive = {
            Active = function() return true end,
            EnableDistrictTransit = true,
            IsContestantActive = function() return true end,
            ActiveDisasters = {ShrinkingArena = true},
        }
        expect(ArenaDistrictTransit.allowed(inactive)).toBe(false)
        inactive.ActiveDisasters = {}
        inactive.EnableDistrictTransit = false
        expect(ArenaDistrictTransit.allowed(inactive)).toBe(false)
        root:Destroy()
        human:Destroy()
    end)

    it("builds optional timed signal objectives in four real Roblox arena layouts", function()
        for _, variantId in ipairs(ArenaVariants.Order) do
            local map = MapBuilder.build(Config, variantId, ArenaVariants)
            local arena = map:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local live = true
            local cleanup = {}
            local ctx = {
                Active = function() return live end,
                EnableDistrictSignals = true,
                ActiveDisasters = {Meteors = true},
                RoundSeconds = 35,
                Cleanup = cleanup,
                IsContestantActive = function() return true end,
                OnDistrictSignalClaimed = function() return true end,
            }
            expect(DistrictSignalRush.allowed(ctx, base)).toBe(true)
            expect(DistrictSignalRush.start(ctx)).toBe(4)
            local folder = arena:FindFirstChild("DistrictSignalRush")
            expect(folder ~= nil and folder:IsA("Folder")).toBe(true)
            expect(folder:GetAttribute("SignalReward")).toBe(2)
            expect(folder:GetAttribute("SignalRoute")).toBe(0)
            expect(#folder:GetChildren()).toBe(4)
            for route = 1, 4 do
                local station = folder:FindFirstChild("SignalStation" .. route)
                expect(station ~= nil and station:IsA("Model")).toBe(true)
                expect(station:GetAttribute("SignalRoute")).toBe(route)
                expect(station:GetAttribute("SignalActive")).toBe(false)
                expect(station.ModelStreamingMode).toBe(
                    Enum.ModelStreamingMode.Atomic)
                local spine = station:FindFirstChild("BeaconSpine")
                expect(spine ~= nil and spine:IsA("BasePart")).toBe(true)
                local prompt = spine:FindFirstChild("SecureDistrictSignal")
                expect(prompt ~= nil and prompt:IsA("ProximityPrompt")).toBe(true)
                expect(prompt.Enabled).toBe(false)
                expect(prompt.MaxActivationDistance <= 10).toBe(true)
                for _, part in ipairs(station:GetDescendants()) do
                    if part:IsA("BasePart") then
                        expect(part.CanCollide).toBe(false)
                        expect(part.CanTouch).toBe(false)
                        expect(part.CanQuery).toBe(false)
                        local x = math.abs(part.Position.X - base.Position.X)
                        local z = math.abs(part.Position.Z - base.Position.Z)
                        expect(x < base.Size.X * 0.5 - 10).toBe(true)
                        expect(z < base.Size.Z * 0.5 - 10).toBe(true)
                    end
                end
            end
            live = false
            for _, item in ipairs(cleanup) do
                if item.Parent then item:Destroy() end
            end
            map:Destroy()
        end
        local arenaMap = MapBuilder.build(Config, "Classic", ArenaVariants)
        local base = arenaMap:FindFirstChild("Arena"):FindFirstChild("Base")
        local ctx = {
            Active = function() return true end,
            EnableDistrictSignals = true,
            RoundSeconds = 35,
            ActiveDisasters = {ShrinkingArena = true},
            IsContestantActive = function() return true end,
            OnDistrictSignalClaimed = function() return true end,
        }
        expect(DistrictSignalRush.allowed(ctx, base)).toBe(false)
        ctx.ActiveDisasters = {}
        ctx.RoundSeconds = 20
        expect(DistrictSignalRush.allowed(ctx, base)).toBe(false)
        ctx.RoundSeconds = 35
        ctx.EnableDistrictSignals = false
        expect(DistrictSignalRush.allowed(ctx, base)).toBe(false)
        arenaMap:Destroy()
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
