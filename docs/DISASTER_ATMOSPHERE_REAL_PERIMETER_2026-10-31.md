# Chaos Survival — disaster atmosphere: real arena perimeter and stream-safe recovery

**31 October 2026 — source-only integration after PR #446.** No new Roblox publication, engine execution or Android performance measurement is asserted for this work.

## Reproduced source-level shortcomings

The client atmospheric owner `arena-cinematic-disaster-atmosphere.client.lua` already creates 4/6/8 native disaster beacons on Low/Medium/High, adds 0/3/4 optional faint vertical shafts and distributes bounded ParticleEmitters. However its positioning used a **single circular radius calculated from the longer floor axis**. On a rectangular deck, some compass directions sat well inside the playable terrain and others outside its edges. Those positions also varied in an inconsistent way during `ShrinkingArena`; beams swept around the global circle instead of the actual floor.

The same owner watched only `GeneratedMap.ChildAdded("Arena")` and used an arbitrary 80-ms delay. Roblox StreamingEnabled may deliver an Arena without its child `Base`, or replicate `VariantId` later. If `rebuild()` ran before Base arrived, the disaster atmosphere stayed empty until an unrelated state or quality change.

## Actual changes

### Geometry follows server-authored floor footprints

`src/shared/DisasterAtmosphereLayout.lua` gains one bounded `edgeRadius(baseSize, angle, multiple)` helper. It intersects an arena-local ray with the current rectangular X/Z footprint, then gives it the original small exterior margin (factor `0.52` of each axis, 4% beyond a half-extent). Unlike using only the maximum axis, this works at 45-degree corners, on rectangles and while shrink/tilt changes the authoritative `Base.Size` / `Base.CFrame`. It uses the already existing `Layout.point` and the unchanged canonical local deck orientation.

The previous `perimeterRadius` API is left intact for compatibility. Existing `beaconFrame` now uses edgeRadius. The real atmospheric owner also uses edgeRadius for the **existing** beams at construction and while their existing sweep updates (factor `0.52 × 1.08`). No additional runtime loop, objects or geometry updates are introduced; existing loops now apply mathematically correct transforms.

### Delayed Arena/Base and VariantId recovery

The same client owner reuses the repository's existing `MapVisualReadiness.watch(generated, "Arena", "Base", onChange)` implementation. This watches late Arena, Base and VariantId replication without timeouts. A single queued `task.defer` coalesces closely-spaced map changes; map generation serials and explicit disposer calls prevent stale callbacks from a previous round's map. An invalid RoundState snapshot now safely falls back to an inactive state rather than terminating the listener.

## Performance, ownership, user experience

- Same **4/6/8** live disaster beacons on Low/Medium/High; same 0/3/4 beams; same original ParticleEmitters, rate limits, reduced-motion and final rush handling.
- All atmospheric parts remain local, anchored, noncolliding, untouchable, unqueryable and shadow-free.
- No changes to server disasters, arena dimensions, player collisions, damage, bot AI, hazards, reward systems, cloud permissions, approved PBR images or mobile quality budgets.
- No added per-frame raycasts, new remote traffic or textures. This is primarily a **correctness and placement** change, not an unmeasured FPS improvement.
- The existing `tests/engine/disaster-atmosphere-layout.spec.luau` assertions were **updated** (not supplemented by a new test file) to describe the correct rectangular footprints, while preserving tilted-deck and shrink verification. The tests were **not executed** in this improvement-only pass.

## Verification at the next release milestone

1. Run Build Validation and all five existing Roblox Open Cloud engine suites on the **exact intended public release SHA**.
2. Inspect rotated and rectangular arena layouts on Android Low/Medium/High. Verify 4/6/8 local beacons remain immediately beyond the real collision edge, including corner angles; optional shafts stay slightly farther outside.
3. Start an ongoing disaster while Arena/Base streams in late. Confirm its visual perimeter appears as soon as Base is available and the VariantId palette corrects after replication, without duplicate effect folders.
4. Trigger an actual shrinking arena during Double Chaos. Verify decoration contracts together with the real server-owned Base, without floating particles/shafts or disguised safe platforms.
5. Switch maps and quality tiers; confirm all listeners are disposed/rebound, the atmosphere is empty in lobby/result, and reduced motion remains conservative.
6. Record actual device frame time, temperature, scene counts and captures before making performance or premium-finish claims. Do not publish unless the final exact-SHA release gate passes.

**Roblox identifiers unchanged:** Universe `10771083668` / Place `95351659174730`. The public version is still the previously verified SHA in `README.md` until a separate audited release.
