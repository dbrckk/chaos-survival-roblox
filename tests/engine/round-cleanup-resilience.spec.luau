--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundCleanup = require("../../src/server/RoundCleanup")
local RoundSettlement = require("../../src/server/RoundSettlement")

describe("Round settlement resilience", function()
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
