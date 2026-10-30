# Rising Lava — honest landing cues and physical parkour guidance

Date: 30 October 2026. Original lava landing/rookie guide safety reached the public game; new live refuge-sign follow-up below is **source-only pending a fresh exact-SHA gate**.

## Product defect and authoritative truth
The Roblox server's `src/server/Disasters/RisingLava.lua` creates a replicated, non-queryable `RoundLava` part in `workspace`. It is intentionally `CanQuery=false` (a visual/kill volume, not a walkable target), so the ordinary landing collision ray can report a real deck as available while it is already submerged. The existing landing brackets then display a safe cyan marker, and the newbie/parkour world cue may also recommend that submerged deck. This is a misleading UI defect rather than a collision or disaster-balance problem.

Server lethal-contact formula: avatar root must be within the lava's actual X/Z rectangle and root Y minus **2.5 studs** must be below or equal to the lava top. The server retains sole authority for elimination.

## Completed code change
- `src/shared/JumpRouteCueRules.lua` adds `lavaAtRoot` using the same **current** `RoundLava` replicated Position/Size and 2.5-stud contact clearance, and `lavaOnDeck` to check a physically authored deck's top with a conservative nominal root placement. Both predicates are read-only, return false for invalid/non-live volumes and never compute future flooding from a timer.
- `src/shared/JumpLandingPreviewRules.lua` classifies a projected actual avatar root within active lava as hazardous, using the same common helper used by the world guide.
- `src/client/JumpLandingPreviewKit.lua` adds the single real, query-disabled `RoundLava` to the existing small hazard array **only when the 10 Hz preview is already sampling**. The existing 4-bracket red X warns instead of a cyan safe landing. Normal and raised safe platforms still show ordinary landing guidance; collision, jump physics and reward logic do not change.
- `src/client/rookie-parkour-cue.client.lua` reuses the existing 0.40 / 0.85-second guidance cadence to reject a lava-covered target (normal route, cargo objective or fork), then searches an existing safe physical alternative at a fork or novice floor entry; if none is safe it hides the optional sign and yields to the disaster escape UI.
- No RemoteEvent, new gameplay loop, server change, forced movement, paid asset, gameplay Part, new particle, extra physics query, high-frequency map scan, or paid service.

## Follow-up: tier-four refuge signs must remain truthful during flood surges

Source inspection after the major hazard-preview QA found a separate UI
contradiction in `src/client/lava-high-ground.client.lua`: the existing
`HighGroundRouteSign` and its `Highlight` were enabled from only
`RouteTier==4`, solidity and current round. Tier four is a **course
difficulty/height class**, not a guarantee a particular platform is still
above the moving server lava surface. The server caps the total rise
against the fourth-highest physical deck, but the four marked tier-four
decks need not be those specific highest platforms.

The client now reuses **the already authoritative** replicated
`JumpRouteCueRules.lavaOnDeck(platform, currentLava)` for all existing
selected signs, so a truly submerged candidate loses *both* its "safe"
sign and outline while the physical deck and disaster remain unchanged.
The current real `RoundLava` Part is watched by exactly **one**
`Position` changed signal; the connection is detached on removal or
round replacement, and the signs re-evaluate immediately when the
flood rises. No RenderStepped/Heartbeat loop, workspace scan, new GUI,
collision, acceleration, extra map Parts, remote or reward. Up to four
signs are touched per actual lava replication event. Before the
authoritative lava Part exists in the ready phase, the original
preparation signs remain available.

The existing real Roblox
`tests/engine/movement-assist-rules.spec.luau` now covers the precise
server root-clearance boundary on an actual tier-four collidable deck,
a sub-threshold flood, a lethal equal-level flood, a rapidly rising
flood, off-map fluid, non-lava Parts and removed warning volumes.
Real Android QA must still confirm a selected sign vanishes at the
moment the rising surface reaches its target platform, and must not
incorrectly disappear from a taller physically safe neighboring roof.

## Acceptance contract at the next major milestone
1. **Real engine build/suites** on the exact merged SHA; catch syntax/runtime regressions in existing five Open Cloud suites. No new unit tests and no feature-iteration suite runs.
2. **Actual Roblox Studio / Android**: jump to a deck at/under active lava surface; preview must show 4-segment red X, never safe cyan. At least one raised deck above the lava must retain ordinary contact brackets. Confirm the same on Classic, Tower Run, Crossroads, Orbital and Harbor with active RisingLava where supported.
3. First-session parkour: under lava pressure, no sign points to a flooded deck. At a genuine branch, recommend only a physically jumpable un-flooded alternative. If none, hide optional cue. A recovered safe high platform should stay marked.
4. Robustness: no stale signs following lava cleanup, map swaps or elimination; no false lava warnings without `RoundLava`, and no lava-based gameplay damage authority in a client.
5. **Native performance**: existing bounds (4 reticle parts, ≤4 raycasts at 10Hz, ≤one world jump billboard, polling cadence unchanged). Frame-time, thermal state and touch responsiveness must still be checked on real hardware; no FPS claim from passing CI.

## Release and remaining gaps
The last independently confirmed public update is [publisher 41112157340](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41112157340) on commit `77e5805c96d9dd793e5bc058b93b4d7e904e1530`. The new source-only work is **not yet published**. Successful engine/build suites verify code paths but do not certify visual gameplay on an Android device.
Because the lava is rising, **current** surface checks cannot promise safety 0.42 seconds in the future. The existing reticle remains a short-horizon physical estimate, not an infallible hazard oracle. Do not report Android QA as passed without native evidence.
