--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local OriginalMeshScenery = require("../../src/server/OriginalMeshScenery")
local LobbyReturnFormation = require("../../src/server/LobbyReturnFormation")
local ArenaVariants = require("../../src/server/ArenaVariants")
local JumpRouteCueRules = require("../../src/shared/JumpRouteCueRules")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
local OrbitalRouteSignKit = require("../../src/client/OrbitalRouteSignKit")
local DisappearingPlatforms = require("../../src/server/Disasters/DisappearingPlatforms")
local SpawnSafety = require("../../src/server/SpawnSafety")
local ArenaPresentation = require("../../src/shared/ArenaPresentation")

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
        expect(#(platforms :: Folder):GetChildren()).toBe(
            #ArenaVariants.get("Classic").Platforms + 16
        )
        -- Route-tier identity is replicated with the physical decks and
        -- reflects intentional jumpable paths, not client-only cosmetics.
        expect((platforms :: Folder):FindFirstChild("Platform1")
            :GetAttribute("RouteTier")).toBe(3)
        expect((platforms :: Folder):FindFirstChild("Platform5")
            :GetAttribute("RouteTier")).toBe(1)
        expect((platforms :: Folder):FindFirstChild("Platform9")
            :GetAttribute("RouteTier")).toBe(2)
        expect((platforms :: Folder):FindFirstChild("Platform13")
            :GetAttribute("RouteTier")).toBe(4)
        local flatGuides = 0
        for _, piece in ipairs((decor :: Folder):GetChildren()) do
            if piece.Name:match("^ClassicEntryChevron") then
                flatGuides += 1
                expect(piece.CanCollide).toBe(false)
                expect(piece.CanTouch).toBe(false)
                expect(piece.CanQuery).toBe(false)
            end
        end
        expect(flatGuides).toBe(8)
        expect((decor :: Folder):FindFirstChild("CenterBeacon") ~= nil).toBe(true)
        expect((decor :: Folder):FindFirstChild("PlatformPanel1") ~= nil).toBe(true)
        expect((decor :: Folder):FindFirstChild("PlatformUnderFrame1") ~= nil).toBe(true)
        -- All four machined edges are cosmetic and obey the server's
        -- authoritative collapse phase (no phantom floor after hiding).
        local platform1 = (platforms :: Folder):FindFirstChild("Platform1")
        expect(platform1 ~= nil).toBe(true)
        local bevels = {}
        for edgeIndex = 1, 4 do
            local bevel = (decor :: Folder):FindFirstChild(
                "PlatformBevel1_" .. edgeIndex
            )
            expect(bevel ~= nil).toBe(true)
            if bevel and bevel:IsA("BasePart") then
                expect(bevel.CanCollide).toBe(false)
                expect(bevel.CanTouch).toBe(false)
                expect(bevel.CanQuery).toBe(false)
                table.insert(bevels, bevel)
            end
        end
        local cosmetics = DisappearingPlatforms.cosmeticsForPlatform(
            decor, platform1
        )
        local tracked = {}
        for _, entry in ipairs(cosmetics) do
            tracked[entry.part] = true
        end
        for _, bevel in ipairs(bevels) do
            expect(tracked[bevel] == true).toBe(true)
        end
        DisappearingPlatforms.setCosmeticsPhase(cosmetics, "Gone")
        for _, bevel in ipairs(bevels) do
            expect(bevel.Transparency).toBe(1)
        end
        DisappearingPlatforms.setCosmeticsPhase(cosmetics, nil)
        for _, bevel in ipairs(bevels) do
            expect(math.abs(bevel.Transparency - 0.08) < 0.0001).toBe(true)
        end
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

    it("keeps center route glyphs and Low-tier surface plates above the arena inset", function()
        -- Use actual authored 3D geometry, not a hand-guessed floor height.
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local base = arena and arena:FindFirstChild("Base")
        local decor = arena and arena:FindFirstChild("Decor")
        local inset = decor and decor:FindFirstChild("ArenaDeckInset")
        expect(base ~= nil and inset ~= nil).toBe(true)

        local platform = base :: BasePart
        local panel = inset :: BasePart
        local topInBase = platform.CFrame:PointToObjectSpace(panel.Position).Y
            + panel.Size.Y * 0.5
        for _, thickness in ipairs({0.05, 0.09}) do
            local centerY = ArenaPresentation.deckArtOffset(platform, thickness)
            local bottomY = centerY - thickness * 0.5
            expect(bottomY > topInBase + 0.005).toBe(true)
            expect(bottomY < topInBase + 0.03).toBe(true)
        end

        expect(ArenaPresentation.deckArtOffset(nil, 0.05) == nil).toBe(true)
        expect(ArenaPresentation.deckArtOffset(Instance.new("Folder"), 0.05)
            == nil).toBe(true)
        root:Destroy()
    end)

    it("avoids other players and world obstacles at round entry", function()
        local generated = MapBuilder.build(Config, "Classic", ArenaVariants)
        local arena = generated:FindFirstChild("Arena")
        local spawns = arena and arena:FindFirstChild("Spawns")
        local marker = spawns and spawns:FindFirstChild("Spawn1")
        expect(marker ~= nil).toBe(true)

        local character = Instance.new("Model")
        character.Name = "RoundEntryProbe"
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        local ownRoot = Instance.new("Part")
        ownRoot.Name = "HumanoidRootPart"
        ownRoot.Size = Vector3.new(2, 2, 1)
        ownRoot.CanCollide = false
        ownRoot.Parent = character
        character.Parent = workspace

        local before, initialSlot = SpawnSafety.resolve(arena, marker, humanoid, ownRoot)
        expect(before ~= nil).toBe(true)
        expect(SpawnSafety.clearAt(arena, before.Position)).toBe(true)

        -- A non-arena solid prop obstructs the first candidate. The
        -- initial scan must select another safe entry while the later
        -- arena-only post-spawn check remains unaffected by other people.
        local obstacle = Instance.new("Part")
        obstacle.Name = "ExternalSpawnObstacle"
        obstacle.Anchored = true
        obstacle.CanCollide = true
        obstacle.Size = Vector3.new(6, 8, 6)
        obstacle.Position = before.Position
        obstacle.Parent = workspace

        local after, nextSlot = SpawnSafety.resolve(arena, marker, humanoid, ownRoot)
        expect(after ~= nil).toBe(true)
        expect(nextSlot ~= initialSlot).toBe(true)
        expect(SpawnSafety.clearAt(arena, before.Position)).toBe(true)

        obstacle:Destroy()

        -- A living peer with query-visible but non-colliding body parts
        -- must also reserve the spawn area; a dead rig does not.
        local peer = Instance.new("Model")
        peer.Name = "OtherSurvivor"
        local peerHumanoid = Instance.new("Humanoid")
        peerHumanoid.Parent = peer
        local peerPart = Instance.new("Part")
        peerPart.Size = Vector3.new(6, 8, 6)
        peerPart.CanCollide = false
        peerPart.CanQuery = true
        peerPart.Anchored = true
        peerPart.Position = before.Position
        peerPart.Parent = peer
        peer.Parent = workspace

        local away, awaySlot = SpawnSafety.resolve(arena, marker, humanoid, ownRoot)
        expect(away ~= nil).toBe(true)
        expect(awaySlot ~= initialSlot).toBe(true)
        peerHumanoid.Health = 0
        local freeAgain, clearSlot = SpawnSafety.resolve(
            arena, marker, humanoid, ownRoot
        )
        expect(freeAgain ~= nil).toBe(true)
        expect(clearSlot).toBe(initialSlot)

        peer:Destroy()
        character:Destroy()
        generated:Destroy()
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

    it("builds four safe sculpted perimeter stations on each enlarged map", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local decor = arena:FindFirstChild("Decor")
            local base = arena:FindFirstChild("Base")
            expect(base.Size.X >= 150).toBe(true)
            expect(base.Size.Z >= 150).toBe(true)

            local count = 0
            local wedges = 0
            for _, direction in ipairs({"North", "East", "South", "West"}) do
                local station = decor:FindFirstChild("PerimeterStation" .. direction)
                expect(station ~= nil and station:IsA("Model")).toBe(true)
                expect(station:GetAttribute("ChaosPerimeterStation")).toBe(true)
                local stationPieces = 0
                for _, piece in ipairs(station:GetDescendants()) do
                    if piece:IsA("BasePart") then
                        stationPieces += 1
                        if piece:IsA("WedgePart") then wedges += 1 end
                        expect(piece.Anchored).toBe(true)
                        expect(piece.CanCollide).toBe(false)
                        expect(piece.CanTouch).toBe(false)
                        expect(piece.CanQuery).toBe(false)
                        expect(piece.CastShadow).toBe(false)
                        expect(math.abs(piece.Position.X - base.Position.X)
                            + piece.Size.X * 0.5 <= base.Size.X * 0.5 - 5
                        ).toBe(true)
                        expect(math.abs(piece.Position.Z - base.Position.Z)
                            + piece.Size.Z * 0.5 <= base.Size.Z * 0.5 - 5
                        ).toBe(true)
                    end
                end
                expect(stationPieces >= 11).toBe(true)
                count += 1
            end
            expect(count).toBe(4)
            expect(wedges >= 8).toBe(true)
            root:Destroy()
        end
    end)

    it("sculpts noninteractive distant skyline outside every enlarged arena", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local decor = arena:FindFirstChild("Decor")
            local count = 0
            local distinctGeometry = 0
            for _, direction in ipairs({"North", "East", "South", "West"}) do
                local skyline = decor:FindFirstChild("SkylineStructure" .. direction)
                expect(skyline ~= nil and skyline:IsA("Model")).toBe(true)
                expect(skyline:GetAttribute("ChaosDistantScenery")).toBe(true)
                count += 1
                local parts = 0
                for _, piece in ipairs(skyline:GetDescendants()) do
                    if piece:IsA("BasePart") then
                        parts += 1
                        if piece:IsA("WedgePart") then
                            distinctGeometry += 1
                        end
                        expect(piece.Anchored).toBe(true)
                        expect(piece.CanCollide).toBe(false)
                        expect(piece.CanTouch).toBe(false)
                        expect(piece.CanQuery).toBe(false)
                        expect(piece.CastShadow).toBe(false)
                        expect(piece.Material ~= Enum.Material.Neon).toBe(true)
                        local relative = piece.Position - base.Position
                        local beyondX = math.abs(relative.X)
                            - piece.Size.Magnitude * 0.5
                            > base.Size.X * 0.5 + 5
                        local beyondZ = math.abs(relative.Z)
                            - piece.Size.Magnitude * 0.5
                            > base.Size.Z * 0.5 + 5
                        -- No decorative skyline shape can intrude on any
                        -- playable edge, even with its most conservative
                        -- bound sphere on rotated geometry.
                        expect(beyondX or beyondZ).toBe(true)
                    end
                end
                expect(parts >= 7 and parts <= 9).toBe(true)
            end
            for _, direction in ipairs({"North", "East", "South", "West"}) do
                for layer = 1, 2 do
                    local depth = decor:FindFirstChild(
                        "SkylineDepth" .. direction .. layer
                    )
                    expect(depth ~= nil and depth:IsA("Model")).toBe(true)
                    expect(depth:GetAttribute("ChaosDistantScenery")).toBe(true)
                    expect(#depth:GetChildren()).toBe(2)
                    for _, piece in ipairs(depth:GetChildren()) do
                        expect(piece:IsA("BasePart")).toBe(true)
                        expect(piece.Anchored).toBe(true)
                        expect(piece.CanCollide).toBe(false)
                        expect(piece.CanTouch).toBe(false)
                        expect(piece.CanQuery).toBe(false)
                        expect(piece.CastShadow).toBe(false)
                        expect(piece.Material ~= Enum.Material.Neon).toBe(true)
                    end
                end
            end
            expect(count).toBe(4)
            expect(distinctGeometry >= 12).toBe(true)
            root:Destroy()
        end
    end)

    it("authors four distinct off-map megastructures without gameplay collisions", function()
        local variantIdentity = {
            Classic = "PrimaryRelayMast",
            Towers = "OverheadServiceBridge",
            Crossroads = "UpperExchange",
            Orbital = "ReactorArc1",
        }
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local decor = arena:FindFirstChild("Decor")
            local hero = decor:FindFirstChild("ArenaSignatureMegastructure")
            expect(hero ~= nil and hero:IsA("Model")).toBe(true)
            expect(hero:GetAttribute("ChaosDistantScenery")).toBe(true)
            expect(hero:GetAttribute("SignatureVariant")).toBe(id)
            expect(hero:FindFirstChild(variantIdentity[id]) ~= nil).toBe(true)
            local count = 0
            local highest = -math.huge
            for _, piece in ipairs(hero:GetDescendants()) do
                if piece:IsA("BasePart") then
                    count += 1
                    expect(piece.Anchored).toBe(true)
                    expect(piece.CanCollide).toBe(false)
                    expect(piece.CanTouch).toBe(false)
                    expect(piece.CanQuery).toBe(false)
                    expect(piece.CastShadow).toBe(false)
                    expect(piece.Material ~= Enum.Material.Neon).toBe(true)
                    -- Conservative sphere radius handles rotated braces and
                    -- wedges; art cannot intrude into the shrinking floor.
                    local distanceBeyondNorth = (base.Position.Z
                        - base.Size.Z * 0.5) - piece.Position.Z
                        - piece.Size.Magnitude * 0.5
                    expect(distanceBeyondNorth > 12).toBe(true)
                    highest = math.max(highest,
                        piece.Position.Y + piece.Size.Y * 0.5)
                end
            end
            expect(count >= 12 and count <= 28).toBe(true)
            expect(highest - base.Position.Y > 40).toBe(true)
            root:Destroy()
        end
    end)

    it("builds an original hero 3D landmark unique to every arena", function()
        local signatures = {
            Classic = "StormDishArc1",
            Towers = "SuspendedTransitCabin-1",
            Crossroads = "ExchangeCoupler1",
            Orbital = "OrbitalOuterArc1",
        }
        local counts = {}
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local decor = arena:FindFirstChild("Decor")
            local hero = decor:FindFirstChild("ArenaHeroArchitecture3D")
            expect(hero ~= nil and hero:IsA("Model")).toBe(true)
            expect(hero:GetAttribute("ChaosDistantScenery")).toBe(true)
            expect(hero:GetAttribute("SourceIsOriginal")).toBe(true)
            expect(hero:GetAttribute("SignatureVariant")).toBe(id)
            expect(hero:FindFirstChild(signatures[id]) ~= nil).toBe(true)
            local count = 0
            local peak = -math.huge
            for _, part in ipairs(hero:GetDescendants()) do
                if part:IsA("BasePart") then
                    count += 1
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part.Material ~= Enum.Material.Neon).toBe(true)
                    -- Conservative 3D radius even for diagonal beams.
                    local beyondEast = (part.Position.X
                        - part.Size.Magnitude * 0.5)
                        - (base.Position.X + base.Size.X * 0.5)
                    expect(beyondEast > 15).toBe(true)
                    peak = math.max(peak,
                        part.Position.Y + part.Size.Y * 0.5)
                end
            end
            expect(count >= 14 and count <= 32).toBe(true)
            expect(hero:GetAttribute("HeroArchitectureParts")).toBe(count)
            expect(peak - base.Position.Y > 30).toBe(true)
            counts[id] = count
            root:Destroy()
        end
        -- Different scene silhouettes: not 4 differently tinted copies.
        expect(counts.Classic ~= counts.Towers).toBe(true)
        expect(counts.Crossroads ~= counts.Orbital).toBe(true)
    end)

    it("adds camera-facing 3D facade glazing without unsafe neon or mobile bloat", function()
        local windows = {
            Classic = "StormReadout",
            Towers = "CabinWestObservation-1",
            Crossroads = "ExchangeDataPane",
            Orbital = "ReactorServicePane",
        }
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local decor = root:FindFirstChild("Arena"):FindFirstChild("Decor")
            local hero = decor:FindFirstChild("ArenaHeroArchitecture3D")
            local facade = hero and hero:FindFirstChild(windows[id])
            expect(facade ~= nil and facade:IsA("BasePart")).toBe(true)
            if facade and facade:IsA("BasePart") then
                expect(facade.Material).toBe(Enum.Material.Glass)
                expect(facade.Size.X < 0.2).toBe(true)
                expect(facade.Transparency > 0.15).toBe(true)
                expect(facade.Transparency < 0.35).toBe(true)
                expect(facade.Anchored).toBe(true)
                expect(facade.CanCollide).toBe(false)
                expect(facade.CanTouch).toBe(false)
                expect(facade.CanQuery).toBe(false)
                expect(facade.CastShadow).toBe(false)
                -- These 3D landmarks are east of the arena; front lenses
                -- must face west (-X), not disappear around the far side.
                local originX = root:FindFirstChild("Arena"):FindFirstChild("Base")
                    .Position.X + ArenaVariants.get(id).BaseSize.X * 0.5 + 68
                expect(facade.Position.X < originX - 2).toBe(true)
            end
            if id == "Classic" then
                expect(hero:FindFirstChild("DishHub").Shape)
                    .toBe(Enum.PartType.Ball)
            elseif id == "Orbital" then
                expect(hero:FindFirstChild("HaloLens").Shape)
                    .toBe(Enum.PartType.Ball)
            elseif id == "Towers" then
                expect(hero:FindFirstChild("CabinWestObservation1") ~= nil)
                    .toBe(true)
            end
            expect(#hero:GetChildren() <= 32).toBe(true)
            root:Destroy()
        end
    end)

    it("keeps a recognizable original 3D skyline under the Android Low budget", function()
        local expectedEssential = {
            Classic = 10, Towers = 8, Crossroads = 6, Orbital = 10,
        }
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local decor = root:FindFirstChild("Arena"):FindFirstChild("Decor")
            local hero = decor:FindFirstChild("ArenaHeroArchitecture3D")
            local total, essential = 0, 0
            local names = {}
            for _, piece in ipairs(hero:GetChildren()) do
                if piece:IsA("BasePart") then
                    total += 1
                    if piece:GetAttribute("HeroSilhouetteEssential") == true then
                        essential += 1
                        names[piece.Name] = true
                        expect(piece.Anchored).toBe(true)
                        expect(piece.CanCollide).toBe(false)
                        expect(piece.CanTouch).toBe(false)
                        expect(piece.CanQuery).toBe(false)
                        expect(piece.CastShadow).toBe(false)
                    end
                end
            end
            expect(essential).toBe(expectedEssential[id])
            expect(hero:GetAttribute("HeroEssentialParts")).toBe(essential)
            expect(hero.ModelStreamingMode).toBe(Enum.ModelStreamingMode.Atomic)
            expect(total).toBe(hero:GetAttribute("HeroArchitectureParts"))
            expect(essential < total).toBe(true)
            if id == "Classic" then
                expect(names.DishHub).toBe(true)
            elseif id == "Towers" then
                expect(names.SkyTransitMainBeam).toBe(true)
            elseif id == "Crossroads" then
                expect(names.EastConduit).toBe(true)
            else
                expect(names.HaloLens).toBe(true)
            end
            root:Destroy()
        end
    end)

    it("gives every arena its own southern 3D skyline without unsafe collision", function()
        local signatures = {
            Classic = "ObservatoryBridge",
            Towers = "SkyTransfer",
            Crossroads = "CentralSwitchCab",
            Orbital = "ObservationArc1",
        }
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local decor = arena:FindFirstChild("Decor")
            local monument = decor:FindFirstChild("SouthHorizonMonument")
            expect(monument ~= nil and monument:IsA("Model")).toBe(true)
            expect(monument:GetAttribute("ChaosDistantScenery")).toBe(true)
            expect(monument:GetAttribute("SignatureVariant")).toBe(id)
            expect(monument:FindFirstChild(signatures[id]) ~= nil).toBe(true)

            local parts = 0
            local neonParts = 0
            local highest = -math.huge
            for _, piece in ipairs(monument:GetDescendants()) do
                if piece:IsA("BasePart") then
                    parts += 1
                    if piece.Material == Enum.Material.Neon then
                        neonParts += 1
                    end
                    expect(piece.Anchored).toBe(true)
                    expect(piece.CanCollide).toBe(false)
                    expect(piece.CanTouch).toBe(false)
                    expect(piece.CanQuery).toBe(false)
                    expect(piece.CastShadow).toBe(false)
                    -- Conservative bound keeps every silhouette WELL beyond
                    -- the kill plane, shrinking floor and bot routes.
                    local beyondSouth = piece.Position.Z
                        - piece.Size.Magnitude * 0.5
                        - (base.Position.Z + base.Size.Z * 0.5)
                    expect(beyondSouth > 12).toBe(true)
                    highest = math.max(highest,
                        piece.Position.Y + piece.Size.Y * 0.5)
                end
            end
            expect(parts >= 12 and parts <= 24).toBe(true)
            expect(neonParts <= 2).toBe(true)
            expect(highest - base.Position.Y > 37).toBe(true)

            -- The complementary industrial background must stay outside
            -- the combat floor, never become fake platforms, and remain
            -- bounded enough for Android graphics budgets.
            local silhouettes = {"North", "East", "South", "West"}
            local totalPieces = 0
            for _, side in ipairs(silhouettes) do
                local model = decor:FindFirstChild("ExteriorSilhouette" .. side)
                expect(model ~= nil and model:IsA("Model")).toBe(true)
                expect(model:GetAttribute("ChaosDistantScenery")).toBe(true)
                expect(model:FindFirstChild("ReactorShell") ~= nil).toBe(true)
                expect(model:FindFirstChild("RoofCanopy") ~= nil).toBe(true)
                expect(model:FindFirstChild("SignalBand") ~= nil).toBe(true)
                local sidePieces = 0
                for _, piece in ipairs(model:GetDescendants()) do
                    if piece:IsA("BasePart") then
                        sidePieces += 1
                        totalPieces += 1
                        expect(piece.Anchored).toBe(true)
                        expect(piece.CanCollide).toBe(false)
                        expect(piece.CanTouch).toBe(false)
                        expect(piece.CanQuery).toBe(false)
                        expect(piece.CastShadow).toBe(false)
                        local centerDelta = piece.Position - base.Position
                        local conservativeRadius = piece.Size.Magnitude * 0.5
                        local outsideX = math.abs(centerDelta.X)
                            - conservativeRadius - base.Size.X * 0.5
                        local outsideZ = math.abs(centerDelta.Z)
                            - conservativeRadius - base.Size.Z * 0.5
                        expect(outsideX > 12 or outsideZ > 12).toBe(true)
                    end
                end
                expect(sidePieces).toBe(6)
            end
            expect(totalPieces).toBe(24)
            root:Destroy()
        end
    end)

    it("preserves route neon but keeps giant floor fills non-emissive", function()
        local wideByArena = {
            Classic = {},
            Towers = {"TowerGroundPlate1", "TowerGroundPlate2"},
            Crossroads = {"CrossroadLaneFill1", "CrossroadLaneFill2",
                "CrossroadLaneFill3", "CrossroadLaneFill4",
                "CrossroadHubMark"},
            Orbital = {"OrbitalCoreMark"},
        }
        local smallCues = {
            Classic = "ClassicEntryChevron1_-1",
            Towers = "TowerAscentChevron1_-1",
            Crossroads = "FluxRouteChevron1_1_-1",
            Orbital = "OrbitalSpoke1",
        }
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local decor = root:FindFirstChild("Arena"):FindFirstChild("Decor")
            for _, name in ipairs(wideByArena[id]) do
                local surface = decor:FindFirstChild(name)
                expect(surface ~= nil and surface:IsA("BasePart")).toBe(true)
                expect(surface.Material ~= Enum.Material.Neon).toBe(true)
                expect(surface.CanCollide).toBe(false)
                expect(surface.CanTouch).toBe(false)
                expect(surface.CanQuery).toBe(false)
            end
            local navigation = decor:FindFirstChild(smallCues[id])
            expect(navigation ~= nil and navigation:IsA("BasePart")).toBe(true)
            expect(navigation.Material).toBe(Enum.Material.Neon)
            for _, seam in ipairs({"DeckLineNorth", "DeckLineEast"}) do
                local line = decor:FindFirstChild(seam)
                expect(line ~= nil and line:IsA("BasePart")).toBe(true)
                expect(line.Material).toBe(Enum.Material.Neon)
                expect(line.Transparency >= 0.55).toBe(true)
            end
            if id == "Towers" then
                local core = decor:FindFirstChild("TowerGroundCore1")
                expect(core.Material).toBe(Enum.Material.Neon)
                expect(core.Transparency >= 0.7).toBe(true)
            end
            root:Destroy()
        end
    end)

    it("frames four map corners with nonblocking sculpted exterior ridges", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local base = arena:FindFirstChild("Base")
            local decor = arena:FindFirstChild("Decor")
            for _, corner in ipairs({"NW", "NE", "SW", "SE"}) do
                local ridge = decor:FindFirstChild("ExteriorRidge" .. corner)
                expect(ridge ~= nil and ridge:IsA("Model")).toBe(true)
                expect(ridge:GetAttribute("ChaosDistantScenery")).toBe(true)
                expect(#ridge:GetChildren()).toBe(3)
                for _, part in ipairs(ridge:GetChildren()) do
                    expect(part:IsA("WedgePart")).toBe(true)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    local delta = part.Position - base.Position
                    expect(math.abs(delta.X) - part.Size.Magnitude * 0.5
                        > base.Size.X * 0.5 + 3).toBe(true)
                    expect(math.abs(delta.Z) - part.Size.Magnitude * 0.5
                        > base.Size.Z * 0.5 + 3).toBe(true)
                end
            end
            root:Destroy()
        end
    end)

    it("physically builds accessible outer parkour while retaining original core IDs", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local base = arena:FindFirstChild("Base")
            local original = #variant.Platforms
            expect(#platforms:GetChildren()).toBe(original + 16)
            for route = 1, 4 do
                local previous = nil
                for step = 1, 4 do
                    local number = original + (route - 1) * 4 + step
                    local platform = platforms:FindFirstChild("Platform" .. number)
                    expect(platform ~= nil).toBe(true)
                    expect(platform.CanCollide).toBe(true)
                    expect(platform.Anchored).toBe(true)
                    expect(platform:GetAttribute("PerimeterRoute")).toBe(route)
                    expect(platform:GetAttribute("PerimeterStep")).toBe(step)
                    expect(platform:GetAttribute("RouteTier")).toBe(step)
                    expect(math.abs(platform.Position.X - Config.ArenaCenter.X)
                        >= 45).toBe(true)
                    expect(math.abs(platform.Position.Y - platform.Size.Y * 0.5
                        - (base.Position.Y + base.Size.Y * 0.5)) < 0.001).toBe(true)
                    if previous then
                        local horizontal = JumpRouteCueRules.gap(previous, platform)
                        local rise = platform.Position.Y + platform.Size.Y * 0.5
                            - (previous.Position.Y + previous.Size.Y * 0.5)
                        expect(horizontal > 0.15 and horizontal < 3.85).toBe(true)
                        expect(rise >= 2.5 and rise <= 4.05).toBe(true)
                    end
                    previous = platform
                end
            end
            -- Real, sculpted exit facades are cosmetic: no collision,
            -- no physics queries and no excess shadow/light cost.
            local decor = arena:FindFirstChild("Decor")
            for route = 1, 4 do
                for _, name in ipairs({
                    "PerimeterExitRib" .. route .. "_-1",
                    "PerimeterExitRib" .. route .. "_1",
                    "PerimeterExitCrown" .. route,
                    "PerimeterExitLens" .. route,
                }) do
                    local piece = decor:FindFirstChild(name)
                    expect(piece ~= nil and piece:IsA("BasePart")).toBe(true)
                    expect(piece.Anchored).toBe(true)
                    expect(piece.CanCollide).toBe(false)
                    expect(piece.CanTouch).toBe(false)
                    expect(piece.CanQuery).toBe(false)
                    expect(piece.CastShadow).toBe(false)
                end
                expect(decor:FindFirstChild("PerimeterExitCrown" .. route)
                    :IsA("WedgePart")).toBe(true)
            end
            -- The same authoritative folder is inspected by AI, shrinking,
            -- platform collapse, collectibles and native raycasts.
            root:Destroy()
        end
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
                -- The server panel exists on every skybridge too; client
                -- markings must clear its actual upper face.
                local index = p.Name:match("^Skybridge(%d+)$")
                expect(index ~= nil).toBe(true)
                local panel = decor:FindFirstChild("PlatformPanel" .. index)
                expect(panel ~= nil).toBe(true)
                expect(panel.CanCollide).toBe(false)
                expect(panel.Size.Y > 0).toBe(true)
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

        -- The world model must actually build the four authored climbing
        -- routes (not merely declare them in ArenaVariants metadata).
        local tierCount = {[1] = 0, [2] = 0, [3] = 0, [4] = 0}
        for _, platform in ipairs((platforms :: Folder):GetChildren()) do
            local tier = tonumber(platform:GetAttribute("RouteTier"))
            if tier then
                expect(platform.CanCollide).toBe(true)
                tierCount[tier] += 1
            end
        end
        expect(#(platforms :: Folder):GetChildren()).toBe(37)
        -- Original 21 decks and Skybridges 18–21 are unchanged.
        -- Sixteen outer-rim stages add four complete four-level escapes.
        expect(tierCount[1]).toBe(9)
        expect(tierCount[2]).toBe(8)
        expect(tierCount[3]).toBe(8)
        expect(tierCount[4]).toBe(8)

        -- Floor guidance must be genuinely visible but never obstruct
        -- escape movement, hazard collision or updraft pads.
        local guides = 0
        for _, item in ipairs((decor :: Folder):GetChildren()) do
            if item.Name:match("^TowerAscentChevron%d+_%-?%d+$") then
                guides += 1
                expect(item:IsA("BasePart")).toBe(true)
                expect(item.CanCollide).toBe(false)
                expect(item.CanTouch).toBe(false)
                expect(item.CanQuery).toBe(false)
                expect(item.CastShadow).toBe(false)
                expect(item.Transparency < 0.7).toBe(true)
            end
        end
        expect(guides).toBe(8)
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

        -- Every authored interchange deck is actually physical, with a
        -- visible tier code that contracts alongside its collision.
        local platforms = arena:FindFirstChild("Platforms")
        expect(platforms ~= nil).toBe(true)
        expect(#(platforms :: Folder):GetChildren()).toBe(
            #ArenaVariants.get("Crossroads").Platforms + 16
        )
        local tiers = {[1] = 0, [2] = 0, [3] = 0, [4] = 0}
        for index = 1, 17 do
            local deck = platforms:FindFirstChild("Platform" .. index)
            expect(deck ~= nil).toBe(true)
            expect(deck.CanCollide).toBe(true)
            local tier = tonumber(deck:GetAttribute("RouteTier"))
            expect(tier ~= nil).toBe(true)
            tiers[tier] += 1
            local finish = decor:FindFirstChild("PlatformPanel" .. index)
            expect(finish ~= nil).toBe(true)
            expect(finish.CanCollide).toBe(false)
        end
        expect(tiers[1]).toBe(5)
        expect(tiers[2]).toBe(4)
        expect(tiers[3]).toBe(4)
        expect(tiers[4]).toBe(4)
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

        local helixCount, entryCount, coreCount, noncolliding = 0, 0, 0, 0
        for _, obj in ipairs((circuit :: Folder):GetChildren()) do
            expect(obj:IsA("BasePart")).toBe(true)
            expect(obj.Anchored).toBe(true)
            expect(type(obj:GetAttribute("OrbitRouteGroup"))).toBe("string")
            local isHelix = obj:GetAttribute("OrbitalHelixRamp") == true
            local isEntry = obj:GetAttribute("OrbitalAccessRamp") == true
            local isCore = obj:GetAttribute("OrbitalCoreRamp") == true
            if isHelix or isEntry or isCore then
                if isHelix then helixCount += 1 end
                if isEntry then entryCount += 1 end
                if isCore then coreCount += 1 end
                local index = isHelix
                    and obj:GetAttribute("HelixLane")
                    or tonumber(obj.Name:match("%d+$"))
                local route = (isHelix or obj.Name == "HelixRamp9")
                    and OrbitalHelix.route(variant, center, index)
                    or OrbitalHelix.accessRoute(variant, center, index,
                        isEntry and "Entry" or "Core")
                expect(route ~= nil).toBe(true)
                expect(obj.CanCollide).toBe(true)
                expect(obj.CanTouch).toBe(true)
                expect(obj.CanQuery).toBe(true)
                expect(obj.Size.X >= 4.5).toBe(true)
                expect(obj.Size.Z >= 7).toBe(true)
                expect((obj.Position - route.CFrame.Position).Magnitude < 0.01)
                    .toBe(true)
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
        expect(helixCount).toBe(8)
        expect(entryCount).toBe(8)
        expect(coreCount).toBe(8)
        expect(noncolliding).toBe(132)
        -- The prior certified ninth core connector remains a real,
        -- transit-only route; no ninth mastery/scoring trigger is added.
        local core = circuit:FindFirstChild("HelixRamp9")
        expect(core ~= nil).toBe(true)
        expect(core:GetAttribute("OrbitalCoreRamp")).toBe(true)
        expect(core:GetAttribute("OrbitalHelixRamp") == nil).toBe(true)
        expect(circuit:FindFirstChild("CoreRamp2") == nil).toBe(true)
        local upper = arena:FindFirstChild("Platforms"):FindFirstChild("Platform18")
        local lower = arena:FindFirstChild("Platforms"):FindFirstChild("Platform17")
        local headroom = upper.Position.Y - upper.Size.Y * 0.5
            - (lower.Position.Y + lower.Size.Y * 0.5)
        expect(headroom >= 8.4).toBe(true)

        -- World signs must label actual solid access routes, not create
        -- fake walkable geometry. Check all eight entries and eight cores,
        -- including the legacy ninth (transit-only) connector.
        local signs = {}
        local count = 0
        for _, obj in ipairs(circuit:GetChildren()) do
            local kind = OrbitalRouteSignKit.kind(obj)
            if kind then
                count += 1
                local sign = OrbitalRouteSignKit.create(
                    obj, obj, "High", "fr-fr"
                )
                expect(sign ~= nil).toBe(true)
                expect(sign:IsA("SurfaceGui")).toBe(true)
                expect(sign.Parent).toBe(obj)
                expect(sign.Adornee).toBe(obj)
                table.insert(signs, sign)
                expect(sign.Face).toBe(Enum.NormalId.Top)
                expect(sign.AlwaysOnTop).toBe(false)
                expect(sign.Active).toBe(false)
                expect(sign.MaxDistance <= 115).toBe(true)
                local plate = sign:FindFirstChild("EtchedWayfindingPlate")
                local name = plate and plate:FindFirstChild("RouteName")
                expect(name ~= nil).toBe(true)
                expect(name.Text == (kind == "Entry" and "MONTER" or "RÉACTEUR"))
                    .toBe(true)
                expect(plate:FindFirstChild("DestinationHint") ~= nil)
                    .toBe(true)
            end
        end
        expect(count).toBe(16)
        expect(#signs).toBe(16)
        expect(OrbitalRouteSignKit.kind(core)).toBe("Core")
        local helixOne = circuit:FindFirstChild("HelixRamp1")
        expect(OrbitalRouteSignKit.kind(helixOne) == nil).toBe(true)
        expect(OrbitalRouteSignKit.create(helixOne, helixOne, "High", "en"))
            .toBe(nil)
        expect(OrbitalRouteSignKit.copy("Entry", "en-us")[1]).toBe("ASCEND")
        expect(OrbitalRouteSignKit.copy("Core", "fr-fr")[2])
            .toBe("DERNIER PALIER")

        -- Low-end mobile hardware keeps concise static wayfinding, but
        -- no extra decorative caption, lights, collisions or local parts.
        local low = OrbitalRouteSignKit.create(core, core, "Low", "en-us")
        table.insert(signs, low)
        expect(low ~= nil and low.Adornee == core).toBe(true)
        expect(low.PixelsPerStud).toBe(16)
        expect(low:FindFirstChild("EtchedWayfindingPlate")
            :FindFirstChild("DestinationHint") == nil).toBe(true)
        expect(low:FindFirstChild("EtchedWayfindingPlate")
            :FindFirstChild("RouteName").Text).toBe("CORE")
        local lowFr = OrbitalRouteSignKit.create(core, core, "Low", "fr-fr")
        table.insert(signs, lowFr)
        expect(lowFr:FindFirstChild("EtchedWayfindingPlate")
            :FindFirstChild("RouteName").Text).toBe("NOYAU")
        for _, sign in ipairs(signs) do
            for _, descendant in ipairs(sign:GetDescendants()) do
                expect(descendant:IsA("BasePart")).toBe(false)
                expect(descendant:IsA("PointLight")).toBe(false)
                expect(descendant:IsA("ParticleEmitter")).toBe(false)
            end
            -- Exactly these locally owned SurfaceGuis are removed on a
            -- streamed arena replacement or VFX quality change.
            sign:Destroy()
        end
        -- Existing collision/deck transform remains authoritative.
        expect(core.CanCollide).toBe(true)
        expect(core:FindFirstChild("OrbitalCoreNavigation") == nil)
            .toBe(true)

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

    it("renders only safe, owned 3D cosmetics beyond playable arena edges", function()
        local asset = Instance.new("Model")
        asset.Name = "UntrustedAssetPackage"
        local mesh = Instance.new("Part")
        mesh.Name = "OriginalMesh"
        mesh.Size = Vector3.new(13, 12, 3)
        mesh.Position = Vector3.new(0, 6, 0)
        mesh.Parent = asset
        local scriptInside = Instance.new("Script")
        scriptInside.Name = "UntrustedScriptMustNotRun"
        scriptInside.Parent = mesh
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "UntrustedParticles"
        particles.Parent = mesh
        local sourceScript = Instance.new("ModuleScript")
        sourceScript.Parent = asset

        local sanitized = OriginalMeshScenery.sanitize(asset)
        expect(sanitized ~= nil).toBe(true)
        expect(#(sanitized :: Model):GetDescendants()).toBe(1)
        local cleanPart = (sanitized :: Model):FindFirstChild("OriginalMesh")
        expect(cleanPart ~= nil and cleanPart:IsA("BasePart")).toBe(true)
        if cleanPart and cleanPart:IsA("BasePart") then
            expect(cleanPart.Anchored).toBe(true)
            expect(cleanPart.CanCollide).toBe(false)
            expect(cleanPart.CanTouch).toBe(false)
            expect(cleanPart.CanQuery).toBe(false)
            expect(cleanPart.CastShadow).toBe(false)
            expect(cleanPart:FindFirstChild("UntrustedScriptMustNotRun") == nil)
                .toBe(true)
            expect(cleanPart:FindFirstChild("UntrustedParticles") == nil)
                .toBe(true)
        end

        for _, variantId in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, variantId, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local decor = arena and arena:FindFirstChild("Decor")
            local base = arena and arena:FindFirstChild("Base")
            expect(base ~= nil and decor ~= nil).toBe(true)
            local placements = OriginalMeshScenery.placements(base, variantId)
            expect(#placements).toBe(8)
            local art = {}
            for _, slot in ipairs(placements) do
                art[slot.asset] = (art[slot.asset] or 0) + 1
            end
            local expected = if variantId == "Orbital"
                then {orbital_halo_array = 2, perimeter_gate = 1,
                    reactor_spire = 1}
                elseif variantId == "Towers"
                then {service_crane = 2, sky_transit_exchange = 1,
                    reactor_spire = 1}
                elseif variantId == "Crossroads"
                then {perimeter_gate = 1, sky_transit_exchange = 1,
                    plasma_foundry = 1, service_crane = 1}
                else {perimeter_gate = 1, plasma_foundry = 1,
                    reactor_spire = 1, service_crane = 1}
            for key, n in pairs(expected) do
                expect(art[key]).toBe(n)
            end
            for key, n in pairs(art) do
                expect(expected[key]).toBe(n)
            end
            local templates = {
                perimeter_gate = sanitized,
                reactor_spire = sanitized,
                service_crane = sanitized,
                plasma_foundry = sanitized,
                sky_transit_exchange = sanitized,
                orbital_halo_array = sanitized,
            }
            local count = OriginalMeshScenery.mount(arena, templates)
            expect(count).toBe(8)
            expect(OriginalMeshScenery.mount(arena, templates)).toBe(0)
            expect(arena:GetAttribute("Original3DSceneryCount")).toBe(8)
            expect(arena:GetAttribute("Original3DSceneryComplete")).toBe(true)
            local bucket = decor and decor:FindFirstChild("Original3DScenery")
            expect(bucket ~= nil).toBe(true)
            expect(#(bucket :: Folder):GetChildren()).toBe(8)

            for _, entry in ipairs(placements) do
                local placed = bucket and bucket:FindFirstChild(entry.name)
                expect(placed ~= nil and placed:IsA("Model")).toBe(true)
                if placed and placed:IsA("Model") then
                    expect(placed:GetAttribute("Original3DAssetId"))
                        .toBe(entry.assetId)
                    expect(placed:GetAttribute("CosmeticOnly")).toBe(true)
                    local _, dimensions = placed:GetBoundingBox()
                    expect(dimensions.Y > 0).toBe(true)
                    for _, p in ipairs(placed:GetDescendants()) do
                        expect(p:IsA("BasePart")).toBe(true)
                        if p:IsA("BasePart") then
                            expect(p.Anchored).toBe(true)
                            expect(p.CanCollide).toBe(false)
                            expect(p.CanTouch).toBe(false)
                            expect(p.CanQuery).toBe(false)
                            expect(p.CastShadow).toBe(false)
                        end
                    end
                    local x, z = entry.position.X, entry.position.Z
                    expect(math.abs(x - base.Position.X) > base.Size.X * 0.5
                        or math.abs(z - base.Position.Z) > base.Size.Z * 0.5)
                        .toBe(true)
                end
            end
            root:Destroy()
        end

        local empty = Instance.new("Model")
        expect(OriginalMeshScenery.sanitize(empty)).toBe(nil)
        empty:Destroy()
        local huge = Instance.new("Model")
        local part = Instance.new("Part")
        part.Size = Vector3.new(70, 70, 70)
        part.Parent = huge
        expect(OriginalMeshScenery.sanitize(huge)).toBe(nil)
        huge:Destroy()
        asset:Destroy()
        local cleanModel = sanitized :: Model
        cleanModel:Destroy()
    end)

    it("separates all six approved imported mesh shapes from native 3D skyline", function()
        local sizes = {
            perimeter_gate = Vector3.new(58, 25, 38),
            reactor_spire = Vector3.new(30, 62, 30),
            service_crane = Vector3.new(60, 48, 20),
            plasma_foundry = Vector3.new(30, 28, 14),
            sky_transit_exchange = Vector3.new(32, 28, 15),
            orbital_halo_array = Vector3.new(23, 31, 12),
        }
        local templates = {}
        for name, size in pairs(sizes) do
            local model = Instance.new("Model")
            model.Name = name
            local part = Instance.new("Part")
            part.Name = "MockImportedMesh"
            part.Size = size
            part.Parent = model
            templates[name] = model
        end
        local function worldRadii(cf, size)
            local x = (math.abs(cf.RightVector.X) * size.X
                + math.abs(cf.UpVector.X) * size.Y
                + math.abs(cf.LookVector.X) * size.Z) * 0.5
            local z = (math.abs(cf.RightVector.Z) * size.X
                + math.abs(cf.UpVector.Z) * size.Y
                + math.abs(cf.LookVector.Z) * size.Z) * 0.5
            return x, z
        end

        for _, variantId in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, variantId, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local decor = arena:FindFirstChild("Decor")
            local native = {}
            for _, model in ipairs(decor:GetChildren()) do
                if model:IsA("Model")
                    and model:GetAttribute("ChaosDistantScenery") == true then
                    local cf, size = model:GetBoundingBox()
                    local rx, rz = worldRadii(cf, size)
                    native[#native + 1] = {
                        x = cf.Position.X, z = cf.Position.Z,
                        rx = rx, rz = rz,
                    }
                end
            end
            expect(#native >= 12).toBe(true)
            expect(OriginalMeshScenery.mount(arena, templates)).toBe(8)
            local originals = decor:FindFirstChild("Original3DScenery")
            expect(#originals:GetChildren()).toBe(8)
            local occupied = {}
            for _, model in ipairs(originals:GetChildren()) do
                local cf, size = model:GetBoundingBox()
                local rx, rz = worldRadii(cf, size)
                occupied[#occupied + 1] = {
                    name = model.Name, x = cf.Position.X, z = cf.Position.Z,
                    rx = rx, rz = rz,
                }
                for _, bound in ipairs(native) do
                    local apartX = math.abs(cf.Position.X - bound.x)
                        >= rx + bound.rx + 3.9
                    local apartZ = math.abs(cf.Position.Z - bound.z)
                        >= rz + bound.rz + 3.9
                    expect(apartX or apartZ).toBe(true)
                end
                expect(model:GetAttribute("OriginalFoundationBuilt")).toBe(true)
            end
            -- Decorative packages must not interpenetrate each other:
            -- native skyline clearance alone is not enough.
            for i = 1, #occupied do
                for j = i + 1, #occupied do
                    local first, second = occupied[i], occupied[j]
                    local apartX = math.abs(first.x - second.x)
                        >= first.rx + second.rx + 3.9
                    local apartZ = math.abs(first.z - second.z)
                        >= first.rz + second.rz + 3.9
                    expect(apartX or apartZ).toBe(true)
                end
            end
            root:Destroy()
        end
        for _, template in pairs(templates) do template:Destroy() end
    end)

    it("has valid round timing and rewards", function()
        expect(Config.RoundSeconds > 0).toBe(true)
        expect(Config.IntermissionSeconds >= 0).toBe(true)
        expect(Config.WinCoins > 0).toBe(true)
        expect(Config.WinXP > 0).toBe(true)
    end)
end)

return nil
