# CHAOS SURVIVAL — real original 3D colossal air carrier

## Why this replaces a visible primitive

`src/client/ArenaSkyFleetKit.lua` currently builds two, three or four enormous airships per map on Low/Medium/High from native Part/WedgePart boxes (`ArmoredKeel`, `FacetedBow`, `SternGuard`, side wings and engine pods). These shapes dominate the sky, and are notably behind the original 3D district/route/ground assets in visual quality. The five per-arena variants' animated identity parts must remain, but the airframe itself needs genuinely sculpted mesh topology.

## Real original geometry created

`tools/generate_original_skyfleet_carrier.py` generates the creator-authored `chaos_skyfleet_carrier.obj` reproducibly, using the existing seven original `chaos_route_kit.mtl` materials.

- **4,118 triangulated faces**, **2,243 OBJ vertices**, **96 authored groups**, **7 distinct material primitives**; no native Roblox Part, unknown marketplace mesh, magic asset ID or placeholder.
- Continuous eleven-sided tapered armored monocoque; recessed sensor cockpit; two genuinely swept articulated solid-chine wings and ribbed skin; two tapered sixteen-sided engine nacelles, real toroidal cooling coils, exhaust hardware, metal control rods and mechanical dorsal plates.
- Measured **53.2 studs across X × 19.63 tall × 49.6 long Z**, a genuinely colossal prop, with a distinctive noncubic airframe and seven authored metallic/ceramic/grip/signalling material masks. The original 3D contains UV/tangent information after glTF export but **no new 2K normal-map asset**; don't conflate metallic-roughness factors with full 2K SurfaceAppearance.
- Scale and triangle limits enforced in the generator; `tools/obj_to_gltf.py` remains the single official, audited original source-to-import conversion.

**Actual independent source validation passed:** [GitHub Actions #41633912610](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41633912610). It generated source OBJ, converted to embedded glTF 2.0, verified matching 4,118 triangles, all 7 material primitives, POSITION/NORMAL/TEXCOORD_0/TANGENT per primitive and verified buffer bounds. The genuine OBJ and glTF are attached as inspectable run artifacts. This is geometry evidence, not a screenshot of Roblox.

## Authorized Roblox import and release plan

1. The one-time `.github/workflows/one-time-import-original-skyfleet-carrier-20261103.yml` uses the existing limited owner-ID/secret-controlled Roblox Assets uploader and real moderation response. **It never publishes the playable place.**
2. Only after obtaining a real `Model` asset ID with `Approved` moderation: record provenance in `assets/source/roblox-asset-registry.json`, sanitize through `OriginalMeshScenery.sanitize`, and cache an inert, verifiably MeshPart template server-side. Fail closed: the existing skyfleet always remains visible if import/load fails.
3. The existing `ArenaSkyFleetKit` should replace only the *main airframe* primitives with the same true 3D model for up to 2/3/4 locally generated ships, keep all five arena-specific moving components and reversible fallback. Never make a carrier stand on the route or become collidable; preserve other native props' motion. No additional render, network or LOD loop. Count all new MeshParts against the existing `ArenaSkyFleetLocal` visual census.
4. Validate exact committed source Luau/Rojo/build, all five Roblox Cloud engine suites and the guarded public release. On actual Android, inspect side/backface winding, proportions, silhouettes, material visibility, LOD, FPS and thermal/memory impact. Do not claim final AAA visual certification until authentic captures exist.

## Verified Roblox package and real game integration

The creator-scoped asset upload finished successfully: [Roblox import #41634338244](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41634338244) returned **Model package ID `84239592388200`, moderation `Approved`**, not an invented raw MeshId.

- `assets/source/roblox-asset-registry.json`: fourteen exact approved packages; the carrier's reproducible source `assets/source/chaos_skyfleet_carrier.obj` is generated before Build Validation checks the registry.
- `PremiumSkyfleetMeshAssets.lua`: independently and belatedly loads only the approved Roblox Model asset, sanitizes the full geometry and embedded materials using the existing strict `OriginalMeshScenery.sanitize`, rejects any native Part or unexpected mesh count/dimension. One delayed asset fetch lane avoids compounding join-time Roblox API throttling.
- `ArenaSkyFleetKit.lua`: each aircraft now mounts the **actual imported and sanitized MeshParts** instead of generic box-keel/wings/bow/thrusters/pressure-deck primitives, while preserving the existing five arena-specific mechanical, animated signature details. The imported mesh components join the same existing `ship.parts` motion and scenery LOD registry. No physical parts or hazard logic are affected. If the asset fails to load, **all original native carrier hulls stay unchanged**.
- `arena-sky-fleet.client.lua`: a single `ChildAdded` listener replaces the native fallback on real late asset arrival; no polling loop or client-side asset fetch. Quality rebuilds already existed.
- The original skyfleet owner already appears in `VisualBudgetRules.LocalFolders` as `ArenaSkyFleetLocal`. All genuine MeshParts are therefore included in existing Low/Medium/High local visual limits, without a new GPU quota or render task.

**Physical Android and Studio screenshots, performance (FPS/p95/memory), normal/winding validation and visual inspection** remain required, and the engine/build tests do not replace them. Only a successful exact-SHA guarded public publisher can be called a released version.
