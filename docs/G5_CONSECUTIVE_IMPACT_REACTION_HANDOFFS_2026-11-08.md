# G5 — Continuous Meteor/Bomb reaction handoffs (2026-11-08)

## Scope
Source baseline: `main` commit `7a9bce64d3908fc2990ef158caa1e424dc7ed672` (merged group-aware refuge scoring #699).
Code: `src/server/AISurvivorService.lua`, `immediateThreat`. No changes to disaster mechanics, movement speed, Humanoid physics, client code, the six-candidate escape planner, or pathfinding.

## Defect
When one live Meteor/Bomb warning overtakes another already being dodged (for instance, a second impact lands sooner), the existing threat-selection code correctly chooses the more urgent warning. But it resets `record.threatSeenAt = now` and deletes the current escape target. The bot consequently has **no urgent escape goal** for its entire initial personality reaction delay (roughly 0.12–0.26 s), even though it was already reacting to an impact. In a tight Double Chaos sequence this can trigger a visible halt or an unsafe fallback to ordinary roaming.

## Fix
- On any focus change, preserve the old warning and reaction timestamp before the existing route-reset code.
- Inherit reaction readiness only when **both** old and new warnings are Meteor/Bomb, the old escape was truly committed (`escapeWarning == old`, actual Vector3 target), the escape plan is still live or no more than 0.20s stale, and the previous reaction delay has already elapsed.
- Still discard every stale target, cached warning version and known-warning set; compute a fresh physically supported route for the new warning on that same brain step.
- Maintain the normal individual reaction delay for the first impact, a not-yet-reacted bot, an expired escape plan, or transitions involving Freeze/JumpShock.
- Increment `BotImpactReactionHandoffs` on genuine matured impact-to-impact transfers; reset at round start.

No new raycasts, extra brain pass, timers, teleportation, client event, immunity or speed changes.

## Engine acceptance matrix

| Scenario | Expected |
| --- | --- |
| First Meteor/Bomb warning appears | Normal personality-dependent first reaction delay remains |
| A second Meteor/Bomb warning becomes more urgent while bot is already executing a live escape | Old path is discarded, bot chooses a new safe supported path **without** a second first-sighting pause; increment handoff counter |
| Second warning appears before bot has reacted to the first | No reaction shortcut; initial delay still applies |
| Old escape plan has expired well beyond the 0.20s brain-step tolerance | New warning uses a fresh normal reaction |
| FreezeWarning or JumpShockWarning is replaced by MeteorWarning | Preserve individual initial reaction; no inappropriate jump/dodge shortcut |
| MeteorWarning is replaced by JumpShockWarning | Keep late jump timing based on server-owned timestamps |
| Both impact warnings overlap, 8 participants | No flip-flop after the existing priority/hysteresis checks; inspect target vectors, `BotImpactReactionHandoffs`, actual evasion and Android FPS |
| New warning and collapsing platform coincide | Physical collapse urgency still wins, no fake safe landing |

## Validation state
Source-level exact-match changes and nine targeted structural safety checks passed. The exact branch SHA has **not** passed Roblox Engine, Cloud or Android runtime QA. There is no automatic publication. Keep the PR open until owner play validation / milestone QA per repository policy.
