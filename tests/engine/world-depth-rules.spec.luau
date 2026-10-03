--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local WorldDepthRules = require("../../src/shared/WorldDepthRules")

describe("World depth rules", function()
    it("scales world decoration budgets with quality", function()
        local low = WorldDepthRules.budgets("Low")
        local medium = WorldDepthRules.budgets("Medium")
        local high = WorldDepthRules.budgets("High")

        expect(low.TransitRibs < medium.TransitRibs).toBe(true)
        expect(medium.TransitRibs < high.TransitRibs).toBe(true)
        expect(low.HorizonStructures < medium.HorizonStructures).toBe(true)
        expect(medium.HorizonStructures < high.HorizonStructures).toBe(true)
    end)

    it("keeps underworld structure budgets tiered", function()
        local low = WorldDepthRules.budgets("Low")
        local medium = WorldDepthRules.budgets("Medium")
        local high = WorldDepthRules.budgets("High")

        expect(low.UnderworldStruts < medium.UnderworldStruts).toBe(true)
        expect(medium.UnderworldStruts < high.UnderworldStruts).toBe(true)
        expect(low.HorizonAccents < high.HorizonAccents).toBe(true)
    end)

    it("keeps transition samples between lobby and arena", function()
        local lobby = Vector3.new(0, 0, -150)
        local arena = Vector3.new(0, 0, 0)

        local first, firstAlpha = WorldDepthRules.transitionSample(
            lobby,
            arena,
            1,
            6
        )
        local last, lastAlpha = WorldDepthRules.transitionSample(
            lobby,
            arena,
            6,
            6
        )

        expect(firstAlpha >= 0.24 and firstAlpha <= 0.66).toBe(true)
        expect(lastAlpha >= 0.24 and lastAlpha <= 0.66).toBe(true)
        expect(first.Z > lobby.Z and first.Z < arena.Z).toBe(true)
        expect(last.Z > first.Z and last.Z < arena.Z).toBe(true)
    end)

    it("centers the far horizon between lobby and arena", function()
        local lobby = Vector3.new(0, 0, -150)
        local arena = Vector3.new(0, 0, 0)
        local center = WorldDepthRules.worldCenter(lobby, arena)

        expect(center).toBe(Vector3.new(0, 0, -75))
    end)

    it("uses a farther horizon on higher quality", function()
        expect(WorldDepthRules.horizonRadius("Low")
            < WorldDepthRules.horizonRadius("Medium")).toBe(true)
        expect(WorldDepthRules.horizonRadius("Medium")
            < WorldDepthRules.horizonRadius("High")).toBe(true)
    end)

    it("produces varied but bounded skyline heights", function()
        local a = WorldDepthRules.horizonHeight(1)
        local b = WorldDepthRules.horizonHeight(2)
        expect(a >= 34 and a <= 85).toBe(true)
        expect(b >= 34 and b <= 85).toBe(true)
        expect(a ~= b).toBe(true)
    end)
end)

return nil
