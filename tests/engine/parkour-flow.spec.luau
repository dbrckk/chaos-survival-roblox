--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local VisualTheme = require("../../src/shared/VisualTheme")
local ParkourFlow = require("../../src/server/ParkourFlow")
local JumpRouteCueRules = require("../../src/shared/JumpRouteCueRules")

local function standingPosition(deck)
    return deck.CFrame:PointToWorldSpace(
        Vector3.new(0, deck.Size.Y * 0.5 + 3, 0)
    )
end

describe("Premium parkour flow over actual server-authored platforms", function()
    it("requires legitimate sequential jump landings and never double counts", function()
        local root = MapBuilder.build(
            Config, "Classic", ArenaVariants, VisualTheme
        )
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local base = arena:FindFirstChild("Base")
        local pieces = {}
        for _, p in ipairs(platforms:GetChildren()) do
            if p:GetAttribute("PerimeterRoute") == 1 then
                local n = p:GetAttribute("PerimeterStep")
                if type(n) == "number" then pieces[n] = p end
            end
        end
        for step = 1, 8 do
            expect(pieces[step] ~= nil).toBe(true)
        end

        local state = {chain = 0, best = 0}
        state = ParkourFlow.advance(
            state, pieces[1], platforms, base.Position, "Classic", 10
        )
        expect(state.chain).toBe(0)
        state = ParkourFlow.advance(
            state, pieces[1], platforms, base.Position,
            "Classic", 10.05, standingPosition(pieces[1])
        )
        expect(state.chain).toBe(0)
        for step = 2, 8 do
            local source = pieces[step - 1]
            local departAt = 10 + (step - 2) * 1.1 + 0.46
            local jumped
            state, jumped = ParkourFlow.takeoff(
                state, platforms, standingPosition(source), departAt
            )
            expect(jumped).toBe(true)
            local nextState, valid = ParkourFlow.advance(
                state, pieces[step], platforms, base.Position,
                "Classic", 10 + (step - 1) * 1.1,
                standingPosition(pieces[step])
            )
            expect(valid).toBe(true)
            state = nextState
            expect(state.chain).toBe(step - 1)
            expect(state.best).toBe(step - 1)
        end
        expect(ParkourFlow.bonusXP(state.best)).toBe(7)
        expect(ParkourFlow.bonusXP(2)).toBe(0)
        expect(ParkourFlow.bonusXP(3)).toBe(4)
        expect(ParkourFlow.bonusXP(6)).toBe(7)
        expect(ParkourFlow.bonusXP(100)).toBe(7)

        -- Backtracking is not a new jump in the authored ascent order,
        -- yet the best run remains an earned result for this round.
        state = ParkourFlow.advance(
            state, pieces[2], platforms, base.Position,
            "Classic", 20, standingPosition(pieces[2])
        )
        expect(state.chain).toBe(0)
        expect(state.best).toBe(7)
        state = ParkourFlow.advance(
            state, nil, platforms, base.Position, "Classic", 21
        )
        expect(state.chain).toBe(0)
        expect(state.best).toBe(7)
        root:Destroy()
    end)

    it("rejects impossible timelines and noncollision ghost platforms", function()
        local root = MapBuilder.build(
            Config, "Harbor", ArenaVariants, VisualTheme
        )
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local base = arena:FindFirstChild("Base")
        local first, second
        for _, deck in ipairs(platforms:GetChildren()) do
            if deck:GetAttribute("HarborRoute") == 1 then
                if deck:GetAttribute("HarborStep") == 1 then first = deck end
                if deck:GetAttribute("HarborStep") == 2 then second = deck end
            end
        end
        expect(first ~= nil and second ~= nil).toBe(true)
        local state = ParkourFlow.advance(
            nil, first, platforms, base.Position, "Harbor", 5
        )
        -- Crossing two Parts without a server-observed JUMP never pays.
        local rapid, validRapid = ParkourFlow.advance(
            state, second, platforms, base.Position,
            "Harbor", 5.01, standingPosition(second)
        )
        expect(validRapid).toBe(false)
        expect(rapid.chain).toBe(0)
        state = ParkourFlow.advance(
            rapid, first, platforms, base.Position,
            "Harbor", 8, standingPosition(first)
        )
        state = ParkourFlow.takeoff(
            state, platforms, standingPosition(first), 10
        )
        state = ParkourFlow.advance(
            state, second, platforms, base.Position,
            "Harbor", 20, standingPosition(second)
        )
        expect(state.chain).toBe(0)

        state = ParkourFlow.advance(
            state, first, platforms, base.Position,
            "Harbor", 25, standingPosition(first)
        )
        state = ParkourFlow.takeoff(
            state, platforms, standingPosition(first), 25.4
        )
        second.CanCollide = false
        expect(ParkourFlow.legalJump(
            first, second, platforms, base.Position, "Harbor"
        )).toBe(false)
        state = ParkourFlow.advance(
            state, second, platforms, base.Position,
            "Harbor", 26, standingPosition(second)
        )
        expect(state.chain).toBe(0)
        second.CanCollide = true
        root:Destroy()
    end)
end)

