# Chaos Survival — Storm Harbor physical-deck and exterior freight identity
_Date: 30 October 2026. Source candidate after successful 82f925c Roblox public update._

## Problem corrected

Storm Harbor's physical route platforms are **real WoodPlanks server geometry** with seven per-route dock steps and additional perimeter/branch/crosslink traversal. The separately constructed client presentation did not support the Harbor variant in the generic `PlatformFinishKit.NAMES` table, and `arena-platform-identity.client.lua` fell through to Classic's calibration-axis marks. That combination meant every Harbor physical dock lacked the shared protective armor/load-brace and visual finish system while showing glowing Classic Grid survey marks. A third module, `arena-architectural-details.client.lua`, still built Classic's broadcast archive structure in Storm Harbor despite the already-authored Harbor silhouettes and server gantry fleet.

The purpose is a single coherent **maritime timber/steel identity**, not additional generic neon.

## Actual implementation

### A. Harbor is a first-class platform variant

- `src/client/PlatformFinishKit.lua` has a dedicated `Harbor` finish recipe consisting of **real timber splice, corroded cargo steel band, and underside metal keel**. All are created as **local, massless, non-colliding Parts welded to the actual physical server deck**, and preserve the same Low (1), Medium (2), High (3) trim budget already used by the other four arenas.
- The same existing `buildArmor` and `buildLoadBraces` pipelines now support Harbor, giving Medium 2 protective corners + 2 structural braces, High 4 + 4, and **zero** extra armor/braces on Low. Structural decorations are still local-only and collision/touch/query free. `CollapsePhase` hides them with actual platforms; Shrinking Arena footprint bindings follow server deck dimensions, preventing ghost ledges.
- `arena-platform-identity.client.lua` replaces the Classic fallback with `decorateHarbor`: 1 short corroded-steel cargo lashing on Medium, an additional below-deck timber mounting support on High, **zero additional Harbor ornaments on Low**. The lashing is intentionally shorter than the platform width and is NOT presented as a traversal arrow or obstacle; the player's authentic neon takeoff chevrons remain independently available. Only `Classic` uses Classic markings now.

### B. Harbor has its own exterior freight-stacker landmark

- `arena-architectural-details.client.lua` no longer creates Classic's transmitter at Harbor. Instead it assembles a **freight crane** outside the original 320×320 studs playable floor, with dual steel legs, a large crosshead and inclined boom, suspended timber cargo box and matching, layered metal rigging.
- Low has the original **five-part** silhouette (2 legs, crosshead, boom, cargo). Medium adds cables, diagonal bracing, feet and a cab. High adds four steel container ribs and a load rail, with two tiny cable/cargo components tracking the **same existing 5-Hz decorative animation owner**, not a new frame loop. Animated ribs are synchronized to the animated cargo so they do not pass through it.
- Built-in Roblox materials, not unlicensed asset IDs; no changes to server navigation, disasters, performance logic or Roblox data stores. `CastShadow`, touch/collision/query are disabled except already-existing optional High shadows on the large metal frame. No runtime fetches, paid libraries, remotes, extra Heartbeats or raycasts.

### C. Genuine low-end optimization

All Harbor cosmetic variants use `VfxQuality.deviceTier`, which respects touch-device constraints and owner-selectable quality tiers. The first-session physical platforms do not gain new collision or heavier textures. No additional Harbor floor geometry on Low beyond the earlier basic deck detailing.

## Required release validation (only at a major publication milestone)

1. **Exact-SHA GitHub build + Roblox Open Cloud Engine Tests**: the already-registered `tests/engine/vfx-quality.spec.luau` now verifies actual server Harbor platform geometry, 1/2/3 Harbor-specific finish materials, legitimate non-colliding welds, Medium/High armor & braces, zero Low armor, and complete disappearance/restoration under `CollapsePhase`. Earlier tests also verify Harbor's 4 original external gantries and navigation.
2. **Android Low / Medium / High**: collect source-matched images of a real Harbor platform and the outside freight yard, compare with Classic. No Classic axis/bar markings or Classic radio mast, clear route takeoff arrows, no hidden locally anchored interior decorations, and correct reduced-motion behavior.
3. **Shrinking Arena**: a platform with new Harbor finishing shrinks; all local weld armor and keenly visible panels follow actual collidable footprint. No free-floating hulls, invalid targets or dangerous missed jump cues.
4. **Frame budget**: report 30 FPS p95 on representative low-end Android and 60 FPS p95 on suitable midrange hardware **only after real measured playtests**, not from source alone. Record client-owned decorative Part counts and active tween/callback counts.
5. **Publication gate**: dispatch only the existing safeguarded public-place publisher after successful exact-SHA Build and Cloud Engine tests. Do not replace the public place with an unknown SHA, and never treat this source feature as published until GitHub confirms a successful run.

**Last independently verified public Roblox release before this pass:** `82f925c320b2525a58acb4944e74435a75a2795c`, [GitHub Actions publisher 41088325686](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41088325686). This document itself does not publish Roblox.
