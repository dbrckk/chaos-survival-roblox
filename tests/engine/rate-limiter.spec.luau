--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RateLimiter = require("../../src/server/RateLimiter")

describe("Rate limiter", function()
    it("allows the first action", function()
        local allow = RateLimiter.new(0.2)
        expect(allow("player", 1.0)).toBe(true)
    end)

    it("blocks actions inside the interval", function()
        local allow = RateLimiter.new(0.2)
        expect(allow("player", 1.0)).toBe(true)
        expect(allow("player", 1.1)).toBe(false)
        expect(allow("player", 1.2)).toBe(true)
    end)

    it("tracks keys independently", function()
        local allow = RateLimiter.new(1)
        expect(allow("a", 10)).toBe(true)
        expect(allow("b", 10)).toBe(true)
        expect(allow("a", 10.5)).toBe(false)
        expect(allow("b", 11)).toBe(true)
    end)
end)

return nil
