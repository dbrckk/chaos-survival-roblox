# Chaos Survival — impact VFX: surface-aligned shrapnel and physical ash

**31 October 2026 — source-only improvement after PR #442.** Not published to Roblox; no runtime measurements or engine tests are claimed.

## Real architectural problem

The existing `HazardImpactFeedback` client already sampled the impacted surface **once per event**, deriving a correct normal, `ImpactMaterialRules.surfaceFrame`, material-aware chip color and dust color. But `ImpactSetpiece.spawn` ignored this data: its `MeteorShard`, `BombPressureSpoke`, `MeteorCraterRim`, and `BombPressureArc` were always positioned in **world-horizontal X/Z** and colored too close to the orange/white blast. On rotated or tilted collision decks they could hover, visibly intersect ground and look like extra light beams instead of broken material. The meteor smoke stayed entirely glowing orange.

## Source changes

- Pass the **existing single raycast** result (`surfaceFrame`, `surfaceColor`, `surfaceMaterial`) to the existing ImpactSetpiece owner; no second raycast or extra network fields.
- Place and tween original shrapnel and crater/pressure-ring pieces in **local ground coordinates** transformed by that `CFrame`. Their motion is now consistent with sloped collision surfaces and the existing material-aware airborne chips.
- Meteor fragments remain native **Basalt** and take a charcoal/earth surface tint with a very small explosion-color contribution; bomb shrapnel uses the existing sampled `ImpactMaterialRules` material and color. Both stay clearly distinguishable from the authoritative impact flash.
- Reuse the **same existing plume ParticleEmitter**, unchanged number of particles, emitter lifetime and rate. Meteor smoke now shifts from heat-tinted ground dust at birth through grey ash to dark drifting residue, instead of all-orange fire; the emission factor is reduced. Bomb clouds use even more of the impacted dust palette.
- No authored texture IDs, unapproved assets, extra raycasts, new loops, new emitters, Parts or lights, collider, damage changes, state mutation or permission changes. ReducedMotion and original Low/Medium/High burst count and concurrency policies are preserved.

## Compatibility and ownership

The new fields on `ImpactSetpiece.spawn` are **optional**; injected-rule/spec callers using only `position/color/kind/radius` fall back to the original world-up frame and a neutral material color. All trajectory positions remain bounded by the existing `ImpactSetpieceRules.safeRadius` and short-lived (`Debris:AddItem(container, recipe.Lifetime + 0.12)`). Local setpiece geometry remains anchored, `CanCollide=false`, `CanQuery=false`, `CanTouch=false`, shadow-free and included in the existing `ImpactSetpieceLocal` resource budget counters.

These visuals do not rewrite warning zones or impact/damage origins. Visuals may extend away from the impact point during a brief impact beat, as before; no gameplay implication is made.

## Next *release milestone* acceptance

1. Launch the **existing** manual Build Validation and all five Roblox Open Cloud engine suites on the exact intended release commit.
2. Trigger Meteor and Bomb on a regular flat deck and a genuinely tilted/rotated map surface. Confirm ground alignment and no wrong-sided crater debris, and that the actual warning/impact flash still takes priority.
3. Inspect original Android Low, Medium, High in a burst of concurrent impacts; verify existing part/effect budgets, camera readability and real frame times, memory, thermal behavior.
4. Inspect ReduceMotion: short flash and clear hazard communication without decorative rotating debris.
5. Validate late StreamingEnabled, arena swap and transition to Result; make sure temporary impact effects clean up fully.
6. If in-engine evidence fails, fix before a subsequent **owner-approved public** Roblox publication.

**Production IDs unchanged:** Universe `10771083668`, Place `95351659174730`. Last previously verified public release remains recorded in README; this commit is source-only.
