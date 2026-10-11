# Arena identity animation — accessibility and streamed decor

Four authored arena identities retain their existing geometric/material designs
and Low/Medium/High animation amplitudes (0.38 / 0.68 / 1). The client only
animates tracked, visible Arena.Decor ornaments during ready/round/result.

ReduceMotion now restores their captured CFrame, color and transparency on
toggle and stops continuous wobble/glow pulses (zero animation scale). The
loop sleeps at 0.60 s when idle, untracked or reduced; active updates retain
the existing 0.16 s Low and 0.09 s Medium/High cadence. Pieces marked
SceneryLodHidden are skipped, without changing LOD state or budgets.

A single map-scoped `ArenaIdentityMotionReadiness.watch` now observes late
`GeneratedMap.Arena`, late/replaced `Arena.Decor`, `Arena.VariantId`
changes, and direct addition **or removal** of named identity BaseParts.
Unrelated hazard and geometry children do not trigger rescans. A debounced
client callback rescans only the current map generation; disconnecting the
watcher invalidates queued work. Each rebuild restores tracked CFrame,
Color and Transparency before recording fresh baselines, preventing stale
animated ornaments and additive drift across map swaps. No new render
loop, geometry, lights, particles, collisions or server-side changes.

Roblox Open Cloud regression lives in
tests/engine/arena-presentation.spec.luau (core_a shard): quality tiers,
ReduceMotion, idle scheduling, LOD skips and streamed-ornament name filters.
The live client event timing is not physically tested by these pure-rule
assertions.

Still unverified: Studio visual check on four arenas (including decor
streaming after map load, ReduceMotion toggles and LOD transitions), and
Android FPS, battery, thermal and GPU metrics with graphics Low/Medium/High.


## Exact-head regression and physical acceptance

The core_a engine spec now exercises real Roblox Instance ChildAdded,
ChildRemoved and VariantId events with late Arena/Decor, relevant vs
irrelevant children, Decor replacement, orphaned old containers and
disconnection. Passing these checks does **not** validate a live network's
streaming schedule or mobile framerate.

On a staged candidate tied to its SHA, cycle Classic -> Towers ->
Crossroads -> Orbital while rapidly reloading or streaming the arena.
Verify ornaments animate once (no duplicates), stop after Decor removal,
follow late VariantId, and restore original static poses when ReduceMotion
is enabled or combat ends. Capture Studio screenshots and Android video,
plus in-client performance statistics if available; leave these acceptance
items unmarked until actually observed.
