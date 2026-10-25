# Chaos Survival — original modular perimeter 3D gate

The files `chaos_perimeter_gate.obj` and `chaos_perimeter_gate.mtl` are **original source artwork generated for Chaos Survival**, not scraped from another Roblox experience and not dependent on an external creator license.

- **Geometry:** 308 OBJ vertices, 560 triangles, 17 named source mesh groups; four grouped palette materials. Approximately 13 studs high, 13 studs wide and 3 studs deep. Decorative mesh only.
- **Intended use:** distinctive reactor/relay landmark, reusable at the enlarged outer edges of Classic, Towers, Crossroads and Orbital. `src/server/MapBuilder.lua` already places native low-cost procedural **perimeter stations** at those coordinates, so there is real in-game decor without any external upload.
- **Current state:** the OBJ/MTL source **is committed but is not a loaded Roblox MeshPart**. Rojo does not publish arbitrary local OBJ files automatically, and the Roblox public experience cannot show this new mesh until imported and given a real Roblox asset ID.

## Exact import and substitution procedure

1. In **Roblox Studio → 3D Importer**, select `chaos_perimeter_gate.obj`; keep its companion `.mtl` beside the OBJ. Verify face normals, material mapping and that the resulting model is oriented upright.
2. Import as MeshPart or grouped MeshParts, **Anchored=true**, **CanCollide=false**, **CanTouch=false**, **CanQuery=false**, **CastShadow=false**; use `DoubleSided` only if warranted by winding/visible faceting. This art must **never replace the collision-tested Base, Platforms, KillPlane or survival hazard hitboxes**.
3. Publish the asset under the experience creator's ownership and note its verified Roblox asset ID and attribution/provenance in the repo. No default or invented `rbxassetid://` is allowed.
4. After the imported mesh actually renders on an authenticated private Studio session, add an asset-backed detail variant into `addPerimeterStations` (or a config-driven reusable cosmetic `MeshPart`) with the proven ID and verified fallbacks to the native decoration.
5. Compare Android **Low/Medium/High** profiles and `ReduceMotion` for texture loading, overdraw, draw calls, frame time, server replication size and background/foreground. Replace the native assembly only after it visibly improves scene quality without blocking hazard telegraphs.

## Free 3D asset sources

