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

## One-shot ReducedMotion pose (11 October 2026)

The local hero-scenery controller now restores each tracked monument's
authored CFrame, size and transparency when ReduceMotion is selected.
A static, at-most-0.13-strength tint conveys active hazard identity without
oscillation, blinking or camera motion. RoundState/tier/accessibility updates
and new-scene scans refresh this pose; the existing 0.24s reduced loop no
longer iterates over tracked pieces or performs tween/trigonometry writes.

Low/Medium/High non-reduced motion and existing LOD skips are unchanged.
No new parts, GPU effects, server logic, hitboxes, network events or
per-frame listeners have been added. Engine regression covers static tint
bounds and fallback behavior in the pre-existing core_a test file.

Manual acceptance: confirm that ReduceMotion toggles restore hero silhouettes
(including reactor core size), that Bombs/Meteors remain recognizable by tint,
and that map swaps and late scenery replication do not retain old transforms.
Android FPS, power consumption and thermals still require hardware testing.

## Single-write monument animation (11 October)

In normal motion mode, the authored service-car, cable and reactor-arm
gesture is composed with the disaster reaction before a single CFrame
write, avoiding the prior intermediate write. Non-moving ornaments
restore their base CFrame once when a disaster ends, rather than
repeating that same write on every quiet loop iteration. Existing
Low/Medium/High amplitudes, ReduceMotion static poses, hazards,
collisions and LOD rules are unchanged. Engine core_a regression checks
rotated 3D composition. Physical Android profiling remains necessary.

## Authored rest-to-motion transitions (11 October 2026)

The client-only hero landmark controller now eases **existing** authored
3D movement in over 480 ms when an ornament first appears, re-enters the
scenery LOD, or when the player turns ReduceMotion **off**. A smoothstep
envelope multiplies each existing Low/Medium/High displacement amplitude,
including disaster reaction translations and rotations. This prevents the
TowerServiceCar, crane cable and OrbitalReactorArm pieces from instantly
jumping from a static authored pose into a distant sine-wave pose.

For parts hidden by scenery LOD, the controller restores their captured
CFrame and Size **once while hidden**, without changing transparency (which
belongs to the LOD owner). The first visible animation frame resumes from
rest. On ReduceMotion **on**, the established immediate one-shot still-pose
path remains in effect; no animation is permitted. New tracked parts begin
with their own start time, so streamed-in geometry also enters gently.

The existing signal, tally, crown and reactor glow offsets are scaled from
their captured transparency baseline during entry, rather than retaining
a constant offset when animation strength is zero. Hazard color accents
remain immediate for danger recognition; gameplay hazard warnings are not
dimmed or delayed.

**Cost:** one scalar smoothstep evaluation per visible tracked landmark
per existing animation tick; no new parts, tweens, loops, remotes, server
work, particles or lights. Current cadence is unchanged.

**Engine regression:** `tests/engine/landmark-disaster-reactions.spec.luau`
(core_a) checks entry endpoints, halfway interpolation, invalid times,
rotated 3D baseline displacement and combined tier/ReduceMotion gating.

**Physical acceptance still outstanding:** Roblox Studio and Android
inspection of the Tower lift/cable, Orbital arms, Crossroads signals and
Classic tally during late streaming, LOD hide/show and rapid
ReduceMotion toggles. Confirm no residual size/pose changes, flicker,
obscured hazard telegraphs or frame-time regression at Low/Medium/High.
No physical FPS, GPU, battery or thermal measurement is claimed.

## Authored kinetic antennae and transit shutter signals (11 October 2026)

The existing noncolliding **Classic** broadcast antennae (two High-tier
neon masts) now counter-sway in local space by at most 1.8 degrees.
The existing **Crossroads** transit signal bars (two on Low, three on
Medium/High) now perform a phase-staggered vertical shutter travel
within 0.085 studs, with at most 1.1 degrees of roll. Their fixed
supporting geometry does not move. Both motions are composed against
the captured original CFrame and combined with the existing disaster
reaction in the controller's single CFrame write.

The old three-state instant on/off Crossroads blink has been replaced
by a continuous three-phase cosine chase: transparency and color now
fade between authored baseline values, avoiding a hard jump every
roughly 0.42 seconds. These signals are *scenery*, not hazard warnings;
the disaster telegraph and UI pipelines are unchanged.

The existing motion tier, 480 ms streaming/LOD resume envelope and
ReduceMotion one-shot authored rest pose gate remain in control.
This lot adds no geometry, lights, particle emitters, remotes, loops,
colliders or server-side work. One bounded CFrame calculation is added
for each visible antenna/signal on the **existing** hero-motion tick.
No new work occurs in the reduced-motion idle path.

