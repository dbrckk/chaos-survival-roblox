# Chaos Survival — long-lived impact geometry budget and Freeze expiry safety

31 October 2026 — source audit of `main` at `df214892d2872a945a70237730191caec0a5fcc9`. This change deliberately excludes current visual map inspection and Roblox public deployment.

## Confirmed source issues

1. `hazard-impact-feedback.client.lua` releases its only `activeBursts` slot after `duration * 1.35 + 0.08` (**~0.32–0.40 seconds**). In contrast, `ImpactSetpiece` fragments can persist for `0.85 + 0.12 = 0.97 seconds`, and material-aware airborne chips for up to `0.62 + 0.25 + 0.14 = 1.01 seconds`. A succession of nearby bursts could therefore allocate more 3D fragments while the prior fragments remained rendered. The existing peripheral cap restricts faraway effects but doesn't solve this near-field lifetime mismatch.
2. An offscreen impact on Android could still build a two-part low-tier `ImpactSetpiece` and raycast the ground, despite the viewport guard preventing expensive smoke/sparks.
3. In `disaster-premium-vfx.client.lua`, the previous Freeze-expiration fix cleared the ice facettes after their deadline **then immediately called `tryBindFreeze` on the same still-parented expired warning**. The metadata was still syntactically valid, so the same frozen parts were reconstructed every decorative tick until the server removed the warning. This is a reproducible state-machine regression visible from the control flow.

## Implemented

- **Independent long-lived Android decorative pool**: `ImpactPulseRules.decorativeBundleCap(tier, reduced, simultaneous)` applies the already shared optional `DisasterCosmeticRules.pressureMultiplier`. At one/two/three+ distinct recognized disasters, cosmetic bundle ceilings are **Low 2/2/1**, **Medium 3/3/2**, **High 4/3/3**. `ReduceMotion` returns zero because it already suppresses optional sculpture. Desktop retains its previous behavior.
- **Lifetime-aware reservation**: the separate `activeDecorativeBundles` counter is held for **1.10 seconds** after a permitted Android sculpture, long enough for the existing ~1.01-second material-chip lifetime, instead of being released when the ~0.4-second flash ends. `burstEpoch` ensures timers from deleted maps/old rounds cannot decrease a newer round's counter.
- **Always preserve compact impact feedback**: the existing local central flash and server-owned warning/damage logic do not depend on the new pool; the optional `ImpactSetpiece` and flying chips are skipped when the pool is exhausted or a burst is offscreen. Offscreen/over-cap mobile impacts no longer perform their previously unnecessary decoration-only raycast.
- **Rich visual budget**: on touch devices `richDetailAllowed` now uses the longer decorative occupancy as its concurrency index. On desktop, it keeps the original short-burst index. Emission count and survivor HUD remain unchanged.
- **Count only active recognized disaster identities**: the existing `RoundState` subscription tracks up to three unique recognized IDs, rejects malformed packets and older numbered rounds, and resets the decorative counter on real round/map transitions. No new subscription, polling or RenderStepped owner.
- **Freeze rebinding bug fixed**: both snapshot reads in `tryBindFreeze` now require a deadline strictly after `workspace:GetServerTimeNow()`. An expired but still-parented warning remains subscribed to metadata changes; it does **not** re-create geometry until server metadata truly re-arms it. ChildRemoved still disconnects pending metadata listeners.

## Important scope boundaries

This is a real cap for **this client's near-impact optional geometry**. It does not enforce an aggregate global GPU budget across all VFX owners. It does not change server damage, knockback, warning footprint, escape cues, collisions, movement, or result scoring. The compact pulse continues to have its original short burst budget.

## Next major-release acceptance criteria (deferred)

- Run Build Validation and the existing **five Roblox Open Cloud engine suites** on the exact merged SHA, then Android Low/Medium/High and PC sessions.
- During Meteor+Bomb Double Chaos, trigger many local impacts at <0.4s intervals for over 2 seconds. Monitor `ImpactSetpieceLocal` Parts, client raycasts, FPS, memory and p95 frame time. On Android check that the **long-lived optional bundles** never exceed 2/2/1 Low, 3/3/2 Medium or 4/3/3 High for 1/2/3+ disaster identities. Older bundles may finish their cleanup as counts drop; the policy does not delete already admitted art on an in-round density change.
- Check that each over-cap or offscreen impact still renders its compact flash/pulse when within the original short-burst budget; the authoritative danger cues never disappear.
- Switch `ReduceMotion`, graphics tier, round number, map, and spectator camera during ongoing explosions. Old deferred decrements must not corrupt new-round budgets.
- Leave an expired FreezeWarning object in workspace for 3 seconds: local `FreezeFacetWarning` Parts should disappear and **not repeatedly reappear**. Set fresh timing attributes on the same Part and verify one clean recreation and subsequent expiry. Verify pending metadata subscriptions are disconnected on cleanup.
- Compare actual FPS, CPU and GPU load instead of claiming unmeasured speedups.

Current visual map audit and public Roblox deployment remain postponed.
