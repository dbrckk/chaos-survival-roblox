# Chaos Survival — shared cosmetic particle pressure across independent VFX owners

31 October 2026. The current source revision was inspected first. This change is an **optional client graphics policy**, not an authoritative hazard or gameplay change. The visual map audit remains deferred.

## Source finding

Arena cinematic atmosphere already reduced its particle rate during Double Chaos in `DisasterAtmosphereLayout.particleMultiplier` (one disaster 1, two 0.85, three+ 0.70 outside Final Rush). However, the separate premium effects owner created `LavaEmbers` and `FreezeMist` at its full per-tier rate whenever it observed these hazards. The main adaptive Low/Medium/High tier was shared, but the **simultaneous-hazard pressure reduction was not**. Each controller individually complied with its own limit, while their cumulative optional GPU particle load still grew.

## Implemented ownership rule

- `DisasterCosmeticRules.pressureMultiplier(simultaneous)` is a shared pure rule for **optional** particle density: 1 disaster = **1.00**, 2 disasters = **0.85**, 3+ = **0.70**. Invalid/missing input defaults to one; existing two-argument callers of `lavaEmberRate` and `freezeMistRate` retain identical single-disaster output.
- `DisasterAtmosphereLayout` consumes the same rule for non-Final-Rush ambience. It retains the existing authored Final Rush multipliers (**1.45** for one, **1.00** for two, **0.80** for three+), preserving its staged climax.
- The premium lava/freeze controller subscribes to the already-existing `RoundState` event and counts *distinct, recognized* disaster IDs during an active round, capped at 3 for policy lookup. It rejects malformed snapshots and older numbered rounds.
- Only when the count changes, the controller reassigns `Rate` on **existing** `LavaEmbers`/`FreezeMist` emitters, without rebuilding the lava overlay, ice wedges, WarningPart, animation owner, or arena geometry. The normal adaptive loop and quality/ReduceMotion changes also apply the current pressure multiplier. In the lobby/non-round phase the policy returns to 1.
- This does **not** limit or disable server-owned Meteor/Bomb warning footprints, damage, Jump Shock timing, collision, survival objectives, or any safety-related HUD/escape cue. It does not change baseline cosmetics for one disaster.

## Review criteria before the next public update

- Inspect the exact `main` SHA, run Build Validation and all five Roblox Open Cloud QA suites at the publication checkpoint; then run actual Android Low/Medium/High and desktop Studio sessions.
- While RisingLava+Freeze are active, inspect the two emitter rates at one/two/three distinct recognized disaster IDs. Check that repeated `RoundState` heartbeats neither recreate emitters nor reset the rate. Test duplicate/unknown/malformed IDs and a late lower `roundNumber`.
- Toggle ReduceMotion, quality tier and Final Rush; verify that Freeze fog is zero when reduced, that lava heat remains recognizable, and the warnings/damage are identical.
- Record per-owner effects and particle rates with `VisualBudgetRules.collect` alongside FPS, memory, frame-time p95 and Android thermal state. A lower configured Rate is not proof of any particular FPS improvement.

This is coordinated optional particle pressure across the atmosphere and premium Lava/Freeze emitters, **not** a new global live allocator or an automatic enforcement of the total Parts/Lights/Effects ceilings for all independent VFX controllers. No public Roblox deployment or visual map inspection is claimed.
