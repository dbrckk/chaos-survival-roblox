# Chaos Survival — Lava crust and disappearing-platform gap readability

**31 October 2026 — source-only visual/UX improvement after PR #445.** Do not confuse this merge with a public Roblox update or engine/device certification.

## Actual problem observed in source

- `disaster-premium-vfx.client.lua` drew a nearly uniform full-size Neon orange `LavaSurfaceLocal` over the **real** rising lava object, with bright yellow-orange embers that stayed overly incandescent as they aged. The result had little recognizable volcanic surface structure despite already having a one-Part overlay and one emitter. A second mesh or independent custom PBR atlas is not necessary.
- `disappearing-platform-readability.client.lua` maintained all four amber border segments around a **Gone** platform (no collision, effectively invisible), for up to the entire 2-second outage. That left an empty-space rectangle that could read as a traversable platform. Six rendered local parts continued animating even though the missing platform was known to be fully gone.
- The collapse cosmetic owner also used `VfxQuality.get`, defaulting to High before the adaptive tier was available on Android.

## Changes made to the existing owners

### Rising lava
- Keep the **exact same one original client-only, noncolliding surface Part**, but use Roblox's built-in `Enum.Material.CrackedLava` (supported by Roblox Engine Material) instead of featureless `Neon`.
- Matte-hot red/orange colors with small, restrained heat-tint pulses expose the native fissure pattern; the original server-owned `RoundLava` stays bright Neon and remains the *sole authority* for touch/damage and rise height.
- Reuse the one original `LavaEmbers` emitter at the exact same quality/reduced-motion particle rate. Hot sparks finish as darker cinders rather than a permanently orange particle; lower emissive intensity leaves the existing `SurfaceLight` responsible for broad illumination.
- Centralize the overlay transparency calculation on initial placement, normal updates and tier/accessibility rebuilds. ReducedMotion retains a stable pulse; the established VFX update interval is unchanged.

### Disappearing platforms
- During **Warning**, preserve all existing amber outlines/X marks, individual audible proximity pings and server-synchronized physical collapse timing.
- On the authoritative `CollapsePhase="Gone"` transition, render a brief **0.42-second fade-out** of the same four warning edges. The warning X already becomes invisible in Gone, and remains so.
- After the local visual fade completes, destroy all **six** warning Part instances for that vanished platform, leaving true empty space. The established phase-listener remains attached so a future valid Warning rebuilds the original six-piece preview correctly.
- On a late-streamed platform already in Gone phase, the brief fade and removal happen the same way. On a map unload/phase restore, existing cleanup remains active.
- The initial tier selection now uses `VfxQuality.deviceTier` to start unknown-quality touch devices at Medium instead of desktop High.

## Performance and gameplay contract

- **No new Parts, textures, assets, particles, emitters, light sources, continuous loops, raycasts or remote events.**
- Existing hazard and platform geometry, physics, collision, damage, rising-lava safety cap, collapse warning length (1.35 seconds), Gone duration (2.0 seconds), bot counterplay, UI prompts and server ownership are unchanged.
- No change to `VfxQuality` global budgets or `DisappearingPlatformVisualRules` ownership logic.
- For a platform in the Gone phase, the new rule can reclaim **six client-only parts** sooner; the source does not claim measured FPS improvement or Android thermal optimization without real device evidence.

## Next important release gate (not executed here)

1. Run the existing manual **Build Validation** and **all five Roblox Open Cloud engine suites** on the exact intended release SHA.
2. In Roblox Android **Low/Medium/High**, inspect the lava from ground level and upper escape decks. Verify the cracked pattern is clearly recognizable while orange damage warning remains strong in day/night weather and catastrophic overlaps.
3. Activate ReduceMotion and change VFX quality mid-lava: verify the surface never flashes at origin, and there is exactly one cosmetic glow light and one ember emitter.
4. In a real disappearing-platform round, verify **Warning** retains strong amber contour/X, then **Gone** removes collision and the visual border fades within 0.42 second to an honest empty gap. Check all six client parts are reclaimed, and a future Warning recreates only its own pieces.
5. Verify late StreamingEnabled replication, quality changes and map swaps; record frame times, thermal state and effects/part counts before making any performance claim.
6. Do not publish to the live game until the release gate and visual acceptance are complete.

**Current Roblox identifiers:** Universe `10771083668`, Place `95351659174730`. The last confirmed public release is still the one identified in `README.md`.
