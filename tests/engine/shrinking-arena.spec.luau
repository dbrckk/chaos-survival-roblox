--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local ShrinkingArena = require("../../src/server/Disasters/ShrinkingArena")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
local ArenaMechanics = require("../../src/server/ArenaMechanics")

local function cleanup(callbacks, objects)
    for _, fn in ipairs(callbacks) do
        pcall(fn)
    end
    for _, object in ipairs(objects) do
        if object and object.Parent then
            object:Destroy()
        end
    end
end

describe("Shrinking Arena mobility integration", function()
    it("keeps every ordinary platform trim on its moving deck and restores it", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local decor = arena and arena:FindFirstChild("Decor")
        local deck = platforms and platforms:FindFirstChild("Platform1")
        expect(deck ~= nil).toBe(true)
        expect(decor ~= nil).toBe(true)
        local originalDeck = deck.CFrame
        local originalDeckSize = deck.Size
        local base = arena:FindFirstChild("Base")
        local originalFloorX = base.Size.X

        -- The cosmetic pieces must remain attached to their associated
        -- physical deck, not to the arena center or their old world pose.
        local names = {
            "PlatformGlow1",
            "PlatformPanel1",
            "PlatformUnderFrame1",
            "PlatformCoreGlow1",
            "PlatformSupport1_1",
            "PlatformBevel1_1",
            "PlatformBevel1_4",
        }
        local snapshot = {}
        for _, name in ipairs(names) do
            local piece = decor:FindFirstChild(name)
            expect(piece ~= nil).toBe(true)
            expect(piece.CanCollide).toBe(false)
            snapshot[piece] = {
                cframe = piece.CFrame,
                size = piece.Size,
                relative = deck.CFrame:ToObjectSpace(piece.CFrame),
            }
        end

        local active = true
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.32,
            Cleanup = {},
            OnCleanup = callbacks,
            Active = function() return active end,
        })
        task.wait(0.19)

        expect((deck.Position - originalDeck.Position).Magnitude > 0.2)
            .toBe(true)
        local scale = base.Size.X / originalFloorX
        expect(scale < 0.98).toBe(true)
        expect(math.abs(deck.Size.X - originalDeckSize.X * scale) < 0.02)
            .toBe(true)
        expect(math.abs(deck.Size.Z - originalDeckSize.Z * scale) < 0.02)
            .toBe(true)
        for piece, original in pairs(snapshot) do
            local p = original.relative.Position
            local expected = deck.CFrame
                * CFrame.new(p.X * scale, p.Y, p.Z * scale)
                * (original.relative - p)
            expect((piece.Position - expected.Position).Magnitude < 0.02)
                .toBe(true)
            local size = Vector3.new(
                original.size.X * scale,
                original.size.Y,
                original.size.Z * scale
            )
            expect((piece.Size - size).Magnitude < 0.02)
                .toBe(true)
            expect(piece.CanCollide).toBe(false)
        end

        active = false
        cleanup(callbacks, {})
        expect((deck.Position - originalDeck.Position).Magnitude < 0.001)
            .toBe(true)
        expect((deck.Size - originalDeckSize).Magnitude < 0.001)
            .toBe(true)
        for piece, original in pairs(snapshot) do
            expect((piece.Position - original.cframe.Position).Magnitude < 0.001)
                .toBe(true)
            expect((piece.Size - original.size).Magnitude < 0.001)
                .toBe(true)
        end
        root:Destroy()
    end)

    it("moves outer exit sculptures together with shrinking physical routes", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local decor = arena:FindFirstChild("Decor")
            local platforms = arena:FindFirstChild("Platforms")
            local base = arena:FindFirstChild("Base")
            -- Exit facade follows the LAST physical terrace (step 8),
            -- not the old fourth platform in the enlarged route.
            local number = #ArenaVariants.get(id).Platforms
                + ArenaVariants.PerimeterSteps
            local deck = platforms:FindFirstChild("Platform" .. number)
            expect(deck ~= nil).toBe(true)
            local startDeck = deck.CFrame
            local floorWidth = base.Size.X
            local pieces = {}
            for _, name in ipairs({
                "PerimeterExitRib1_-1", "PerimeterExitRib1_1",
                "PerimeterExitCrown1", "PerimeterExitLens1",
            }) do
                local piece = decor:FindFirstChild(name)
                expect(piece ~= nil).toBe(true)
                expect(piece:GetAttribute("PerimeterPlatformIndex")).toBe(number)
                pieces[piece] = {
                    size = piece.Size,
                    cframe = piece.CFrame,
                    relative = deck.CFrame:ToObjectSpace(piece.CFrame),
                }
            end

            local active = true
            local callbacks = {}
            ShrinkingArena.start({
                Config = Config, RoundSeconds = 0.32,
                Cleanup = {}, OnCleanup = callbacks,
                Active = function() return active end,
            })
            task.wait(0.19)
            local scale = base.Size.X / floorWidth
            expect(scale < 0.98).toBe(true)
            expect((deck.Position - startDeck.Position).Magnitude > 0.1).toBe(true)
            for piece, state in pairs(pieces) do
                local offset = state.relative.Position
                local expected = deck.CFrame
                    * CFrame.new(offset.X * scale, offset.Y, offset.Z * scale)
                    * (state.relative - offset)
                expect((piece.Position - expected.Position).Magnitude < 0.03).toBe(true)
                expect(math.abs(piece.Size.X - state.size.X * scale) < 0.03
                    and math.abs(piece.Size.Z - state.size.Z * scale) < 0.03)
                    .toBe(true)
                expect(piece.CanCollide).toBe(false)
            end
            active = false
            cleanup(callbacks, {})
            expect((deck.Position - startDeck.Position).Magnitude < 0.001).toBe(true)
            for piece, state in pairs(pieces) do
                expect((piece.Position - state.cframe.Position).Magnitude < 0.001)
                    .toBe(true)
                expect((piece.Size - state.size).Magnitude < 0.001).toBe(true)
            end
            root:Destroy()
        end
    end)

    it("shrinks arena inlays with the solid floor in every variant", function()
        local cases = {
            {
                id = "Classic",
                names = {"ArenaDeckInset", "DeckLineNorth", "ClassicGridX-2",
                    "ClassicEntryChevron1_-1"},
            },
            {
                id = "Towers",
                names = {"ArenaDeckInset", "DeckLineEast",
                    "TowerGroundPlate1", "TowerGroundCore1",
                    "TowerAscentChevron1_-1"},
            },
            {
                id = "Crossroads",
                names = {"ArenaDeckInset", "DeckLineSouth",
                    "CrossroadLaneFill1", "FluxRouteChevron1_1_-1"},
            },
            {
                id = "Orbital",
                names = {"ArenaDeckInset", "DeckLineWest"},
            },
        }

        for _, case in ipairs(cases) do
            local root = MapBuilder.build(Config, case.id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local decor = arena:FindFirstChild("Decor")
            local origin = base.CFrame
            local originalBase = base.Size
            local floorSnapshot = {}
            for _, name in ipairs(case.names) do
                local part = decor:FindFirstChild(name)
                expect(part ~= nil).toBe(true)
                expect(part.CanCollide).toBe(false)
                floorSnapshot[part] = {
                    cframe = part.CFrame,
                    size = part.Size,
                    localPosition = origin:PointToObjectSpace(part.Position),
                }
            end

            local active = true
            local callbacks = {}
            ShrinkingArena.start({
                Config = Config,
                RoundSeconds = 0.33,
                Cleanup = {},
                OnCleanup = callbacks,
                Active = function() return active end,
            })
            task.wait(0.20)
            local scale = base.Size.X / originalBase.X
            expect(scale < 0.90).toBe(true)

            for piece, before in pairs(floorSnapshot) do
                local expectedSize, expectedPosition =
                    ShrinkingArena.scaledFloorTransform(
                        before.size, before.localPosition, scale
                    )
                local expectedWorld = origin:PointToWorldSpace(expectedPosition)
                expect((piece.Size - expectedSize).Magnitude < 0.02)
                    .toBe(true)
                expect((piece.Position - expectedWorld).Magnitude < 0.02)
                    .toBe(true)
                expect(piece.CanCollide).toBe(false)
            end
            local inset = decor:FindFirstChild("ArenaDeckInset")
            expect(inset.Size.X < base.Size.X).toBe(true)
            expect(inset.Size.Z < base.Size.Z).toBe(true)

            active = false
            cleanup(callbacks, {})
            for piece, before in pairs(floorSnapshot) do
                expect((piece.CFrame.Position - before.cframe.Position).Magnitude < 0.001)
                    .toBe(true)
                expect((piece.Size - before.size).Magnitude < 0.001)
                    .toBe(true)
            end
            root:Destroy()
        end
    end)

    it("moves mobility pads inward and restores them on cleanup", function()
        MapBuilder.build(Config, "Towers", ArenaVariants)

        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local base = arena and arena:FindFirstChild("Base")
        expect(base ~= nil).toBe(true)

        local mechanics = Instance.new("Folder")
        mechanics.Name = "Mechanics"
        mechanics.Parent = arena

        local pad = Instance.new("Part")
        pad.Name = "MobilityPadRegression"
        pad.Anchored = true
        pad.Size = Vector3.new(6.5, 0.35, 6.5)
        pad.Position = (base :: BasePart).Position + Vector3.new(28, 1.7, 28)
        pad:SetAttribute("ArenaMobilityPad", true)
        pad:SetAttribute("ImpulseX", 40)
        pad:SetAttribute("ImpulseY", 10)
        pad:SetAttribute("ImpulseZ", -20)
        pad.Parent = mechanics

        local original = pad.CFrame
        local originalImpulse = Vector3.new(40, 10, -20)
        local originalDistance = (
            Vector3.new(pad.Position.X, 0, pad.Position.Z)
            - Vector3.new((base :: BasePart).Position.X, 0, (base :: BasePart).Position.Z)
        ).Magnitude

        local active = true
        local objects = {}
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.30,
            Cleanup = objects,
            OnCleanup = callbacks,
            Active = function()
                return active
            end,
        })

        task.wait(0.18)

        local movedDistance = (
            Vector3.new(pad.Position.X, 0, pad.Position.Z)
            - Vector3.new((base :: BasePart).Position.X, 0, (base :: BasePart).Position.Z)
        ).Magnitude
        expect(movedDistance < originalDistance).toBe(true)

        local shrunkImpulse = Vector3.new(
            tonumber(pad:GetAttribute("ImpulseX")) or 0,
            tonumber(pad:GetAttribute("ImpulseY")) or 0,
            tonumber(pad:GetAttribute("ImpulseZ")) or 0
        )
        expect(math.abs(shrunkImpulse.X) < math.abs(originalImpulse.X)).toBe(true)
        expect(math.abs(shrunkImpulse.Z) < math.abs(originalImpulse.Z)).toBe(true)
        expect(shrunkImpulse.Y).toBe(originalImpulse.Y)

        active = false
        cleanup(callbacks, objects)
        expect(pad.CFrame).toBe(original)
        expect(pad:GetAttribute("ImpulseX")).toBe(originalImpulse.X)
        expect(pad:GetAttribute("ImpulseY")).toBe(originalImpulse.Y)
        expect(pad:GetAttribute("ImpulseZ")).toBe(originalImpulse.Z)

        if generated then
            generated:Destroy()
        end
    end)
    it("shrinks four Tower Run skybridge decks, rails and supports as one assembly", function()
        local root = MapBuilder.build(Config, "Towers", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local decor = arena:FindFirstChild("Decor")
        local originals = {}
        local details = {}

        -- The new tower traversal must shrink as a complete connected
        -- physical system, not leave its decks full-sized under small
        -- moving skybridges.
        local tiers = {}
        for _, index in ipairs({1, 2, 3, 13, 14}) do
            local deck = platforms:FindFirstChild("Platform" .. index)
            local panel = decor:FindFirstChild("PlatformPanel" .. index)
            expect(deck ~= nil).toBe(true)
            expect(panel ~= nil).toBe(true)
            expect(deck:GetAttribute("RouteTier") ~= nil).toBe(true)
            tiers[#tiers + 1] = {
                deck = deck,
                panel = panel,
                deckCFrame = deck.CFrame,
                deckSize = deck.Size,
                panelCFrame = panel.CFrame,
                panelSize = panel.Size,
            }
        end
        local base = arena:FindFirstChild("Base")
        local baseOriginalX = base.Size.X

        expect(ShrinkingArena.skybridgeSpan(49, 1)).toBe(49)
        expect(math.abs(ShrinkingArena.skybridgeSpan(49, 0.45) - 18.2) < 0.01).toBe(true)
        for index = 18, 21 do
            local bridge = platforms:FindFirstChild("Skybridge" .. index)
            expect(bridge ~= nil).toBe(true)
            expect(bridge.CanCollide).toBe(true)
            expect(bridge:GetAttribute("ChaosSkybridge")).toBe(true)
            local prefix = {
                "SkybridgeRail" .. index .. "_1",
                "SkybridgeRib" .. index .. "_0",
                "PlatformGlow" .. index,
                "PlatformPanel" .. index,
                "PlatformUnderFrame" .. index,
                "PlatformCoreGlow" .. index,
                "PlatformSupport" .. index .. "_1",
                "PlatformBevel" .. index .. "_1",
                "PlatformBevel" .. index .. "_4",
            }
            originals[bridge] = {cf = bridge.CFrame, size = bridge.Size}
            details[bridge] = {}
            for _, name in ipairs(prefix) do
                local part = decor:FindFirstChild(name)
                expect(part ~= nil).toBe(true)
                originals[part] = {cf = part.CFrame, size = part.Size}
                table.insert(details[bridge], part)
            end
        end

        local running = true
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config, RoundSeconds = 0.36,
            Cleanup = {}, OnCleanup = callbacks,
            Active = function() return running end,
        })
        task.wait(0.22)

        local shrinkScale = base.Size.X / baseOriginalX
        expect(shrinkScale < 1).toBe(true)
        for _, tier in ipairs(tiers) do
            expect(math.abs(tier.deck.Size.X
                - tier.deckSize.X * shrinkScale) < 0.03).toBe(true)
            expect(math.abs(tier.deck.Size.Z
                - tier.deckSize.Z * shrinkScale) < 0.03).toBe(true)
            expect(math.abs(tier.panel.Size.X
                - tier.panelSize.X * shrinkScale) < 0.03).toBe(true)
            expect(math.abs(tier.panel.Size.Z
                - tier.panelSize.Z * shrinkScale) < 0.03).toBe(true)
        end

        for bridge, old in pairs(originals) do
            if bridge:GetAttribute("ChaosSkybridge") == true then
                local alongX = old.size.X > old.size.Z
                local originalSpan = math.max(old.size.X, old.size.Z)
                local shrunkSpan = math.max(bridge.Size.X, bridge.Size.Z)
                expect(shrunkSpan < originalSpan).toBe(true)
                expect(shrunkSpan > 4).toBe(true)
                expect(bridge.CanCollide).toBe(true)
                -- North/south/east/west spans follow their tower rows inward.
                expect((bridge.Position - Config.ArenaCenter).Magnitude
                    < (old.cf.Position - Config.ArenaCenter).Magnitude).toBe(true)

                for _, detail in ipairs(details[bridge]) do
                    local prior = originals[detail]
                    local d0 = alongX and prior.size.X or prior.size.Z
                    local d1 = alongX and detail.Size.X or detail.Size.Z
                    if d0 > 2.2 then
                        expect(d1 < d0).toBe(true)
                    end
                    expect(detail.CanCollide).toBe(false)
                    expect(detail.Parent).toBe(decor)
                end
            end
        end

        running = false
        cleanup(callbacks, {})
        for _, tier in ipairs(tiers) do
            expect((tier.deck.Position - tier.deckCFrame.Position).Magnitude < 0.001)
                .toBe(true)
            expect((tier.panel.Position - tier.panelCFrame.Position).Magnitude < 0.001)
                .toBe(true)
            expect((tier.deck.Size - tier.deckSize).Magnitude < 0.001)
                .toBe(true)
            expect((tier.panel.Size - tier.panelSize).Magnitude < 0.001)
                .toBe(true)
        end
        for part, old in pairs(originals) do
            expect((part.Position - old.cf.Position).Magnitude < 0.001).toBe(true)
            expect((part.Size - old.size).Magnitude < 0.001).toBe(true)
        end
        root:Destroy()
    end)

    it("keeps Crossroads Flux Relays on the shrinking base and restores gate locations", function()
        local root = MapBuilder.build(Config, "Crossroads", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local mechanicsCtx = {
            Active = function() return true end,
            IsContestantActive = function() return false end,
            Cleanup = {},
            Contestants = {},
        }
        ArenaMechanics.start(mechanicsCtx, "Crossroads")
        local mechanics = arena:FindFirstChild("Mechanics")
        local relays = mechanics and mechanics:FindFirstChild("FluxRelays")
        expect(relays ~= nil).toBe(true)
        expect(#relays:GetChildren()).toBe(4)

        local base = arena:FindFirstChild("Base")
        local platforms = arena:FindFirstChild("Platforms")
        local decor = arena:FindFirstChild("Decor")
        local initialFloorWidth = base.Size.X
        local routePieces = {}
        for _, index in ipairs({1, 3, 10, 14}) do
            local deck = platforms:FindFirstChild("Platform" .. index)
            local panel = decor:FindFirstChild("PlatformPanel" .. index)
            expect(deck ~= nil).toBe(true)
            expect(panel ~= nil).toBe(true)
            expect(deck:GetAttribute("RouteTier") ~= nil).toBe(true)
            routePieces[#routePieces + 1] = {
                deck = deck, panel = panel,
                deckCFrame = deck.CFrame, panelCFrame = panel.CFrame,
                deckSize = deck.Size, panelSize = panel.Size,
            }
        end
        local original = {}
        for _, gate in ipairs(relays:GetChildren()) do
            original[gate] = gate.CFrame
        end
        local active = true
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.36,
            Cleanup = {}, OnCleanup = callbacks,
            Active = function() return active end,
        })
        task.wait(0.22)
        local scale = base.Size.X / initialFloorWidth
        expect(scale < 0.98).toBe(true)
        for _, route in ipairs(routePieces) do
            expect(math.abs(route.deck.Size.X - route.deckSize.X * scale) < 0.03)
                .toBe(true)
            expect(math.abs(route.deck.Size.Z - route.deckSize.Z * scale) < 0.03)
                .toBe(true)
            expect(math.abs(route.panel.Size.X - route.panelSize.X * scale) < 0.03)
                .toBe(true)
            expect(math.abs(route.panel.Size.Z - route.panelSize.Z * scale) < 0.03)
                .toBe(true)
        end
        for gate, old in pairs(original) do
            local current = gate.Position - Config.ArenaCenter
            local before = old.Position - Config.ArenaCenter
            local planarCurrent = Vector3.new(current.X, 0, current.Z).Magnitude
            local planarBefore = Vector3.new(before.X, 0, before.Z).Magnitude
            expect(planarCurrent < planarBefore - 0.2).toBe(true)
            expect(gate.CanCollide).toBe(false)
            expect(gate.CanTouch).toBe(true)
            expect(gate:GetAttribute("FluxCycleEpoch") ~= nil).toBe(true)
        end
        active = false
        cleanup(callbacks, {})
        for _, route in ipairs(routePieces) do
            expect((route.deck.Size - route.deckSize).Magnitude < 0.001).toBe(true)
            expect((route.panel.Size - route.panelSize).Magnitude < 0.001).toBe(true)
            expect((route.deck.Position - route.deckCFrame.Position).Magnitude < 0.001)
                .toBe(true)
            expect((route.panel.Position - route.panelCFrame.Position).Magnitude < 0.001)
                .toBe(true)
        end
        for gate, old in pairs(original) do
            expect((gate.CFrame.Position - old.Position).Magnitude < 0.001).toBe(true)
        end
        root:Destroy()
    end)

    it("shrinks every Orbital ramp with the decks, then restores its beams", function()
        local root = MapBuilder.build(Config, "Orbital", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local helix = arena and arena:FindFirstChild("HelixCircuit")
        expect(platforms ~= nil).toBe(true)
        expect(helix ~= nil).toBe(true)

        local originals = {}
        local source = OrbitalHelix.capture(helix)
        expect(#source).toBe(24)
        local states = {}
        for _, state in ipairs(source) do
            states[state.ramp] = state
            originals[state.ramp] = {
                cf = state.ramp.CFrame,
                size = state.ramp.Size,
            }
            expect(#state.decorations).toBe(
                (state.ramp:GetAttribute("OrbitalHelixRamp") == true
                    or state.ramp.Name == "HelixRamp9") and 8 or 4
            )
            for _, d in ipairs(state.decorations) do
                originals[d.part] = {cf = d.part.CFrame, size = d.part.Size}
            end
        end

        local active = true
        local objects = {}
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.36,
            Cleanup = objects,
            OnCleanup = callbacks,
            Active = function() return active end,
        })
        task.wait(0.22)

        local factor = arena:FindFirstChild("Base").Size.X
            / ArenaVariants.get("Orbital").BaseSize.X
        local advanced = 0
        for index = 1, 8 do
            local outer = platforms:FindFirstChild("Platform" .. index)
            local inner = platforms:FindFirstChild("Platform" .. (index + 8))
            local ramp = helix:FindFirstChild("HelixRamp" .. index)
            expect(outer ~= nil).toBe(true)
            expect(inner ~= nil).toBe(true)
            expect(ramp ~= nil).toBe(true)

            local from = outer.Position + Vector3.new(0, outer.Size.Y * 0.5 - 0.15, 0)
            local to = inner.Position + Vector3.new(0, inner.Size.Y * 0.5 - 0.15, 0)
            expect((ramp.Position - (from + to) * 0.5).Magnitude < 0.1).toBe(true)
            expect((ramp.CFrame.LookVector - (to - from).Unit).Magnitude < 0.02).toBe(true)
            expect(math.abs(ramp.Size.Z - ((to - from).Magnitude + 4.4)) < 0.1).toBe(true)

            local old = originals[ramp]
            if (ramp.Position - old.cf.Position).Magnitude > 1 then
                advanced += 1
            end
            expect(ramp.CanCollide).toBe(true)
            local rail = helix:FindFirstChild("HelixEdgeSignal" .. index .. "_1")
            expect(rail ~= nil).toBe(true)
            expect(rail.CanCollide).toBe(false)
            expect((rail.CFrame.Position - originals[rail].cf.Position).Magnitude > 0.3).toBe(true)

            for _, kind in ipairs({"Entry", "Core"}) do
                local name = kind == "Core" and index == 2
                    and "HelixRamp9" or (kind .. "Ramp" .. index)
                local access = helix:FindFirstChild(name)
                expect(access ~= nil).toBe(true)
                local route = states[access]
                expect(route ~= nil).toBe(true)
                local function moved(point)
                    local relative = point - Config.ArenaCenter
                    return Config.ArenaCenter + Vector3.new(
                        relative.X * factor, relative.Y, relative.Z * factor
                    )
                end
                local expectedFrom, expectedTo =
                    moved(route.from), moved(route.to)
                expect((access.Position
                    - (expectedFrom + expectedTo) * 0.5).Magnitude < 0.1)
                    .toBe(true)
                expect(math.abs(access.Size.Z
                    - ((expectedTo - expectedFrom).Magnitude + route.padding))
                    < 0.1).toBe(true)
                expect(access.Size.X < originals[access].size.X).toBe(true)
                expect(access.CanCollide).toBe(true)
                local trimName = kind == "Core" and index == 2
                    and "HelixEdgeSignal9_1"
                    or (kind .. "Signal" .. index .. "_1")
                local trim = helix:FindFirstChild(trimName)
                expect(trim ~= nil).toBe(true)
                expect(trim.CanCollide).toBe(false)
                expect((trim.Position - originals[trim].cf.Position).Magnitude > 0.3)
                    .toBe(true)
            end
        end
        expect(advanced).toBe(8)
        local preservedCore = helix:FindFirstChild("HelixRamp9")
        expect(preservedCore:GetAttribute("OrbitalCoreRamp")).toBe(true)
        expect(preservedCore:GetAttribute("OrbitalHelixRamp") == nil).toBe(true)
        expect(states[preservedCore] ~= nil).toBe(true)

        active = false
        cleanup(callbacks, objects)
        for part, state in pairs(originals) do
            expect((part.CFrame.Position - state.cf.Position).Magnitude < 0.001).toBe(true)
            expect((part.Size - state.size).Magnitude < 0.001).toBe(true)
        end
        root:Destroy()
    end)
end)

return nil
