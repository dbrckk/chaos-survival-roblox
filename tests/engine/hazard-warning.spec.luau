--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local HazardWarning = require("../../src/server/HazardWarning")

describe("Hazard warning metadata", function()
    it("publishes bounded animation metadata on warning parts", function()
        local part = Instance.new("Part")
        HazardWarning.configure(part, "Meteor", 0.9, 5.5, 16)

        expect(part:GetAttribute("WarningKind")).toBe("Meteor")
        expect(part:GetAttribute("WarningDuration")).toBe(0.9)
        expect(part:GetAttribute("WarningStartSize")).toBe(5.5)
        expect(part:GetAttribute("WarningEndSize")).toBe(16)

        part:Destroy()
    end)

    it("sanitizes invalid durations and sizes", function()
        local part = Instance.new("Part")
        HazardWarning.configure(part, "Bomb", -2, -5, 0)

        expect((part:GetAttribute("WarningDuration") :: number) >= 0.05).toBe(true)
        expect((part:GetAttribute("WarningStartSize") :: number) >= 0.1).toBe(true)
        expect((part:GetAttribute("WarningEndSize") :: number) >= 0.1).toBe(true)

        part:Destroy()
    end)
end)

return nil
