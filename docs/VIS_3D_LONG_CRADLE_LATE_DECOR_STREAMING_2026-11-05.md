# VIS-009 / VIS-010 — genuine 3D long structures on progressive streaming

**Date:** 2026-11-05. **Repository:** dbrckk/chaos-survival-roblox, main. **State:** code committed, not necessarily live/published.

## Reproduced source-path gap

- `PremiumLargeStructureMeshKit.selectNearRouteStructures` returned **zero** eligible LongCradles and columns when `Arena.Decor` was not yet replicated, although `Arena.Platforms` and owner-approved original `LongCradle` source were available.
- `arena-platform-identity.client.lua` watched map Base, Platforms and late approved Models, **not** the `Decor` folder or server-authored `PlatformSupportN_K` streaming events. Thus authentic tall support columns could stay absent for the whole current map, showing native rectangular supports after the late folder/parts appeared.

## Implemented

1. LongCradle candidates now depend on verified physical platforms and approved original sources, **independently of the optional Decor folder**. Its exact geometric coverage, 4 High / 2 Medium cap and collapse/shrink owner are unchanged.
2. Support source verification is conditional on an existing real `Decor` folder; absent/late supports cannot consume an approved column budget. Never fabricate posts or colliders.
3. The same existing visual owner subscribes to appearance/replacement of `Arena.Decor` via `MapVisualReadiness.watch` and to **only** `PlatformSupportN_K` additions/removals. A single 0.18-second scheduled batch coalesces streaming bursts, with generation invalidation on map/folder switch and explicit event disconnection. No camera polling or new render-loop owner.
4. Genuine structurally verified MeshParts mount via existing weld/visibility/native-fallback contracts; hazards, shutter warnings, real physical routes, `Low` tier, eight-player simulation and server scripts remain untouched.

## Milestone checks remaining

One exact-SHA Build Validation and seven real Roblox engine suites on next important milestone. Actual Roblox Studio/Android low-medium-high captures must check early join, late Decor arrival, support loss, shrinking and the five distinct arena identities. Pass in CI is not proof of visual coverage, performance or publication.

## Android streaming rebuild-budget amendment

The existing full-map visual rebuild owner now batches PlatformN streaming bursts into one scheduled 0.12 s reconstruction instead of repeatedly re-creating the whole map once per deferred network batch. The Decor watcher only queues post-driven reconstructs for Medium/High when an actual approved variant source is present; template arrival itself already triggers the existing source watcher. The native hazard/shutter/collapse callbacks and physical server colliders are unaffected. No runtime FPS claim or actual-device proof is made.
