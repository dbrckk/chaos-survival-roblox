--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local LobbyActivities = require("../../src/server/LobbyActivities")

describe("Lobby activities", function()
    it("provides four symmetric practice boost pads", function()
        expect(#LobbyActivities.Definitions).toBe(4)

        local total = Vector3.zero
        for _, definition in ipairs(LobbyActivities.Definitions) do
            total += definition.offset
        end

        expect(total.Magnitude < 0.001).toBe(true)
    end)

    it("keeps practice boosts inside movement safety limits", function()
        local result = LobbyActivities.safeVelocity(
            Vector3.new(40, 10, 0),
            Vector3.new(31, 28, 0)
        )

        expect(Vector3.new(result.X, 0, result.Z).Magnitude <= 48.001).toBe(true)
        expect(result.Y <= 48.001).toBe(true)
        expect(result.Y >= -45.001).toBe(true)
    end)
end)

return nil
