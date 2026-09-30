--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local GameAnalytics = require("../../src/server/GameAnalytics")

describe("Game analytics helpers", function()
    it("labels solo and multiplayer consistently", function()
        expect(GameAnalytics.modeLabel(true)).toBe("Solo")
        expect(GameAnalytics.modeLabel(false)).toBe("Multiplayer")
    end)

    it("creates at most three valid custom analytics fields", function()
        local values = GameAnalytics.fields("Mode:Solo", "Result:Survived", "Disaster:Meteors")
        local count = 0

        for key, value in pairs(values) do
            count += 1
            expect(type(key)).toBe("string")
            expect(type(value)).toBe("string")
        end

        expect(count).toBe(3)
        expect(values[Enum.AnalyticsCustomFieldKeys.CustomField01.Name]).toBe("Mode:Solo")
        expect(values[Enum.AnalyticsCustomFieldKeys.CustomField02.Name]).toBe("Result:Survived")
        expect(values[Enum.AnalyticsCustomFieldKeys.CustomField03.Name]).toBe("Disaster:Meteors")
    end)

    it("omits empty custom field slots", function()
        local values = GameAnalytics.fields("Mode:Multiplayer", nil, nil)
        local count = 0
        for _ in pairs(values) do
            count += 1
        end

        expect(count).toBe(1)
    end)
end)

return nil
