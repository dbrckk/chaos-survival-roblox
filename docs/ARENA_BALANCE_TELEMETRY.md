# Arena balance telemetry — first observational pass (2026-10-21)

**Scope:** Server-side analytics instrumentation for Chaos Survival's four arenas. This document defines how to evaluate survival, engagement and NPC credibility before adjusting difficulty. **There are no observed gameplay measurements yet**: the latest repository code is not necessarily installed in the public Roblox experience.

## What is measured

Roblox **AnalyticsService custom events**, logged on the server, with a bounded set of three string custom fields:

| Event | Frequency / source | Numeric value | Field 01 | Field 02 | Field 03 |
| --- | --- | --- | --- | --- | --- |
| `ArenaSurvived` | Once per connected human at round completion | 1 if alive, 0 if eliminated | `Arena:Classic/Towers/Crossroads/Orbital` | `Mode:Solo/Multiplayer` | `Primary:<id>\|Fusion:Yes/No\|Extra:Yes/No` |
| `ArenaTimeAliveSeconds` | Once per connected human at round completion | Time from round start to first real `Humanoid.Died` (or elapsed duration if still alive), 0–120s | Same | Same | Same |
| `ArenaBotSurvivalFraction` | **At most once per server round**, attributed to the first connected human (Roblox requires a Player) and only if actual bots started | Living bots ÷ bots at round start, bounded 0–1 | `Arena:...` | `Mode:...` | `Bots:<count>\|Early:Yes/No` |

* `Extra:Yes` means the dynamic mechanic **really started on the server**; it does not merely mean the round was eligible. Baseline mechanics are available in all rounds.
* The primary disaster is tracked; for Double Chaos use `Fusion:Yes` (the secondary disaster ID is not encoded to keep the number of possible breakdowns low).
* Death timestamps come from the same server's monotonic `os.clock()` as the round; if an elimination cannot be precisely timestamped, the system uses elapsed round time instead of fabricating an early death.
* **Players who disconnect before results are not counted** in these round-completion samples. Never interpret the result as retention or a complete participation denominator. The pre-existing `SessionExitStage` and `RoundStarted` events can expose disconnect bias.
* The bot fraction is one **round-level** sample, not one sample per bot or per human. An early end when the last human is eliminated can artificially raise the fraction, so segment `Early:Yes` and `Early:No` separately.
* No persistent data table, DataStore changes, client inputs, remote events, user identifiers in dimension fields, new Heartbeat connection, or per-second analytics logs. Existing `ArenaMechanicUsed`, `RoundChallengeCompleted`, `ChaosShardCollected` and economy events continue unchanged.

## How to review in Roblox Creator Dashboard

Navigate to **Creator Dashboard → Analytics → Explore** for the experience after the updated Roblox place has **actually been deployed** and has received live rounds.

1. Choose `ArenaSurvived` and **Average value**, grouped by Field 01 (Arena), filtered to each Field 02 (Mode). This is the human survival fraction for *completed connected-player rounds*. Repeat by Field 03 for disaster and dynamic-mechanic cohorts.
2. Choose `ArenaTimeAliveSeconds` and **Average value**, preserving the same arena/mode/hazard filters. The value reveals early losses that a survival percentage alone can hide. Compare Solo to Solo, multi to multi, and like-for-like disasters.
3. Choose `ArenaBotSurvivalFraction` and **Average value** by arena and bot cohort. Split `Early:Yes/No` before comparing bot performance. The average is per observed *server round*, not per AI and not a bot-versus-human head-to-head win probability.
4. Examine pre-existing `ArenaMechanicUsed`, `RoundChallengeCompleted`, `RoundStarted`, `RoundCompleted`, `SessionExitStage` and `SessionDurationSeconds` when interpreting whether a map is played, understood, skipped, or abandoned. Do not claim a player enjoyed a round merely because a counter increased.

## Decision guidelines (not fabricated results)

- Compare **the same primary disaster, mode, Fusion setting and Extra setting** across maps. Always inspect sample count and represent small samples as *inconclusive*, not a difficulty ranking.
- If a map's survival drops and time alive drops within the same cohorts, first examine warning readability, danger overlap, AI path choice and mobile control precision. Favor larger warning windows or fairer route access over immediate rewards.
- If survival stays similar but mechanics usage and session progression collapse, investigate whether its objective is obvious, reachable, and satisfying without excessive repetitions.
- If NPCs regularly outlast humans, inspect `Early` cohorts, active AI count, navigation and warning latency; do not grant bots hidden bonuses to mask poor path selection.
- Validate gameplay feel, touch controls, FPS, visuals, progression and reliable long sessions in **real Roblox/Android playtests**. Analytics alone cannot certify these.
- Do not publish or modify the public universe merely to populate this dashboard. Follow the existing release runbook and authenticated publish permissions.

## Limits and reference

`LogCustomEvent` requires a `Player`, a numeric value and up to **three** string custom fields. Roblox applies global AnalyticsService request budgets and cardinality restrictions. Accordingly, the implementation emits two events per connected human after each completed round and at most one bot event per entire server round (no per-frame metrics).

Official Roblox documentation: https://create.roblox.com/docs/production/analytics/custom-events and https://create.roblox.com/docs/production/analytics/event-types.
