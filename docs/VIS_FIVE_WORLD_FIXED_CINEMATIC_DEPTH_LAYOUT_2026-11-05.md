# VIS — Fixed cinematic skyline locations across all five quality tiers

Date: 2026-11-05. Chaos Survival Roblox. Source milestone only, not a Roblox public update.

## Source defect

The existing `arena-cinematic-depth.client.lua` generates four independent cosmetic rings in every 320-stud world. Their angles were calculated with `index / visibleCount`. Changing Low, Medium or High therefore changed the WORLD position of identically named horizon structures, Orbital halo arcs, atmospheric beacons/lights and sky traffic trajectories. This creates visible backdrop jumping on Android quality changes.

## Corrected

The pure shared `CinematicDepthLayoutRules` makes each numbered slot an immutable angular location. The same original 5/8/11 horizon pieces, 0/10/14 Orbital halo pieces, 0/3/5 atmospheric beacon lights and 0/2/4 sky traffic models are now low/medium/high subsets of a single canonical High ring. The variants, material/phase tints, size, distance LOD, animations, ReduceMotion, source-approved imported 3D kits, platform collision, warnings and gameplay remain unchanged.

No new Models, textures, Parts, lamps, physics, remote events, per-frame updates or cloud assets. This changes positions only and retains existing cosmetics and their performance budgets. The existing owner still rebuilds on phase, tier or streaming changes.

## Certification

Added a dedicated Lest engine spec `tests/engine/cinematic-depth-layout.spec.luau` to the existing seven-suite Roblox Cloud workflow. It verifies counts, each tier is a subset of the previous, unique ordered angles, rejected invalid indices and source identity. An exact-SHA source milestone and full Roblox build must also pass before considering the change validated.

Real Android Low/Medium/High and PC screenshots, measured mobile FPS, motion quality and final AAA art acceptance are NOT certified by source checks; public publication remains disabled.
