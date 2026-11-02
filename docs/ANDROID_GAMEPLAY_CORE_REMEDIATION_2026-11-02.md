# Actual Android gameplay corrective pass — 2 November 2026

## Scope and evidence

The owner provided six real 1536×688 Android screenshots from the actually published Chaos Survival build `a3e414bea21d6dec9e0d8bed7a454c8b42415699` (public workflow 41428449036). **8/8 EN VIE** is visible, but that HUD number alone is NOT evidence that eight humans were playing.

Priority defects independently seen: insufficient terrain/character lighting, bright neon with dark almost unreadable surrounding geometry, simplistic floating platform silhouettes, stacked optional task labels, and several bot NPCs converging or appearing stuck/uncoordinated. Although the extra Android floating panel at right comes from another app, the game itself still needs stronger center visibility and better survival instruction.

The existing source patch on `main` (`6e1d320bb024cd1a932711c5eff613f5cfa354c6`) was **not publicly published**. Its Build Validation succeeded, but the real Roblox Cloud engine run **41430457701 failed core_a: 4 deterministic regressions** from stale expected Android nameplate/Neon transparency values. The 4 failures were NOT a network outage. This branch updates the stale existing engine expectations first.

## Corrective implementation

**1. Daylight readability without lights per deck**

`arena-lighting.client.lua` is now authored for genuine readable 14:42–15:36 daylight rather than 17:50–19:06 dusk in all five distinct world palettes. Existing true Roblox Ambient/OutdoorAmbient become moderately bright and neutral, brightness 2.45 (2.65 Low) with a positive unmodified-phase exposure range 0.11–0.14. Preserve the existing native bloom, disaster-specific warning effects, shadows on supported tiers, five distinct art palettes and same local tween owner. No extra lights, shadow casters or per-frame loops. As before, disaster post-processing owns actual round/ready hazard visuals. A real Android screenshot comparison is necessary to validate the physical result.

**2. Physically plausible bot recovery**

`AISurvivorRules.forwardTravel` measures ONLY actual horizontal movement toward the chosen destination. A bot oscillating sideways against a large wall no longer passes the old “1.15-stud displacement” test and remains permanently stuck. After genuine low progress (with normal hesitation and reaction), `AISurvivorService.recoverIfStuck` records the failed point for 7.5 seconds, discards stale multi-step traversal reservations, keeps human-equivalent normal jump, then attempts a 6.5-stud detour **only through clear horizontal raycast air with a true solid floor below**. No teleport, artificial animation speed, noclip, server path ownership change or unbounded raycast sweep; at most eight clearance probes after the *second* missed progress interval. Subsequent target selection temporarily rejects the same repeatedly blocked zone, with live hazards retaining priority. New pure forward-motion checks in the existing AI engine suite assert forward, lateral, reversed, vertical and malformed cases.

**3. Actually explain the main win condition**

The persistent bottom focus strip already has bonus-task progress (“ÉCLATS 0/2”) and a third pill that often duplicated the exact disaster name printed in the large hazard header. Rather than adding another banner that obscures the player, replace only this **redundant** label with the true **SURVIS X s / SURVIVE X s** instruction from existing `CoreLocalization.SURVIVE_SECONDS`. Keep optional coin/shard/parkour progress, actual danger HUD, sweep/flanks/fusion/intensification and the final 0-second countdown unchanged. No new persistent UI element.

**4. Real platform form and native material details**

`PlatformFinishKit.buildServiceHatch` adds a visible three-layer 3D maintenance hatch/collar/handle with map-appropriate concrete, metal, diamond-plate or timber materials on **one out of three** medium/high-tier qualifying real decks. Mobile Low gets **zero extra parts**. Only decks 8–36 studs wide qualify. Every hatch inherits the real colliding platform's existing Weld, CollapsePhase, route-shrink footprint and lifecycle; all three detail parts are Massless, CanCollide/CanTouch/CanQuery=false and have no lights/particles/false jump surfaces. Existing material/brace/corner armor and all maps' unique hardware remain. Existing engine specs validate 3D ownership, collision safety, collapse and Low-budget exclusion.

## QA/release contract

- Fix all four known pre-existing Cloud assertion regressions in `tests/engine/arena-presentation.spec.luau` and `tests/engine/ai-survivor-rules.spec.luau`. They must reflect unchanged real current code, not paper over an actual runtime bug.
- Run GitHub Build Validation and ALL FIVE Roblox Open Cloud engine shards on the **new exact main SHA** after merge (one major milestone); investigate rather than blindly retry any genuine failure.
- Only after green CI can the existing manual-only public-playtest workflow publish the same SHA to existing Roblox universe 10771083668 / place 95351659174730. A repository merge is NOT a live update.
- Physically validate 15 genuine Android screenshots over 5 maps: distinguish lit character from all surfaces; see an accessible raised escape route in Rising Lava, normal walking/jumping NPC behavior against walls and densely packed peers, real shard objective plus visible SURVIS seconds, dynamic shockwave warning, platform visual fidelity and p95 FPS/thermals on low hardware.
- Mark true AI unsticking **provisional** until a real game recording or Studio diagnostic proves NPC navigation across large obstacles. Real-world success is a stronger bar than syntactically valid Luau code.
