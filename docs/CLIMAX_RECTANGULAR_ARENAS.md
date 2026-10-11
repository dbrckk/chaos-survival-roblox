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
