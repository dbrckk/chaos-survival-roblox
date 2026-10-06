# Complexity & Subtraction Register

## Purpose

Feature count is not quality.

This register tracks areas where the project may become too complex, duplicated or noisy.

## Complexity categories

### Code complexity
Watch:
- giant files;
- repeated phase logic;
- duplicate localization;
- duplicate VFX systems;
- repeated workspace scans;
- overlapping ownership.

### Player complexity
Watch:
- too many currencies;
- too many challenges;
- too many result tags;
- too many buttons;
- too many named modes;
- overlapping progression systems.

### Sensory complexity
Watch:
- too many glows;
- too many trails;
- too many concurrent sounds;
- too many banners;
- too many camera effects.

### Operational complexity
Watch:
- too many branches/workflows;
- fragile deployment steps;
- hidden config;
- undocumented asset ownership.

## Current watchlist

1. `src/client/init.client.lua`
   Dense central UI ownership. Continue extracting only when extraction improves clarity without creating fragmented state.

2. Result presentation
   Many valid tags/rewards/social elements can compete. Keep narrative priority strict.

3. Character polish
   Procedural layers have reached diminishing returns. Avoid adding more before authored-animation benchmark.

4. Audio composites
   Layering is strong, but many composites reuse the same legacy source sounds. Replace sources rather than adding more layers.

5. Visual depth
   Multiple environment systems exist. Prefer tuning/harmonization over a new scenery controller.

6. Social surfaces
   Invite, reaction, share and crew continuity are useful, but must remain result/lobby bounded.

## Subtraction sprint procedure

For one iteration:
- no new feature;
- no new currency;
- no new UI panel;
- no new persistent system.

Only:
- delete;
- merge;
- simplify;
- localize;
- optimize;
- harmonize.

Review every active system:
- does it create unique player value?
- does another system already communicate this?
- can its effect be reduced?
- can two feedback layers become one?

## Removal criteria

Remove/merge if:
- value is hard to explain;
- players ignore it;
- it conflicts with higher-priority information;
- it causes disproportionate technical cost;
- it duplicates another system;
- its metric impact is weak.

## Premium principle

AAA-like polish is often the result of editing.

A coherent 90% feature set can feel more premium than a noisy 120% feature set.
