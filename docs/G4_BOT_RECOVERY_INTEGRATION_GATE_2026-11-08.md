# G4 — Bot recovery integration gate (2026-11-08)

Baseline: `7984351bac09f80819bb4825dc6152a13605a615` on `main`. This is an inspection/acceptance contract, not a claim of engine validation or public publication.

## Verified source behavior

- `AISurvivorService.recoverIfStuck` waits for grounded walking and a genuine 1.15 s progress stall before recovery.
- A failed route quarantines its **original goal**, not its temporary NavMesh waypoint; a pending computation retains its original destination.
- Physical local sidesteps are checked before requesting a full asynchronous route. No teleport is used.
- Sky Shield, Team Dash, Sky Spine and district reservations are released on confirmed stall.
- The existing `PerformanceDiagnostics` exposes stall, local recovery, replan, accepted/completed/invalidated/expired routes and pending/active counts.

## Integration scenarios to certify

| Scenario | Expected authoritative outcome |
| --- | --- |
| Wide anchored wall; local detour impossible | One bounded async NavMesh request, eventual physical route or goal quarantine; no infinite same-goal retry |
| Pending path + repeated stall | Original pending destination retained; no replacement request to a transient sidestep |
| Knockback during active path | Airborne frame does not invalidate grounded corridor; hazard response still wins |
| Shutter closes during route | Bot does not enter a closed physical gate; recovery never fabricates safe floor |
| Collapse/shrink removes a deck | Route invalidated; no move onto missing collider |
| Two consecutive recoveries | Recovery side rotates and original goal is quarantined; no teleport |
| Player joins during eight-participant round | No extra participant beyond admission rules; eliminated bots remain eliminated |
| 30-minute Android session | No unresolved non-deliberate >6 s immobilization; measure CPU, FPS and memory rather than infer them |

## Diagnostic collection (existing counters only)

Capture before/after each scenario: `StallDetections`, `LocalRecoveryFound`, `LocalRecoveryFailed`, `GroundReplansRequested`, `GroundRoutesAccepted`, `GroundRoutesCompleted`, `GroundRoutesInvalidated`, `GroundRoutesExpired`, `GroundRoutesPending`, `GroundRoutesActive`, `AverageBotStepMs`, `PeakBotStepMs`, and `InRoundBots`. Also record actual observed freeze duration and a short video for each failure.

## Release gate

Do not merge a behavioral change solely from static inspection. For the final candidate, run existing Build Validation and all seven Roblox Cloud engine suites on the **same SHA**, then perform real Android gameplay checks and verify published place version. Do not mark any of these gates passed without artifacts.

## Next implementation decision

If a scenario fails, change the **smallest** navigation state transition that reproduces the failure; retain existing bounded request and diagnostics infrastructure. Prioritize a reproducible blocking bug over cosmetic AI changes. Avoid extra polling loops, invented floor coordinates, unverified models and unconditional resets of recovery attempts.

## Source change — transient ComputeAsync exception

Commit `2f54889` releases a still-owned recovery fallback when `ComputeAsync` raises an exception. It does **not** mark the destination as unreachable and it does not overwrite a newer station, district, hazard or ordinary target. The existing nine-second path-request throttle remains intact.

Acceptance: force a transient path computation exception while a local recovery fallback is owned; verify that the fallback is released and normal destination selection resumes. Repeat with a newer target and verify it remains unchanged. This has **not** been validated in a live Roblox engine session.

## Source change — pending path timeout

Commit `d4a0ae4` releases an owned temporary fallback when a pending `ComputeAsync` exceeds the existing query timeout. It preserves a newer objective, invalidates the old async token and retains the existing retry throttle. This is source-reviewed but **not engine-tested**.

Acceptance: force a pending route timeout while the bot holds its own position; verify it selects another normal objective. Repeat with a newly assigned station/hazard target and verify the target is preserved. Confirm that a late callback cannot change the target and that `GroundRoutesTimedOut` increments once.
