# Chaos Survival — near-route architectural depth, five arenas

**31 October 2026, after PR #437. Source-only improvement; not a Roblox publication or Android certification.**

## Existing architecture reviewed
The four client-only district sectors (`DistrictSectorSetpiecesLocal`) already had noncolliding bases, four distinct macro silhouettes, localized signage, quality-tier reconstruction, limited animations and visual-budget telemetry. Their shapes primarily distinguished **sector roles** (observatory, freight, power, communications); identical sector assemblies were reused across the five different arenas.

The repo's `VisualBudgetRules.LocalFolders` already includes the district setpiece folder, and `scenery-lod.client.lua` already culls it. The `PbrDistrictRules` client-selection system supports tagged, native surfaces and has per-owner and global 2K material limits. No new culling/rendering subsystem is justified.

## Implemented — new environment language at player height
The existing `src/client/district-sector-setpieces.client.lua` uses **native, original anchored Roblox Parts** and the existing four near-route models. A variant-aware, stationary architectural layer adds **two Parts per sector on Medium**, and **three per sector on High**; on Android Low, the existing **exact five-Part silhouettes per sector** are retained unchanged.

| Arena | Medium: two major physical volumes per sector | High: one additional distinct form |
| --- | --- | --- |
| Classic | Weathered survey support and tall mast | 3D receiver head |
| Towers | Paired industrial lift guide columns | Overhead mechanical crosshead |
| Crossroads | Rusted switch-concourse mass and genuine concrete pier | Asymmetric transfer beam |
| Orbital | Opposed ceramic containment wings | Reinforcing crossbrace |
| Harbor | Two corroded dock crane supports | Freight hoist crosshead |

The five visual themes reuse each arena's `VisualTheme` palette and material decisions, including genuine Orbital ceramic and Crossroads concrete. The latter is explicitly marked `PreserveNativeMaterial`, preventing the already-existing 2K PBR selector from turning it into a metal surface.

## Ownership / costs
- New parts total: **0 Low / 8 Medium / 12 High per currently loaded arena**, all **client-only**, inside the already-existing `DistrictSectorSetpiecesLocal` budget owner. These counts are per all four district models, not each.
- No server-owned parts, assets, asset IDs, textures, remotes, collisions, touch/query, scripts, emitters, shadow casters, sound effects, or additional updates/loops.
- `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Anchored=true` and `CastShadow=false` are inherited from the existing local `make` factory.
- Existing `rebuild` clears all prior models on quality/map changes; the existing `scenery-lod.client.lua` retains the right to hide the folder at distance. No permanent parts survive destruction.
- Each district model reports `VariantArchitectureParts` (0 / 2 / 3) as runtime inspection metadata, and a guarded assertion prevents accidental changes to the Medium/High per-model allocation. Existing `Decorative3DParts` and maximum 16/35 per-model tier guards remain unchanged.
- These are illustrative machines, not enterable buildings, usable lifts, ladders, walkable bridges or real objectives; server-authoritative platforms, hazard warnings and navigation remain unchanged.

## Important remaining certification
This is **source integrated for review, not engine-tested**. No unit tests are added and no automatic or manual CI tests are run during the owner's improvement-only stage.

At the next actual milestone (prior to an owner-approved public Roblox release), run existing manual `Build Validation` and the five Roblox Open Cloud engine suites for the *exact final merge SHA*, and then capture Android Low/Medium/High from the arena centre and each sector access route. Verify actual foreground/hazard readability, visual joins, rebuild after a quality change, no missing textures, no FPS/thermal regression and that cosmetic structures cannot physically support a player. If blocked, repair and rerun before publishing to Universe `10771083668` / Place `95351659174730`.

## Next improvement after in-game review
Tackle visual clutter and player route comprehension ahead of further geometry. Consider adding more near-field detail only when real device evidence shows it is useful and within the mobile frame-time budget.
