# VIS — Keep actual platform 3D trim near the player at the 320-stud rim

Date: 2026-11-05. Chaos Survival Roblox. Product source milestone, not a public release or measured mobile visual QA.

## Inspected defect

`scenery-lod.client.lua` treated `ArenaPlatformIdentityLocal` as one monolithic cosmetic folder. On mobile Low, a 105-stud cutoff and on Medium a 165-stud cutoff were applied from the **center of a 320×320 map**. Consequently, when the camera reaches an authentic peripheral parkour platform, all of that platform's bevels, decals, original owner-approved MeshParts, structural side treatments and route markings could remain `LocalTransparencyModifier=1` despite being right beside the player. The platform's collidable top and hazard warning remain visible, but the surrounding scene appears generic.

## Corrected using actual source and physical ownership

- `PlatformIdentityLodRules.owner` accepts only the existing exact `ChaosPlatformTrimWeld` or `PlatformIdentityWeld` pointing to an actual `Arena.Platforms` Part, or `OriginalSupportVisualWeld` pointing at a correctly named, anchored, noncolliding original `Arena.Decor` support. It does **not** mutate or hide any gameplay Part.
- From the existing 0.65/0.90-second scenery sampler, `applyPlatformIdentityNearPlayer` uses `min(camera-to-arena-center, camera-to-actual-native-owner)`. Same Low 105 / Medium 165 cutoffs and per-owner hysteresis; High remains unculled. Center looks as before, but a genuine route near the rim keeps its original authorized 3D cosmetics. An unrelated/unverified local decorative element still uses the original center cutoff.
- A cached owner distance is evaluated at most once per true native platform in each already-running LOD pass. `SceneryLodCache` still handles late streaming, cache invalidation, and quality changes. Old owner references are dropped after each pass to avoid memory retention across games.
- All VFX/effects/part masks remain on the existing `SceneryLodHidden` + `LocalTransparencyModifier` contract; `ChaosBaseTransparency` and the server's `CollapsePhase` / `BridgeShutterPhase` still independently control physical warning overlays. No render loop, asset, texture, lighting, RemoteEvent, collider or player movement changes.

## Validation boundary

Milestone: real Luau Build Validation, unchanged existing 7 Roblox Cloud engine suites, expanded visual-budget suite for welded physical ownership, approved native supports, center conservation, Low/Medium genuine proximity and invalid anchors. Android/PC screenshots at four perimeter routes, shrink/hazards/bridge shutters, and FPS must be separately inspected; this patch alone does not certify premium visual quality or publish to the public experience.
