--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local MovementSafety = require("../../src/server/MovementSafety")
local PhaseDashRules = require("../../src/shared/PhaseDashRules")
local DashVisualRules = require("../../src/client/PhaseDashVisualRules")
local DashObserverRegistry = require("../../src/client/PhaseDashObserverRegistry")

describe("Movement safety", function()
    it("gives every active survivor one free bounded Phase Dash", function()
        local rules = PhaseDashRules
        expect(rules.canActivate("round", true, false, 100, true, 10, 9)).toBe(true)
        expect(rules.canActivate("round", true, false, 100, true, 10, 10)).toBe(true)
        expect(rules.canActivate("round", true, false, 100, true, 10, 11)).toBe(false)
        expect(rules.canActivate("ready", true, false, 100, true, 10, 0)).toBe(false)
        expect(rules.canActivate("result", true, false, 100, true, 10, 0)).toBe(false)
        expect(rules.canActivate("round", false, false, 100, true, 10, 0)).toBe(false)
        expect(rules.canActivate("round", true, true, 100, true, 10, 0)).toBe(false)
        expect(rules.canActivate("round", true, false, 0, true, 10, 0)).toBe(false)
        expect(rules.canActivate("round", true, false, 100, false, 10, 0)).toBe(false)
        expect(rules.nextReadyAt(10)).toBe(10 + rules.Cooldown)
        expect(rules.Cooldown >= 7).toBe(true)
    end)

    it("authors directional shockwave facets inside unchanged Android part caps", function()
        local art = DashVisualRules
        expect(art.count("High")).toBe(10)
        expect(art.count("Medium")).toBe(7)
        expect(art.count("Low")).toBe(5)
        expect(art.count("Unknown")).toBe(0)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local count = art.count(tier)
            local first = art.facet(tier, 1, false)
            expect(first ~= nil and first.Count == count).toBe(true)
            local differing = false
            for i = 1, count do
                local design = art.facet(tier, i, false)
                local repeatDesign = art.facet(tier, i, false)
                expect(design.Angle).toBe(repeatDesign.Angle)
                expect(design.EndScale).toBe(repeatDesign.EndScale)
                expect(design.Bank).toBe(repeatDesign.Bank)
                expect(design.StartScale >= 1 and design.StartScale <= 1.04)
                    .toBe(true)
                expect(design.EndScale >= 0.88 and design.EndScale <= 1.20)
                    .toBe(true)
                expect(design.ChordScale > 0.75 and design.ChordScale <= 0.96)
                    .toBe(true)
                expect(math.abs(design.Bank) <= math.rad(13)).toBe(true)
                if design.EndScale ~= first.EndScale then differing = true end
            end
            expect(differing).toBe(true)
        end
        expect(art.facet("Unknown", 1, false) == nil).toBe(true)
        expect(art.facet("Low", 6, false) == nil).toBe(true)
        expect(art.facet("High", 1.5, false) == nil).toBe(true)
        expect(art.facet("High", 0/0, false) == nil).toBe(true)
        expect(art.facet("High", math.huge, false) == nil).toBe(true)
        local primary = art.facet("High", 2, false)
        local accent = art.facet("High", 2, true)
        expect(primary.Thickness > accent.Thickness).toBe(true)
        expect(primary.ChordScale > accent.ChordScale).toBe(true)
        expect(primary.Bank ~= accent.Bank).toBe(true)
    end)

    it("disconnects remote avatar pulse listeners on respawn and departure", function()
        local added = Instance.new("BindableEvent")
        local removing = Instance.new("BindableEvent")
        local first = Instance.new("Model")
        local second = Instance.new("Model")
        local fakePlayer = {
            Character = first,
            CharacterAdded = added.Event,
            CharacterRemoving = removing.Event,
        }
        local fired = 0
        local observers = DashObserverRegistry.new(function()
            fired += 1
        end)
        expect(observers.watch(fakePlayer)).toBe(true)
        expect(observers.watch(fakePlayer)).toBe(false)
        expect(observers.count()).toBe(1)
        first:SetAttribute("PhaseDashPulse", 1)
        expect(fired).toBe(1)
        fakePlayer.Character = second
        added:Fire(second)
        task.wait() -- covers deferred RBXScriptSignal delivery in engine shards
        first:SetAttribute("PhaseDashPulse", 2)
        expect(fired).toBe(1)
        second:SetAttribute("PhaseDashPulse", 1)
        expect(fired).toBe(2)
        removing:Fire(second)
        task.wait()
        second:SetAttribute("PhaseDashPulse", 2)
        expect(fired).toBe(2)
        expect(observers.stop(fakePlayer)).toBe(true)
        expect(observers.stop(fakePlayer)).toBe(false)
        expect(observers.count()).toBe(0)
        fakePlayer.Character = first
        added:Fire(first)
        task.wait()
        first:SetAttribute("PhaseDashPulse", 3)
        expect(fired).toBe(2)
        first:Destroy()
        second:Destroy()
        added:Destroy()
        removing:Destroy()
    end)

    it("rejects nonfinite dash headings, physics and cooldown attributes", function()
        local r = PhaseDashRules
        local badNumbers = {0/0, math.huge, -math.huge}
        local expected = Vector3.new(0, 0, -1)
        for _, bad in ipairs(badNumbers) do
            local heading = r.direction(Vector3.new(bad, 0, 1),
                Vector3.new(bad, 0, bad))
            expect(heading).toBe(expected)
            local faceOnly = r.direction(Vector3.zero,
                Vector3.new(0, 0, bad))
            expect(faceOnly).toBe(expected)
            local result = r.velocity(Vector3.new(bad, 1, 5),
                Vector3.new(bad, 0, 0), Vector3.new(0, 0, -1))
            expect(Vector3.new(result.X, 0, result.Z).Magnitude
                <= r.MaxHorizontalSpeed).toBe(true)
            expect(result.X == result.X and result.Y == result.Y
                and result.Z == result.Z).toBe(true)
            expect(result.Y >= -52 and result.Y <= 48).toBe(true)
            expect(r.canActivate("round", true, false, 100, true,
                bad, 0)).toBe(false)
            expect(r.canActivate("round", true, false, bad, true,
                10, 0)).toBe(false)
            expect(r.canActivate("round", true, false, 100, true,
                10, bad)).toBe(false)
            expect(r.remaining(bad, 100)).toBe(0)
            expect(r.remaining(100, bad)).toBe(0)
            expect(r.nextReadyAt(bad)).toBe(r.Cooldown)
        end
        expect(r.direction(Vector3.new(1e8, 0, 0),
            Vector3.new(1, 0, 0))).toBe(Vector3.new(1, 0, 0))
        expect(r.direction(Vector3.new(1e8, 0, 0),
            Vector3.new(1e8, 0, 0))).toBe(expected)
        expect(r.remaining(120, 111)).toBe(9)
        expect(r.remaining(100, 111)).toBe(0)
        expect(r.remaining(nil, 111)).toBe(0)
    end)

    it("limits Phase Dash movement and never trusts arbitrary client vectors", function()
        local rules = PhaseDashRules
        local direction = rules.direction(
            Vector3.new(2, 5, 0), Vector3.new(0, 0, -1)
        )
        expect(math.abs(direction.Magnitude - 1) < 0.001).toBe(true)
        expect(direction.Y).toBe(0)

        local idle = rules.direction(Vector3.zero, Vector3.new(1, 0, 0))
        expect(idle).toBe(Vector3.new(1, 0, 0))

        for _, initial in ipairs({
            Vector3.zero,
            Vector3.new(85, 120, 85),
            Vector3.new(-95, -180, 20),
        }) do
            local result = rules.velocity(initial, Vector3.new(5, 0, -2), Vector3.zero)
            expect(Vector3.new(result.X, 0, result.Z).Magnitude
                <= rules.MaxHorizontalSpeed + 0.001).toBe(true)
            expect(result.Y >= -52 and result.Y <= 48).toBe(true)
        end

        local boosted = rules.velocity(Vector3.zero, Vector3.new(1, 0, 0), nil)
        expect(boosted.X > 25).toBe(true)
        expect(boosted.Y >= 2).toBe(true)
    end)

    it("bounds horizontal disaster velocity", function()
        local velocity = MovementSafety.addImpulse(
            Vector3.new(90, 0, -90),
            Vector3.new(30, 0, 30),
            62,
            -55,
            58
        )

        local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
        expect(horizontal.Magnitude <= 62.001).toBe(true)
    end)

    it("bounds vertical disaster velocity in both directions", function()
        local upward = MovementSafety.addImpulse(
            Vector3.new(0, 55, 0),
            Vector3.new(0, 30, 0),
            62,
            -55,
            58
        )
        expect(upward.Y).toBe(58)

        local downward = MovementSafety.addImpulse(
            Vector3.new(0, -50, 0),
            Vector3.new(0, -30, 0),
            62,
            -55,
            58
        )
        expect(downward.Y).toBe(-55)
    end)

    it("handles inverted vertical bounds defensively", function()
        local velocity = MovementSafety.clampVelocity(
            Vector3.new(0, 100, 0),
            62,
            58,
            -55
        )
        expect(velocity.Y).toBe(58)
    end)
end)

return nil
