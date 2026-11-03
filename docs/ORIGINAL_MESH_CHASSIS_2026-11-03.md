# Original approved 3D asset foundation finish — November 2026

## Why this is not another native-block-only facelift

The live game already uses six **creator-owned, Roblox-moderated original model packages** loaded through `AssetService.LoadAssetAsync` and placed as eight independent exterior skyline meshes per active arena. Their IDs and authored source .obj files are in `assets/source/roblox-asset-registry.json`. Those packages are real imported 3D meshes, not Roblox stock toolbox models.

The four old foundation cubes below every imported model remained visibly primitive. This change retains all approved MeshParts and gives each of the six distinct asset families its own dimensional chassis: paired industrial steel I-beam rails, tapered angled side buttresses, exposed service rails, plus a radial heat exchanger or industrial manifold according to model function. **Seven additional native decorative pieces per imported original mesh**, up to 56 per arena when all eight imported assets load. No gameplay-authoritative parts are replaced.

All extra pieces are:
- beneath the real mesh bottom (no phantom jump ledges);
- anchored, non-colliding, non-touching, non-queryable and non-shadow-casting;
- children of the existing atomic-streaming `Original3DScenery` model and thus managed by its existing Android distance/quality LOD;
- colored with the existing authored steel palettes, with no new asset IDs, new scripts, runtime per-frame loops or high-cost local light sources.

This is one significant **original 3D asset integration** milestone, not evidence that all game textures, UI art or lights are now AAA. Existing PBR 2K assets and existing five-map atmosphere/lighting controller remain in use, and the physical Android visual review is still necessary.

## Gates

Require full Luau compile, complete Rojo place build and five actual Roblox Cloud engine suites on the exact main commit. Do not claim an Android screenshot or FPS without actual capture. Public publication is separate and guarded.
