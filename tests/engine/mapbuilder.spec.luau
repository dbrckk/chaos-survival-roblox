--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local LobbyReturnFormation = require("../../src/server/LobbyReturnFormation")
local ArenaVariants = require("../../src/server/ArenaVariants")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
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
        -- Roblox may choose a point anywhere inside an 8x8 SpawnLocation,
        -- not just its center. Require avatar clearance for the FULL
        -- footprint from the solid raised stage, plus a floor landing area.
        local lobbySpawn = lobby and lobby:FindFirstChild("LobbySpawn")
        local lobbyFloor = lobby and lobby:FindFirstChild("Floor")
        local stage = (lobbyDecor :: Folder):FindFirstChild("CenterPlatform")
        expect(lobbySpawn ~= nil and lobbySpawn:IsA("SpawnLocation")).toBe(true)
        if lobbySpawn and lobbySpawn:IsA("SpawnLocation")
            and stage and stage:IsA("BasePart")
            and lobbyFloor and lobbyFloor:IsA("BasePart") then
            local spawnLocal = stage.CFrame:PointToObjectSpace(lobbySpawn.Position)
            local minClearanceZ = (stage.Size.Z + lobbySpawn.Size.Z) * 0.5 + 2
            expect(spawnLocal.Z < -minClearanceZ).toBe(true)
            expect(lobbySpawn.CanCollide).toBe(false)
            expect(math.abs(lobbySpawn.Position.X - lobbyFloor.Position.X)
                + lobbySpawn.Size.X * 0.5 < lobbyFloor.Size.X * 0.5 - 2).toBe(true)
            expect(math.abs(lobbySpawn.Position.Z - lobbyFloor.Position.Z)
                + lobbySpawn.Size.Z * 0.5 < lobbyFloor.Size.Z * 0.5 - 2).toBe(true)
            expect(lobbySpawn.Position.Y >
                lobbyFloor.Position.Y + lobbyFloor.Size.Y * 0.5).toBe(true)
            -- First join should face the arena approach, not the rear wall.
            expect(lobbySpawn.CFrame.LookVector:Dot(Vector3.new(0, 0, 1)) > 0.95)
                .toBe(true)
            -- The raised stage is not the only lobby collision geometry.
            -- In particular "02 SURVIVE" at z=-18 is a solid panel:
            -- the full native spawn footprint must avoid ALL solid decor.
            for _, item in ipairs((lobbyDecor :: Folder):GetDescendants()) do
                if item:IsA("BasePart") and item.CanCollide then
                    local dx = math.abs(lobbySpawn.Position.X - item.Position.X)
                    local dz = math.abs(lobbySpawn.Position.Z - item.Position.Z)
                    local clearX = dx >= (lobbySpawn.Size.X + item.Size.X) * 0.5 + 2
                    local clearZ = dz >= (lobbySpawn.Size.Z + item.Size.Z) * 0.5 + 2
                    expect(clearX or clearZ).toBe(true)
                end
            end
        end
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

    it("builds eight connected, solid Orbital helix ramps with cosmetic rails", function()
        local variant = ArenaVariants.get("Orbital")
        local center = Config.ArenaCenter
        local root = MapBuilder.build(Config, "Orbital", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local circuit = arena and arena:FindFirstChild("HelixCircuit")
        expect(circuit ~= nil).toBe(true)
        expect(OrbitalHelix.Count).toBe(8)

        local physical = 0
        local noncolliding = 0
        for _, obj in ipairs((circuit :: Folder):GetChildren()) do
            expect(obj:IsA("BasePart")).toBe(true)
            expect(obj.Anchored).toBe(true)
            if obj:GetAttribute("OrbitalHelixRamp") == true then
                physical += 1
                local index = obj:GetAttribute("HelixLane")
                local route = OrbitalHelix.route(variant, center, index)
                expect(route ~= nil).toBe(true)
                expect(obj.CanCollide).toBe(true)
                expect(obj.CanTouch).toBe(true)
                expect(obj.CanQuery).toBe(true)
                expect(obj.Size.X >= 5).toBe(true)
                expect(obj.Size.Z >= 12).toBe(true)
                expect((obj.Position - route.CFrame.Position).Magnitude < 0.01).toBe(true)
                expect(obj.CFrame.LookVector:Dot(
                    (route.Finish - route.Start).Unit) > 0.999).toBe(true)
            else
                noncolliding += 1
                expect(obj.CanCollide).toBe(false)
                expect(obj.CanTouch).toBe(false)
                expect(obj.CanQuery).toBe(false)
                expect(obj.CastShadow).toBe(false)
            end
        end
        expect(physical).toBe(8)
        expect(noncolliding).toBe(64)

        local swapped = MapBuilder.buildArena(Config, "Classic", ArenaVariants)
        expect(swapped:FindFirstChild("HelixCircuit") == nil).toBe(true)
        root:Destroy()
    end)

    it("returns sixteen survivors to separated, solid-free lobby slots", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local lobby = root:FindFirstChild("Lobby")
        local spawn = lobby and lobby:FindFirstChild("LobbySpawn")
        local floor = lobby and lobby:FindFirstChild("Floor")
        local decor = lobby and lobby:FindFirstChild("Decor")
        expect(lobby ~= nil and spawn ~= nil and floor ~= nil and decor ~= nil).toBe(true)

        local positions = LobbyReturnFormation.positions(spawn, floor, decor, 16)
        expect(#positions).toBe(16)
        expect(#LobbyReturnFormation.positions(nil, nil, nil, 3)).toBe(0)

        local floorTop = floor.Position.Y + floor.Size.Y * 0.5
        for index, candidate in ipairs(positions) do
            local onFloor = floor.CFrame:PointToObjectSpace(candidate)
            expect(math.abs(onFloor.X) + 2.6 < floor.Size.X * 0.5).toBe(true)
            expect(math.abs(onFloor.Z) + 2.6 < floor.Size.Z * 0.5).toBe(true)

            for _, obstacle in ipairs(decor:GetDescendants()) do
                if obstacle:IsA("BasePart") and obstacle.CanCollide then
                    local high = obstacle.Position.Y + obstacle.Size.Y * 0.5
                    local low = obstacle.Position.Y - obstacle.Size.Y * 0.5
                    if high > floorTop + 0.8 and low < floorTop + 8 then
                        local localCandidate = obstacle.CFrame:PointToObjectSpace(candidate)
                        local intersects = math.abs(localCandidate.X)
                            < obstacle.Size.X * 0.5 + 2.6
                            and math.abs(localCandidate.Z)
                            < obstacle.Size.Z * 0.5 + 2.6
                        expect(intersects).toBe(false)
                    end
                end
            end

            for otherIndex = index + 1, #positions do
                local delta = candidate - positions[otherIndex]
                local horizontal = Vector3.new(delta.X, 0, delta.Z)
                expect(horizontal.Magnitude >= 6.4).toBe(true)
            end
        end

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
