--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AttentionBudgetRules = require("../../src/shared/AttentionBudgetRules")

describe("attention budget rules", function()
    it("treats only intermission with options as active voting", function()
        expect(AttentionBudgetRules.voteActive("intermission", {"A", "B", "C"})).toBe(true)
        expect(AttentionBudgetRules.voteActive("intermission", {})).toBe(false)
        expect(AttentionBudgetRules.voteActive("round", {"A"})).toBe(false)
    end)

    it("suppresses meta controls during vote ready round and result", function()
        expect(AttentionBudgetRules.suppressMetaControls(
            "intermission",
            {"A", "B", "C"},
            4
        )).toBe(true)
        expect(AttentionBudgetRules.suppressMetaControls("ready", nil, 4)).toBe(true)
        expect(AttentionBudgetRules.suppressMetaControls("round", nil, 4)).toBe(true)
        expect(AttentionBudgetRules.suppressMetaControls("result", nil, 4)).toBe(true)
    end)

    it("keeps the first session focused on learning the core loop", function()
        expect(AttentionBudgetRules.suppressMetaControls("waiting", nil, 0)).toBe(true)
        expect(AttentionBudgetRules.suppressMetaControls("intermission", nil, 0)).toBe(true)
    end)

    it("only shows meta notifications in a calm non-voting intermission", function()
        expect(AttentionBudgetRules.canShowMetaNotification(
            "intermission",
            nil,
            2
        )).toBe(true)
        expect(AttentionBudgetRules.canShowMetaNotification(
            "intermission",
            {"A", "B", "C"},
            2
        )).toBe(false)
        expect(AttentionBudgetRules.canShowMetaNotification("round", nil, 2)).toBe(false)
        expect(AttentionBudgetRules.canShowMetaNotification("result", nil, 2)).toBe(false)
        expect(AttentionBudgetRules.canShowMetaNotification("intermission", nil, 0)).toBe(false)
    end)

    it("allows meta controls only in calm phases after the first game", function()
        expect(AttentionBudgetRules.suppressMetaControls("waiting", nil, 2)).toBe(false)
        expect(AttentionBudgetRules.suppressMetaControls("intermission", nil, 2)).toBe(false)
        expect(AttentionBudgetRules.suppressMetaControls("intermission", {}, 2)).toBe(false)
    end)
end)

return nil
