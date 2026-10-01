--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DataSession = require("../../src/server/DataSession")

describe("Data session ownership", function()
    it("claims a session without dropping existing or unknown fields", function()
        local claimed = DataSession.claim({
            Coins = 125,
            FutureField = "keep-me",
        }, "session-a", 100)

        expect(claimed.Coins).toBe(125)
        expect(claimed.FutureField).toBe("keep-me")
        expect(claimed[DataSession.TokenKey]).toBe("session-a")
        expect(claimed[DataSession.ClaimedAtKey]).toBe(100)
    end)

    it("rejects stale saves after another session takes ownership", function()
        local current = DataSession.claim({Coins = 10}, "session-new", 200)

        expect(DataSession.merge(current, {Coins = 999}, "session-old", 201) == nil).toBe(true)

        local merged = DataSession.merge(current, {Coins = 20}, "session-new", 202)
        expect(merged ~= nil).toBe(true)
        expect((merged :: any).Coins).toBe(20)
        expect((merged :: any)[DataSession.SavedAtKey]).toBe(202)
    end)

    it("preserves unknown fields while saving the current schema snapshot", function()
        local current = DataSession.claim({
            Coins = 10,
            FutureField = "preserve",
        }, "session-a", 100)

        local merged = DataSession.merge(current, {
            Coins = 35,
            XP = 500,
        }, "session-a", 110)

        expect(merged ~= nil).toBe(true)
        expect((merged :: any).Coins).toBe(35)
        expect((merged :: any).XP).toBe(500)
        expect((merged :: any).FutureField).toBe("preserve")
    end)
end)

return nil
