--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local MovementAssistRules = require("../../src/shared/MovementAssistRules")

describe("Movement assist rules", function()
    it("allows a short coyote jump after leaving the floor", function()
        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.05,
            Enum.HumanoidStateType.Freefall,
            true
        )).toBe(true)

        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.15,
            Enum.HumanoidStateType.Freefall,
            true
        )).toBe(false)
    end)

    it("does not turn a normal jump into a double jump", function()
        expect(MovementAssistRules.canCoyoteJump(
            false, 0.04, Enum.HumanoidStateType.Jumping, true
        )).toBe(false)
        -- Jumping may already have transitioned to Freefall inside
        -- the coyote window: the first jump must consume its allowance.
        expect(MovementAssistRules.canCoyoteJump(
            false, 0.04, Enum.HumanoidStateType.Freefall, true, true
        )).toBe(false)
        expect(MovementAssistRules.canCoyoteJump(
            false, 0.04, Enum.HumanoidStateType.Freefall, true, false
        )).toBe(true)
    end)

    it("never adds a second jump while already grounded", function()
        expect(MovementAssistRules.canCoyoteJump(
            true,
            0,
            Enum.HumanoidStateType.Running,
            true
        )).toBe(false)
    end)

    it("respects disabled or blocked jump states", function()
        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.04,
            Enum.HumanoidStateType.Seated,
            true
        )).toBe(false)

        expect(MovementAssistRules.canCoyoteJump(
            false,
            0.04,
            Enum.HumanoidStateType.Freefall,
            false
        )).toBe(false)
    end)

    it("respects the active Roblox jump mode and Freeze Pulse disable", function()
        local enabled = MovementAssistRules.jumpEnabled
        expect(enabled(100, true, 50, 0, true)).toBe(true)
        expect(enabled(100, false, 0, 7.2, true)).toBe(true)
        -- The inactive control can remain at its previous nonzero default.
        expect(enabled(100, true, 0, 7.2, true)).toBe(false)
        expect(enabled(100, false, 50, 0, true)).toBe(false)
        expect(enabled(100, true, 50, 7.2, false)).toBe(false)
        expect(enabled(0, true, 50, 7.2, true)).toBe(false)
        expect(enabled(100, true, math.huge, 7.2, true)).toBe(false)
        expect(enabled(100, false, 50, 0 / 0, true)).toBe(false)
    end)

    it("keeps the buffered jump window short and deterministic", function()
        local expires = MovementAssistRules.bufferUntil(10)
        expect(math.abs(expires - 10.12) < 0.001).toBe(true)
        expect(MovementAssistRules.bufferActive(10.08, expires)).toBe(true)
        expect(MovementAssistRules.bufferActive(10.13, expires)).toBe(false)
    end)
    it("predicts only near-term descending contact and validates edges", function()
        local Rules = require("../../src/shared/JumpLandingPreviewRules")
        local freefall = Enum.HumanoidStateType.Freefall
        local eligible = Rules.eligible
        expect(eligible("round", true, false, 100, freefall, false, -14)).toBe(true)
        expect(eligible("ready", true, false, 100, freefall, false, -14)).toBe(false)
        expect(eligible("round", false, false, 100, freefall, false, -14)).toBe(false)
        expect(eligible("round", true, true, 100, freefall, false, -14)).toBe(false)
        expect(eligible("round", true, false, 0, freefall, false, -14)).toBe(false)
        expect(eligible("round", true, false, 100, freefall, true, -14)).toBe(false)
        expect(eligible("round", true, false, 100, freefall, false, 8)).toBe(false)
        expect(eligible("round", true, false, 100, freefall, false, -14)).toBe(true)

        local time = Rules.timeToSurface(-20, 196.2, 3)
        expect(time ~= nil and time > 0 and time < 0.42).toBe(true)
        expect(Rules.timeToSurface(8, 196.2, 3)).toBe(nil)
        expect(Rules.timeToSurface(-10, 0, 3)).toBe(nil)
        expect(Rules.timeToSurface(-10, 196.2, 20)).toBe(nil)
        expect(Rules.timeToSurface(-4, 20, 13)).toBe(nil)
        expect(Rules.timeToSurface(-20, 196.2, -1)).toBe(nil)
        expect(Rules.timeToSurface(0 / 0, 196.2, 3)).toBe(nil)

        -- The old straight-down-only ray could not preview a valid higher
        -- destination whenever the avatar passed over empty lower ground.
        -- Near/mid/late projections accept a physically timed target but
        -- reject a distant floor or an inconsistent contact instant.
        expect(#Rules.ProbeSeconds).toBe(3)
        expect(Rules.probeMatches(0.08, 0.07)).toBe(true)
        expect(Rules.probeMatches(0.23, 0.20)).toBe(true)
        expect(Rules.probeMatches(0.36, 0.40)).toBe(true)
        expect(Rules.probeMatches(0.08, 0.35)).toBe(false)
        expect(Rules.probeMatches(0.23, 0.42)).toBe(false)
        expect(Rules.probeMatches(0.08, nil)).toBe(false)
        expect(Rules.probeMatches(0 / 0, 0.10)).toBe(false)
        expect(Rules.probeMatches(-0.1, 0.08)).toBe(false)
        expect(Rules.probeMatches(0.36, 0.50)).toBe(false)

        -- A 20 studs/s forward jump: beneath the avatar lies base ground
        -- too low to be the imminent landing, but at t=0.23 the horizontal
        -- projection reaches an elevated, valid 7-stud deck. No physics
        -- buff is necessary; the visual can now select the real target.
        local surfaceTime = Rules.timeToSurface(-10, 196.2, 6)
        expect(surfaceTime ~= nil).toBe(true)
        expect(Rules.probeMatches(0.23, surfaceTime)).toBe(true)
        expect(math.abs(20 * surfaceTime - 4.0) < 0.5).toBe(true)
        local baseTime = Rules.timeToSurface(-10, 196.2, 13)
        expect(Rules.probeMatches(0.08, baseTime)).toBe(false)
        -- Even when the lower base has the smaller timestamp error,
        -- the closer elevated platform is the first physical contact.
        local lowerError = math.abs(0.36 - baseTime)
        expect(Rules.preferContact(0.36, baseTime, nil, math.huge)).toBe(true)
        expect(Rules.preferContact(
            0.08, surfaceTime, baseTime, lowerError
        )).toBe(true)
        expect(Rules.preferContact(
            0.36, baseTime, surfaceTime, 0.12
        )).toBe(false)
        expect(Rules.preferContact(0.08, nil, nil, 0)).toBe(false)
        expect(Rules.preferContact(-1, 0.08, nil, 0)).toBe(false)

        local deck = Instance.new("Part")
        deck.Size = Vector3.new(10, 2, 10)
        deck.CFrame = CFrame.new(9, 4, -7) * CFrame.Angles(0, math.rad(35), 0)
        local middle = deck.CFrame.Position
        expect(math.abs(Rules.edgeMargin(deck, middle) - 5) < 0.001).toBe(true)
        local nearEdge = deck.CFrame:PointToWorldSpace(Vector3.new(4.6, 0, 0))
        expect(Rules.edgeMargin(deck, nearEdge) < 1.75).toBe(true)
        expect(Rules.edgeMargin(deck, nil)).toBe(nil)
        deck:Destroy()
    end)
end)

return nil
