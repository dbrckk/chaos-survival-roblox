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

## Human ribbon motion hysteresis and live identity

The sprint ribbon now uses a 0.82 speed-ratio entry threshold and a
0.76 exit threshold for an already-visible ribbon. Camera culling retains
the previous ribbon for at most 3 additional studs (Medium 63 / High 93).
This reduces boundary flicker and repeated segment startup while preserving
the four/eight remote-ribbon GPU caps. Phase changes, Final Rush, airborne
states, Low and ReduceMotion always disable the effect immediately on the
next decorative update. A changed `ChaosAccent` recolors the **existing**
ribbon once, without adding attachments, trails, particles or lights.

**Automated evidence:** the existing character-polish engine spec checks
both hysteresis boundaries, all mandatory disable conditions, accent
recoloring and unchanged object count. **Physical QA still required:**
camera oscillation near 60/90 studs, sprint-stop jitter, changing accents
mid-round, repeated respawn, crowded Android GPU/FPS and long-session
cleanup. No real-device performance improvement is claimed.

## Human ribbon — contestant identity and attachment recovery

The human ribbon now requires server-owned `RoundParticipant=true` and
`RoundEliminated~=true` player attributes, as well as the existing round,
sprint, quality and distance gates. Late joiners, eliminated players and
spectators cannot display the same sprint signal as active survivors.
The registry caches the owning Player when binding a rig, avoiding repeated
player lookups in the decorative update loop. A missing streamed attachment
is detected even when its Trail still exists; the builder repairs the same
ribbon on the next eligible visual update.

**Engine coverage:** eligible/ineligible participant states and intact,
orphaned and repaired attachment transitions. **Physical QA:** sprint in the
lobby during an active round, join late, eliminate and respawn, and delete
an attachment while sprinting in a staging Studio session. Confirm one
Trail and two attachments per eligible root; compare Low/Medium/High and
ReduceMotion on Android. No FPS gain is claimed without device measurements.

## Remote human ribbons — camera-frustum culling

Remote human trails now require **both** the existing speed/phase/distance
policy and a padded camera-viewport projection before entering the nearest
4/8-player GPU selection. New ribbons use a 10% viewport margin; an already
visible ribbon gets an 18% margin to avoid abrupt changes during camera pans.
Roots behind the camera are culled. Projection only runs for otherwise
eligible remote rigs and does not use per-frame RenderStepped hooks, raycasts,
extra particles, lights, or allocations of Instance objects. Camera viewport
initialization (zero-sized or missing view) fails open; the old distance and
tier caps still apply. Local player trails stay exempt. Low/ReduceMotion
still disable the effect, and the engine test covers the screen bounds,
retention margin, behind-camera depth, and camera-startup fallback.

**Physical acceptance pending:** rotate the camera quickly beside sprinting
survivors, check edges on narrow Android portrait/landscape screens, observe
spectator camera changes, repeat respawns and tier toggles, and profile GPU
fill/FPS and 30-minute stability. Projection reduces *eligible off-screen*
ribbons but is not a wall-occlusion test or measured Android improvement.

## Character footwork — directional sculpted 3D signatures

The existing short-lived locomotion cues now use authored shapes rather
than three recolored flat neon strips: **Launch** creates paired forward
thrust wedges, **Pivot** creates radial counter-steer wedge fins, and
**Skid** leaves low industrial metal braking grooves. Their opposing
rotations and offsets make motion legible even without relying on color.
High adds a restrained Neon material on only the first pair of wedge
fins; Medium is non-Neon, and Low/ReduceMotion keep their existing zero
ground-cue policy. Every cue stays within the pre-existing **2 Medium /
4 High parts**, **0.56-second cleanup**, and exactly one tween per part.
There are no meshes, external assets, new lights, collision, shadow,
humanoid/physics, camera, damage or movement changes.

**Automated evidence:** the existing body-motion engine spec validates
each cue's actual instance class, material, piece count, dimensions,
transparency, noncolliding properties and rejected invalid signatures.
**Physical acceptance pending:** verify both feet and surface readability
on rotated maps, footwork under simultaneous hazards, camera tilt, R6/R15
character movement and mobile GPU/FPS at Low/Medium/High/ReduceMotion.
CI is not evidence of Android performance or visual polish in Studio.

## Sculpted footwork — slope alignment and contestant identity

Launch/Pivot wedges and metallic Skid grooves now follow the actual raycast
**floor normal** rather than a horizontal plane; their yaw rotates around
the inclined surface up-axis. A deterministic basis helper rejects steep
walls, missing normals or degenerate headings. Geometry remains anchored,
noncolliding, shadowless and auto-cleaned within 0.56 seconds. No extra
parts, emitters, raycasts or high-frequency loops were added.

Local ground cues also require the server-owned **RoundParticipant=true**,
**RoundEliminated~=true**, a living Humanoid and the round phase. This
prevents late joiners or eliminated spectators from showing movement marks
reserved for active survivors. Ordinary locomotion, camera, UI, hazard
warnings, collision, speed and rewards are unchanged. Bots still follow
their existing phase/range/cooldown policies, and Low/ReduceMotion emit no
optional ground cues.

**Engine regression coverage:** sloped basis normal/tangent, 3 styles x
four High-tier parts, steep/invalid surfaces and active/spectator/life
participation gates. **Physical acceptance required:** capture slanted
Towers and Orbital ramps at Low/Medium/High; test joins, elimination,
respawn, camera turns and 30-minute Android GPU/FPS/cleanup. No physical
Studio/device result or FPS gain is claimed from CI alone.