describe("Authentic airborne parkour score protection", function()
    it("rejects seam-walking, off-deck takeoffs and repeated events", function()
        local root = MapBuilder.build(
            Config, "Classic", ArenaVariants, VisualTheme
        )
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local base = arena:FindFirstChild("Base")
        local first, second
        for _, deck in ipairs(platforms:GetChildren()) do
            if deck:GetAttribute("PerimeterRoute") == 1 then
                if deck:GetAttribute("PerimeterStep") == 1 then first = deck end
                if deck:GetAttribute("PerimeterStep") == 2 then second = deck end
            end
        end
        expect(first ~= nil and second ~= nil).toBe(true)

        local state = ParkourFlow.advance(
            nil, first, platforms, base.Position,
            "Classic", 5, standingPosition(first)
        )
        -- Walking over a seam could previously trigger a false chain.
        local justWalked, walked = ParkourFlow.advance(
            state, second, platforms, base.Position,
            "Classic", 6, standingPosition(second)
        )
        expect(walked).toBe(false)
        expect(justWalked.chain).toBe(0)

        state = ParkourFlow.advance(
            justWalked, first, platforms, base.Position,
            "Classic", 7, standingPosition(first)
        )
        local blocked, valid = ParkourFlow.takeoff(
            state, platforms, standingPosition(first)
                + Vector3.new(35, 0, 0), 7.4
        )
        expect(valid).toBe(false)
        expect(blocked.jumpFrom == nil).toBe(true)

        state, valid = ParkourFlow.takeoff(
            blocked, platforms, standingPosition(first), 7.5
        )
        expect(valid).toBe(true)
        local duplicate, duplicateValid = ParkourFlow.takeoff(
            state, platforms, standingPosition(first), 7.7
        )
        expect(duplicateValid).toBe(false)
        expect(duplicate.jumpAt).toBe(7.5)
        state, valid = ParkourFlow.advance(
            duplicate, second, platforms, base.Position,
            "Classic", 8.15, standingPosition(second)
        )
        expect(valid).toBe(true)
        expect(state.chain).toBe(1)

        -- This live first-stage contact must NOT award a second point.
        local same, sameValid = ParkourFlow.advance(
            state, second, platforms, base.Position,
            "Classic", 8.2, standingPosition(second)
        )
        expect(sameValid).toBe(false)
        expect(same.chain).toBe(1)
        expect(same.jumpFrom == nil).toBe(true)
        root:Destroy()
    end)

    it("does not erase real long Moon Gravity jumps but rejects stale flights", function()
        local root = MapBuilder.build(
            Config, "Classic", ArenaVariants, VisualTheme
        )
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local base = arena:FindFirstChild("Base")
        local first, second
        for _, deck in ipairs(platforms:GetChildren()) do
            if deck:GetAttribute("PerimeterRoute") == 3 then
                if deck:GetAttribute("PerimeterStep") == 1 then first = deck end
                if deck:GetAttribute("PerimeterStep") == 2 then second = deck end
            end
        end
        local state = ParkourFlow.advance(
            nil, first, platforms, base.Position,
            "Classic", 10, standingPosition(first)
        )
        state = ParkourFlow.takeoff(
            state, platforms, standingPosition(first), 10.4
        )
        local landing, valid = ParkourFlow.advance(
            state, second, platforms, base.Position,
            "Classic", 14.7, standingPosition(second)
        )
        expect(valid).toBe(true)
        expect(landing.best).toBe(1)

        -- Even in a low-gravity mode, an old airborne flag is not a
        -- valid receipt for a different round or a much later teleport.
        landing = ParkourFlow.advance(
            landing, first, platforms, base.Position,
            "Classic", 16, standingPosition(first)
        )
        landing = ParkourFlow.takeoff(
            landing, platforms, standingPosition(first), 16.5
        )
        local stale, credited = ParkourFlow.advance(
            landing, second, platforms, base.Position,
            "Classic", 22.1, standingPosition(second)
        )
        expect(credited).toBe(false)
        expect(stale.best).toBe(1)
        root:Destroy()
    end)

    it("rejects non-airborne teleport, low-flight and impossible speed", function()
        local root = MapBuilder.build(
            Config, "Classic", ArenaVariants, VisualTheme
        )
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local base = arena:FindFirstChild("Base")
        local first, second
        for _, deck in ipairs(platforms:GetChildren()) do
            if deck:GetAttribute("PerimeterRoute") == 2 then
                if deck:GetAttribute("PerimeterStep") == 1 then first = deck end
                if deck:GetAttribute("PerimeterStep") == 2 then second = deck end
            end
        end

        local state = ParkourFlow.advance(
            nil, first, platforms, base.Position,
            "Classic", 10, standingPosition(first)
        )
        state = ParkourFlow.takeoff(
            state, platforms, standingPosition(first), 10.4
        )
        local impossible, accepted = ParkourFlow.advance(
            state, second, platforms, base.Position,
            "Classic", 10.41, standingPosition(second)
        )
        expect(accepted).toBe(false)
        expect(impossible.chain).toBe(0)
        -- Requiring a new observed JUMP prevents cashing in a stale launch.
        state = ParkourFlow.advance(
            impossible, first, platforms, base.Position,
            "Classic", 11, standingPosition(first)
        )
        state = ParkourFlow.takeoff(
            state, platforms, standingPosition(first), 11.4
        )
        local farPosition = standingPosition(second) + Vector3.new(250, 0, 0)
        local invalid, credited = ParkourFlow.advance(
            state, second, platforms, base.Position,
            "Classic", 11.9, farPosition
        )
        expect(credited).toBe(false)
        expect(invalid.best).toBe(0)
        root:Destroy()
    end)
end)


