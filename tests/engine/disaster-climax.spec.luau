--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterClimax = require("../../src/shared/DisasterClimax")

local IDS = {
    "RisingLava",
    "Meteors",
    "LowGravity",
    "DisappearingPlatforms",
    "Tornado",
    "Freeze",
    "Bombs",
    "SpeedSurge",
    "Darkness",
    "ShrinkingArena",
    "JumpShock",
}

describe("Disaster climax progression", function()
    it("covers every disaster with a unique climax profile", function()
        local kinds = {}
        for _, id in ipairs(IDS) do
            local profile = DisasterClimax.get(id)
            expect(profile ~= nil).toBe(true)
            expect(type(profile.Kind)).toBe("string")
            expect(typeof(profile.Color)).toBe("Color3")
            expect(typeof(profile.Secondary)).toBe("Color3")
            kinds[profile.Kind] = true
        end
        expect(#IDS).toBe(11)
        expect(next(kinds) ~= nil).toBe(true)
    end)

    it("progresses through surge and critical stages from intensity", function()
        expect(DisasterClimax.stageFor(0.90, false, false)).toBe(0)
        expect(DisasterClimax.stageFor(0.98, false, false)).toBe(1)
        expect(DisasterClimax.stageFor(1.06, false, false)).toBe(2)
    end)

    it("promotes overdrive to the critical visual stage", function()
        expect(DisasterClimax.stageFor(0.90, false, true)).toBe(2)
        expect(DisasterClimax.stageFor(1.02, false, true)).toBe(2)
    end)

    it("always gives final rush the highest climax stage", function()
        expect(DisasterClimax.stageFor(0.88, true, false)).toBe(3)
        expect(DisasterClimax.stageFor(1.12, true, true)).toBe(3)
    end)
end)

return nil
