# Next major public playtest release — eight-player movement and Android arenas
Date: 2026-11-02
Status: SOURCE CANDIDATE. NOT A PUBLIC ROBLOX DEPLOYMENT.

## Verified baseline

- Current `main` before this branch: `b9a52815e696967d871d065cb5543519362e4a98`.
- Last confirmed public starting-place publishing run: [41489124289](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41489124289), exact source `79e73a2a5030e9cde0adf80e6f1a8fda51959728`. The authenticated job included successful Build Validation, exact-SHA engine checks and **Publish ONLY the existing public starting place**.
- Later main changes had green [Build Validation 41494260248](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41494260248) and [Roblox Open Cloud Engine Tests 41494359576](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41494359576). Those are source/engine checks, **not** proof of a public update or Android gameplay.

## Release bundle — notable improvements since live SHA

1. Physically grounded NPC skyway routing: movement selects a real supported neighboring deck rather than an unreachable adjacent floating island.
2. Imminent meteor, bomb and collapse avoidance: escape destinations remain inside the real R15-safe deck surface and danger evasion outranks impossible collapse holds.
3. **New in this candidate:** bounded Roblox server `PathfindingService` fallback around a **large ground obstacle** when the eight-participant bot cannot pass using its existing first-line 6.5-stud grounded detour.
   - Asynchronous ComputeAsync, one request after repeated true stalls or a failed local escape; nine-second per-bot cooldown. The sequential bot brain never waits for a remote path computation.
   - Navmesh must return a non-jumping route: up to 24 physical waypoints, up to 155 studs total, each next segment at most 13 studs. Every waypoint and segment midpoint must raycast onto the actual server-owned arena Base, not a non-colliding decorative facade or void.
   - Changes use the existing Roblox Humanoid MoveTo. No teleport, noclip, artificial boosts, extra remotes or paid shortcuts. Physical waypoint corners use direct steering rather than lateral social jitter.
   - Path is invalidated immediately when a hazard warning appears, a high-risk collapsing/lava/tornado stage starts, the bot is replaced, or its round ends. A pending ComputeAsync cannot apply a stale route to the next round.
   - Server diagnostic: `BotGroundNavigationCount` on an AI rig. Incremented only when an independently validated fallback route is adopted; **not** evidence that the bot reached its destination.
4. Previously merged monumental authentic 3D physical-route architecture, improved Android daylight, persistent survive-seconds objective, distinct Storm Harbor machinery and spatially bounded decor remain in scope **only to the extent not already in the live SHA**. Avoid marketing these as untested new assets.

## Hard release gates

- No unit tests during feature implementation. At this release milestone run the existing GitHub Build Validation on the **final exact main SHA** and all five Roblox Cloud engine test suites on the **same SHA**. Investigate any genuine failure, never bypass it.
- Run authenticated Roblox Studio E2E and collect genuine 15-frame screenshots from all five arenas; check physical nav (wall, arch, spawn obstacle, skyway gap, live warning), actual landing, eight-slot READY roster and visible start/end outcomes. A simulated engine spec does not establish visual quality.
- Real physical Android landscape gameplay: one minute of normal movement in each of the five variants; no black floor/characters, no unreadable permanent 3D signs, no floating cosmetic platforms mistaken for physical routes, stable touch HUD, clear SURVIVE X s objective and no bot loops or jump-in-place. Record actual FPS/temperature on the owner's device, not invented values.
- Verify cloud source `Build Validation`, engine, Studio E2E, human accessibility and baseline persistence/round lifecycle before using the existing guarded `Publish Existing Chaos Survival (Public Playtest Update)` workflow on the exact same main commit. Publish only to existing universe 10771083668, place 95351659174730.
- Roll back to the last known public SHA if a verified gameplay failure appears. Never assert publication from a merge or a green workflow without checking the actual publish step.

## Exit criteria

A first-time Android player can identify the survival timer and a grounded escape route without instructions; visible NPCs move around major floor obstacles when native direct steering fails; none of the new path routes crosses uncovered gaps or masks imminent disasters; up to eight participants remain provisioned at READY; all five arenas preserve their original quality/identity and Android budgets. Mark acceptance provisional until actual capture evidence arrives.
