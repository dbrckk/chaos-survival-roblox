# Rising Lava — honest landing cues and physical parkour guidance

Date: 30 October 2026. **Feature branch: not public until a verified exact-SHA release.**

## Product defect and authoritative truth
The Roblox server's `src/server/Disasters/RisingLava.lua` creates a replicated, non-queryable `RoundLava` part in `workspace`. It is intentionally `CanQuery=false` (a visual/kill volume, not a walkable target), so the ordinary landing collision ray can report a real deck as available while it is already submerged. The existing landing brackets then display a safe cyan marker, and the newbie/parkour world cue may also recommend that submerged deck. This is a misleading UI defect rather than a collision or disaster-balance problem.

Server lethal-contact formula: avatar root must be within the lava's actual X/Z rectangle and root Y minus **2.5 studs** must be below or equal to the lava top. The server retains sole authority for elimination.

## Completed code change
- `src/shared/JumpRouteCueRules.lua` adds `lavaAtRoot` using the same **current** `RoundLava` replicated Position/Size and 2.5-stud contact clearance, and `lavaOnDeck` to check a physically authored deck's top with a conservative nominal root placement. Both predicates are read-only, return false for invalid/non-live volumes and never compute future flooding from a timer.
- `src/shared/JumpLandingPreviewRules.lua` classifies a projected actual avatar root within active lava as hazardous, using the same common helper used by the world guide.
- `src/client/JumpLandingPreviewKit.lua` adds the single real, query-disabled `RoundLava` to the existing small hazard array **only when the 10 Hz preview is already sampling**. The existing 4-bracket red X warns instead of a cyan safe landing. Normal and raised safe platforms still show ordinary landing guidance; collision, jump physics and reward logic do not change.
- `src/client/rookie-parkour-cue.client.lua` reuses the existing 0.40 / 0.85-second guidance cadence to reject a lava-covered target (normal route, cargo objective or fork), then searches an existing safe physical alternative at a fork or novice floor entry; if none is safe it hides the optional sign and yields to the disaster escape UI.
- No RemoteEvent, new gameplay loop, server change, forced movement, paid asset, gameplay Part, new particle, extra physics query, high-frequency map scan, or paid service.

## Acceptance contract at the next major milestone
1. **Real engine build/suites** on the exact merged SHA; catch syntax/runtime regressions in existing five Open Cloud suites. No new unit tests and no feature-iteration suite runs.
2. **Actual Roblox Studio / Android**: jump to a deck at/under active lava surface; preview must show 4-segment red X, never safe cyan. At least one raised deck above the lava must retain ordinary contact brackets. Confirm the same on Classic, Tower Run, Crossroads, Orbital and Harbor with active RisingLava where supported.
3. First-session parkour: under lava pressure, no sign points to a flooded deck. At a genuine branch, recommend only a physically jumpable un-flooded alternative. If none, hide optional cue. A recovered safe high platform should stay marked.
4. Robustness: no stale signs following lava cleanup, map swaps or elimination; no false lava warnings without `RoundLava`, and no lava-based gameplay damage authority in a client.
5. **Native performance**: existing bounds (4 reticle parts, ≤4 raycasts at 10Hz, ≤one world jump billboard, polling cadence unchanged). Frame-time, thermal state and touch responsiveness must still be checked on real hardware; no FPS claim from passing CI.

## Release and remaining gaps
The baseline public update was confirmed by [GitHub run 41095777897](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41095777897) at commit `030e191407ff454a09315c9db66688559e641fff`.
The Harbor decorative fallback PR #402 was merged later in commit `ce0aa980d9d257e40050288aa21fd69086c37ab8` and is also unpublic until validated.
Because the lava is rising, **current** surface checks cannot promise safety 0.42 seconds in the future. The existing reticle remains a short-horizon physical estimate, not an infallible hazard oracle. Do not report Android QA as passed without native evidence.
