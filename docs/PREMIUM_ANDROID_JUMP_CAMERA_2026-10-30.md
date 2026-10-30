# Chaos Survival — Premium jump feel & Android camera reliability
_Date: 30 October 2026 • unpublished source candidate_

## Goal

The premium platformer must not drop jump assistance after slow Android avatar streaming, and buffered jump windows should be identical whether the engine signals `FloorMaterial` or `StateChanged(Landed)` first. The camera must not distort a narrow landing while the player tries to correct their trajectory.

## Fixed production defects

### 1. Infinite, event-driven Humanoid attachment

Previous `src/client/jump-assist.client.lua` used `Character:WaitForChild("Humanoid", 5)`. If replication exceeded **five seconds**, the helper returned permanently and neither coyote nor buffered jump listeners were installed until another full respawn. It could also miss a live Humanoid replacement.

Now, on every current Character binding, a cheap `ChildAdded` listener catches a late Humanoid **without a timeout**, and a `ChildRemoved` listener disconnects and replaces only the affected Humanoid's two subscriptions. Old rig callbacks remain guarded by version + character + exact Humanoid identity; all four connections are disconnected on respawn. No polling, no 60-Hz rescan and no forced motion.

### 2. Correctly ordered landing and exactly-once buffered jump

A `JumpRequest` up to **120 milliseconds before landing** remains buffered under the existing `MovementAssistRules`. Roblox can fire `FloorMaterial` and `StateChanged` in either order. Now both paths attempt dispatch, but `MovementAssistRules.canDispatchBufferedJump` requires **real non-air FloorMaterial**, a legitimate **Landed/Running/RunningNoPhysics state**, a still-live input window, and a healthy enabled jump control. A single `task.defer` rechecks all conditions before consuming the buffer. Duplicate engine events cannot produce extra jumps; a dead/old Humanoid, Freeze Pulse, Swim, Seat, or a resumed app after the 120-ms window cannot replay an invalid jump. The original **100-ms coyote window** and native Roblox jump semantics remain untouched.

### 3. Touch camera descents remain readable

`LocomotionDynamics.precisionCameraFactor` provides a **0.48 passive-motion envelope** only while a touch player is actually descending (`verticalSpeed < -3`) in a real round. The one existing `movement-feel.client.lua` RenderStep owner uses it for speed-driven FOV, acceleration kick, lean and low-gravity drift, limiting apparent deck-size and sightline changes right before a precision landing. Existing disaster impact shake, landing feedback, local collision landing brackets, button input, spectator controls and R15 physics are **not disabled or rewritten**. No new camera/animation/render owner. NaN/zero/paused Android frame deltas are also clamped to a quiet 1/60-second restart frame rather than driving the spring with a multi-second elapsed time.

## Correctness and release gate

Existing real Roblox engine spec files are expanded **without adding new standalone unit-test suites**:

- `tests/engine/movement-assist-rules.spec.luau`: first-/second-signal ordering, disabled jump, state validity, input expiry, once-only consumption and exact coyote timing.
- `tests/engine/body-motion-rules.spec.luau`: touch-only airborne camera factor, no desktop/idle/ready manipulation, invalid speed protection.

The new engine assertions are **not executed during this improvement phase**, per project rules. At the next significant release milestone, run full exact-SHA Build Validation + real Roblox Open Cloud Engine Tests on the final source SHA, then carry out actual smartphone and PC sessions. A source merge is not a Roblox deployment or a verified FPS measurement.

### Device QA matrix

| Device/scenario | Expected result |
| --- | --- |
| Android: delayed character replication >5 s | Jump helper attaches as soon as Humanoid appears, no requirement to die/respawn |
| Android: die and respawn rapidly while holding Jump | Old rig can never replay a jump or leave duplicate listeners |
| Android/PC: jump pressed on ground | Native Roblox Jump still works; no unwanted second jump |
| Android: leave a deck and tap at 40–90 ms | One coyote jump, never a double jump |
| Android: tap 50–110 ms before a real landing | One buffered jump regardless of FloorMaterial/StateChanged ordering |
| Android: tap 150+ ms before landing | Buffer expires, no forced jump |
| Android: Freeze disables jumping during buffer | Nothing dispatched until valid, no Freeze bypass |
| Android: descend onto narrow 9.6/10-stud deck | Passive camera lean and FOV settle, disaster telegraph/landing feedback remain obvious |
| Android: app suspend/resume with high delta | No massive camera kick or lingering jump |
| Desktop keyboard/mouse and touch disabled | Existing camera motion & jump control unchanged |

## Product metrics to record before declaring premium

Actual latency percentiles of JumpRequest→humanoid Jumping, jump miss rates at 0/1/2/3.5-stud platform margins, collision/landing reticle accuracy, median and p95 FPS in 5 maps × 3 graphics tiers, camera occlusion rate, difficulty-specific completion rates, observed replay intent and retention. No values are claimed without logs and playtest captures.

**Status:** source improvement candidate, not the AAA final release. The last verified public Roblox place remains at SHA `a0f56bcd4cfa401162a608404c95649bb39b6446`.
