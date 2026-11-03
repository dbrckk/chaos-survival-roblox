# Original sculpted Sky Spine Crown — source/asset milestone, 3 Nov 2026

## Reason
The **Sky Spine** on all five arenas is a real collidable ten-platform crossing, but its central upper interchange still has a native `Part`/`WedgePart` crown, cylindrical/spherical variant ornaments and straight neon strips. The preceding updates already imported true approved bridge decks, underdeck chassis and a lobby portal; this lot begins replacing the **large central high-route silhouette** with its own original real triangulated 3D geometry rather than stacking more Parts.

## Authored source
- `tools/generate_original_sky_spine_crown.py` creates a deterministic sculpted, chamfered, multi-rib structural crown with suspended machinery, recessed heat sinks, azimuth rotor and integrated guide inlay.
- Seven authored material groups, normals, UV and tangent-compatible existing glTF converter; target 1k–6.5k triangles, roughly 18×21×5 studs. No stock Roblox mesh and no fabricated IDs.
- **Open player aperture:** lower 12 studs are empty within `|X| < 6`. External support pylons are outside the 12-stud true playable deck. The decorative roof is above the jump/landing clearance.
- Only two genuine center sections `SkySpineStep=5/6` per arena should receive the future approved asset. Never replace the real server-owned `PlatformN` collision, change AI routes or create a false new path.

## Owner import (source only)
`.github/workflows/one-time-import-original-sky-spine-crown-20261103.yml` validates OBJ bounds, aperture, real triangle count, all seven material groups and embedded glTF buffer/UV/normals/tangents. It calls the existing `upload-original-3d-models.yml` under the **already verified Roblox creator ID 9774173158**, requiring the existing dedicated `ROBLOX_ASSET_API_KEY` and `UPLOAD_CHAOS_ORIGINAL_3D` acknowledgement. This creates a **Model asset**, NOT a new Roblox place or game publication. A successful upload still requires confirmation of an actual returned asset ID and `Approved` moderation before any runtime reference.

## Next implementation gate
After the asset ID and moderation are actually returned, add it to `assets/source/roblox-asset-registry.json`, build a server-sanitized replicated template using `OriginalMeshScenery.sanitize`, then a client-side LOD kit that authenticates `SkySpineInterchange` plus `SkySpineStep` and preserves `PerimeterPlatformIndex` hazard visibility. Enforce **Low=0 / Medium=1 / High=2** local crowns, reuse existing scenery scheduler, and retire/hide matching native crown components only while an authentic safe 3D model is mounted. Finish with actual Roblox engine suite, Android low-tier visibility checks and exact-SHA guarded public publication.

## Import propriétaire effectivement vérifié

- Diagnostic HTTP 400 de la première tentative : nom d'asset trop long, 54 caractères, refus `INVALID_ARGUMENT`. Correction du titre en `Chaos Sky Spine Crown 3D` et garde d'import `3..49` caractères.
- [Open Cloud owner upload #41660854748](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41660854748) : **Model `71492051540032` créé, moderation = `Approved`**, triangulation et 7 familles de matériaux attestées par la source.
- `PremiumRouteMeshAssets` valide le package serveur avec `OriginalMeshScenery.sanitize`, bounds de la sculpture et limite 12 MeshParts, puis replie un template vérifié. Aucun asset réseau ne charge côté client.
- `SkySpineCrownMeshKit` n'accepte que les vrais `PlatformN` collisionnels, `SkySpineStep=5/6`, `ChaosPermanentRoute=true` et `SkySpineInterchange=true`. Il conserve les rails et la surface physique, remplace la grande silhouette haute native seulement quand un modèle approuvé est monté, restaure en catastrophe, suit le porteur par weld cosmétique et gère le streaming tardif.
- Plafonds visuels réels : Low=0, Medium=1, High=2, dossier inscrit dans `VisualBudgetRules.LocalFolders` et compteur de modèles `LocalOriginalSkySpineCrownCount` exposé au QA. Le runtime partage `scenery-lod.client.lua` sans nouvelle tâche de rendu.
- Test moteur sur cinq définitions d'arène, hazard collapse, shrink, provenance, collisions et duplication des éléments natifs via StreamingEnabled ajouté à `tests/engine/mapbuilder-advanced.spec.luau`.

**Nouveau jalon :** build source + 5 suites moteur réelles + publication exacte du commit uniquement après leur succès ; rendu et fluidité AAA sur Android à vérifier par capture/mesure, non certifiés par la CI.
