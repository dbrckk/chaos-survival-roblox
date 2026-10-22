--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local RoundJourneyRules = require("../../src/shared/RoundJourneyRules")

local RoundVariety = require("../../src/server/RoundVariety")

local function d(id)
    return {Id = id}
end

describe("Round variety", function()
    it("removes the immediately previous primary when enough choices remain", function()
        local pool = {d("A"), d("B"), d("C"), d("D"), d("E")}
        local filtered = RoundVariety.excludeImmediateRepeat(pool, "C", 3)

        expect(#filtered).toBe(4)
        for _, item in ipairs(filtered) do
            expect(item.Id ~= "C").toBe(true)
        end
    end)

    it("keeps the full pool when excluding would leave too few choices", function()
        local pool = {d("A"), d("B"), d("C")}
        local filtered = RoundVariety.excludeImmediateRepeat(pool, "C", 3)

        expect(#filtered).toBe(3)
    end)

    it("does not mutate the original pool", function()
        local pool = {d("A"), d("B"), d("C"), d("D")}
        local filtered = RoundVariety.excludeImmediateRepeat(pool, "A", 3)

        expect(#pool).toBe(4)
        expect(#filtered).toBe(3)
        expect(pool[1].Id).toBe("A")
    end)

    it("excludes multiple recent primaries when the pool is large enough", function()
        local pool = {d("A"), d("B"), d("C"), d("D"), d("E"), d("F")}
        local filtered = RoundVariety.excludeRecent(pool, {"B", "D"}, 3)

        expect(#filtered).toBe(4)
        for _, item in ipairs(filtered) do
            expect(item.Id ~= "B").toBe(true)
            expect(item.Id ~= "D").toBe(true)
        end
    end)

    it("relaxes the oldest exclusion when needed to preserve vote choice", function()
        local pool = {d("A"), d("B"), d("C"), d("D")}
        local filtered = RoundVariety.excludeRecent(pool, {"A", "B"}, 3)

        expect(#filtered).toBe(3)
        local ids = {}
        for _, item in ipairs(filtered) do ids[item.Id] = true end
        expect(ids.A).toBe(true)
        expect(ids.B == true).toBe(false)
    end)

    it("prefers new unordered Double Chaos pairs without preventing fusion", function()
        local pool = {d("Meteors"), d("Bombs"), d("Tornado")}
        expect(RoundVariety.fusionKey("Bombs", "Meteors"))
            .toBe(RoundVariety.fusionKey("Meteors", "Bombs"))
        expect(RoundVariety.fusionKey("Bombs", "Bombs") == nil).toBe(true)
        expect(RoundVariety.fusionKey(nil, "Meteors") == nil).toBe(true)

        local recent = {"Bombs+Meteors", "Bombs+Tornado"}
        local candidates = RoundVariety.freshFusionCandidates(
            "Bombs", pool, recent
        )
        -- Even a malformed caller-supplied pool cannot force a Bombs+Bombs
        -- pairing, including when recent-history filtering must relax.
        expect(#candidates).toBe(2)
        expect(candidates[1].Id).toBe("Meteors")
        expect(candidates[2].Id).toBe("Tornado")
        local compatible = {d("Meteors"), d("Tornado")}
        local newPool = RoundVariety.freshFusionCandidates(
            "Bombs", compatible, {"Bombs+Meteors"}
        )
        expect(#newPool).toBe(1)
        expect(newPool[1].Id).toBe("Tornado")
        local fallback = RoundVariety.freshFusionCandidates(
            "Bombs", compatible, recent
        )
        expect(#fallback).toBe(2)
        expect(fallback[1].Id).toBe("Meteors")
        expect(fallback[2].Id).toBe("Tornado")
        expect(#compatible).toBe(2)
        expect(#pool).toBe(3)
        expect(#RoundVariety.freshFusionCandidates("Bombs", {}, recent))
            .toBe(0)
        expect(#RoundVariety.freshFusionCandidates("Bombs", {d("Bombs")}, {}))
            .toBe(0)
    end)

    it("maintains a bounded unique recent history", function()
        local recent = RoundVariety.pushRecent({"A", "B"}, "C", 2)
        expect(#recent).toBe(2)
        expect(recent[1]).toBe("B")
        expect(recent[2]).toBe("C")

        recent = RoundVariety.pushRecent(recent, "B", 2)
        expect(#recent).toBe(2)
        expect(recent[1]).toBe("C")
        expect(recent[2]).toBe("B")
    end)
end)


describe("Complete round journey", function()
    it("recognizes a full live sequence despite repeated phase snapshots", function()
        local stage = 0
        local completed = 0
        for _, phase in ipairs({
            "waiting", "intermission", "intermission",
            "ready", "ready", "round", "round", "result", "result",
        }) do
            local finished
            stage, finished = RoundJourneyRules.advance(stage, phase)
            if finished then completed += 1 end
        end
        expect(stage).toBe(4)
        expect(completed).toBe(1)
    end)

    it("rejects invalid phase order and restarts with a fresh intermission", function()
        local rules = RoundJourneyRules
        local stage, complete = rules.advance(0, "round")
        expect(stage).toBe(0)
        expect(complete).toBe(false)
        stage, complete = rules.advance(1, "round")
        expect(stage).toBe(0)
        expect(complete).toBe(false)
        stage, complete = rules.advance(2, "result")
        expect(stage).toBe(0)
        expect(complete).toBe(false)
        stage, complete = rules.advance(3, "result")
        expect(stage).toBe(4)
        expect(complete).toBe(true)
        stage, complete = rules.advance(4, "intermission")
        expect(stage).toBe(1)
        expect(complete).toBe(false)
        stage, complete = rules.advance(4, "waiting")
        expect(stage).toBe(0)
        expect(complete).toBe(false)
    end)
end)

return nil
