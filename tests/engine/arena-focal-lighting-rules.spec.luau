--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaFocalLightingRules = require("../../src/shared/ArenaFocalLightingRules")

describe("Arena focal lighting rules", function()
    it("keeps focal lights disabled on low quality", function()
        expect(ArenaFocalLightingRules.sourceCount("Low")).toBe(0)
        expect(ArenaFocalLightingRules.sourceCount("Medium")).toBe(2)
        expect(ArenaFocalLightingRules.sourceCount("High")).toBe(3)
    end)

    it("uses restrained physical housings with no extra light sources", function()
        expect(ArenaFocalLightingRules.fixtureParts("Low")).toBe(0)
        expect(ArenaFocalLightingRules.fixtureParts("Medium")).toBe(1)
        expect(ArenaFocalLightingRules.fixtureParts("High")).toBe(2)
        local low = ArenaFocalLightingRules.fixtureParts("Low")
            * ArenaFocalLightingRules.sourceCount("Low")
        local high = ArenaFocalLightingRules.fixtureParts("High")
            * ArenaFocalLightingRules.sourceCount("High")
        expect(low).toBe(0)
        expect(high <= 6).toBe(true)
    end)

    it("defines three focal candidates for every arena", function()
        for _, id in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local definitions = ArenaFocalLightingRules.definitions(id)
            expect(#definitions >= 3).toBe(true)
            expect(definitions[1].Range > 0).toBe(true)
            expect(definitions[1].Angle > 0).toBe(true)
        end
    end)

    it("suppresses decorative lighting during high gameplay pressure", function()
        local ready = ArenaFocalLightingRules.phaseScale("ready", false)
        local round = ArenaFocalLightingRules.phaseScale("round", false)
        local rush = ArenaFocalLightingRules.phaseScale("round", true)

        expect(round < ready).toBe(true)
        expect(rush < round).toBe(true)
        expect(ArenaFocalLightingRules.phaseScale("waiting", false)).toBe(0)
    end)
end)

return nil
