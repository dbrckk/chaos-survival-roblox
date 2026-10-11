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
