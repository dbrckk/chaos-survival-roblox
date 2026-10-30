# Chaos Survival — Storm Harbor original deck finishing, post-publication iteration
_Date: 30 October 2026. Candidate SOURCE ONLY, explicitly excluded from the concurrent public release until its SHA is validated separately._

## Actual fifth-map defect

The common `ArenaDeckFinishKit` provided proper, tiered floor finish recipes for Classic, Towers, Crossroads and Orbital only. Storm Harbor returned **zero authored macro details**, even though it is a complete 320x320 real playable map with 80 jumpable platform parts, 4 storm cargo switchback routes, imported creator-owned 3D assets and four crane models.

The separate `arena-surface-detail.client.lua` also treated Harbor like Classic in its generic `addPanelLanguage` path, adding very long metal grid survey seams, repair plates and neon insets which conflict with the visual semantics of a weathered maritime timber port.

## Finished source candidate

- New dedicated Harbor `ArenaDeckFinishKit` recipe uses `WoodPlanks`, `CorrodedMetal` and restrained `Metal`: **Low = 2**, **Medium = 4**, **High = 6** real 3D cosmetic Parts. Named drydock planks, freight rails and mooring cleats, all positioned at quiet outboard areas, **inside** the base extent, outside known spawning and sweep-lane footprints. These are not fake bridges, arrows or player-interactive items.
- `ArenaDeckFinishKit.build` already creates anchored, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false` cosmetic parts, and records `SurfaceBaseColor` for consistent existing disaster colour reactions. The previously implemented `ArenaFloorFollowerKit` automatically follows authoritative base-size contraction during Shrinking Arena; no new loop is required.
- A Harbor-specific early branch in `arena-surface-detail.client.lua` **replaces** the generic oversize survey grids with short timber plank joints and cargo-grade corroded-metal fixings. Allocations are capped at **2 on Low**, **8 on Medium**, and **12 on High** in this module, rather than the much larger generic seam/repair patch combinations that used to display.
- Combined with previously merged work, Harbor now has authored server cargo piers and scenery, original Low/Medium/High silhouette, proper localized player objective, distinct playable-platform finishes and visual side armor, real external cargo crane, and now independent floor macro/micro-detail. No new asset IDs, Roblox currency, UI panels, physics, remotes, raycasts, music, update loops or player privileges.

## Verification and publishing contract

Expanded **existing**, already-registered Roblox Open Cloud engine suite `tests/engine/vfx-quality.spec.luau` to construct an ACTUAL Harbor arena and verify the new 2/4/6 `ArenaDeckFinishKit` outputs, non-colliding anchored ownership, authentic Roblox WoodPlanks/CorrodedMetal/Metal, safe position within base, and exact shrink-follow semantics using `ArenaFloorFollowerKit`.

**Tests for this post-release follow-up have not yet been executed.** Do NOT publish this feature on the public place until its own exact-SHA build and Roblox Cloud engine tests pass. The in-progress Harbor 3D publish workflow for SHA `58af603f185c2adebabd70517ce37f36b778aea8` must first complete; merging into main prematurely would cause its exact-SHA safety gate to abort.

### Physical Android and PC review

- Screenshot Harbor Low, Medium and High in 3 light/weather states and compare with Classic. Verify neither Classic axis nor Orbital glass trims; Harbor looks like timber/steel docks.
- Confirm all new details stay outside first eight spawn points, cyan mobility pads, HarborCargoSweep safety zones and platform navigation arrows; no decoration appears to be a solid ledge.
- Trigger Shrinking Arena and verify floor macro pieces contract in both X/Z dimensions rather than forming phantom floors.
- Verify all 80 real Harbor platform families remain jumpable and all cosmetic Parts remain CanCollide/CanTouch/CanQuery=false.
- Capture FPS/frametime from representative Android Low and Medium before claiming 30/60 FPS. No performance results can be inferred from code alone.

**Verified public status:** the preceding 3D/physical-platform version has now **successfully published** as SHA `58af603f185c2adebabd70517ce37f36b778aea8`, [public publisher 41092002110](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41092002110), after green [exact-SHA gate 41091311509](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41091311509), [Build Validation 41091324370](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41091324370) and [Roblox engine tests 41091334778](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41091334778). The **additional** Harbor deck finishing described in this document is a new source-only improvement; it is *not* in the live experience until its own later validation and publish. No physical Android visual/FPS certification has been claimed.
