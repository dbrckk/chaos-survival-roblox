# True original 3D route-kit assets — Chaos Survival

**Date:** 2026-11-03. **Work items:** VIS-009 (original platform MeshParts), VIS-010 (original skybridge MeshParts), VIS-032 (authored UV/material pipeline).

## Source artwork delivered

1. `assets/source/chaos_premium_jump_deck.obj`: **1,156 real triangulated faces**, **3,468 indexed source vertices**, bevelled 11.9-stud industrial platform deck with five octagonal layered hull profiles, inset high-grip parallel walkway ribs, eight machined corner fastener faces, side braces, rear structural web and a recessed six-layer material finish. The uppermost decorative surface is approximately Y=-0.01 relative to original model reference; all physically dangerous behavior remains the original Roblox platform.
2. `assets/source/chaos_premium_skybridge_module.obj`: **920 real triangulated faces**, **2,760 source vertices**, modular ~10x5-stud original box-beam bridge with tapered side girders, tread plates, recessed service stops, fixing studs, understructure cross-members and narrow neutral signal ribs.
3. `assets/source/chaos_route_kit.mtl`: seven original materials (ARMOR, BRUSHED, CARBON, GRIP, ALLOY, CERAMIC, SIGNAL), subdued industrial colors and restrained cold signal tones, **no emissive neon floor**.
4. Existing `tools/obj_to_gltf.py` exports embedded glTF 2.0 with baked face normals, deterministic planar UVs (6-stud texel repeat), tangent vectors, authored per-material metallic/roughness values, all required glTF accessors and bounding boxes. This is a bona fide 3D triangulated glTF mesh with UVs, **not Roblox Part/WedgePart geometry**.

**Geometry gate:** full source Luau compile, 2 original OBJ → glTF conversions, validated normal/tangent/UV accessors, and complete Roblox Rojo build: [workflow (passed)](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41614292241).

## Ownership and import

The existing audited `upload-original-3d-models.yml` supports both new source names. One-shot workflow `one-time-import-premium-route-mesh-20261103.yml` uploads each to **the existing creator-owned Roblox user** using its preexisting dedicated Roblox Assets key, once per model. It never publishes the live place. Failed imports leave the current native playable decks intact.

**A successful OBJ export is NOT a Roblox asset ID.** The importer must return a real Roblox Model package ID and moderation outcome. Do not enter an invented ID in the runtime. The uploaded package must be inspected and sanitized before attaching any mesh to moving platforms. The source OBJ files are intentionally **not** registered as approved in `roblox-asset-registry.json` until external evidence exists.

## Actual game integration acceptance after upload

- Validate package IDs and visible meshes through Roblox Assets metadata. Use the existing sanitizer, reject Scripts/LocalScripts/unknown effects before mounting.
- Cosmetic-only; keep existing collision Parts as gameplay authority; new mesh must never create climbable ledges or fake safe platforms after a shrink, disappearing-platform disaster or Skybridge shutter closure.
- Only decorate a **bounded set of camera-visible** suitable 10–16-stud decks and repeating bridge segments, with the existing Android Low/Medium/High LOD owner and no per-frame fetch loop. A safe native fallback remains if loading fails or a newly moderated asset is unavailable.
- Confirm per-platform geometry follows real CFrame and resizes or hides when gameplay support shrinks; avoid any MeshPart blocking raycasting, touches, collisions or AI movement.
- Check five arènes, readable landing top, Low/Medium/High, collapse, shrink, stream swaps and 30-minute session; require actual Android screenshots/FPS before claiming AAA production quality.

Do not claim VIS-009/010 completed merely because the original OBJ files now exist. The full task is **source → import → validation → runtime integration → engine/build → public publish → Android visual review**.
