# Phase Dash distance LOD — PR #19

This client-only visual optimization keeps the original authored pressure-blade
motif while reducing transient Part/Tween creation for distant survivor dashes.

## Visual budgets

| Viewer-to-avatar distance | Low | Medium | High |
| --- | ---: | ---: | ---: |
| Local player or remote below 72 studs | 5 | 7 | 10 |
| Remote from 72 through 110 studs | 3 | 4 | 5 |
| Remote above 110 studs | 0 | 0 | 0 |
| ReduceMotion (within view) | 3 | 4 | 5 |

At close range, High still receives its existing secondary 10-facet ring
and Medium/High still receive their ribbon. At 72–110 studs, the secondary
ring and ribbons are omitted. ReduceMotion disables both regardless of distance.
The 110-stud outer culling threshold is unchanged.

No new light, emitter, permanent loop, physics, hitbox, input, cooldown,
network message, or server-authoritative gameplay change is introduced.

## Automated regression coverage

`tests/engine/movement-safety.spec.luau` checks near/far tier caps,
facet descriptors, ReduceMotion interactions, invalid distances and
72/110-stud boundaries. Build Validation and all five Roblox Open Cloud
shards must pass on the exact final PR head.

## Required physical acceptance (not yet performed)

On an unpublished candidate, check each tier with a second avatar at
71.99, 72, 110 and >110 studs, including spectators and AI survivors.
Verify close-range directionality and responsive gamefeel, reduced-motion
readability, cleanup over repeated rounds, and stable hazard warnings.
Measure Android FPS, frame-time spikes, memory, battery and thermal
behavior on a physical device before claiming a performance gain.
