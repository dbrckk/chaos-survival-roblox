--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ChaosFusion = require("../../src/server/ChaosFusion")

describe("Chaos fusion", function()
    it("uses memorable names for special disaster pairs", function()
        expect(ChaosFusion.name("RisingLava", "Meteors")).toBe("APOCALYPSE RAIN")
        expect(ChaosFusion.name("Freeze", "Darkness")).toBe("VOIDFROST")
        expect(ChaosFusion.name("Tornado", "SpeedSurge")).toBe("HYPERSTORM")
    end)

    it("is order independent", function()
        expect(ChaosFusion.name("Meteors", "Tornado")).toBe(ChaosFusion.name("Tornado", "Meteors"))
    end)

    it("keeps the survival bonus modest", function()
        expect(ChaosFusion.bonusCoins()).toBe(5)
        expect(ChaosFusion.bonusCoins() <= 5).toBe(true)
    end)
end)

return nil
