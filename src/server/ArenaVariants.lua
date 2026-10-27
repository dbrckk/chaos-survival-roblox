local ArenaVariants = {}

ArenaVariants.Order = {"Classic", "Towers", "Crossroads", "Orbital"}

ArenaVariants.Definitions = {
    Classic = {
        Id = "Classic",
        Name = "CLASSIC GRID",
        StrategyHint = "FOLLOW FLOOR ARROWS • CLIMB FOUR ESCAPE ROUTES • SURVIVE TO 0",
        BaseSize = Vector3.new(224, 2, 224),
        BaseColor = Color3.fromRGB(92, 103, 125),
        PlatformColor = Color3.fromRGB(120, 145, 190),
        SpawnOffsets = {
            Vector3.new(-30,3,-30), Vector3.new(30,3,-30),
            Vector3.new(-30,3,30), Vector3.new(30,3,30),
            Vector3.new(0,3,-35), Vector3.new(0,3,35),
            Vector3.new(-35,3,0), Vector3.new(35,3,0),
        },
        -- Four authored ascending zigzag routes, each with genuine jump
        -- gaps and no vertical stacking: entry (+4) -> transfer (+7)
        -- -> elevated turn (+9) -> exposed lookout (+11).
        -- A stacked deck with only 1-3 studs of headroom would TRAP R15
        -- avatars on the lower tier even if a 2D "reachable" check passed.
        -- All routes also preserve every native spawn and Grid Circuit
        -- sensor at (+/-16, +/-16), plus a six-stud outer floor margin.
        -- Platform1 stays high enough for engineered support cosmetics.
        Platforms = {
            -- Tier 3: exposed turn from the cardinal transfer.
            {offset=Vector3.new(39,9,12),size=Vector3.new(10,2,10),RouteTier=3},
            {offset=Vector3.new(-12,9,39),size=Vector3.new(10,2,10),RouteTier=3},
            {offset=Vector3.new(-39,9,-12),size=Vector3.new(10,2,10),RouteTier=3},
            {offset=Vector3.new(12,9,-39),size=Vector3.new(10,2,10),RouteTier=3},
            -- Tier 1: floor-accessible takeoff terraces.
            {offset=Vector3.new(12,4,0),size=Vector3.new(12,2,12),RouteTier=1},
            {offset=Vector3.new(0,4,12),size=Vector3.new(12,2,12),RouteTier=1},
            {offset=Vector3.new(-12,4,0),size=Vector3.new(12,2,12),RouteTier=1},
            {offset=Vector3.new(0,4,-12),size=Vector3.new(12,2,12),RouteTier=1},
            -- Tier 2: lateral takeoffs clear the straight floor-to-entry
            -- corridor. Diagonal jumps are short and well within range.
            {offset=Vector3.new(26,7,12),size=Vector3.new(10,2,10),RouteTier=2},
            {offset=Vector3.new(-12,7,26),size=Vector3.new(10,2,10),RouteTier=2},
            {offset=Vector3.new(-26,7,-12),size=Vector3.new(10,2,10),RouteTier=2},
            {offset=Vector3.new(12,7,-26),size=Vector3.new(10,2,10),RouteTier=2},
            -- Tier 4: turn outward once more for the final exposed lookout.
            -- No spawn pads
            -- or sensor volumes underneath, no inaccessible islands.
            {offset=Vector3.new(39,11,25),size=Vector3.new(10,2,10),RouteTier=4},
            {offset=Vector3.new(-25,11,39),size=Vector3.new(10,2,10),RouteTier=4},
            {offset=Vector3.new(-39,11,-25),size=Vector3.new(10,2,10),RouteTier=4},
            {offset=Vector3.new(25,11,-39),size=Vector3.new(10,2,10),RouteTier=4},
        },
    },

    Towers = {
        Id = "Towers",
        Name = "TOWER RUN",
        StrategyHint = "FOLLOW FLOOR ARROWS • CLIMB TO BRIDGES • SURVIVE TO 0",
        BaseSize = Vector3.new(224, 2, 224),
        BaseColor = Color3.fromRGB(78, 88, 112),
        PlatformColor = Color3.fromRGB(105, 155, 185),
        SpawnOffsets = {
            Vector3.new(-32,3,-32), Vector3.new(32,3,-32),
            Vector3.new(-32,3,32), Vector3.new(32,3,32),
            Vector3.new(0,3,-38), Vector3.new(0,3,38),
            Vector3.new(-38,3,0), Vector3.new(38,3,0),
        },
        Platforms = (function()
            -- Four authored, mirrored ascent circuits. The old Tower Run
            -- stacked three decks at identical X/Z, leaving 4-stud ceiling
            -- voids that R15 avatars could not traverse. Instead, each
            -- actual jump is 1–3.6 studs across and at most 4 studs up.
            -- Order preserves bridge IDs 18–21 for Skyrail/SkybridgePressure.
            local result = {}
            local corners = {
                {-1, -1}, {1, -1}, {-1, 1}, {1, 1},
            }
            for _, signs in ipairs(corners) do
                local x, z = signs[1], signs[2]
                -- Entry top Y=5, reachable directly from the arena floor
                -- and across a half-stud gap from the central safe hub.
                table.insert(result, {
                    offset = Vector3.new(x * 6, 4, z * 14),
                    size = Vector3.new(9, 2, 9),
                    RouteTier = 1,
                })
                -- Destination at bridge elevation. Kept at the original
                -- corner center so each skybridge still overlaps both ends.
                table.insert(result, {
                    offset = Vector3.new(x * 28, 12, z * 28),
                    size = Vector3.new(10, 2, 10),
                    RouteTier = 3,
                })
                -- Offset inward in BOTH axes, clear of the north/west
                -- bridge underpasses and the terminal deck's footprint.
                table.insert(result, {
                    offset = Vector3.new(x * 16, 8, z * 16),
                    size = Vector3.new(9, 2, 9),
                    RouteTier = 2,
                })
            end
            -- Shared playable central platform (not an unreachable roof).
            table.insert(result, {
                offset = Vector3.new(0, 4, 0),
                size = Vector3.new(18, 2, 18),
                RouteTier = 1,
            })
            -- Optional upper lookouts off the terminal decks; no deck
            -- hangs directly over a lower avatar landing area.
            for _, signs in ipairs(corners) do
                table.insert(result, {
                    offset = Vector3.new(signs[1] * 39, 15, signs[2] * 28),
                    size = Vector3.new(8, 2, 8),
                    RouteTier = 4,
                })
            end
            -- Keep exactly four real, fixed 13-stud-high skybridge lanes
            -- with their original index/name/extent for every subsystem.
            table.insert(result, {
                offset = Vector3.new(0, 12.5, -28),
                size = Vector3.new(49, 1, 4.5), Skybridge = true,
            })
            table.insert(result, {
                offset = Vector3.new(0, 12.5, 28),
                size = Vector3.new(49, 1, 4.5), Skybridge = true,
            })
            table.insert(result, {
                offset = Vector3.new(-28, 12.5, 0),
                size = Vector3.new(4.5, 1, 49), Skybridge = true,
            })
            table.insert(result, {
                offset = Vector3.new(28, 12.5, 0),
                size = Vector3.new(4.5, 1, 49), Skybridge = true,
            })
            return result
        end)(),
    },

    Orbital = {
        Id = "Orbital",
        Name = "ORBITAL RING",
        StrategyHint = "FOLLOW ARROWS • USE RAMPS TO REACTOR • SURVIVE TO 0",
        BaseSize = Vector3.new(224, 2, 224),
        BaseColor = Color3.fromRGB(72, 82, 102),
        PlatformColor = Color3.fromRGB(90, 185, 175),
        SpawnOffsets = (function()
            local result = {}
            -- Eight safe entry lanes BETWEEN the outer radial ramps.
            -- The old spawns sat inside 7-9-stud-high outer platforms,
            -- trapping newly spawned R15 avatars before the round began.
            for i = 0, 7 do
                local angle = math.rad(i * 45 + 15)
                table.insert(result, Vector3.new(
                    math.cos(angle) * 42, 3, math.sin(angle) * 42
                ))
            end
            return result
        end)(),
        Platforms = (function()
            local result = {}
            for i = 0, 7 do
                local angle = math.rad(i * 45)
                table.insert(result, {
                    offset = Vector3.new(math.cos(angle) * 31, 4, math.sin(angle) * 31),
                    size = Vector3.new(13, 2, 13),
                    RouteTier = 1,
                })
            end
            for i = 0, 7 do
                local angle = math.rad((i * 45) + 22.5)
                table.insert(result, {
                    offset = Vector3.new(math.cos(angle) * 18, 9 + (i % 2), math.sin(angle) * 18),
                    size = Vector3.new(11, 2, 11),
                    RouteTier = 2,
                })
            end
            -- Ground-accessible central rescue hub and elevated reactor podium.
            -- The 14-stud clear gap between them admits full-size R15 rigs;
            -- every inner lane also has a physical spoke to the upper core.
            table.insert(result, {
                offset = Vector3.new(0, 4, 0),
                size = Vector3.new(18, 2, 18),
                RouteTier = 1,
            })
            table.insert(result, {
                offset = Vector3.new(0, 18, 0),
                size = Vector3.new(11, 2, 11),
                RouteTier = 4,
            })
            return result
        end)(),
    },

    Crossroads = {
        Id = "Crossroads",
        Name = "CROSSROADS",
        StrategyHint = "FOLLOW FLOOR ARROWS • CLIMB THE SWITCHBACKS • SURVIVE TO 0",
        BaseSize = Vector3.new(224, 2, 224),
        BaseColor = Color3.fromRGB(86, 96, 110),
        PlatformColor = Color3.fromRGB(155, 125, 185),
        SpawnOffsets = {
            Vector3.new(-36,3,-18), Vector3.new(-36,3,18),
            Vector3.new(36,3,-18), Vector3.new(36,3,18),
            Vector3.new(-18,3,-36), Vector3.new(18,3,-36),
            Vector3.new(-18,3,36), Vector3.new(18,3,36),
        },
        Platforms = {
            -- The central junction is reachable from the floor without
            -- a dash or mobility purchase, even on standard R15 jump.
            {offset=Vector3.new(0,4,0),size=Vector3.new(18,2,18),RouteTier=1},
            -- Four independent routes from hub to inner and outer stations.
            {offset=Vector3.new(-18,7,0),size=Vector3.new(14,2,12),RouteTier=1},
            {offset=Vector3.new(-34,10,0),size=Vector3.new(12,2,12),RouteTier=2},
            {offset=Vector3.new(18,7,0),size=Vector3.new(14,2,12),RouteTier=1},
            {offset=Vector3.new(34,10,0),size=Vector3.new(12,2,12),RouteTier=2},
            {offset=Vector3.new(0,7,-18),size=Vector3.new(12,2,14),RouteTier=1},
            {offset=Vector3.new(0,10,-34),size=Vector3.new(12,2,12),RouteTier=2},
            {offset=Vector3.new(0,7,18),size=Vector3.new(12,2,14),RouteTier=1},
            {offset=Vector3.new(0,10,34),size=Vector3.new(12,2,12),RouteTier=2},

            -- Each outer arm now branches to ONE assigned high sector:
            -- west -> NW, north -> NE, east -> SE, south -> SW.
            -- Older diagonal decks at (+/-25,+/-25) were 14 studs
            -- horizontally beyond the nearest approach and unreachable.
            {offset=Vector3.new(-25,13,-12),size=Vector3.new(10,2,10),RouteTier=3},
            {offset=Vector3.new(12,13,-25),size=Vector3.new(10,2,10),RouteTier=3},
            {offset=Vector3.new(25,13,12),size=Vector3.new(10,2,10),RouteTier=3},
            {offset=Vector3.new(-12,13,25),size=Vector3.new(10,2,10),RouteTier=3},

            -- Finish each branch with a true three-stud horizontal jump
            -- and four-stud vertical rise, not an unlandable roof.
            {offset=Vector3.new(-12,17,-12),size=Vector3.new(10,2,10),RouteTier=4},
            {offset=Vector3.new(12,17,-12),size=Vector3.new(10,2,10),RouteTier=4},
            {offset=Vector3.new(12,17,12),size=Vector3.new(10,2,10),RouteTier=4},
            {offset=Vector3.new(-12,17,12),size=Vector3.new(10,2,10),RouteTier=4},
        },
    },
}


