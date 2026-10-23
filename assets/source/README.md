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
