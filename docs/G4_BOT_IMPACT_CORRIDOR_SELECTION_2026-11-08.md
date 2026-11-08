# G4 — Impact-safe bot corridor selection (2026-11-08)

Source branch: `fix/bot-live-impact-route-revalidation-20261108`. This document records source logic and engine acceptance cases. It does not claim Roblox runtime, Android, or live-place validation.

## Defect

Bots previously cached a Meteor/Bomb warning's version even when their current goal was an ineligible committed world route or cooperative action. Returning to ordinary roaming with the same warning could skip the route intersection check. Replanning a new target under an unchanged warning also skipped the earlier event-only check.

Ordinary roam candidate scoring already penalized intersections, but its safest tier prioritized *landing exposure* alone. A path traversing a current impact zone could still defeat a completely safe corridor when both candidate destinations were outside the footprint.

## Implementation

- `AISurvivorService.stepRecord`: validate a new ordinary goal before `moveHumanLike`, using the cached warning set when either the warning version or *actually inspected* target changes. Do not mark a warning as inspected during committed NavMesh, elevated traversal, real cooperative interaction or urgent danger response.
- On a warned segment: abandon only that ordinary target, cancel the previous movement command, clear idle/turn pause, increment the existing `BotHazardRouteInvalidations` attribute, and let the next normal brain pass select another goal.
- Reset the inspected-target snapshot on rig replacement and every lobby/round entry; no cross-round warning state.
- `scoreCandidate`: reuse the already-computed server warning corridor penalty. Count intersected Meteor/Bomb zones at the same `>= 20` threshold used by `AISurvivorRules.newImpactIntersectsEscape`. When ranking ordinary candidates, minimize landing exposures first, then corridor exposures; preserve profile scores and route variety **only inside** the resulting safest tier.
- No extra physics raycasts, global workspace scans, new timers, movement speed changes, or teleports.

## Engine acceptance matrix

| Situation | Expected behavior |
| --- | --- |
| Two grounded candidates both end outside a Meteor warning; only one route crosses the ring | Bot prefers the nonintersecting corridor before personality randomization |
| Two candidates have different endpoint exposures | Lower landing exposure still has priority; no dangerous goal wins on a random score |
| Warning appears during a committed raised-deck crossing; bot later resumes normal roam | Crossing remains committed; newly eligible normal goal is checked before movement |
| Existing Bomb warning remains while bot chooses another ordinary destination | Newly chosen target is checked despite unchanged warning-version counter |
| Ordinary route is intercepted by new live warning | Existing target and MoveTo are canceled; bot replans without stepping into the warned lane |
| Warning outside all candidate routes | Normal candidate variety and pace remain unchanged |
| New warning and urgent evade coincide | Urgent evasion still wins; no ordinary route override |
| Eight participants on Android during overlapping Meteor/Bomb | Measure `BotHazardRouteInvalidations`, bot step latency, actual FPS and movement continuity; check no repeated per-pass rescoring |

## Release gate

Source checks passed for target snapshot/round reset, one event-cached warning scan and reuse of the existing route-penalty threshold. This is **not** a real Roblox engine pass. Follow the repository's existing exact-SHA Build Validation, Cloud suites, and device QA policy before publishing the existing place. Public experience state cannot be inferred from a GitHub commit.
