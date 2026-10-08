--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Showtime = require("../../src/shared/LobbyShowtimeRules")

describe("Lobby Showtime", function()
    it("makes emotes available only in calm phases", function()
        expect(Showtime.enabled("waiting", nil)).toBe(true)
        expect(Showtime.enabled("intermission", nil)).toBe(true)
        expect(Showtime.enabled("result", nil)).toBe(true)
        expect(Showtime.enabled("intermission", {{id = "Meteors"}})).toBe(false)
        for _, phase in ipairs({"round", "ready", "unknown"}) do
            expect(Showtime.enabled(phase, nil)).toBe(false)
        end
    end)

    it("requires a living humanoid to start a dance", function()
        expect(Showtime.canEmote("waiting", nil, 100)).toBe(true)
        expect(Showtime.canEmote("waiting", nil, 0)).toBe(false)
        expect(Showtime.canEmote("result", nil, -1)).toBe(false)
        expect(Showtime.canEmote("round", nil, 100)).toBe(false)
    end)

    it("has native R15 and R6 clips for every displayed emote", function()
        expect(#Showtime.Order).toBe(4)
        for _, id in ipairs(Showtime.Order) do
            local r15 = Showtime.get(id, "R15")
            local r6 = Showtime.get(id, "R6")
            expect(r15 ~= nil).toBe(true)
            expect(r6 ~= nil).toBe(true)
            expect(r15.AnimationId > 0).toBe(true)
            expect(r6.AnimationId > 0).toBe(true)
            expect(#r15.LabelEN > 0 and #r15.LabelFR > 0).toBe(true)
        end
        expect(Showtime.get("unknown", "R15") == nil).toBe(true)
        expect(Showtime.get("dance", "unknown") == nil).toBe(true)
    end)

    it("keeps emote controls clear of the accessibility panel", function()
        for _, entry in ipairs({
            {width = 540, touch = true, narrow = true, settingsWidth = 176, rightGap = 10},
            {width = 640, touch = true, narrow = false, settingsWidth = 186, rightGap = 10},
            {width = 1280, touch = false, narrow = false, settingsWidth = 178, rightGap = 19.2},
        }) do
            local inset = Showtime.dockRightInset(entry.width, entry.touch, entry.narrow)
            expect(inset - entry.rightGap - entry.settingsWidth >= 12).toBe(true)
            expect(entry.width - inset - 232 >= 0).toBe(true)
        end
    end)

    it("caps procedural dance scenery for each graphics tier", function()
        local low = Showtime.profile("Low")
        local mid = Showtime.profile("Medium")
        local high = Showtime.profile("High")
        expect(low.Grid < mid.Grid and mid.Grid < high.Grid).toBe(true)
        expect(low.Dancers).toBe(0)
        expect(mid.Dancers).toBe(1)
        expect(high.Dancers).toBe(2)
        expect(low.Lights).toBe(0)
        expect(mid.Lights <= high.Lights).toBe(true)
        expect(low.Bursts <= mid.Bursts and mid.Bursts <= high.Bursts).toBe(true)
        expect(low.Interval > high.Interval).toBe(true)
    end)
end)

return nil
