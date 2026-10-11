--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Showtime = require("../../src/shared/LobbyShowtimeRules")
local UITheme = require("../../src/shared/UITheme")
local ShowtimeProps = require("../../src/client/ShowtimeProps")
local ShowtimeChoreography = require("../../src/client/ShowtimeChoreography")
local ShowtimeHologramDetails = require("../../src/client/ShowtimeHologramDetails")

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

    it("supports eight Animator-safe emotes with two original visual dances", function()
        expect(#Showtime.Order).toBe(8)
        for _, id in ipairs(Showtime.Order) do
            local r15 = Showtime.get(id, "R15")
            local r6 = Showtime.get(id, "R6")
            expect(r15 ~= nil).toBe(true)
            expect(r6 ~= nil).toBe(true)
            expect(r15.AnimationId > 0).toBe(true)
            expect(r6.AnimationId > 0).toBe(true)
            if id == "robot" or id == "orbit" then
                expect(r15.VisualStyle).toBe(id)
                expect(r6.VisualStyle).toBe(id)
            end
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

    it("keeps both the mobile emote grid and Settings reachable on tiny screens", function()
        for _, width in ipairs({320, 360, 400, 440}) do
            expect(Showtime.dockSide(width, true)).toBe("left")
            expect(12 + math.min(232, width - 24) <= width - 12).toBe(true)
        end
        expect(Showtime.dockSide(450, true)).toBe("right")
        expect(Showtime.dockSide(540, true)).toBe("right")
        expect(Showtime.dockSide(320, false)).toBe("right")
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
        local low = ShowtimeProps.build(container, CFrame.new(0, 5, 0), "Low", UITheme)
        local high = ShowtimeProps.build(container, CFrame.new(0, 5, 0), "High", UITheme)
        expect(low.folder:FindFirstChild("ShowtimeDJBooth") ~= nil).toBe(true)
        expect(low.folder:FindFirstChild("ShowtimeSpeakerHousing1") ~= nil).toBe(true)
        expect(high.folder:FindFirstChild("ShowtimeTrussAccent1") ~= nil).toBe(true)
        expect(low.folder:FindFirstChild("ShowtimeWaveguideRib1") ~= nil).toBe(true)
        expect(high.folder:FindFirstChild("ShowtimeWaveguideRib8") ~= nil).toBe(true)
        expect(high.folder:FindFirstChild("ShowtimeAcousticWingEdge-1") ~= nil).toBe(true)
        expect(low.folder:FindFirstChild("ShowtimeAcousticWingEdge-1") == nil).toBe(true)
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

    it("has eight authored, visually different synchronized dancer poses", function()
        local choreography = ShowtimeChoreography
        local labels = {"dance", "shuffle", "groove", "robot", "orbit", "cheer", "wave", "laugh"}
        for _, style in ipairs(labels) do
            expect(choreography.style(12.3, 1, style, 2)).toBe(style)
            local pose = choreography.pose(12.3, 1, style, 2, false)
            expect(pose.Style).toBe(style)
            expect(math.abs(pose.Sway) <= 0.8).toBe(true)
            expect(math.abs(pose.Bob) <= 0.3).toBe(true)
            expect(math.abs(pose.LegSwing) <= 0.6).toBe(true)
            expect(math.abs(pose.ArmL) <= 1.8).toBe(true)
            expect(math.abs(pose.ArmR) <= 1.8).toBe(true)
        end
        local cheer = choreography.pose(12.3, 1, "cheer", 2, false)
        local wave = choreography.pose(12.3, 1, "wave", 2, false)
        local shuffle = choreography.pose(12.3, 1, "shuffle", 2, false)
        expect(math.abs(cheer.ArmL) > math.abs(wave.ArmL)).toBe(true)
        expect(math.abs(wave.ArmR) > math.abs(shuffle.ArmR)).toBe(true)
        expect(math.abs(shuffle.LegSwing) > math.abs(wave.LegSwing)).toBe(true)
        local robotA = choreography.pose(12.3, 1, "robot", 2, false)
        local robotB = choreography.pose(12.6, 1, "robot", 2, false)
        local orbit = choreography.pose(12.3, 1, "orbit", 2, false)
        expect(robotA.Style).toBe("robot")
        expect(robotA.ArmL ~= robotB.ArmL or robotA.Yaw ~= robotB.Yaw).toBe(true)
        expect(math.abs(orbit.Roll) <= 0.20).toBe(true)
        expect(orbit.ArmL ~= robotA.ArmL).toBe(true)
        expect(choreography.style(12.3, 1, "invalid", 2) ~= "invalid").toBe(true)
        expect(choreography.style(5.0, 1, "wave", 0) ~= "wave").toBe(true)
        expect(choreography.style(5.0, 1, nil, 0)
            ~= choreography.style(5.0, 2, nil, 0)).toBe(true)
    end)

    it("updates the existing stage sign for solo players, group dances and named emotes", function()
        local caption = ShowtimeChoreography.caption
        expect(caption(nil, 0, true)).toBe("PISTE DE DANSE")
        expect(caption(nil, 0, false)).toBe("CHAOS SHOWTIME")
        expect(caption(nil, 1, false)).toBe("JOIN THE FLOOR")
        expect(caption(nil, 3, true)).toBe("DANSONS ENSEMBLE")
        expect(caption("wave", 1, true)).toBe("EN DUO / SALUT")
        expect(caption("cheer", 2, false)).toBe("DUET / CHEER")
        expect(caption("laugh", 4, true)).toBe("EN DUO / RIRE")
        expect(caption("unknown", 4, false)).toBe("DANCE TOGETHER")
        expect(caption("dance", 0, true)).toBe("PISTE DE DANSE")
    end)

    it("freezes every moving joint for reduced motion while retaining an emote silhouette", function()
        for _, id in ipairs({"dance", "shuffle", "groove", "robot", "orbit", "cheer", "wave", "laugh"}) do
            local first = ShowtimeChoreography.pose(6, 1, id, 3, true)
            local second = ShowtimeChoreography.pose(32, 1, id, 3, true)
            expect(first.Style).toBe(id)
            for _, key in ipairs({
                "Sway", "Bob", "Yaw", "Roll", "HeadYaw", "LegSwing", "ArmSwing",
            }) do
                expect(first[key]).toBe(0)
                expect(second[key]).toBe(0)
            end
            expect(first.ArmL).toBe(second.ArmL)
            expect(first.ArmR).toBe(second.ArmR)
        end
    end)

    it("builds layered hologram costume pieces without new render lights or collisions", function()
        local container = Instance.new("Folder")
        local count = {Low = 0, Medium = 2, High = 4}
        local color = UITheme.Colors.Cyan
        local face = CFrame.new(17, 5, -4) * CFrame.Angles(0, math.rad(38), 0)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local details = ShowtimeHologramDetails.build(container, tier, 2, color)
            expect(#details).toBe(count[tier])
            expect(#details).toBe(ShowtimeHologramDetails.count(tier))
            ShowtimeHologramDetails.pose(
                details, face, face * CFrame.new(0, 1.35, 0),
                face * CFrame.new(-0.78, 0.28, 0),
                face * CFrame.new(0.78, 0.28, 0), true
            )
            for _, p in ipairs(details) do
                expect(p:GetAttribute("ChaosHologramDetail")).toBe(true)
                expect(p:IsA("BasePart")).toBe(true)
                expect(p.CanCollide).toBe(false)
                expect(p.CanTouch).toBe(false)
                expect(p.CanQuery).toBe(false)
                expect(p.Anchored).toBe(true)
                expect(p.CastShadow).toBe(false)
                expect(p.Material == Enum.Material.Neon).toBe(false)
                expect(p.Transparency < 0.40).toBe(true)
                expect((p.Position - face.Position).Magnitude < 2).toBe(true)
            end
            ShowtimeHologramDetails.pose(details, face, face, face, face, false)
            for _, p in ipairs(details) do
                expect(p.Transparency).toBe(1)
                p:Destroy()
            end
        end
        expect(#container:GetChildren()).toBe(0)
        expect(#ShowtimeHologramDetails.build(nil, "High", 2, color)).toBe(0)
        expect(#ShowtimeHologramDetails.build(container, "Bad", 2, color)).toBe(0)
        expect(#ShowtimeHologramDetails.build(container, "High", 0, color)).toBe(0)
        container:Destroy()
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
