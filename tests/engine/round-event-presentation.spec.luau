--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local RoundEventPresentation = require("../../src/shared/RoundEventPresentation")
local CinematicPulseRingKit = require("../../src/client/CinematicPulseRingKit")

describe("Round event presentation", function()
    it("mixes double-chaos accent colors", function()
        local colors = {
            A = Color3.fromRGB(255, 0, 0),
            B = Color3.fromRGB(0, 0, 255),
        }
        local color = RoundEventPresentation.accent({"A", "B"}, function(id)
            return colors[id]
        end)

        expect(math.abs(color.R - 0.5) < 0.01).toBe(true)
        expect(math.abs(color.B - 0.5) < 0.01).toBe(true)
    end)

    it("presents single chaos as an immediate survival reveal", function()
        local main, sub = RoundEventPresentation.roundTitle({
            title = "SOLO RUSH: Meteor Shower",
            doubleChaos = false,
        })
        expect(main).toBe("SURVIVE!")
        expect(sub).toBe("Meteor Shower")
    end)

    it("presents double chaos as an explicit fusion survival reveal", function()
        local main, sub = RoundEventPresentation.roundTitle({
            title = "CHAOS FUSION: Storm Core",
            doubleChaos = true,
            fusionName = "Storm Core",
        })
        expect(main).toBe("SURVIVE THE FUSION!")
        expect(string.find(sub, "Storm Core", 1, true) ~= nil).toBe(true)
        expect(string.find(sub, "TWO HAZARDS ACTIVE", 1, true) ~= nil).toBe(true)
    end)

    it("only returns ready countdown values inside the last three seconds", function()
        expect(RoundEventPresentation.countdownValue({
            phase = "ready",
            seconds = 3,
        }, "ready")).toBe(3)

        expect(RoundEventPresentation.countdownValue({
            phase = "ready",
            seconds = 1,
        }, "ready")).toBe(1)

        expect(RoundEventPresentation.countdownValue({
            phase = "ready",
            seconds = 4,
        }, "ready") == nil).toBe(true)

        expect(RoundEventPresentation.countdownValue({
            phase = "round",
            seconds = 3,
        }, "ready") == nil).toBe(true)
    end)

    it("gives stronger camera kick to fusion round starts", function()
        local normal = RoundEventPresentation.cameraKick(
            "ready",
            {phase = "round", doubleChaos = false},
            false,
            false
        )
        local fusion = RoundEventPresentation.cameraKick(
            "ready",
            {phase = "round", doubleChaos = true},
            false,
            false
        )

        expect(normal > 0).toBe(true)
        expect(fusion > normal).toBe(true)
    end)

    it("only kicks once for final rush and overdrive transitions", function()
        expect(RoundEventPresentation.cameraKick(
            "round",
            {phase = "round", finalRush = true},
            false,
            false
        ) > 0).toBe(true)

        expect(RoundEventPresentation.cameraKick(
            "round",
            {phase = "round", finalRush = true},
            true,
            false
        )).toBe(0)

        expect(RoundEventPresentation.cameraKick(
            "round",
            {phase = "round", overdrive = true},
            false,
            false
        ) > 0).toBe(true)
    end)

    it("adds camera emphasis only on meaningful phase changes", function()
        expect(RoundEventPresentation.cameraKick("ready", {
            phase = "round",
            doubleChaos = false,
        }, false, false) > 0).toBe(true)

        expect(RoundEventPresentation.cameraKick("ready", {
            phase = "round",
            doubleChaos = true,
        }, false, false) > RoundEventPresentation.cameraKick("ready", {
            phase = "round",
            doubleChaos = false,
        }, false, false)).toBe(true)

        expect(RoundEventPresentation.cameraKick("round", {
            phase = "round",
            finalRush = true,
        }, false, false) > 0).toBe(true)

        expect(RoundEventPresentation.cameraKick("round", {
            phase = "round",
        }, false, false)).toBe(0)
    end)

    it("dismisses hazard escalation cards before results and on elimination", function()
        local shouldClear = RoundEventPresentation.shouldClearRoundToast
        expect(shouldClear("round", "result", false)).toBe(true)
        expect(shouldClear("round", "intermission", false)).toBe(true)
        expect(shouldClear("round", "ready", false)).toBe(true)
        expect(shouldClear("round", "waiting", false)).toBe(true)
        expect(shouldClear("round", "round", true)).toBe(true)
        expect(shouldClear("round", "round", false)).toBe(false)
        expect(shouldClear("ready", "round", false)).toBe(false)
        expect(shouldClear("result", "ready", false)).toBe(false)
        expect(shouldClear("waiting", "waiting", true)).toBe(false)
        expect(shouldClear("round", "round", nil)).toBe(false)
    end)

    it("retains unchanged FOV targets across repeated countdown packets", function()
        expect(RoundEventPresentation.cameraTargetChanged(nil, 76)).toBe(true)
        expect(RoundEventPresentation.cameraTargetChanged(76, 76)).toBe(false)
        expect(RoundEventPresentation.cameraTargetChanged(76, 76.01)).toBe(false)
        expect(RoundEventPresentation.cameraTargetChanged(76, 79)).toBe(true)
        expect(RoundEventPresentation.cameraTargetChanged(76, nil)).toBe(false)
    end)

    it("cancels late Double Chaos visual pulses after phase or arena changes", function()
        local current = Instance.new("Folder")
        current.Name = "CurrentArena"
        current.Parent = workspace
        local oldBase = Instance.new("Part")
        oldBase.Name = "OldArenaBase"
        oldBase.Parent = current
        local newBase = Instance.new("Part")
        newBase.Name = "NewArenaBase"
        newBase.Parent = current

        local valid = RoundEventPresentation.pulseStillCurrent
        expect(valid(12, 12, oldBase, oldBase)).toBe(true)
        -- Repeated same-phase RoundState packets keep a pending flourish
        -- valid, but any new round/final rush/phase gets a new epoch.
        expect(valid(12, 13, oldBase, oldBase)).toBe(false)
        expect(valid(12, 12, oldBase, newBase)).toBe(false)
        expect(valid(12, 12, nil, oldBase)).toBe(false)
        expect(valid(nil, 12, oldBase, oldBase)).toBe(false)

        oldBase.Parent = nil
        expect(valid(12, 12, oldBase, oldBase)).toBe(false)
        oldBase:Destroy()
        newBase:Destroy()
        current:Destroy()
    end)

    it("keeps final rush above all other transition priorities", function()
        expect(
            RoundEventPresentation.priority("finalRush")
                > RoundEventPresentation.priority("roundStart")
        ).toBe(true)
        expect(
            RoundEventPresentation.priority("roundStart")
                > RoundEventPresentation.priority("fusion")
        ).toBe(true)
        expect(
            RoundEventPresentation.priority("fusion")
                > RoundEventPresentation.priority("overdrive")
        ).toBe(true)
        expect(
            RoundEventPresentation.priority("overdrive")
                > RoundEventPresentation.priority("impactWave")
        ).toBe(true)
        expect(
            RoundEventPresentation.priority("impactWave")
                > RoundEventPresentation.priority("readyCountdown")
        ).toBe(true)
        expect(RoundEventPresentation.priority("collapseWave"))
            .toBe(RoundEventPresentation.priority("impactWave"))
        expect(RoundEventPresentation.priority("speedTempo"))
            .toBe(RoundEventPresentation.priority("impactWave"))
        expect(
            RoundEventPresentation.priority("overdrive")
                > RoundEventPresentation.priority("readyCountdown")
        ).toBe(true)
    end)
end)


