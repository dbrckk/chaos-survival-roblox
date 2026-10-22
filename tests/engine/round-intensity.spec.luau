--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundIntensity = require("../../src/server/RoundIntensity")
local ImpactWaveDirector = require("../../src/server/ImpactWaveDirector")

describe("Round intensity director", function()
    it("ramps smoothly through a normal round", function()
        local start = RoundIntensity.factor(0, 40, false, false)
        local middle = RoundIntensity.factor(20, 40, false, false)
        local finish = RoundIntensity.factor(40, 40, false, false)

        expect(start).toBe(0.92)
        expect(middle > start).toBe(true)
        expect(finish > middle).toBe(true)
        expect(finish).toBe(1.22)
    end)

    it("caps escalation for solo and double chaos", function()
        expect(RoundIntensity.factor(40, 40, true, false)).toBe(1.14)
        expect(RoundIntensity.factor(40, 40, false, true)).toBe(1.10)
        expect(RoundIntensity.factor(40, 40, true, true)).toBe(1.06)
    end)

    it("clamps progress and spawn delay", function()
        expect(RoundIntensity.progress(-10, 40)).toBe(0)
        expect(RoundIntensity.progress(100, 40)).toBe(1)
        expect(RoundIntensity.spawnDelay(1, 2, 0.6)).toBe(0.6)
        expect(RoundIntensity.spawnDelay(1, 0.5, 0.2)).toBe(2)
    end)
    it("unlocks three distinct meteor/bomb patterns only after guided rounds", function()
        local wave = ImpactWaveDirector
        expect(wave.mode(0, 40, true, 40, 40)).toBe("Scatter")
        expect(wave.mode(12, 40, true, 40, 40)).toBe("Scatter")
        expect(wave.mode(13, 40, true, 40, 40)).toBe("Sweep")
        expect(wave.mode(26, 40, true, 40, 40)).toBe("Sweep")
        expect(wave.mode(27, 40, true, 40, 40)).toBe("Flanks")
        expect(wave.mode(42, 40, true, 40, 40)).toBe("Flanks")
        expect(wave.mode(28, 40, false, 40, 40)).toBe("Scatter")
        expect(wave.mode(28, 20, true, 40, 40)).toBe("Scatter")
        expect(wave.mode(28, 40, true, 12, 40)).toBe("Scatter")
        expect(wave.mode(28, 40, true, 40, 12)).toBe("Scatter")
        expect(wave.mode(math.huge, 40, true, 40, 40)).toBe("Scatter")
        expect(wave.forContext(nil, 12, 40, 40)).toBe("Scatter")
        expect(wave.forContext({
            EnableImpactWaves = false, RoundStartedAt = 100,
            RoundSeconds = 40,
        }, 128, 40, 40)).toBe("Scatter")
        expect(wave.forContext({
            EnableImpactWaves = true, RoundStartedAt = 100,
            RoundSeconds = 40,
        }, 128, 40, 40)).toBe("Flanks")
    end)

    it("sweeps predictably before alternating flank strikes within arena bounds", function()
        local wave = ImpactWaveDirector
        local xPositions = {}
        for step = 1, 5 do
            local offset = wave.anchor("Sweep", step, 5, "Meteors", 42, 42)
            expect(typeof(offset)).toBe("Vector3")
            expect(math.abs(offset.Y)).toBe(0)
            expect(math.abs(offset.X) < 33 and math.abs(offset.Z) < 33)
                .toBe(true)
            xPositions[#xPositions + 1] = offset.X
        end
        for i = 2, #xPositions do
            expect(xPositions[i] > xPositions[i - 1]).toBe(true)
        end
        local returnSweep = wave.anchor("Sweep", 6, 5, "Meteors", 42, 42)
        expect(returnSweep.Z * wave.anchor(
            "Sweep", 1, 5, "Meteors", 42, 42
        ).Z < 0).toBe(true)
        local meteor = wave.anchor("Sweep", 1, 5, "Meteors", 42, 42)
        local bomb = wave.anchor("Sweep", 1, 5, "Bombs", 42, 42)
        expect(meteor.X * bomb.X < 0).toBe(true)
        expect(meteor.Z * bomb.Z < 0).toBe(true)

        local first = wave.anchor("Flanks", 1, 7, "Meteors", 42, 38)
        local second = wave.anchor("Flanks", 2, 7, "Meteors", 42, 38)
        expect(first.X * second.X < 0).toBe(true)
        expect(first.Z * second.Z < 0).toBe(true)
        for _, mode in ipairs({"Sweep", "Flanks"}) do
            for index = 1, 17 do
                local points = wave.candidates(mode, index, 7,
                    "Bombs", 42, 38)
                expect(#points).toBe(7)
                for _, point in ipairs(points) do
                    expect(math.abs(point.X) <= 42 * 0.78 + 0.001).toBe(true)
                    expect(math.abs(point.Z) <= 38 * 0.78 + 0.001).toBe(true)
                    expect(point.Y).toBe(0)
                end
            end
        end
        expect(wave.anchor("Scatter", 1, 7, "Bombs", 42, 38)
            == nil).toBe(true)
        expect(#wave.candidates("Sweep", 1, 7, "Bombs", 10, 38))
            .toBe(0)
    end)
end)

return nil
