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
end)

return nil
