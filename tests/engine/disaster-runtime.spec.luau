--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local DisasterBalance = require("../../src/server/DisasterBalance")
local MovementSafety = require("../../src/server/MovementSafety")
local ArenaTargeting = require("../../src/server/ArenaTargeting")
local ImpactWaveDirector = require("../../src/server/ImpactWaveDirector")
local RisingLava = require("../../src/server/Disasters/RisingLava")
local Tornado = require("../../src/server/Disasters/Tornado")

local Meteors = require("../../src/server/Disasters/Meteors")
local Bombs = require("../../src/server/Disasters/Bombs")

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

describe("Rising Lava walkable high-ground fairness", function()
    it("preserves four real high refuges in all four shipped arenas", function()
        for _, variantId in ipairs(ArenaVariants.Order) do
            local definition = ArenaVariants.get(variantId)
            local topHeights = {}
            for _, deck in ipairs(definition.Platforms) do
                topHeights[#topHeights + 1] = deck.offset.Y + deck.size.Y * 0.5
            end
            local distance = RisingLava.safeRiseDistance(-6, topHeights, 25)
            expect(distance > 0 and distance <= 25).toBe(true)
            local finalSurface = -6 + distance
            local safeDecks = 0
            local submergedLower = 0
            for _, top in ipairs(topHeights) do
                if top - finalSurface >= 2 - 0.001 then
                    safeDecks += 1
                elseif top < finalSurface then
                    submergedLower += 1
                end
            end
            expect(safeDecks >= 4).toBe(true)
            expect(submergedLower >= 1).toBe(true)
        end
    end)

    it("clamps the final lava height and rejects invalid deck measurements", function()
        local rise = RisingLava.safeRiseDistance
        expect(rise(-6, {12, 12, 12, 12}, 25)).toBe(16)
        expect(rise(-6, {30, 30, 30, 30}, 25)).toBe(25)
        expect(rise(-6, {5, 5, 5, 5}, 25)).toBe(9)
        expect(rise(-6, nil, 25)).toBe(15)
        expect(rise(-6, {math.huge, 12, 12, 12, 12}, 25)).toBe(16)
        expect(rise(-6, {0 / 0, 12, 12, 12, 12}, 25)).toBe(16)
        expect(rise(-6, {-10, -10, -10, -10}, 25)).toBe(0)
        expect(rise(-6, {12, 12, 12, 12}, -10)).toBe(0)
    end)
end)

describe("Veteran lava surge fairness", function()
    it("keeps novice lava linear and advanced lava continuous at the same final height", function()
        local rise = RisingLava.riseAt
        for _, t in ipairs({0, 0.3, 3.8, 9.7, 15, 19, 25, 35, 40}) do
            local fraction, stage = rise(t, 40, false)
            expect(math.abs(fraction - math.clamp(t / 40, 0, 1)) < 0.0001)
                .toBe(true)
            expect(stage == nil).toBe(true)
        end
        local early, climb = rise(0, 40, true)
        expect(early).toBe(0)
        expect(climb).toBe("Climb")
        local announce, soon = rise(12, 40, true)
        expect(soon).toBe("SurgeSoon")
        expect(math.abs(announce - (0.30 * 0.28 / 0.38)) < 0.0001)
            .toBe(true)
        local startSurge, surge = rise(40 * 0.38, 40, true)
        expect(math.abs(startSurge - 0.28) < 0.0001).toBe(true)
        expect(surge).toBe("Surge")
        local endSurge, last = rise(40 * 0.62, 40, true)
        expect(math.abs(endSurge - 0.70) < 0.0001).toBe(true)
        expect(last).toBe("FinalRise")
        local done = rise(40, 40, true)
        expect(done).toBe(1)
        local previous = -1
        for i = 0, 100 do
            local fraction = rise(i * 0.4, 40, true)
            expect(fraction >= previous and fraction <= 1).toBe(true)
            previous = fraction
        end
        expect(rise(-40, 40, true)).toBe(0)
        expect(rise(400, 40, true)).toBe(1)
        expect(rise(math.huge, 40, true)).toBe(0)
        expect(rise(0 / 0, 40, true)).toBe(0)
    end)
end)

describe("Freeze Pulse ownership and cleanup", function()
    it("restores previous frozen marker without erasing later state changes", function()
        local freeze = require("../../src/server/Disasters/Freeze")
        expect(freeze.restoredFrozenMarker(true, nil)).toBe(nil)
        expect(freeze.restoredFrozenMarker(true, false)).toBe(false)
        expect(freeze.restoredFrozenMarker(true, true)).toBe(true)
        expect(freeze.restoredFrozenMarker(false, true)).toBe(false)
        expect(freeze.restoredFrozenMarker(nil, true)).toBe(nil)
    end)
end)

describe("Real-engine evolving impact storms", function()
    it("spawns physical meteor/bomb telegraphs on forecast sweep and flank routes", function()
        for _, case in ipairs({
            {id = "Meteors", source = Meteors, marker = "MeteorWarning",
                profile = {MeteorWarningSeconds = 0.25, MeteorRadius = 8}},
            {id = "Bombs", source = Bombs, marker = "BombWarning",
                profile = {BombWarningSeconds = 0.25, BombRadius = 8}},
        }) do
            local map = MapBuilder.build(Config, "Classic", ArenaVariants)
            local active = true
            local cleanup = {}
            local startedAt = os.clock() - 20
            local ctx = {
                Config = Config,
                Cleanup = cleanup,
                Active = function() return active end,
                RoundStartedAt = startedAt,
                RoundSeconds = 40,
                RoundEndsAt = os.clock() + 2.5,
                RoundNumber = 5,
                EnableImpactWaves = true,
                BalanceProfile = case.profile,
                Contestants = {},
                HazardContestants = {},
            }
            local ok, err = pcall(case.source.start, ctx)
            expect(ok).toBe(true)
            local marker = nil
            local deadline = os.clock() + 0.85
            repeat
                marker = workspace:FindFirstChild(case.marker)
                -- Bomb Rain configures its authoritative warning in a
                -- separate spawned task. Wait for the full metadata bundle,
                -- not merely the existence of the initial 3D marker.
                if marker and marker:GetAttribute("WarningEndSize") ~= nil then
                    break
                end
                task.wait(0.02)
            until os.clock() >= deadline

            expect(marker ~= nil).toBe(true)
            if marker then
                expect(marker:GetAttribute("ImpactWaveMode")).toBe("Sweep")
                expect(marker:GetAttribute("WarningKind")).toBe(
                    case.id == "Meteors" and "Meteor" or "Bomb"
                )
                local hx, hz = ArenaTargeting.activeHalfExtents(6, 42)
                local planned = ImpactWaveDirector.anchor(
                    "Sweep", 1, 5, case.id, hx, hz
                )
                local actual = marker.Position - Config.ArenaCenter
                    - Vector3.new(0, 1.2, 0)
                expect((actual - planned).Magnitude < 0.1).toBe(true)
                -- The authored route changes only the X/Z target, not
                -- the warning lifetime, radius or server-owned damage.
                expect(marker:GetAttribute("WarningEndSize")).toBe(16)
            end

            active = false
            runCleanup(cleanup, {})
            if map and map.Parent then map:Destroy() end
            local generated = workspace:FindFirstChild("GeneratedMap")
            if generated then generated:Destroy() end
            if not ok then error(tostring(err)) end
        end
    end)

    it("retains separated warning placement under cross-disaster overlap", function()
        MapBuilder.build(Config, "Classic", ArenaVariants)
        local hx, hz = ArenaTargeting.activeHalfExtents(6, 42)
        local ctx = {
            Config = Config,
            RoundStartedAt = os.clock() - 30,
            RoundSeconds = 40,
            RoundNumber = 5,
            EnableImpactWaves = true,
        }
        local pending = {}
        local first, mode = ArenaTargeting.evolvingImpactOffset(
            ctx, "Meteors", 1, pending, 6, 42, 22
        )
        expect(mode).toBe("Flanks")
        expect(math.abs(first.X) <= hx and math.abs(first.Z) <= hz)
            .toBe(true)
        local marker = Instance.new("Part")
        marker.Position = Config.ArenaCenter + first
        marker.Parent = workspace
        pending[marker] = true
        local second, pairedMode = ArenaTargeting.evolvingImpactOffset(
            ctx, "Bombs", 1, pending, 6, 42, 22
        )
        expect(pairedMode).toBe("Flanks")
        expect(Vector3.new(second.X - first.X, 0, second.Z - first.Z)
            .Magnitude >= 21.99).toBe(true)
        marker:Destroy()
        local generated = workspace:FindFirstChild("GeneratedMap")
        if generated then generated:Destroy() end
    end)
end)

describe("Round-end lethal warning safety", function()
    it("only starts meteors and bombs with enough time for visible warning and damage", function()
        local deadline = {RoundEndsAt = 30}
        expect(Meteors.canComplete(deadline, 27, 1.05, 0.5)).toBe(true)
        expect(Meteors.canComplete(deadline, 28.3, 1.05, 0.5)).toBe(false)
        expect(Bombs.canComplete(deadline, 27.5, 1.45, 0)).toBe(true)
        expect(Bombs.canComplete(deadline, 28.4, 1.45, 0)).toBe(false)
        expect(Meteors.canComplete({}, 999, 1.05, 0.5)).toBe(true)
        expect(Bombs.canComplete({}, 999, 1.45, 0)).toBe(true)
    end)
end)

describe("Collapsing platform visual truth", function()
    it("unlocks fair synchronized two-deck waves only after the advanced-round midpoint", function()
        local D = require("../../src/server/Disasters/DisappearingPlatforms")
        local ctx = {
            EnableCollapseWaves = true,
            RoundStartedAt = 100,
            RoundSeconds = 40,
        }
        expect(D.waveSize(ctx, 8, 119)).toBe(1)
        expect(D.waveSize(ctx, 8, 121)).toBe(1)
        expect(D.waveSize(ctx, 8, 123)).toBe(2)
        expect(D.waveSize(ctx, 7, 123)).toBe(1)
        expect(D.waveSize({
            EnableCollapseWaves = false,
            RoundStartedAt = 100, RoundSeconds = 40,
        }, 8, 123)).toBe(1)
        expect(D.waveSize({
            EnableCollapseWaves = true,
            RoundStartedAt = 100, RoundSeconds = 15,
        }, 8, 113)).toBe(1)
        expect(D.waveSize({}, 12, 999)).toBe(1)

        local candidates = {}
        for i = 1, 8 do
            local p = Instance.new("Part")
            p.Name = "Candidate" .. i
            p.Position = Vector3.new(i * 8, 0, (i % 2) * 30)
            candidates[i] = p
        end
        local selected = D.chooseWavePlatforms(candidates, 2, 1)
        expect(#selected).toBe(2)
        expect(selected[1]).toBe(candidates[1])
        expect(selected[2] ~= selected[1]).toBe(true)
        local delta = selected[2].Position - selected[1].Position
        expect(Vector3.new(delta.X, 0, delta.Z).Magnitude >= 18)
            .toBe(true)
        expect(#D.chooseWavePlatforms(candidates, 1, 1)).toBe(1)
        expect(#D.chooseWavePlatforms(candidates, 2, 1)).toBe(2)
        expect(#D.chooseWavePlatforms({}, 2, 1)).toBe(0)
        for _, p in ipairs(candidates) do p:Destroy() end
    end)

    it("physically collapses two far-apart decks together and restores both on cleanup", function()
        local D = require("../../src/server/Disasters/DisappearingPlatforms")
        local existing = workspace:FindFirstChild("GeneratedMap")
        if existing then existing:Destroy() end

        local root = Instance.new("Folder")
        root.Name = "GeneratedMap"
        root.Parent = workspace
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = root
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = arena

        local decks = {}
        for i = 1, 8 do
            local deck = Instance.new("Part")
            deck.Name = "Platform" .. i
            deck.Anchored = true
            deck.Size = Vector3.new(7, 1, 7)
            deck.Position = Vector3.new(i * 14, 8, (i % 2) * 32)
            deck.CanCollide = true
            deck.Parent = platforms
            decks[i] = deck
        end

        local cleanup = {}
        local active = true
        local ctx = {
            Active = function() return active end,
            Cleanup = {},
            OnCleanup = cleanup,
            EnableCollapseWaves = true,
            RoundStartedAt = os.clock() - 28,
            RoundSeconds = 40,
            RoundEndsAt = os.clock() + 6,
        }
        D.start(ctx)

        local function countPhase(phase)
            local n = 0
            for _, deck in ipairs(decks) do
                if deck:GetAttribute("CollapsePhase") == phase then
                    n += 1
                end
            end
            return n
        end

        local deadline = os.clock() + 0.75
        while countPhase("Warning") < 2 and os.clock() < deadline do
            task.wait(0.02)
        end
        expect(countPhase("Warning")).toBe(2)
        -- The round HUD must never announce a dual failure unless the
        -- authoritative hazard has staged two actual walkable decks.
        expect(ctx.DoubleCollapseUnlocked).toBe(true)
        local signaled = {}
        local startedAt = nil
        for _, deck in ipairs(decks) do
            if deck:GetAttribute("CollapsePhase") == "Warning" then
                expect(deck.CanCollide).toBe(true)
                signaled[#signaled + 1] = deck
                if not startedAt then
                    startedAt = deck:GetAttribute("CollapseWarningStartedAt")
                else
                    expect(deck:GetAttribute("CollapseWarningStartedAt"))
                        .toBe(startedAt)
                end
            end
        end
        expect(#signaled).toBe(2)
        local delta = signaled[1].Position - signaled[2].Position
        expect(Vector3.new(delta.X, 0, delta.Z).Magnitude >= 18)
            .toBe(true)

        deadline = os.clock() + 2.0
        while countPhase("Gone") < 2 and os.clock() < deadline do
            task.wait(0.03)
        end
        expect(countPhase("Gone")).toBe(2)
        local safe = 0
        for _, deck in ipairs(decks) do
            if deck.CanCollide then safe += 1 end
        end
        expect(safe).toBe(6)

        active = false
        runCleanup({}, cleanup)
        expect(ctx.DoubleCollapseUnlocked == nil).toBe(true)
        for _, deck in ipairs(decks) do
            expect(deck.CanCollide).toBe(true)
            expect(deck:GetAttribute("CollapsePhase") == nil).toBe(true)
        end
        root:Destroy()
    end)

    it("hides real server trims and supports along with the collision deck", function()
        local D = require("../../src/server/Disasters/DisappearingPlatforms")
        -- The mobile warning needs enough time for normal reactions
        -- and a real movement response, not just a cosmetic flash.
        expect(D.WarningSeconds >= 1.25 and D.WarningSeconds <= 1.65).toBe(true)
        expect(D.GoneSeconds).toBe(2)
        expect(D.canBegin({}, 100)).toBe(true)
        expect(D.canBegin({RoundEndsAt = 100}, 94)).toBe(true)
        expect(D.canBegin({RoundEndsAt = 100}, 95)).toBe(false)
        local existing = workspace:FindFirstChild("GeneratedMap")
        if existing then existing:Destroy() end

        local root = Instance.new("Folder")
        root.Name = "GeneratedMap"
        root.Parent = workspace
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = root
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = arena
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena

        local deck = Instance.new("Part")
        deck.Name = "Platform1"
        deck.Anchored = true
        deck.CanCollide = true
        deck.Parent = platforms

        local skybridge = Instance.new("Part")
        skybridge.Name = "Skybridge2"
        skybridge.CanCollide = true
        skybridge:SetAttribute("ChaosSkybridge", true)
        skybridge.Parent = platforms
        expect(#D.eligiblePlatforms(platforms, {})).toBe(1)

        local names = {
            "PlatformPanel1", "PlatformUnderFrame1", "PlatformCoreGlow1",
            "PlatformGlow1", "PlatformSupport1_1", "PlatformSupport1_2",
        }
        local cosmetics = {}
        for i, name in ipairs(names) do
            local piece = Instance.new("Part")
            piece.Name = name
            piece.Anchored = true
            piece.CanCollide = false
            piece.Transparency = i * 0.05
            piece.Parent = decor
            table.insert(cosmetics, {part = piece, alpha = piece.Transparency})
        end
        -- A sculpted outer facade without a legacy Platform* prefix
        -- must also disappear along with its owning physical deck.
        local outerFacade = Instance.new("WedgePart")
        outerFacade.Name = "PerimeterExitCrown1"
        outerFacade:SetAttribute("PerimeterPlatformIndex", 1)
        outerFacade.CanCollide = false
        outerFacade.Transparency = 0.18
        outerFacade.Parent = decor
        table.insert(cosmetics, {
            part = outerFacade, alpha = outerFacade.Transparency,
        })

        local unrelated = Instance.new("Part")
        unrelated.Name = "PlatformPanel11"
        unrelated.Transparency = 0.27
        unrelated.Parent = decor

        local owned = D.cosmeticsForPlatform(decor, deck)
        expect(#owned).toBe(#cosmetics)
        expect(#D.cosmeticsForPlatform(decor, skybridge)).toBe(0)

        local cleanup = {}
        local active = true
        D.start({
            Active = function() return active end,
            Cleanup = {},
            OnCleanup = cleanup,
        })

        -- Verify that the entire client-visible warning is physically
        -- solid. Normal and AI humanoids can walk away throughout this
        -- extended interval; the skybridge stays unaffected.
        local warningDeadline = os.clock() + 0.4
        while deck:GetAttribute("CollapsePhase") ~= "Warning"
            and os.clock() < warningDeadline do
            task.wait(0.01)
        end
        expect(deck:GetAttribute("CollapsePhase")).toBe("Warning")
        expect(deck.CanCollide).toBe(true)
        expect(deck:GetAttribute("CollapseWarningStartedAt") ~= nil).toBe(true)
        task.wait(0.65)
        expect(deck:GetAttribute("CollapsePhase")).toBe("Warning")
        expect(deck.CanCollide).toBe(true)

        local deadline = os.clock() + 2.0
        while deck:GetAttribute("CollapsePhase") ~= "Gone"
            and os.clock() < deadline do
            task.wait(0.025)
        end
        expect(deck:GetAttribute("CollapsePhase")).toBe("Gone")
        expect(deck.CanCollide).toBe(false)
        expect(deck.Transparency).toBe(1)
        for _, entry in ipairs(cosmetics) do
            expect(entry.part.Transparency).toBe(1)
        end
        -- Roblox stores Part.Transparency as float32, not a decimal64.
        expect(math.abs(unrelated.Transparency - 0.27) < 0.0001).toBe(true)
        expect(skybridge.Transparency).toBe(0)

        active = false
        runCleanup({}, cleanup)
        expect(deck:GetAttribute("CollapsePhase") == nil).toBe(true)
        expect(deck.CanCollide).toBe(true)
        for _, entry in ipairs(cosmetics) do
            expect(entry.part.Transparency).toBe(entry.alpha)
        end

        -- A stale delayed restore cannot revive a different collapse.
        root:Destroy()
    end)
end)

describe("Headless disaster playtest", function()
    it("runs smooth Moon Gravity tides with an authoritative world warning", function()
        local gravity = require("../../src/server/Disasters/LowGravity")
        local target, stage, remaining = gravity.tideAt(0, false)
        expect(target).toBe(55)
        expect(stage).toBe("Float")
        target, stage, remaining = gravity.tideAt(5, true)
        expect(target).toBe(55)
        expect(stage).toBe("Float")
        expect(remaining).toBe(1.5)
        expect(gravity.tideCue(stage, remaining)).toBe("PULL IN 2s")

        target, stage = gravity.tideAt(7.25, true)
        expect(stage).toBe("PullRising")
        expect(math.abs(target - 87.5) < 0.01).toBe(true)
        target, stage = gravity.tideAt(8, true)
        expect(target).toBe(120)
        expect(stage).toBe("Pull")
        target, stage = gravity.tideAt(13.25, true)
        expect(stage).toBe("FloatReturning")
        expect(math.abs(target - 87.5) < 0.01).toBe(true)
        target, stage = gravity.tideAt(14, true)
        expect(target).toBe(55)
        expect(stage).toBe("Float")
        target = gravity.tideAt(21, false)
        expect(target).toBe(55)
        expect(gravity.tideAt(21, true) > 55).toBe(true)

        local originalGravity = workspace.Gravity
        local character = Instance.new("Model")
        character.Name = "MoonTideEngineSubject"
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.CanCollide = false
        root.Position = Vector3.new(0, 30, 0)
        root.Parent = character
        local hum = Instance.new("Humanoid")
        hum.Parent = character
        character.Parent = workspace
        local subject = {Character = character}
        local cleanup = {}
        local onCleanup = {}
        local active = true

        local ctx = {
            Config = Config,
            EnableGravityTides = true,
            RoundStartedAt = os.clock() - 9,
            Active = function() return active end,
            IsContestantActive = function(p) return p == subject end,
            HazardContestants = {subject},
            Cleanup = cleanup,
            OnCleanup = onCleanup,
        }
        gravity.start(ctx)
        expect(ctx.GravityTideStage).toBe("Pull")
        task.wait(0.12)
        expect(ctx.GravityTideStage).toBe("Pull")
        local beacon = workspace:FindFirstChild("MoonGravityBeacon")
        expect(beacon ~= nil).toBe(true)
        local label = beacon and beacon:FindFirstChild("GravityTideSignal")
        local text = label and label:FindFirstChild("GravityTideText")
        expect(text ~= nil).toBe(true)
        if text then
            expect(string.find(text.Text, "PULL", 1, true) ~= nil).toBe(true)
        end
        local force = root:FindFirstChild("MoonGravityForce")
        expect(force ~= nil).toBe(true)
        if force then
            local expected = gravity.compensationForce(
                root.AssemblyMass, originalGravity, 120
            )
            expect(math.abs(force.Force.Y - expected) < 0.5).toBe(true)
        end

        active = false
        runCleanup(cleanup, onCleanup)
        expect(ctx.GravityTideStage == nil).toBe(true)
        expect(beacon == nil or beacon.Parent == nil).toBe(true)
        expect(force == nil or force.Parent == nil).toBe(true)
        expect(workspace.Gravity).toBe(originalGravity)
        character:Destroy()
    end)

    it("makes elevated routes a real tornado escape without weakening ground hazards", function()
        local center = Vector3.zero
        local ground, groundStrength = Tornado.impulseAt(
            Vector3.new(10, 4, 0), center, 17, 1
        )
        local elevated, elevatedStrength = Tornado.impulseAt(
            Vector3.new(10, 20, 0), center, 17, 1
        )
        local above, aboveStrength = Tornado.impulseAt(
            Vector3.new(10, 28, 0), center, 17, 1
        )
        expect(ground ~= nil).toBe(true)
        expect(elevated ~= nil).toBe(true)
        expect(groundStrength > elevatedStrength).toBe(true)
        expect(elevatedStrength > 0).toBe(true)
        expect(elevated.Magnitude < ground.Magnitude).toBe(true)
        expect(above == nil).toBe(true)
        expect(aboveStrength).toBe(0)
        expect(Tornado.verticalExposure(12)).toBe(1)
        expect(Tornado.verticalExposure(20)).toBe(0.5)
        expect(Tornado.verticalExposure(28)).toBe(0)
        expect(Tornado.verticalExposure(nil)).toBe(0)
        -- Descending below the funnel does not make a safe pocket.
        expect(Tornado.verticalExposure(-8)).toBe(1)
    end)

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

    it("gives veteran Speed Surge a repeatable seven/five-second rhythm", function()
        local speed = require("../../src/server/Disasters/SpeedSurge")
        local phase, remaining = speed.tempoAt(0, true)
        expect(phase).toBe("Surge")
        expect(remaining).toBe(7)
        phase, remaining = speed.tempoAt(7, true)
        expect(phase).toBe("Recover")
        expect(remaining).toBe(5)
        phase, remaining = speed.tempoAt(12, true)
        expect(phase).toBe("Surge")
        expect(remaining).toBe(7)
        phase, remaining = speed.tempoAt(9, false)
        expect(phase).toBe("Surge")
        expect(remaining).toBe(math.huge)
    end)

    it("eases Speed Surge speed changes without a movement snap", function()
        local speed = require("../../src/server/Disasters/SpeedSurge")
        local at = speed.speedAt
        local midpoint = speed.TransitionSeconds * 0.5
        expect(at(16, 24, 0, true)).toBe(24)
        expect(at(16, 24, 6.99, true)).toBe(24)
        expect(at(16, 24, 7, true)).toBe(24)
        expect(math.abs(at(16, 24, 7 + midpoint, true) - 20) < 0.001)
            .toBe(true)
        expect(at(16, 24, 7 + speed.TransitionSeconds, true)).toBe(16)
        expect(at(16, 24, 11.9, true)).toBe(16)
        expect(at(16, 24, 12, true)).toBe(16)
        expect(math.abs(at(16, 24, 12 + midpoint, true) - 20) < 0.001)
            .toBe(true)
        expect(at(16, 24, 12 + speed.TransitionSeconds, true)).toBe(24)
        expect(at(16, 24, 19 + speed.TransitionSeconds, true)).toBe(16)
        expect(at(16, 24, 27, false)).toBe(24)
        expect(at(16, 24, 0 / 0, true)).toBe(24)
        expect(at(16, 24, math.huge, true)).toBe(24)

        -- Small precision differences are ours; an external speed
        -- modifier must not be overwritten on the next update or cleanup.
        expect(speed.ownsSpeed(20, 20.00001)).toBe(true)
        expect(speed.ownsSpeed(20.2, 20)).toBe(false)
        expect(speed.ownsSpeed(0 / 0, 20)).toBe(false)
        expect(speed.ownsSpeed(20, math.huge)).toBe(false)

        -- The actual Humanoid speed may round away from the originally
        -- assigned Luau double. Continue the tide only while still owned.
        expect(speed.shouldAssignSpeed(20, 20.000001, 24)).toBe(true)
        expect(speed.shouldAssignSpeed(20, 20, 20.000001)).toBe(false)
        expect(speed.shouldAssignSpeed(19.75, 20, 24)).toBe(false)
        expect(speed.shouldAssignSpeed(0 / 0, 20, 24)).toBe(false)
        expect(speed.shouldAssignSpeed(20, 20, math.huge)).toBe(false)
    end)

    it("allows a real timed jump to dodge Jump Shock, not a fall", function()
        local jumpShock = require("../../src/server/Disasters/JumpShock")
        local dodged = jumpShock.dodgedByJump
        local jumping = Enum.HumanoidStateType.Jumping
        local falling = Enum.HumanoidStateType.Freefall
        local running = Enum.HumanoidStateType.Running

        expect(jumpShock.WarningSeconds >= 1).toBe(true)
        expect(dodged(jumping, 18, 7)).toBe(true)
        expect(dodged(falling, 9, 5)).toBe(true)
        expect(dodged(falling, -10, 7)).toBe(false)
        expect(dodged(jumping, 12, 2)).toBe(false)
        expect(dodged(running, 20, 8)).toBe(false)
        expect(dodged(jumping, 15, 0)).toBe(false)
        expect(dodged(jumping, nil, 7)).toBe(false)
        expect(dodged(jumping, 15, nil)).toBe(false)

        -- The physical airborne/velocity/ground checks rescue a valid
        -- remote-owned player jump when server Humanoid state is stale.
        expect(dodged(running, 18, 7, true)).toBe(true)
        expect(dodged(running, 18, 7, false)).toBe(false)
        expect(dodged(running, 0, 7, true)).toBe(false)
        expect(dodged(running, 18, 2, true)).toBe(false)
        expect(dodged(nil, 18, 7, true)).toBe(true)
    end)

    it("credits an earned shock dodge only while the round is active", function()
        local jumpShock = require("../../src/server/Disasters/JumpShock")
        local credited = {}
        local active = true
        local subject = {name = "survivor"}
        local ctx = {
            Active = function() return active end,
            OnHazardNearMiss = function(target, kind, distance, radius)
                table.insert(credited, {target, kind, distance, radius})
            end,
        }

        expect(jumpShock.rewardDodge(ctx, subject)).toBe(true)
        expect(#credited).toBe(1)
        expect(credited[1][1]).toBe(subject)
        expect(credited[1][2]).toBe("JumpShock")

        active = false
        expect(jumpShock.rewardDodge(ctx, subject)).toBe(false)
        expect(#credited).toBe(1)
        expect(jumpShock.rewardDodge({}, subject)).toBe(false)
        expect(jumpShock.rewardDodge(nil, subject)).toBe(false)
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
            if entry.id == "Darkness" then
                ctx.EnableBlackoutWindows = true
                ctx.RoundStartedAt = os.clock() - 7.2
                local stageAt = entry.module.stageAt
                expect(stageAt(0, true)).toBe("Dark")
                expect(stageAt(6.99, true)).toBe("Dark")
                expect(stageAt(7, true)).toBe("PowerReturn")
                expect(stageAt(9.99, true)).toBe("PowerReturn")
                expect(stageAt(10, true)).toBe("Dark")
                expect(stageAt(20, true)).toBe("PowerReturn")
                expect(stageAt(7, false)).toBe(nil)
                expect(stageAt(math.huge, true)).toBe("Dark")
            end

            local ok, err = pcall(entry.module.start, ctx)
            expect(ok).toBe(true)

            task.wait(0.08)
            if entry.id == "Darkness" then
                expect(ctx.BlackoutStage).toBe("PowerReturn")
            end
            active = false
            runCleanup(cleanup, onCleanup)
            if entry.id == "Darkness" then
                expect(ctx.BlackoutStage).toBe(nil)
            end
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

describe("Veteran tornado journey and novice fairness", function()
    it("keeps novice and Double Chaos storms fixed with a stable eight-second opening", function()
        local tornado = Tornado
        local ctx = {
            EnableTornadoDrift = true,
            RoundStartedAt = 100,
            RoundSeconds = 40,
        }
        expect(tornado.driftOffset({}, 120)).toBe(Vector3.zero)
        expect(tornado.driftOffset({EnableTornadoDrift = false}, 120))
            .toBe(Vector3.zero)
        expect(tornado.driftOffset(ctx, 100)).toBe(Vector3.zero)
        expect(tornado.driftOffset(ctx, 107.99)).toBe(Vector3.zero)
        expect(tornado.driftOffset(ctx, 108)).toBe(Vector3.zero)
        expect(tornado.driftOffset({
            EnableTornadoDrift = true, RoundStartedAt = 100, RoundSeconds = 20,
        }, 120)).toBe(Vector3.zero)
        expect(tornado.driftOffset({
            EnableTornadoDrift = true, RoundStartedAt = 100,
        }, 120)).toBe(Vector3.zero)
        expect(tornado.driftOffset(ctx, 0/0)).toBe(Vector3.zero)
        expect(tornado.driftOffset(ctx, math.huge)).toBe(Vector3.zero)
        expect(tornado.driftOffset(nil, 120)).toBe(Vector3.zero)

        local emerging = tornado.driftOffset(ctx, 109)
        local moving = tornado.driftOffset(ctx, 120)
        expect(emerging.Magnitude > 0 and emerging.Magnitude < 4).toBe(true)
        expect(moving.Magnitude > emerging.Magnitude).toBe(true)
        expect(moving.Y).toBe(0)
        expect(math.abs(moving.X) <= 11).toBe(true)
        expect(math.abs(moving.Z) <= 9).toBe(true)
        expect(tornado.driftOffset(ctx, 1000)).toBe(
            tornado.driftOffset(ctx, 140)
        )
        for second = 0, 40 do
            local now = 100 + second
            local offset = tornado.driftOffset(ctx, now)
            local nextOffset = tornado.driftOffset(ctx, now + 0.25)
            expect((nextOffset - offset).Magnitude < 1).toBe(true)
            expect(math.abs(offset.X) <= 11 and math.abs(offset.Z) <= 9)
                .toBe(true)
        end
    end)

    it("moves the replicated funnel and server-owned wind influence together", function()
        local active = true
        local ctx = {
            Config = {ArenaCenter = Vector3.new(30, 9, -20)},
            Cleanup = {},
            Active = function() return active end,
            Contestants = {},
            HazardContestants = {},
            RoundStartedAt = os.clock() - 19,
            RoundSeconds = 40,
            EnableTornadoDrift = true,
            BalanceProfile = {TornadoForce = 17},
        }
        Tornado.start(ctx)
        local model = workspace:FindFirstChild("RoundTornado")
        expect(model ~= nil).toBe(true)
        local lower = model and model:FindFirstChild("LowerFunnel")
        local danger = model and model:FindFirstChild("DangerZone")
        expect(lower ~= nil and danger ~= nil).toBe(true)

        local deadline = os.clock() + 0.55
        while lower and (lower.Position.X - ctx.Config.ArenaCenter.X) == 0
            and os.clock() < deadline do
            task.wait(0.03)
        end
        if lower and danger then
            local actualCenter = lower.Position - Vector3.new(0, 3, 0)
            expect((actualCenter - ctx.Config.ArenaCenter).Magnitude > 1)
                .toBe(true)
            expect((actualCenter - ctx.Config.ArenaCenter).Magnitude < 15)
                .toBe(true)
            local zoneCenter = danger.Position - Vector3.new(0, 1.12, 0)
            expect((zoneCenter - actualCenter).Magnitude < 0.01)
                .toBe(true)
            local hit, strength = Tornado.impulseAt(
                actualCenter, actualCenter, 17, 1
            )
            expect(hit ~= nil and strength == 1).toBe(true)
        end

        active = false
        runCleanup(ctx.Cleanup, {})
        expect(model == nil or model.Parent == nil).toBe(true)
    end)
end)


return nil
