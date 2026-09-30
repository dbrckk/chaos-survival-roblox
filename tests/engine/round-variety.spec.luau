--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundVariety = require("../../src/server/RoundVariety")

local function d(id)
    return {Id = id}
end

describe("Round variety", function()
    it("removes the immediately previous primary when enough choices remain", function()
        local pool = {d("A"), d("B"), d("C"), d("D"), d("E")}
        local filtered = RoundVariety.excludeImmediateRepeat(pool, "C", 3)

        expect(#filtered).toBe(4)
        for _, item in ipairs(filtered) do
            expect(item.Id ~= "C").toBe(true)
        end
    end)

    it("keeps the full pool when excluding would leave too few choices", function()
        local pool = {d("A"), d("B"), d("C")}
        local filtered = RoundVariety.excludeImmediateRepeat(pool, "C", 3)

        expect(#filtered).toBe(3)
    end)

    it("does not mutate the original pool", function()
        local pool = {d("A"), d("B"), d("C"), d("D")}
        local filtered = RoundVariety.excludeImmediateRepeat(pool, "A", 3)

        expect(#pool).toBe(4)
        expect(#filtered).toBe(3)
        expect(pool[1].Id).toBe("A")
    end)

    it("excludes multiple recent primaries when the pool is large enough", function()
        local pool = {d("A"), d("B"), d("C"), d("D"), d("E"), d("F")}
        local filtered = RoundVariety.excludeRecent(pool, {"B", "D"}, 3)

        expect(#filtered).toBe(4)
        for _, item in ipairs(filtered) do
            expect(item.Id ~= "B").toBe(true)
            expect(item.Id ~= "D").toBe(true)
        end
    end)

    it("relaxes the oldest exclusion when needed to preserve vote choice", function()
        local pool = {d("A"), d("B"), d("C"), d("D")}
        local filtered = RoundVariety.excludeRecent(pool, {"A", "B"}, 3)

        expect(#filtered).toBe(3)
        local ids = {}
        for _, item in ipairs(filtered) do ids[item.Id] = true end
        expect(ids.A).toBe(true)
        expect(ids.B == true).toBe(false)
    end)

    it("maintains a bounded unique recent history", function()
        local recent = RoundVariety.pushRecent({"A", "B"}, "C", 2)
        expect(#recent).toBe(2)
        expect(recent[1]).toBe("B")
        expect(recent[2]).toBe("C")

        recent = RoundVariety.pushRecent(recent, "B", 2)
        expect(#recent).toBe(2)
        expect(recent[1]).toBe("C")
        expect(recent[2]).toBe("B")
    end)
end)

return nil
