--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaVariants = require("../../src/server/ArenaVariants")
local ArenaTargeting = require("../../src/server/ArenaTargeting")
local OriginalMeshScenery = require("../../src/server/OriginalMeshScenery")
local GridCircuitRules = require("../../src/shared/GridCircuitRules")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
local JumpRouteCueRules = require("../../src/shared/JumpRouteCueRules")

describe("Arena variants", function()
    it("recovers safe imported 3D after late maps, arena swaps and full map rebuilds", function()
        local world = Instance.new("Folder")
        world.Name = "TransientWorldTest"
        local ready = {}
        local stop = OriginalMeshScenery.observeWorld(world, function(arena)
            ready[#ready + 1] = arena
        end)
        local function createArena(generated)
            local arena = Instance.new("Folder")
            arena.Name = "Arena"
            arena.Parent = generated
            return arena
        end
        local function finish(arena)
            local base = Instance.new("Part")
            base.Name = "Base"
            base.Parent = arena
            local decor = Instance.new("Folder")
            decor.Name = "Decor"
            decor.Parent = arena
        end

        local originalMap = Instance.new("Folder")
        originalMap.Name = "GeneratedMap"
        originalMap.Parent = world
        local a = createArena(originalMap)
        task.wait(0.03)
        expect(#ready).toBe(0) -- no callback on half-built arena
        finish(a)
        task.wait(0.05)
        expect(#ready).toBe(1)
        expect(ready[1]).toBe(a)

        local b = createArena(originalMap)
        finish(b)
        task.wait(0.03)
        expect(#ready).toBe(1) -- old Arena remains canonical
        a:Destroy()
        task.wait(0.05)
        expect(#ready).toBe(2)
        expect(ready[2]).toBe(b)

        local replacement = Instance.new("Folder")
        replacement.Name = "GeneratedMap"
        replacement.Parent = world
        local c = createArena(replacement)
        finish(c)
        task.wait(0.03)
        expect(#ready).toBe(2) -- original map remains canonical
        originalMap:Destroy()
        task.wait(0.05)
        expect(#ready).toBe(3)
        expect(ready[3]).toBe(c)

        stop()
        stop() -- idempotent teardown
        local d = createArena(replacement)
        finish(d)
        c:Destroy()
        task.wait(0.05)
        expect(#ready).toBe(3)
        world:Destroy()
    end)

    it("moves optional imported assets away from a previously placed mesh", function()
        local variant = ArenaVariants.get("Classic")
        local base = Instance.new("Part")
        base.Anchored = true
        base.Size = variant.BaseSize
        base.Position = Vector3.new(24, 4, 37)

        local placement = OriginalMeshScenery.placements(base, "Classic")[1]
        local size = Vector3.new(58, 25, 38)
        local starting = OriginalMeshScenery.safeExteriorPosition(base, placement, size)
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        local bucket = Instance.new("Folder")
        bucket.Name = "Original3DScenery"
        bucket.Parent = decor

        local mounted = Instance.new("Model")
        mounted.Name = "EarlierApprovedMesh"
        mounted:SetAttribute("CosmeticOnly", true)
        mounted:SetAttribute("Original3DAssetId", 135985134195364)
        mounted.Parent = bucket
        local occupied = Instance.new("Part")
        occupied.Size = Vector3.new(60, 25, 44)
        occupied.CFrame = CFrame.new(starting)
        occupied.Anchored = true
        occupied.Parent = mounted

        local selected = OriginalMeshScenery.unobstructedExteriorPosition(
            base, placement, size, decor
        )
        expect(selected ~= nil).toBe(true)
        expect((selected - starting).Magnitude > 1).toBe(true)
        local dx = math.abs(selected.X - starting.X)
        local dz = math.abs(selected.Z - starting.Z)
        expect(dx >= (size.X + occupied.Size.X) * 0.5 + 3.9
            or dz >= (size.Z + occupied.Size.Z) * 0.5 + 3.9).toBe(true)

        -- Changing the load order or preloading the owner must not make
        -- the same occupied slot suddenly appear free.
        expect(OriginalMeshScenery.unobstructedExteriorPosition(
            base, placement, size, decor
        )).toBe(selected)

        decor:Destroy()
        base:Destroy()
    end)

    it("positions all original 3D models entirely beyond the live arena floor", function()
        local sizes = {
            Vector3.new(65, 40, 65),
            Vector3.new(48, 60, 16),
            Vector3.new(16, 60, 48),
        }
        for _, variantId in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(variantId)
            local base = Instance.new("Part")
            base.Anchored = true
            base.Size = variant.BaseSize
            base.Position = Vector3.new(18, 4, -34)
            local positions = OriginalMeshScenery.placements(base, variantId)
            expect(#positions).toBe(4)
            local palette = {}
            for _, placement in ipairs(positions) do
                expect(type(placement.assetId)).toBe("number")
                expect(placement.assetId > 0).toBe(true)
                palette[placement.asset] = true
            end
            if variantId == "Classic" then
                expect(palette.plasma_foundry).toBe(true)
            elseif variantId == "Towers" then
                expect(palette.sky_transit_exchange).toBe(true)
            elseif variantId == "Crossroads" then
                expect(palette.plasma_foundry).toBe(true)
                expect(palette.sky_transit_exchange).toBe(true)
            else
                expect(palette.orbital_halo_array).toBe(true)
            end
            for _, placement in ipairs(positions) do
                for _, size in ipairs(sizes) do
                    local safe = OriginalMeshScenery.safeExteriorPosition(
                        base, placement, size
                    )
                    expect(safe ~= nil).toBe(true)
                    local yaw = placement.yaw
                    local radiusX = (
                        math.abs(math.cos(yaw)) * size.X
                        + math.abs(math.sin(yaw)) * size.Z
                    ) * 0.5
                    local radiusZ = (
                        math.abs(math.cos(yaw)) * size.Z
                        + math.abs(math.sin(yaw)) * size.X
                    ) * 0.5
                    if placement.axis == "X" then
                        local distance = (safe.X - base.Position.X) * placement.sign
                            - radiusX - base.Size.X * 0.5
                        expect(distance >= 12.49).toBe(true)
                        expect(safe.Z).toBe(placement.position.Z)
                    else
                        local distance = (safe.Z - base.Position.Z) * placement.sign
                            - radiusZ - base.Size.Z * 0.5
                        expect(distance >= 12.49).toBe(true)
                        expect(safe.X).toBe(placement.position.X)
                    end
                    expect(safe.Y).toBe(placement.position.Y)
                end
            end
            base:Destroy()
        end

        local base = Instance.new("Part")
        base.Size = Vector3.new(150, 2, 150)
        local valid = OriginalMeshScenery.placements(base, "Classic")[1]
        expect(OriginalMeshScenery.safeExteriorPosition(
            base, valid, Vector3.new(66, 8, 8)
        )).toBe(nil)
        expect(OriginalMeshScenery.safeExteriorPosition(
            base, valid, Vector3.new(8, 8, 8)) ~= nil).toBe(true)
        expect(OriginalMeshScenery.safeExteriorPosition(
            base, {position = valid.position, axis = "Y", sign = 1, yaw = 0},
            Vector3.new(8, 8, 8)
        )).toBe(nil)
        base:Destroy()
    end)

    it("mounts sanitized original 3D art with no overlap or physical hazard", function()
        local footprints = {
            service_crane = Vector3.new(60, 48, 20),
            perimeter_gate = Vector3.new(58, 25, 38),
            reactor_spire = Vector3.new(30, 62, 30),
            plasma_foundry = Vector3.new(30, 28, 14),
            sky_transit_exchange = Vector3.new(32, 28, 15),
            orbital_halo_array = Vector3.new(23, 31, 12),
        }
        local templates = {}
        for name, size in pairs(footprints) do
            local asset = Instance.new("Model")
            asset.Name = name
            local mesh = Instance.new("Part")
            mesh.Name = "ImportedGeometry"
            mesh.Size = size
            mesh.Anchored = false
            mesh.Parent = asset
            local ignoredLight = Instance.new("PointLight")
            ignoredLight.Parent = mesh
            local clean = OriginalMeshScenery.sanitize(asset)
            asset:Destroy()
            expect(clean ~= nil).toBe(true)
            expect(clean:FindFirstChild("PointLight", true)).toBe(nil)
            templates[name] = clean
        end

        for _, id in ipairs(ArenaVariants.Order) do
            local arena = Instance.new("Model")
            arena.Name = "Original3DTestArena"
            arena:SetAttribute("VariantId", id)
            arena.Parent = workspace
            local base = Instance.new("Part")
            base.Name = "Base"
            base.Anchored = true
            base.Size = ArenaVariants.get(id).BaseSize
            base.Position = Vector3.new(41, 5, -26)
            base.Parent = arena
            local decor = Instance.new("Folder")
            decor.Name = "Decor"
            decor.Parent = arena

            expect(OriginalMeshScenery.mount(arena, templates)).toBe(4)
            expect(OriginalMeshScenery.mount(arena, templates)).toBe(0)
            expect(arena:GetAttribute("Original3DSceneryComplete")).toBe(true)
            local folder = decor:FindFirstChild("Original3DScenery")
            expect(#folder:GetChildren()).toBe(4)
            for _, placement in ipairs(OriginalMeshScenery.placements(base, id)) do
                local model = folder:FindFirstChild(placement.name)
                expect(model ~= nil).toBe(true)
                expect(model:GetAttribute("OriginalFoundationBuilt")).toBe(true)
                for _, name in ipairs({"FoundationShoulder", "FoundationInset",
                    "FoundationBallast", "FoundationGroundPad"}) do
                    local support = model:FindFirstChild(name)
                    expect(support ~= nil and support:IsA("BasePart")).toBe(true)
                    if support and support:IsA("BasePart") then
                        expect(support.CanCollide).toBe(false)
                        expect(support.CanTouch).toBe(false)
                        expect(support.CanQuery).toBe(false)
                        expect(support.CastShadow).toBe(false)
                        -- Supports are no wider than the actual imported
                        -- mesh and therefore cannot cross its safe gap.
                        expect(support.Size.X <= footprints[placement.asset].X).toBe(true)
                        expect(support.Size.Z <= footprints[placement.asset].Z).toBe(true)
                        local ground = base.Position.Y + base.Size.Y * 0.5
                        expect(support.Position.Y < ground).toBe(true)
                    end
                end
                for _, piece in ipairs(model:GetDescendants()) do
                    if piece:IsA("BasePart") then
                        expect(piece.Anchored).toBe(true)
                        expect(piece.CanCollide).toBe(false)
                        expect(piece.CanTouch).toBe(false)
                        expect(piece.CanQuery).toBe(false)
                        expect(piece.CastShadow).toBe(false)
                        local worldRadiusX = (
                            math.abs(piece.CFrame.RightVector.X) * piece.Size.X
                            + math.abs(piece.CFrame.UpVector.X) * piece.Size.Y
                            + math.abs(piece.CFrame.LookVector.X) * piece.Size.Z
                        ) * 0.5
                        local worldRadiusZ = (
                            math.abs(piece.CFrame.RightVector.Z) * piece.Size.X
                            + math.abs(piece.CFrame.UpVector.Z) * piece.Size.Y
                            + math.abs(piece.CFrame.LookVector.Z) * piece.Size.Z
                        ) * 0.5
                        local clearance = if placement.axis == "X"
                            then (piece.Position.X - base.Position.X) * placement.sign
                                - worldRadiusX - base.Size.X * 0.5
                            else (piece.Position.Z - base.Position.Z) * placement.sign
                                - worldRadiusZ - base.Size.Z * 0.5
                        expect(clearance >= 12.49).toBe(true)
                    end
                end
            end
            arena:Destroy()
        end
        for _, model in pairs(templates) do
            model:Destroy()
        end
    end)

    it("adds bounded, idempotent industrial footing only to approved original art", function()
        local instance = Instance.new("Model")
        local center = CFrame.new(14, 30, -12) * CFrame.Angles(0, 0.65, 0)
        local size = Vector3.new(32, 28, 15)
        expect(OriginalMeshScenery.addFoundation(
            instance, "sky_transit_exchange", center, size)).toBe(4)
        expect(OriginalMeshScenery.addFoundation(
            instance, "sky_transit_exchange", center, size)).toBe(0)
        expect(#instance:GetChildren()).toBe(4)
        for _, p in ipairs(instance:GetChildren()) do
            expect(p:IsA("BasePart")).toBe(true)
            expect(p.Size.X <= size.X).toBe(true)
            expect(p.Size.Z <= size.Z).toBe(true)
            expect(p.CanCollide).toBe(false)
            expect(p.CanTouch).toBe(false)
            expect(p.CanQuery).toBe(false)
            expect(p.CastShadow).toBe(false)
            local localPosition = center:PointToObjectSpace(p.Position)
            expect(localPosition.Y < -size.Y * 0.5).toBe(true)
        end
        instance:Destroy()
        local invalid = Instance.new("Model")
        expect(OriginalMeshScenery.addFoundation(
            invalid, "unapproved_model", center, size)).toBe(0)
        expect(#invalid:GetChildren()).toBe(0)
        invalid:Destroy()
    end)

    it("defines four distinct playable layouts", function()
        expect(#ArenaVariants.Order).toBe(4)

        local seen = {}
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            expect(variant ~= nil).toBe(true)
            expect(seen[id] == nil).toBe(true)
            seen[id] = true

            expect(#variant.SpawnOffsets >= 8).toBe(true)
            expect(#variant.Platforms >= 14).toBe(true)
            expect(variant.BaseSize.X >= 150).toBe(true)
            expect(variant.BaseSize.Z >= 150).toBe(true)
            -- Preserve the old physical routes and hazard sensors at the
            -- center while providing a much wider safe exploration ring.
            for _, offset in ipairs(variant.SpawnOffsets) do
                expect(math.abs(offset.X) <= variant.BaseSize.X * 0.5 - 5).toBe(true)
                expect(math.abs(offset.Z) <= variant.BaseSize.Z * 0.5 - 5).toBe(true)
            end

            -- The visual jump arrows are generated only for physically
            -- reachable successors, and never for Orbital's real Helix
            -- ramps. Exercise the full live collision-sized authored set.
            local live = Instance.new("Folder")
            live.Name = "ParkourRouteProof"
            local decks = {}
            for index, definition in ipairs(variant.Platforms) do
                local part = Instance.new("Part")
                part.Name = (definition.Skybridge and "Skybridge" or "Platform")
                    .. tostring(index)
                part.Size = definition.size
                part.Position = definition.offset
                part.Anchored = true
                if definition.RouteTier then
                    part:SetAttribute("RouteTier", definition.RouteTier)
                end
                part.Parent = live
                decks[#decks + 1] = part
            end
            local checked = 0
            for _, from in ipairs(decks) do
                local to = JumpRouteCueRules.select(
                    from, decks, Vector3.zero, id
                )
                if to then
                    checked += 1
                    local gap = JumpRouteCueRules.gap(from, to)
                    local rise = to.Position.Y + to.Size.Y * 0.5
                        - from.Position.Y - from.Size.Y * 0.5
                    expect(gap > 0.15 and gap <= JumpRouteCueRules.MaxGap).toBe(true)
                    expect(rise >= -0.05
                        and rise <= JumpRouteCueRules.MaxRise).toBe(true)
                    local frame = JumpRouteCueRules.takeoffFrame(from, to, nil)
                    expect(frame ~= nil).toBe(true)
                    local localPoint = from.CFrame:PointToObjectSpace(frame.Position)
                    expect(math.abs(localPoint.X) <= from.Size.X * 0.5 - 0.7).toBe(true)
                    expect(math.abs(localPoint.Z) <= from.Size.Z * 0.5 - 0.7).toBe(true)
                end
            end
            expect(checked >= (id == "Orbital" and 0 or 8)).toBe(true)
            if id == "Orbital" then
                expect(checked).toBe(0)
            end
            live:Destroy()
        end
    end)

    it("adds four physically walkable exterior routes without moving core systems", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local perimeter = variant.PerimeterPlatforms
            expect(type(perimeter)).toBe("table")
            expect(#perimeter).toBe(8)
            local baseTop = variant.BaseSize.Y * 0.5
            for route = 1, 4 do
                local entry = perimeter[(route - 1) * 2 + 1]
                local outer = perimeter[(route - 1) * 2 + 2]
                expect(entry.PerimeterRoute).toBe(route)
                expect(outer.PerimeterRoute).toBe(route)
                expect(entry.PerimeterStep).toBe(1)
                expect(outer.PerimeterStep).toBe(2)
                expect(entry.RouteTier).toBe(1)
                expect(outer.RouteTier).toBe(2)

                local topEntry = entry.offset.Y + entry.size.Y * 0.5
                local topOuter = outer.offset.Y + outer.size.Y * 0.5
                local belowEntry = entry.offset.Y - entry.size.Y * 0.5
                local belowOuter = outer.offset.Y - outer.size.Y * 0.5
                -- Platforms are solid from the floor up: no R15 could be
                -- trapped underneath the new larger outskirts.
                expect(math.abs(belowEntry - baseTop) < 0.001).toBe(true)
                expect(math.abs(belowOuter - baseTop) < 0.001).toBe(true)
                expect(topEntry - baseTop <= 4).toBe(true)
                expect(topOuter - topEntry > 2).toBe(true)
                expect(topOuter - topEntry <= JumpRouteCueRules.MaxRise).toBe(true)

                local dx = math.max(0, math.abs(outer.offset.X - entry.offset.X)
                    - (outer.size.X + entry.size.X) * 0.5)
                local dz = math.max(0, math.abs(outer.offset.Z - entry.offset.Z)
                    - (outer.size.Z + entry.size.Z) * 0.5)
                local gap = math.sqrt(dx * dx + dz * dz)
                expect(gap > 0.15 and gap <= JumpRouteCueRules.MaxGap).toBe(true)

                local radius = math.max(math.abs(entry.offset.X), math.abs(entry.offset.Z))
                expect(radius >= 45).toBe(true)
                for _, deck in ipairs({entry, outer}) do
                    expect(math.abs(deck.offset.X) + deck.size.X * 0.5
                        <= variant.BaseSize.X * 0.5 - 5).toBe(true)
                    expect(math.abs(deck.offset.Z) + deck.size.Z * 0.5
                        <= variant.BaseSize.Z * 0.5 - 5).toBe(true)
                    for _, spawn in ipairs(variant.SpawnOffsets) do
                        local clearX = math.abs(spawn.X - deck.offset.X)
                            >= deck.size.X * 0.5 + 3.8
                        local clearZ = math.abs(spawn.Z - deck.offset.Z)
                            >= deck.size.Z * 0.5 + 3.8
                        expect(clearX or clearZ).toBe(true)
                    end
                end
            end
        end
    end)

    it("gives Classic four authored, spawn-safe, continuously reachable tiers", function()
        local classic = ArenaVariants.get("Classic")
        local tiers = {{}, {}, {}, {}}
        expect(#classic.Platforms).toBe(16)
        for _, deck in ipairs(classic.Platforms) do
            local tier = deck.RouteTier
            expect(type(tier)).toBe("number")
            expect(tier >= 1 and tier <= 4).toBe(true)
            table.insert(tiers[tier], deck)

            -- A mobile avatar arriving at any native spawn marker must not
            -- materialize inside a high deck, regardless of its height.
            -- Model R15 horizontal dimensions plus a one-stud margin.
            for _, spawn in ipairs(classic.SpawnOffsets) do
                local dx = math.abs(spawn.X - deck.offset.X)
                local dz = math.abs(spawn.Z - deck.offset.Z)
                local clearX = dx > deck.size.X * 0.5 + 3.8
                local clearZ = dz > deck.size.Z * 0.5 + 3.8
                expect(clearX or clearZ).toBe(true)
            end

            -- Grid Circuit is an active floor mechanic at four diagonal
            -- nodes. Elevated decks must not bury their touch sensors:
            -- account for the full 7.2-stud box and an extra buffer.
            for _, node in ipairs(GridCircuitRules.Offsets) do
                local dx = math.abs(node.X - deck.offset.X)
                local dz = math.abs(node.Z - deck.offset.Z)
                local clearX = dx > deck.size.X * 0.5 + 4.1
                local clearZ = dz > deck.size.Z * 0.5 + 4.1
                expect(clearX or clearZ).toBe(true)
            end
        end
        for tier = 1, 4 do expect(#tiers[tier]).toBe(4) end

        -- Four floor-to-entry corridors must stay open to full-height R15
        -- characters; raised transfer decks must not form a low ceiling
        -- between the native spawn and the accessible first terrace.
        local corridors = {
            {x=29,z=0,sx=10,sz=7}, {x=-29,z=0,sx=10,sz=7},
            {x=0,z=29,sx=7,sz=10}, {x=0,z=-29,sx=7,sz=10},
        }
        for i, first in ipairs(classic.Platforms) do
            if first.RouteTier > 1 then
                for _, corridor in ipairs(corridors) do
                    local freeX = math.abs(first.offset.X - corridor.x)
                        >= (first.size.X + corridor.sx) * 0.5
                    local freeZ = math.abs(first.offset.Z - corridor.z)
                        >= (first.size.Z + corridor.sz) * 0.5
                    expect(freeX or freeZ).toBe(true)
                end
            end

            -- A deck directly above another with 1-3 studs of headroom
            -- would trap the player and make an apparent jump unusable.
            for j = i + 1, #classic.Platforms do
                local other = classic.Platforms[j]
                if other.RouteTier ~= first.RouteTier then
                    local separateX = math.abs(first.offset.X - other.offset.X)
                        >= (first.size.X + other.size.X) * 0.5
                    local separateZ = math.abs(first.offset.Z - other.offset.Z)
                        >= (first.size.Z + other.size.Z) * 0.5
                    expect(separateX or separateZ).toBe(true)
                end
            end

            -- Even the final lookouts remain comfortably inside the
            -- walkable floor, never hanging beyond the map boundary.
            expect(math.abs(first.offset.X) + first.size.X * 0.5
                <= classic.BaseSize.X * 0.5 - 5).toBe(true)
            expect(math.abs(first.offset.Z) + first.size.Z * 0.5
                <= classic.BaseSize.Z * 0.5 - 5).toBe(true)
        end

        local baseTop = classic.BaseSize.Y * 0.5
        for _, entry in ipairs(tiers[1]) do
            -- The floor -> starter leap is shorter than a standard jump.
            local top = entry.offset.Y + entry.size.Y * 0.5
            expect(top - baseTop <= 4.5).toBe(true)
        end

        local function canJump(from, target)
            local ascent = target.offset.Y + target.size.Y * 0.5
                - from.offset.Y - from.size.Y * 0.5
            local gapX = math.max(0, math.abs(from.offset.X - target.offset.X)
                - (from.size.X + target.size.X) * 0.5)
            local gapZ = math.max(0, math.abs(from.offset.Z - target.offset.Z)
                - (from.size.Z + target.size.Z) * 0.5)
            return ascent >= 0 and ascent <= 4.5
                and (gapX * gapX + gapZ * gapZ) <= 16
        end

        -- Every advanced deck has an explicit adjacent route from a lower
        -- tier; no decorative platform is an impossible floating island.
        for tier = 2, 4 do
            for _, target in ipairs(tiers[tier]) do
                local reachable = false
                for _, source in ipairs(tiers[tier - 1]) do
                    if canJump(source, target) then
                        reachable = true
                    end
                end
                expect(reachable).toBe(true)
            end
        end
    end)

    it("adds a connected high-route skybridge circuit to the Tower Run arena", function()
        local towers = ArenaVariants.get("Towers")
        local links = {}
        local mid = {}
        for _, entry in ipairs(towers.Platforms) do
            if entry.Skybridge == true then
                table.insert(links, entry)
            elseif entry.offset.Y == 12 then
                table.insert(mid, entry)
            end
        end
        expect(#links).toBe(4)
        expect(#mid).toBe(4)
        for _, bridge in ipairs(links) do
            local top = bridge.offset.Y + bridge.size.Y * 0.5
            expect(math.abs(top - 13) < 0.001).toBe(true)
            expect(math.max(bridge.size.X, bridge.size.Z) >= 49).toBe(true)
            expect(math.min(bridge.size.X, bridge.size.Z) >= 4).toBe(true)
            local aligned = 0
            for _, deck in ipairs(mid) do
                local delta = deck.offset - bridge.offset
                local reachX = deck.size.X * 0.5 + bridge.size.X * 0.5
                local reachZ = deck.size.Z * 0.5 + bridge.size.Z * 0.5
                if math.abs(delta.X) <= reachX and math.abs(delta.Z) <= reachZ then
                    aligned += 1
                end
            end
            expect(aligned).toBe(2)
        end
    end)

    it("keeps all four Tower Run ascent circuits reachable and R15 clear", function()
        local towers = ArenaVariants.get("Towers")
        expect(#towers.Platforms).toBe(21)
        local hub = towers.Platforms[13]
        expect(hub.RouteTier).toBe(1)
        expect(hub.offset.Y + hub.size.Y * 0.5).toBe(5)

        local function boundsGap(a, b)
            local dx = math.max(0, math.abs(a.offset.X - b.offset.X)
                - (a.size.X + b.size.X) * 0.5)
            local dz = math.max(0, math.abs(a.offset.Z - b.offset.Z)
                - (a.size.Z + b.size.Z) * 0.5)
            return math.sqrt(dx * dx + dz * dz)
        end
        local function reachable(from, target)
            local ascent = target.offset.Y + target.size.Y * 0.5
                - from.offset.Y - from.size.Y * 0.5
            return ascent >= 0 and ascent <= 4.05
                and boundsGap(from, target) <= 3.7
        end

        local routes = {}
        for quadrant = 1, 4 do
            local start = towers.Platforms[(quadrant - 1) * 3 + 1]
            local terminal = towers.Platforms[(quadrant - 1) * 3 + 2]
            local transfer = towers.Platforms[(quadrant - 1) * 3 + 3]
            local lookout = towers.Platforms[13 + quadrant]
            expect(start.RouteTier).toBe(1)
            expect(transfer.RouteTier).toBe(2)
            expect(terminal.RouteTier).toBe(3)
            expect(lookout.RouteTier).toBe(4)
            expect(reachable(hub, start)).toBe(true)
            expect(reachable(start, transfer)).toBe(true)
            expect(reachable(transfer, terminal)).toBe(true)
            expect(reachable(terminal, lookout)).toBe(true)
            routes[#routes + 1] = {start, transfer, terminal, lookout}

            -- All floor-entry and outer lookout decks are inside the real
            -- playable base, not hovering beyond the fall boundary.
            for _, deck in ipairs(routes[#routes]) do
                expect(math.abs(deck.offset.X) + deck.size.X * 0.5 <= 43)
                    .toBe(true)
                expect(math.abs(deck.offset.Z) + deck.size.Z * 0.5 <= 43)
                    .toBe(true)
            end
        end

        -- No lower deck may have a solid roof immediately above it.
        -- The old stacked towers had 3-4 studs of avatar headroom.
        for i, deck in ipairs(towers.Platforms) do
            if deck.Skybridge ~= true then
                for j = i + 1, 17 do
                    local other = towers.Platforms[j]
                    if other and other.offset.Y ~= deck.offset.Y then
                        local separateX = math.abs(deck.offset.X - other.offset.X)
                            >= (deck.size.X + other.size.X) * 0.5
                        local separateZ = math.abs(deck.offset.Z - other.offset.Z)
                            >= (deck.size.Z + other.size.Z) * 0.5
                        expect(separateX or separateZ).toBe(true)
                    end
                end
            end
        end

        -- Eight existing spawn slots must keep R15-safe headroom below
        -- elevated destination decks, without client-side teleports.
        for _, spawn in ipairs(towers.SpawnOffsets) do
            for _, deck in ipairs(towers.Platforms) do
                if deck.Skybridge ~= true then
                    local overhead = math.abs(spawn.X - deck.offset.X)
                        < deck.size.X * 0.5 + 2.8
                        and math.abs(spawn.Z - deck.offset.Z)
                        < deck.size.Z * 0.5 + 2.8
                    if overhead then
                        local clearance = deck.offset.Y - deck.size.Y * 0.5
                            - towers.BaseSize.Y * 0.5
                        expect(clearance >= 8.4).toBe(true)
                    end
                end
            end
        end

        -- Preserve bridge identities, world height, and both end landings.
        for index = 18, 21 do
            local link = towers.Platforms[index]
            expect(link.Skybridge).toBe(true)
            expect(link.offset.Y + link.size.Y * 0.5).toBe(13)
            local endpoints = 0
            for _, route in ipairs(routes) do
                local terminal = route[3]
                local dx = math.abs(terminal.offset.X - link.offset.X)
                local dz = math.abs(terminal.offset.Z - link.offset.Z)
                if dx <= (terminal.size.X + link.size.X) * 0.5
                    and dz <= (terminal.size.Z + link.size.Z) * 0.5
                then
                    endpoints += 1
                end
            end
            expect(endpoints).toBe(2)
        end
    end)

    it("keeps every Crossroads upper sector reachable from its assigned lane", function()
        local crossroads = ArenaVariants.get("Crossroads")
        expect(#crossroads.Platforms).toBe(17)

        local function gap(a, b)
            local dx = math.max(0, math.abs(a.offset.X - b.offset.X)
                - (a.size.X + b.size.X) * 0.5)
            local dz = math.max(0, math.abs(a.offset.Z - b.offset.Z)
                - (a.size.Z + b.size.Z) * 0.5)
            return math.sqrt(dx * dx + dz * dz)
        end
        local paths = {
            {1, 2, 3, 10, 14},  -- west -> northwest
            {1, 6, 7, 11, 15},  -- north -> northeast
            {1, 4, 5, 12, 16},  -- east -> southeast
            {1, 8, 9, 13, 17},  -- south -> southwest
        }
        local visited = {}
        for _, path in ipairs(paths) do
            local elevations = {}
            for step, index in ipairs(path) do
                local deck = crossroads.Platforms[index]
                expect(deck ~= nil).toBe(true)
                expect(deck.RouteTier ~= nil).toBe(true)
                local elevation = deck.offset.Y + deck.size.Y * 0.5
                elevations[#elevations + 1] = elevation
                visited[index] = true
                if step > 1 then
                    local prior = crossroads.Platforms[path[step - 1]]
                    local rise = elevation
                        - (prior.offset.Y + prior.size.Y * 0.5)
                    expect(rise >= 0 and rise <= 4).toBe(true)
                    expect(gap(prior, deck) <= 3.05).toBe(true)
                end
            end
            expect(elevations[1]).toBe(5)
            expect(elevations[2]).toBe(8)
            expect(elevations[3]).toBe(11)
            expect(elevations[4]).toBe(14)
            expect(elevations[5]).toBe(18)
        end
        for index = 1, 17 do expect(visited[index]).toBe(true) end

        -- A lower walkway cannot sit directly below a ceiling with
        -- less than the full R15 standing clearance (8.4 studs).
        for index, first in ipairs(crossroads.Platforms) do
            expect(math.abs(first.offset.X) + first.size.X * 0.5 < 48).toBe(true)
            expect(math.abs(first.offset.Z) + first.size.Z * 0.5 < 48).toBe(true)
            for j = index + 1, #crossroads.Platforms do
                local second = crossroads.Platforms[j]
                local overlapX = math.abs(first.offset.X - second.offset.X)
                    < (first.size.X + second.size.X) * 0.5
                local overlapZ = math.abs(first.offset.Z - second.offset.Z)
                    < (first.size.Z + second.size.Z) * 0.5
                if overlapX and overlapZ then
                    local lower = first.offset.Y < second.offset.Y and first or second
                    local upper = lower == first and second or first
                    local clearance = upper.offset.Y - upper.size.Y * 0.5
                        - (lower.offset.Y + lower.size.Y * 0.5)
                    expect(clearance >= 8.4).toBe(true)
                end
            end
        end

        -- No stock arena spawn may be sealed beneath a low crossing.
        for _, spawn in ipairs(crossroads.SpawnOffsets) do
            for _, deck in ipairs(crossroads.Platforms) do
                local overlapsAvatar = math.abs(spawn.X - deck.offset.X)
                    < deck.size.X * 0.5 + 2.8
                    and math.abs(spawn.Z - deck.offset.Z)
                    < deck.size.Z * 0.5 + 2.8
                if overlapsAvatar then
                    local headroom = deck.offset.Y - deck.size.Y * 0.5
                        - crossroads.BaseSize.Y * 0.5
                    expect(headroom >= 8.4).toBe(true)
                end
            end
        end
    end)


    it("connects Orbital spawns, Helix decks and reactor through walkable ramps", function()
        local orbital = ArenaVariants.get("Orbital")
        expect(#orbital.SpawnOffsets).toBe(8)
        expect(#orbital.Platforms).toBe(18)
        local floorTop = orbital.BaseSize.Y * 0.5
        local lowHub = orbital.Platforms[17]
        local reactor = orbital.Platforms[18]
        expect(lowHub.RouteTier).toBe(1)
        expect(reactor.RouteTier).toBe(4)
        local headroom = reactor.offset.Y - reactor.size.Y * 0.5
            - (lowHub.offset.Y + lowHub.size.Y * 0.5)
        expect(headroom >= 8.4).toBe(true)

        local function planarDistanceToRamp(point, ramp)
            local p = Vector3.new(point.X, 0, point.Z)
            local from = Vector3.new(ramp.Start.X, 0, ramp.Start.Z)
            local to = Vector3.new(ramp.Finish.X, 0, ramp.Finish.Z)
            local delta = to - from
            local progress = math.clamp((p - from):Dot(delta) / delta:Dot(delta), 0, 1)
            return (p - from - delta * progress).Magnitude
        end

        for index = 1, OrbitalHelix.Count do
            local outer = orbital.Platforms[index]
            local inner = orbital.Platforms[index + OrbitalHelix.Count]
            local spawn = orbital.SpawnOffsets[index]
            expect(outer.RouteTier).toBe(1)
            expect(inner.RouteTier).toBe(2)
            expect(math.abs(spawn.X) < 44.5 and math.abs(spawn.Z) < 44.5)
                .toBe(true)

            -- No player at any of the eight spawn pads may materialize
            -- under an elevated platform or directly inside an access ramp.
            for _, deck in ipairs(orbital.Platforms) do
                local overlapsX = math.abs(spawn.X - deck.offset.X)
                    < deck.size.X * 0.5 + 2.8
                local overlapsZ = math.abs(spawn.Z - deck.offset.Z)
                    < deck.size.Z * 0.5 + 2.8
                expect(overlapsX and overlapsZ).toBe(false)
            end
            for routeIndex = 1, OrbitalHelix.Count do
                local access = OrbitalHelix.accessRoute(
                    orbital, Vector3.zero, routeIndex, "Entry"
                )
                expect(planarDistanceToRamp(spawn, access)
                    > access.Size.X * 0.5 + 2.8).toBe(true)
            end

            local entry = OrbitalHelix.accessRoute(
                orbital, Vector3.zero, index, "Entry"
            )
            local core = OrbitalHelix.accessRoute(
                orbital, Vector3.zero, index, "Core"
            )
            local helix = OrbitalHelix.route(orbital, Vector3.zero, index)
            expect(entry ~= nil and helix ~= nil and core ~= nil).toBe(true)
            local entryFloor = entry.Start.Y - floorTop
            expect(math.abs(entryFloor + 0.35) < 0.001).toBe(true)

            local function slope(route)
                local horizontal = Vector3.new(
                    route.Finish.X - route.Start.X, 0,
                    route.Finish.Z - route.Start.Z
                ).Magnitude
                return (route.Finish.Y - route.Start.Y) / horizontal
            end
            expect(slope(entry) > 0 and slope(entry) <= 0.76).toBe(true)
            expect(slope(helix) > 0 and slope(helix) <= 0.60).toBe(true)
            expect(slope(core) > 0 and slope(core) <= 0.76).toBe(true)

            local outerTop = outer.offset.Y + outer.size.Y * 0.5
            local innerTop = inner.offset.Y + inner.size.Y * 0.5
            local reactorTop = reactor.offset.Y + reactor.size.Y * 0.5
            expect(math.abs(entry.Finish.Y - (outerTop - 0.35)) < 0.001)
                .toBe(true)
            expect(math.abs(helix.Start.Y - (outerTop - 0.15)) < 0.001)
                .toBe(true)
            expect(math.abs(helix.Finish.Y - (innerTop - 0.15)) < 0.001)
                .toBe(true)
            expect(math.abs(core.Start.Y - (innerTop - 0.35)) < 0.001)
                .toBe(true)
            expect(math.abs(core.Finish.Y - (reactorTop - 0.35)) < 0.001)
                .toBe(true)
            -- The exit from each Helix and the next reactor climb must
            -- join at the same landing, never form a 3-stud-low roof.
            expect((core.Start - helix.Finish).Magnitude <= 0.21).toBe(true)
            -- At the central rescue-hub edge the upper incline leaves
            -- enough space for an R15 avatar standing on the lower deck.
            local innerRadius = Vector3.new(
                inner.offset.X, 0, inner.offset.Z
            ).Magnitude
            local exitRadius = Vector3.new(
                core.Finish.X, 0, core.Finish.Z
            ).Magnitude
            local radialPoint = 8.5
            local at = (innerRadius - radialPoint)
                / (innerRadius - exitRadius)
            local bridgeHeight = core.Start.Y
                + at * (core.Finish.Y - core.Start.Y)
            expect(bridgeHeight - 0.46
                - (lowHub.offset.Y + lowHub.size.Y * 0.5) >= 8.4)
                .toBe(true)
        end
        expect(OrbitalHelix.accessRoute(orbital, Vector3.zero, 9, "Entry"))
            .toBe(nil)
        expect(OrbitalHelix.accessRoute(orbital, Vector3.zero, 1, "Unknown"))
            .toBe(nil)
    end)

    it("derives hazard targeting bounds from arena footprints", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local halfX, halfZ = ArenaTargeting.halfExtents(variant.BaseSize, 6, 42)

            expect(halfX > 0).toBe(true)
            expect(halfZ > 0).toBe(true)
            expect(halfX <= (variant.BaseSize.X * 0.5)).toBe(true)
            expect(halfZ <= (variant.BaseSize.Z * 0.5)).toBe(true)
        end

        local fallbackX, fallbackZ = ArenaTargeting.halfExtents(nil, 6, 42)
        expect(fallbackX).toBe(42)
        expect(fallbackZ).toBe(42)
    end)

    it("keeps overlapping bomb and meteor warnings apart when safe routes exist", function()
        local choose = ArenaTargeting.chooseSeparatedOffset
        local center = Vector3.new(12, 3, -8)
        local occupied = {Vector3.new(12, 50, -8)}
        local near = Vector3.new(3, 0, 0)
        local safe = Vector3.new(24, 0, 0)
        local far = Vector3.new(35, 0, 0)

        -- The vertical separation is intentionally ignored: the danger
        -- rings overlap on the player's X/Z map regardless of deck height.
        expect(choose({near, safe, far}, center, occupied, 22)).toBe(safe)
        expect(choose({near, safe, far}, center, occupied, 30)).toBe(far)
        expect(choose({near, safe}, center, occupied, 40)).toBe(safe)
        expect(choose({near}, center, {}, 22)).toBe(near)
        expect(choose({}, center, occupied, 22)).toBe(Vector3.zero)

        -- With two active hazards a new warning must consider BOTH zones,
        -- not just the most recently spawned marker.
        local paired = {
            Vector3.new(12, 0, -8),
            Vector3.new(52, 0, -8),
        }
        expect(choose({
            Vector3.new(3, 0, 0),
            Vector3.new(40, 0, 0),
            Vector3.new(21, 0, 25),
        }, center, paired, 22)).toBe(Vector3.new(21, 0, 25))

        -- The shared per-round marker set cannot retain destroyed instances;
        -- choosing a new random candidate automatically removes stale keys.
        local dead = Instance.new("Part")
        local pending = {[dead] = true}
        dead:Destroy()
        local offset = ArenaTargeting.randomSeparatedOffset(
            6, 42, center, pending, 22
        )
        expect(typeof(offset)).toBe("Vector3")
        expect(pending[dead] == nil).toBe(true)
    end)

    it("never publishes metadata for a removed or not-yet-ready arena", function()
        local map = Instance.new("Folder")
        map.Name = "GeneratedMap"
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = map

        expect(ArenaVariants.activeDefinition(arena, map)).toBe(nil)
        arena:SetAttribute("VariantId", "Towers")
        expect(ArenaVariants.activeDefinition(arena, map).Id).toBe("Towers")

        arena:SetAttribute("VariantId", "Unknown")
        expect(ArenaVariants.activeDefinition(arena, map)).toBe(nil)
        arena:SetAttribute("VariantId", "Orbital")
        expect(ArenaVariants.activeDefinition(arena, map).Id).toBe("Orbital")

        local replacement = Instance.new("Folder")
        replacement.Name = "GeneratedMap"
        expect(ArenaVariants.activeDefinition(arena, replacement)).toBe(nil)

        arena.Parent = nil
        expect(ArenaVariants.activeDefinition(arena, map)).toBe(nil)
        arena.Parent = replacement
        expect(ArenaVariants.activeDefinition(arena, replacement).Id).toBe("Orbital")

        arena.Name = "OldArena"
        expect(ArenaVariants.activeDefinition(arena, replacement)).toBe(nil)
        arena.Name = "Arena"
        replacement.Name = "RemovedMap"
        expect(ArenaVariants.activeDefinition(arena, replacement)).toBe(nil)

        map:Destroy()
        replacement:Destroy()
    end)

    it("gives every arena concise actionable strategy guidance", function()
        local seenHints = {}
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            expect(type(variant.StrategyHint)).toBe("string")
            expect(#variant.StrategyHint >= 24).toBe(true)
            expect(#variant.StrategyHint <= 96).toBe(true)
            expect(seenHints[variant.StrategyHint] == nil).toBe(true)
            seenHints[variant.StrategyHint] = true
        end
    end)

    it("never immediately repeats a map when alternatives exist", function()
        for _, previous in ipairs(ArenaVariants.Order) do
            for _ = 1, 20 do
                local nextId = ArenaVariants.choose(previous)
                expect(nextId ~= previous).toBe(true)
                expect(ArenaVariants.get(nextId) ~= nil).toBe(true)
            end
        end
    end)

    it("avoids both recently played maps", function()
        for _ = 1, 30 do
            local nextId = ArenaVariants.chooseRecent({"Classic", "Towers"})
            expect(nextId ~= "Classic").toBe(true)
            expect(nextId ~= "Towers").toBe(true)
            expect(ArenaVariants.get(nextId) ~= nil).toBe(true)
        end
    end)

    it("keeps recent history bounded and unique", function()
        local recent = ArenaVariants.pushRecent({"Classic", "Towers"}, "Orbital", 2)
        expect(#recent).toBe(2)
        expect(recent[1]).toBe("Orbital")
        expect(recent[2]).toBe("Classic")

        recent = ArenaVariants.pushRecent(recent, "Classic", 2)
        expect(#recent).toBe(2)
        expect(recent[1]).toBe("Classic")
        expect(recent[2]).toBe("Orbital")
    end)
end)

return nil