-- Mega-arena design: 224 x 224 = 2.1x the original floor area.
-- Keep every core authored platform and bridge ID intact. Extend each
-- physically walkable perimeter ladder from two to FOUR ground-supported
-- steps: an actual destination on the new outskirts, not empty dead space.
-- These Parts remain under the authoritative Platforms folder for hazards,
-- AI, collectibles, platform loss and death physics.
local perimeterLocations = {
    Classic = {entryX = 49, entryZ = 49, outerX = 62, outerZ = 49},
    Towers = {entryX = 50, entryZ = 46, outerX = 63, outerZ = 46},
    Crossroads = {entryX = 51, entryZ = 48, outerX = 64, outerZ = 48},
    Orbital = {entryX = 46, entryZ = 46, outerX = 60, outerZ = 54},
}

for _, variantId in ipairs(ArenaVariants.Order) do
    local variant = ArenaVariants.Definitions[variantId]
    local positions = perimeterLocations[variantId]
    local routes = {}
    local quadrants = {{-1,-1}, {1,-1}, {-1,1}, {1,1}}
    for route, signs in ipairs(quadrants) do
        local sx, sz = signs[1], signs[2]
        -- The bases TOUCH the arena floor. No new 2–4 stud "crawling
        -- underneath the platform" trap, and no physics changes are
        -- needed to ascend the first 3-stud floor step.
        table.insert(routes, {
            offset = Vector3.new(sx * positions.entryX, 2.5,
                sz * positions.entryZ),
            size = Vector3.new(12, 3, 12),
            RouteTier = 1,
            PerimeterRoute = route,
            PerimeterStep = 1,
        })
        -- The next three destinations all grow UP FROM THE FLOOR,
        -- avoiding low roofs under which an R15 rig could become stuck.
        -- One cardinal coordinate stays fixed; the other advances in
        -- 13-stud jumps (1-stud lip gap; 3.6-stud rise each time).
        -- Final blocks end at <= 95 studs inside the 112-stud half-floor,
        -- leaving a wide clear edge for Shrinking Arena mechanics.
        for step = 2, 4 do
            table.insert(routes, {
                offset = Vector3.new(
                    sx * (positions.outerX + (step - 2) * 13),
                    4.3 + (step - 2) * 1.8,
                    sz * positions.outerZ
                ),
                size = Vector3.new(12, 6.6 + (step - 2) * 3.6, 12),
                RouteTier = step,
                PerimeterRoute = route,
                PerimeterStep = step,
            })
        end
    end
    variant.PerimeterPlatforms = routes
