--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundCleanup = require("../../src/server/RoundCleanup")

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
