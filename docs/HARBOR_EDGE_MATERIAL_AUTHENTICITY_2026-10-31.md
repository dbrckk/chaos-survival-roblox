# Chaos Survival — Harbor perimeter architecture and authored material safety

**31 October 2026 — source-only visual improvement on `main` after PR #440.** No Roblox engine execution, Android capture, public publish or performance certification has been performed.

## Existing problems found in the repository

1. `ArenaEdgeFinishKit` was invoked on **every** arena through `arena-edge-profile.client.lua`, but supported only Classic, Towers, Crossroads and Orbital. Storm Harbor silently returned an empty list. Harbor already had authored cargo motifs elsewhere, but this specific 4-sided perimeter-finish layer was missing.
2. `ArenaMaterialRules.targetMaterial` did not recognize Harbor. Its default `else` used the Classic metal/diamond-plate variation vocabulary for Harbor instead of maritime corrosion.
3. `material-variation.client.lua` selected any matching `BasePart` under the replicated arena Decor, including pretextured `MeshPart`s and surfaces carrying explicitly authored `SurfaceAppearance` or `MaterialVariant` overrides. A near-surface cosmetic color/material perturbation must not interfere with a proper 3D artist's UV/material treatment.

## Integrated work

### Four-sided native Harbor perimeter detailing
New names are added to the **existing** ArenaEdgeFinishKit motif catalogue and are built by the original `ArenaEdgeProfileLocal` owner:
- **Low**: one broad, matte **WoodPlanks fender beam** under each of four edges (4 local Parts total), easily readable in a wide mobile camera without emitting light.
- **Medium**: a weathered steel **fender backing plate** on each side as well (8 local Parts total).
- **High**: add one physically dimensional, fixed **cylindrical mooring roller** per side (12 local Parts total).

All elements sit on the exterior below-deck fascia, **not** the walkable top. They remain anchored, noncolliding, untouchable, unqueryable and shadowless. No extra animations, lights, resources, networking, imported assets, unknown material IDs or loop are introduced. The original `ArenaFloorFollowerKit` owner follows actual Shrinking Arena footprint changes and releases the parts on map/quality changes. The existing visual telemetry counts `ArenaEdgeProfileLocal`.

These additions are exclusive to Harbor. Four other arenas retain their original per-side `1/2/3` budgets unchanged.

### Correct material identities and imported model protection
- The existing material variation policy now handles **Harbor explicitly**: a limited existing percentage of steel receives `CorrodedMetal`, `DiamondPlate` receives matte `Metal`, while authored `SmoothPlastic` remains untouched. The Low tier still retains native materials.
- The cosmetic material variation client does **not** mutate MeshParts, UV-authored SurfaceAppearance geometry, existing MaterialVariant overrides or parts explicitly tagged `PreserveNativeMaterial`.
- This is **not** a claim of new 2K PBR textures, new normal/roughness/metalness maps, or improved imported asset texture resolution. It safeguards the existing authored texture work and gives native steel/timber visibly distinct physical structure.

## Cost and compatibility

- **Harbor perimeter new client geometry:** 4 Low / 8 Medium / 12 High anchored, local-only Parts total, inside one already-budgeted and already-updating owner.
- **Other arena perimeter geometry:** unchanged.
- No new server geometry or additional replication; no changes to physical platforms, playable arena dimensions, movement, bots, disasters, controls, navigation, inventory, rewards or saves.
- No new external dependencies or license concerns.
- Existing texture/PBR system remains opt-out-capable and quota-controlled by its own owner.

## Milestone acceptance before any public Roblox update

Owner requests deferring heavy tests until an important milestone. **No tests are run during this improvement pass.** At the next exact-commit release gate:

1. Compare Harbor perimeter from the **player's camera** at Low, Medium and High; confirm timber fenders and steel plates read as cargo-dock infrastructure, not as a false safe ledge or route arrow.
2. Activate Shrinking Arena and observe that all four-sided pieces follow the actual platform footprint without becoming floating collision surfaces; confirm zero collision/query/touch.
3. On every arena, confirm imported 3D meshes retain their original color and SurfaceAppearance, and authored material variants are not swapped by generic variation.
4. Verify Harbor native metal can vary to rust under Medium/High without corrupting actual timber and without affecting active hazard warnings.
5. Record mobile CPU/GPU/frame-time and thermal data, full screenshots across the five maps; then run the repository's manual Build Validation and all five Roblox Open Cloud Engine suites on the **exact intended merge SHA** before an owner-approved public release.

**Roblox IDs protected:** Universe `10771083668`; Place `95351659174730`. No Roblox publication has been performed.
