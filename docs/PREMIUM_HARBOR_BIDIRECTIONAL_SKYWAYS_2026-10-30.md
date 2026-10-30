# Storm Harbor — real cross-quay roof routes, bidirectional navigation

Date: 30 October 2026. Feature source branch only until a subsequent **exact-SHA build + real Roblox Open Cloud verification and approved public publisher**.

## Inspected gameplay defect
Storm Harbor has four seven-step cargo switchbacks, one per quadrant, ending at world offsets (`±51, +22, ±50`) with 9.6×9.6-stud walkable top surfaces at height **23 studs**. Despite four authentic top platforms, the high routes were dead ends: crossing to an adjacent gantry required dropping to the floor and restarting the climb. There was no inter-quay high-route choice. The 320×320 mega-arena's elevated navigability remained fragmented.

## Completed level design — not static facade or AI hallucination
- Two **real, server-owned, anchored, colliding** elevated skyway runs: north (`Z=-50`) and south (`Z=+50`). Each contains seven progressively graded native steel platforms, **14 new playable parts** total. They connect the west HarborRoute 1→2 and 3→4 termini; every physical jump works in both directions.
- Platform centers: `X=-51 + step×12.75`, `step=1..7`; landing widths **10.5** studs at end approaches and **9.8** across the precision midspans. Steel surface tops always `Y=23` (center 22, thickness 2), matching actual cargo step-seven roof elevations.
- Exact center-to-center distance **12.75**; legal clear jump gaps **2.60..2.95** studs within the existing authoritative `JumpRouteCueRules.MaxGap=3.85`. Terminal-to-first/last clear gap **2.70** studs. No snap, hidden walkway, teleport, new jump power or client-side collision.
- Elevated crossings run at `Z=±50`, **outside** the cargo step-five/six real ascent at `Z=±37`. Closest route-family deck footprint has at least 2.8 studs of empty horizontal clearance; there is no 3-stud-low roof sitting over the existing takeoff. They are away from four floor-level HarborCargoSweep pulses at `X/Z=±32` and form legitimate alternative high routes.
- Keep all existing 28 Harbor platforms and 52 perimeter/branch/crosslink platforms at their previous indices. Append skyways as `Platform81..Platform94`. Existing server-owned `DisappearingPlatforms`, `ShrinkingArena`, AI targeting, collisions and player movement still receive them through `Arena.Platforms`.
- Materials are original Roblox `CorrodedMetal`, with a quiet themed industrial palette, standard graded `PlatformPanel`, underside frames, chamfers and ground-supported noncolliding structural footings from the existing `addPlatformFinish` pipeline. No external uploads, remotes, player entitlement, new lights, persistent loops or mesh-loading network dependencies.

## Gameplay clarity and actual two-way completion
- Explicit `HarborSkywayLane/HarborSkywayStep` attributes exist only on the newly authored real platforms; `HarborRoute/HarborStep` remains unchanged on cargo landings.
- The new shared `JumpRouteCueRules.skywayLeap` accepts *only* level-height skyway legs with collision, warning-phase and true physical gap validation. The existing normal ascents stay strictly 0.4..4.05-stud rises; no global permissive jump regression.
- From every existing cargo **step-seven** terminal, `nextSkyway` identifies the correct physical near-end bridge platform. Once on the roof, the coach remembers the previous **physically contacted** step, not unreliable touch joystick/heading. Jumping east or west selects the correct next real step. Falling, respawning and changing arena/round reset direction safely.
- After a successful terminal-to-terminal crossing, the rookie cue stops suggesting the reverse jump immediately. All optional hints still respect real collapse warnings, active meteor/bomb/sweep route checks and current replicated RisingLava submersion; primary disaster escape UI keeps priority.
- Experienced players retain their optional timed recovery coach (no GPS spam), and the current Harbor cargo shard navigation is not overwritten.

## Evidence from deterministic layout review, not Roblox simulation
Coordinates and widths imply eight consecutive traversable edges for each roof:
`[-51,-38.25,-25.5,-12.75,0,12.75,25.5,38.25,51]`.
Clear gaps are `[2.70,2.60,2.95,2.95,2.95,2.95,2.60,2.70]`, **all within the shared maximum 3.85**. This is a geometric source review; it is not a human-engine parkour run or device FPS measurement.

## Existing engine regression coverage (not executed during feature work)
Extended **existing** `tests/engine/mapbuilder.spec.luau` rather than adding a new suite:
- update only aggregate platform-count expectations for the Harbor-only append;
- build the actual Harbor native map;
- assert all 14 server-authored steel Parts' lane/step IDs, anchored collision and precise real gap;
- assert `nextPhysical` covers Harbor terminal → seven platform crossing → opposite Harbor terminal **in both directions**, on both real routes;
- collapsing the entry landing invalidates the immediately suggested route, then restores it.

**Final release verification:** after this PR merges and all existing in-progress exact-SHA checks conclude, run Build Validation and all five real Roblox Open Cloud engine suites on the exact final `main` SHA. Never assert 100% completion or publish on code review alone.

## Hardware/visual acceptance still required
A real Roblox Studio and Android run must confirm four climb → seven precision jumps → opposite port terminal traversals; camera does not clip support posts; elevated seams and underside materials look authentic; hazard warnings/collapse stay authoritative; Low/Medium/High FPS and 360px mobile touch navigation remain within device targets. Existing automated suites cannot certify real-device rendering, retaining players, or 9/10 overall quality.

Current actual public baseline prior to merge: `030e191407ff454a09315c9db66688559e641fff` (publisher [41095777897](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41095777897)). No claim that this new skyway has been published.
