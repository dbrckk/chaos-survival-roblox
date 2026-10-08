--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Showtime = require("../../src/shared/LobbyShowtimeRules")
local ShowtimeProps = require("../../src/client/ShowtimeProps")

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
        expect(#Showtime.Order).toBe(6)
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

    it("celebrates only surviving players once, without forced motion", function()
        expect(Showtime.shouldCelebrate("result", "round", {12, 34}, 12, false)).toBe(true)
        expect(Showtime.shouldCelebrate("result", "result", {12}, 12, false)).toBe(false)
        expect(Showtime.shouldCelebrate("result", "round", {12}, 12, true)).toBe(false)
        expect(Showtime.shouldCelebrate("result", "round", {34}, 12, false)).toBe(false)
        expect(Showtime.shouldCelebrate("round", "ready", {12}, 12, false)).toBe(false)
        expect(Showtime.shouldCelebrate("result", "round", nil, 12, false)).toBe(false)
    end)

    it("limits spatial stage audio to nearby unmuted calm phases", function()
        expect(Showtime.spatialBeatActive("waiting", nil, 4, false)).toBe(true)
        expect(Showtime.spatialBeatActive("intermission", nil, 23, false)).toBe(true)
        expect(Showtime.spatialBeatActive("waiting", nil, 25, false)).toBe(false)
        expect(Showtime.spatialBeatActive("waiting", nil, 4, true)).toBe(false)
        expect(Showtime.spatialBeatActive("round", nil, 4, false)).toBe(false)
        expect(Showtime.spatialBeatActive("intermission", {{id = "Meteors"}}, 4, false)).toBe(false)
        expect(Showtime.spatialBeatActive("result", nil, nil, false)).toBe(false)
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

    it("builds real non-colliding stage props and restores them after combat", function()
        local container = Instance.new("Folder")
        local low = ShowtimeProps.build(container, CFrame.new(0, 5, 0), "Low")
        local high = ShowtimeProps.build(container, CFrame.new(0, 5, 0), "High")
        expect(low.folder:FindFirstChild("ShowtimeDJBooth") ~= nil).toBe(true)
        expect(low.folder:FindFirstChild("ShowtimeSpeakerHousing1") ~= nil).toBe(true)
        expect(high.folder:FindFirstChild("ShowtimeTrussAccent1") ~= nil).toBe(true)
        expect(low.folder:FindFirstChild("ShowtimeCrownCrystal") ~= nil).toBe(true)
        expect(high.folder:FindFirstChild("ShowtimeCrownHeart") ~= nil).toBe(true)
        expect(#low.crown.orbit).toBe(6)
        expect(#high.crown.orbit).toBe(28)
        expect(#high.props > #low.props).toBe(true)
        expect(#high.props <= 100).toBe(true)

        for _, descendant in ipairs(high.props) do
            if descendant:IsA("BasePart") then
                expect(descendant.CanCollide).toBe(false)
                expect(descendant.CanTouch).toBe(false)
                expect(descendant.CanQuery).toBe(false)
            end
        end

        local casing = low.folder:FindFirstChild("ShowtimeSpeakerHousing1")
        ShowtimeProps.update(low, 1.0, false, false, 0)
        expect(casing.Transparency).toBe(1)
        ShowtimeProps.update(low, 1.2, true, false, 2)
        expect(casing.Transparency < 1).toBe(true)
        local equalizer = low.folder:FindFirstChild("ShowtimeEqualizer1")
        ShowtimeProps.update(low, 2.0, true, true, 0)
        -- Roblox Vector3 components are float32; avoid exact equality to
        -- decimal literals represented as double-precision Luau numbers.
        expect(math.abs(equalizer.Size.Y - 0.38) < 0.0001).toBe(true)
        expect(#low.equalizer).toBe(3)
        expect(#high.equalizer).toBe(8)

        local firstRing = low.crown.orbit[1].part
        ShowtimeProps.update(low, 2.0, true, true, 0)
        local atRest = firstRing.CFrame
        ShowtimeProps.update(low, 5.0, true, true, 4)
        expect(firstRing.CFrame).toBe(atRest)
        ShowtimeProps.update(low, 6.0, true, false, 4)
        expect(firstRing.CFrame ~= atRest).toBe(true)
        ShowtimeProps.update(low, 7.0, false, false, 0)
        expect(firstRing.Transparency).toBe(1)
        ShowtimeProps.update(low, 7.2, true, true, 0)
        expect(firstRing.Transparency < 1).toBe(true)
        container:Destroy()
    end)

    it("animates a bounded radial floor wave with no flash in reduce-motion mode", function()
        expect(Showtime.floorPulse(0, 0, false)).toBe(1)
        expect(Showtime.floorPulse(6, 0.5, false) > 0.3).toBe(true)
        expect(Showtime.floorPulse(6, 0.5, true)).toBe(0)
        expect(Showtime.floorPulse(100, 0.5, false)).toBe(0)
        expect(Showtime.floorPulse(0, -1, false)).toBe(0)
        expect(Showtime.floorPulse(0, 1.5, false)).toBe(0)
        expect(Showtime.floorPulse(6, nil, false)).toBe(0)
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
