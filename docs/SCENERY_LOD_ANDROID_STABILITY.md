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

## Client practice-pad budget accounting (11 October 2026)

The four lobby practice pads are server-owned BaseParts in
GeneratedMap/Lobby/Activities. Their **local** Highlight lives in a Folder
under each pad, and their **local** ParticleEmitter in a separate Attachment
directly under that pad. Neither is a top-level workspace folder, so the
previous VisualBudgetRules.collect(root) silently omitted them from live
device-tier budget telemetry.

The collector now traverses *only* marked lobby practice pads and counts
these named local child effects; it excludes server-owned pad geometry,
PointLights and unrelated effects. A missing or partially removed local
bundle is handled without exceptions. On four active pads, the visible
counter gains exactly eight local GPU effects (one emitter and one
Highlight per pad). It drops to six on removal of one pad and zero on
cleanup. No budget thresholds are raised; the actual live visual load is
unchanged, and the corrected count can expose previously hidden overages.
The existing core_b2 visual-budget engine shard verifies these scenarios.

This fixes telemetry accounting, **not** actual render-frame cost. Android
FPS/GPU/memory and physical-device screenshots remain to be measured.

## Nested practice-pad LOD (11 October 2026)

The distance-based cosmetic LOD previously looked for
`workspace.PracticePadPolishLocal`, but the local practice effects are
actually nested under server-owned BaseParts at
`GeneratedMap/Lobby/Activities/PracticeBoostPad*`. Their Highlight
Folder and particle Attachment also have separate parents.

On every existing LOD cadence (0.65s Low, 0.90s Medium/High), the
client now discovers only these two specific local containers per marked
pad. Both use the existing lobby distance cutoffs of 100/150 studs and
8-stud hysteresis. The shared hide/restore code disables out-of-range
emitters and highlights, and restores their previous Enabled state on
return, without adding any new task or render loop.

Server-owned pads, PointLights and unrelated game effects are not passed
to the local LOD writer. The engine core_b2 suite checks correct nested
target discovery, four-pad and streaming-removal counts, no duplicate
targets, server-art exclusion and existing Low/High distance behavior.
A real Android frame-time/temperature check is still needed to measure
the performance impact.
