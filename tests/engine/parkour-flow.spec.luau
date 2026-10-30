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

return nil
