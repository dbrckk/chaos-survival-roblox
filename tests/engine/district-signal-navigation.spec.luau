--!strict
-- 2026-11-05 Android screenshots: never advertise optional +2 signal
-- with 2s left and 123 studs to the target as a live doable objective.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Rules = require("../../src/shared/DistrictSignalNavigationRules")
local CoreLocalization = require("../../src/shared/CoreLocalization")

describe("Android timed district objective feasibility", function()
    it("suppresses screenshot-class impossible live goals", function()
        expect(Rules.liveCueReachable(2, 123)).toBe(false)
        expect(Rules.liveCueReachable(2, 123, 120, 30, 0.55))
            .toBe(false)
        expect(Rules.liveCueReachable(6, 121, 121, 38, 0.55))
            .toBe(true) -- 121 studs of optimistic DASH can beat 6s
        expect(Rules.liveCueReachable(0, 2)).toBe(false)
        expect(Rules.liveCueReachable(-1, 0)).toBe(false)
    end)

    it("preserves physically plausible short walks and free transit", function()
        expect(Rules.liveCueReachable(2, 30)).toBe(true)
        expect(Rules.liveCueReachable(1, 30)).toBe(false)
        expect(Rules.liveCueReachable(3, 160, 0, 30, 0.55))
            .toBe(true)
        expect(Rules.liveCueReachable(3, 160)).toBe(false)
        expect(Rules.liveCueReachable(1.5, 50, 80, 50, 0.55))
            .toBe(false)
    end)

    it("rejects malformed distances and false gate metadata", function()
        expect(Rules.liveCueReachable(5, math.huge)).toBe(false)
        expect(Rules.liveCueReachable(5, -1)).toBe(false)
        expect(Rules.liveCueReachable(5, 90, -1, 1)).toBe(true)
        expect(Rules.liveCueReachable(5, 90, 1, math.huge))
            .toBe(true)
        expect(Rules.liveCueReachable(math.huge, 1)).toBe(false)
    end)

    it("provides distinct compact OPEN/CLOSE copy with no ellipsis", function()
        expect(CoreLocalization.text(
            "fr-fr", "DISTRICT_SIGNAL_OPENS_SHORT", "6s"))
            .toBe("OUVRE 6s")
        expect(CoreLocalization.text(
            "fr-fr", "DISTRICT_SIGNAL_ENDS_SHORT", "2s"))
            .toBe("FIN 2s")
        expect(CoreLocalization.text(
            "en-us", "DISTRICT_SIGNAL_OPENS_SHORT", "6s"))
            .toBe("OPENS 6s")
        expect(CoreLocalization.text(
            "en-us", "DISTRICT_SIGNAL_ENDS_SHORT", "2s"))
            .toBe("ENDS 2s")
        local shortFR = CoreLocalization.hazardHint(
            "fr-fr", "DisappearingPlatforms")
        expect(shortFR).toBe("QUITTE LES PLATEFORMES QUI CLIGNOTENT")
        expect(#shortFR <= 40).toBe(true)
    end)
end)

return nil
