--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local VisualTheme = require("../../src/shared/VisualTheme")
local ParkourFlow = require("../../src/server/ParkourFlow")

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
            state, pieces[1], platforms, base.Position, "Classic", 10.5
        )
        expect(state.chain).toBe(0)
        for step = 2, 8 do
            local nextState, valid = ParkourFlow.advance(
                state, pieces[step], platforms, base.Position,
                "Classic", 10 + (step - 1) * 1.1
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
            state, pieces[2], platforms, base.Position, "Classic", 20
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
        local rapid, validRapid = ParkourFlow.advance(
            state, second, platforms, base.Position, "Harbor", 5.01
        )
        expect(validRapid).toBe(false)
        expect(rapid.chain).toBe(0)
        state = ParkourFlow.advance(
            rapid, first, platforms, base.Position, "Harbor", 8
        )
        state = ParkourFlow.advance(
            state, second, platforms, base.Position, "Harbor", 20
        )
        expect(state.chain).toBe(0)

        state = ParkourFlow.advance(
            state, first, platforms, base.Position, "Harbor", 25
        )
        second.CanCollide = false
        expect(ParkourFlow.legalJump(
            first, second, platforms, base.Position, "Harbor"
        )).toBe(false)
        state = ParkourFlow.advance(
            state, second, platforms, base.Position, "Harbor", 26
        )
        expect(state.chain).toBe(0)
        second.CanCollide = true
        root:Destroy()
    end)
end)

return nil
