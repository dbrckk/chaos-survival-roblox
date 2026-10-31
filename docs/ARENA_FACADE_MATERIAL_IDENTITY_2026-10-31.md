# Chaos Survival — Five-arena architecture material coherence

**31 October 2026 — source-only art direction pass.** This is an improvement on top of merged PR #435. It is not itself a Roblox publish, a screenshot comparison, an engine certification or a device-performance benchmark.

## Identified mismatch

The 16 original district buildings now carry physical service doors and overhead industrial detail. They previously used essentially the same facade materials for all five arenas. Additionally, the shared PBR selector categorised all `ServiceEntry*` parts via the generic `service` substring, potentially converting an authored ceramic airlock into oxidized steel and a diamond-plated service door into rust.

One material stencil was placed on a lateral panel; these serials could be difficult to recognize while approaching from the arena's central routes.

## Implementation

The same eight decorative service-facade pieces are retained per building with distinctive, physically motivated surface language. No additional Part, mesh, texture ID, paid asset, collision surface, loop, light or remote has been created.

| Arena | Entrance visual identity | Main entrance finish |
| --- | --- | --- |
| Classic | Radar infrastructure / armoured technical access | Diamond-plated door; corroded recess and steel shelter |
| Towers | Machined elevator and freight machinery | Foil-machined door, diamond-plate rail and shelter |
| Crossroads | Weathered transit control and switching | Diamond-plate door, corroded service casings, genuine concrete shelter |
| Orbital | Sealed containment station | Ceramic-tiled recessed airlock / door / canopy |
| Harbor | Wet-dock service entrance | Corroded freight steel, wooden plank shelter (not faux metallic wood) |

Canopy depth changes minimally within the existing service-building footprint. Geometry is anchored, entirely inert and explicitly noncolliding, untouchable and unqueryable. Existing signed sector colors, near-field pathways, hazard authority and player/bot movements are untouched.

### PBR correctness and budget

- `PbrDistrictRules.materialKey` now maps the four main `ServiceEntry*` surfaces to the material-matched existing approved families instead of applying "service=rust" unconditionally.
- Parts explicitly tagged `PreserveNativeMaterial` (concrete/wood shelter) are ineligible for metallic/ceramic PBR substitution. Existing Wood/WoodPlanks global exclusion remains in place.
- The front door receives a modest selection-priority bonus, still within **existing unchanged** per-owner and global 2K texture budgets; Low remains free of optional PBR.
- No new MaterialVariant definitions or texture uploads; all material names are existing project-owned variants and Roblox native materials.

### Real player-height labeling

Existing `DistrictMaterialFinishKit` now has one additional **compact** `service-door` design. It places a small neutral equipment-stamp plate at the upper end of the actual front door; it does not cover or fake a full PBR-finished wall and does not add neon hazard warnings. The existing `district-architecture-materials.client.lua` uses this stamp instead of a side-facing canvas. Medium continues to display stamps on eight models; High on sixteen; Low on zero. It remains camera-distance and world-visibility gated and retains proper streaming cleanup.

All improvements are in the actual game source, not a concept/render.

## Validation contract before publication

Per the current owner rules, no tests are added or triggered for an intermediate improvement commit. **No engine verification, build, Roblox mobile gameplay capture or release has been performed for this candidate.** Before public update, validate this exact merged SHA with the repository's manual Build Validation and real Open Cloud Engine suites, then review actual Android/PC views:

1. Verify the material language for **all five** arenas and that native Harbor timber and Crossroads concrete remain correctly non-metallic on High.
2. Inspect the front-facing physical door/serial in a genuine player camera, at Low/Medium/High, after streaming and after a runtime quality-tier switch.
3. Check PBR active surface/budget counters, no shader flashing during camera turns, and no abnormal Android memory, FPS or thermal regression.
4. Confirm that only the original platforms remain collidable and visible hazard colors retain contrast; the service door remains purely decorative.
5. Publish only via the existing protected, exact-SHA workflow to Universe `10771083668` and Place `95351659174730` after the owner's milestone approval.

**Remaining larger goal:** physical rendering quality must be judged from screenshots/video; source reviews alone cannot prove premium/AAA quality.
