# Physical bot navigation recovery — real Android feedback (2 November 2026)

## Reproduced player issue and source-level root cause

Six real Android captures show crowded bot survivors and report **stupid movement, collision with obstacles, stuck positions and frequent erratic hops**. All eight participants can be visibly present; that is not proof their routes are competent.

In `src/server/AISurvivorService.lua`, `recoverIfStuck` waited for `stuckCount >= 2`, **but on the FIRST directional stall it immediately cleared `record.target`**. On the following brain tick, `if not record.target` reset `stuckCount=0`. In the usual traversal case this defeated the actual physical clearance branch and left NPCs cycling through the same failed wall destination. The original helper sampled only the *end* of a lateral movement; it could propose a 6.5-stud sidestep across a void or a collapsing deck.

## Actual code repair, without cheats or an additional simulation

1. **Real 1.15-second directional progress check.** Measure forward displacement *toward the current target*, not overall lateral flailing or intentional jump motion. Only consider live **grounded**, **walking** Humanoids with a distant target. If the target changes appreciably or the bot is paused, airborne or holding an interaction, reset the sample instead of counting a fake stall.
2. **Recover on the first confirmed stall**, not after an unreachable second stall. Preserve the failed target for 7.5 seconds and stop choosing it repeatedly. Release physical Team DASH / Skyline SHIELD station reservations and optional district challenge traversals; a stuck bot cannot reserve a team activity indefinitely.
3. **Choose seven real avatar-walkable alternatives relative to the original destination**: left/right forward-biased sidesteps, pure sidesteps, two slightly backward sidesteps and a retreat. Rotate the first side by the authentic bot slot *and* the number of consecutive failed recoveries. This prevents the entire AI group from tracing the same failed evasive path.
4. **Validate physical clearance** with genuine world collision raycasts (noncolliding cosmetic lights do not block), a minimum of 4.5 studs of real remaining travel after arena bounds clamp, and **two separate supporting-ground raycasts**: one at the halfway point and one at the final destination. Reject sloped/wall collisions, already blinking/fallen platforms, near-vertical height changes and sky gaps. Never teleport, `PivotTo`, raise WalkSpeed, create invisible walkable geometry or fake survival status.
5. **Preserve progress state** through the recovery; only clear its failure count when the next attempt makes measurable progress toward the selected route. Reset stale samples, failed destinations and telemetry on genuine round/lobby transitions. Publish `BotStallRecoveryCount` and `BotRecoveryRouteFound` as server-owned rig attributes for authentic Studio/player observability.
6. **Reduce needless random pogo jumps during live disasters** to 20% of the old ambient probability; deliberate jumps for a raised physical deck, a real escape hazard and normal R15 parkour remain unchanged. A bot already airborne or committed to a skyrail never executes an additional purely random jump.

This is a meaningful bug correction in existing `AISurvivorService.lua` and `AISurvivorRules.lua`, not a new AI dependency, an expensive model, a client remote, a fake bot count or a developer-only demonstration. It operates on the real 8-participant roster.

## Source acceptance

Existing `tests/engine/ai-survivor-rules.spec.luau` checks the seven genuine normalized detour vectors, seven-bot side differentiation, legitimate forward progression and that held prompts, airborne jumping and momentary turns do **not** trigger recovery. Production helper uses `RaycastParams.RespectCanCollide=true`, the existing shared `platformAvailable` hazard guard, and visible server telemetry on each real rescue.

## Public playtest / release gate

- Same exact merged main SHA must pass Roblox Luau lint/build + ALL FIVE Open Cloud engine suites, not tests from another commit. At this time the latest previously green baseline is `dbe193694a560c86a78a570b9bcb91e64a35526c`. A separate reviewed Android-midtones correction PR #548 has now been integrated in source, but remains unverified on its newer SHA.
- During physical Android test, watch each of seven real bots for at least a full Meteor, Lava and DisappearingPlatforms round. Check actual engine attributes `BotStallRecoveryCount` and `BotRecoveryRouteFound` via authenticated Studio capture. Count repeated collision loops, midair escape attempts, movement into sky gaps, time spent standing still, repetitive jumps and whether AI physically reaches real interactive consoles.
- No public Roblox game publication occurs by GitHub merge. Android/Studio visual QA and the explicitly acknowledged `Publish Existing Chaos Survival` workflow remain separate. Existing public game: `https://www.roblox.com/games/95351659174730/Chaos-Survival`.

## Next major visual systems (NOT included in this navigation fix)

The owner also reported blackish floors despite bright neon, basic flat platforms and unclear first-time objectives. Midtone-specific PR #548 addresses floor fill on the next unpublished source. The route-topology and first-time guidance systems need independent **real Android** validation, not a claim that this AI patch makes them premium.
