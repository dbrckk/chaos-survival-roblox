--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local MonetizationRules = require("../../src/server/MonetizationRules")

describe("Monetization visibility rules", function()
    it("shows paid offers only when saves are available", function()
        expect(MonetizationRules.offersEnabled(true, 2)).toBe(true)
        expect(MonetizationRules.offersEnabled(false, 2)).toBe(false)
        expect(MonetizationRules.offersEnabled(true, 0)).toBe(false)
    end)
end)

return nil
