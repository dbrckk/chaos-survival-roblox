# Visual QA scorecard — subjective art quality requires visual evidence

Use this file to review a **rendered build**, not its source code. Do not assign arbitrary AAA/10 ratings without screenshots and a tester.

| Area | Reviewer discipline | Required evidence | Gate |
| --- | --- | --- | --- |
| Silhouette per arena | Environment art | Low/High distance capture for all four maps | Distinct without neon |
| Composition & pacing | Art direction | Lobby, Ready, Round, Result footage | One focal point per phase |
| Materials & detail | Technical art | Close/medium-range side-by-side captures | Plausible layered forms |
| Character animation | Animation | R6/R15 walk, pivot, jump, land, death, emote | No broken poses |
| VFX signature | VFX | 11 hazards under Low/High and Double Chaos | Clarity precedes spectacle |
| UI interaction | UX | 320/360/400/440px tap-safe video | No overlap and clear next action |
| Accessibility | QA | Reduced Motion, audio muted, color-only signals | Usable without motion/color |
| Mobile performance | Performance | Model, session, tier, FPS, memory, temperature | No crash or persistent hitch |
| Streaming & cleanup | Engine QA | Map swap, reconnect, 30-minute session | No ghost objects or leaks |

**Rating scale:** 0 = absent, 1 = broken, 2 = generic but functional, 3 = intentional, 4 = polished, 5 = production showcase. Require a source screenshot, reviewer, date, candidate commit for each rating. Treat performance, accessibility and gameplay readability as hard gates regardless of the art rating.

Release blocks: unlicensed assets, unreadable warnings, visual blockers/colliders, persistent camera seizure, severe mobile frame drops, missing model after replication, duplicated UI/lighting, dangling VFX after multiple rounds.

## Human momentum ribbon: mobile and accessibility gate

The human sprint ribbon uses one sculpted, three-point tapered Trail, lazily
created only for eligible round movement. AI trails remain owned by
`bot-motion-polish`; the human controller no longer watches bot rigs.
Low and ReduceMotion emit no human ribbons; Medium culls beyond 60 studs,
High beyond 90 studs from the camera (local player exempt). Styling changes
only when the tier changes, at the tier's decorative update interval.
Incomplete rigs receive one ChildAdded listener and an 8-second timeout.

**Physical acceptance still required:** respawn and reconnect repeatedly;
switch Low/Medium/High and ReduceMotion while sprinting; inspect humanoid
root trail counts, Final Rush and elimination cleanup, and remote culling.
Profile a crowded round on a low-end Android device for FPS, memory, GPU
overdraw and 30-minute stability. Engine specs check policy, not real FPS.

## Crowded-round remote ribbon budget

Only the nearest **four** remote humans on Medium or **eight** on High
can render human momentum ribbons simultaneously; Low and ReduceMotion
remain fully disabled. The local player's ribbon is never removed by
the remote budget. Existing visible ribbons get a 3-stud priority bias
to reduce popping as nearby players trade distance. Reusable candidate
and selection tables avoid allocations in the decorative update loop.
This is cosmetic only: movement, damage, collisions, rewards and
server-authoritative bot visuals are unchanged.

**Verification:** engine rules specs cover budget, nearest ordering,
selection reset and tie stability. On an authenticated Android/Studio
session, compare crowded rounds at each tier, test rapid camera turns,
respawns, ReduceMotion toggles and GPU overdraw. No measured FPS gain
is claimed until physical profiling.

## Human ribbon rebuild safety — lifecycle regression

`CharacterMotionTrailBuilder.ensure` now reuses the two authored root
attachments if the Trail is externally deleted, and reconnects an existing
Trail if either attachment disappears during a streamed-rig transition.
This prevents duplicate attachment accumulation during cosmetic recreation;
there are no new parts, sounds, lights, or motion settings. Low/Medium/High,
ReduceMotion, remote ribbon caps and gameplay authority are unchanged.

**Engine coverage:** create twice, destroy/rebuild the Trail, and destroy/
repair one attachment. **Physical follow-up:** verify 2 attachments and at
most 1 human ribbon per root after repeated respawns and long Android rounds.
The engine test is not evidence of real-device FPS or GPU behavior.
