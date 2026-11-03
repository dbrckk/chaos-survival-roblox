# VIS-001 — Original 3D assets, 2K PBR steel finish and release repair

## Cause confirmed

The public-experience update at source SHA `49329942899ff0e9895d6756e40b08690582dcca` was blocked, correctly, by the actual Roblox Open Cloud engine suite [41606219369](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41606219369): 357 passing, one failing. The one stale expectation in `tests/engine/arena-variants.spec.luau` asserted FOUR total footing pieces after the actual source upgrade now creates ELEVEN for an authentic full-size original mesh.

This is a **test-to-source mismatch**, not an instruction to loosen collision, ownership, dimension or position checks. Do not suppress the test failure. Older tiny 13 x 12 x 3 mock asset still correctly creates FOUR; the new chassis applies only where both source mesh horizontal dimensions are at least five studs.

## Scope

- `OriginalMeshScenery.addFoundation`: retain four approved native base strata, two I-beam flanges, two angled wedge buttresses, two maintenance rails and one asset-specific technical module (11 approved cosmetic pieces). Real imported original MeshParts remain unchanged and sanitized; all eleven additions are noncolliding, non-touching, non-queryable, no dynamic lights/shadows and lower than the original mesh's lowest point.
- Record `OriginalFoundationPieceCount` on the actual model to enable runtime verification on streamed clients and distinguish a full-size eleven-piece chassis from a small four-piece fallback.
- `tests/engine/arena-variants.spec.luau`: enforce the exact complete set, attribution, wedge topology, in-game five-arena clearance, full chassis count, idempotence, bounding box dimensions, material provenance and cosmetic collision safety. No new test suite is added.
- `tests/engine/mapbuilder-advanced.spec.luau`: preserve the four-piece fallback assertion for the deliberately narrow model.
- `PbrDistrictRules.lua`: permit **only two approved I-beam Part names** to receive the creator-owned original armor PBR set (Color, Normal, Roughness, Metalness) within the existing per-owner **one Medium / two High** and global touch-device **32 Medium / 72 High** quotas. No new material IDs, no new render loop, no texture override on source MeshParts or wedges. Steel plates are mapped to `armor` instead of looking like generic brushed titanium.
- `tests/engine/arena-material-rules.spec.luau`: extend the existing asset provenance test to require exact original package ID and original part ownership tags and to reject unapproved wedges/foreign IDs.

## Release and honest acceptance

The branch-only full Luau/Android VFX/complete Rojo milestone **passed**: [41611257710](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41611257710).

**This document does not constitute a successful public release.** The next main SHA must independently pass Build Validation **and all five real Roblox Cloud engine shards** before the existing guarded public publisher may update Universe `10771083668` / Place `95351659174730`. Authentic Roblox Studio screenshots for all five arenas and physical Android FPS, textures, shadow visibility and loading still remain outstanding; do not mark full AAA visuals or Android QA completed merely because the compiler passed.

## Follow-up: actual PBR allocation versus eligibility

The restored steel I-beam whitelist is necessary but by itself insufficient: the owner's old four much larger base slabs beat a narrow steel flange on surface-area priority. A client with one/two per-owner PBR selections could therefore spend both approved slots on flat slabs and render neither new flange in armor PBR. The same existing scoring function now adds a **local structural score of 2200 for the two original explicitly tagged I-beams**, within the unchanged global/device quotas, allowing Medium to select the camera-relevant one and High up to both when the global budget permits. Source MeshPart UVs still cannot be touched.

The extended preexisting material engine test compares a marked I-beam with a larger original FoundationShoulder and asserts the unchanged owner quota. Eligibility does not guarantee PBR on every far model: camera-distance rules, Android tier and global limits still apply.
