--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local DisappearingPlatforms = require("../../src/server/Disasters/DisappearingPlatforms")

describe("Chaos Survival engine", function()
    it("builds a complete playable map hierarchy", function()
        local existing = workspace:FindFirstChild("GeneratedMap")
        if existing then
            existing:Destroy()
        end

        local root = MapBuilder.build(Config, "Classic", ArenaVariants)

        expect(root ~= nil).toBe(true)
        expect(root.Parent == workspace).toBe(true)
        expect(root:FindFirstChild("Lobby") ~= nil).toBe(true)
        expect(root:FindFirstChild("Arena") ~= nil).toBe(true)

        local lobby = root:FindFirstChild("Lobby")
        local lobbyDecor = lobby and lobby:FindFirstChild("Decor")
        expect(lobbyDecor ~= nil).toBe(true)
        expect((lobbyDecor :: Folder):FindFirstChild("CenterPlatform") ~= nil).toBe(true)
        expect((lobbyDecor :: Folder):FindFirstChild("CenterGlow") ~= nil).toBe(true)
        expect((lobbyDecor :: Folder):FindFirstChild("ArenaGateTop") ~= nil).toBe(true)
        expect((lobbyDecor :: Folder):FindFirstChild("ArenaRunway") ~= nil).toBe(true)
        expect((lobbyDecor :: Folder):FindFirstChild("ArenaApproachRibTop1") ~= nil).toBe(true)
        expect((lobbyDecor :: Folder):FindFirstChild("ChaosSign") ~= nil).toBe(true)
        expect(#(lobbyDecor :: Folder):GetChildren() >= 12).toBe(true)

        local arena = root:FindFirstChild("Arena")
        expect(arena ~= nil).toBe(true)

        local spawns = arena and arena:FindFirstChild("Spawns")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local entryGuides = arena and arena:FindFirstChild("EntryGuides")
        local decor = arena and arena:FindFirstChild("Decor")
        local killPlane = arena and arena:FindFirstChild("KillPlane")

        expect(killPlane ~= nil).toBe(true)
        expect((killPlane :: BasePart).CanCollide).toBe(false)
        expect((killPlane :: BasePart).CanTouch).toBe(true)
        expect((killPlane :: BasePart).Position.Y < Config.ArenaCenter.Y - 10).toBe(true)
        expect(spawns ~= nil).toBe(true)
        expect(platforms ~= nil).toBe(true)
        expect(entryGuides ~= nil).toBe(true)
        expect(#(entryGuides :: Folder):GetChildren()).toBe(#(spawns :: Folder):GetChildren() * 2)
        expect(decor ~= nil).toBe(true)
        expect(#(spawns :: Folder):GetChildren() >= 8).toBe(true)
        local firstSpawn = (spawns :: Folder):FindFirstChild("Spawn1")
        expect(firstSpawn ~= nil).toBe(true)
        if firstSpawn and firstSpawn:IsA("BasePart") then
            local inward = Vector3.new(
                Config.ArenaCenter.X - firstSpawn.Position.X,
                0,
                Config.ArenaCenter.Z - firstSpawn.Position.Z
            )
            if inward.Magnitude > 0.01 then
                expect(firstSpawn.CFrame.LookVector:Dot(inward.Unit) > 0.15).toBe(true)
            end
        end
        expect(#(platforms :: Folder):GetChildren() >= 14).toBe(true)
        expect((decor :: Folder):FindFirstChild("CenterBeacon") ~= nil).toBe(true)
        expect((decor :: Folder):FindFirstChild("PlatformPanel1") ~= nil).toBe(true)
        expect((decor :: Folder):FindFirstChild("PlatformUnderFrame1") ~= nil).toBe(true)
        expect((decor :: Folder):FindFirstChild("PlatformSupport1_1") ~= nil).toBe(true)
        expect(#(decor :: Folder):GetChildren() >= 5).toBe(true)

        for _, item in ipairs((decor :: Folder):GetDescendants()) do
            if item:IsA("BasePart") then
                expect(item.CanCollide).toBe(false)
                expect(item.CanTouch).toBe(false)
                expect(item.CanQuery).toBe(false)
            end
        end

        root:Destroy()
    end)

    it("resolves humanoids from nested hit descendants", function()
        local character = Instance.new("Model")
        character.Name = "NestedCharacter"

        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character

        local accessory = Instance.new("Model")
        accessory.Name = "NestedAccessory"
        accessory.Parent = character

        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Parent = accessory

        character.Parent = workspace

        expect(MapBuilder.humanoidFromHit(handle)).toBe(humanoid)

        character:Destroy()
    end)

    it("can hot-swap every arena variant without deleting the lobby", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local lobby = root:FindFirstChild("Lobby")
        expect(lobby ~= nil).toBe(true)

        for _, id in ipairs(ArenaVariants.Order) do
            local arena = MapBuilder.buildArena(Config, id, ArenaVariants)
            expect(arena:GetAttribute("VariantId")).toBe(id)
            expect(arena:FindFirstChild("Spawns") ~= nil).toBe(true)
            expect(arena:FindFirstChild("Platforms") ~= nil).toBe(true)
            expect(arena:FindFirstChild("Decor") ~= nil).toBe(true)
            expect(root:FindFirstChild("Lobby") == lobby).toBe(true)
        end

        root:Destroy()
    end)

    it("builds physical Tower Run bridges with purely cosmetic edge rails", function()
        local root = MapBuilder.build(Config, "Towers", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local decor = arena and arena:FindFirstChild("Decor")
        expect(platforms ~= nil).toBe(true)
        expect(decor ~= nil).toBe(true)

        local bridges = 0
        for _, p in ipairs((platforms :: Folder):GetChildren()) do
            if p:GetAttribute("ChaosSkybridge") == true then
                bridges += 1
                expect(p.CanCollide).toBe(true)
                expect(p:IsA("BasePart")).toBe(true)
                expect(math.abs(p.Position.Y + p.Size.Y * 0.5
                    - (Config.ArenaCenter.Y + 13)) < 0.001).toBe(true)
            end
        end
        expect(bridges).toBe(4)
        -- Permanently safe bridges supply a consistent escape route; only
        -- adjacent conventional platforms participate in random collapse.
        local eligible = DisappearingPlatforms.eligiblePlatforms(platforms, {})
        expect(#eligible > 0).toBe(true)
        for _, candidate in ipairs(eligible) do
            expect(candidate:GetAttribute("ChaosSkybridge") == true).toBe(false)
        end

        for _, item in ipairs((decor :: Folder):GetChildren()) do
            if string.find(item.Name, "SkybridgeRail", 1, true) then
                expect(item.CanCollide).toBe(false)
                expect(item.CanTouch).toBe(false)
                expect(item.CanQuery).toBe(false)
            end
        end
        expect((decor :: Folder):FindFirstChild("SkybridgeRail18_-1") ~= nil).toBe(true)
        root:Destroy()
    end)

    it("draws twenty-four noncolliding return-route chevrons in Crossroads", function()
        local root = MapBuilder.build(Config, "Crossroads", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local decor = arena and arena:FindFirstChild("Decor")
        expect(decor ~= nil).toBe(true)
        local count = 0
        for _, part in ipairs((decor :: Folder):GetChildren()) do
            if string.find(part.Name, "FluxRouteChevron", 1, true) then
                count += 1
                expect(part:IsA("BasePart")).toBe(true)
                expect(part.CanCollide).toBe(false)
                expect(part.CanTouch).toBe(false)
                expect(part.CanQuery).toBe(false)
                expect(part.Size.Y <= 0.06).toBe(true)
            end
        end
        expect(count).toBe(24)
        root:Destroy()
    end)

    it("has valid round timing and rewards", function()
        expect(Config.RoundSeconds > 0).toBe(true)
        expect(Config.IntermissionSeconds >= 0).toBe(true)
        expect(Config.WinCoins > 0).toBe(true)
        expect(Config.WinXP > 0).toBe(true)
    end)
end)

return nil
