--!strict
-- Physical Roblox Instance contract for AI cooperation in the shared
-- 23-gap sky network. No synthetic path, fake bot or forced Humanoid floor.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local SkySpineSwitchyard = require("../../src/server/SkySpineSwitchyard")

describe("Sky network cooperative bot approach — real deck geometry", function()
    for _, id in ipairs(ArenaVariants.Order) do
        it("accepts only current solid command decks in " .. id, function()
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
            local controls = arena:FindFirstChild("SkySpineSwitchyard")
            expect(controls:GetAttribute("SkyNetworkGapCount")).toBe(23)
            for _, command in ipairs({
                "SkySpineCommand3", "SkySpineCommand8",
                "SkySpineCommandNorth", "SkySpineCommandSouth",
            }) do
                local model = controls:FindFirstChild(command)
                expect(model ~= nil).toBe(true)
                local core = model:FindFirstChild("CommandCore")
                expect(core ~= nil and core:IsA("BasePart")).toBe(true)

                local actualDeck
                for _, part in ipairs(platforms:GetChildren()) do
                    if part:IsA("BasePart") then
                        local y = part.Position.Y + part.Size.Y * 0.5
                        local delta = Vector3.new(
                            core.Position.X - part.Position.X, 0,
                            core.Position.Z - part.Position.Z
                        )
                        if delta.Magnitude < 0.01
                            and math.abs(core.Position.Y - y - 3.1) < 0.01 then
                            actualDeck = part
                            break
                        end
                    end
                end
                expect(actualDeck ~= nil).toBe(true)
                expect(actualDeck:GetAttribute("ChaosPermanentRoute")).toBe(true)
                local top = actualDeck.Position.Y + actualDeck.Size.Y * 0.5
                local standing = Vector3.new(
                    core.Position.X, top + 2.6, core.Position.Z)
                local target = SkySpineSwitchyard.sameDeckApproach(
                    standing, actualDeck)
                expect(typeof(target)).toBe("Vector3")
                expect(target).toBe(standing)

                -- Same elevation on another route is not enough. The
                -- foot position must really overlap the exact deck.
                expect(SkySpineSwitchyard.sameDeckApproach(
                    standing + Vector3.new(actualDeck.Size.X, 0, 0),
                    actualDeck)).toBe(nil)
                expect(SkySpineSwitchyard.sameDeckApproach(
                    standing + Vector3.new(0, 8, 0),
                    actualDeck)).toBe(nil)
                expect(SkySpineSwitchyard.sameDeckApproach(
                    standing, arena:FindFirstChild("Base"))).toBe(nil)

                actualDeck:SetAttribute("CollapsePhase", "Warning")
                expect(SkySpineSwitchyard.sameDeckApproach(
                    standing, actualDeck)).toBe(nil)
                actualDeck:SetAttribute("CollapsePhase", nil)
                actualDeck.CanCollide = false
                expect(SkySpineSwitchyard.sameDeckApproach(
                    standing, actualDeck)).toBe(nil)
                actualDeck.CanCollide = true
                expect(SkySpineSwitchyard.sameDeckApproach(
                    standing, actualDeck)).toBe(standing)
            end

            -- No fake bot, no remote actor or ungrounded proximity may
            -- produce a command claim or a forced network activation.
            expect(SkySpineSwitchyard.botApproach(nil, os.clock()))
                .toBe(nil)
            expect(SkySpineSwitchyard.botOpportunity(nil, os.clock()))
                .toBe(nil)
            expect(SkySpineSwitchyard.activateBot(nil, nil))
                .toBe(false)
            expect(controls:GetAttribute("SkyNetworkConnected")).toBe(false)
            for _, cleanup in ipairs(ctx.OnCleanup) do cleanup() end
            for _, item in ipairs(ctx.Cleanup) do
                if item and item.Parent then item:Destroy() end
            end
            root:Destroy()
        end)
    end
end)

return nil
