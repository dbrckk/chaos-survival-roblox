# Climax effects on rectangular arenas

The nine radial climax signatures (lava, meteor, tornado, gravity,
fracture, speed, darkness, freeze and shock) use the replicated arena
Base.Size for separate local X/Z scaling instead of treating the longest
edge as a circular arena diameter. Rotation follows the scaled travel
direction; detail length uses the shorter side. Scalar legacy recipes
remain available.

The effects remain client-only, without hitboxes, shadows or new loops.
Per-hazard Low/Medium/High part caps stay at 2/4/6 and ReduceMotion
stays at one stationary, fading element. No server or protocol changes.

Validation: tests/engine/disaster-climax.spec.luau covers a 168x62
deck, malformed geometry, a rotated/pitched frame and quality counts.
Manual Roblox Studio visual inspection and real Android FPS/thermal
profiling are still required.

## Bomb pressure fronts and shrinking-edge accents

The Bombs climax now follows the rectangular deck's X/Z proportions rather
than using the short side as a circular radius. Its two-color, alternating
wedge pressure fins use the existing parts, sizes and tween durations; no
additional geometry or GPU effects are created. The yaw follows the local
elliptical radius.

At High quality, the shrinking-arena climax now puts both extra short
strokes on opposite **long edges** of a rectangular deck, including tall
arenas. Medium and Low retain their prior four/two cardinal or opposed
strokes. ReduceMotion remains one static, fading part for either hazard.

The engine suite asserts a 168x62 deck, rotated/sloped frame parity from
existing tests, axis-scaled blast endpoints, long-edge accents and unchanged
part-count budgets. Actual Android/Studio visual acceptance is outstanding.
