--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundCleanup = require("../../src/server/RoundCleanup")
local RoundSettlement = require("../../src/server/RoundSettlement")

describe("Round settlement resilience", function()
    it("freezes the real winner roster before any failing payout or achievement", function()
        local alice = {UserId = 101, connected = true, health = 42}
        local bob = {UserId = 202, connected = true, health = 0}
        local claire = {UserId = 303, connected = true, health = 16}
        local left = {UserId = 404, connected = false, health = 50}
        local participants, survivors, winning = RoundSettlement.snapshot(
            {alice, bob, claire, left, alice},
            {[202] = true},
            function(p) return p.connected end,
            function(p) return p.health > 0 end
        )
        expect(#participants).toBe(3)
        expect(participants[1]).toBe(101)
        expect(participants[2]).toBe(202)
        expect(participants[3]).toBe(303)
        expect(#survivors).toBe(2)
        expect(survivors[1]).toBe(101)
        expect(survivors[2]).toBe(303)
        expect(winning[101]).toBe(true)
        expect(winning[303]).toBe(true)
        expect(winning[202] == nil).toBe(true)
        expect(winning[404] == nil).toBe(true)

        local succeeded, failed = RoundSettlement.eachPlayer(
            {alice, bob, claire},
            function(player)
                if player == alice then
                    error("data grant threw before feedback")
                end
            end
        )
        expect(succeeded).toBe(2)
        expect(failed).toBe(1)
        -- Even a disconnected/failing reward transaction cannot rewrite
        -- the authoritative RESULT roster after the disaster is over.
        alice.connected = false
        claire.health = 0
        expect(#survivors).toBe(2)
        expect(winning[101]).toBe(true)
        expect(winning[303]).toBe(true)
    end)

    it("processes the remaining players when an earlier player fails", function()
        local seen = {}
        local errors = {}
        local completed, failed = RoundSettlement.eachPlayer(
            {"alice", "bob", "charlie"},
            function(player)
                table.insert(seen, player)
                if player == "bob" then error("simulated achievement failure") end
            end,
            function(player, message)
                table.insert(errors, {player = player, message = message})
            end
        )
        expect(completed).toBe(2)
        expect(failed).toBe(1)
        expect(#seen).toBe(3)
        expect(seen[3]).toBe("charlie")
        expect(#errors).toBe(1)
        expect(errors[1].player).toBe("bob")
        expect(string.find(errors[1].message, "simulated achievement failure") ~= nil)
            .toBe(true)
    end)

    it("contains errors from the error reporter without retrying payouts", function()
        local calls = 0
        local completed, failed = RoundSettlement.eachPlayer(
            {1, 2},
            function(player)
                calls += 1
                if player == 1 then error("partial reward") end
            end,
            function()
                error("broken logging sink")
            end
        )
        expect(calls).toBe(2)
        expect(completed).toBe(1)
        expect(failed).toBe(1)
        expect(select(1, RoundSettlement.eachPlayer({}, function()
            error("should not execute")
        end))).toBe(0)
    end)
end)

describe("Round cleanup", function()
    it("continues after callback failures and reports them", function()
        local ranAfterFailure = false
        local errors = {}

        local failures = RoundCleanup.runCallbacks({
            function()
                error("expected cleanup failure")
            end,
            function()
                ranAfterFailure = true
            end,
        }, function(kind, key, err)
            table.insert(errors, {
                kind = kind,
                key = key,
                err = tostring(err),
            })
        end)

        expect(failures).toBe(1)
        expect(ranAfterFailure).toBe(true)
        expect(#errors).toBe(1)
        expect(errors[1].kind).toBe("callback")
    end)

    it("unwinds cleanup callbacks in reverse registration order", function()
        local order = {}

        local failures = RoundCleanup.runCallbacks({
            function()
                table.insert(order, "first")
            end,
            function()
                table.insert(order, "second")
            end,
            function()
                table.insert(order, "third")
            end,
        })

        expect(failures).toBe(0)
        expect(order[1]).toBe("third")
        expect(order[2]).toBe("second")
        expect(order[3]).toBe("first")
    end)

    it("destroys remaining cleanup objects", function()
        local a = Instance.new("Folder")
        local b = Instance.new("Folder")
        a.Parent = workspace
        b.Parent = workspace

        local failures = RoundCleanup.destroyAll({a, b})
        expect(failures).toBe(0)
        expect(a.Parent == nil).toBe(true)
        expect(b.Parent == nil).toBe(true)
    end)
end)

return nil
