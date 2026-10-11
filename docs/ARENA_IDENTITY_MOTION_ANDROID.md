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

## Exact-head core_a regression repair

The original watcher used `require(script.Parent.ArenaIdentityMotionRules)` at module load, which failed in file-based Lest (`script` was nil) before any arena spec could execute. The watcher now takes the already-loaded `ArenaIdentityMotionRules.isIdentityPart` predicate as its third argument. The live LocalScript supplies the same predicate, and the Open Cloud test supplies it explicitly. This eliminates the test-environment-only dependency without duplicating the filtering logic or changing the render budget. Recheck Build Validation plus all five engine shards on the resulting commit; no visual/mobile sign-off is inferred.

## Authored mechanical micro-motion pass

The existing noncolliding, anchored MapBuilder ornament parts now get six
distinct **local-space** animation signatures, layered onto the established
color/transparency treatments. There are no new Parts, lights, emitters,
remote events, render loops, or changes to playable collision geometry:

| Map | Existing ornament | Authored secondary motion (High maximum) |
| --- | --- | --- |
| Classic | Survey-marker crowns | Vertical calibration travel within 0.16 studs |
| Classic | Broadcast glow vanes | Slow yaw within 4 degrees |
| Towers | Machinery caps | Hoist travel within 0.18 studs |
| Towers | Antenna glow shafts | Roll within 1.5 degrees |
| Crossroads | Route gates | Structural sweep within 0.10 studs |
| Crossroads | Gantry signal bars | Roll within 2.2 degrees |

Low/Medium/High amplitudes reuse the existing 0.38 / 0.68 / 1 tiers.
Each pose is applied to a captured base CFrame, never accumulated from the
last tick. Existing Orbital crown/node motion and static tower bands are
untouched. ReduceMotion uses zero animation scale and immediately restores
the original captured transforms through the existing accessibility handler.
The 0.16 / 0.09 second active update policy is unchanged.

The core_a `arena-presentation.spec.luau` suite now checks all six named
styles, tier scaling, maximum displacement, deterministic frame transforms,
invalid targets, and reduced-motion gating.

**Physical acceptance still required:** visually check on Studio and
Android that survey heads, vanes, machinery, antennas and gantry strips
remain coherent with their fixed supporting architecture. Record close and
wide view, Low/Medium/High and ReduceMotion, and watch for occlusion,
distraction from hazard warnings, and performance regressions. No FPS or
premium quality pass is asserted by these automated geometry tests.
