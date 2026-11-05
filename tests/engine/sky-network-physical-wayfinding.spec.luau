--!strict
-- Roblox-engine route contract. No mocked destination coordinates:
-- every target is a live, server-built collidable PlatformN in one map.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local JumpRouteCueRules = require("../../src/shared/JumpRouteCueRules")

describe("H-shaped five-world physical sky route wayfinding", function()
    for _, variantId in ipairs(ArenaVariants.Order) do
        it("guides both crossings and safe detours in " .. variantId, function()
            local root = MapBuilder.build(Config, variantId, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local all = platforms:GetChildren()
            local function find(kind, number, stepKind, step)
                for _, deck in ipairs(all) do
                    if deck:IsA("BasePart")
                        and deck:GetAttribute(kind) == number
                        and deck:GetAttribute(stepKind) == step then
                        return deck
                    end
                end
                return nil
            end
            local function nextFrom(part, direction)
                return JumpRouteCueRules.nextPhysical(
                    part, all, Config.ArenaCenter, variantId, direction)
            end

            for lane = 1, 2 do
                local westRoute = lane == 1 and 1 or 3
                local eastRoute = westRoute + 1
                local left = find("BranchRoute", westRoute, "BranchStep", 4)
                local right = find("BranchRoute", eastRoute, "BranchStep", 4)
                local first = find("PromenadeLane", lane, "PromenadeStep", 1)
                local last = find("PromenadeLane", lane, "PromenadeStep", 8)
                local center = find("PromenadeLane", lane, "PromenadeStep", 4)
                local other = find("PromenadeLane", lane, "PromenadeStep", 5)
                local spineStep = lane == 1 and 1 or 10
                local spine = find("SkySpineInterchange", true,
                    "SkySpineStep", spineStep)
                expect(left ~= nil and right ~= nil).toBe(true)
                expect(first ~= nil and last ~= nil).toBe(true)
                expect(center ~= nil and other ~= nil and spine ~= nil)
                    .toBe(true)
                expect(JumpRouteCueRules.skyNetworkLink(left, first))
                    .toBe(true)
                expect(JumpRouteCueRules.skyNetworkLink(right, last))
                    .toBe(true)
                expect(nextFrom(left)).toBe(first)
                expect(nextFrom(right)).toBe(last)
                expect(nextFrom(first, -1)).toBe(left)
                expect(nextFrom(last, 1)).toBe(right)

                for step = 1, 7 do
                    local a = find("PromenadeLane", lane, "PromenadeStep", step)
                    local b = find("PromenadeLane", lane, "PromenadeStep", step + 1)
                    expect(JumpRouteCueRules.skyNetworkLink(a, b)).toBe(true)
                    expect(nextFrom(a, 1)).toBe(b)
                    expect(nextFrom(b, -1)).toBe(a)
                    expect(a.CanCollide and b.CanCollide).toBe(true)
                end
                local progress, interchange =
                    JumpRouteCueRules.skyNetworkOptions(center, all, 1)
                expect(progress).toBe(other)
                expect(interchange).toBe(spine)
                expect(JumpRouteCueRules.skyNetworkLink(center, spine))
                    .toBe(true)

                -- No fake SAFE jump into a warning/collapsed promenade:
                -- the transverse spine remains a real alternate path.
                other:SetAttribute("CollapsePhase", "Warning")
                expect(nextFrom(center, 1)).toBe(spine)
                spine:SetAttribute("CollapsePhase", "Warning")
                expect(nextFrom(center, 1)).toBe(nil)
                other:SetAttribute("CollapsePhase", nil)
                spine:SetAttribute("CollapsePhase", nil)
                expect(nextFrom(center, 1)).toBe(other)

                -- A streamed-out link is NOT replaced by an invented
                -- physical platform with only a plausible coordinate.
                first.CanCollide = false
                expect(nextFrom(left)).toBe(nil)
                first.CanCollide = true
                expect(nextFrom(left)).toBe(first)
            end

            for step = 1, 9 do
                local a = find("SkySpineInterchange", true, "SkySpineStep", step)
                local b = find("SkySpineInterchange", true, "SkySpineStep", step + 1)
                expect(JumpRouteCueRules.skyNetworkLink(a, b)).toBe(true)
                expect(nextFrom(a, 1)).toBe(b)
                expect(nextFrom(b, -1)).toBe(a)
            end
            local north = find("SkySpineInterchange", true, "SkySpineStep", 1)
            local south = find("SkySpineInterchange", true, "SkySpineStep", 10)
            local northProm = find("PromenadeLane", 1, "PromenadeStep", 4)
            local southProm = find("PromenadeLane", 2, "PromenadeStep", 4)
            expect(nextFrom(north, -1)).toBe(northProm)
            expect(nextFrom(south, 1)).toBe(southProm)

            -- No cross-world/non-playable surface may receive a direction.
            expect(JumpRouteCueRules.skyNetworkOptions(
                arena:FindFirstChild("Base"), all, 1)).toBe(nil)
            root:Destroy()
        end)
    end
end)

return nil
