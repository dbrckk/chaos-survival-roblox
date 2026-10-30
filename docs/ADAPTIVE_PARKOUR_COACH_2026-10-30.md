# Chaos Survival — Adaptive Parkour Coach (30 October 2026)

## Goal

Help the platformer feel more like a premium, readable physical obstacle course **without turning every jump into an always-on GPS overlay**. The game has an existing 100 ms coyote jump, 120 ms input buffer, camera landing brackets, and physical per-platform routes. This feature reuses them rather than replacing the controls or granting additional movement.

## Integrated design

- **Experienced players** see a single localized, depth-tested, short-range next-jump sign **only after being grounded on the same real platform without travelling farther than 3.4 studs for 5.2 seconds**. A platform switch, airborne jump, movement, eliminated state, changed map or changed round invalidates the stall timer. This is assistance when visibly stuck, not compulsory tutorial text during a normal run.
- Existing **new-player signs** remain immediate on physical starter decks and deliberate climbing paths. Harbor cargo-cache guidance retains its priority over the optional veteran recovery coach.
- When a **meteor or bomb** is warning, the coach checks the **entire proposed walking/jumping segment**, not just the destination, against the server's replicated `WarningEndSize` footprint plus a small margin. If the character is already in the footprint, the **primary disaster escape HUD** has priority.
- At a physical fork (perimeter step 5) or crossing (step 6), prefer a real jumpable side route if the default successor is in the hazard footprint; otherwise **hide the unsafe sign**. First-session players on the base floor also get the next *physically accessible, safe* first-tier entry rather than a blocked one.
- The separate high-ground mastery cue has priority. The coach does not add optional veteran hints during that objective or during final rush.
- The existing single BillboardGui, its occlusion and 48-stud distance, and its **0.40 / 0.85 s polling cadence** are retained. No new RenderStepped, RemoteEvent, server checks, 3D collision, jump physics, teleport, performance-hungry scene scan or reward system. Live warning Parts are tracked by the existing workspace ChildAdded/ChildRemoved event family, not a per-frame descendants query.

## Release QA

The pure predicates `JumpRouteCueRules.recoveryHintReady` and `safeGuidedPath` are covered by additional **unexecuted** existing engine specs in `tests/engine/mapbuilder.spec.luau`. In accordance with project policy **do not run tests during iterative implementation**; the next public milestone must execute the exact-SHA Build Validation and Roblox Open Cloud Engine Tests first.

On real Android, check that the optional sign stays hidden during healthy progression; appears after a stalled climb; disappears on walking/jumping; never points across active Meteor/Bomb footprints; offers a feasible safe detour at actual forks; does not overlay high-ground mastery cues; and has negligible frame-time cost. Test Classic, Towers, Crossroads, Orbital, Harbor, Low/Medium/High, both landscape and portrait phone display orientations where supported. Passing engine specs alone is not a claim of real-device play certification.

## Next quality gates

Physical jump-feel tuning based on device measurements (jump error rate, early exits, stuck points); map-specific route silhouette polish; player retention and replay incentives tied to verified server rewards. Prioritize measured problems over adding unbounded cosmetic systems.
