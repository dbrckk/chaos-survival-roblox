--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AISurvivorRules = require("../../src/server/AISurvivorRules")
local AISurvivorService = require("../../src/server/AISurvivorService")
local AISurvivorNetworkOwnership = require("../../src/server/AISurvivorNetworkOwnership")
local BotNameplateRules = require("../../src/shared/BotNameplateRules")
local ArenaVariants = require("../../src/server/ArenaVariants")
local OrbitalHelix = require("../../src/server/OrbitalHelix")

describe("AI survivor rules", function()
    it("loads the runtime AI survivor service contract in Roblox", function()
        expect(type(AISurvivorService)).toBe("table")
        expect(type(AISurvivorService.start)).toBe("function")
        expect(type(AISurvivorService.setRoundState)).toBe("function")
        expect(type(AISurvivorService.visibleCount)).toBe("function")
        expect(type(AISurvivorService.aliveRoundCount)).toBe("function")
        expect(type(AISurvivorService.names)).toBe("function")
    end)

    it("commits to real outer routes without selecting unreachable upper jumps", function()
        local hold = AISurvivorRules.outerRouteHold
        local approach = AISurvivorRules.outerStepReachable

        expect(hold(1.2, 80, 16, 1) >= 5.6).toBe(true)
        expect(hold(1.2, 80, 16, 1) <= 6.2).toBe(true)
        expect(hold(1.2, 130, 16, 1)).toBe(6.2)
        expect(hold(1.2, 20, 16, 2) > 1.2).toBe(true)
        expect(hold(1.2, 5, 16, 2)).toBe(1.2)
        expect(hold(1.2, 80, 16, nil)).toBe(1.2)
        expect(hold(1.2, 80, 16, 0)).toBe(1.2)
        expect(hold(1.2, math.huge, 16, 1)).toBe(1.2)
        expect(hold(1.2, 80, 0 / 0, 1)).toBe(1.2)
        expect(hold(1.2, -20, 16, 1)).toBe(1.2)
        expect(hold(1.2, 80, 16, 1) > hold(1.2, 80, 16, nil)).toBe(true)

        local ground = Vector3.new(0, 3, 0)
        local distantUpper = Vector3.new(58, 10, 52)
        local nearEntry = Vector3.new(13, 6, 0)
        expect(approach(1, ground, distantUpper, false)).toBe(true)
        expect(approach(1, ground, distantUpper, true)).toBe(false)
        expect(approach(2, ground, distantUpper, false)).toBe(false)
        expect(approach(2, ground, nearEntry, false)).toBe(true)
        expect(approach(2, ground, Vector3.new(13, 12, 0), false)).toBe(false)
        expect(approach(2, ground, nearEntry, true)).toBe(false)
        expect(approach(2, nil, nearEntry, false)).toBe(false)
        expect(approach(2, ground, nil, false)).toBe(false)
        expect(approach(nil, ground, distantUpper, false)).toBe(true)
    end)

    it("finishes deliberate world routes without suppressing emergency replans", function()
        local committed = AISurvivorRules.committedWorldRoute
        local folder = Instance.new("Folder")
        folder.Name = "RouteTestWorld"
        folder.Parent = workspace
        local target = Instance.new("Part")
        target.Parent = folder

        -- Ordinary waypoints can be reconsidered so bots still feel human.
        expect(committed(false, nil)).toBe(false)
        expect(committed(false, target)).toBe(false)
        -- A skyrail is a physical crossing that should not be abandoned
        -- halfway along merely because a reconsideration roll succeeded.
        expect(committed(true, target)).toBe(true)
        expect(committed(true, nil)).toBe(true)

        target:SetAttribute("PerimeterStep", 1)
        expect(committed(false, target)).toBe(true)
        target:SetAttribute("PerimeterStep", 2)
        expect(committed(false, target)).toBe(true)
        target:SetAttribute("PerimeterStep", 3)
        expect(committed(false, target)).toBe(false)
        -- Only a deliberate expedition owns later decks: casual wanderers
        -- may still change their minds when seeing an unreachable terrace.
        expect(committed(false, target, true)).toBe(true)
        target:SetAttribute("PerimeterStep", 8)
        expect(committed(false, target, true)).toBe(true)
        target:SetAttribute("PerimeterStep", nil)
        target:SetAttribute("BranchStep", 4)
        expect(committed(false, target)).toBe(false)
        expect(committed(false, target, true)).toBe(true)
        target:SetAttribute("BranchStep", nil)

        target:SetAttribute("GridCircuitIndex", 3)
        expect(committed(false, target)).toBe(true)
        target:SetAttribute("GridCircuitIndex", nil)
        target:SetAttribute("FluxRelayIndex", 1)
        expect(committed(false, target)).toBe(true)
        target:SetAttribute("FluxRelayIndex", nil)
        expect(committed(false, target)).toBe(false)

        -- Removed targets must not keep a bot committed to a stale model.
        target.Parent = nil
        target:SetAttribute("PerimeterStep", 1)
        expect(committed(false, target)).toBe(false)
        target:Destroy()
        folder:Destroy()
    end)

    it("keeps world objectives until reached while ordinary bots can reconsider", function()
        local chooseAgain = AISurvivorRules.shouldReplanTarget
        local strafe = AISurvivorRules.allowRouteStrafe
        local folder = Instance.new("Folder")
        folder.Parent = workspace
        local waypoint = Instance.new("Part")
        waypoint.Parent = folder
        local destination = Vector3.new(62, 8, 34)

        expect(chooseAgain("round", 5, 8, destination, false, waypoint)).toBe(false)
        expect(chooseAgain("round", 9, 8, destination, false, waypoint)).toBe(true)
        expect(strafe(false, false, waypoint)).toBe(true)

        waypoint:SetAttribute("PerimeterStep", 1)
        expect(chooseAgain("round", 11, 8, destination, false, waypoint)).toBe(false)
        expect(strafe(false, false, waypoint)).toBe(false)
        waypoint:SetAttribute("PerimeterStep", 2)
        expect(chooseAgain("round", 11, 8, destination, false, waypoint)).toBe(false)
        waypoint:SetAttribute("PerimeterStep", 6)
        expect(strafe(false, false, waypoint)).toBe(true)
        expect(strafe(false, false, waypoint, true)).toBe(false)
        expect(chooseAgain("round", 11, 8, destination,
            false, waypoint, false, true)).toBe(false)
        expect(chooseAgain("round", 13, 8, destination,
            false, waypoint, false, true)).toBe(true)
        expect(chooseAgain("round", 11, 8, destination,
            false, waypoint, true, true)).toBe(false)

        waypoint:SetAttribute("PerimeterStep", nil)
        waypoint:SetAttribute("BranchStep", 3)
        expect(strafe(false, false, waypoint, true)).toBe(false)
        expect(strafe(false, false, waypoint)).toBe(true)
        waypoint:SetAttribute("BranchStep", nil)
        waypoint:SetAttribute("GridCircuitIndex", 2)
        expect(chooseAgain("round", 11, 8, destination, false, waypoint)).toBe(false)
        expect(strafe(false, false, waypoint)).toBe(false)
        waypoint:SetAttribute("GridCircuitIndex", nil)
        waypoint:SetAttribute("FluxRelayIndex", 1)
        expect(chooseAgain("round", 11, 8, destination, false, waypoint)).toBe(false)
        expect(strafe(false, false, waypoint)).toBe(false)
        waypoint:SetAttribute("FluxRelayIndex", nil)

        expect(chooseAgain("round", 11, 8, destination, true, waypoint)).toBe(false)
        expect(chooseAgain("round", 13, 8, destination, true, waypoint)).toBe(true)
        expect(strafe(false, true, waypoint)).toBe(false)
        expect(strafe(true, false, waypoint)).toBe(false)
        expect(chooseAgain("intermission", 40, 8, destination, true, waypoint)).toBe(true)
        expect(chooseAgain("round", 40, 8, nil, true, waypoint)).toBe(true)
        waypoint.Parent = nil
        expect(chooseAgain("round", 40, 8, destination, false, waypoint)).toBe(true)
        expect(strafe(false, false, waypoint)).toBe(true)
        waypoint:Destroy()
        folder:Destroy()
    end)

    it("never interrupts a live hazard escape to choose a random route", function()
        local shouldReplan = AISurvivorRules.shouldReplanTarget
        local regularTarget = Vector3.new(36, 4, 18)
        local retreatTarget = Vector3.new(-18, 4, -22)
        local floor = Instance.new("Part")
        floor.Name = "SafePathGoal"
        floor.Parent = workspace

        -- A long-lived meteor or collapsing-platform evacuation overrides
        -- *any* roam/route timer, even during the last seconds of the round.
        for _, now in ipairs({1, 5, 40, 900}) do
            expect(shouldReplan("round", now, 0, retreatTarget,
                false, floor, true)).toBe(false)
            expect(shouldReplan("round", now, 0, retreatTarget,
                true, nil, true)).toBe(false)
        end
        -- When the hazard clears, ordinary roaming and deliberate world
        -- objectives regain their standard timing (including expiry).
        expect(shouldReplan("round", 10, 0, regularTarget,
            false, floor, false)).toBe(true)
        floor:SetAttribute("PerimeterStep", 1)
        expect(shouldReplan("round", 3, 0, regularTarget,
            false, floor, false)).toBe(false)
        expect(shouldReplan("round", 5, 0, regularTarget,
            false, floor, false)).toBe(true)
        -- An unusable escape target is not allowed to freeze the brain.
        expect(shouldReplan("round", 10, 0, nil,
            false, floor, true)).toBe(true)
        floor:Destroy()
    end)

    it("advances perimeter and branch stages only after a real grounded deck landing", function()
        local landed = AISurvivorRules.landedOnRouteDeck
        local frame = CFrame.new(36, 8, -18)
        local size = Vector3.new(12, 6, 12)
        -- The physical top is Y=11, and a HumanoidRootPart stands above it.
        expect(landed(frame, size, Vector3.new(36, 13.5, -18), true)).toBe(true)
        expect(landed(frame, size, Vector3.new(36, 13.5, -18), false)).toBe(false)
        expect(landed(frame, size, Vector3.new(36, 13.5, -18), nil)).toBe(false)
        expect(landed(frame, size, Vector3.new(36, 18, -18), true)).toBe(false)
        expect(landed(frame, size, Vector3.new(36, 13.5, -25), true)).toBe(false)
        expect(landed(frame, size, Vector3.new(36, 13.5, -18), true)).toBe(true)

        local rotated = frame * CFrame.Angles(0, math.rad(45), 0)
        local inside = rotated:PointToWorldSpace(Vector3.new(4, 5.5, 4))
        local outside = rotated:PointToWorldSpace(Vector3.new(6, 5.5, 0))
        expect(landed(rotated, size, inside, true)).toBe(true)
        expect(landed(rotated, size, outside, true)).toBe(false)
        expect(landed(frame, size, nil, true)).toBe(false)
        expect(landed(frame, Vector3.new(-1, 6, 12),
            Vector3.new(36, 13.5, -18), true)).toBe(false)
    end)

    it("avoids simultaneous rotated floor sweeps along the whole impact escape", function()
        local penalty = AISurvivorRules.floorSweepRoutePenalty
        local band = CFrame.new(0, 0, 0)
        local size = Vector3.new(8, 0.1, 68)

        -- Both endpoints are clear but the segment crosses the active lane.
        expect(penalty(Vector3.new(-20, 3, 0),
            Vector3.new(20, 3, 0), band, size)).toBe(90)
        -- An unthreatened sideways exit and elevated escape remain valid.
        expect(penalty(Vector3.new(20, 3, 0),
            Vector3.new(25, 3, 0), band, size)).toBe(0)
        expect(penalty(Vector3.new(-20, 15, 0),
            Vector3.new(20, 15, 0), band, size)).toBe(0)
        -- A bot already inside must NOT be discouraged from escaping out.
        expect(penalty(Vector3.new(0, 3, 0),
            Vector3.new(16, 3, 0), band, size)).toBe(0)
        expect(penalty(Vector3.new(0, 3, 0),
            Vector3.new(1, 3, 0), band, size)).toBe(125)
        expect(penalty(Vector3.new(-20, 3, 0),
            Vector3.new(1, 3, 0), band, size)).toBe(125)

        -- Rotation must follow the actual server-authored band, not assume
        -- global X/Z coordinates or fabricate a rectangular world axis.
        local rotated = CFrame.new(32, 0, -40)
            * CFrame.Angles(0, math.rad(90), 0)
        local first = rotated:PointToWorldSpace(Vector3.new(-20, 3, 0))
        local last = rotated:PointToWorldSpace(Vector3.new(20, 3, 0))
        expect(penalty(first, last, rotated, size)).toBe(90)
        expect(penalty(first, first, rotated, size)).toBe(0)
        expect(penalty(first, last, nil, size)).toBe(0)
        expect(penalty(first, last, rotated, Vector3.new(0, 0, 68))).toBe(0)
    end)

    it("uses a varied fictional identity pool without AI-labelled public names", function()
        local identities = AISurvivorService.identityCatalog()
        expect(#identities >= 20).toBe(true)
        local usernames = {}
        local displays = {}
        for _, identity in ipairs(identities) do
            local username, display = identity.Username, identity.DisplayName
            expect(type(username)).toBe("string")
            expect(type(display)).toBe("string")
            expect(#username >= 3 and #username <= 20).toBe(true)
            expect(#display >= 2 and #display <= 20).toBe(true)
            expect(username:match("^[%w_]+$") ~= nil).toBe(true)
            expect(username:lower():find("bot", 1, true) == nil).toBe(true)
            expect(display:lower() ~= "ai").toBe(true)
            expect(usernames[username:lower()] == nil).toBe(true)
            expect(displays[display:lower()] == nil).toBe(true)
            usernames[username:lower()] = true
            displays[display:lower()] = true
        end
        -- Callers must not be able to mutate the private live roster.
        local first = identities[1].Username
        identities[1].Username = "tampered"
        expect(AISurvivorService.identityCatalog()[1].Username).toBe(first)
    end)

    it("avoids confusing real players with identical AI names", function()
        local identities = {
            {Username = "NovaByte", DisplayName = "Nova"},
            {Username = "MiloRush", DisplayName = "Milo"},
            {Username = "KaiPixel", DisplayName = "Kai"},
        }
        local choose = AISurvivorRules.availableIdentityIndex
        expect(choose(identities, 1, {}, {})).toBe(1)
        expect(choose(identities, 1, {
            {Name = "realplayer", DisplayName = "nOvA"},
        }, {})).toBe(2)
        expect(choose(identities, 2, {
            {Name = "MILORUSH", DisplayName = "Other"},
        }, {})).toBe(3)
        expect(choose(identities, 3, {}, {
            {Username = "KaiPixel", DisplayName = "Kai"},
        })).toBe(1)
        expect(choose(identities, 1, {
            {Name = "NovaByte", DisplayName = "Nova"},
            {Name = "MiloRush", DisplayName = "Milo"},
            {Name = "KaiPixel", DisplayName = "Kai"},
        }, {})).toBe(nil)
        expect(choose({}, 1, {}, {})).toBe(nil)
    end)

    it("checks Roblox Instance names, not only Lua-table player doubles", function()
        local identities = {
            {Username = "NovaByte", DisplayName = "Nova"},
            {Username = "MiloRush", DisplayName = "Milo"},
            {Username = "KaiPixel", DisplayName = "Kai"},
        }
        -- Real Players:GetPlayers() entries have typeof == "Instance".
        -- Humanoid supplies both name fields without requiring a live player
        -- connection in the headless Roblox Open Cloud engine test.
        local playerLike = Instance.new("Humanoid")
        playerLike.Name = "RealPlayer"
        playerLike.DisplayName = "nOvA"
        local choose = AISurvivorRules.availableIdentityIndex
        expect(choose(identities, 1, {playerLike}, {})).toBe(2)

        playerLike.Name = "MILORUSH"
        playerLike.DisplayName = "Other"
        expect(choose(identities, 2, {playerLike}, {})).toBe(3)

        -- Generic Roblox instances lack DisplayName but must not crash.
        local nonPlayer = Instance.new("Folder")
        nonPlayer.Name = "NovaByte"
        expect(choose(identities, 1, {nonPlayer}, {})).toBe(2)
        nonPlayer:Destroy()
        playerLike:Destroy()
    end)

    it("clears a recycled bot's Classic Grid Circuit completion at each round", function()
        local model = Instance.new("Model")
        model:SetAttribute("GridCircuitStep", 4)
        model:SetAttribute("GridCircuitNext", 0)
        model:SetAttribute("GridCircuitDeadline", 1234)
        model:SetAttribute("GridCircuitComplete", true)
        expect(AISurvivorService.resetGridCircuit(model)).toBe(true)
        expect(model:GetAttribute("GridCircuitStep")).toBe(0)
        expect(model:GetAttribute("GridCircuitNext")).toBe(0)
        expect(model:GetAttribute("GridCircuitDeadline")).toBe(0)
        expect(model:GetAttribute("GridCircuitComplete")).toBe(false)
        expect(AISurvivorService.resetGridCircuit(nil)).toBe(false)
        model:Destroy()
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

        -- With real Orbital navigation the entry is reachable from a
        -- fresh floor spawn. The high reactor route must remain a later
        -- objective, reachable only after actually climbing a Helix.
        local orbital = ArenaVariants.get("Orbital")
        for index = 1, OrbitalHelix.Count do
            local entry = OrbitalHelix.accessRoute(
                orbital, Vector3.zero, index, "Entry"
            )
            local core = OrbitalHelix.accessRoute(
                orbital, Vector3.zero, index, "Core"
            )
            local function waypointFor(route)
                return route.CFrame.Position + route.CFrame.UpVector
                    * (route.Size.Y * 0.5 + 2.4)
            end
            local floorRoot = orbital.SpawnOffsets[index]
                + Vector3.new(0, 1.5, 0)
            local inner = orbital.Platforms[index + OrbitalHelix.Count]
            local innerRoot = inner.offset
                + Vector3.new(0, inner.size.Y * 0.5 + 2.4, 0)
            expect(rules.helixWaypointReachable(
                floorRoot, waypointFor(entry)
            )).toBe(true)
            expect(rules.helixWaypointReachable(
                floorRoot, waypointFor(core)
            )).toBe(false)
            expect(rules.helixWaypointReachable(
                innerRoot, waypointFor(core)
            )).toBe(true)
        end
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

    it("fills missing solo bots exactly at ready entry, never on later joins", function()
        local allowed = AISurvivorRules.rosterReconciliationAllowed
        expect(allowed("waiting", false)).toBe(true)
        expect(allowed("intermission", false)).toBe(true)
        expect(allowed("ready", true)).toBe(true)
        expect(allowed("ready", false)).toBe(false)
        expect(allowed("ready", nil)).toBe(false)
        expect(allowed("round", true)).toBe(false)
        expect(allowed("result", true)).toBe(false)

        -- One human needs three AI competitors at the committed transition.
        expect(AISurvivorRules.desiredBotCount(1)).toBe(3)
        expect(AISurvivorRules.rosterLocked("ready")).toBe(true)
    end)

    it("counts admitted ready contestants, not connected spectators, against solo bots", function()
        local count = AISurvivorRules.rosterHumanCount
        local desired = AISurvivorRules.desiredBotCount

        expect(count("ready", true, 3, 1)).toBe(1)
        expect(desired(count("ready", true, 3, 1))).toBe(3)
        expect(count("ready", true, 4, 2)).toBe(2)
        expect(desired(count("ready", true, 4, 2))).toBe(2)
        -- A late arrival cannot change an already committed roster.
        expect(count("ready", false, 3, 1)).toBe(3)
        expect(count("intermission", false, 3, 1)).toBe(3)
        -- Old or malformed payloads safely fall back to connected humans.
        expect(count("ready", true, 2, nil)).toBe(2)
        expect(count("ready", true, 2, 0)).toBe(2)
        expect(count("ready", true, 2, math.huge)).toBe(2)
        expect(count("ready", true, 2, 0 / 0)).toBe(2)
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

    it("cycles eight distinct grounded streetwear silhouettes without random rerolls", function()
        local seen = {}
        for index = 1, 20 do
            local style = AISurvivorRules.appearanceStyle(index)
            expect(style >= 1 and style <= 8).toBe(true)
            expect(AISurvivorRules.appearanceStyle(index)).toBe(style)
            seen[style] = true
        end

        local count = 0
        for _ in pairs(seen) do
            count += 1
        end
        expect(count).toBe(8)
        expect(AISurvivorRules.appearanceStyle(1)).toBe(1)
        expect(AISurvivorRules.appearanceStyle(6)).toBe(6)
        expect(AISurvivorRules.appearanceStyle(8)).toBe(8)
        expect(AISurvivorRules.appearanceStyle(9)).toBe(1)
        expect(AISurvivorRules.appearanceStyle(nil)).toBe(1)
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

    it("actually changes direction on sharp turns instead of running backward", function()
        local forward = Vector3.new(1, 0, 0)
        local backward = Vector3.new(-1, 0, 0)
        local reversal = AISurvivorRules.steeredDirection(forward, backward, false)
        expect(reversal:Dot(backward) > 0.99).toBe(true)
        expect(math.abs(reversal.Magnitude - 1) < 0.001).toBe(true)

        -- Off-axis 130-degree turns must also make forward progress toward
        -- the new target, while regular right-angle turns stay smooth.
        local angled = Vector3.new(-0.65, 0, 0.76).Unit
        local pivot = AISurvivorRules.steeredDirection(forward, angled, false)
        expect(pivot:Dot(angled) > 0.50).toBe(true)
        expect(pivot.Y).toBe(0)

        local zeroHistory = AISurvivorRules.steeredDirection(Vector3.zero, backward, false)
        expect((zeroHistory - backward).Magnitude < 0.001).toBe(true)
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

    it("times bot Jump Shock reactions to the late rising-dodge window", function()
        local ready = AISurvivorRules.shockJumpWindow
        -- 1.05 second ring: early jumping should never count as a dodge.
        expect(ready(100, 1.05, 100.20)).toBe(false)
        expect(ready(100, 1.05, 100.72)).toBe(true)
        expect(ready(100, 1.05, 100.90)).toBe(true)
        expect(ready(100, 1.05, 101.01)).toBe(false)
        expect(ready(100, 1.05, 101.06)).toBe(false)
        expect(ready(nil, 1.05, 100.90)).toBe(false)
        expect(ready(100, 0, 100.90)).toBe(false)
        expect(ready(100, math.huge, 100.90)).toBe(false)
        expect(ready(100, 1.05, math.huge)).toBe(false)
        expect(ready(100, 1.05, 0 / 0)).toBe(false)
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

    it("lets bots anticipate the final blast radius rather than the starting marker", function()
        local radius = AISurvivorRules.warningDetectionRadius
        -- Both hazards start with a 5.5 stud-wide marker, but ultimately
        -- hit within eight studs of their impact center.
        expect(radius("MeteorWarning", 2.75, 16)).toBe(17)
        expect(radius("BombWarning", 2.75, 16)).toBe(17)
        expect(radius("BombWarning", 10, 16)).toBe(19)
        expect(radius("MeteorWarning", 2.75, 0)).toBe(11.75)
        expect(radius("MeteorWarning", 2.75, nil)).toBe(11.75)
        expect(radius("MeteorWarning", 2.75, math.huge)).toBe(11.75)
        expect(radius("MeteorWarning", 2.75, 0 / 0)).toBe(11.75)
        expect(radius("FreezeWarning", 12, 40)).toBe(80)
        expect(radius("JumpShockWarning", 12, 40)).toBe(80)
        expect(radius("MeteorWarning", 1, 1000000)).toBe(129)
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

    it("plans a real full-length Skyrail traversal from elevated decks only", function()
        local r = AISurvivorRules
        local north = CFrame.new(0, 12.5, -28)
        local span = Vector3.new(49, 1, 4.5)
        local target, sign = r.skyrailCrossingTarget(
            Vector3.new(28, 15.4, -28), north, span)
        expect(target ~= nil).toBe(true)
        expect(sign).toBe(-1)
        expect(target.X < -17).toBe(true)
        expect(math.abs(target.Z + 28) < 0.1).toBe(true)
        local reverse, otherSign = r.skyrailCrossingTarget(
            Vector3.new(-28, 15.4, -28), north, span)
        expect(reverse.X > 17).toBe(true)
        expect(otherSign).toBe(1)
        expect(r.skyrailCrossingTarget(
            Vector3.new(28, 3, -28), north, span) == nil).toBe(true)
        expect(r.skyrailCrossingTarget(
            Vector3.new(0, 15.4, -28), north, span) == nil).toBe(true)
        expect(r.skyrailCrossingTarget(
            Vector3.new(28, 15.4, -40), north, span) == nil).toBe(true)
        expect(r.skyrailCrossingTarget(
            Vector3.new(28, 15.4, -28), north, Vector3.new(49, 1, 2)) == nil).toBe(true)
        local west = CFrame.new(-28, 12.5, 0)
        local zTarget, zSign = r.skyrailCrossingTarget(
            Vector3.new(-28, 15.4, 28), west, Vector3.new(4.5, 1, 49))
        expect(zSign).toBe(-1)
        expect(zTarget.Z < -17).toBe(true)
        local moved = r.skyrailExitTarget(
            CFrame.new(-20, 12.5, 0), Vector3.new(4.5, 1, 22), zSign)
        expect(moved.Z < -5).toBe(true)
        expect(r.skyrailExitTarget(west, span, 0) == nil).toBe(true)

        -- A temporary Skybridge outage must redirect bots to a supported
        -- tower endpoint instead of an unsafe sideways dodge toward hub.
        local northEast = r.skybridgeEscapeTarget(
            Vector3.new(12, 15.4, -28), north, span,
            Vector3.new(-17, 0, 0))
        expect(northEast ~= nil).toBe(true)
        expect(northEast.X > 26 and northEast.X < 28).toBe(true)
        expect(math.abs(northEast.Z + 28) < 0.01).toBe(true)
        local northWest = r.skybridgeEscapeTarget(
            Vector3.new(-13, 15.4, -28), north, span, Vector3.zero)
        expect(northWest.X < -26).toBe(true)
        local midForward = r.skybridgeEscapeTarget(
            Vector3.new(0, 15.4, -28), north, span, Vector3.new(-15, 0, 0))
        expect(midForward.X < -26).toBe(true)
        local westExit = r.skybridgeEscapeTarget(
            Vector3.new(-28, 15.4, 8), west,
            Vector3.new(4.5, 1, 49), Vector3.zero)
        expect(westExit.Z > 26).toBe(true)
        expect(math.abs(westExit.X + 28) < 0.01).toBe(true)
        expect(r.skybridgeEscapeTarget(
            Vector3.new(0, 3, -28), north, span) == nil).toBe(true)
        expect(r.skybridgeEscapeTarget(
            Vector3.new(0, 15.4, -38), north, span) == nil).toBe(true)
        expect(r.skybridgeEscapeTarget(
            Vector3.new(0, 15.4, -28), north, Vector3.new(49, 1, 2)
        ) == nil).toBe(true)
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

    it("holds a live hazard target through overlapping warning proximity ties", function()
        local keep = AISurvivorRules.keepThreatFocus
        -- Two warnings cross in perceived distance while a survivor dodges.
        -- The old target must remain within the next closest detection
        -- envelope; a clearly nearer threat can still interrupt it.
        expect(keep(11, 9, 4)).toBe(true)
        expect(keep(13, 9, 4)).toBe(true)
        expect(keep(13.1, 9, 4)).toBe(false)
        expect(keep(4, 9, 4)).toBe(true)
        expect(keep(19, 9, 4)).toBe(false)
        -- Do not retain a destroyed/out-of-range warning represented by
        -- an infinite/missing distance when scanning the live warning set.
        expect(keep(math.huge, 9, 4)).toBe(false)
        expect(keep(9, math.huge, 4)).toBe(false)
        expect(keep(nil, 9, 4)).toBe(false)
        expect(keep(0 / 0, 9, 4)).toBe(false)
        expect(keep(5, -1, 4)).toBe(false)
        -- Bound hysteresis so a stale target cannot win forever.
        expect(keep(16, 9, 999)).toBe(false)
        expect(keep(15, 9, 999)).toBe(true)
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


describe("AI survivor nameplate readability", function()
    it("emphasizes real lobby and results phases but not active hazards", function()
        for _, phase in ipairs({"ready", "intermission", "result"}) do
            local view = BotNameplateRules.presentation(phase, "High", false)
            expect(view.AlwaysOnTop).toBe(true)
            expect(view.MaxDistance).toBe(96)
            expect(view.StrokeTransparency).toBe(0.24)
        end

        for _, phase in ipairs({"waiting", "round", "vote", "unknown"}) do
            local view = BotNameplateRules.presentation(phase, "High", false)
            expect(view.AlwaysOnTop).toBe(false)
            expect(view.MaxDistance).toBe(72)
            expect(view.StrokeTransparency).toBe(0.38)
        end
    end)

    it("reduces low-tier touch-label overdraw without hiding nearby bots", function()
        local ready = BotNameplateRules.presentation("ready", "Low", true)
        local round = BotNameplateRules.presentation("round", "Low", true)
        expect(ready.MaxDistance).toBe(58)
        expect(round.MaxDistance).toBe(42)
        expect(ready.AlwaysOnTop).toBe(false)
        expect(round.AlwaysOnTop).toBe(false)
        expect(BotNameplateRules.presentation("round", "Medium", true).MaxDistance)
            .toBe(54)
        expect(BotNameplateRules.presentation("ready", "High", true).MaxDistance)
            .toBe(72)
        expect(BotNameplateRules.presentation("round", "Low", false).MaxDistance)
            .toBe(72)
    end)
end)


describe("Bot escape intelligence for moving veteran tornado", function()
    it("reads the live visible cyclone center and uses safe fallback", function()
        local rules = AISurvivorRules
        local fallback = Vector3.new(0, 4, 0)
        expect(rules.tornadoCenter(nil, fallback)).toBe(fallback)
        expect(rules.tornadoCenter("broken", fallback)).toBe(fallback)
        expect(rules.tornadoCenter(nil, nil)).toBe(nil)
        local cyclone = Instance.new("Model")
        cyclone.Name = "RoundTornado"
        cyclone.Parent = workspace
        expect(rules.tornadoCenter(cyclone, fallback)).toBe(fallback)

        local lower = Instance.new("Part")
        lower.Name = "LowerFunnel"
        lower.Position = Vector3.new(12, 7, -9)
        lower.Parent = cyclone
        local live = rules.tornadoCenter(cyclone, fallback)
        expect(live).toBe(Vector3.new(12, 4, -9))
        lower.Position = Vector3.new(-10, 7, 8)
        expect(rules.tornadoCenter(cyclone, fallback))
            .toBe(Vector3.new(-10, 4, 8))
        cyclone:Destroy()
    end)

    it("rewards avoiding the current vortex and using upper platforms", function()
        local score = AISurvivorRules.tornadoRouteScore
        local center = Vector3.zero
        local close = Vector3.new(5, 4, 0)
        local far = Vector3.new(32, 4, 0)
        expect(score(far, center, 0.2) > score(close, center, 0.2))
            .toBe(true)
        local higher = Vector3.new(12, 28, 0)
        local ground = Vector3.new(12, 4, 0)
        expect(score(higher, center, 0.2) > score(ground, center, 0.2))
            .toBe(true)
        expect(score(ground, center, 0.2) > score(ground, center, 1.0))
            .toBe(true)
        expect(score(nil, center, 0.2)).toBe(0)
        expect(score(ground, nil, 0.2)).toBe(0)
        -- Identical absolute positions are no longer equally safe after
        -- the tornado moves away from the map's original center.
        expect(score(ground, Vector3.new(-10, 0, 0), 0.2)
            > score(ground, Vector3.new(12, 0, 0), 0.2)).toBe(true)
    end)
end)

return nil
