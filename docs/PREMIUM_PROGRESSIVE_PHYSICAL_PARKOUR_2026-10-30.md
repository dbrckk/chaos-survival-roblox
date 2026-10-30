# Chaos Survival — physically progressive premium platform routes
_Date: 30 October 2026 • unpublished source candidate_

## Product intent

Before this change, the four 320-stud perimeter climbs on every arena and all seven Storm Harbor switchback decks had a nearly identical **12×12 stud landing area**. The player experienced height and route length, but had little increasing need for landing precision. This revision gives a deliberate **four-grade physical skill curve** while preserving the real R15 jump physics, existing movement assistance, and exact server-authoritative platform routes.

### Real physical collision footprints

| Course type | Stage → width in studs | Grade progression |
| --- | --- | --- |
| Four perimeter routes on all five maps | 12, 12, 12, 11.6, 11.2, 10.8, 10.4, 10 | I, I, II, II, III, III, IV, IV |
| Four Storm Harbor cargo switchbacks | 12, 12, 11.6, 11.1, 10.6, 10.1, 9.6 | I, I, II, II, III, III, IV |
| Four true outer branches on every map | 12, 12, 11.2, 10.4 | III, III, IV, IV |
| Four ridge-to-branch rescue crosslinks per map | unchanged: 12 | III — deliberate safety margin |

Widths refer to **both X and Z dimensions of the actual collidable top deck**, never a decorative inset or fake client waypoint. First-session entries and their first jumps stay easy. Late narrow decks demand deliberate direction control without tiny or invisible hitboxes.

- Perimeter horizontal center separations remain **13 studs**, with the first true gap **1 stud** and later gaps below **3 studs**, compared with the existing max permissible **3.85 studs**.
- Harbor retains its original 90-degree turns, 13-stud center separations and 3-stud rises. The worst late edge gap is **3.15 studs**, within the existing jumpable limit.
- Side branches keep physical 3-stud rises and preserve actual ridge/branch crosslinks. Crosslinks remain 12 studs wide for emergency escape and other disasters.
- All platform centers, R15 clearance, arena base dimensions, original platform IDs, raycast/grounded detection, ai bot navigation metadata, collectible positions and map generation ordering are untouched.
- A new server-authored `ParkourGrade` attribute is derived from the same stage definition as the physical size. It cannot be set by a player to modify collisions, score or jump powers.
- The existing landing top panel and bevels use a modest material color progression tied to grade. The original single depth-tested rookie/recovery jump cue now announces **PRECISION JUMP / SAUT PRÉCIS** at grade III and **EXPERT JUMP / SAUT EXPERT** at grade IV. Objective, choice-of-route, cargo and safe-detour messages still have priority. **Zero new platform Parts, lights, shadows, UIs, remotes, expensive PBR materials or per-frame physics**. Android rendering costs remain effectively bounded by the existing map.
- The existing user scores, skill medals, server-verified jump chains, persistent personal bests and daily/weekly quests automatically use these **real physical surfaces**. No client score claims or artificial difficulty bonuses.

## Regression and accessibility contract

New cases in the already-registered `tests/engine/parkour-flow.spec.luau` cover **all five arenas**, each of the four perimeter ascents, four branches, four physical crosslinks and four Harbor routes. They check monotonic collision size, bounded four-grade progression, walkable anchored Parts, actual `JumpRouteCueRules.jumpable` and genuine `ParkourFlow.legalJump` continuity. Tests have been **written but not executed** during this incremental improvement cycle, in accordance with the owner's instruction. The next major final-revision gate must run exact-SHA Build Validation and all Roblox Open Cloud Engine Tests before any publication.

For premium acceptance **beyond automation**, a real Android + PC play session must measure early-stage success against late-stage completion, input latency, overshoot/falls and 30/60 fps frame pacing. Verify players still identify where to jump during simultaneous disasters and find the optional safe branches without excessive hints. In particular test low-gravity, speed surge, collapsing platforms, streaming/reconnect, bots and the last narrow Harbor deck.

### Recovery guidance under repeated missed attempts

The previous optional veteran coach reset its 5.2-second wait whenever a character jumped. An expert who repeatedly tried and failed the same ledge could therefore remain stranded *forever* without assistance. The same effect happened when simply rising vertically more than 3.4 studs: the old 3D progress distance counted jump height as if it were traversal.

The existing client now **hides its single physical target cue while airborne but preserves the same-deck stall timer**, measures actual horizontal X/Z progress, and only resets when a new grounded deck is reached, the avatar moves more than 3.4 studs horizontally, the character respawns, the arena changes, or the round becomes ineligible. The cue appears after a genuine stall **including several unsuccessful hops**, while a skilled player who progresses through the course sees no persistent GPS overlay. A pure distance helper and engine assertions protect these decisions without any new polling loop, billboard, remote event or jump physics modifications. No tests were run during this improvement phase.

**Current status:** source improvement only, not a certified final AAA product and not a public Roblox update.
