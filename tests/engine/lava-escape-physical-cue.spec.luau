--!strict
-- Emergency Android coaching must refer only to genuinely live server
-- climb entries; no invented route to a high platform while lava rises.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local JumpRouteCueRules = require("../../src/shared/JumpRouteCueRules")

describe("Lava escape: find a genuine dry entry for new and veteran players", function()
    for _, id in ipairs(ArenaVariants.Order) do
        it("never advertises vanished, submerged or unreachable decks: " .. id,
            function()
                local root = MapBuilder.build(Config, id, ArenaVariants)
                local arena = root:FindFirstChild("Arena")
                local platforms = arena:FindFirstChild("Platforms")
                local base = arena:FindFirstChild("Base")
                local floor = base.Position
                    + Vector3.new(0, base.Size.Y * 0.5, 0)
                local decks = platforms:GetChildren()

                -- The full 320-stud arena still contains a genuine
                -- nearby, climbable route — not a fake goal in midair.
                local first = JumpRouteCueRules.nearestLavaClimbEntry(
                    decks, floor, nil, 106)
                expect(first ~= nil).toBe(true)
                expect(first:IsA("BasePart")).toBe(true)
                expect(first.CanCollide and first.Anchored).toBe(true)
                expect(first:GetAttribute("RouteTier")).toBe(1)
                expect(first.Parent).toBe(platforms)
                local top = first.Position.Y + first.Size.Y * 0.5
                expect(top - floor.Y >= 1.5 and top - floor.Y <= 5.2)
                    .toBe(true)

                -- A distant goal outside the strict range is never
                -- made reachable by increasing UI Billboard distance.
                expect(JumpRouteCueRules.nearestLavaClimbEntry(
                    decks, floor, nil, 0)).toBe(nil)

                -- Real server collapse metadata disqualifies the old
                -- takeoff immediately; the next safe one is acceptable.
                first:SetAttribute("CollapsePhase", "Warning")
                local alternate = JumpRouteCueRules.nearestLavaClimbEntry(
                    decks, floor, nil, 106)
                expect(alternate ~= first).toBe(true)
                first:SetAttribute("CollapsePhase", nil)

                local lava = Instance.new("Part")
                lava.Name = "RoundLava"
                lava.Size = Vector3.new(400, 4, 400)
                lava.Position = Vector3.new(
                    base.Position.X, top + 2, base.Position.Z)
                lava.Anchored = true
                lava.CanCollide = false
                lava.Parent = workspace
                expect(JumpRouteCueRules.lavaOnDeck(first, lava))
                    .toBe(true)
                local escape = JumpRouteCueRules.nearestLavaClimbEntry(
                    decks, floor, lava, 106)
                expect(escape ~= first).toBe(true)

                lava:Destroy()
                expect(JumpRouteCueRules.nearestLavaClimbEntry(
                    decks, floor, nil, 106)).toBe(first)
                expect(JumpRouteCueRules.nearestLavaClimbEntry(
                    {}, floor, nil, 106)).toBe(nil)
                expect(JumpRouteCueRules.nearestLavaClimbEntry(
                    decks, nil, nil, 106)).toBe(nil)
                root:Destroy()
            end)
    end
end)

return nil
