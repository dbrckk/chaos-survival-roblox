# Chaos Survival — Harbor focal floodlighting and shrink/tilt-safe light hardware

**31 October 2026. Source-only 3D/environment improvement after PR #448.** The public Roblox game is NOT updated by merging this branch. No engine execution or physical Android measurements are claimed.

## Confirmed source-level problems

1. `ArenaFocalLightingRules.Definitions` defined **only Classic, Towers, Crossroads and Orbital**. On Harbor the fallback silently reused Classic's spotlight offsets, colors and roles, even after #448 replaced Harbor's Classic hero-scenery fallback with its original maritime storm-signal gantry.
2. `ArenaFocalFixtureKit.SCHEMES` also defined only those four maps, so Harbor got the original two/three SpotLights **without any physical light housing**. The four other maps had one Medium or two High housing parts per spotlight.
3. Focal spotlight anchors and their separate cosmetic fixtures were positioned once on initial map load. During ShrinkingArena or a tilted/moved floor, the already-created lights **remained at their old world location**, unlike #447's corrected atmospheric beacons.

## Completed source changes

### Maritime lighting without extra GPU lights

- A Harbor-specific palette of three architectural floodlight candidates, aimed at its storm-signal gantry, cargo-yard approaches and seaport perimeter. Their brightness remains subordinate to real hazard telegraphs through the existing `ArenaCrisisSurfaceRules.light` and `ArenaFocalLightingRules.phaseScale` (round 0.30 / Final Rush 0.08).
- Native industrial `DockFloodlightCowl` (medium), plus `DockStormBaffle` (high), built by the original noncolliding fixture owner. Corroded metal with restrained structure/detail hues; no neon, fake danger-light colors, decals, imported models or extra shadows on Low.
- **Unchanged original budgets:** Low 0 lights/0 fixture parts, Medium 2 lights/2 fixture parts, High 3 lights/6 fixture parts. All five map identities now have physically motivated housings.

### True floor-relative positions during catastrophes

- Added one pure, validated `ArenaFocalLightingRules.anchorFrame(base.CFrame, base.Size, definition)` policy using floor-local coordinates and the actual tilted floor normal.
- The original `arena-focal-lighting.client.lua` now captures each housing piece's local transform relative to its spotlight anchor and updates both together on the actual floor's **Size** or **CFrame** changes.
- An event-coalesced, generation-safe `task.defer` handles bursts of shrinking size replication. There is **no new polling loop**, per-frame raycast or light reallocation. Two per-Base property subscriptions are disconnected on map/quality rebuild and on teardown.
- A final immediate re-synchronization after initial construction handles a change that happened while 2–3 lights were being created. Spotlight light color, range, cone and hazard reaction/tween owners remain unchanged.

### Existing engine acceptance updated, not executed

The already-existing `tests/engine/arena-focal-lighting-rules.spec.luau` includes Harbor in its original five-map coverage, validates its original source and fixture tier limits and asserts that the floor-relative transform relocates correctly on a tilted/shrinking rectangular deck. **No new test file has been added.** The owner defers actual test execution until a significant release milestone.

## Real functionality/performance limits

- The change affects **only local decoration** and does not modify server-owned structures, true collisions, meteor/ice/lava physics, damage or rewards.
- New potential runtime work occurs only on an actual Base.Size/CFrame event; there are at most three spotlight anchor poses and six existing decorative pieces to update. This does not claim measured FPS gains without device profiling.
- StreamingEnabled and quality rebuild still reuse `MapVisualReadiness.watch`, with explicit listener disposal and no duplicate lights on map replacement.
- No additional textures or PBR image sets. Harbor keeps its approved material palette and existing distance LOD for `ArenaFocalLightingLocal`.

## Full milestone gate before PUBLIC Roblox publication

1. Execute the project's manual Build Validation and five existing Roblox Open Cloud engine suites on the **exact candidate SHA**; inspect any failure before publishing.
2. On Harbor in a real client, verify both Medium floodlamp cowls and all six High housing pieces, and no light/fixture objects on Low.
3. In all five map variants trigger ShrinkingArena and map tilt; verify spotlights and separate housings move **as one**, without floating old fixtures or unintended beams across player hazards.
4. Trigger Tornado, Freeze, Darkness, Meteors and Final Rush; verify `ArenaCrisisSurfaceRules.light` retains its soft, readable capped color response and hazards remain far more visible than the fixtures.
5. Switch graphics Low/Medium/High mid-round, stream Base/VariantId late, reset map and enable ReduceMotion. Ensure no orphaned event subscriptions or duplicated lights.
6. Profile actual mobile render/frame time, thermals and GPU memory under simultaneous disaster load. Visual and performance acceptance requires in-engine evidence.

**Current Roblox identifiers:** Universe `10771083668`, Place `95351659174730`. Source-only PR, not a live update.
