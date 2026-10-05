# Cross-Discipline Tool — System Conflict Matrix

## Purpose

High-quality systems can conflict when active together. This matrix lists the most important collision pairs.

## Visual conflicts

| System A | System B | Risk | Rule |
|---|---|---|---|
| Hazard warning | Decorative lighting | warning loses contrast | decorative lighting yields |
| Double Chaos VFX | Double Chaos VFX | opacity overload | primary/secondary hierarchy |
| Final Rush | Critical health | competing vignette | merge/prioritize |
| Result constellation | Cosmetics | too many glows | reduce secondary lights |
| World signage | Hazard telegraph | false gameplay cue | signage lower saturation |
| Bloom | emissive warning | warning becomes soft | lower bloom in ROUND |

## UI conflicts

| A | B | Risk | Rule |
|---|---|---|---|
| Vote | Meta menus | cognitive split | vote closes/deprioritizes meta |
| READY | Tutorial overlay | too much copy | one actionable instruction |
| ROUND | Social CTA | distraction | hidden |
| Result | Next round | CTA persists too long | phase invalidates CTA |
| Spectator | Result | stale overlay | state machine owns transition |

## Audio conflicts

| A | B | Risk | Rule |
|---|---|---|---|
| Hazard cue | Music | masked warning | music ducks |
| Impact | Reward | emotional ambiguity | impact first |
| Double Chaos cues | each other | noise | frequency/rhythm separation |
| UI spam | ambience | fatigue | rate-limit UI sounds |

## Motion conflicts

| A | B | Risk | Rule |
|---|---|---|---|
| Authored animation | procedural lean | broken pose | procedural layer bounded |
| Landing | camera impact | excessive motion | shared intensity budget |
| Final Rush pulse | ReduceMotion | discomfort | accessibility wins |
| Bot steering | cosmetic motion | uncanny movement | steering truth wins |

## Gameplay conflicts

| A | B | Risk | Rule |
|---|---|---|---|
| Shard route | lethal route | forced greed | shard optional/safe enough |
| Challenge | survival | player reads instead of reacts | challenge secondary |
| Double Chaos pair | arena mechanic | impossible state | pair/map audit |
| Bot avoidance | pad targeting | missed pad | pad approach priority |

## Social conflicts

| A | B | Risk | Rule |
|---|---|---|---|
| Invite | first session | premature marketing | wait until value exists |
| Share | new round | interruption | result-only |
| Reaction UI | gameplay | distraction | result-only |
| Status/prestige | newcomer | alienation | visible but non-dominating |

## Performance conflicts

| A | B | Risk | Rule |
|---|---|---|---|
| AI | high VFX | CPU/GPU contention | tier budgets |
| Cosmetics | result VFX | light/particle spike | result budget |
| Dynamic skyline | hazard particles | fill-rate spike | phase-aware suppression |
| Multiple RenderStepped systems | mobile | frame-time fragmentation | consolidate/throttle |

## Data/economy conflicts

| A | B | Risk | Rule |
|---|---|---|---|
| Daily reward | save outage | false persistence | hide/temporary-state messaging |
| Purchase | stale session | duplication/loss | server authority + idempotency |
| Invite/share | reward economy | spam incentive | no gameplay/economic reward |

## Review rule

Whenever a new system is added:
1. list at least three systems it may overlap with;
2. define priority;
3. define fallback;
4. test simultaneous activation.
