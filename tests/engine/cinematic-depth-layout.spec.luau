--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Layout = require("../../src/shared/CinematicDepthLayoutRules")

describe("immutable cinematic skyline ring layouts", function()
    it("retains original 5/8/11, 0/10/14, 0/3/5 and 0/2/4 tier budgets", function()
        local counts = {
            Horizon = {5, 8, 11},
            OrbitalHalo = {0, 10, 14},
            Beacon = {0, 3, 5},
            Traffic = {0, 2, 4},
        }
        for group, budget in pairs(counts) do
            local low = Layout.indices(group, "Low")
            local medium = Layout.indices(group, "Medium")
            local high = Layout.indices(group, "High")
            expect(#low).toBe(budget[1])
            expect(#medium).toBe(budget[2])
            expect(#high).toBe(budget[3])
            local mediumSet, highAngles = {}, {}
            local previous = -1
            for _, index in ipairs(high) do
                expect(highAngles[index] == nil).toBe(true)
                local angle = Layout.angle(group, index)
                expect(angle ~= nil and angle > previous).toBe(true)
                highAngles[index] = angle
                previous = angle
            end
            for _, index in ipairs(medium) do
                expect(mediumSet[index] == nil).toBe(true)
                mediumSet[index] = true
                expect(Layout.angle(group, index)).toBe(highAngles[index])
            end
            for _, index in ipairs(low) do
                expect(mediumSet[index]).toBe(true)
                expect(Layout.angle(group, index)).toBe(highAngles[index])
            end
            expect(Layout.angle(group, budget[3] + 1)).toBe(nil)
        end
        expect(Layout.angle("Horizon", 1)).toBe(math.rad(11))
        expect(Layout.angle("Beacon", 1)).toBe(math.rad(22))
        expect(Layout.angle("Horizon", 0)).toBe(nil)
        expect(Layout.angle("Horizon", 0/0)).toBe(nil)
        expect(#Layout.indices("Unrelated", "High")).toBe(0)
        expect(Layout.angle("Unrelated", 1)).toBe(nil)
    end)
end)
return nil
