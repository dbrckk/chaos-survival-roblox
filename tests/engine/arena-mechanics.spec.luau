--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaVariants = require("../../src/server/ArenaVariants")
local ArenaMechanics = require("../../src/server/ArenaMechanics")

describe("Arena mechanics", function()
    it("defines one mobility mechanic for every playable arena", function()
        local seenNames = {}

        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)
            expect(mechanic ~= nil).toBe(true)
            expect(type(mechanic.Name)).toBe("string")
            expect(type(mechanic.Hint)).toBe("string")
            expect(#mechanic.Name >= 4).toBe(true)
            expect(#mechanic.Hint >= 24).toBe(true)
            expect(#mechanic.Hint <= 96).toBe(true)
            expect(seenNames[mechanic.Name] == nil).toBe(true)
            seenNames[mechanic.Name] = true
        end
    end)

    it("provides multiple telegraphed mobility choices per arena", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)
            expect(#mechanic.Pads >= 4).toBe(true)

            for _, pad in ipairs(mechanic.Pads) do
                expect(typeof(pad.offset)).toBe("Vector3")
                expect(typeof(pad.impulse)).toBe("Vector3")
                expect(pad.impulse.Magnitude >= 20).toBe(true)
                expect(pad.impulse.Magnitude <= 60).toBe(true)
            end
        end
    end)

    it("keeps mobility impulses non-lethal and bounded", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)

            for _, pad in ipairs(mechanic.Pads) do
                expect(pad.impulse.Y >= 0).toBe(true)
                expect(math.abs(pad.impulse.X) <= 50).toBe(true)
                expect(math.abs(pad.impulse.Z) <= 50).toBe(true)
                expect(pad.impulse.Y <= 55).toBe(true)
            end
        end
    end)
end)

return nil
