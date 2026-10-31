# Chaos Survival — Original 2K PBR on true entry doors and ceramic wings

**31 October 2026 | Source-only visual improvement after #441**

## Code-level diagnosis

The four original image sets (16 verified, creator-owned 2K textures with Color/Normal/Roughness/Metalness) are already present in `MaterialService`, and the client's PBR selector enforces the following unchanged total Android quotas: **Low 0 / Medium 32 / High 72** active surfaces and 0 / 6 / 16 per ordinary model.

Two separate correctness problems were found after the district facade and near-route silhouette passes:

1. The approved original `ServiceEntryDoor` on each of **16** `ArenaDistrictArchitecture3D` Models is a 4.65 × 4.68 × **0.18** stud Part. `PbrDistrictRules.eligiblePart` required **every dimension >= 0.35 studs**. Consequently, the previous door-specific PBR family mapping and entrance priority could *never* apply to any real service door. Each front door had just native Roblox metal/ceramic finishing, not the approved 2K variant.
2. The new Orbital `DistrictOrbitalContainmentWing` is natively made from `CeramicTiles`, but its name does not contain the substring 'ceramic'. The old name-only `materialKey` could select the **brushed titanium** MaterialVariant and make a clearly ceramic, nonmetal wing look metallic.

## Implemented

- A narrow `canonicalServiceDoor` eligibility exception permits the existing 0.18-stud entrance surface **only** when it is an original Part under the canonical `ArenaDistrictArchitecture3D` folder, in a server-labeled `ArenaDistrictArchitecture` + `SourceIsOriginal` + `CosmeticOnly` Model with an integer district index in 1..16, physically matching the original width, height and shallow thickness.
- All existing safety gates still apply first: anchored, no collide/touch/query, nearly opaque, not Neon/Glass/timber, visible under the true scenery LOD, untouched authored `MaterialVariant`, original-mesh restriction, correct distance.
- Strengthen entrance importance within the **unchanged** original per-owner/global selection budget so a near player-facing door can win against inconsequential high roof trim. No new surfaces are added; the selector already implements camera-facing importance, distance, hysteresis and diff-only reconciliation.
- After exact original foundation overrides, a **native `CeramicTiles` source material** selects the existing creator-owned **ChaosReactorCeramic** MaterialVariant, even when the name says *ContainmentWing*, instead of incorrectly falling through to titanium.
- The previously authored `PreserveNativeMaterial` on Crossroads concrete and Harbor timber still overrides all of this. Roblox platform gameplay geometry and player collisions are never in the PBR candidate pool.

## Expected visual impact (not yet measured)

- **Classic:** entry door can show original anti-slip diamond-armor relief.
- **Towers:** brushed metallic entry door matches machined tower treatment.
- **Crossroads:** door can carry approved armor PBR; actual concrete canopy stays native.
- **Orbital:** ceramic airlock, recess and nearby containment wings preserve nonmetal ceramic normal/roughness response.
- **Harbor:** steel door can take approved oxidized metal maps; wooden canopy stays untouched.

This is a *selection policy correction* for existing 2048 × 2048 Roblox images. No new texture upload, new synthetic/placeholder IDs, decals, lights, Parts, replication, animations or loops. The underlying native material fallback is retained when PBR is off or runtime variants are absent.

## Acceptance required at release milestone

No interim engine tests run per owner's project policy. Before publishing the exact final merge SHA:

1. Complete manual Build Validation and all five Open Cloud Roblox Engine suites on the exact release SHA.
2. Android Medium/High: camera within 50 studs of each original sector entry; inspect normal-map emboss, roughness and metalness in daylight and disaster lighting. Confirm candidate/active counters remain <=32 / <=72.
3. Android Low or PBR manually disabled: verify native door, ceramic and wooden architecture remains correct and zero 2K variants are active.
4. Confirm imported MeshParts retain UV-authored SurfaceAppearance and `PreserveNativeMaterial` concrete/timber retain original appearance.
5. Check 16-model streaming and scenery LOD: panels/doors never become visible when culled, PBR budget returns on stream-out, and no temporary color/metal flashes on turn or tier change.
6. Capture actual Android frame time, GPU memory and thermals; do not infer visual certification merely from successful metadata approval.

The public Roblox place (Universe `10771083668`, Place `95351659174730`) is **not** updated by this change.
