local ArenaVariants = {}

ArenaVariants.Order = {"Classic", "Towers", "Crossroads", "Orbital", "Harbor"}

-- Actual landing surfaces progress from forgiving first-session geometry
-- to harder late-route precision. Keep center positions, jumps, top
-- heights, decorations and disaster ownership unchanged. This is not a
-- dynamic client scaling trick: every player sees the SAME solid platforms.
local COURSE_WIDTHS = {
    Harbor = {12, 12, 11.6, 11.1, 10.6, 10.1, 9.6},
    Perimeter = {12, 12, 12, 11.6, 11.2, 10.8, 10.4, 10},
    Branch = {12, 12, 11.2, 10.4},
}

function ArenaVariants.parkourFootprint(kind, step)
    if type(step) ~= "number" or step % 1 ~= 0 then return nil, nil end
    local widths = COURSE_WIDTHS[kind]
    if not widths or not widths[step] then return nil, nil end
    local grade = kind == "Branch"
        and (step <= 2 and 3 or 4)
        or math.min(4, math.floor((step + 1) / 2))
    return widths[step], grade
end

ArenaVariants.Definitions = {
    Classic = {
        Id = "Classic",
        Name = "CLASSIC GRID",
        StrategyHint = "FOLLOW FLOOR ARROWS • CLIMB FOUR ESCAPE ROUTES • SURVIVE TO 0",
        BaseSize = Vector3.new(320, 2, 320),
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
        BaseSize = Vector3.new(320, 2, 320),
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
        BaseSize = Vector3.new(320, 2, 320),
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
        BaseSize = Vector3.new(320, 2, 320),
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


-- STORM HARBOR: four ORIGINAL cargo-pier switchbacks, each a genuine
-- seven-deck lane with progressively tighter 1..3.25-stud clear gaps
-- and consistent three-stud rises.
-- Physical zig-zags make the harbor an alternative to the circular
-- reactor and straight perimeter climbs, rather than a fifth recolor.
ArenaVariants.Definitions.Harbor = {
    Id = "Harbor",
    Name = "STORM HARBOR",
    StrategyHint = "CROSS CARGO PIERS • CLIMB STORM GANTRIES • SURVIVE TO 0",
    BaseSize = Vector3.new(320, 2, 320),
    BaseColor = Color3.fromRGB(48, 83, 96),
    PlatformColor = Color3.fromRGB(92, 170, 185),
    SpawnOffsets = {
        Vector3.new(-45, 3, -12), Vector3.new(45, 3, -12),
        Vector3.new(-45, 3, 12), Vector3.new(45, 3, 12),
        Vector3.new(-12, 3, -45), Vector3.new(12, 3, -45),
        Vector3.new(-12, 3, 45), Vector3.new(12, 3, 45),
    },
    Platforms = (function()
        local decks = {}
        local corners = {
            {-1, -1}, {1, -1}, {-1, 1}, {1, 1},
        }
        local turns = {
            {12, 11}, {25, 11}, {25, 24}, {38, 24},
            {38, 37}, {51, 37}, {51, 50},
        }
        for route, signs in ipairs(corners) do
            for step, coords in ipairs(turns) do
                local width, grade = ArenaVariants.parkourFootprint(
                    "Harbor", step
                )
                table.insert(decks, {
                    offset = Vector3.new(
                        signs[1] * coords[1], 4 + (step - 1) * 3,
                        signs[2] * coords[2]
                    ),
                    size = Vector3.new(width, 2, width),
                    RouteTier = math.min(step, 4),
                    ParkourGrade = grade,
                    HarborRoute = route,
                    HarborStep = step,
                })
            end
        end
        return decks
    end)(),
}


-- ORIGINAL HIGH-QUAY CROSSINGS: north and south cargo endpoints previously
-- terminated as isolated level-23 platforms. Two seven-landing, genuinely
-- COLLABORATIVE skyways now connect west and east terminals in both directions.
-- The +/-50 Z corridors run outside the lower Harbor zig-zag rises at +/-37:
-- never place an overhead roof over the working step-five/six takeoff.
-- 12.75 studs between centers, with 9.8..10.5-stud landings gives real
-- 2.25..2.95-stud jump gaps; all top surfaces align at Y +23.
-- Append after every original/outer/branch/crosslink platform identity.
ArenaVariants.Definitions.Harbor.SkywayPlatforms = (function()
    local bridge = {}
    for lane, signedZ in ipairs({-50, 50}) do
        for step = 1, 7 do
            local width = (step == 1 or step == 7) and 10.5 or 9.8
            bridge[#bridge + 1] = {
                offset = Vector3.new(-51 + step * 12.75, 22, signedZ),
                size = Vector3.new(width, 2, width),
                RouteTier = 4,
                ParkourGrade = (step >= 3 and step <= 5) and 4 or 3,
                HarborSkywayLane = lane,
                HarborSkywayStep = step,
            }
        end
    end
    return bridge
end)()


-- Four genuinely PLAYABLE cardinal dock runs make the large open
-- middle of Storm Harbor useful. Each route begins on the arena floor,
-- then climbs through four precise but standard-R15-jumpable landings to
-- a distinct 14-stud-high lookout. Exactly SIXTEEN
-- colliding native decks, not a fake skyline or nonphysical sign.
-- Append AFTER the existing 94 Harbor platforms to preserve all original
-- IDs, bridge/mobility references and skyway mastery indices.
ArenaVariants.Definitions.Harbor.SpokePlatforms = (function()
    local decks = {}
    local directions = {
        {0, -1}, {1, 0}, {0, 1}, {-1, 0},
    }
    local widths = {12, 11.5, 11, 10.5}
    for route, axis in ipairs(directions) do
        for step = 1, 4 do
            local distance = 55 + (step - 1) * 13
            local width = widths[step]
            decks[#decks + 1] = {
                offset = Vector3.new(
                    axis[1] * distance, 4 + (step - 1) * 3,
                    axis[2] * distance
                ),
                size = Vector3.new(width, 2, width),
                RouteTier = step,
                ParkourGrade = math.min(4, step + 1),
                HarborSpokeRoute = route,
                HarborSpokeStep = step,
            }
        end
    end
    return decks
end)()


-- Mega districts: 320 x 320 is 2.04x the preceding 224 x 224 map.
-- Keep the authored central routes and bridge indices unchanged. Eight
-- physical, ground-supported perimeter terraces now lead toward the outer
-- 320-stud boundary rather than terminating in a mostly empty floor.
-- Every route is traversable via standard R15 jumps (1..3-stud gaps
-- and 3.6-stud elevation gains), with no low-ceiling crawl traps underneath.
local perimeterLocations = {
    Classic = {entryX = 49, entryZ = 49, outerX = 62, outerZ = 49},
    Towers = {entryX = 50, entryZ = 46, outerX = 63, outerZ = 46},
    Crossroads = {entryX = 51, entryZ = 48, outerX = 64, outerZ = 48},
    Orbital = {entryX = 46, entryZ = 46, outerX = 60, outerZ = 54},
    Harbor = {entryX = 58, entryZ = 72, outerX = 71, outerZ = 72},
}

ArenaVariants.PerimeterSteps = 8

for _, variantId in ipairs(ArenaVariants.Order) do
    local variant = ArenaVariants.Definitions[variantId]
    local positions = perimeterLocations[variantId]
    local routes = {}
    local quadrants = {{-1,-1}, {1,-1}, {-1,1}, {1,1}}
    for route, signs in ipairs(quadrants) do
        local sx, sz = signs[1], signs[2]
        local entryWidth, entryGrade = ArenaVariants.parkourFootprint(
            "Perimeter", 1
        )
        table.insert(routes, {
            offset = Vector3.new(sx * positions.entryX, 2.5,
                sz * positions.entryZ),
            size = Vector3.new(entryWidth, 3, entryWidth),
            RouteTier = 1,
            ParkourGrade = entryGrade,
            PerimeterRoute = route,
            PerimeterStep = 1,
        })
        for step = 2, ArenaVariants.PerimeterSteps do
            local width, grade = ArenaVariants.parkourFootprint(
                "Perimeter", step
            )
            table.insert(routes, {
                offset = Vector3.new(
                    sx * (positions.outerX + (step - 2) * 13),
                    4.3 + (step - 2) * 1.8,
                    sz * positions.outerZ
                ),
                size = Vector3.new(width, 6.6 + (step - 2) * 3.6, width),
                -- Guidance/visual tiers stay within the existing 1..4 API.
                RouteTier = math.min(step, 4),
                ParkourGrade = grade,
                PerimeterRoute = route,
                PerimeterStep = step,
            })
        end
    end
    variant.PerimeterPlatforms = routes

    -- The 320-stud floor needs real side destinations, not only a wider
    -- empty rectangle around the original four straight escape ladders.
    -- Branch off physical perimeter STEP FIVE toward each distant corner.
    -- Side-route landing widths gently tighten; there is still a real
    -- achievable jump and a 3-stud rise between grounded terraces.
    -- no hidden collision roof, fake platform or powered jump required.
    -- Branch definitions append AFTER all 32 original perimeter decks, so
    -- existing original/skybridge/deck indices and hazard owners are stable.
    local branches = {}
    local floorTop = variant.BaseSize.Y * 0.5
    for route = 1, 4 do
        local fork = routes[(route - 1) * ArenaVariants.PerimeterSteps + 5]
        local directionZ = fork.offset.Z >= 0 and 1 or -1
        local forkTop = fork.offset.Y + fork.size.Y * 0.5
        for step = 1, 4 do
            local height = forkTop + step * 3 - floorTop
            local width, grade = ArenaVariants.parkourFootprint(
                "Branch", step
            )
            table.insert(branches, {
                offset = Vector3.new(
                    fork.offset.X,
                    floorTop + height * 0.5,
                    fork.offset.Z + directionZ * 13 * step
                ),
                size = Vector3.new(width, height, width),
                RouteTier = math.min(4, step + 1),
                ParkourGrade = grade,
                BranchRoute = route,
                BranchStep = step,
                BranchParentStep = 5,
            })
        end
    end
    variant.BranchPlatforms = branches

    -- Four compact, fully solid escape crosslinks join the *existing*
    -- perimeter step SIX to side-branch step TWO. Players can reach the
    -- lookout even after the next ridge deck disappears. Both ends are
    -- genuine R15 jumps: 1 or sqrt(2)-stud clear gaps and 1.2-stud rises.
    -- These append AFTER all previously authored platform IDs, so no
    -- skybridge, damage, bot, collectible or side-lookout owner changes.
    local crosslinks = {}
    for route = 1, 4 do
        local ridge = routes[(route - 1) * ArenaVariants.PerimeterSteps + 6]
        local flank = branches[(route - 1) * 4 + 2]
        local ridgeTop = ridge.offset.Y + ridge.size.Y * 0.5
        local flankTop = flank.offset.Y + flank.size.Y * 0.5
        local top = (ridgeTop + flankTop) * 0.5
        local height = top - floorTop
        table.insert(crosslinks, {
            offset = Vector3.new(
                ridge.offset.X,
                floorTop + height * 0.5,
                (ridge.offset.Z + flank.offset.Z) * 0.5
            ),
            size = Vector3.new(12, height, 12),
            RouteTier = 4,
            -- A rescue crossover must remain generously sized even when
            -- the surrounding late-route decks grow more challenging.
            ParkourGrade = 3,
            CrosslinkRoute = route,
            CrosslinkFromPerimeterStep = 6,
            CrosslinkToBranchStep = 2,
        })
    end
    variant.CrosslinkPlatforms = crosslinks

    -- MONUMENTAL SKY PROMENADES: two REAL 200-stud-scale routes connect
    -- the existing north and south branch lookouts. The far edge of
    -- every district gains a second direction (left or right), not a
    -- decorative dead end. Append last: all historical PlatformN IDs,
    -- Harbor's skyways and dock spurs remain unchanged.
    --
    -- Eight native solid landing slabs per lane. Centre spacing is
    -- exactly 1/8 of the two endpoint lookout positions; each slab
    -- occupies (spacing - 2.4) studs of that span. This produces eight
    -- uniform 2.4-stud standard-R15 jump gaps along each crossing and
    -- generous *overlap* with the original 12-stud endpoint landings.
    -- The collision is only 2 studs thick AT lookout height: the
    -- ground-level combat area beneath stays free, unlike a giant
    -- 30-stud-tall wall of colliders across the entire map.
    local promenades = {}
    for lane, leftRoute in ipairs({1, 3}) do
        local left = branches[(leftRoute - 1) * 4 + 4]
        local right = branches[leftRoute * 4 + 4]
        local xDistance = right.offset.X - left.offset.X
        local laneSpacing = math.abs(xDistance) / 8
        local leftTop = left.offset.Y + left.size.Y * 0.5
        local rightTop = right.offset.Y + right.size.Y * 0.5
        assert(math.abs(leftTop - rightTop) < 0.001
            and laneSpacing > 17 and laneSpacing < 32,
            "Sky promenade endpoint geometry must match existing lookouts")
        for step = 1, 8 do
            local progress = (step - 0.5) / 8
            table.insert(promenades, {
                offset = Vector3.new(
                    left.offset.X + xDistance * progress,
                    leftTop - 1,
                    left.offset.Z + (right.offset.Z - left.offset.Z) * progress
                ),
                size = Vector3.new(laneSpacing - 2.4, 2, 12),
                RouteTier = 4,
                ParkourGrade = (step == 4 or step == 5) and 4 or 3,
                PromenadeLane = lane,
                PromenadeStep = step,
            })
        end
    end
    variant.PromenadePlatforms = promenades
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
