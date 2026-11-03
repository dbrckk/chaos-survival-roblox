# Original 3D underdeck chassis — owner-authored source, gated Roblox import

Date: **2026-11-03**. Scope: original playable-platform **underside structural art** for five 320-stud worlds, without any fake gameplay collider.

## Preexisting constraints verified in the actual repository

- Public main `5893e55bc7376ffde0e395ce1fe6d9a5b85b570c` is live on the existing Roblox game after successful [CI build #41642047111](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41642047111), [five real engine suites #41642057429](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41642057429) and [publisher #41642735726](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41642735726).
- `src/client/arena-understructure.client.lua` still creates visible generic `Part` ribs, long chassis bars, structural props and an Orbital `PartType.Ball` hub. They **are not** creator-owned UV-triangulated original 3D meshes.
- The live `PremiumRouteMeshKit` already renders genuine approved UV/tangent MeshParts on near jump platforms/sky bridges. The gameplay and shrink/collapse owner must never be replaced by cosmetic geometry.
- The existing 14 approved Roblox Models are carefully allowlisted in `assets/source/roblox-asset-registry.json`. A newly generated asset **MUST NOT** be inserted there as `Approved` until moderation + real upload receipt are verified.

## Original authored 3D sculpture

`tools/generate_original_underdeck_chassis.py` creates `assets/source/chaos_underdeck_chassis.obj` deterministically (source OBJ is generated during builds, not committed as huge binary). Approximate envelope **23.3 × 4 × 10 studs**, composed of open-lattice dual web beams, X/Z braces, hollow torsion conduits, shaft cassettes, mechanical ventilation/torque modules, real 3D retaining shoes, transverse ribs, maintenance signals, asymmetric real occluding geometry and negative space. Seven distinct metallic-roughness glTF material families: `ARMOR`, `BRUSHED`, `CARBON`, `GRIP`, `ALLOY`, `CERAMIC`, `SIGNAL`.

The geometry is not generated from Roblox cubes, not a borrowed asset, and does not claim any author-approved `MeshId`. The generator reuses verified project-native chamfered mesh and radial tube *algorithms*, with newly authored geometry positions and groups. Every face is triangulated with a nondegenerate cross product, UV/tangent output is verified by `tools/obj_to_gltf.py`; minimum 1,400 and maximum 8,500 real triangles. **Top of all source vertices is below Y=0**, intended to align directly below the true collision platform rather than creating a second walkable surface.

## Import steps and safety

1. The one-time main-only workflow `.github/workflows/one-time-import-original-underdeck-chassis-20261103.yml` first generates `OBJ` + embedded `glTF 2.0`, validates all seven materials, geometry extent, triangle count and `POSITION/NORMAL/TEXCOORD_0/TANGENT`, and archives an inspectable source artifact.
2. Only after the source gate succeeds, the **preexisting** `.github/workflows/upload-original-3d-models.yml` sends a *single* owner-authorized Roblox Model creation request using the existing dedicated Roblox Asset API key. Asset owner ID `9774173158`. It makes **NO edits to the public playable place**.
3. A real response with creator-owned `asset_id` and moderation `Approved` is required before updating the registry and building a client runtime module. Failed/Unknown/Pending status must not be called approved; do not auto-retry the POST.
4. Runtime installation in the *next deployment milestone* must use the same known imported Model ID, server-side `OriginalMeshScenery.sanitize`, no client external asset fetches, client cosmetic clone set `CanCollide/CanTouch/CanQuery=false`, existing camera-quality sampling and actual platform safety. Preserve collapse, resize, shrink, streaming, route warning surfaces and default low Android quota.
5. Final public release only after exact-SHA green `Build Validation`, all five real Roblox Cloud engine suites and the existing guarded public publisher. Android screenshot, PBR visual correctness and FPS remain unverified until observed in the actual game.

## Actual approval and live runtime installation — subsequent milestone

- **Verified 3 November 2026**: source gate and owner import [GitHub Actions #41644715829](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41644715829) completed successfully: **3,072 triangles, 108 source groups, 7 PBR material families**, Roblox creator-owned MODEL **`84582262145054`**, moderation **`Approved`**, artifact `chaos-original-model-underdeck_chassis-metadata`. Imported creator `9774173158`, no marketplace copy and no invented MeshPart IDs.
- Registry now records **15** owner-Approved original Models and the exact evidence; `PremiumRouteMeshAssets.lua` loads the underdeck through the existing server-side `OriginalMeshScenery.sanitize`, with one serialized nonblocking loader lane for rate-limit safety. Without a verified template, the original deck/bridge native look stays intact.
- `PremiumRouteMeshKit.lua` mounts the new real imported MeshParts strictly under the **actual server-owned** safe 17+ stud platforms. The true collision deck remains unchanged and the cosmetically scaled/rotated **mesh upper surface is always below its lower face**. Every material MeshPart is `Massless`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`, and welded to the real platform. The existing `CollapsePhase`, `BridgeShutterPhase`, `Size`, `CanCollide` and `Transparency` signals immediately mask the cosmetic when the true route becomes unsafe; the base shrink gate retires it.
- New hard quotas: **Low 0 / Medium 2 / High 4** additional original underdeck MODEL instances. The same `PremiumRouteMeshLocal` owner exists in Android's shared 440/680/900 Part census, so every imported MeshPart remains accounted for. Existing real route MeshPart quota and camera-distance rules are unchanged; no additional RenderStepped/task polling or remote asset request is introduced.
- The client attribute `LocalOriginalUnderdeckMeshCount` reports how many genuine 3D machine instances are resident for visual QA (not how many are verified drawn by the Android GPU).
- The *existing* live Roblox Cloud bridge spec has been extended at this release milestone to ensure the approved Model selection, real geometry below the collider, no accidental collision and correct demolition/shrink cleanup.

**Status:** The approved original 3D geometry is connected to runtime source; publication and on-device visual validation still require green exact-SHA Build Validation, all five real Roblox engine test suites and the guarded public publisher. Do not call it live before those workflows succeed. The rest of the lobby/long understructure source still contains Roblox Part primitives and remains a separate major asset-production target.
