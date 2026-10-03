--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterSetpiece = require("../../src/shared/DisasterSetpiece")

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

describe("Disaster setpiece profiles", function()
    it("covers all eleven disasters", function()
        for _, id in ipairs(IDS) do
            local profile = DisasterSetpiece.get(id)
            expect(profile ~= nil).toBe(true)
            expect(type(profile.Kind)).toBe("string")
            expect(typeof(profile.Color)).toBe("Color3")
            expect(typeof(profile.Secondary)).toBe("Color3")
        end
    end)

    it("preserves order for double chaos", function()
        local profiles = DisasterSetpiece.forIds({"Meteors", "Freeze"})
        expect(#profiles).toBe(2)
        expect(profiles[1].Kind).toBe("skyfall")
        expect(profiles[2].Kind).toBe("freeze")
    end)
end)

return nil
