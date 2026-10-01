--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AchievementService = require("../../src/server/AchievementService")

describe("Server service contracts", function()
    it("exports round-result achievement evaluation", function()
        expect(type(AchievementService.evaluate)).toBe("function")
        expect(type(AchievementService.sync)).toBe("function")
        expect(type(AchievementService.init)).toBe("function")
    end)
end)

return nil
