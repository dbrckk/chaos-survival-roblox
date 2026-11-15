--!strict
-- Coverage reflects authenticated resident mesh masks on streamed owners.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Census = require("../../src/shared/DistrictVisualCensusRules")

describe("Live district 3D coverage", function()
    it("does not invent coverage when no buildings are streamed", function()
        local empty = Census.summarize(0, 65535, 65535)
        expect(empty.loaded).toBe(0)
        expect(empty.unstreamed).toBe(16)
        expect(empty.coveragePercent).toBe(nil)
        expect(empty.states).toBe("----------------")
    end)

    it("counts complete, partial and native-only streamed owners", function()
        -- Four streamed buildings: one complete, two partial, one native.
        local result = Census.summarize(15, 3, 5)
        expect(result.loaded).toBe(4)
        expect(result.complete).toBe(1)
        expect(result.facadeOnly).toBe(1)
        expect(result.sidewallOnly).toBe(1)
        expect(result.nativeOnly).toBe(1)
        expect(result.partial).toBe(2)
        expect(result.coveragePercent).toBe(25)
        expect(result.states:sub(1,4)).toBe("BFSN")
    end)

    it("ignores mesh masks for buildings not streamed", function()
        local result = Census.summarize(1, 65535, 65535)
        expect(result.complete).toBe(1)
        expect(result.coveragePercent).toBe(100)
        expect(result.unstreamed).toBe(15)
    end)
end)

return nil