describe("Hollow cinematic transition pulse", function()
    it("uses a small, safe number of arcs rather than opaque cylinders", function()
        expect(CinematicPulseRingKit.segmentCount("Low")).toBe(4)
        expect(CinematicPulseRingKit.segmentCount("Medium")).toBe(6)
        expect(CinematicPulseRingKit.segmentCount("High")).toBe(8)
        expect(CinematicPulseRingKit.segmentCount("Unknown")).toBe(0)

        local parent = Instance.new("Folder")
        local frame = CFrame.new(20, 8, -15)
            * CFrame.Angles(math.rad(8), math.rad(32), math.rad(-5))
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local count = CinematicPulseRingKit.segmentCount(tier)
            local parts = CinematicPulseRingKit.emit(
                parent, "VisualArc", frame, Color3.fromRGB(74, 210, 255),
                12, 90, 2, tier, true, 0.60
            )
            expect(#parts).toBe(count)
            for i, piece in ipairs(parts) do
                expect(piece.Name).toBe("VisualArc_Arc" .. i)
                expect(piece:GetAttribute("ChaosTransitionArc")).toBe(true)
                expect(piece.Shape).toBe(Enum.PartType.Block)
                expect(piece.Anchored).toBe(true)
                expect(piece.CanCollide).toBe(false)
                expect(piece.CanTouch).toBe(false)
                expect(piece.CanQuery).toBe(false)
                expect(piece.CastShadow).toBe(false)
                expect(piece.Size.Y < 0.1).toBe(true)
                expect(piece.Size.Z < 0.4).toBe(true)
                expect(piece.Size.X < 90).toBe(true)
                local offset = frame:PointToObjectSpace(piece.Position)
                expect(math.abs(offset.Y) < 0.001).toBe(true)
                expect(math.abs(offset.Magnitude - 45) < 0.01).toBe(true)
                piece:Destroy()
            end
        end
        expect(#parent:GetChildren()).toBe(0)
        parent:Destroy()
    end)

    it("rejects bad settings without any parts", function()
        local parent = Instance.new("Folder")
        local frame = CFrame.new()
        local color = Color3.new(1, 1, 1)
        expect(#CinematicPulseRingKit.emit(nil, "Arc", frame, color, 1, 20, 1, "High", false)).toBe(0)
        expect(#CinematicPulseRingKit.emit(parent, "Arc", nil, color, 1, 20, 1, "High", false)).toBe(0)
        expect(#CinematicPulseRingKit.emit(parent, "Arc", frame, color, 1, 20, 1, "Bad", false)).toBe(0)
        expect(#CinematicPulseRingKit.emit(parent, "Arc", frame, color, 1, -20, 1, "High", false)).toBe(0)
        expect(#CinematicPulseRingKit.emit(parent, "Arc", frame, color, 1, 20, 0, "High", false)).toBe(0)
        expect(#parent:GetChildren()).toBe(0)
        parent:Destroy()
    end)
end)

return nil
