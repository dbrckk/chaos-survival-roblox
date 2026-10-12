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

## Phase-aware cinematic ease-in

Anchored arena ornaments now fade into their existing movement when a round
state changes instead of immediately jumping from a static pose to full swing.
The existing RoundState remote is reused; no new event, object, texture,
sound or update loop is introduced. The local owner only resets the clock on
an *actual phase change*, so repeated RoundState updates do not restart
animation.

* Ready: 68% of tier amplitude (anticipation without overpowering UI).
* Round: 100% of tier amplitude (active arena character).
* Result: 46% of tier amplitude (calmer visual finish).
* Waiting, vote, other inactive phases: 0%, with original transforms restored.
* Inactive-to-active transitions ease from 0%, while ready-to-round and
  round-to-result transitions ease from the previous displayed intensity
  (including interrupted transitions). No sudden reset to rest mid-round.
  The smoothstep interpolation takes 340 ms.
* Re-enabling ReduceMotion eases in from rest; enabling it restores the
  captured authored pose immediately.
* Existing quality-tier amplitude caps, ReduceMotion zero gate and update
  intervals are unchanged. The function controls scenery only, not hazard
  telegraphs, camera, player inputs or collision.

The core_a engine tests verify 0/170/340 ms, crossfades from the previous
pose (including interrupted transitions), steady-state targets, inactive
phases and interaction with Low graphics and ReduceMotion.

Android/Studio manual acceptance still required: check ready-to-round,
round-to-result and result-to-lobby transitions in all four arenas. Watch
for unwanted movement jumps, visual distractions during a sudden disaster
warning, smoothness at Low quality, and stability after repeated phase
messages. Automated engine rules cannot establish subjective appearance or
mobile FPS; no such claim is made.

## Precision collar and reactor-node articulation (11 October 2026)

Two additional existing MapBuilder ornaments now receive subtle original
3D choreography, without new geometry, light sources or GPU emitters:

- **Towers**: each of the twelve anchored `TowerBand*` collars counter-rotates
  up to 2.6 degrees around its local Y axis, phase-shifted per collar. The
  fixed tower spine remains unchanged.
- **Orbital**: each of the eight anchored `OrbitalReactorNode*` spheres
  levitates within 0.12 studs relative to its existing authored base frame.
  This combines with the existing Orbital wobble in a **single CFrame write**
  per ornament/tick. The twelve Orbital crowns retain their existing motion.

The shared `ornamentOffset` guard rejects non-finite timestamps, indices and
amplitudes; index must be an integer from 1 to 64. Timestamps beyond 10 million seconds are rejected instead of wrapping
the animation phase; this avoids an abrupt pose jump at a periodic boundary. All eight named
motions retain tier amplitudes Low=0.38, Medium=0.68, High=1 and zero motion
with ReduceMotion. Hidden ornaments remain skipped by the existing LOD gate.

Engine `core_a` regression now covers eight 3D signatures, deterministic
local-space composition, long-session timestamps, and malformed numeric inputs.
The previous six-motion tests are preserved. No live Roblox Studio/Android
visual acceptance or physical FPS, battery, thermals or GPU profiling has
been performed. Check collars and nodes at close range on all tiers, including
accessibility toggles and map streaming, before marking production-ready.

## Final Rush visual-focus stability (11 October 2026)

The existing `RoundState.finalRush` flag now reduces the amplitude of
the eight **decorative** arena ornament motions to 38% of their existing
phase/tier-limited intensity. Gameplay hitboxes, disaster telegraphs,
UI warnings, character motion and server hazard timing are not changed.

On entry to, and exit from, Final Rush, the current displayed ornamental
amplitude interpolates to the new target over 450 ms (smoothstep).
Repeated RoundState packets with an unchanged flag do not restart the
transition. A mid-transition interruption starts from its actual
displayed value, avoiding a visual snap. The already-existing
ReduceMotion, Low/Medium/High and decorative update cadence are retained.
No new Part, VFX emitter, lighting instance, client loop, server remote
or gameplay change is introduced.

The `core_a` engine spec tests initial/halfway/completed focus transitions,
recovery, interrupted transitions, invalid numeric input and combined
Low-quality and ReduceMotion constraints. Manual Studio and Android QA
must confirm hazard legibility and camera-facing clarity during Final Rush.

**Exact-head build hygiene correction:** `ArenaIdentityMotionRules.lua`
contained the numeric constant `10000000` in the long-session guard.
The existing production hygiene CI rejects six consecutive zero digits,
as it also uses that pattern to catch placeholder identifiers. Writing
the identical numeric threshold as `1e7` keeps runtime behavior unchanged
and avoids a false positive. Build and Roblox Open Cloud checks on the
new HEAD are required; neither outcome is assumed here.

## Streamed identity ornaments: LOD and accessibility return

Arena.Decor identity pieces now track their own **appearance resume** time.
When a new named piece streams in, or an existing piece returns after
`SceneryLodHidden`, its original authored pose is the starting frame.
A 480 ms smoothstep envelope progressively restores its existing per-map
motion, color pulse and glow; this envelope multiplies (never overrides)
phase intensity, Final Rush focus and Low/Medium/High budgets.

The map watcher previously restored and rescanned **every** ornament when
one new named child streamed in, causing existing machinery to jump to
rest. Within the same Arena and VariantId, rebuilds now reuse existing
parts' authored baselines, current resume clocks and LOD state. Only
newly arrived parts begin their resume envelope; removed parts are
restored once. Changing arena or variant still restores old poses before
capturing a new baseline.

