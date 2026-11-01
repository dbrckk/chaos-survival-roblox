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
    it("builds sixteen physical side lookouts without changing original route indices", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local base = arena:FindFirstChild("Base")
            local start = #variant.Platforms + #variant.PerimeterPlatforms
            expect(#platforms:GetChildren()).toBe(
                start + 20 + #(variant.SkywayPlatforms or {})
                    + #(variant.SpokePlatforms or {})
                    + #(variant.PromenadePlatforms or {})
            )
            for route = 1, 4 do
                local forkIndex = #variant.Platforms
                    + (route - 1) * ArenaVariants.PerimeterSteps + 5
                for side = -1, 1, 2 do
                    local arrow = arena:FindFirstChild("Decor")
                        :FindFirstChild("BranchForkArrow" .. route .. "_"
                            .. tostring(side))
                    expect(arrow ~= nil and arrow:IsA("BasePart")).toBe(true)
                    expect(arrow:GetAttribute("PerimeterPlatformIndex"))
                        .toBe(forkIndex)
                    expect(arrow.CanCollide).toBe(false)
                end
                for step = 1, 4 do
                    local index = start + (route - 1) * 4 + step
                    local deck = platforms:FindFirstChild("Platform" .. index)
                    expect(deck ~= nil and deck:IsA("BasePart")).toBe(true)
                    expect(deck.Anchored).toBe(true)
                    expect(deck.CanCollide).toBe(true)
                    expect(deck:GetAttribute("BranchRoute")).toBe(route)
                    expect(deck:GetAttribute("BranchStep")).toBe(step)
                    expect(deck:GetAttribute("BranchParentStep")).toBe(5)
                    local decor = arena:FindFirstChild("Decor")
                    for side = -1, 1, 2 do
                        local mark = decor:FindFirstChild(
                            "BranchStepArrow" .. route .. "_" .. step
                                .. "_" .. tostring(side)
                        )
                        expect(mark ~= nil and mark:IsA("BasePart")).toBe(true)
                        expect(mark:GetAttribute("PerimeterPlatformIndex"))
                            .toBe(index)
                        expect(mark.CanCollide).toBe(false)
                        expect(mark.CanQuery).toBe(false)
                    end
                    expect(math.abs(deck.Position.Y - deck.Size.Y * 0.5
                        - (base.Position.Y + base.Size.Y * 0.5)) < 0.001)
                        .toBe(true)
                    if step == 4 then
                        local billboard = deck:FindFirstChild("SideLookoutLabel")
                        expect(billboard ~= nil and billboard:IsA("BillboardGui"))
                            .toBe(true)
                        expect(billboard.Adornee).toBe(deck)
                        expect(billboard.MaxDistance <= 80).toBe(true)
                        expect(billboard.AlwaysOnTop).toBe(false)
                    end
                end
            end
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
        local authored = ArenaVariants.get("Towers")
        expect(#(platforms :: Folder):GetChildren()).toBe(
            #authored.Platforms + #authored.PerimeterPlatforms
                + #authored.BranchPlatforms + #authored.CrosslinkPlatforms
                + #authored.PromenadePlatforms
        )
        -- Original 21 decks and Skybridges 18–21 are unchanged.
        -- The outer rim, 16 corner spurs and four physical crosslinks
        -- expand the routes without changing legacy game-system indices.
        expect(tierCount[1]).toBe(9)
        expect(tierCount[2]).toBe(12)
        expect(tierCount[3]).toBe(12)
        expect(tierCount[4]).toBe(36 + #authored.PromenadePlatforms)

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
            #ArenaVariants.get("Crossroads").Platforms + 52
                + #ArenaVariants.get("Crossroads").PromenadePlatforms
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

        -- Source models may have a stale authored/importer WorldPivot.
        -- Moving cloned Parts individually does not repair it automatically.
        -- This intentionally wrong pivot must not reach mounted scenery.
        (sanitized :: Model).WorldPivot = CFrame.new(900, 80, -900)

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
            -- Each arena uses all six approved originals, but repeats two
            -- signature silhouettes for its own eight-slot skyline.
            local expected = if variantId == "Orbital"
                then {orbital_halo_array = 2, perimeter_gate = 2,
                    reactor_spire = 1, sky_transit_exchange = 1,
                    plasma_foundry = 1, service_crane = 1}
                elseif variantId == "Towers"
                then {service_crane = 2, sky_transit_exchange = 2,
                    reactor_spire = 1, perimeter_gate = 1,
                    plasma_foundry = 1, orbital_halo_array = 1}
                elseif variantId == "Crossroads"
                then {perimeter_gate = 2, sky_transit_exchange = 2,
                    plasma_foundry = 1, service_crane = 1,
                    orbital_halo_array = 1, reactor_spire = 1}
                elseif variantId == "Harbor"
                then {service_crane = 2, plasma_foundry = 2,
                    perimeter_gate = 1, sky_transit_exchange = 1,
                    reactor_spire = 1, orbital_halo_array = 1}
                else {perimeter_gate = 2, plasma_foundry = 2,
                    reactor_spire = 1, service_crane = 1,
                    sky_transit_exchange = 1, orbital_halo_array = 1}
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
                    local box, dimensions = placed:GetBoundingBox()
                    expect(dimensions.Y > 0).toBe(true)
                    -- The LOD computes distance with GetPivot(), not
                    -- GetBoundingBox(); both must refer to the *mounted*
                    -- exterior location, never the stale template pivot.
                    local pivot = placed:GetPivot().Position
                    expect(math.abs(pivot.X - box.Position.X) < 0.05)
                        .toBe(true)
                    expect(math.abs(pivot.Z - box.Position.Z) < 0.05)
                        .toBe(true)
                    -- Four supports extend below the original mesh.
                    expect(math.abs(pivot.Y - box.Position.Y) < 8)
                        .toBe(true)
                    expect((pivot - Vector3.new(900, 80, -900)).Magnitude > 400)
                        .toBe(true)
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
                    local builtSupports = 0
                    local validNames = {
                        FoundationShoulder = true, FoundationInset = true,
                        FoundationBallast = true, FoundationGroundPad = true,
                    }
                    for _, support in ipairs(placed:GetChildren()) do
                        if support:GetAttribute("OriginalFoundationVisual") == true then
                            expect(support:IsA("Part")).toBe(true)
                            expect(validNames[support.Name]).toBe(true)
                            builtSupports += 1
                        end
                    end
                    expect(builtSupports).toBe(4)
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


-- The coach uses exact live physical decks and server warning footprints;
-- only its visual optional guidance changes, never a score or collision.
describe("Adaptive premium parkour guidance", function()
    it("shows veteran recovery cues only after a real stall", function()
        local ready = JumpRouteCueRules.recoveryHintReady
        expect(ready(5.2, 0.2, true)).toBe(true)
        expect(ready(4.9, 0, true)).toBe(false)
        expect(ready(15, 4, true)).toBe(false)
        expect(ready(15, 1, false)).toBe(false)
        expect(ready(15, 1, nil)).toBe(false)
        expect(ready(math.huge, 0, true)).toBe(false)
        expect(ready(10, 0 / 0, true)).toBe(false)
        expect(ready(10, -1, true)).toBe(false)
    end)

    it("does not point toward or across a live server meteor or bomb", function()
        local safe = JumpRouteCueRules.safeGuidedPath
        local warning = Instance.new("Part")
        warning.Name = "MeteorWarning"
        warning.Anchored = true
        warning.CanCollide = false
        warning.Size = Vector3.new(3, 0.1, 3)
        warning.Position = Vector3.new(0, 2, 0)
        warning:SetAttribute("WarningEndSize", 24)
        warning.Parent = workspace
        local present = {warning}
        -- Both endpoints are safe, yet the straight jump path crosses the
        -- authoritative FUTURE 24-stud-diameter impact footprint.
        expect(safe(Vector3.new(-24, 5, 0),
            Vector3.new(24, 5, 0), present)).toBe(false)
        expect(safe(Vector3.new(-24, 5, 25),
            Vector3.new(24, 5, 25), present)).toBe(true)
        expect(safe(Vector3.new(0, 5, 0),
            Vector3.new(20, 5, 0), present)).toBe(false)
        expect(safe(Vector3.new(-25, 5, 0),
            Vector3.new(0, 5, 0), present)).toBe(false)
        warning.Name = "BombWarning"
        expect(safe(Vector3.new(-24, 5, 0),
            Vector3.new(24, 5, 0), present)).toBe(false)
        warning.Name = "HarmlessDecoration"
        expect(safe(Vector3.new(-24, 5, 0),
            Vector3.new(24, 5, 0), present)).toBe(true)
        warning:Destroy()
        expect(safe(Vector3.new(-24, 5, 0),
            Vector3.new(24, 5, 0), present)).toBe(true)
        expect(safe(nil, Vector3.zero, {})).toBe(false)
        expect(safe(Vector3.zero, Vector3.zero, nil)).toBe(false)
    end)
end)



return nil