`tests/engine/landmark-disaster-reactions.spec.luau` (core_a) adds
checks for all five possible pieces, local-space composition on a
rotated base, deterministic no-drift poses, maximum travel, quality
scaling, zero-scale rest, invalid numeric input and the smooth,
three-phase light cycle.

**Still requiring manual verification:** visually inspect antenna
alignment and transit-bar clearances in Roblox Studio, then assess
Android readability, accessibility, LOD streaming and frame-time
under Low/Medium/High. Automated tests and a successful build cannot
certify premium visual quality or device FPS/thermals.

## Towers crane counterweight: opposing local articulation (11 October 2026)

The already-authored `TowerMaintenanceCounterweight` now performs a
small mechanical counter-travel opposite the nearby
`TowerMaintenanceCraneCable` sway. The same 0.72 phase drives a maximum
0.28-stud local X translation and 0.8-degree counter-roll, composed from
the captured original CFrame. No additional geometry, lights, emitters,
physics, server remotes or update loops are introduced.

The counterweight exists only in Medium/High Towers scenery; Low creates
no counterweight and therefore incurs no new tracked part. The existing
motion tier multiplier (Low 0.18, Medium 0.62, High 1), 480 ms resume
envelope, distance-LOD gate, disaster reaction, and one-shot ReduceMotion
rest pose remain authoritative. The counterweight is anchored and has
CanCollide/CanTouch/CanQuery disabled by the scene factory.

The core_a engine spec checks opposite motion to the cable, bounded
translation, tier scaling, deterministic poses on rotated bases, invalid
clock inputs and zero-amplitude accessibility behavior. This is not a
claim of physical Android FPS or Studio visual clearance: inspect the
counterweight against the mast, cable and nearby player sightlines in
Studio and on a real Android device before accepting the visual result.

## Orbital reactor: low-cost precession (11 October 2026)

The already-authored, anchored `OrbitalReactorCore` now combines its existing
size/color/transparency pulse with a slow original **axial precession**:
maximum 0.10 stud of local vertical travel and 1.6 degrees of local pitch.
Its offset is composed with the existing disaster-reaction frame in the
single CFrame write, against its captured authored base pose.

The precession is **disabled on Low** (the original pulse remains intact)
and uses a continuous Medium/High amplitude under the existing 480 ms
stream/LOD resume envelope. Moving from Medium/High to Low restores the
core's base CFrame on the next normal controller update; switching on
ReduceMotion restores it immediately via the existing one-shot static-pose
handler. Scenery LOD continues to own visibility and hidden pieces are
not animated. No parts, lights, GPU emitters, remotes, loops, physics,
server code or hazard telegraphs were added.

`tests/engine/landmark-disaster-reactions.spec.luau` (core_a) verifies the
bounds, rotated local-frame composition, deterministic no-drift transforms,
Low rest pose, Medium/High scale, invalid inputs and ReduceMotion zero
offset. CI is necessary but insufficient: visual clearance, actual Android
FPS/frame-time, GPU/memory and thermal performance are **not verified**
without Roblox Studio and physical-device profiling.

## Non-colliding service-scene articulation and light choreography (11 October 2026)

The existing **Medium/High** asymmetric client-local hero scenery now gets
an intentional secondary service-language pass, without instancing new art:

- Classic: the anchored `ClassicOpsAntenna` surveys with a maximum
  1.15-degree local yaw, while the fixed operations booth is undisturbed.
- Orbital: `OrbitalDockingArmGlow` runs a slow restrained Neon intensity
  cycle without moving the structural docking arm or adding a light.
- Crossroads: the three `CrossroadsClosedLaneBarrier*` strips use distinct
  phase offsets for a smooth, low-contrast closure chase rather than
  identical flashing. They remain visible throughout the pulse.

All poses use the stored original CFrame and the existing 480ms resume,
quality-tier and distance-LOD policy. Low does not instantiate the service
cluster; ReduceMotion restores all baseline colors/poses/transparencies in
one shot. Active disaster tint remains immediate and the service elements
are not gameplay telegraphs. No new BasePart, GPU emitter, light, network
event, collision or rendering loop is added. The single existing hero
loop tracks these pieces only when they exist.

Existing `landmark-disaster-reactions.spec.luau` (core_a) now verifies
deterministic local 3D composition, rotation limits, tier scaling, static
accessibility, slow staggered 3-bar pulses and malformed timestamps.

