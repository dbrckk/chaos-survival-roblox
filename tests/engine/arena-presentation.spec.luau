--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaPresentation = require("../../src/shared/ArenaPresentation")

local CENTER = Vector3.new(0, 0, 0)

local function planarUnit(vector)
    local flat = Vector3.new(vector.X, 0, vector.Z)
    return flat.Magnitude > 0.001 and flat.Unit or Vector3.zero
end

describe("Arena presentation", function()
    it("faces Classic spawns toward the arena center", function()
        local spawn = Vector3.new(30, 3, -30)
        local cf = ArenaPresentation.spawnCFrame("Classic", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)
        expect(cf.LookVector:Dot(inward) > 0.98).toBe(true)
    end)

    it("frames Towers inward while targeting elevated structure", function()
        local spawn = Vector3.new(-32, 3, -32)
        local target = ArenaPresentation.lookTarget("Towers", spawn, CENTER)
        local cf = ArenaPresentation.spawnCFrame("Towers", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)

        expect(target.Y > CENTER.Y + 8).toBe(true)
        expect(cf.LookVector:Dot(inward) > 0.90).toBe(true)
    end)

    it("aligns Crossroads spawns with a cardinal lane", function()
        local spawn = Vector3.new(36, 3, 18)
        local cf = ArenaPresentation.spawnCFrame("Crossroads", spawn, CENTER)
        expect(math.abs(cf.LookVector.X) > 0.98).toBe(true)
        expect(math.abs(cf.LookVector.Z) < 0.05).toBe(true)
    end)

    it("frames Orbital spawns along the ring instead of straight inward", function()
        local spawn = Vector3.new(35, 3, 0)
        local cf = ArenaPresentation.spawnCFrame("Orbital", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)
        local tangent = Vector3.new(0, 0, 1)

        expect(cf.LookVector:Dot(tangent) > 0.80).toBe(true)
        expect(cf.LookVector:Dot(inward) > 0.15).toBe(true)
    end)

    it("always returns a planar stable spawn orientation", function()
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local cf = ArenaPresentation.spawnCFrame(
                variant,
                Vector3.new(-30, 3, 30),
                CENTER
            )
            expect(math.abs(cf.LookVector.Y) < 0.001).toBe(true)
            expect(cf.LookVector.Magnitude > 0.99).toBe(true)
        end
    end)
end)

return nil
