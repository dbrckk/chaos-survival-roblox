# VIS — Harbor identity and proper Darkness-safe mobile illumination

Date: 2026-11-05. Repository: dbrckk/chaos-survival-roblox. This is a source milestone; no new published Roblox build is claimed.

## Why this changes visible gameplay

1. `arena-navigation-language.client.lua` handled Harbor through the generic Classic center-grid else branch. Both of its permanent floor index marks were therefore visually indistinguishable from Classic's radar design, despite the authored maritime world and distinct physical port routes.
2. `arena-reveal.client.lua` also used Classic's dramatic long orthogonal neon grid for Harbor. Those sweeping lines could be mistaken for traversable routes outside genuine port geometry.
3. `arena-lighting.client.lua` always applied Android's brighter neutral fill on `ready`/`round`, including when **Darkness** was the primary or secondary disaster. The actual disaster owner already reduces material bounce and uses blackout ColorCorrection, but the identity owner counteracted it via `Ambient`, `OutdoorAmbient` and `Brightness`.

## Implemented

- Harbor now has two separate weathered-steel berth-index marks on the actual floor (still only **two** noncollidable Parts) instead of Classic's crossed grid. The existing floor shrink follower keeps the marks true to the authoritative playable base. Distinct from the four other existing map languages.
- Harbor's temporary reveal uses four High / two Medium short dock-side pulses with existing `TweenService` and `Debris`, not a 320-stud illuminated fake route. Low and ReduceMotion produce zero extra pulses. No extra permanent Parts, assets or frame samplers.
- Identity lighting imports the existing shared `ArenaLightingReadabilityRules.hasDarkness` contract, including disaster slot 2. It skips the **extra mobile neutral fill only for Darkness** and retains normal Android readability for RisingLava, JumpShock and all other non-Darkness combinations.
- A change of the disaster pair during an otherwise identical READY/round phase updates the Darkness guard once; redundant one-second timer packets do not generate additional Lighting tweens. A partial packet without `disasterIds` preserves the previous guard until the list arrives or the phase finishes.
- Client-only diagnostic `LocalIdentityDarknessFillSuppressed` describes the intended lighting profile, never measured screen brightness.

## No changes

The server authoritative physics, catastrophe exposure grading / negative ColorCorrection, authored 3D assets / PBR source IDs, mobile quality budgets, gameplay path hints and real route warning colors are unchanged. No new remote requests or background service.

## Remaining gates

Exact-SHA Lua/Roblox Build Validation and seven Roblox Open Cloud suites at the next important milestone; actual Android Low/Medium/High screenshot comparison in normal round, Darkness alone and Double Chaos with Darkness as secondary, plus Harbor against Classic. A passing build is not screenshot or FPS certification, and no publication occurs here.

## CI correction during exact-SHA milestone

Build Validation initially failed because `.github/workflows/ci.yml` still required the obsolete literal `if nextPhase == phase then return end`. That assertion contradicted the fixed hazard-aware guard. The CI source contract now asserts both the unchanged-phase Darkness transition and normal Android fill exclusion, instead of accepting the former known-bug behavior. A fresh exact-SHA milestone is dispatched by the workflow edit; the previous build failure is not treated as a green result.
