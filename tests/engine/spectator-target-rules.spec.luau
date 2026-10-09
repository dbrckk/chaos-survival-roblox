--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Rules = require("../../src/shared/SpectatorTargetRules")

describe("Spectator target stability", function()
    local alpha = {}
    local beta = {}
    local gamma = {}

    it("gives the spectator camera exclusive ownership during active rounds", function()
        expect(Rules.isSpectating(true, true, false)).toBe(false)
        expect(Rules.isSpectating(true, true, true)).toBe(true)
        expect(Rules.isSpectating(true, false, false)).toBe(true)
        expect(Rules.isSpectating(true, nil, false)).toBe(true)
        expect(Rules.isSpectating(false, true, true)).toBe(false)
        expect(Rules.isSpectating(false, false, false)).toBe(false)
    end)

    it("keeps the same character when targets are reordered", function()
        expect(Rules.resolveIndex({
            {Character = alpha},
            {Character = beta},
        }, beta, 2, false)).toBe(2)

        expect(Rules.resolveIndex({
            {Character = gamma},
            {Character = alpha},
            {Character = beta},
        }, beta, 2, false)).toBe(3)
    end)

    it("cycles to the next target and wraps", function()
        local targets = {
            {Character = alpha},
            {Character = beta},
            {Character = gamma},
        }
        expect(Rules.resolveIndex(targets, beta, 2, true)).toBe(3)
        expect(Rules.resolveIndex(targets, gamma, 3, true)).toBe(1)
        expect(Rules.resolveIndex({{Character = beta}}, beta, 1, true)).toBe(1)
    end)

    it("does not skip the next survivor after elimination", function()
        local remaining = {
            {Character = alpha},
            {Character = gamma},
        }
        expect(Rules.resolveIndex(remaining, beta, 2, true)).toBe(2)
        expect(Rules.resolveIndex(remaining, beta, 2, false)).toBe(2)
    end)

    it("wraps when the final observed target disappears", function()
        local remaining = {
            {Character = alpha},
            {Character = beta},
        }
        expect(Rules.resolveIndex(remaining, gamma, 3, false)).toBe(1)
        expect(Rules.resolveIndex(remaining, gamma, 3, true)).toBe(1)
        expect(Rules.resolveIndex({{Character = alpha}}, beta, 2, false)).toBe(1)
    end)

    it("handles empty and outdated selections", function()
        expect(Rules.resolveIndex({}, beta, 2, true)).toBe(0)
        expect(Rules.resolveIndex({{Character = alpha}}, nil, 0, false)).toBe(1)
        expect(Rules.resolveIndex({{Character = alpha}}, beta, 100, true)).toBe(1)
    end)
end)

return nil
