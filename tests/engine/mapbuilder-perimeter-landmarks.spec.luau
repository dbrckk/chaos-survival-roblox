--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local DisappearingPlatforms = require("../../src/server/Disasters/DisappearingPlatforms")
local SkyRouteMonuments = require("../../src/server/SkyRouteMonuments")
local VisualTheme = require("../../src/shared/VisualTheme")

describe("Perimeter escape landmarks", function()
    it("builds twelve monumental, nonblocking 3D escape landmarks on actual decks in all five worlds", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local root = MapBuilder.build(Config, id, ArenaVariants, VisualTheme)
            local arena = root:FindFirstChild("Arena")
            local decks = arena:FindFirstChild("Platforms")
            local decor = arena:FindFirstChild("Decor")
            local totalMonuments = 0
            for route = 1, 4 do
                for _, step in ipairs({1, 4, 8}) do
                    local index = #variant.Platforms
                        + (route - 1) * ArenaVariants.PerimeterSteps + step
                    local deck = decks:FindFirstChild("Platform" .. index)
                    expect(deck ~= nil and deck:IsA("BasePart")).toBe(true)
                    expect(deck.CanCollide and deck.Anchored).toBe(true)
                    expect(deck:GetAttribute("PerimeterRoute")).toBe(route)
                    expect(deck:GetAttribute("PerimeterStep")).toBe(step)
                    local stage = SkyRouteMonuments.Steps[step]
                    local count, arrows = 0, 0
                    local components = {}
                    for _, piece in ipairs(decor:GetChildren()) do
                        if piece:GetAttribute("SkyRouteMonument") == true
                            and piece:GetAttribute("PerimeterPlatformIndex")
                                == index then
                            count += 1
                            components[#components + 1] = piece
                            expect(piece:IsA("BasePart")).toBe(true)
                            expect(piece.Anchored).toBe(true)
                            expect(piece.CanCollide).toBe(false)
                            expect(piece.CanTouch).toBe(false)
                            expect(piece.CanQuery).toBe(false)
                            expect(piece.CastShadow).toBe(false)
                            expect(piece:GetAttribute("SkyRouteStage"))
                                .toBe(stage)
                            if piece:GetAttribute("SurvivalRouteArrow") == true then
                                arrows += 1
                                expect(piece:GetAttribute("ChaosWayfinding"))
                                    .toBe(true)
                                local localPos = deck.CFrame:PointToObjectSpace(
                                    piece.Position)
                                expect(localPos.Y > deck.Size.Y * 0.5).toBe(true)
                            end
                        end
                    end
                    expect(count >= 12).toBe(true)
                    expect(count <= SkyRouteMonuments.MaxPartsPerMonument)
                        .toBe(true)
                    expect(arrows).toBe(step == 8 and 0 or 2)
                    totalMonuments += 1

                    -- Real walking footprint is completely free: the two
                    -- towering pillars are OUTSIDE the Z edge and the
                    -- overhead giant arch stays above normal R15 jumps.
                    for _, side in ipairs({-1, 1}) do
                        local column = decor:FindFirstChild(
                            "SkyRouteMonument" .. index
                                .. "_VerticalBridgePylon" .. side)
                        expect(column ~= nil and column:IsA("BasePart"))
                            .toBe(true)
                        local localPos = deck.CFrame:PointToObjectSpace(
                            column.Position)
                        expect(math.abs(localPos.Z)
                            > deck.Size.Z * 0.5 + 0.5).toBe(true)
                    end
                    local arch = decor:FindFirstChild(
                        "SkyRouteMonument" .. index
                            .. "_MonumentalOverpass")
                    expect(arch ~= nil and arch:IsA("BasePart")).toBe(true)
                    local beamBottom =
                        deck.CFrame:PointToObjectSpace(arch.Position).Y
                        - arch.Size.Y * 0.5
                    for _, side in ipairs({-1, 1}) do
                        local column = decor:FindFirstChild(
                            "SkyRouteMonument" .. index
                                .. "_VerticalBridgePylon" .. side)
                        local topOfColumn = deck.CFrame:PointToObjectSpace(
                            column.Position).Y + column.Size.Y * 0.5
                        -- Every stage's load pylons MUST touch its beam,
                        -- including taller late-stage summit structures.
                        expect(topOfColumn - beamBottom >= 0.15).toBe(true)
                        expect(topOfColumn - beamBottom <= 0.80).toBe(true)
                    end
                    local beacon = decor:FindFirstChild(
                        "SkyRouteMonument" .. index
                            .. "_RouteStageBeacon")
                    expect(beacon ~= nil).toBe(true)
                    local beaconTop = deck.CFrame:PointToObjectSpace(
                        beacon.Position).Y + beacon.Size.Y * 0.5
                    expect(beaconTop >= beamBottom).toBe(true)
                    expect(beaconTop - beamBottom < 0.5).toBe(true)
                    expect(deck.CFrame:PointToObjectSpace(
                        arch.Position).Y >= deck.Size.Y * 0.5 + 11)
                        .toBe(true)
                    if step == 8 then
                        -- Unlike permanent starter routes, a hard summit
                        -- can disappear. Its WHOLE architectural structure
                        -- must vanish with its physical collider, not
                        -- float as an inviting false rescue route.
                        local cosmetics =
                            DisappearingPlatforms.cosmeticsForPlatform(
                                decor, deck)
                        local linked = 0
                        for _, entry in ipairs(cosmetics) do
                            if entry.part:GetAttribute(
                                    "SkyRouteMonument") == true then
                                linked += 1
                            end
                        end
                        expect(linked).toBe(count)
                        DisappearingPlatforms.setCosmeticsPhase(
                            cosmetics, "Gone")
                        for _, piece in ipairs(components) do
                            expect(piece.Transparency).toBe(1)
                        end
                        DisappearingPlatforms.setCosmeticsPhase(
                            cosmetics, "Ready")
                    end
                end
            end
            expect(totalMonuments).toBe(12)
            -- Do not add a decorative "platform" to the real physics
            -- folder. Only the older authoritative deck count is legal.
            expect(#decks:GetChildren()).toBe(
                #variant.Platforms + #variant.PerimeterPlatforms
                + #variant.BranchPlatforms + #variant.CrosslinkPlatforms
                + #(variant.SkywayPlatforms or {})
                + #(variant.SpokePlatforms or {})
                + #variant.PromenadePlatforms + #variant.SkySpinePlatforms
            )
            root:Destroy()
        end
    end)
end)

return nil
