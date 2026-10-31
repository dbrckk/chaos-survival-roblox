# Android — four playable-sector setpieces use individual distance LOD

31 October 2026 · Source-only optimization following the real hero-origin fix in PR #474.

## Confirmed source issue

- The four original client-owned sectors in `src/client/district-sector-setpieces.client.lua` have independent original 3D Model pivots at `(±min(116,halfX-26), ±min(88,halfZ-38))` relative to the arena Base (320×320 studs by default).
- Previously the single root `DistrictSectorSetpiecesLocal` Folder was culled against **arena center** with **245/255** Low/Medium thresholds. All four monuments became visible/hidden together even if the player stood beside one and another was nearly 300 studs away.
- On Low this kept four 5-part silhouettes active unnecessarily across the map; on Medium it could retain far richer geometry and 2K PBR candidates, while close-range monument visibility depended on the unrelated arena center.

## Finished fix

- Preserve **exactly the existing** 245-stud Low and 255-stud Medium LOD thresholds and 8-stud hysteresis. High remains fully visible.
- The existing `scenery-lod.client.lua` 0.65/0.90-second loop now applies the already-existing `applyFolder()` per Model, using each `Model:GetPivot().Position`, **not** the shared parent Folder.
- Only Models explicitly marked `LocalOriginal3D=true`, `CosmeticOnly=true` and integer `DistrictSector=1..4` may enter this logic, under the exact existing local sector Folder.
- No new model, geometry, lights, quality-budget changes, physics, signals, graphics loops, Remotes or gameplay logic. Existing sceneries' `SceneryLodHidden` and `LocalTransparencyModifier` tracking now reflect each actual sector. The original PBR observer and MaterialVariant selection already use those visibility flags; they automatically follow the new per-model culling.
- The previous Folder-level writer has been removed to avoid two independent LOD owners alternately hiding/showing the same client geometry.

## Acceptance at the next major gate

1. Verify all four sectors in each of the five real Roblox arenas on Low/Medium/High. On Low, each **near** sector's recognisable five-part silhouette must remain visible, while a remote sector is allowed to cull independently beyond 245 studs. High always retains the authored details.
2. Check camera movement across corners: no simultaneous hide/reveal of all four monuments, no visual popping at 8-stud hysteresis, no flashing when switching VFX tiers.
3. Verify that original static sector decals/3D elements and optional PBR materials respect `SceneryLodHidden`; authoritative platforms, caches, prompts, lava and hazard warnings remain visible and function.
4. Run exact-commit Build Validation, five Open Cloud engine suites and actual Android visual+FPS inspection before any further public publishing.

No new unit tests were created. Static source checks and PR diff review are **not** a substitute for genuine Roblox runtime proof; no public deployment is claimed.
