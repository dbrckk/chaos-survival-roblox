--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AISurvivorRules = require("../../src/server/AISurvivorRules")
local AISurvivorService = require("../../src/server/AISurvivorService")
local AISurvivorNetworkOwnership = require("../../src/server/AISurvivorNetworkOwnership")

describe("AI survivor rules", function()
    it("loads the runtime AI survivor service contract in Roblox", function()
        expect(type(AISurvivorService)).toBe("table")
        expect(type(AISurvivorService.start)).toBe("function")
        expect(type(AISurvivorService.setRoundState)).toBe("function")
        expect(type(AISurvivorService.visibleCount)).toBe("function")
        expect(type(AISurvivorService.aliveRoundCount)).toBe("function")
        expect(type(AISurvivorService.names)).toBe("function")
    end)

    it("only claims server physics ownership for a live workspace rig", function()
        local model = Instance.new("Model")
        model.Name = "OwnershipProbe"
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.Anchored = false
        root.Parent = model

        -- Regression: calling SetNetworkOwner before parenting used to be
        -- silently ignored by a blanket pcall in the bot rig factory.
        expect(AISurvivorNetworkOwnership.claim(model)).toBe(false)
        model.Parent = workspace
        root.Anchored = true
        expect(AISurvivorNetworkOwnership.claim(model)).toBe(false)

        root.Anchored = false
        local ok, canSet = pcall(root.CanSetNetworkOwnership, root)
        if ok and canSet then
            expect(AISurvivorNetworkOwnership.claim(model)).toBe(true)
            local ownerOk, owner = pcall(root.GetNetworkOwner, root)
            expect(ownerOk).toBe(true)
            expect(owner == nil).toBe(true)
        else
            -- Editing and some cloud test contexts cannot assign simulation
            -- ownership; the live-server path is covered by Studio QA.
            expect(AISurvivorNetworkOwnership.claim(model)).toBe(false)
        end
        model:Destroy()
    end)

    it("uses elevated Orbital ramps only when a bot can actually reach them", function()
        local rules = AISurvivorRules
        local waypoint = Vector3.new(15, 12, 8)
        expect(rules.helixWaypointReachable(Vector3.new(5, 10, 4), waypoint)).toBe(true)
        expect(rules.helixWaypointReachable(Vector3.new(5, 2, 4), waypoint)).toBe(false)
        expect(rules.helixWaypointReachable(Vector3.new(-19, 10, 8), waypoint)).toBe(false)
        expect(rules.helixWaypointReachable(nil, waypoint)).toBe(false)
        expect(rules.helixWaypointReachable(waypoint, nil)).toBe(false)
    end)

    it("fills a small server toward four visible participants", function()
        expect(AISurvivorRules.desiredBotCount(0)).toBe(0)
        expect(AISurvivorRules.desiredBotCount(1)).toBe(3)
        expect(AISurvivorRules.desiredBotCount(2)).toBe(2)
        expect(AISurvivorRules.desiredBotCount(3)).toBe(1)
        expect(AISurvivorRules.desiredBotCount(4)).toBe(0)
        expect(AISurvivorRules.desiredBotCount(9)).toBe(0)
    end)

    it("freezes active AI competitors when a human joins mid-round", function()
        expect(AISurvivorRules.desiredBotCount(1)).toBe(3)
        expect(AISurvivorRules.desiredBotCount(2)).toBe(2)

        -- The extra human must not evict a live AI during a round.
        for _, phase in ipairs({"ready", "round", "result"}) do
            expect(AISurvivorRules.rosterLocked(phase)).toBe(true)
        end
        for _, phase in ipairs({"waiting", "intermission", "vote"}) do
            expect(AISurvivorRules.rosterLocked(phase)).toBe(false)
        end
        expect(AISurvivorRules.rosterLocked(nil)).toBe(false)
    end)

    it("rotates distinct behavior profiles", function()
        expect(AISurvivorRules.profileForSlot(1).Id).toBe("Cautious")
        expect(AISurvivorRules.profileForSlot(2).Id).toBe("Balanced")
        expect(AISurvivorRules.profileForSlot(3).Id).toBe("Bold")
        expect(AISurvivorRules.profileForSlot(4).Id).toBe("Cautious")
    end)

    it("keeps human-like behavior traits bounded and varied", function()
        local cautious = AISurvivorRules.profileForSlot(1)
        local balanced = AISurvivorRules.profileForSlot(2)
        local bold = AISurvivorRules.profileForSlot(3)

        for _, profile in ipairs({cautious, balanced, bold}) do
            expect(profile.MistakeChance >= 0 and profile.MistakeChance <= 0.30).toBe(true)
            expect(profile.SocialChance >= 0 and profile.SocialChance <= 0.40).toBe(true)
        end

        expect(cautious.MistakeChance < bold.MistakeChance).toBe(true)
        expect(cautious.SocialChance < bold.SocialChance).toBe(true)
    end)

    it("varies temperament between rounds while keeping identity bounded", function()
        local profile = AISurvivorRules.profileForSlot(2)
        local roundA = AISurvivorRules.roundTraits(profile, 2, 4)
        local roundB = AISurvivorRules.roundTraits(profile, 2, 5)
        local repeatA = AISurvivorRules.roundTraits(profile, 2, 4)

        expect(roundA.Risk >= 0.12 and roundA.Risk <= 0.88).toBe(true)
        expect(roundA.SocialChance >= 0.06 and roundA.SocialChance <= 0.46).toBe(true)
        expect(roundA.MistakeChance >= 0.035 and roundA.MistakeChance <= 0.27).toBe(true)
        expect(roundA.PadChance >= 0.07 and roundA.PadChance <= 0.52).toBe(true)
        expect(roundA.HesitationChance >= 0.05 and roundA.HesitationChance <= 0.18).toBe(true)
        expect(roundA.ReconsiderChance >= 0.05 and roundA.ReconsiderChance <= 0.13).toBe(true)
        expect(roundA.FollowThrough >= 0.92 and roundA.FollowThrough <= 1.12).toBe(true)
        expect(roundA.DirectionBias >= -1 and roundA.DirectionBias <= 1).toBe(true)

        expect(roundA.Risk).toBe(repeatA.Risk)
        expect(roundA.SocialChance).toBe(repeatA.SocialChance)
        expect(
            roundA.Risk ~= roundB.Risk
            or roundA.SocialChance ~= roundB.SocialChance
            or roundA.DirectionBias ~= roundB.DirectionBias
        ).toBe(true)
    end)

    it("reduces optional jumps under pressure without disabling them", function()
        local calm = AISurvivorRules.freeJumpChance(0.20, 0, false)
        local pressured = AISurvivorRules.freeJumpChance(0.20, 0.8, false)
        local lowGravity = AISurvivorRules.freeJumpChance(0.20, 0, true)
        local pressuredLowGravity = AISurvivorRules.freeJumpChance(0.20, 0.8, true)

        expect(calm).toBe(0.20)
        expect(pressured < calm).toBe(true)
        expect(pressured >= 0.04).toBe(true)
        expect(lowGravity < calm).toBe(true)
        expect(pressuredLowGravity < lowGravity).toBe(true)
    end)

    it("selects distinct lobby modes with vote taking priority", function()
        expect(AISurvivorRules.lobbyActivity(0.05, 0.20, 0.20, false)).toBe("social")
        expect(AISurvivorRules.lobbyActivity(0.30, 0.20, 0.20, false)).toBe("practice")
        expect(AISurvivorRules.lobbyActivity(0.80, 0.20, 0.20, false)).toBe("roam")
        expect(AISurvivorRules.lobbyActivity(0.80, 0.20, 0.20, true)).toBe("vote")
    end)

    it("spreads vote gathering and social spacing around partners", function()
        local a = AISurvivorRules.voteGatherOffset(1, 4)
        local b = AISurvivorRules.voteGatherOffset(2, 4)
        expect(a.Magnitude >= 6 and a.Magnitude <= 10.01).toBe(true)
        expect(b.Magnitude >= 6 and b.Magnitude <= 10.01).toBe(true)
        expect((a - b).Magnitude > 1).toBe(true)

        local socialA = AISurvivorRules.socialSpacing(1, 2)
        local socialB = AISurvivorRules.socialSpacing(2, 1)
        expect(socialA.Magnitude >= 4.5 and socialA.Magnitude <= 6.46).toBe(true)
        expect(socialB.Magnitude >= 4.5 and socialB.Magnitude <= 6.46).toBe(true)
        expect((socialA - socialB).Magnitude > 0.5).toBe(true)
    end)

    it("distributes lobby roam targets across social nodes", function()
        local a = AISurvivorRules.lobbyNodeOffset(1, 0)
        local b = AISurvivorRules.lobbyNodeOffset(2, 0)
        local nextA = AISurvivorRules.lobbyNodeOffset(1, 1)

        expect(a.Magnitude >= 15 and a.Magnitude <= 21).toBe(true)
        expect(b.Magnitude >= 15 and b.Magnitude <= 21).toBe(true)
        expect((a - b).Magnitude > 8).toBe(true)
        expect((a - nextA).Magnitude > 8).toBe(true)
    end)

    it("cycles five avatar styles across survivor identities", function()
        local seen = {}
        for index = 1, 8 do
            local style = AISurvivorRules.appearanceStyle(index)
            expect(style >= 1 and style <= 5).toBe(true)
            seen[style] = true
        end

        local count = 0
        for _ in pairs(seen) do
            count += 1
        end
        expect(count).toBe(5)
        expect(AISurvivorRules.appearanceStyle(1)).toBe(1)
        expect(AISurvivorRules.appearanceStyle(6)).toBe(1)
    end)

    it("keeps identity-based body scales bounded and varied", function()
        local bodyA, proportionA = AISurvivorRules.bodyScales(1)
        local bodyB, proportionB = AISurvivorRules.bodyScales(2)

        expect(bodyA >= 0.04 and bodyA <= 0.20).toBe(true)
        expect(proportionA >= 0.08 and proportionA <= 0.28).toBe(true)
        expect(bodyB >= 0.04 and bodyB <= 0.20).toBe(true)
        expect(proportionB >= 0.08 and proportionB <= 0.28).toBe(true)
        expect(bodyA ~= bodyB or proportionA ~= proportionB).toBe(true)
    end)

    it("selects natural idle walk run and fall animation states", function()
        local idle, idleSpeed = AISurvivorRules.locomotionAnimation(0, false, 1)
        local walk, walkSpeed = AISurvivorRules.locomotionAnimation(8, false, 1)
        local run, runSpeed = AISurvivorRules.locomotionAnimation(16, false, 1)
        local fall, fallSpeed = AISurvivorRules.locomotionAnimation(16, true, 1)

        expect(idle).toBe("idle")
        expect(idleSpeed).toBe(1)
        expect(walk).toBe("walk")
        expect(walkSpeed >= 0.70 and walkSpeed <= 1.25).toBe(true)
        expect(run).toBe("run")
        expect(runSpeed >= 0.78 and runSpeed <= 1.32).toBe(true)
        expect(fall).toBe("fall")
        expect(fallSpeed).toBe(1)
    end)

    it("varies non-running animation tempo without extreme playback", function()
        local slowIdle = AISurvivorRules.animationPlaybackScale("idle", 1, 0.90)
        local fastIdle = AISurvivorRules.animationPlaybackScale("idle", 1, 1.10)
        local fall = AISurvivorRules.animationPlaybackScale("fall", 1, 1.10)
        local jump = AISurvivorRules.animationPlaybackScale("jump", 1, 0.90)
        local run = AISurvivorRules.animationPlaybackScale("run", 1.22, 0.90)

        expect(slowIdle < fastIdle).toBe(true)
        expect(slowIdle >= 0.94 and fastIdle <= 1.06).toBe(true)
        expect(fall >= 0.96 and fall <= 1.04).toBe(true)
        expect(jump >= 0.95 and jump <= 1.05).toBe(true)
        expect(run).toBe(1.22)
    end)

    it("uses distinct locomotion blends instead of one fixed fade", function()
        expect(AISurvivorRules.locomotionTransition("idle", "idle")).toBe(0)
        expect(AISurvivorRules.locomotionTransition("idle", "walk")).toBe(0.14)
        expect(AISurvivorRules.locomotionTransition("walk", "run")).toBe(0.16)
        expect(AISurvivorRules.locomotionTransition("run", "idle")).toBe(0.12)
        expect(AISurvivorRules.locomotionTransition("run", "fall")).toBe(0.06)
        expect(AISurvivorRules.locomotionTransition("fall", "run")).toBe(0.10)
    end)

    it("isolates one failed AI step without stopping other bots", function()
        local processed = {}
        local bots = {
            {identity = "Nova"},
            {identity = "Milo"},
            {identity = "Kai"},
        }
        local function step(record)
            if record.identity == "Milo" then
                error("simulated NPC-only failure")
            end
            table.insert(processed, record.identity)
        end

        local warnings = 0
        for _, bot in ipairs(bots) do
            local ok, err, shouldReport = AISurvivorRules.runBrainStep(
                bot, 10, step
            )
            if bot.identity == "Milo" then
                expect(ok).toBe(false)
                expect(type(err)).toBe("string")
                expect(shouldReport).toBe(true)
                warnings += shouldReport and 1 or 0
            else
                expect(ok).toBe(true)
            end
        end
        expect(processed[1]).toBe("Nova")
        expect(processed[2]).toBe("Kai")
        expect(#processed).toBe(2)
        expect(warnings).toBe(1)

        local okLater, _, reportLater = AISurvivorRules.runBrainStep(
            bots[2], 11, step
        )
        expect(okLater).toBe(false)
        expect(reportLater).toBe(false)

        local _, _, reportAgain = AISurvivorRules.runBrainStep(
            bots[2], 18, step
        )
        expect(reportAgain).toBe(true)
    end)

    it("slows the ai brain when idle or showing results", function()
        expect(AISurvivorRules.brainCadence(0, "waiting")).toBe(0.75)
        expect(AISurvivorRules.brainCadence(3, "result")).toBe(0.42)
        expect(AISurvivorRules.brainCadence(3, "round")).toBe(0.18)
        expect(AISurvivorRules.brainCadence(3, "intermission")).toBe(0.18)
    end)

    it("keeps identity-based depth and head scales bounded and varied", function()
        local depthA, headA = AISurvivorRules.shapeScales(1)
        local depthB, headB = AISurvivorRules.shapeScales(2)

        expect(depthA >= 0.94 and depthA <= 1.06).toBe(true)
        expect(headA >= 0.95 and headA <= 1.05).toBe(true)
        expect(depthB >= 0.94 and depthB <= 1.06).toBe(true)
        expect(headB >= 0.95 and headB <= 1.05).toBe(true)
        expect(depthA ~= depthB or headA ~= headB).toBe(true)
    end)

    it("varies result reactions with temperament without changing gameplay stats", function()
        expect(AISurvivorRules.resultReaction(0.05, 0.20)).toBe("jump")
        expect(AISurvivorRules.resultReaction(0.45, 0.20)).toBe("sidestep")
        expect(AISurvivorRules.resultReaction(0.68, 0.20)).toBe("acknowledge")
        expect(AISurvivorRules.resultReaction(0.95, 0.20)).toBe("still")

        local cautiousJumpCutoff = AISurvivorRules.resultReaction(0.30, 0.10)
        local boldJumpCutoff = AISurvivorRules.resultReaction(0.30, 0.90)
        expect(cautiousJumpCutoff ~= boldJumpCutoff).toBe(true)
    end)

    it("smooths ordinary steering but keeps urgent steering direct", function()
        local previous = Vector3.new(1, 0, 0)
        local desired = Vector3.new(0, 0, 1)

        local smooth = AISurvivorRules.steeredDirection(previous, desired, false)
        local urgent = AISurvivorRules.steeredDirection(previous, desired, true)

        expect(smooth.X > 0).toBe(true)
        expect(smooth.Z > 0).toBe(true)
        expect((urgent - desired.Unit).Magnitude < 0.001).toBe(true)
    end)

    it("only inserts a turn pause for sharp non-urgent reversals", function()
        local forward = Vector3.new(0, 0, -1)
        local reverse = Vector3.new(0, 0, 1)
        local side = Vector3.new(1, 0, 0)

        local reversalPause = AISurvivorRules.turnPauseSeconds(
            forward,
            reverse,
            false,
            0
        )
        expect(reversalPause > 0).toBe(true)
        expect(
            AISurvivorRules.turnPauseSeconds(forward, reverse, true, 0)
        ).toBe(0)
        expect(
            AISurvivorRules.turnPauseSeconds(forward, side, false, 0)
        ).toBe(0)

        local pressuredPause = AISurvivorRules.turnPauseSeconds(
            forward,
            reverse,
            false,
            0.8
        )
        expect(pressuredPause < reversalPause).toBe(true)
    end)

    it("narrows route and pad choice width as risk falls", function()
        expect(AISurvivorRules.routeChoiceWidth(0.20, 8)).toBe(1)
        expect(AISurvivorRules.routeChoiceWidth(0.50, 8)).toBe(2)
        expect(AISurvivorRules.routeChoiceWidth(0.80, 8)).toBe(3)
        expect(AISurvivorRules.routeChoiceWidth(0.80, 2)).toBe(2)

        expect(AISurvivorRules.padChoiceWidth(0.40, 4)).toBe(1)
        expect(AISurvivorRules.padChoiceWidth(0.75, 4)).toBe(2)
        expect(AISurvivorRules.padChoiceWidth(0.75, 1)).toBe(1)
    end)

    it("increases bounded survival pressure as health and round danger worsen", function()
        local healthy = AISurvivorRules.survivalPressure(100, 100, false, false)
        local wounded = AISurvivorRules.survivalPressure(45, 100, false, false)
        local critical = AISurvivorRules.survivalPressure(20, 100, true, true)

        expect(healthy).toBe(0)
        expect(wounded > healthy).toBe(true)
        expect(critical > wounded).toBe(true)
        expect(critical <= 0.82).toBe(true)
    end)

    it("becomes more cautious under pressure without becoming perfect", function()
        local base = {
            Risk = 0.60,
            SocialChance = 0.30,
            MistakeChance = 0.16,
            PadChance = 0.25,
            HesitationChance = 0.10,
            ReconsiderChance = 0.08,
            FollowThrough = 1.0,
            DirectionBias = 0.4,
        }

        local calm = AISurvivorRules.pressuredTraits(base, 0)
        local pressured = AISurvivorRules.pressuredTraits(base, 0.8)

        expect(calm.Risk).toBe(base.Risk)
        expect(pressured.Risk < calm.Risk).toBe(true)
        expect(pressured.SocialChance < calm.SocialChance).toBe(true)
        expect(pressured.MistakeChance < calm.MistakeChance).toBe(true)
        expect(pressured.MistakeChance >= 0.03).toBe(true)
        expect(pressured.PadChance > calm.PadChance).toBe(true)
        expect(pressured.HesitationChance < calm.HesitationChance).toBe(true)
        expect(pressured.ReconsiderChance > calm.ReconsiderChance).toBe(true)
        expect(pressured.DirectionBias).toBe(base.DirectionBias)
    end)

    it("uses mobility pads more often when arena topology calls for them", function()
        local base = 0.20

        expect(AISurvivorRules.padInterest(base, "Classic", true, false)).toBe(base)
        expect(AISurvivorRules.padInterest(base, "Towers", true, false) > base).toBe(true)
        expect(AISurvivorRules.padInterest(base, "Towers", false, false)).toBe(base)
        expect(AISurvivorRules.padInterest(base, "Orbital", false, false) > base).toBe(true)
        expect(AISurvivorRules.padInterest(base, "Crossroads", false, false) > base).toBe(true)
        expect(AISurvivorRules.padInterest(base, "Classic", false, true) > base).toBe(true)
        expect(AISurvivorRules.padInterest(0.70, "Towers", true, true)).toBe(0.72)
    end)

    it("rejects unreachable vertical targets without a pad route", function()
        expect(AISurvivorRules.reachableElevation(3, 10, "Classic")).toBe(true)
        expect(AISurvivorRules.reachableElevation(3, 11, "Classic")).toBe(false)
        expect(AISurvivorRules.reachableElevation(3, 11.4, "Towers")).toBe(true)
        expect(AISurvivorRules.reachableElevation(3, 12, "Towers")).toBe(false)
        expect(AISurvivorRules.reachableElevation(12, 6, "Towers")).toBe(true)
    end)

    it("preserves plausible route continuity per arena", function()
        local center = Vector3.zero

        expect(
            AISurvivorRules.routeContinuity(
                "Orbital",
                Vector3.new(29, 0, 0),
                Vector3.new(29, 0, 12),
                center,
                0.2
            ) > 0
        ).toBe(true)
        expect(
            AISurvivorRules.routeContinuity(
                "Orbital",
                Vector3.new(29, 0, 0),
                Vector3.new(29, 0, -12),
                center,
                0.2
            ) < 0
        ).toBe(true)

        expect(
            AISurvivorRules.routeContinuity(
                "Towers",
                Vector3.new(28, 0, 28),
                Vector3.new(25, 8, 25),
                center,
                0
            ) > AISurvivorRules.routeContinuity(
                "Towers",
                Vector3.new(28, 0, 28),
                Vector3.new(-25, 8, -25),
                center,
                0
            )
        ).toBe(true)

        expect(
            AISurvivorRules.routeContinuity(
                "Crossroads",
                Vector3.new(24, 0, 2),
                Vector3.new(-20, 0, 1),
                center,
                0
            ) > AISurvivorRules.routeContinuity(
                "Crossroads",
                Vector3.new(24, 0, 2),
                Vector3.new(20, 0, 20),
                center,
                0
            )
        ).toBe(true)
    end)

    it("gives each arena a distinct route affinity", function()
        local center = Vector3.zero

        expect(
            AISurvivorRules.routeAffinity("Orbital", Vector3.new(29, 0, 0), center)
            > AISurvivorRules.routeAffinity("Orbital", Vector3.zero, center)
        ).toBe(true)

        expect(
            AISurvivorRules.routeAffinity("Crossroads", Vector3.new(30, 0, 0), center)
            > AISurvivorRules.routeAffinity("Crossroads", Vector3.new(20, 0, 20), center)
        ).toBe(true)

        expect(
            AISurvivorRules.routeAffinity("Towers", Vector3.new(28, 0, 28), center)
            > AISurvivorRules.routeAffinity("Towers", Vector3.new(28, 0, 0), center)
        ).toBe(true)

        expect(
            AISurvivorRules.routeAffinity("Classic", Vector3.new(24, 0, 0), center)
            > AISurvivorRules.routeAffinity("Classic", Vector3.zero, center)
        ).toBe(true)
    end)

    it("rejects collapsing or non-solid platform targets", function()
        expect(AISurvivorRules.platformAvailable(true, 0, nil)).toBe(true)
        expect(AISurvivorRules.platformAvailable(true, 0.2, "Warning")).toBe(false)
        expect(AISurvivorRules.platformAvailable(true, 1, "Gone")).toBe(false)
        expect(AISurvivorRules.platformAvailable(false, 0, nil)).toBe(false)
        expect(AISurvivorRules.platformAvailable(true, 0.95, nil)).toBe(false)
    end)

    it("keeps Freeze and JumpShock warning detection distances numeric", function()
        for _, kind in ipairs({"FreezeWarning", "JumpShockWarning"}) do
            local radius = AISurvivorRules.warningDetectionRadius(kind, 75)
            expect(type(radius)).toBe("number")
            expect(radius).toBe(80)
            expect(79.9 <= radius).toBe(true)
        end

        expect(AISurvivorRules.warningDetectionRadius("MeteorWarning", 12)).toBe(21)
        expect(AISurvivorRules.warningDetectionRadius("BombWarning", 8)).toBe(17)
        expect(AISurvivorRules.warningDetectionRadius("BombWarning", -10)).toBe(9)
    end)

    it("consumes each Freeze pulse only once even if the bot declines jumping", function()
        local handled = setmetatable({}, {__mode = "k"})
        local freeze = Instance.new("Part")
        freeze.Name = "FreezeWarning"

        expect(AISurvivorRules.consumeWarningJump(handled, freeze, 0.70)).toBe(false)
        expect(handled[freeze]).toBe(true)
        expect(AISurvivorRules.consumeWarningJump(handled, freeze, 0.10)).toBe(false)

        local nextFreeze = Instance.new("Part")
        nextFreeze.Name = "FreezeWarning"
        expect(AISurvivorRules.consumeWarningJump(handled, nextFreeze, 0.10)).toBe(true)
        expect(AISurvivorRules.consumeWarningJump(handled, nextFreeze, 0.10)).toBe(false)

        freeze:Destroy()
        nextFreeze:Destroy()
    end)

    it("allows one pre-jump per Shock warning and ignores unrelated markers", function()
        local handled = {}
        local shock = Instance.new("Part")
        shock.Name = "JumpShockWarning"
        expect(AISurvivorRules.consumeWarningJump(handled, shock, 0.99)).toBe(true)
        expect(AISurvivorRules.consumeWarningJump(handled, shock, 0.01)).toBe(false)

        local meteor = Instance.new("Part")
        meteor.Name = "MeteorWarning"
        expect(AISurvivorRules.consumeWarningJump(handled, meteor, 0.01)).toBe(false)
        expect(handled[meteor] == nil).toBe(true)
        expect(AISurvivorRules.consumeWarningJump(nil, shock, 0.01)).toBe(false)

        shock:Destroy()
        meteor:Destroy()
    end)

    it("delays reactions instead of granting perfect reflexes", function()
        expect(AISurvivorRules.reactionReady(10, 10.19, 0.20)).toBe(false)
        expect(AISurvivorRules.reactionReady(10, 10.20, 0.20)).toBe(true)
        expect(AISurvivorRules.reactionReady(10, 10.50, 0.34)).toBe(true)
    end)

    it("produces stable vote choices inside the available range", function()
        local index = AISurvivorRules.voteIndex(3, 3, 7)
        expect(index >= 1).toBe(true)
        expect(index <= 3).toBe(true)
        expect(AISurvivorRules.voteIndex(3, 3, 7)).toBe(index)
    end)
end)

return nil
