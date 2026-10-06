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

    it("blocks a second claim until takeover is explicitly forced", function()
        local first = DataSession.claim({Coins = 10}, "session-a", 100)
        expect(first ~= nil).toBe(true)

        local blocked = DataSession.claim(first, "session-b", 101)
        expect(blocked == nil).toBe(true)

        local forced = DataSession.claim(first, "session-b", 102, true)
        expect(forced ~= nil).toBe(true)
        expect((forced :: any)[DataSession.TokenKey]).toBe("session-b")
    end)

    it("releases ownership only for the active session", function()
        local current = DataSession.claim({Coins = 10}, "session-a", 100)

        local staleRelease = DataSession.release(current, "session-b", 110)
        expect(staleRelease == nil).toBe(true)

        local released = DataSession.release(current, "session-a", 111)
        expect(released ~= nil).toBe(true)
        expect((released :: any)[DataSession.TokenKey]).toBe("")
        expect((released :: any)[DataSession.SavedAtKey]).toBe(111)
    end)

    it("rejects stale saves after another session takes ownership", function()
        local current = DataSession.claim({Coins = 10}, "session-new", 200)

        expect(DataSession.merge(current, {Coins = 999}, "session-old", 201) == nil).toBe(true)

        local merged = DataSession.merge(current, {Coins = 20}, "session-new", 202)
        expect(merged ~= nil).toBe(true)
        expect((merged :: any).Coins).toBe(20)
        expect((merged :: any)[DataSession.SavedAtKey]).toBe(202)
    end)

    it("survives rapid handoff without allowing stale overwrite or release", function()
        local initial = {
            Coins = 25,
            XP = 100,
        }

        local oldSession = DataSession.claim(initial, "session-old", 100)
        expect(oldSession ~= nil).toBe(true)

        local takeover = DataSession.claim(oldSession, "session-new", 108, true)
        expect(takeover ~= nil).toBe(true)
        expect((takeover :: any)[DataSession.TokenKey]).toBe("session-new")

        local staleSave = DataSession.merge(
            takeover,
            {Coins = 999, XP = 9999},
            "session-old",
            109
        )
        expect(staleSave == nil).toBe(true)

        local staleRelease = DataSession.release(takeover, "session-old", 110)
        expect(staleRelease == nil).toBe(true)

        local currentSave = DataSession.merge(
            takeover,
            {Coins = 40, XP = 160},
            "session-new",
            111
        )
        expect(currentSave ~= nil).toBe(true)
        expect((currentSave :: any).Coins).toBe(40)
        expect((currentSave :: any).XP).toBe(160)

        local released = DataSession.release(currentSave, "session-new", 112)
        expect(released ~= nil).toBe(true)
        expect((released :: any)[DataSession.TokenKey]).toBe("")

        local rejoined = DataSession.claim(released, "session-next", 113)
        expect(rejoined ~= nil).toBe(true)
        expect((rejoined :: any).Coins).toBe(40)
        expect((rejoined :: any).XP).toBe(160)
        expect((rejoined :: any)[DataSession.TokenKey]).toBe("session-next")
    end)

    it("refuses writes after a session has been released", function()
        local current = DataSession.claim({Coins = 10}, "session-a", 100)
        local released = DataSession.release(current, "session-a", 101)

        expect(released ~= nil).toBe(true)
        expect(DataSession.merge(released, {Coins = 20}, "session-a", 102) == nil).toBe(true)
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
