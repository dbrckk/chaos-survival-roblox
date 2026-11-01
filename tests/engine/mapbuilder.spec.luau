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
local VisualTheme = require("../../src/shared/VisualTheme")

describe("Chaos Survival engine", function()
    it("gives all five physical parkour maps distinct deck materials", function()
        local expected = {
            Classic = Enum.Material.DiamondPlate,
            Towers = Enum.Material.Foil,
            Crossroads = Enum.Material.CorrodedMetal,
            Orbital = Enum.Material.CeramicTiles,
            Harbor = Enum.Material.WoodPlanks,
        }
        local seen = {}
        for _, variantId in ipairs(ArenaVariants.Order) do
            local material = expected[variantId]
            expect(material ~= nil).toBe(true)
            expect(seen[material] == nil).toBe(true)
            seen[material] = variantId
            expect(VisualTheme.arena(variantId).PanelMaterial).toBe(material)

            -- Inject the candidate's source palette: the Open Cloud test
            -- DataModel may still contain the previously published Shared
            -- VisualTheme asset. Production calls continue using its
            -- replicated module after the next certified publish.
            local root = MapBuilder.build(
                Config, variantId, ArenaVariants, VisualTheme
            )
            local arena = root:FindFirstChild("Arena")
            local decor = arena:FindFirstChild("Decor")
            local platforms = arena:FindFirstChild("Platforms")
            local n = #platforms:GetChildren()

            -- Sample near, center, and outer branch platforms. Deck
            -- materials are cosmetic; their true server collision,
            -- geometry, structural material, and hazard tags are intact.
            for _, index in ipairs({1, math.floor(n * 0.5), n}) do
                local platform = platforms:FindFirstChild("Platform" .. index)
                if not platform then
                    platform = platforms:FindFirstChild("Skybridge" .. index)
                end
                local panel = decor:FindFirstChild("PlatformPanel" .. index)
                expect(platform ~= nil).toBe(true)
                expect(panel ~= nil).toBe(true)
                expect(platform.Anchored).toBe(true)
                expect(platform.CanCollide).toBe(true)
                expect(panel.Material).toBe(material)
                expect(panel.CanCollide).toBe(false)
                expect(panel.CanTouch).toBe(false)
                expect(panel.CanQuery).toBe(false)
            end
            root:Destroy()
        end
    end)

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
            #ArenaVariants.get("Classic").Platforms + 52
                + #ArenaVariants.get("Classic").PromenadePlatforms
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
            local lobbyFloor = root:FindFirstChild("Lobby"):FindFirstChild("Floor")
            expect(base.Size.X).toBe(320)
            expect(base.Size.Z).toBe(320)
            -- Enlarging the arena must NOT swallow the separate lobby.
            -- Keep physical clearance for the external skyline and player
            -- respawns, including its outermost collision/kill envelope.
            local clearGap = (base.Position.Z - base.Size.Z * 0.5)
                - (lobbyFloor.Position.Z + lobbyFloor.Size.Z * 0.5)
            expect(clearGap >= 100).toBe(true)

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
            Harbor = "QuayCraneSpanningBeam",
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
            Harbor = "GantryCrown",
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
            Harbor = "HarborBridgeGlass",
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
            Harbor = 8,
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
            elseif id == "Harbor" then
                expect(names.HarborDrydockFoundation).toBe(true)
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
            Harbor = "HarborLightshipBridge",
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
            Harbor = {"HarborQuayInlay1", "HarborQuayInlay2"},
        }
        local smallCues = {
            Classic = "ClassicEntryChevron1_-1",
            Towers = "TowerAscentChevron1_-1",
            Crossroads = "FluxRouteChevron1_1_-1",
            Orbital = "OrbitalSpoke1",
            Harbor = "DistrictArrow1_1_-1",
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
            expect(#platforms:GetChildren()).toBe(
                original + 52 + #(variant.SkywayPlatforms or {})
                    + #(variant.SpokePlatforms or {})
                    + #(variant.PromenadePlatforms or {})
            )
            -- Continuous floor-to-sky paths are mandatory during a
            -- collapse: the suspended viaduct is not useful if its
            -- approach or exit vanishes underneath stranded survivors.
            local collapsible = DisappearingPlatforms.eligiblePlatforms(
                platforms, {})
            local remaining = {}
            for _, deck in ipairs(collapsible) do
                remaining[deck] = true
                expect(deck:GetAttribute("ChaosPermanentRoute") ~= true)
                    .toBe(true)
            end
            expect(#collapsible >= 8).toBe(true)
            for route = 1, 4 do
                local previous = nil
                for step = 1, ArenaVariants.PerimeterSteps do
                    local number = original + (route - 1) * ArenaVariants.PerimeterSteps + step
                    local platform = platforms:FindFirstChild("Platform" .. number)
                    expect(platform ~= nil).toBe(true)
                    expect(platform.CanCollide).toBe(true)
                    expect(platform.Anchored).toBe(true)
                    expect(platform:GetAttribute("PerimeterRoute")).toBe(route)
                    expect(platform:GetAttribute("PerimeterStep")).toBe(step)
                    expect(platform:GetAttribute("RouteTier")).toBe(math.min(step, 4))
                    expect(platform:GetAttribute("ChaosPermanentRoute") == true)
                        .toBe(step <= 5)
                    expect(remaining[platform] == true).toBe(step > 5)
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
            if id == "Harbor" then
                -- Appended dry-dock routes must remain physical and
                -- progression-ready, without shifting any older deck.
                local startIndex = original + 52
                    + #(variant.SkywayPlatforms or {})
                expect(#variant.SpokePlatforms).toBe(16)
                for route = 1, 4 do
                    local previous = nil
                    for step = 1, 4 do
                        local index = startIndex + (route - 1) * 4 + step
                        local deck = platforms:FindFirstChild("Platform" .. index)
                        expect(deck ~= nil and deck:IsA("BasePart")).toBe(true)
                        expect(deck.Anchored and deck.CanCollide).toBe(true)
                        expect(deck:GetAttribute("HarborSpokeRoute")).toBe(route)
                        expect(deck:GetAttribute("HarborSpokeStep")).toBe(step)
                        expect(deck:GetAttribute("RouteTier")).toBe(step)
                        expect(deck:GetAttribute("ParkourGrade")).toBe(
                            math.min(4, step + 1)
                        )
                        if previous then
                            expect(JumpRouteCueRules.jumpable(previous, deck))
                                .toBe(true)
                            expect(JumpRouteCueRules.nextPhysical(
                                previous, platforms:GetChildren(),
                                base.Position, "Harbor"
                            )).toBe(deck)
                        else
                            local rise = deck.Position.Y
                                + deck.Size.Y * 0.5
                                - (base.Position.Y + base.Size.Y * 0.5)
                            expect(rise >= 1.5 and rise <= 5.2).toBe(true)
                        end
                        if step == 4 then
                            expect(deck:FindFirstChild("HarborDryDockOutpost")
                                :IsA("BillboardGui")).toBe(true)
                            expect(JumpRouteCueRules.nextPhysical(
                                deck, platforms:GetChildren(),
                                base.Position, "Harbor"
                            )).toBe(nil)
                        end
                        previous = deck
                    end
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
            -- On the larger map, extra scenery must be volumetric 3D
            -- yet absolutely incapable of blocking R15 routes or stealing
            -- raycasts/touches from the authoritative disaster floor.
            local districts = decor:FindFirstChild("ArenaDistrictArchitecture3D")
            expect(districts ~= nil and districts:IsA("Folder")).toBe(true)
            expect(districts:GetAttribute("District3DCount")).toBe(16)
            expect(#districts:GetChildren()).toBe(16)
            local profiles = {}
            local sectorCounts = {}
            local sectorSignals = {}
            local physicalSigns = 0
            for _, model in ipairs(districts:GetChildren()) do
                expect(model:IsA("Model")).toBe(true)
                expect(model.ModelStreamingMode).toBe(Enum.ModelStreamingMode.Atomic)
                local profile = model:GetAttribute("DistrictProfile")
                expect(type(profile)).toBe("number")
                expect(profile >= 1 and profile <= 4).toBe(true)
                profiles[profile] = (profiles[profile] or 0) + 1
                local sectorSide = model:GetAttribute("DistrictSide")
                expect(type(sectorSide)).toBe("string")
                expect(({North=true, East=true, South=true, West=true})[sectorSide])
                    .toBe(true)
                sectorCounts[sectorSide] = (sectorCounts[sectorSide] or 0) + 1
                local signal = model:FindFirstChild("RecessedSignal")
                expect(signal ~= nil and signal:IsA("BasePart")).toBe(true)
                -- Roblox can store Color3 attributes and Part.Color with
                -- slightly different floating-point precision. Compare
                -- with a visible-color tolerance, not bitwise equality.
                local savedColor = model:GetAttribute("DistrictWayfindingColor")
                expect(typeof(savedColor)).toBe("Color3")
                local colorError = math.abs(savedColor.R - signal.Color.R)
                    + math.abs(savedColor.G - signal.Color.G)
                    + math.abs(savedColor.B - signal.Color.B)
                assert(colorError < 0.025,
                    "District wayfinding material/attribute mismatch: "
                        .. model.Name .. " error=" .. tostring(colorError))
                if profile == 1 then
                    sectorSignals[sectorSide] = signal.Color
                end
                local surfaceSign = signal:FindFirstChild("DistrictWayfindingSign")
                if profile == 2 then
                    physicalSigns += 1
                    expect(surfaceSign ~= nil
                        and surfaceSign:IsA("SurfaceGui")).toBe(true)
                    expect(surfaceSign.Adornee).toBe(signal)
                    expect(surfaceSign.Face).toBe(Enum.NormalId.Front)
                    expect(surfaceSign.AlwaysOnTop).toBe(false)
                    local plate = surfaceSign:FindFirstChild("SignPlate")
                    local code = plate and plate:FindFirstChild("SectorCode")
                    expect(code ~= nil and code:IsA("TextLabel")).toBe(true)
                    local sectorIndex = ({
                        North = 1, East = 2, South = 3, West = 4,
                    })[sectorSide]
                    expect(code.Text).toBe(
                        sectorSide:sub(1, 1) .. "  /  "
                            .. string.format("%02d", sectorIndex)
                    )
                else
                    -- Exactly one HUD-free architectural sign per side.
                    expect(surfaceSign).toBe(nil)
                end
                local signature = ({
                    "OrbitalSurveyLens", "CabShell", "VentTurbine0",
                    "SignalCrystal",
                })[profile]
                expect(model:FindFirstChild(signature) ~= nil).toBe(true)
                expect(model:GetAttribute("SourceIsOriginal")).toBe(true)
                expect(model:GetAttribute("CosmeticOnly")).toBe(true)
                -- Two readable core door volumes must remain server owned.
                -- Optional Medium/High 3D facade Parts are local-only and
                -- MUST NOT multiply replication across sixteen buildings.
                expect(model:GetAttribute("FacadeVisualVersion")).toBe(1)
                expect(model:GetAttribute("FacadeVariantId")).toBe(id)
                expect(model:GetAttribute("FacadeDetailPieceCount")).toBe(2)
                expect(model:GetAttribute("FacadeOptionalLocalPartBudget")).toBe(6)
                local serviceDoor = model:FindFirstChild("ServiceEntryDoor")
                local serviceRecess = model:FindFirstChild("ServiceEntryRecess")
                expect(serviceDoor ~= nil and serviceDoor:IsA("BasePart")).toBe(true)
                expect(serviceRecess ~= nil and serviceRecess:IsA("BasePart")).toBe(true)
                expect(model:FindFirstChild("ServiceEntryLintel")).toBe(nil)
                expect(model:FindFirstChild("ServiceEntryCanopy")).toBe(nil)
                expect(model:FindFirstChild("PortalHydraulicColumn-1")).toBe(nil)
                expect(model:FindFirstChild("PortalHydraulicColumn1")).toBe(nil)
                local pieces = 0
                local complex = 0
                for _, piece in ipairs(model:GetChildren()) do
                    expect(piece:IsA("BasePart")).toBe(true)
                    pieces += 1
                    if piece:IsA("WedgePart")
                        or piece.Shape == Enum.PartType.Cylinder
                        or piece.Shape == Enum.PartType.Ball then
                        complex += 1
                    end
                    expect(piece.Anchored).toBe(true)
                    expect(piece.CanCollide).toBe(false)
                    expect(piece.CanTouch).toBe(false)
                    expect(piece.CanQuery).toBe(false)
                    expect(piece.CastShadow).toBe(false)
                    expect(math.abs(piece.Position.X - base.Position.X)
                        < base.Size.X * 0.5).toBe(true)
                    expect(math.abs(piece.Position.Z - base.Position.Z)
                        < base.Size.Z * 0.5).toBe(true)
                end
                expect(pieces >= 19).toBe(true)
                expect(complex >= 5).toBe(true)
            end
            for profile = 1, 4 do
                expect(profiles[profile]).toBe(4)
            end
            -- Four navigable sectors now have muted facade hues and
            -- one depth-tested, static, 3D-mounted sign each. No Parts
            -- or dynamic lights are added to the client GPU budget.
            expect(physicalSigns).toBe(4)
            local sides = {"North", "East", "South", "West"}
            for _, side in ipairs(sides) do
                expect(sectorCounts[side]).toBe(4)
                expect(typeof(sectorSignals[side])).toBe("Color3")
            end
            for i = 1, #sides do
                for j = i + 1, #sides do
                    local a, b = sectorSignals[sides[i]], sectorSignals[sides[j]]
                    local difference = math.abs(a.R - b.R)
                        + math.abs(a.G - b.G) + math.abs(a.B - b.B)
                    expect(difference > 0.20).toBe(true)
                end
            end
            local districtArrows = 0
            for _, instance in ipairs(decor:GetChildren()) do
                if instance.Name:match("^DistrictArrow") then
                    districtArrows += 1
                    expect(instance.CanCollide).toBe(false)
                    expect(instance.CanTouch).toBe(false)
                    expect(instance.CanQuery).toBe(false)
                end
            end
            expect(districtArrows).toBe(24)
            for route = 1, 4 do
                for _, point in ipairs({"Entry", "Lookout"}) do
                    local anchor = decor:FindFirstChild(
                        "DistrictWayfinder" .. route .. point
                    )
                    expect(anchor ~= nil).toBe(true)
                    expect(anchor.CanCollide).toBe(false)
                    local label = anchor:FindFirstChild("ObjectiveLabel")
                    expect(label and label:IsA("BillboardGui")).toBe(true)
                    expect(label.MaxDistance <= 90).toBe(true)
                end
            end
            -- New routes must lead to REAL terrain, not decorative dead
            -- ends. Validate all five floor cues, eight climb cues and
            -- 3D landmarks in every one of the four districts.
            for route = 1, 4 do
                local firstIndex = (route - 1) * ArenaVariants.PerimeterSteps
                local entry = variant.PerimeterPlatforms[firstIndex + 1]
                local finalPlatformIndex = original + firstIndex
                    + ArenaVariants.PerimeterSteps
                for step = 1, 5 do
                    for side = -1, 1, 2 do
                        local cue = decor:FindFirstChild(
                            "OuterRouteChevron" .. route .. "_" .. step
                                .. "_" .. tostring(side)
                        )
                        expect(cue ~= nil and cue:IsA("BasePart")).toBe(true)
                        expect(cue:GetAttribute("ChaosWayfinding")).toBe(true)
                        expect(cue.CanCollide).toBe(false)
                        expect(cue.CanTouch).toBe(false)
                        expect(cue.CanQuery).toBe(false)
                        local localPosition = cue.Position - Config.ArenaCenter
                        expect(localPosition.X * entry.offset.X > 0).toBe(true)
                        expect(localPosition.Z * entry.offset.Z > 0).toBe(true)
                        expect(math.abs(localPosition.X)
                            < math.abs(entry.offset.X) + 2).toBe(true)
                        expect(math.abs(localPosition.Z)
                            < math.abs(entry.offset.Z) + 2).toBe(true)
                    end
                end
                for step = 1, ArenaVariants.PerimeterSteps do
                    local platformIndex = original + firstIndex + step
                    local deck = platforms:FindFirstChild(
                        "Platform" .. platformIndex
                    )
                    for side = -1, 1, 2 do
                        local cue = decor:FindFirstChild(
                            "OuterStepChevron" .. route .. "_" .. step
                                .. "_" .. tostring(side)
                        )
                        expect(cue ~= nil and cue:IsA("BasePart")).toBe(true)
                        expect(cue:GetAttribute("PerimeterPlatformIndex"))
                            .toBe(platformIndex)
                        expect(cue:GetAttribute("ChaosWayfinding")).toBe(true)
                        expect(cue.CanCollide).toBe(false)
                        expect(math.abs(cue.Position.Y
                            - (deck.Position.Y + deck.Size.Y * 0.5 + 0.07))
                            < 0.001).toBe(true)
                    end
                end
                for _, suffix in ipairs({"", "Lens", "Crown"}) do
                    local signal = decor:FindFirstChild(
                        "OuterRouteSignal" .. suffix .. route
                    )
                    expect(signal ~= nil and signal:IsA("BasePart")).toBe(true)
                    expect(signal:GetAttribute("PerimeterPlatformIndex"))
                        .toBe(finalPlatformIndex)
                    expect(signal.CanCollide).toBe(false)
                    expect(signal.CanTouch).toBe(false)
                    expect(signal.CanQuery).toBe(false)
                    expect(signal.CastShadow).toBe(false)
                end
            end
            -- The same authoritative folder is inspected by AI, shrinking,
            -- platform collapse, collectibles and native raycasts.
            root:Destroy()
        end
    end)

    it("builds four real ridge-to-lookout escape crosslinks per arena", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            expect(#variant.CrosslinkPlatforms).toBe(4)
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local decor = arena:FindFirstChild("Decor")
            local base = arena:FindFirstChild("Base")
            local originalCount = #variant.Platforms
            local branchEnd = originalCount + #variant.PerimeterPlatforms
                + #variant.BranchPlatforms
            local all = platforms:GetChildren()
            expect(#all).toBe(
                branchEnd + 4 + #(variant.SkywayPlatforms or {})
                    + #(variant.SpokePlatforms or {})
                    + #(variant.PromenadePlatforms or {})
            )

            for route = 1, 4 do
                local ridge6 = platforms:FindFirstChild("Platform" .. (
                    originalCount + (route - 1) * 8 + 6))
                local ridge7 = platforms:FindFirstChild("Platform" .. (
                    originalCount + (route - 1) * 8 + 7))
                local side2 = platforms:FindFirstChild("Platform" .. (
                    originalCount + 32 + (route - 1) * 4 + 2))
                local connectorIndex = branchEnd + route
                local crossing = platforms:FindFirstChild(
                    "Platform" .. connectorIndex
                )
                local panel = decor:FindFirstChild(
                    "PlatformPanel" .. connectorIndex
                )
                expect(crossing ~= nil).toBe(true)
                expect(panel ~= nil and panel.CanCollide == false).toBe(true)
                expect(crossing.Anchored).toBe(true)
                expect(crossing.CanCollide).toBe(true)
                expect(crossing:GetAttribute("CrosslinkRoute")).toBe(route)
                expect(crossing:GetAttribute("CrosslinkFromPerimeterStep"))
                    .toBe(6)
                expect(crossing:GetAttribute("CrosslinkToBranchStep"))
                    .toBe(2)
                expect(crossing:GetAttribute("RouteTier")).toBe(4)
                expect(math.abs(
                    crossing.Position.Y - crossing.Size.Y * 0.5
                    - (base.Position.Y + base.Size.Y * 0.5)
                ) < 0.001).toBe(true)
                local firstGap = JumpRouteCueRules.gap(ridge6, crossing)
                local secondGap = JumpRouteCueRules.gap(crossing, side2)
                expect(firstGap > 0.15 and firstGap <= 3.85).toBe(true)
                expect(secondGap > 0.15 and secondGap <= 3.85).toBe(true)
                expect(JumpRouteCueRules.jumpable(ridge6, crossing)).toBe(true)
                expect(JumpRouteCueRules.jumpable(crossing, side2)).toBe(true)

                local forward, detour = JumpRouteCueRules.crosslinkOptions(
                    ridge6, all
                )
                expect(forward).toBe(ridge7)
                expect(detour).toBe(crossing)
                expect(JumpRouteCueRules.nextPhysical(
                    ridge6, all, Config.ArenaCenter, id
                )).toBe(ridge7)
                expect(JumpRouteCueRules.nextPhysical(
                    crossing, all, Config.ArenaCenter, id
                )).toBe(side2)

                -- Real collapsing terrain must not be advertised as a
                -- route; the crossing remains a physically valid bypass.
                ridge7:SetAttribute("CollapsePhase", "Warning")
                expect(JumpRouteCueRules.nextPhysical(
                    ridge6, all, Config.ArenaCenter, id
                )).toBe(crossing)
                crossing:SetAttribute("CollapsePhase", "Warning")
                expect(JumpRouteCueRules.nextPhysical(
                    ridge6, all, Config.ArenaCenter, id
                )).toBe(nil)
                ridge7:SetAttribute("CollapsePhase", nil)
                expect(JumpRouteCueRules.nextPhysical(
                    ridge6, all, Config.ArenaCenter, id
                )).toBe(ridge7)
                crossing:SetAttribute("CollapsePhase", nil)

                ridge7.CanCollide = false
                expect(JumpRouteCueRules.nextPhysical(
                    ridge6, all, Config.ArenaCenter, id
                )).toBe(crossing)
                ridge7.CanCollide = true
                side2.CanCollide = false
                expect(JumpRouteCueRules.nextPhysical(
                    crossing, all, Config.ArenaCenter, id
                )).toBe(nil)
                side2.CanCollide = true
                expect(JumpRouteCueRules.nextPhysical(
                    crossing, all, Config.ArenaCenter, id
                )).toBe(side2)
            end
            root:Destroy()
        end
    end)

    it("guides rookie parkour only between currently jumpable physical platforms", function()
        for _, variantId in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(variantId)
            local root = MapBuilder.build(Config, variantId, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local originals = #variant.Platforms
            local perimeterEnd = originals + #variant.PerimeterPlatforms
            local pieces = platforms:GetChildren()

            for route = 1, 4 do
                -- The first seven perimeter jumps must lead to the next
                -- REAL collidable deck; never a location invented by a GUI.
                for step = 1, ArenaVariants.PerimeterSteps - 1 do
                    local number = originals
                        + (route - 1) * ArenaVariants.PerimeterSteps + step
                    local from = platforms:FindFirstChild("Platform" .. number)
                    local to = platforms:FindFirstChild("Platform" .. number + 1)
                    expect(JumpRouteCueRules.jumpable(from, to)).toBe(true)
                    expect(JumpRouteCueRules.nextPhysical(
                        from, pieces, Config.ArenaCenter, variantId
                    )).toBe(to)
                    expect(JumpRouteCueRules.jumpable(to, from)).toBe(false)
                end
                -- A fifth-step perimeter fork has TWO real alternative
                -- landings: continue along the ridge or climb the
                -- orthogonal side lookout. Both respect ordinary R15
                -- rise/gap constraints; collapsing one leaves the other.
                local fork = platforms:FindFirstChild("Platform" .. (
                    originals + (route - 1) * ArenaVariants.PerimeterSteps + 5))
                local forward = platforms:FindFirstChild("Platform" .. (
                    originals + (route - 1) * ArenaVariants.PerimeterSteps + 6))
                local side = platforms:FindFirstChild("Platform" .. (
                    perimeterEnd + (route - 1) * 4 + 1))
                local mainOption, sideOption =
                    JumpRouteCueRules.forkOptions(fork, pieces)
                expect(mainOption).toBe(forward)
                expect(sideOption).toBe(side)
                expect(JumpRouteCueRules.jumpable(fork, side)).toBe(true)
                expect(JumpRouteCueRules.nextPhysical(
                    fork, pieces, Config.ArenaCenter, variantId
                )).toBe(forward)

                -- Disaster warning phases are signaled *before* the
                -- platform loses collision. Favor the playable flank
                -- during an amber ridge collapse, and vice versa.
                forward:SetAttribute("CollapsePhase", "Warning")
                local unsafeForward, safeFlank =
                    JumpRouteCueRules.forkOptions(fork, pieces)
                expect(unsafeForward).toBe(nil)
                expect(safeFlank).toBe(side)
                expect(JumpRouteCueRules.nextPhysical(
                    fork, pieces, Config.ArenaCenter, variantId
                )).toBe(side)
                side:SetAttribute("CollapsePhase", "Warning")
                expect(JumpRouteCueRules.nextPhysical(
                    fork, pieces, Config.ArenaCenter, variantId
                )).toBe(nil)
                forward:SetAttribute("CollapsePhase", nil)
                expect(JumpRouteCueRules.nextPhysical(
                    fork, pieces, Config.ArenaCenter, variantId
                )).toBe(forward)
                side:SetAttribute("CollapsePhase", nil)
                -- If the fork itself is warning, the player must still
                -- see a safe escape rather than being trapped there.
                fork:SetAttribute("CollapsePhase", "Warning")
                expect(JumpRouteCueRules.nextPhysical(
                    fork, pieces, Config.ArenaCenter, variantId
                )).toBe(forward)
                fork:SetAttribute("CollapsePhase", nil)

                forward.CanCollide = false
                expect(JumpRouteCueRules.nextPhysical(
                    fork, pieces, Config.ArenaCenter, variantId
                )).toBe(side)
                forward.CanCollide = true
                side.CanCollide = false
                local availableMain, unavailableSide =
                    JumpRouteCueRules.forkOptions(fork, pieces)
                expect(availableMain).toBe(forward)
                expect(unavailableSide).toBe(nil)
                forward.CanCollide = false
                expect(JumpRouteCueRules.nextPhysical(
                    fork, pieces, Config.ArenaCenter, variantId
                )).toBe(nil)
                forward.CanCollide = true
                side.CanCollide = true
                -- The final outer lookout is still a terminal platform,
                -- not a route back to the beginning.
                local last = platforms:FindFirstChild("Platform" .. (
                    originals + route * ArenaVariants.PerimeterSteps))
                expect(JumpRouteCueRules.nextPhysical(
                    last, pieces, Config.ArenaCenter, variantId
                )).toBe(nil)

                for step = 1, 3 do
                    local number = perimeterEnd + (route - 1) * 4 + step
                    local from = platforms:FindFirstChild("Platform" .. number)
                    local to = platforms:FindFirstChild("Platform" .. number + 1)
                    expect(JumpRouteCueRules.jumpable(from, to)).toBe(true)
                    expect(JumpRouteCueRules.nextPhysical(
                        from, pieces, Config.ArenaCenter, variantId
                    )).toBe(to)
                end
                local lookout = platforms:FindFirstChild("Platform" .. (
                    perimeterEnd + route * 4))
                expect(JumpRouteCueRules.nextPhysical(
                    lookout, pieces, Config.ArenaCenter, variantId
                )).toBe(nil)
            end

            -- Before the first jump, all eight native spawn positions
            -- have a reachable, low original/perimeter entry. No marker
            -- sends new players to a high roof or an unlandable shortcut.
            local base = arena:FindFirstChild("Base")
            local floorY = base.Position.Y + base.Size.Y * 0.5
            for _, offset in ipairs(variant.SpawnOffsets) do
                local feet = Vector3.new(
                    Config.ArenaCenter.X + offset.X, floorY,
                    Config.ArenaCenter.Z + offset.Z
                )
                local entry = JumpRouteCueRules.nearestEntry(pieces, feet, 42)
                expect(entry ~= nil).toBe(true)
                expect(entry:GetAttribute("RouteTier")).toBe(1)
                expect(entry:GetAttribute("BranchRoute")).toBe(nil)
                expect(entry:GetAttribute("PerimeterRoute") == nil
                    or entry:GetAttribute("PerimeterStep") == 1).toBe(true)
                local rise = entry.Position.Y + entry.Size.Y * 0.5 - floorY
                expect(rise >= 1.5 and rise <= 5.2).toBe(true)
                expect(entry.CanCollide).toBe(true)
            end
            expect(JumpRouteCueRules.nearestEntry(pieces, nil, 42)).toBe(nil)
            expect(JumpRouteCueRules.nearestEntry({}, Vector3.zero, 42))
                .toBe(nil)

            local from = platforms:FindFirstChild(
                "Platform" .. (originals + 1))
            local to = platforms:FindFirstChild(
                "Platform" .. (originals + 2))
            expect(from ~= nil and to ~= nil).toBe(true)
            to.CanCollide = false
            expect(JumpRouteCueRules.nextPhysical(
                from, pieces, Config.ArenaCenter, variantId
            )).toBe(nil)
            to.CanCollide = true

            -- Warning starts 1.35 seconds before physical collapse.
            -- Collidability alone is NOT proof that it is safe to land.
            to:SetAttribute("CollapsePhase", "Warning")
            expect(JumpRouteCueRules.safeLandingTarget(to)).toBe(false)
            expect(JumpRouteCueRules.nextPhysical(
                from, pieces, Config.ArenaCenter, variantId
            )).toBe(nil)
            to:SetAttribute("CollapsePhase", "Gone")
            expect(JumpRouteCueRules.safeLandingTarget(to)).toBe(false)
            to:SetAttribute("CollapsePhase", nil)
            expect(JumpRouteCueRules.nextPhysical(
                from, pieces, Config.ArenaCenter, variantId
            )).toBe(to)

            -- Escaping FROM a yellow deck must remain possible. Only
            -- its use as the landing destination is suppressed.
            from:SetAttribute("CollapsePhase", "Warning")
            expect(JumpRouteCueRules.nextPhysical(
                from, pieces, Config.ArenaCenter, variantId
            )).toBe(to)
            -- The first floor-to-platform cue obeys the same rule.
            local floorY = arena:FindFirstChild("Base").Position.Y
                + arena:FindFirstChild("Base").Size.Y * 0.5
            local floorNearStart = Vector3.new(from.Position.X, floorY,
                from.Position.Z)
            expect(JumpRouteCueRules.nearestEntry(
                {from}, floorNearStart, 24
            )).toBe(nil)
            from:SetAttribute("CollapsePhase", nil)
            expect(JumpRouteCueRules.nearestEntry(
                {from}, floorNearStart, 24
            )).toBe(from)

            to.Transparency = 1
            expect(JumpRouteCueRules.nextPhysical(
                from, pieces, Config.ArenaCenter, variantId
            )).toBe(nil)
            to.Transparency = 0

            -- A mistakenly tagged/streamed deck must never bypass
            -- the actual geometry, displacement and height validation.
            to.Position += Vector3.new(15, 0, 0)
            expect(JumpRouteCueRules.nextPhysical(
                from, pieces, Config.ArenaCenter, variantId
            )).toBe(nil)
            to.Position -= Vector3.new(15, 0, 0)
            expect(JumpRouteCueRules.nextPhysical(
                from, pieces, Config.ArenaCenter, variantId
            )).toBe(to)

            expect(JumpRouteCueRules.nextPhysical(
                arena:FindFirstChild("Base"), pieces,
                Config.ArenaCenter, variantId
            )).toBe(nil)
            expect(JumpRouteCueRules.nextPhysical(
                from, {}, Config.ArenaCenter, variantId
            )).toBe(nil)

            root:Destroy()
        end
    end)

end)

return nil
