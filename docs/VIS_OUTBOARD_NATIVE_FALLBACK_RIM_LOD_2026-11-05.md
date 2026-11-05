# VIS — Outboard skyline keeps genuine near-rim structure when fallback is needed

Date: 2026-11-05. Chaos Survival, five 320-stud worlds. Code-only milestone; no public place update.

## Audited source defect

`scenery-lod.client.lua` applied a SINGLE `ArenaMidgroundMassLocal` folder-wide native visibility decision from `GeneratedMap.Arena.Base.Position` with cutoffs Low **145** / Medium **215**. The authored native outboard Classic/Crossroads facades, Towers cooling towers, Orbital stations and Harbor cargo boats have their REAL anchor positions well outside the 320-stud arena. At a far 320-stud rim, an Android player can be near a building yet over 145/215 studs from the arena center. The blanket policy then sets `LocalTransparencyModifier=1` on all fallbacks at once, even when the corresponding approved 3D source cannot load, or is culled by source budget/quality pressure. The horizon loses visible structures just as the player approaches them.

## Production correction

- Use `MidgroundOutboardLodRules` with the existing exactly tagged `OriginalMidgroundSkylineIndex`, `OriginalTowerCoolingSpireIndex`, `OriginalOrbitalStationIndex`, `OriginalHarborMidgroundBargeIndex` and the exact native `*MassN`/barge hull anchor names. Only actual locally authored, anchored, noncolliding `CosmeticOnly` Parts may serve as identity. Never touch server-owned physical platforms, explosions, hazard outlines, boost pads, or original MeshPart sources.
- Distance for each genuine native group is `min(camera-to-arena-center, camera-to-actual-native-anchor)`. This preserves the previous full distant silhouette from near the arena center, and also restores a nearby original building at the rim. Other outboard groups still get culled when both centers are distant. Hysteresis stays per group.
- Retain **exactly** the existing Low=145/Medium=215 and High=unlimited thresholds. No new meshes, textures, extra lights, shadow budget, geometry, network, scheduler or fresh renderer. Current `scenery-lod` pass and `SceneryLodCache` cache own all updates, including first-join streaming and per-tier invalidation.
- Native masking remains `LocalTransparencyModifier` only, independent of actual approved 3D MeshPart kits' `Transparency=1` replacement masks. The already-certified 1/2/3/4/5/6 quality/pressure quotas and source-native restoration remain authoritative.
- The renderer never uses a completely arbitrary part as an outboard anchor. Missing/unsafe group anchors are not treated as a valid sector; fallback handling is bounded to the locally owned cosmetic folder.

## Certification and release boundaries

Build Validation and seven genuine Roblox Cloud engine suites on identical SHA, existing engine visual-budget suite asserting all five authentic ownership labels, center conservation, near-rim visibility, distance thresholds, no gameplay collider ownership and malformed token rejection. Then actual Android Low/Medium/High screenshots walking from center to rim to confirm no native silhouette flashes or empty backgrounds under asset/quality pressure. No public publish, device FPS claims or visual sign-off by source code alone.
