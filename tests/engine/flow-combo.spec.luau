--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local FlowCombo = require("../../src/server/FlowCombo")

describe("Flow combo", function()
    it("allows one shard pickup shortly after a mobility pad", function()
        expect(FlowCombo.qualifies(10, 14.9, false)).toBe(true)
        expect(FlowCombo.qualifies(10, 15, false)).toBe(true)
    end)

    it("rejects late or already claimed combos", function()
        expect(FlowCombo.qualifies(10, 15.01, false)).toBe(false)
        expect(FlowCombo.qualifies(10, 12, true)).toBe(false)
        expect(FlowCombo.qualifies(nil, 12, false)).toBe(false)
    end)

    it("keeps the economy bonus small", function()
        expect(FlowCombo.BonusCoins).toBe(2)
        expect(FlowCombo.BonusCoins <= 2).toBe(true)
        expect(FlowCombo.WindowSeconds).toBe(5)
    end)
end)

return nil
