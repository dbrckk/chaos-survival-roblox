# Hero landmark motion: Android and accessibility

The existing client-owned landmark motion loop now uses
`HeroMotionBudgetRules` for conservative per-tier scheduling. Low, Medium
and High retain their 0.16s, 0.09s and 0.055s animation intervals and
motion amplitudes of 0.18, 0.62 and 1. Unknown tiers fall back to Low.

ReduceMotion removes **continuous landmark displacement** entirely
(scale 0, previously 0.18) and throttles the remaining non-displacing
hazard tint/transparency refresh to 0.24s. With no tracked scenery the
loop backs off to 0.50s; the existing ChildAdded/periodic scan still
detects new landmarks. LOD-hidden cosmetic parts are skipped until visible.

The implementation does not create new Parts, lights, particles, loops
or remotes. No gameplay, collisions, server rules or visual part-count
budgets change. The existing disaster reaction color feedback remains.

Automated regression: `tests/engine/landmark-disaster-reactions.spec.luau`
covers all tiers, unknown-tier fallback, ReduceMotion, idle cadence,
and LOD-hidden/detached instances. This file is already assigned to the
core_a Open Cloud shard.

Manual acceptance: compare landmark animations and hazard readability
in Roblox Studio, then profile real Android devices at Low/Medium/High
with ReduceMotion on/off. FPS, battery and thermal benefits have
**not** been measured on hardware.
