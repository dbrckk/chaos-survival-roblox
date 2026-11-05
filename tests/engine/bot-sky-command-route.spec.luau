--!strict
-- Sky-network bot approach has a complete physical route from every
-- branch lookout to a real cooperative console, in each authored arena.
-- Uses MapBuilder colliders, not invented waypoints or fake AI motion.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local AISurvivorRules = require("../../src/server/AISurvivorRules")
local JumpRouteCueRules = require("../../src/shared/JumpRouteCueRules")
local SkySpineSwitchyard = require("../../src/server/SkySpineSwitchyard")

describe("Bot cooperative route: climb, real sky jumps, hold", function()
    for _, id in ipairs(ArenaVariants.Order) do
        it("connects four real lookout routes to two consoles in " .. id, function()
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local ctx = {
                Active = function() return true end,
                IsContestantActive = function() return true end,
                Cleanup = {}, OnCleanup = {}, RoundSeconds = 65,
                ActiveDisasters = {},
            }
            expect(SkySpineSwitchyard.start(ctx)).toBe(9)
            local station = arena:FindFirstChild("SkySpineSwitchyard")
            expect(station:GetAttribute("SkyNetworkConnected")).toBe(false)

            local function find(routeName, routeNumber, stepName, step)
                for _, deck in ipairs(platforms:GetChildren()) do
                    if deck:IsA("BasePart")
                        and deck:GetAttribute(routeName) == routeNumber
                        and deck:GetAttribute(stepName) == step then
                        return deck
                    end
                end
                return nil
            end
            for route = 1, 4 do
                local origin = find(
                    "BranchRoute", route, "BranchStep", 4)
                expect(origin ~= nil).toBe(true)
                local lane = route <= 2 and 1 or 2
                local direction = route % 2 == 1 and 1 or -1
                local entry = direction == 1 and 1 or 8
                local previous, traversed = origin, 0
                for step = entry, 4, direction do
                    local deck = find(
                        "PromenadeLane", lane, "PromenadeStep", step)
                    expect(deck ~= nil).toBe(true)
                    expect(deck.CanCollide and deck.Anchored).toBe(true)
                    expect(AISurvivorRules.neighboringPhysicalDeck(
                        previous.CFrame, previous.Size,
                        deck.CFrame, deck.Size
                    )).toBe(true)
                    expect(JumpRouteCueRules.skyNetworkLink(
                        previous, deck)).toBe(true)
                    if previous:GetAttribute("PromenadeLane") ~= nil then
                        local first = direction == 1 and previous or deck
                        local second = direction == 1 and deck or previous
                        local center, size =
                            SkySpineSwitchyard.promenadeGapBetween(
                                first, second)
                        expect(typeof(center)).toBe("Vector3")
                        expect(math.abs(size.X - 3.2) < 0.02).toBe(true)
                    end
                    traversed += 1
                    previous = deck
                end
                expect(traversed).toBe(direction == 1 and 4 or 5)
                expect(previous:GetAttribute("PromenadeStep")).toBe(4)
                -- The last actual deck is the SAME deck hosting the
                -- already-shared co-op console — no phantom final leap.
                local console = station:FindFirstChild(
                    lane == 1 and "SkySpineCommandNorth"
                        or "SkySpineCommandSouth")
                local core = console:FindFirstChild("CommandCore")
                local stand = previous.Position
                    + Vector3.new(0, previous.Size.Y * 0.5 + 2.6, 0)
                expect((core.Position.X - stand.X)).toBe(0)
                expect((core.Position.Z - stand.Z)).toBe(0)
                expect(SkySpineSwitchyard.sameDeckApproach(
                    stand, previous)).toBe(stand)
            end
            for _, cleanup in ipairs(ctx.OnCleanup) do cleanup() end
            for _, item in ipairs(ctx.Cleanup) do
                if item and item.Parent then item:Destroy() end
            end
            root:Destroy()
        end)
    end
end)

return nil
