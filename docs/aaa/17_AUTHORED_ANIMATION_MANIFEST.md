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


## Production specification

These timings are project targets, not gameplay locks. They must be tuned against actual Humanoid speed and may change after device playtest.

| Clip | Target length/cycle | Roblox priority intent | Blend target | Required notes |
|---|---:|---|---:|---|
| Idle Neutral | 2.5–4.0 s loop | Idle | 0.18–0.30 s | subtle breathing/weight shift, no exaggerated sway |
| Idle Variant A/B | 2.0–3.5 s loop | Idle | 0.20–0.35 s | variation only; never distract during READY |
| Walk | 0.80–1.05 s cycle | Movement | 0.10–0.18 s | stable foot contact at expected walk speed |
| Run | 0.55–0.78 s cycle | Movement | 0.10–0.16 s | athletic, forward intent, no sprint caricature |
| Jump Takeoff | 0.18–0.30 s | Action/Movement transition | 0.06–0.12 s | Takeoff marker; gameplay jump occurs immediately |
| Fall/Apex | 0.45–0.90 s loop/hold | Movement | 0.10–0.18 s | readable silhouette, not ragdoll-like |
| Light Landing | 0.20–0.34 s | Action | 0.06–0.12 s | Land marker near first stable contact |
| Heavy Landing | 0.34–0.58 s | Action | 0.06–0.12 s | Land + Impact; visual recovery must not lock control |
| Stop/Deceleration | 0.20–0.42 s | Movement/Action | 0.08–0.14 s | avoid foot skating when velocity already stopped |
| Hit React Light | 0.14–0.26 s | Action | 0.04–0.10 s | upper-body readable, locomotion remains responsive |
| Hit React Heavy | 0.22–0.38 s | Action | 0.04–0.10 s | no long stun unless gameplay separately owns it |
| Eliminated | 0.65–1.20 s | Action | 0.05–0.12 s | must hand off cleanly to spectator/result state |
| Victory | 1.4–2.3 s | Action | 0.10–0.18 s | readable from result camera distance |
| Clutch/Master | 1.5–2.5 s | Action | 0.10–0.18 s | stronger silhouette than normal victory |
| Social Emote | 1.0–2.0 s | Action | 0.10–0.18 s | lobby/result only; cancel cleanly on round transition |

### Marker timing contract

Markers are semantic events, not decoration.

- `FootL` / `FootR`: closest stable foot contact, used for material footstep audio/VFX.
- `Takeoff`: visual departure beat; it must not trigger the real gameplay jump.
- `Land`: first convincing ground contact.
- `Impact`: strongest heavy-landing/hit beat.
- `VictoryBeat`: primary pose/celebration accent.
- `EmoteBeat`: optional social accent.

Acceptance:
- marker timing remains believable at 0.9x–1.15x playback;
- no duplicate footstep events with existing material-footstep logic;
- client effects subscribe once and disconnect/cleanup correctly.

## Runtime integration contract

Create one animation ownership layer instead of letting every feature play tracks independently.

Recommended runtime responsibilities:
- preload/cached Animation objects by semantic ID;
- obtain one Animator per Humanoid;
- cache loaded tracks per character;
- stop/replace incompatible tracks by state;
- blend using weights rather than abrupt Stop/Play where possible;
- never search the full character hierarchy every frame;
- cleanup tracks/connections on CharacterRemoving/Destroying;
- bots may offset playback start/speed slightly within bounded rules.

Procedural systems remain additive:
- lean;
- braking micro-pose;
- impact compression;
- camera;
- trails;
- ReduceMotion scaling.

If an authored clip and a procedural layer fight the same joint strongly, the authored clip owns the major pose and the procedural layer must be reduced.

## File / asset naming

Source file convention:
- `anim_r15_<state>_v###`

Examples:
- `anim_r15_idle_neutral_v001`
- `anim_r15_run_v003`
- `anim_r15_land_heavy_v002`

Roblox manifest fields:
- semantic ID;
- source filename/version;
- Roblox animation asset ID;
- creator/owner;
- published date;
- loop flag;
- expected priority;
- markers;
- QA status;
- replacement/fallback clip.

Do not hardcode final IDs across unrelated scripts. Centralize them in one shared animation configuration module when authored clips are integrated.

## Review cameras

Every clip is reviewed:
1. default player camera;
2. side 3/4 view;
3. result distance;
4. narrow Android viewport;
5. bot/remote-player distance.

An animation that only looks good from the authoring viewport is not approved.

## First production milestone

Do not author all clips simultaneously.

Milestone A:
1. Idle Neutral
2. Walk
3. Run
4. Jump Takeoff
5. Fall/Apex
6. Light Landing
7. Heavy Landing

Integrate and compare against the current procedural/default stack.

Milestone B only begins if A measurably improves perceived quality without harming responsiveness:
8. Stop/Deceleration
9. Hit React Light
10. Eliminated
11. Victory
12. Clutch/Master
13. Social Emote

## Animation department exit gate

Animation reaches premium release-candidate status only when:
- Milestone A is authored, integrated and device-tested;
- result/elimination moments no longer read as stock Roblox motion;
- footsteps/landing markers are synchronized;
- no control latency is introduced;
- no track stacking/memory leak appears in a 30-minute session;
- bots remain varied;
- ReduceMotion still preserves state readability;
- animation ownership is documented and tested.
