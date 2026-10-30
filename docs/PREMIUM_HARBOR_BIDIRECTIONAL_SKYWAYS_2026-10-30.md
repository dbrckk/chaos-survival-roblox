# Storm Harbor — real cross-quay roof routes, bidirectional navigation

Date: 30 October 2026. Skyway geometry, guidance and server-verified XP are **published in the public playtest** at SHA `77e5805c96d9dd793e5bc058b93b4d7e904e1530` ([publisher 41112157340](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41112157340), Success). New anti-farming follow-up below is **not yet public**.

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

## Follow-up: real server-awarded skill progression for roof-to-roof jumps

The skyway geometry and optional rookie hints alone did not complete the loop: before this follow-up, `ParkourFlow.legalJump` unconditionally called `JumpRouteCueRules.jumpable`, which *correctly* rejects level-height transitions on ordinary ascending courses. It therefore falsely reset an otherwise authentic Harbor skyway combo on every horizontal jump, preventing the established parkour XP bonus during the most challenging new route.

The targeted fix first validates source and destination as actual server-anchored, solid, active `Arena.Platforms` instances. **Only for Harbor's explicitly authored skyway endpoints**, it delegates horizontal geometry and safe landing to `skywayLeap` and confirms the destination is the immediate corresponding server-authored `nextSkyway` in either direction. Other arenas and horizontal moves on unrelated decks still fail; no new RemoteEvent, client claim, reward value, jump power, currency grant, replay loophole or pay-to-win path. The existing server-observed Humanoid takeoff, plausible flight speed/time, physical raycast landing, capped combo and once-per-round bonus continue unchanged.

Existing `tests/engine/parkour-flow.spec.luau` now exercises server takeoff → physical skyway landing → capped seven-jump legend XP on both lanes, in both directions, and rejects cross-variant, collapse-warning and noncolliding destinations. This scoring fix passed the exact-SHA real Roblox engine and build gate and was published with the public update `77e5805c`.

## Post-publication mastery integrity — direction-locked streaks

**Observed source vulnerability after successful public update of SHA `77e5805c`:** the Harbor cross-quay bridge has legal server-authored jumps in either direction. `ParkourFlow.advance` previously credited all physically valid jumps as a contiguous chain, allowing a player to repeat `SkywayStep1 ⇄ SkywayStep2` until earning `RIDGE LEGEND` and bonus XP without actually traversing the bridge.

The corrected server-side flow maintains a tiny `skywayDirection` value in existing per-player round memory, derived exclusively from the existing server-authored `HarborRoute` and `HarborSkywayStep` metadata after a real Humanoid takeoff and physical landing. Once a player has committed to one end of the bridge, a reverse jump remains **legitimate movement and safe during a disaster**, but it ends the *current mastery chain*. Advancing along the same direction continues the streak; reaching an actual terminal clears the direction so a complete return crossing can earn independent progression. A failed landing also clears the direction. No movement or camera restriction, new UI, new network event, artificial checkpoint, recurring task, currency grant or additional mobile cost.

An engine scenario was added to the **existing** `tests/engine/parkour-flow.spec.luau` to bounce repeatedly between two actual Harbor decks with valid server takeoff/landing events. It requires `best == 2`, `bonusXP(best) == 0`, and confirms real forward travel still scores while tactical reverse hops remain legal but break mastery. Existing two-way full-crossing certification is retained unchanged.

**Release policy:** feature branch only until next exact-SHA build and real five-suite Roblox Open Cloud gate. The previously published public game remains on `77e5805c`; no automated publication has been attempted. Android/manual acceptance still requires an actual screen and tactile performance review.

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

Published public baseline while developing this anti-farming follow-up: `77e5805c96d9dd793e5bc058b93b4d7e904e1530` (publisher [41112157340](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41112157340), Success). Physical-device Android/Studio review remains incomplete.
