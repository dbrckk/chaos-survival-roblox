--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaVariants = require("../../src/server/ArenaVariants")
local ArenaTargeting = require("../../src/server/ArenaTargeting")
local GridCircuitRules = require("../../src/shared/GridCircuitRules")
local OrbitalHelix = require("../../src/server/OrbitalHelix")

describe("Arena variants", function()
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
            expect(variant.BaseSize.X >= 90).toBe(true)
            expect(variant.BaseSize.Z >= 90).toBe(true)
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