describe("Real active arena sweep lanes never lure jump coaching into danger", function()
    it("rejects oriented floor lanes but allows high decks and idle waves", function()
        local band = Instance.new("Part")
        band.Name = "HarborSweepLane1"
        band.Size = Vector3.new(7.5, 0.10, 68)
        band.CFrame = CFrame.new(26, 4, -35)
            * CFrame.Angles(0, math.rad(35), 0)
        band.Anchored = true
        band.CanCollide = false
        band.Parent = workspace
        band:SetAttribute("HarborSweepPhase", "Warning")
        local from = band.CFrame:PointToWorldSpace(Vector3.new(-20, 3, 0))
        local to = band.CFrame:PointToWorldSpace(Vector3.new(20, 3, 0))
        expect(JumpRouteCueRules.activeSweepOnPath(from, to, band)).toBe(true)
        expect(JumpRouteCueRules.safeGuidedPath(from, to, {band})).toBe(false)
        expect(JumpRouteCueRules.safeGuidedPath(
            band.CFrame:PointToWorldSpace(Vector3.new(-20, 15, 0)),
            band.CFrame:PointToWorldSpace(Vector3.new(20, 15, 0)),
            {band}
        )).toBe(true)
        expect(JumpRouteCueRules.safeGuidedPath(
            band.CFrame:PointToWorldSpace(Vector3.new(-20, 3, 48)),
            band.CFrame:PointToWorldSpace(Vector3.new(20, 3, 48)),
            {band}
        )).toBe(true)

        band:SetAttribute("HarborSweepPhase", "Pulse")
        expect(JumpRouteCueRules.safeGuidedPath(from, to, {band})).toBe(false)
        band:SetAttribute("HarborSweepPhase", "Idle")
        expect(JumpRouteCueRules.safeGuidedPath(from, to, {band})).toBe(true)
        band.Name = "GridSweepBand2"
        band:SetAttribute("GridSweepPhase", "Warning")
        expect(JumpRouteCueRules.safeGuidedPath(from, to, {band})).toBe(false)
        band:SetAttribute("GridSweepPhase", "Pulse")
        expect(JumpRouteCueRules.safeGuidedPath(from, to, {band})).toBe(false)
        band:Destroy()
        expect(JumpRouteCueRules.safeGuidedPath(from, to, {band})).toBe(true)
    end)
end)


