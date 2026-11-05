# VIS — source-approved 3D Orbital halo lattice

Date: 2026-11-05. Chaos Survival Roblox. Code-only visual milestone; **not a public Roblox publish**.

## Inspected existing art

The 320-stud Orbital world renders 10 Medium and 14 High `CinemaOrbitalHaloN` segments at the exact fixed world positions already certified by `CinematicDepthLayoutRules`. Each segment is just one rectangular 34 × 1.5 × 3.6 Roblox Part at the sky ring, around 238 studs from its center. Repeating those plain metallic/neon bars dominates the panorama and conflicts with the desired detailed original 3D architecture.

The already approved, creator-owned `PremiumSkybridgeModule` Model package (asset **94023662427980**) contains actual UV/tangent-ready MeshParts and dimensions approximately 10 × 1.542 × 4.94 studs. It is already imported and sanitized by the existing server `PremiumRouteMeshAssets` lane, so no new asset request or permission is needed. Unlike an oversized cooling tower or industrial arch, this open structural truss has an appropriate modular shape for ring beams.

## Implemented

- New pure `CinematicOrbitalHaloMeshRules` fixes the existing 14 authored ring positions, distinguishes the actual `CinemaOrbitalHaloN` native Part by precise name, type, cosmetic tag, size, local ring position and nonphysical attributes, and rejects malformed source bounds.
- The existing cinematic builder adds `OriginalCinematicHaloIndex` to each true native ring segment. No gameplay or physics owner changes.
- `ApprovedOrbitalHaloTrussMeshKit` checks source ownership/Approved ID, `PremiumRoute3D`, geometry (MeshPart only), bounding dimensions, existing no-collision/touch/query flags and script absence. For a selected sector it assembles **four separately scaled original 3D truss Models** at offsets along the existing 34-stud tangent. Real geometric detail, no one-piece distorted giant scale. The geometric modules fit fully within the native segment envelope; same world radius, tilt, source light/color environment.
- Original native Part becomes transparent only **after all four authentic 3D modules mount**. A missing source, tier switch, camera LOD, GPU pressure, model deletion, streaming or new arena restores the native before removing the imported pieces. Native state is not destroyed, so a player cannot be left with a broken ring or a false platform. Neither imported art nor native ring elements have collisions, touches or query footprints.
- `scenery-lod.client.lua` remains the ONE update owner and 0.65/0.90-second camera sampler. The new selection uses existing `SpatialMidgroundSelectionRules.choose` to spread limited hero MeshParts around the ring rather than concentrate them. No new RenderStepped/Heartbeat updates, lights, sounds, network events or client asset loading.
- Existing **0/10/14** native ring counts remain unchanged in Low/Medium/High, even when source missing. Maximum **real replacement sectors** at pressure levels 0/1/2: Low **0/0/0**, Medium **2/1/0**, High PC **5/2/0**, High Android **3/1/0**. Each replacement consists of **4 source modules** of at most 12 MeshParts each (normally the approved package uses seven). All genuine MeshParts are registered in `VisualBudgetRules.LocalFolders` and count in the existing **440/680/900** total visual Part ledger.
- Diagnostics: `LocalOriginalOrbitalHalo3DCount` counts genuinely mounted whole ring sectors and `LocalOriginalOrbitalHaloNativeReplaced` counts hidden native originals; no credit for merely eligible or unavailable source geometry.

## Validation boundaries

The existing engine suite `tests/engine/cinematic-depth-layout.spec.luau` now checks source identity, authenticated 14-sector world positions, nonphysical fallback, precise dimensions, four-module fit and quality/pressure ceilings. The exact-SHA milestone additionally verifies real source/template provenance, code contracts, Luau build and seven real Roblox Cloud suites with **no public publish**.

Remaining: real Android Low/Medium/High screenshots, view occlusion, readability, actual source arrival after initial join and FPS/memory frame pacing. This is an authentic modular truss replacement, **not yet a bespoke single-piece curved ring MeshPart**; that would require an additional creator-approved import and visual review. Do not claim complete AAA world quality based solely on source validation.
