# Chaos Survival — replacement of primitive under-arena beams with approved original 3D

**Scope:** Classic and Crossroads. This is one complete, release-gated visual feature, not a new unapproved asset or any change to the game's collision architecture.

## Before / after

- Classic: two original ~198-stud featureless, intersecting underfloor slabs are replaced by **twelve separated 23.3-stud engineered beam bays**, arranged around the approved central arena keel.
- Crossroads: four original ~134-stud featureless radial underfloor trunks are replaced by **sixteen separated 23.3-stud beam bays** with a clear central machinery space.
- Near-camera beam bays show the **existing, approved, creator-owned, source-triangulated 3D Model 84582262145054** (original underdeck chassis, 3,072 triangles and seven material families). No fresh creator upload, marketplace asset or unverified ID is involved.
- Native beam bays remain non-collidable fallbacks. A bay is made invisible **only after** its matching imported MeshParts have been authenticated, cloned and positioned; a disappearing mesh restores the exact original transparency of that bay.
- Imported models are positioned entirely beneath the authoritative server floor. All parts are anchored, non-collidable, untouchable, nonqueryable and shadowless. None can become a phantom platform or influence AI, hazards, hitboxes, spawn, shrink or route movement.
- There is no added frame loop. The existing scenery LOD camera sampler controls model residency. A base Size/CFrame/collision/ancestry change instantly restores native cosmetics and removes all optional meshes. The original understructure's normal shrink-following behaviour remains active.

## Android budget / telemetry

| Tier | Max simultaneous 3D understructure bays | Maximum distance, studs |
| --- | ---: | ---: |
| Low | 1 | 140 |
| Medium | 2 | 210 |
| High | 4 | 290 |

Each Model contains up to 12 authenticated MeshParts (normally seven), included in the existing `VisualBudgetRules` Parts ledger under `OriginalUnderstructureBeamsLocal`. The player attribute `LocalOriginalUnderstructureBeamCount` records actual local Model residency, not an invented FPS or an assertion that materials finished drawing.

## Safety / release gate

1. `src/server/PremiumRouteMeshAssets.lua` is the only importer; it validates the same Model ID from the existing approved source registry. A client may never fetch arbitrary Roblox asset IDs.
2. `src/client/arena-understructure.client.lua` owns the deterministic 12/16 native bays and resets the 3D substitution layer before any rebuild.
3. `src/client/UnderstructureBeamMeshKit.lua` owns source identity, per-camera selection, 1/2/4 cap, authored orientation, per-bay transparency restoration and shrink cleanup.
4. `src/client/scenery-lod.client.lua` is the only existing camera sampler; the census is updated in `src/shared/VisualBudgetRules.lua`.
5. The Roblox engine milestone spec validates owner identity, source dimensions, actual MeshPart instance safety, Classic and Crossroads replacement, Low/Medium/High caps, fallback restoration and immediate shrink removal.
6. The exact-SHA build and seven Cloud engine suites must both succeed before the existing guarded public publisher may publish.

**Remaining:** large native supports in Towers, exterior arched landmarks and the remote Orbital understructure are separate future genuine 3D replacement tasks. Screenshots and real-device FPS are not claimed by this source/runtime integration.
