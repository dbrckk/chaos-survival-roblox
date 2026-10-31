# Chaos Survival — 31 October 2026: large-scale authored skyline and district silhouette pass

**Status:** Source candidate only. Does not publish a new Roblox place or certify Android gameplay.

## Inspection

Repository head before this change: `708f9fb721562279932f40b07b760e7661819697` (merged PR #436). The five arena variants already had substantial 3D content, a per-device visual tier, one existing `ArenaMidgroundMassLocal` client owner, and an existing `ArenaDetailKit` capped at 1/2/3 motifs on Low/Medium/High.

**Observed weakness:** the distant mass builders (especially Classic, Towers and Crossroads) had largely box-shaped structures with relatively small ornament strips, while Harbor never called the shared motif builder. The 16 in-arena sector buildings also had recognizable but modest roof signatures.

## Integrated visual scope

### Five coherent midground identities
`ArenaDetailKit.build(..., "Midground", ...)` has been redesigned to spend its **unchanged 1 / 2 / 3 Parts per host** on larger, readable forms instead of flat ornamental strips.

| Arena | Low: essential large form | Medium: structural mass | High: final equipment |
| --- | --- | --- | --- |
| Classic | Raised storm receiver mast | Broad radar crossarm | Physical spherical sensor |
| Towers | Tall, industrial rooftop cooling stack | Machined vent cap | Upper mechanical crown |
| Crossroads | Oversailing transit signal header | Distinct service enclosure | Asymmetric switch module |
| Orbital | Angled ceramic solar wing | Opposing wing | Central telemetry boss |
| Harbor | WedgePart tapered freight barge prow | Raised aft wheelhouse | Overhead load boom |

All parts are genuine Roblox native anchored geometry on the original host CFrames. They do not form new parkour ledges, gameplay platforms, collision objects or navigation obstacles.

For Harbor specifically, `arena-midground-mass.client.lua` now calls the same original motif kit on the **existing hull**. It adds **2 Low / 6 Medium / 12 High client-only Parts total** over 2/3/4 barges respectively. Other arenas **retain their pre-existing motif counts**, but replace thin details with larger structural profiles. Nothing is repeatedly spawned per frame; the same map/tier rebuild handles cleanup and the existing shared scenery LOD limits distance.

### Player-visible in-arena skyline
`ArenaDistrictArchitecture.lua` resizes eight **existing geometric definitions**, without increasing its existing 16 building Models or part count:
- Observatory fins and survey lens made taller/more visible.
- Freight cross-gantry widened.
- Industrial turbines and armored housings enlarged.
- Communication mast, cross arms and signal prism extended vertically.

All updated original buildings remain anchored, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`, and inherit the existing per-model mobile visibility and PBR ownership. No UI, audio, remotes, gameplay hazard, AI, respawn, reward or map footprint changes.

## Resource and quality contract

- **One edited shared native motif kit**, one existing Harbor caller, one original district server builder. No new game modules, imported assets, texture uploads, Roblox permissions, lights, physics, loops or new unit tests.
- Macro form upgrade is not photorealism. Visibility, shadow style, texture appearance, parallax and clipping need authenticated device captures; the new wedge / rooftop heights require actual visual review.
- The two Harbor barge structures on Low add two local Parts (one each). High adds 12 parts across its four barge hulls. `VisualBudgetRules` already counts the existing `ArenaMidgroundMassLocal` folder, so these Parts are not silently untracked. No FPS or thermal claim without real evidence.
- The `ArenaDetailKit` helper now accepts an optional Roblox-native `WedgePart` class for a realistic prow, preserving ordinary `Part` behavior and conditional `Shape` usage for all existing service decorations.

## Publication safety gate

Per project policy, **no unit or integration tests are triggered in this improvement phase**. Before the **next public update**, run the existing **manual** full Build Validation and all five Open Cloud engine suites on the final **exact merged SHA**, then capture actual Android Low, Medium and High shots in all five arenas. Review from player-height and elevated parkour cameras, inspect device FPS/memory and make sure new silhouettes do not confuse players about accessible paths.

The public experience remains Universe `10771083668`, Place `95351659174730`. No publishing credentials or saved game data are touched by this PR. Publish only after successful exact-SHA gates and owner-approved release workflow.

## Next product decision

After real Android visual evidence, prioritize **visible parkour depth, architectural focal hierarchy and accurate PBR roughness** rather than adding many more small details. If visual clutter obscures disaster warnings, simplify foreground art before adding larger meshes.
