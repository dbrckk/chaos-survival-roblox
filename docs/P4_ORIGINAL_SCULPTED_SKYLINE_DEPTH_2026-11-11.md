# P4 — Authored 3D distant skyline roof: source, scoped import, and runtime gate

11 novembre 2026. Source audit: `MapBuilder.addDistantSkyline` creates
`SkylineDepth{North,East,South,West}{1,2}`: eight
`DistantRoofMass` `WedgePart` per variant, **40 generator-side
occurrences across five variants** (one variant active at a time).
Each roof also has a native `DistantAerial` marker.

## Art created in this change

`tools/generate_original_skyline_depth.py` authors a distinctive octagonal
industrial tower, with a tapered multi-ring forged body, open load bracing,
captured facade bolts, slot fins, real-depth ventilation cassettes and
ceramic observation ports. Seven physical materials are separated into
seven glTF mesh primitives; this is actual 3D triangulated OBJ source,
**not** a 2D texture, fake MeshId or an imported part from another creator.

- A single geometry is designed to be adapted across eight deep-horizon
  positions of varying height and width, once an approved Roblox asset ID
  is returned and the exact rendered fit has been checked.
- It uses the existing authored `chaos_route_kit.mtl`; metallic/roughness
  factors are not proof of unique normal/roughness *texture images*.
- The existing game still renders all eight legacy WedgeParts: this commit
  does **not** mask them or introduce unverified IDs.

## Release chain, without cheating provenance

1. `skyline-depth-original-source-regression.yml` builds OBJ + self-contained
   glTF and verifies topology, position attributes, UV/tangents, all seven
   materials, SHA-256, geometry envelope and bounded triangle count.
2. The one-time `one-time-original-skyline-depth-20261111.yml` only
   attempts the **owned Roblox Model upload** on protected main after a
   second source gate. The uploader checks the caller, owner ID, secret,
   explicit acknowledgment and Roblox response; it never publishes a Place.
3. **Only after a real Roblox Approved asset ID is observed:** register the
   model and connect a strict client-side `ApprovedSkylineDepth` substitution
   with streamed native fallback, per-variant owner check, camera distance,
   Low/Medium/High limits and Android budget.
4. Finally run Open Cloud engine checks and a real Android near/far skyline
   screenshot comparison before promising visible improvement.

## Audit scope

The targeted denominator is 8 roof WedgeParts **per arena**, not the entire
game's large number of Parts. Replacements at present: **0/8** from this
new asset, because ownership/moderation and client integration are not yet
verified. Retain `DistantAerial` as navigation identity until explicitly
reviewed; gameplay parts and collision stay unchanged.

No GitHub change alone updates the public Roblox Place.

## Ownership approved and actual runtime integration

The guarded GitHub import [run #42994003806](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42994003806)
returned authentic Roblox Model asset **80692067525256**, moderation
**Approved**, with owner ID 9774173158. The source verified in Actions
contains **2,156 triangles**, **81 sculpted groups**, **7 material glTF
primitives** and bounding box **11.4 × 33.95 × 7.19**. These are validated
source dimensions, not an Android screenshot or certification of normal-map
textures.

The second change registers this proven ID in
`assets/source/roblox-asset-registry.json`, loads it through
`PremiumApprovedAssetImportGate` (two concurrent AssetService calls maximum),
sanitizes the Model on the server, verifies exactly seven noncolliding
MeshParts and checks the model's dimensions before replication. The client
`ApprovedSkylineDepthMeshKit` **now prefers this actual, specially carved
roof sculpt instead of borrowing the generic exterior tower templates**.
It reuses the existing `scenery-lod.client.lua` timer and exact
`SkylineDepth...` provenance checks.

All **8 per-arena native roofs** are eligible in the generator/source, but
the live client only mounts up to **2 on Medium, 4 on High PC, 3 on High
Android, and 1 on Low (Android/PC, à 315 studs et pression normale)**, with lower caps under adaptive VFX pressure and
camera-distance culling. The `DistantAerial` markers remain native, and
gameplay Base/platform collision is never touched. On failure, missing
streamed sources, or LOD reduction, the native WedgeParts remain visible.
No runtime frame benchmark or rendered comparison is claimed.

### Suite du 11 novembre — visibilité Low et première manche

Le client n'exclut plus automatiquement toutes les sculptures de toit
sur Low : il autorise **un modèle à sept MeshParts**, limité à la source
approuvée, au propriétaire réel et à 315 studs de la caméra. Avec le kit
`ApprovedPrimarySkylineMeshKit`, le Low peut monter **deux modèles 3D au
maximum** pour les deux familles de skyline (14 MeshParts), soit jusqu'à
**cinq formes natives masquées simultanément** (quatre corps du primaire et
une toiture). La pression graphique de niveau 1 ou 2 ramène les deux caps
à zéro ; l'absence d'asset, le streaming et les changements de carte
restaurent les éléments natifs sans toucher à la navigation ni aux collisions.

L'import serveur de cette unique sculpture de toiture commence désormais
à **24 secondes** au lieu de 34 après le démarrage du chargeur, après les
signatures prioritaires (18–21 s). Le garde-fou FIFO global conserve
ses deux requêtes Roblox simultanées maximum. Ce délai avancé est une
**opportunité** de visibilité dès la première manche, pas une garantie :
le chargement réseau et la modération peuvent encore retarder ou empêcher
l'affichage. Aucune mesure FPS Android, capture d'écran ni publication
de l'expérience n'est revendiquée dans cette modification.

Verification: the amended `verify_skyline_depth_approved_fallback.py`
checks all five variants × eight heights/positions, genuine registry
provenance, 3D bounds, fallback behavior and strict client import
separation. Actual Model residency still requires Roblox engine QA and
Android snapshots **before public publication**.
