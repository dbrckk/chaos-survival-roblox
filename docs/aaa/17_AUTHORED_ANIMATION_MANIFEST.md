# Animation Department — Authored R15 Manifest

## Goal

Replace the remaining "Roblox-standard" motion ceiling with a small, coherent authored animation set.

Procedural layers remain secondary:
- lean;
- bob;
- camera;
- trails;
- accessibility scaling.

Authored clips provide the fundamental body performance.

## Required clips

| Clip | Priority | Loop | Markers | Gameplay lock? | Status |
|---|---|---|---|---|---|
| Idle Neutral | S | yes | optional IdleBeat | no | NOT AUTHORED |
| Idle Variant A | B | yes | optional | no | NOT AUTHORED |
| Idle Variant B | C | yes | optional | no | NOT AUTHORED |
| Walk | S | yes | FootL, FootR | no | NOT AUTHORED |
| Run | S | yes | FootL, FootR | no | NOT AUTHORED |
| Jump Takeoff | S | no | Takeoff | no | NOT AUTHORED |
| Fall/Apex | A | loop/hold | optional | no | NOT AUTHORED |
| Light Landing | S | no | Land | no | NOT AUTHORED |
| Heavy Landing | A | no | Land, Impact | no | NOT AUTHORED |
| Stop/Deceleration | A | no | optional | no | NOT AUTHORED |
| Hit React Light | A | no | Impact | no control lock | NOT AUTHORED |
| Hit React Heavy | B | no | Impact | no/very short | NOT AUTHORED |
| Eliminated | A | no | Impact | server state already owns elimination | NOT AUTHORED |
| Victory | A | no | VictoryBeat | result only | NOT AUTHORED |
| Clutch/Master | A | no | VictoryBeat | result only | NOT AUTHORED |
| Social Emote | B | no | EmoteBeat | lobby/result only | NOT AUTHORED |

## Motion style

Chaos Survival characters should feel:
- athletic;
- reactive;
- light enough for fast survival;
- grounded enough to avoid floaty default motion;
- slightly stylized, not realistic mocap copied without cleanup.

## Key animation rules

- hips lead locomotion;
- shoulders counterbalance;
- feet should not slide visibly;
- jump anticipates but does not delay input;
- landing compression must fit actual velocity;
- heavy reaction must not steal control;
- victory animation must be readable in result composition;
- bots may vary playback/timing subtly but share the same physical language.

## Authoring workflow

1. reference;
2. block key poses;
3. validate at gameplay speed;
4. add breakdowns/overlap;
5. fix foot contact;
6. add markers;
7. export/publish;
8. integrate with Animator;
9. blend with procedural layer;
10. test ReduceMotion;
11. test Android.

## Acceptance test

Side-by-side:
- current procedural/default stack;
- authored stack.

Keep authored clip only if observers perceive:
- stronger weight;
- cleaner intention;
- better polish;
- equal or better responsiveness.

## Performance

Animation quality must not trigger:
- expensive per-frame rig searches;
- duplicate Animator ownership;
- uncontrolled track stacking.

Cache tracks and reuse.
