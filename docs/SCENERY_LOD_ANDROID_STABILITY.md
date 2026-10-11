# Stable decorative scenery LOD on Android

The existing client-only decorative scenery LOD uses distance thresholds for
Low and Medium tiers. A symmetric 8-stud hysteresis now avoids frequent show/
hide transitions when a player or mobile camera rests near one cutoff.
Fresh folders use the original threshold. Already-visible art hides at
threshold + 8; hidden art returns at threshold - 8. High remains unlimited.

The camera CFrame is now sampled once per LOD pass rather than once per
decorative folder. Hidden Parts, Lights and Effects are only written again if
another cosmetic owner changed their hidden value. This still enforces
invisibility and preserves each pre-LOD transparency/enabled state for restore.

No new geometry, light, GPU effect, render loop, server script, gameplay remote
or mobile quality budget was added or changed. Roblox engine checks in
tests/engine/visual-budget-rules.spec.luau (existing core_b2 shard) verify
initial thresholds, stable hysteresis and malformed-distance fallback.

Manual Roblox Studio and physical Android acceptance remains required:
walk slowly across the distance threshold in Classic/Towers/Crossroads/Orbital,
check animated landmarks and hazard warnings remain legible at Low/Medium/High,
then profile FPS, GPU, memory and temperature during map and tier switches.

## Visible-folder fast path (11 October 2026)

When a folder remains visible and its descendant membership has not changed,
the client now skips its redundant per-descendant LOD property scan. The
DescendantAdded/DescendantRemoving callbacks continue to invalidate caches,
and a hidden→visible transition still restores every original transparency
and Enabled state. Hidden folders retain their existing per-pass re-hide
checks, so concurrent cosmetic animations cannot expose distant decoration.

This changes only client CPU work; it does not change distance hysteresis,
quality thresholds, visual appearance, static/mobile part budgets, any
gameplay behavior or add new loops. Build and Open Cloud checks are required
on the exact commit. Actual FPS, CPU, GPU and heat improvements must be
measured on Roblox Studio and an Android device before making performance
claims.
