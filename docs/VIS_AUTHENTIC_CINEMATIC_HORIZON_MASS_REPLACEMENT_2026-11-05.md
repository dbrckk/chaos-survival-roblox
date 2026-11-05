# VIS — Major authentic 3D conversion of five cinematic horizons

Date: 2026-11-05. Repository `dbrckk/chaos-survival-roblox`, source-only milestone. This is NOT a Roblox public release or an Android screenshot/fps certification.

## Previously audited source

The five 320×320 arenas build a full cinematic skyline in `arena-cinematic-depth.client.lua`. Each one contains 5 Low / 8 Medium / 11 High groups. Each group was a plain native `CinemaHorizonStructureN` Part (or simple Orbital cylinder), plus a box `CinemaHorizonCrownN`, and an optional `CinemaHorizonSlitN` on High. Those primitive shapes are large enough to dominate the first-person/third-person skyline. Earlier fixes stabilized their positions across quality tiers but did not give these visual masses genuine geometry. Across the five mutually exclusive arenas, **up to 55 distinct High-tier skyline positions** can have a source-approved real MeshPart replacement; this is a capacity, not a claim that all 55 source models are actually rendered or simultaneously loaded.

## Source-approved replacement in this lot

- Introduced `ApprovedCinematicHorizonMeshKit` and pure `CinematicHorizonMeshRules`. The cinematic source owner now tags the genuine native structure + crown + optional slit with one exact `OriginalCinematicHorizonIndex` and `OriginalCinematicHorizonVariant`. It uses the SAME shared original size/offset formula to preserve existing 3D placement and gameplay.
- The client reuses ONLY server-provided, owner-verified original Roblox Models from the existing `ApprovedDistrictFacadeTemplates` (Observatory, Freight, Turbine, Aerial), Towers original cooling spire / hollow stack sources, and Orbital original Satellite / Containment sources. All IDs are checked against their existing approved asset IDs, exact owner attributes and script-free, noncolliding MeshPart geometry. No new AssetService calls or unapproved assets.
- The source is scaled to fit **within** the existing nonphysical native horizon's X/Z footprint and height, retains original 11-sector world placement and theme rotation, and is rejected if it becomes too small or invalid. Candidates prefer the five world's distinct original families with a bounded fallback to the four approved industrial facade models when a special source is unavailable.
- Only once **all** MeshParts of a candidate are cloned and validated does the client hide its native structure, crown, and optional slit. On quality pressure, source disappearance, late replication, map swap, size/CFrame drift, broken model or source unavailability, it restores the native originals BEFORE the approved model is unmounted. No collision, touch, CanQuery, fake route, hazard masking, server-owned geometry or bot change.
- The existing 0.65s Low / 0.90s Medium/High scenery LOD sampler performs all model selection, spatial separation, mounting/unmounting and counters. No new polling or per-frame update loop.
- The existing 440 / 680 / 900 local Part budget census now counts `OriginalCinematicHorizonMeshesLocal`. Quality-pressure hard caps are Low **2 / 1 / 0**, Medium **5 / 2 / 0**, High Android **7 / 3 / 0**, and High desktop **11 / 6 / 0** for stress levels 0/1/2. Only one arena is active. Those are **Model residency** caps, not asserted frame-rate measurements. Original 5/8/11 native skyline group counts are unchanged.
- Native `ArenaCinematicDepthLocal` LOD range increases from Low 165 / Medium 245 to Low 240 / Medium 315 to avoid dropping the only remaining skyline fallback near the map rim; this changes range but **not** native part/model counts. Android measured FPS and possible tier retuning are still release gates.

## Actual inspectable diagnostics and validation

`LocalOriginalCinematicHorizon3DCount` counts valid mounted approved originals; `LocalNativeCinematicHorizonPartsReplaced` counts actual native Parts replaced. An empty source cache leaves the original Parts and counts zero, never falsely claims replacement.

The existing Roblox Cloud `cinematic-depth-layout.spec.luau` now verifies all five variants' exact 55 physical source positions, dimensions and compatible source keys, unchanged source-tier 5/8/11 indexes, and Low/Medium/High/pressure residency caps. Build Validation compiles Rojo/Luau, the seven real Roblox engine suites run on exact SHA, and the milestone source contract checks there are no new external client asset fetches, controllers or physics effects.

Still required before publication: actual Roblox Studio/Android captures of all five maps at Low/Medium/High, late source streaming, pressure level 1/2, material quality/lighting, occlusion of true routes, device FPS/memory, public join and honest release-SHA evidence. In particular, successful source and engine tests do **not** prove the real imported Models were observed on a user's Android device.
