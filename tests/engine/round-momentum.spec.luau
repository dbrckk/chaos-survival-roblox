--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundMomentum = require("../../src/server/RoundMomentum")

describe("Round momentum", function()
    it("chains skill actions inside the momentum window", function()
        expect(RoundMomentum.next(1, 10, 15)).toBe(2)
        expect(RoundMomentum.next(2, 15, 20.5)).toBe(3)
    end)

    it("resets after the momentum window expires", function()
        expect(RoundMomentum.next(4, 10, 16.01)).toBe(1)
        expect(RoundMomentum.next(4, nil, 20)).toBe(1)
    end)

    it("uses a short readable skill-chain window", function()
        expect(RoundMomentum.WindowSeconds).toBe(6)
    end)
end)

return nil