- [Kenney 3D asset packs](https://kenney.nl/assets): free modular environment/building and prop packs; inspect the particular pack's license before use.
- [Quaternius](https://quaternius.com/): modular sci-fi/city/building packs. **Check the current Quaternius Asset License (QAL)** at https://quaternius.com/license.html; commercial incorporation is allowed, but **standalone redistribution/repackaging of source assets is restricted**. Do not copy external asset packs directly into this public source repository without satisfying their conditions.
- [Roblox Creator Store](https://create.roblox.com/store/models): free/paid Roblox-native meshes and materials. Inspect scripts in imported models, licensing/creator ownership and effects budgets. Never blindly enable untrusted model scripts.

**Art direction:** intentionally toned-down structural metal, bevelled/angular silhouette, a single inset reactor lens, distinct identity per arena, subdued neon only as route/signature accents. Avoid opaque glow planes, excessive saturated floor fill and center-screen UI clutter. Native stations render today; true high-end 3D meshes remain an import/review task.

## Additional original 3D architecture — 24 October 2026

Two authored low-poly environment models are now present as **editable OBJ source**, accompanied by a shared `chaos_industrial_materials.mtl`. All geometry and palette definitions were created for Chaos Survival, not copied from a third-party pack.

| Original model | OBJ file | Vertex count | Triangle count | Dimensions (studs, approximately) | Intended arena use |
|---|---|---:|---:|---|---|
| **Chaos Reactor Spire** | `chaos_reactor_spire.obj` | 680 | 1,220 | 13.5 wide × 27 high × 13.5 deep | Orbital / Classic skyline, industrial reactor tower |
| **Chaos Service Crane** | `chaos_service_crane.obj` | 316 | 504 | 22 wide × 17.8 high × 10 deep | Towers / Crossroads industrial outskirts |

Technical authoring check: all 74 closed mesh groups across both models have consistently paired triangle edges, positive signed volume/outward face winding, zero unpaired edges, and no external texture dependencies. Six compatible palette materials are defined in `chaos_industrial_materials.mtl`. These are source-geometry checks, **not proof of native Roblox import success, visual polish, or Android frame rate**.

### Studio integration — asset ownership is required

1. Open `chaos_reactor_spire.obj` or `chaos_service_crane.obj` in **Blender** for visual review, or in **Roblox Studio → 3D Importer**, with `chaos_industrial_materials.mtl` in the same folder. Confirm face winding, scale, group origin, UV/material assignment and that the Y axis is upright. OBJ materials are a preview palette; Roblox's imported appearance requires actual review.
2. Import as one or more `MeshPart` instances (or convert to FBX/GLB if the Roblox importer needs it). Use `Anchored=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`. Do not allow any imported model to replace the authoritative `Base`, `KillPlane`, jump decks or server hazard hitboxes.
3. Publish under the **correct experience creator's Roblox inventory**, record the **real** moderated asset ID/ownership and test on an authenticated staging place. Never invent an ID or import third-party executable scripts.
4. Add a curated `MeshPart` cosmetic variant of the existing external skyline/scenery system only after the owned ID has been verified. Keep the Roblox-native fallback geometry for delayed streaming or failed asset loads.
5. Capture actual Android landscape Low/Medium/High frames at all four arenas and measure FPS, overdraw, memory and thermal stability; retain the source models only if the improvement is visible and sustainable.

**Current release status:** the original OBJ and MTL files are now in source control, but they are **not rendered by the published Roblox game**. GitHub commits do not upload asset binaries to Roblox or publish a place automatically.

## New original 3D hero objects — 26 October 2026

Three additional **game-authored triangulated OBJ** sources are tracked in this
repository. They are not borrowed from any marketplace; all 3D coordinates and
geometry were generated specifically for Chaos Survival.

| Model | Triangles | Vertices | Approximate 3D bounds | Scene purpose |
|---|---:|---:|---|---|
| Plasma Foundry | 992 | 560 | 30 × 27.6 × 14 studs | Classic reactor-industry skyline |
| Sky Transit Exchange | 620 | 376 | 32 × 27.8 × 15 studs | Towers elevated cranes/transit scene |
| Orbital Halo Array | 1,616 | 920 | 22.8 × 30.2 × 12 studs | Orbital large ring silhouette |

Editable geometry: `chaos_plasma_foundry.obj`,
`chaos_sky_transit_exchange.obj`, and `chaos_orbital_halo_array.obj`.
Each uses the **existing** `chaos_industrial_materials.mtl`. All triangles are
checked by the existing OBJ → self-contained glTF conversion in
`Build Validation`; no Roblox asset IDs are invented or added to the approved
asset registry. Asset import, ownership and moderation must be confirmed from a
real Roblox Open Cloud response before optional MeshPart runtime integration.

### Immediately renderable 3D composition

`src/server/HeroArchitecture.lua` also implements four uniquely authored,
**always-available Roblox-native** exterior hero models:
Classic observatory; Towers suspended transit gantry; Crossroads switchyard
interchange; Orbital nested halo reactor. `MapBuilder` creates one per arena
without network calls, textures, remotes, or an asset upload. Each contains
14–32 static Parts, no lights/emissions, and all parts are anchored and fully
non-colliding/non-queryable/non-touchable and lack shadows. The generated 3D art
cannot block players, AI, gameplay warnings, safe pads or hazard hitboxes.

**Important:** Roblox source changes do not affect the public place until a
separate guarded publishing action. Validate first in the Roblox engine and,
before claiming visual/AAA quality, in an authenticated device session on
Android. Three new OBJ sources are not yet considered moderator-approved
Roblox packages.