end

local legacyRecent = {}

function ArenaVariants.get(id)
    return ArenaVariants.Definitions[id]
end

-- Server metadata may only be sourced from a live Arena belonging to the
-- currently tracked GeneratedMap, and never from a not-yet-ready default.
-- Kept pure so the existing Open Cloud arena tests can exercise late
-- attributes and removed/replaced folders without running server scripts.
function ArenaVariants.activeDefinition(arena, generated)
    if typeof(arena) ~= "Instance" or typeof(generated) ~= "Instance"
        or arena.Parent ~= generated or not arena:IsA("Folder")
        or arena.Name ~= "Arena" or generated.Name ~= "GeneratedMap" then
        return nil
    end
    local id = arena:GetAttribute("VariantId")
    if type(id) ~= "string" or id == "" then
        return nil
    end
    return ArenaVariants.get(id)
end

function ArenaVariants.chooseRecent(recentIds)
    local excluded = {}
    for _, id in ipairs(recentIds or {}) do
        excluded[id] = true
    end

    local candidates = {}
    for _, id in ipairs(ArenaVariants.Order) do
        if not excluded[id] then
            table.insert(candidates, id)
        end
    end

    if #candidates == 0 then
        candidates = table.clone(ArenaVariants.Order)
    end

    return candidates[math.random(1, #candidates)]
end

function ArenaVariants.pushRecent(recentIds, id, limit)
    local result = {id}
    for _, previous in ipairs(recentIds or {}) do
        if previous ~= id and #result < (limit or 2) then
            table.insert(result, previous)
        end
    end
    return result
end

function ArenaVariants.choose(previousId)
    if previousId then
        legacyRecent = ArenaVariants.pushRecent(legacyRecent, previousId, 2)
    end

    local chosen = ArenaVariants.chooseRecent(legacyRecent)
    legacyRecent = ArenaVariants.pushRecent(legacyRecent, chosen, 2)
    return chosen
end

return ArenaVariants