-- Roblox BasePart.Size serializes through float32: numeric decimal deck
-- footprints such as 11.6 and 11.2 cannot be compared byte-exactly to
-- Lua number literals. Test physical dimensions within 0.001 studs;
-- keep actual reachability and legalJump checks fully strict.
describe("Physically progressive landing footprints on all five arenas", function()
    it("uses deterministic bounded 4-grade course difficulty", function()
        local shapes = {
            Harbor = {12, 12, 11.6, 11.1, 10.6, 10.1, 9.6},
            Perimeter = {12, 12, 12, 11.6, 11.2, 10.8, 10.4, 10},
            Branch = {12, 12, 11.2, 10.4},
        }
        for kind, widths in pairs(shapes) do
            local previous = math.huge
            for step, width in ipairs(widths) do
                local actual, grade = ArenaVariants.parkourFootprint(kind, step)
                expect(actual).toBe(width)
                expect(actual <= previous).toBe(true)
                expect(actual >= 9.6).toBe(true)
                expect(grade >= 1 and grade <= 4).toBe(true)
                previous = actual
            end
            expect(ArenaVariants.parkourFootprint(kind, 0)).toBe(nil)
            expect(ArenaVariants.parkourFootprint(kind, #widths + 1)).toBe(nil)
        end
        expect(ArenaVariants.parkourFootprint("UntrustedRoute", 2)).toBe(nil)
        expect(ArenaVariants.parkourFootprint("Harbor", 2.5)).toBe(nil)
    end)

    it("keeps all five real perimeter ascents reachable as stages tighten", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local root = MapBuilder.build(Config, id, ArenaVariants, VisualTheme)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local originals = #variant.Platforms
            for route = 1, 4 do
                local previous = nil
                for step = 1, ArenaVariants.PerimeterSteps do
                    local index = originals
                        + (route - 1) * ArenaVariants.PerimeterSteps + step
                    local deck = platforms:FindFirstChild("Platform" .. index)
                    local expectedWidth, expectedGrade =
                        ArenaVariants.parkourFootprint("Perimeter", step)
                    expect(math.abs(deck.Size.X - expectedWidth) < 0.001).toBe(true)
                    expect(math.abs(deck.Size.Z - expectedWidth) < 0.001).toBe(true)
                    expect(deck:GetAttribute("ParkourGrade")).toBe(expectedGrade)
                    expect(deck.Anchored and deck.CanCollide).toBe(true)
                    if previous then
                        local gap = JumpRouteCueRules.gap(previous, deck)
                        expect(gap > 0.15 and gap < 3.85).toBe(true)
                        expect(JumpRouteCueRules.jumpable(previous, deck)).toBe(true)
                        expect(ParkourFlow.legalJump(
                            previous, deck, platforms,
                            Config.ArenaCenter, id
                        )).toBe(true)
                    end
                    previous = deck
                end
            end
            root:Destroy()
        end
    end)

    it("preserves all elevated branches, safe rescue crosslinks and harbor switchbacks", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local root = MapBuilder.build(Config, id, ArenaVariants, VisualTheme)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local original = #variant.Platforms
            local branchStart = original + #variant.PerimeterPlatforms
            local crossStart = branchStart + #variant.BranchPlatforms
            for route = 1, 4 do
                local sideLast = nil
                for step = 1, 4 do
                    local deck = platforms:FindFirstChild(
                        "Platform" .. (branchStart + (route - 1) * 4 + step)
                    )
                    local expectedWidth, grade =
                        ArenaVariants.parkourFootprint("Branch", step)
                    expect(math.abs(deck.Size.X - expectedWidth) < 0.001).toBe(true)
                    expect(math.abs(deck.Size.Z - expectedWidth) < 0.001).toBe(true)
                    expect(deck:GetAttribute("ParkourGrade")).toBe(grade)
                    if sideLast then
                        expect(JumpRouteCueRules.jumpable(sideLast, deck)).toBe(true)
                        expect(ParkourFlow.legalJump(
                            sideLast, deck, platforms, Config.ArenaCenter, id
                        )).toBe(true)
                    end
                    sideLast = deck
                end
                local ridge6 = platforms:FindFirstChild("Platform" ..
                    (original + (route - 1) * 8 + 6))
                local link = platforms:FindFirstChild("Platform" .. (crossStart + route))
                local branch2 = platforms:FindFirstChild("Platform" ..
                    (branchStart + (route - 1) * 4 + 2))
                expect(link.Size.X).toBe(12)
                expect(link.Size.Z).toBe(12)
                expect(link:GetAttribute("ParkourGrade")).toBe(3)
                expect(JumpRouteCueRules.jumpable(ridge6, link)).toBe(true)
                expect(JumpRouteCueRules.jumpable(link, branch2)).toBe(true)
            end
            if id == "Harbor" then
                for route = 1, 4 do
                    local previous = nil
                    for step = 1, 7 do
                        local deck = platforms:FindFirstChild(
                            "Platform" .. ((route - 1) * 7 + step)
                        )
                        local width, grade =
                            ArenaVariants.parkourFootprint("Harbor", step)
                        expect(math.abs(deck.Size.X - width) < 0.001).toBe(true)
                        expect(math.abs(deck.Size.Z - width) < 0.001).toBe(true)
                        expect(deck:GetAttribute("ParkourGrade")).toBe(grade)
                        if previous then
                            expect(JumpRouteCueRules.gap(previous, deck)
                                <= JumpRouteCueRules.MaxGap).toBe(true)
                            expect(JumpRouteCueRules.jumpable(previous, deck))
                                .toBe(true)
                            expect(ParkourFlow.legalJump(
                                previous, deck, platforms,
                                Config.ArenaCenter, id
                            )).toBe(true)
                        end
                        previous = deck
                    end
                end
            end
            root:Destroy()
        end
    end)
end)



describe("Veteran parkour retry coaching after unsuccessful physical jumps", function()
    it("tracks actual horizontal progress and ignores vertical jump arcs", function()
        local distance = JumpRouteCueRules.horizontalProgressDistance
        local anchor = Vector3.new(23, 4, -45)
        -- A 6-stud hop straight up is an attempt, not progress along
        -- the platform course. Retain the optional 5.2-second help timer.
        expect(distance(anchor, anchor + Vector3.new(0, 6, 0))).toBe(0)
        expect(distance(anchor, anchor + Vector3.new(3, 0, 4))).toBe(5)
        expect(distance(anchor,
            anchor + Vector3.new(3, 100, 0))).toBe(3)
        expect(distance(nil, anchor)).toBe(math.huge)
        expect(distance(anchor, nil)).toBe(math.huge)
        expect(JumpRouteCueRules.recoveryHintReady(
            5.2, distance(anchor, anchor + Vector3.new(0, 6, 0)), true
        )).toBe(true)
        expect(JumpRouteCueRules.recoveryHintReady(
            5.2, distance(anchor, anchor + Vector3.new(4, 0, 0)), true
        )).toBe(false)
    end)
end)

-- The exact physical Harbor 14-deck skyways are part of parkour gameplay,
-- not map scenery. Keep their engine assertions here instead of inflating
-- mapbuilder.spec.luau beyond Lest Open Cloud's 105 KB single-spec cap.
describe("Actual bidirectional Harbor cross-quay parkour", function()
    it("crosses both real upper gantries, rejects collapsing landings", function()
        local variantId = "Harbor"
        local variant = ArenaVariants.get(variantId)
        local root = MapBuilder.build(Config, variantId, ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local pieces = platforms:GetChildren()
        local originals = #variant.Platforms
            -- Exercise the REAL Harbor physics geometry via both physical
            -- terminal-to-terminal upper paths, never synthetic dummy Parts.
                expect(#variant.SkywayPlatforms).toBe(14)
                local startIndex = originals + #variant.PerimeterPlatforms
                    + #variant.BranchPlatforms + #variant.CrosslinkPlatforms
                for lane = 1, 2 do
                    local westRoute = lane == 1 and 1 or 3
                    local eastRoute = westRoute + 1
                    local west = platforms:FindFirstChild(
                        "Platform" .. ((westRoute - 1) * 7 + 7)
                    )
                    local east = platforms:FindFirstChild(
                        "Platform" .. ((eastRoute - 1) * 7 + 7)
                    )
                    expect(west ~= nil and east ~= nil).toBe(true)
                    local previous = west
                    for step = 1, 7 do
                        local deck = platforms:FindFirstChild(
                            "Platform" .. (startIndex + (lane - 1) * 7 + step)
                        )
                        expect(deck ~= nil).toBe(true)
                        expect(deck.Anchored and deck.CanCollide).toBe(true)
                        expect(deck.Material).toBe(Enum.Material.CorrodedMetal)
                        expect(deck:GetAttribute("HarborSkywayLane")).toBe(lane)
                        expect(deck:GetAttribute("HarborSkywayStep")).toBe(step)
                        expect(JumpRouteCueRules.skywayLeap(previous, deck))
                            .toBe(true)
                        expect(JumpRouteCueRules.nextPhysical(
                            previous, pieces, Config.ArenaCenter, variantId, 1
                        )).toBe(deck)
                        previous = deck
                    end
                    expect(JumpRouteCueRules.skywayLeap(previous, east))
                        .toBe(true)
                    expect(JumpRouteCueRules.nextPhysical(
                        previous, pieces, Config.ArenaCenter, variantId, 1
                    )).toBe(east)

                    previous = east
                    for step = 7, 1, -1 do
                        local deck = platforms:FindFirstChild(
                            "Platform" .. (startIndex + (lane - 1) * 7 + step)
                        )
                        expect(JumpRouteCueRules.skywayLeap(previous, deck))
                            .toBe(true)
                        expect(JumpRouteCueRules.nextPhysical(
                            previous, pieces, Config.ArenaCenter, variantId, -1
                        )).toBe(deck)
                        previous = deck
                    end
                    expect(JumpRouteCueRules.nextPhysical(
                        previous, pieces, Config.ArenaCenter, variantId, -1
                    )).toBe(west)

                    -- An impending collapse must invalidate this ACTUAL
                    -- landing, not leave a fictitious safe next-jump sign.
                    local first = platforms:FindFirstChild(
                        "Platform" .. (startIndex + (lane - 1) * 7 + 1)
                    )
                    first:SetAttribute("CollapsePhase", "Warning")
                    expect(JumpRouteCueRules.nextPhysical(
                        west, pieces, Config.ArenaCenter, variantId, 1
                    )).toBe(nil)
                    first:SetAttribute("CollapsePhase", nil)
                end

        root:Destroy()
    end)
end)

-- Every rewarded leap requires a real server Humanoid takeoff and a
-- physical landing; the horizontal skyways must not silently reset the
-- combo, unlike arbitrary flat movements between unrelated platforms.
describe("Server-owned Harbor elevated parkour scoring", function()
    it("keeps both bidirectional cargo-to-skyway skill chains", function()
        local id = "Harbor"
        local variant = ArenaVariants.get(id)
        local root = MapBuilder.build(Config, id, ArenaVariants)
        local platforms = root:FindFirstChild("Arena"):FindFirstChild("Platforms")
        local startIndex = #variant.Platforms
            + #variant.PerimeterPlatforms
            + #variant.BranchPlatforms
            + #variant.CrosslinkPlatforms

        for lane = 1, 2 do
            local westRoute = lane == 1 and 1 or 3
            local west = platforms:FindFirstChild(
                "Platform" .. ((westRoute - 1) * 7 + 7)
            )
            local east = platforms:FindFirstChild(
                "Platform" .. (westRoute * 7 + 7)
            )
            local decks = {}
            for step = 1, 7 do
                decks[step] = platforms:FindFirstChild(
                    "Platform" .. (startIndex + (lane - 1) * 7 + step)
                )
            end

            local now = 10
            local memory = ParkourFlow.advance(
                nil, west, platforms, Config.ArenaCenter,
                id, now, standingPosition(west)
            )
            local function leap(to)
                local from = memory.deck
                expect(ParkourFlow.legalJump(
                    from, to, platforms, Config.ArenaCenter, id
                )).toBe(true)
                local tookOff
                memory, tookOff = ParkourFlow.takeoff(
                    memory, platforms, standingPosition(from), now + 0.35
                )
                expect(tookOff).toBe(true)
                local earned
                memory, earned = ParkourFlow.advance(
                    memory, to, platforms, Config.ArenaCenter,
                    id, now + 0.90, standingPosition(to)
                )
                expect(earned).toBe(true)
                now += 0.90
            end

            for step = 1, 7 do
                leap(decks[step])
                expect(memory.chain).toBe(step)
            end
            leap(east)
            expect(memory.best).toBe(7)
            expect(ParkourFlow.bonusXP(memory.best)).toBe(7)

            for step = 7, 1, -1 do
                leap(decks[step])
                expect(memory.chain).toBe(7)
            end
            leap(west)

            -- Cross-variant abuse and warned/noncolliding destinations
            -- must never convert into a server XP combo.
            expect(ParkourFlow.legalJump(
                west, decks[1], platforms, Config.ArenaCenter, "Classic"
            )).toBe(false)
            decks[1]:SetAttribute("CollapsePhase", "Warning")
            expect(ParkourFlow.legalJump(
                west, decks[1], platforms, Config.ArenaCenter, id
            )).toBe(false)
            decks[1]:SetAttribute("CollapsePhase", nil)
            decks[1].CanCollide = false
            expect(ParkourFlow.legalJump(
                west, decks[1], platforms, Config.ArenaCenter, id
            )).toBe(false)
            decks[1].CanCollide = true
        end

        root:Destroy()
    end)
end)

return nil
