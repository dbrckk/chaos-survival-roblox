--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local GameAnalytics = require("../../src/server/GameAnalytics")
local PerformancePulseRules = require("../../src/shared/PerformancePulseRules")

describe("Game analytics helpers", function()
    it("samples initial 3D availability after 12 active seconds, then every 45 seconds", function()
        expect(PerformancePulseRules.pulseInterval(true)).toBe(12)
        expect(PerformancePulseRules.pulseInterval(false)).toBe(45)
        expect(PerformancePulseRules.pulseInterval(nil)).toBe(45)
        expect(PerformancePulseRules.pulseInterval("true")).toBe(45)
    end)

    it("reports genuine live 3D residency without mistaking eligible assets for mounted visuals", function()
        local rules = PerformancePulseRules
        local sample = rules.sanitize({
            arenaVariant = "Orbital", deviceClass = "Touch",
            vfxTier = "Medium", originalGround = 12.9,
            originalRoutes = 8.3, originalHorizon = 3.8,
            originalTraffic = 0, originalHalo = 2,
            originalHorizonMasked = 8, originalHaloMasked = 2,
            optionalPressure = 1,
        })
        expect(sample.arenaVariant).toBe("Orbital")
        expect(sample.originalGround).toBe(12)
        expect(sample.originalRoutes).toBe(8)
        expect(sample.originalHorizon).toBe(3)
        expect(sample.originalTraffic).toBe(0)
        expect(sample.originalHalo).toBe(2)
        expect(sample.originalHorizonMasked).toBe(8)
        expect(sample.originalHaloMasked).toBe(2)
        expect(sample.optionalPressure).toBe(1)
        local count, arena, tier, flags = rules.original3DAnalytics(sample)
        expect(count).toBe(25)
        expect(arena).toBe("Arena:Orbital")
        expect(tier).toBe("Device:Touch|VFX:Medium")
        expect(flags).toBe("P1C1T0H1F0")

        -- Partial source replication or a stale fallback mask must be
        -- visible in telemetry, never silently classified as healthy.
        local _, _, _, broken = rules.original3DAnalytics({
            arenaVariant = "Harbor", vfxTier = "High",
            deviceClass = "Desktop", originalHorizon = 2,
            originalTraffic = 2, originalHalo = 1,
            originalHorizonMasked = 0, originalHaloMasked = 0,
        })
        expect(broken).toBe("P0C1T1H1F1")
    end)

    it("bounds untrusted visual residence samples and refuses injected analytics dimensions", function()
        local rules = PerformancePulseRules
        local dangerous = rules.sanitize({
            originalGround = math.huge,
            originalRoutes = -100,
            originalHorizon = 1000.2,
            originalTraffic = 12,
            originalHalo = 0 / 0,
            originalHorizonMasked = 99,
            originalHaloMasked = math.huge,
            optionalPressure = 70,
            arenaVariant = "Orbital|Device:Other",
            vfxTier = "Unverified", deviceClass = "??",
        })
        expect(dangerous.originalGround).toBe(0)
        expect(dangerous.originalRoutes).toBe(0)
        expect(dangerous.originalHorizon).toBe(11)
        expect(dangerous.originalTraffic).toBe(4)
        expect(dangerous.originalHalo).toBe(0)
        expect(dangerous.originalHorizonMasked).toBe(33)
        expect(dangerous.originalHaloMasked).toBe(0)
        expect(dangerous.optionalPressure).toBe(2)
        expect(dangerous.arenaVariant).toBe("Unknown")
        local count, arena, device, flags = rules.original3DAnalytics(dangerous)
        expect(count).toBe(15)
        expect(arena).toBe("Arena:Unknown")
        expect(device).toBe("Device:Unknown|VFX:Unknown")
        expect(flags).toBe("P0C1T1H0F0")
        local emptyCount, emptyArena, emptyDevice, emptyFlags =
            rules.original3DAnalytics(nil)
        expect(emptyCount).toBe(0)
        expect(emptyArena).toBe("Arena:Unknown")
        expect(emptyDevice).toBe("Device:Unknown|VFX:Unknown")
        expect(emptyFlags).toBe("P0C0T0H0F0")
    end)


    it("labels solo and multiplayer consistently", function()
        expect(GameAnalytics.modeLabel(true)).toBe("Solo")
        expect(GameAnalytics.modeLabel(false)).toBe("Multiplayer")
    end)

    it("uses bounded server-observed entry phases and time bands for retention", function()
        local a = GameAnalytics
        for _, phase in ipairs({"waiting", "intermission", "ready", "round", "result"}) do
            expect(a.arrivalPhase(phase)).toBe(phase)
        end
        for _, bad in ipairs({"ROUND", "unknown phase", 7, {}, true}) do
            expect(a.arrivalPhase(bad)).toBe("unknown")
        end
        expect(a.arrivalPhase(nil)).toBe("unknown")
        expect(a.phaseRemainingBand(0)).toBe("0-10s")
        expect(a.phaseRemainingBand(10)).toBe("0-10s")
        expect(a.phaseRemainingBand(11)).toBe("11-30s")
        expect(a.phaseRemainingBand(30)).toBe("11-30s")
        expect(a.phaseRemainingBand(31)).toBe("31-60s")
        expect(a.phaseRemainingBand(60)).toBe("31-60s")
        expect(a.phaseRemainingBand(61)).toBe("61s+")
        expect(a.phaseRemainingBand(-1)).toBe("Unknown")
        expect(a.phaseRemainingBand(math.huge)).toBe("Unknown")
        expect(a.phaseRemainingBand(-math.huge)).toBe("Unknown")
        expect(a.phaseRemainingBand(0 / 0)).toBe("Unknown")
        expect(a.phaseRemainingBand("12")).toBe("11-30s")
        expect(a.phaseRemainingBand(nil)).toBe("Unknown")
    end)

    it("creates at most three valid custom analytics fields", function()
        local values = GameAnalytics.fields("Mode:Solo", "Result:Survived", "Disaster:Meteors")
        local count = 0

        for key, value in pairs(values) do
            count += 1
            expect(type(key)).toBe("string")
            expect(type(value)).toBe("string")
        end

        expect(count).toBe(3)
        expect(values[Enum.AnalyticsCustomFieldKeys.CustomField01.Name]).toBe("Mode:Solo")
        expect(values[Enum.AnalyticsCustomFieldKeys.CustomField02.Name]).toBe("Result:Survived")
        expect(values[Enum.AnalyticsCustomFieldKeys.CustomField03.Name]).toBe("Disaster:Meteors")
    end)

    it("builds stable low-cardinality arena cohorts for every round type", function()
        local a = GameAnalytics
        for _, arena in ipairs({"Classic", "Towers", "Crossroads", "Orbital", "Harbor"}) do
            local field1, field2, field3 = a.arenaRoundFields(
                arena, true, "Meteors", false, true
            )
            expect(field1).toBe("Arena:" .. arena)
            expect(field2).toBe("Mode:Solo")
            expect(field3).toBe("Primary:Meteors|Fusion:No|Extra:Yes")

            local _, multiplayer, fallback = a.arenaRoundFields(
                arena, false, "JumpShock", true, false
            )
            expect(multiplayer).toBe("Mode:Multiplayer")
            expect(fallback).toBe("Primary:JumpShock|Fusion:Yes|Extra:No")
        end

        local unknown, solo, safe = a.arenaRoundFields(
            "../../unexpected", true, "bad;injected:value", false, false
        )
        expect(unknown).toBe("Arena:Unknown")
        expect(solo).toBe("Mode:Solo")
        expect(safe).toBe("Primary:Unknown|Fusion:No|Extra:No")
        local _, _, empty = a.arenaRoundFields(nil, nil, nil, nil, nil)
        expect(empty).toBe("Primary:Unknown|Fusion:No|Extra:No")
    end)

    it("normalizes real time-alive measurements and one-per-round AI rates", function()
        local a = GameAnalytics
        expect(a.roundAliveSeconds(30, 4.25, false)).toBe(4.25)
        expect(a.roundAliveSeconds(30, 4.25, true)).toBe(30)
        expect(a.roundAliveSeconds(7, 10, false)).toBe(7)
        expect(a.roundAliveSeconds(17.5, nil, false)).toBe(17.5)
        expect(a.roundAliveSeconds(30, -6, false)).toBe(0)
        expect(a.roundAliveSeconds(500, 10, true)).toBe(120)
        expect(a.roundAliveSeconds(20, math.huge, false)).toBe(0)
        expect(a.botSurvivalFraction(0, 0) == nil).toBe(true)
        expect(a.botSurvivalFraction(4, 3)).toBe(0.75)
        expect(a.botSurvivalFraction(4, 9)).toBe(1)
        expect(a.botSurvivalFraction(4, -2)).toBe(0)
        expect(a.botSurvivalFraction(3, 0)).toBe(0)
        expect(a.botSurvivalFraction("invalid", 2) == nil).toBe(true)
        expect(a.arenaRoundMetrics(nil, {})).toBe(false)
        expect(a.arenaBotMetrics(nil, {})).toBe(false)
    end)

    it("omits empty custom field slots", function()
        local values = GameAnalytics.fields("Mode:Multiplayer", nil, nil)
        local count = 0
        for _ in pairs(values) do
            count += 1
        end

        expect(count).toBe(1)
    end)
end)

return nil