On the first observed hidden frame, the client restores the authored
`CFrame`, `Color` and `Transparency` once. It deliberately **does not
change `LocalTransparencyModifier` or `SceneryLodHidden`**, which are
owned by the scenery LOD system. Returning from ReduceMotion also resets
the resume clock. No new client loops, scene parts, lights, emitters,
server messages, hitboxes or gameplay timing are introduced.

The `core_a` engine regression covers invalid/halfway/complete resume
times, tier and ReduceMotion multiplication, actual Roblox BasePart pose
restoration, preserved LOD visibility modifier, and detached instances.
The client-side rebuild ordering and live streaming event timing remain
manual acceptance items, not covered by those pure-rule assertions.

**Physical acceptance required:** cycle all four arenas with rapid
stream-in/out and ReduceMotion on/off; inspect that crowns, antennas,
collars and reactor nodes reappear without visible pose jumps, while
unchanged ornaments continue their original animation when one new part
streams in. Verify mobile Low/Medium/High and hazard cue readability.
Record Studio and physical Android frame-time, FPS and thermal
observations separately; none have been measured in this change.

## Core_a Roblox floating-point regression (11 October)

The Open Cloud `core_a` run for `af489e1` reported 218/219 assertions
passing. The sole failure was an exact `BasePart.Transparency` comparison:
`0.31` versus the engine-stored `0.3100000023841858`. The restoration
implementation was not changed. The regression now checks transparency and
`LocalTransparencyModifier` with a strict absolute tolerance of `1e-5`;
CFrame and Color assertions, LOD ownership, accessibility and tier budgets
remain in place. This handles engine property precision without masking a
visible or material deviation. Verify Build Validation and all five Open
Cloud shards on the resulting exact HEAD before considering CI green.

## Tower lift counterweight synchronization (11 October 2026)

The two **existing** anchored, non-colliding `TowerCounterweight-1` and
`TowerCounterweight1` parts now travel opposite to the Towers signature
lift cabin (maximum 1.4 studs, compared with the cabin's 2.0 studs).
Their initial authored CFrames are captured once, so updates cannot drift.
This adds two entries to the **existing** signature animation list, with no
new Parts, lights, particle emitters, remote events or render loops.

The signature clock now treats NaN, infinities, negative timestamps and
unreasonably large values as rest pose, preventing invalid CFrames after
malformed or interrupted client timing. ReduceMotion immediately restores
both the cabin and counterweights to their authored poses. The existing
Low/Medium/High part budgets and update cadence are unchanged.

The `arena-presentation.spec.luau` engine suite checks opposite-direction
travel, amplitude bounds, all three tiers, accessibility restoration and
invalid-clock handling. **Manual acceptance remains necessary:** inspect
counterweight clearance, movement readability and device performance in
Roblox Studio and on a physical Android device; no FPS or GPU results are
claimed here.

## Touch readability versus distance LOD (11 October 2026)

On touch devices, `MobileReadabilityKit` attenuates decorative Neon
using `LocalTransparencyModifier` while preserving the smaller gameplay-edge
tint and noncompounding Point/Spot/SurfaceLight brightness profiles.
A streamed decoration marked `SceneryLodHidden = true` is now excluded
from the Neon modifier pass, so touch-tier refreshes cannot reveal a
distance-culled part by replacing its LOD-owned modifier of 1. Lights
still receive the normal brightness profile without changing their
`Enabled` state. After the scenery LOD owner restores the visibility
attribute and baseline modifier, the next touch readability pass can
apply the correct Low/Medium/High appearance again.

The existing `arena-presentation.spec.luau` core_a engine shard checks
both a decorative Neon part and a safety-edge Neon part through
Low/High hidden updates, Medium visibility return and disabled light
state. No additional geometry, particle emitters, lights, render loop,
server traffic, collision or gameplay change is introduced.

Manual acceptance remains open: on physical Android and in Studio,
toggle graphic tiers near a streaming/LOD boundary and confirm that
decorations stay hidden until LOD reveals them, while warning and
navigation cues remain readable. No Android performance metrics or
Studio screenshots are claimed by this regression.

## Touch Neon return after LOD (11 October 2026)

The previous hidden-state guard prevented touch-tier changes from revealing
Neon while `SceneryLodHidden` was true. A second, distinct failure mode
remained: distance LOD could restore the saved visibility modifier after the
last touch readability pass, leaving a returned Neon strip at its unadjusted
brightness until another quality or streaming event.

The touch client now registers one `SceneryLodHidden` attribute listener
per Neon part, including children of newly streamed subtrees. When LOD has
restored `LocalTransparencyModifier` and clears its hidden attribute,
the client reapplies the active touch tier immediately. Hidden transitions
never write visibility. Observers disconnect when a subtree disappears
and when the Decor generation changes, avoiding stale map callbacks.
The source of truth for hidden state remains `scenery-lod.client.lua`.

Existing `arena-presentation.spec.luau` in the core_a Open Cloud shard
exercises both ordinary and gameplay-edge Neon, hide/reveal event ordering,
modifier precision and listener disconnection. No new client loop, 3D
geometry, particle, light, network message, physics rule or player input
change is introduced.

This is automated engine coverage, not physical Android acceptance:
real-device streaming and repeated distance-boundary traversal still
need a visual and performance pass at all quality tiers.


## RoundState resilience (12 October 2026)

The client-only arena ornament listener now reads RoundState through
ArenaIdentityMotionRules.roundSnapshot. Non-table or late malformed event
payloads reset decorative state to waiting without throwing and disrupting
future decorative phase transitions. Valid ready/round/result transitions
and Final Rush pressure retain their earlier meaning; this changes no
server state, collision, damage, or hazard telegraph. The engine arena
presentation suite exercises malformed payloads and valid transitions.
Studio and physical Android rendering remain untested.