Required before visual signoff: Roblox Studio and physical Android
reviews of antenna clearance, all three closure strip light rhythms,
Orbital docking silhouette, LOD reappearance, Low/Medium/High and
ReduceMotion. No Studio screenshots or physical FPS/GPU/thermal metrics
have been obtained by this code-only pass.

## Exact-head Open Cloud core_a reactor guard repair (11 October 2026)

The `core_a` job in run `38154978005` on `3b418550` reported
225/226 assertions passing. The sole failure was the oversized
`reactorCoreOffset(1.37, 1e8)` input returning approximately
0.09239 stud of movement when the contract required the original rest
frame. Large-but-finite scales were clamped to full amplitude. The
reactor-core rule now rejects scale magnitudes above `1e7`, consistent
with its existing timestamp bound and invalid NaN/infinity checks.
A negative oversized scale is also tested. All legitimate
Low/Medium/High, ReduceMotion and streaming/LOD behavior is unchanged.
No server gameplay, geometry, collision or GPU budget is affected.
Verify Build Validation and all five Open Cloud shards on the new SHA.
Roblox Studio and physical Android QA remain outstanding.

## Android quiet-frame BasePart.Color write reduction (11 October 2026)

The client-owned landmark controller previously assigned the same baseline
`BasePart.Color` on **every** animation tick for all roles other than the
animated reactor core and transit signals, even when no hazard was active.
This unnecessary property-write traffic affected service decorations and
other static landmarks on mobile.

The new `shouldRestoreBaseColor(role, hadReaction)` policy writes the
captured baseline exactly once on the first frame after a disaster reaction
ends. During a disaster, per-frame accent composition is unchanged.
`reactorCore` and `signal` still author their own dynamic color every
frame, including the first quiet frame. The policy also preserves
ReduceMotion's immediate one-shot rest pose and the LOD-hidden skip.

A `core_a` regression covers all tracked landmark roles, quiet frames,
the reaction-to-idle transition, and the real Part's restored Color.
No geometry, physics, network calls, render loops, or emitters are added.
The optimization removes redundant assignments, but physical Android
FPS/GPU/thermal improvements remain **unmeasured**.

## Orbital docking capsule: bounded local stabilizer (11 October 2026)

The existing noncolliding anchored `OrbitalDockingPod` now gets a unique
mechanical stabilization pose: at most 0.12 stud of vertical travel and
1.25 degrees of roll, with differing time phases. The `OrbitalDockingArm`
and `OrbitalDockingNeck` stay fixed; no extra geometry, lights, emitters,
server events, hitboxes, or render loops are introduced. The pod only
exists in the pre-existing Medium/High asymmetric service cluster,
not Low.

Each pose composes from its captured original CFrame and uses the
existing per-tier amplitude, 480 ms stream/LOD re-entry envelope,
active-disaster reaction and one-shot ReduceMotion return to rest.
A bounds and non-finite-input guard rejects malformed timing/scales.
The core_a landmark spec covers deterministic transformations on a
rotated base, amplitude/angle limits, tier scaling, invalid numeric
inputs and static accessibility gates.

Unverified: actual Roblox Studio clearance against the pod's docking
neck, visual desirability of the movement, physical Android graphics
and thermal/FPS performance. No screenshots or device measurements
have been produced.


## ReduceMotion / LOD-hidden rest-pose handoff (11 October 2026)

When ReduceMotion is enabled while an authored landmark is outside the
distance-LOD range, the landmark must return to its captured rest pose
*while still hidden*. The LOD controller owns `LocalTransparencyModifier`
and its `SceneryLodHidden` attribute; the hero-motion controller owns
the decorative part's authored `CFrame`, `Size`, `Transparency` and
`Color`. Restoring those authored properties cannot unmask the LOD
visibility modifier (which remains 1 until the LOD controller shows it).

The reduced-motion handler now applies the still pose to both visible
and LOD-hidden tracked parts on the existing event/scan path. This
prevents a hidden moving monument from briefly reappearing in an
animated pose when the distance-LOD state changes ahead of the next
2.5-second scan. No continuous reduced-motion animation, additional
instances, render loops, remotes or server writes are introduced.

The `core_a` engine regression exercises a real LOD-hidden Part,
checks pose, size, authored alpha/color, preserved visibility mask and
the subsequent show transition. Existing Low/Medium/High cadence and
ReduceMotion stillness remain unchanged. Visual clearance and frame
time on Roblox Studio/Android hardware remain unverified.
