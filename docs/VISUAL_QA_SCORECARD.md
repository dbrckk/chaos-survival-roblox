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

## Character reaction and Showtime finishing — 15 October 2026 (unreleased)

Four existing client visual owners received additive polish without new
particle, light, Beam, Motor6D, collision, or remote-event families.

- **Showtime holograms:** the existing six-Part performers interpolate
  `CFrame` poses across dance changes using the established quality-tier
  update cadence. Switching Reduced Motion snaps to a quiet still pose;
  hiding/revealing the stage invalidates old interpolation history.
- **AI ground cues:** when an Android client resumes after a rendering gap
  above 0.30 seconds, `bot-motion-polish` resets velocity baselines and
  expired cue styling instead of fabricating a sprint, skid, or pivot. Its
  server-owned AI navigation, animation tracks and original trail survive.
- **Impact reaction fairness:** the local survivor retains priority, then
  nearby human and AI survivors compete equally for the existing Medium 2 /
  High 3 shock-reaction actor limits. Inactive, eliminated and streamed-out
  rigs remain ineligible, with the same cooldowns and Beam cap.
- **Character beams:** existing Dodge/Shock/Landing Beam instances now have
  a four-stop colour gradient and a sharpened-to-soft opacity envelope,
  instead of plain two-stop neon. The existing per-stroke Debris cleanup
  and 12 concurrent-Beam cap are unchanged.

**Physical acceptance needed:**
1. Film Showtime robot/shuffle/orbit/wave transitions and two holograms
   at 30/60 FPS; confirm silhouettes never pop or appear detached from
   the head and limb detailing. Toggle Reduced Motion and repeat.
2. On Android, background/resume mid-bot sprint, mid-pivot, and during a
   frozen dance pose. Confirm no false ground effects, ghost trails or
   catch-up jumps. Check Low, Medium and High.
3. In Studio with one human and three AI, fire Meteors/Bombs near bots;
   verify nearby bot and human pressure ribbons are coherent and stay
   readable against warning radii. With several human players present,
   verify visible near-camera bots are not starved by iteration order.
4. Run successive rounds/respawns/StreamingEnabled transitions and
   capture live Parts/Lights/Effects budgets; compare device FPS,
   thermals and GPU overdraw before assigning any visual-quality rating.

The reported quality target remains **at least 9/10 against premium
reference footage**; these commits are implementation evidence, not a
certified rendered-art score.

## Four-map hero finish — 14 October 2026 (unreleased)

The existing `ArenaSignatureKit` now constructs **two extra machined
signature details on Medium, four on High, and none on Low** without new
light sources, sounds, particles, or external asset IDs. The new optical
baffles (Classic), elevator guide shoes/rail stops (Towers), traffic
switch fins (Crossroads) and containment petals (Orbital) have materially
distinct 3D silhouettes. The moving Towers guide shoes share the cabin's
existing animation timebase. The existing foundation emissive plate
breathes very slowly; it is static in ReduceMotion.

The arena controller now integrates a bounded **0.25-second maximum
per visual update**, rather than feeding arbitrary device uptime to
animated monuments. This avoids large catch-up jumps after an Android
suspension and starts a new round/graphics reconstruction from an authored
rest pose. It does not affect player/bot motion, hazard timing or physics.

**Physical art acceptance:**
- Capture wide and close views of the four signatures in Low, Medium
  and High, with hazard markers visible. Verify no misleading safe
  paths or neon dominance, and check the original map silhouettes.
- In Towers, verify both carriage shoes stay attached to the visual
  cabin throughout the full up/down travel. Inspect the upper rail
  stops for intersecting geometry.
- In Classic/Crossroads/Orbital, inspect newly sculpted WedgeParts
  from front/side and in darkness. Check glass sorting and minimum
  30 FPS on the target Android phone during Double Chaos.
- Toggle ReduceMotion while active; confirm no pulsing, safe rest
  pose and graceful restart. Suspend/resume Android and change maps
  rapidly; no fast-forward jump, duplicate art or runtime warnings.
- Record candidate SHA, Studio/client version, before/after screenshots,
  FPS, memory, local Part/Light/Effect counts and reviewer notes.

**9/10 gate:** do not award an AAA-quality rating based on new geometry,
code compilation, or engine checks alone. Require a side-by-side
comparison with polished reference experiences and at least one independent
art/animation review using captured footage.

## Weighted R6/R15 landing — motion finishing candidate (14 October 2026)

The existing `body-feel.client.lua` owner now layers a short, damped
compression/rebound pair over the original landing flinch, based on the
avatar's actual downward speed before the Humanoid landing transition.
Torso, root, hips and arm counterbalance share this envelope. The shared
`LocomotionDynamics.landingRecovery` function computes the two bounded
normalized weights; no new AnimationIds, Motor6Ds, physics forces,
camera shakes, GPU particles, lights, or server mutations are added.

Graphics tier scaling, ReduceMotion dampening, existing R6 amplitude
limits, and Showtime's action-track blend remain in control. Render
integration is limited to 1/15 s of visual time per frame after Android
suspension. Frame gaps above 0.30 s discard false acceleration, braking
and turning impulses (and associated foot-ground VFX) instead of reacting
to a stale movement sample.

**Visual acceptance required, not yet performed:**
- Compare neutral jump/landing against falls that exceed the existing
  20-studs/s threshold. Review anticipation, compression, rebound,
  arm counterbalance, feet clearance, and absence of joint snapping.
- Record R6 and R15 in Studio at 30 and 60 FPS, including sprint-to-jump,
  quick pivots, hard stops, Speed Surge and Low Gravity.
- Dance/emote immediately upon landing and confirm Showtime Action
  tracks continue to override additive C0 offsets. Test simultaneous
  explosion reactions and rapid respawns.
- Repeat with Low, Medium, High and ReduceMotion on Android; switch
  settings while falling, return from background after 1+ second, then
  inspect whether false ground scuffs or sudden angular poses appear.
- Compare CPU/frame timing and character Motor6D count before/after.
  No claim of 9/10 animation quality or measured FPS improvement without
  native capture and independent visual review.

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

## AI survivor ribbons — camera visibility and mobile update cost

Human and AI cosmetic trails now share `VisualViewportRules.contains`.
Eligible AI ribbons and the brief bot ground accents are culled outside a
padded camera viewport (10% entry margin, 18% retained margin). The existing
High/Medium distance/speed/phase gates remain intact, while Low and
ReduceMotion always suppress these optional effects. A zero-size or
unavailable camera keeps the previous distance-based behavior.

Bot trail lifetime is applied only when its target value changes or a trail
is replaced; `Enabled` is written only on state changes. Spectating
clients calculate distance from the **camera**, not an eliminated lobby
avatar. No new Trails, lights, particles, raycasts or RenderStepped loops
are introduced, and existing AI server movement/physics are unchanged.

**Regression coverage:** shared viewport alias and in/out/behind/edge
bounds, hysteresis, startup fallback, Low, ReduceMotion and distance rules.
**Physical QA pending:** camera-follow spectating, rotating beside AI rigs,
Streamed AI replacement, 30-minute Android memory/FPS/overdraw, and
Low/Medium/High transitions on a densely populated round. No real-device
performance improvement is claimed from code review or CI alone.

## Disaster VFX — mobile decorative cadence and attached-effect accounting

Two **cosmetic** disaster animation owners now use the shared decorative
cadence instead of updating all quality tiers at 30 Hz: High 30 Hz,
Medium 24 Hz, Low 15 Hz, and ReduceMotion at most 12 Hz. This changes only
optional lava/freeze and arena shrink/blackout ornamentation, not the
server-owned disaster timing, damage, hitboxes or authoritative warnings.
No new parts, materials, emitters, shaders, paid assets or lights.

The live `VisualBudgetRules.collect` audit also now counts client-authored
`LavaGlowLocal` surface lights and `LavaEmbers`/`FreezeMist` particle
emitters attached to server-owned `RoundLava`/`FreezeWarning` parts. It
does not count those server parts as decorative geometry, and ignores other
server-authored effects. This **improves measurement** of peak GPU load;
collection is not an automatic emitter-kill mechanism or a measured FPS gain.

**Engine regression coverage:** tier/reduced-motion cadence, exact
attachment names and classes, exclusion of authoritative hazards, plus
cleanup of counted effects. **Physical acceptance pending:** Freeze + Lava
Double Chaos stress at Low/Medium/High/ReduceMotion, warning legibility,
Android FPS/GPU/temperature, and repeated map changes and 30-minute soaks.

## CI regression: viewport source-path compatibility

The core_a engine failure at `83f1b5e` was traced to an unguarded
`script.Parent` import in pure `CharacterMotionTrailRules` under Lest.
Human and bot client controllers now both import `VisualViewportRules`
directly; `CharacterMotionTrailRules` stays dependency-free for source-path
engine tests. Existing 10%/18% viewport margins and Low/Medium/High,
ReduceMotion, camera depth and GPU budgets are unchanged. Engine specs
continue testing camera edges and load the human policy without a Roblox
ModuleScript instance. Exact-head Open Cloud validation remains required.

## Lava cosmetic VFX reuse and immediate ReduceMotion policy

Graphics-tier and ReduceMotion switches now reuse an intact lava overlay,
ember emitter and SurfaceLight, changing visual properties in place
instead of destroying/recreating GPU instances. Missing children or
a replacement lava host still trigger full reconstruction. Optional
freeze mist begins immediately with the correct tier rate, including
zero on ReduceMotion, instead of emitting before the first decorative
update. Unchanged particle rates are no longer rewritten every tick.

**Engine regression coverage:** intact/replaced/destroyed lava hosts and
children, scaled emission rates, reduced-motion freeze silence. This is
purely cosmetic: server damage, warnings, phase timing, collisions and
Low/Medium/High visual caps are preserved. Device QA is still needed
for rapid setting switches, respawn/map rotations, Double Chaos and
30-minute Android GPU/FPS/memory stability.

## Lava/frost VFX attachment lifecycle hardening

The reusable lava state now verifies its heat attachment belongs to the
active `RoundLava`, the ember emitter belongs to that attachment, and the
SurfaceLight belongs to the same lava host. Detached cosmetic instances
trigger self-repair rather than being silently treated as valid.
Freeze warning effects similarly check the mist/attachment and every
glass wedge on each decorative update. Missing children are repaired;
intact same-count rings can update without reallocating crystals or mist.
Changing profile to a different crystal count still rebuilds the bounded
2/4/6/8-piece ring; no server-owned warning, hitbox or damage changes.
Detached descendants are destroyed when clearing the client effect.

Engine regressions cover detached lava/freeze attachments, missing wedges
and survivor lifetime rules. Mobile QA remains required for rapid tier
switching, streamed warning hosts and Double Chaos soak / FPS measurements.

## Custom 3D catastrophe climax silhouettes: lava and meteors

Two more catastrophe climax effects have their own authored, procedural
3D geometry rather than identical neon bars. **Rising Lava** grows angled
volcanic fins outward and upward from the floor, with asymmetric pitch.
**Meteors** use inward-descending metallic spearhead wedges, creating a
different readable silhouette without large opaque screen overlays.
Both inherit the arena's full pitched/rotated `Base.CFrame`.

Each climax retains the existing **Low 2 / Medium 4 / High 6** part budget.
ReduceMotion uses a single short-lived, nearly static translucent wedge.
All pieces are locally anchored, noncolliding, non-queryable, unshadowed,
and cleaned by Debris; there are no new emitters, textures, lights,
paid assets, hitboxes, sounds, or server-controlled movement changes.
Existing named disaster warning geometry and timing remain unchanged.

**Engine regression:** recipe validity/determinism across three stages,
three tiers and both shapes, exact piece counts, stage-specific movement,
pitched deck alignment, reduced-motion placement, collision/shadow checks,
and rejection of malformed data. **Physical QA required:** compare
Low/Medium/High lava and meteor shapes, floor readability under Double
Chaos, camera angles, screenshots and GPU/FPS/thermal Android soak.
Roblox Cloud engine tests do not substitute for device profiling.

## Tornado spiral sculpture and stale-climax suppression

Tornado climax presentation now uses bespoke helix-like, inward-spiraling
WedgePart fins that lift through the arena-local frame, replacing generic
world-axis strips. It matches the shared climax kit's **2 Low / 4 Medium /
6 High** part cap (down from 3/5/7), with **one** static-leaning temporary
fin for ReduceMotion. No physical collision, shadows, new particles, paid
assets, or extra lighting. The server-owned tornado behavior is untouched.

Scheduled local climax effects also check that the current intensity
stage, round generation, and arena base still match before displaying.
Superseded pending bursts are dropped rather than overlapping a later
stage or a different arena. The current survivor/elimination filter remains.

Engine coverage extends the existing visual spec to Tornado recipe
determinism, geometry and deck orientation across all tiers and stages,
plus stale callback cases. Actual Studio/mobile screenshot QA, Double
Chaos fill-rate/FPS and 30-minute memory testing remain pending.

## Gravity petals and collapsing-platform fault teeth — original climax 3D

LowGravity and DisappearingPlatforms climaxes now have different, bespoke
procedural silhouettes instead of uniform unrotated neon bars:
**Gravity** creates thin anti-gravity lift petals rising and drifting
inward from the arena; **Fracture** creates angular fault wedges spreading
outward from the deck center. Both inherit the full pitched/rotated
arena `Base.CFrame` and are visually distinct from Lava, Meteors and
Tornado. High materials are restrained (Glass for gravity, Metal for
fracture); lower tiers use SmoothPlastic to avoid excessive overdraw.
All facets remain anchored, non-colliding, unshadowed and time-limited.

Each event now costs **2 Low / 4 Medium / 6 High WedgeParts**, rather than
the previous 3/5/8 gravity or 3/5/7 fracture bars. ReduceMotion creates
only one nearly static, short-lived facet. There are no additional
particles, lights, third-party assets, or changes to server-owned disaster
damage, collision, movement, reward mechanics or audio.

Engine regression tests cover the expanded five-type recipe family
across stage 1–3 and graphics tiers, deterministic orientation, pitched
deck positions, accessibility caps, material choices and malformed input.
Physical acceptance remains: Studio visual QA on rotated arenas,
Double Chaos mixed VFX screenshots, Android FPS/thermal profiling and
longer session stability; no unmeasured FPS gain is claimed.

## Speed Surge slipstream and Darkness eclipse sculptures

Replaced the remaining **world-axis Speed Surge bars** and
**arena-wide Darkness cylinder / light column** with two unique, bounded
procedural 3D languages. Speed creates tangential slipstream chevrons
travelling across the deck; Darkness lowers angular eclipse shutters
inward toward the center. Both use the arena's full pitched and rotated
`Base.CFrame` and leave gameplay warnings visible.
No new textures, emitters, lights, collision geometry or server effects.

Each climax uses **2 Low / 4 Medium / 6 High** short-lived WedgeParts,
compared with the former 3/5/7 Speed parts and up to 2 large Darkness
parts. ReduceMotion uses exactly **one** nearly static, translucent
wedge for either effect. Low has no Neon/Glass overdraw; all parts
remain anchored, non-colliding, non-queryable, unshadowed, and Debris-
cleaned. Obsolete cylinder/beam helper code was removed from the
climax controller.

The existing engine spec now exercises seven original geometric
silhouettes over all tiers/stages, deterministic positions, sloped
arena transforms, reduced-motion placement and invalid input,
including NaN/infinite spans. Physical QA is still required for
Double Chaos warning legibility, rotated arena camera views,
Android fill rate, thermals and 30-minute stability. No measured
performance improvement is claimed.

## Reduced-motion parity for eleven disaster climaxes

Freeze, JumpShock, Bombs and ShrinkingArena now allocate one short-lived,
translucent part under ReduceMotion, instead of two, matching the seven
other authored 3D climax types. Normal Low/Medium/High remain 2/4/6.
Fractional counts/stages, non-finite spans or horizontal arena dimensions,
and invalid quality tiers are rejected without creating parts. The arena
transforms, server-owned hazards and gameplay rules remain unchanged.
Engine tests cover reduced-motion geometry and invalid inputs. Physical
Studio and Android FPS, GPU, thermal and Double Chaos QA are still pending.

## Disaster climax lifecycle: no stale hazards after a map/phase change

The local climax presenter now clears live temporary geometry immediately
on arena replacement and when leaving the round, rather than leaving
up to ~0.7 seconds of visible debris on a different screen. It also
reconciles the authoritative disaster-ID snapshot: a removed hazard loses
its displayed stage, while a per-ID generation invalidates queued effects
even if the same hazard returns at the same intensity before the callback
executes. The full snapshot is supplied by the existing server; there are
no extra remotes, polling loops, physics, hitboxes, or server changes.

The existing 2/4/6 Low/Medium/High part counts and one-piece ReduceMotion
limit remain unchanged. Engine specs cover hazard removal, reintroduction,
duplicate/invalid IDs, absent snapshots and generation invalidation.
Physical verification remains required: rapid round-to-result transitions,
arena swap while a climax is visible, streaming delays, and Android
30-minute memory/FPS measurements. No physical test is claimed.

## Double Chaos climax-budget coordination

The local climax owner now selects **at most two distinct, recognized
disaster signatures per RoundState snapshot**. During a simultaneous pair,
the purely cosmetic High-tier climax uses the Medium mesh count (4 per
hazard instead of 6); Medium stays at 4 and Low stays at 2. The
result is a bounded **8 climax pieces for Double Chaos at High/Medium,
4 at Low, or 2 with ReduceMotion**. Ordinary solo-disaster presentation
keeps its original 2/4/6 quality levels and authored shapes. This scope
only covers one-shot climax meshes, not permanent map decoration,
particles, client lights or other VFX owners.

Duplicate and unknown disaster IDs never take a cosmetic burst slot.
The authoritative server hazards, damage, impact locations, safety
warnings, UI, round state, accessibility settings and device quality
selection remain untouched. This is a conservative peak burst-work
reduction, **not a measured Android FPS improvement**.

Engine coverage verifies snapshot filtering, stable ordering, all tier
transitions and single-versus-double budgets. Actual visual acceptance
requires High and Medium side-by-side Double Chaos captures, correct
hazard warnings, simultaneous peak GPU/thermal tests and 30-minute
Android and Studio runs.

## Global transient climax budget and selection invalidation

The Double Chaos cap is now enforced on the **live client-only
`DisasterClimaxLocal` folder across successive RoundState snapshots**,
not just the geometry emitted during one callback. Every authorized
burst reserves its 1/2/4/6 pieces, evicting oldest climax cosmetics if
necessary. The cap is **6 High / 4 Medium / 2 Low / 1 ReduceMotion**
for one hazard; **8 High or Medium / 4 Low / 2 ReduceMotion** for
Double Chaos. This budget does not include or delete persistent
arena decoration, client damage cues, authoritative warnings, or
non-climax VFX. Oldest-first eviction can shorten an earlier decorative
fade during quick changes rather than creating an overdraw spike.

Client presentation ownership is now reconciled against the **two
selected signature IDs**, not every authoritative disaster ID. A
previously selected climax whose server hazard remains active but no
longer occupies a presentation slot has its queued callback invalidated.
When the intensity drops below cosmetic climax thresholds, pending
visual bursts are also invalidated while gameplay remains unaffected.

Regression tests cover part-limit arithmetic, cumulative burst evictions,
live selection changes and invalidation of old scheduled callbacks.
Manual Studio/Android tests are still required for rapid stage changes,
replacement arena streaming, Double Chaos peak fill-rate and stable
30-minute GPU/CPU/memory measurements. No real FPS claim.

## Shared human+AI footwork VFX global cap

Both the R15 movement-feel owner and AI motion accents already use
`LocomotionGroundFx` and the common `LocomotionContactLocal` folder.
Crowded maneuvers could briefly leave multiple overlapping 2/4-part
foot-contact groups, even though each individual emission was capped.
The renderer now counts only its own authored contact groups and
evicts the **oldest entire burst**, never one side of the distinctive
acceleration, brake-groove or pivot-wedge pair. This keeps up to
**16 live pieces on High, 8 on Medium and 0 on Low** after every
new emission. Unrelated sibling folders are preserved. When the local
round ends or ReduceMotion/Low turns on, surviving footwork cosmetics
are cleared immediately. No changes to humanoid control, animation
motors, AI pathing, gameplay or authoritative danger signaling.

Regression coverage: cumulative seven-burst pressure, preservation of
unrelated nodes, whole-pair geometry retention, Medium tier downshift
and invalid tier rejection. Physical Studio and Android 30-minute
tests must still verify visual smoothness, actual FPS/overdraw and
lobby/round transitions. The live cap is a preventive limit rather
than proof of measured performance gain.

## R6/R15 local body-feel animation parity

The `body-feel.client.lua` presenter previously required an R15
Humanoid and skipped all rigid R6 avatars. It now binds to Roblox's
native R6 `HumanoidRootPart.RootJoint`, `Torso["Left Hip"]`,
`Torso["Right Hip"]`, `Torso["Left Shoulder"]`, and
`Torso["Right Shoulder"]` motors. R15 continues to use its original
Waist, lower Root, hips and shoulders. R6 pose layers inherit the
existing start, skid, pivot, jump, landing, danger reaction, ready
stance and short post-round celebration envelopes, but with **46%**
of the joint offset to account for its rigid single torso and avoid
exaggerated avatar motion. The original Motor6D.C0 values are restored
when switching characters and obsolete streamed rigs cannot override
the new one.

Only the client's decorative joint offsets change. No new animation
asset IDs, physics impulses, Animator replacements, body forces,
collision changes, or new render loops are introduced. Existing
Low/Medium/High and ReduceMotion attenuation still apply.

Engine specs cover the two rig layouts, exact joint object matching,
missing/partially streamed joints, lookalike instance rejection and
unsupported rig fallbacks. Full acceptance requires Roblox Studio
preview on genuine R6/R15 rigs (with native running/emote animations),
quick respawn or rig swaps, shoulder and hip clipping checks and real
Android game-feeling/performance profiling.

## R6 animation hotfix: missing Waist and late skeletal replication

A critical issue was found in the R6 rollout: the client used
`ipairs({waist, rootJoint, ...})` to save and restore original Motor6D
poses. Because **R6 has no Waist**, `ipairs` stopped immediately at
index one. No base C0 snapshot was saved and subsequent additive
animation updates had no valid starting pose. R15 could likewise be
affected when a particular upper joint was missing.

The body-feel owner now obtains a compact ordered list of existing
Motor6Ds using `BodyMotionRules.activeJoints`, so every present hip,
shoulder and RootJoint receives a correct original-pose snapshot and
restore. One bounded, character-scoped `DescendantAdded` connection
also repairs bindings if a Motor6D, Torso, LowerTorso, UpperTorso or
HumanoidRootPart arrives after initial rig setup. The same existing
StateChanged observer is reused, old connections are disconnected on
respawn, and delayed events check the character serial and identity.
No new frame loop, animator override, control rewrite, physics changes,
external assets or server actions.

Engine regression tests construct a native-named R6 joint model with
no Waist; assert **five** active motors, a reversible C0 pose write,
partial-streaming motor removal, and late replacement recovery.
Existing engine tests also exercise R15, ReduceMotion and bad instances.
Runtime acceptance remains pending for real Roblox R6/R15 avatars
and emotes, rapid respawns, partial character replication, restoration
on shutdown, and on-device Android motion/thermal profiling.

## Native Showtime emotes vs. R6/R15 authored body offsets

`lobby-showtime.client.lua` plays Roblox Animator Action-priority
clips, while the independently rendered body-feel layer modifies
Motor6D.C0. Until now, the two animations could overlap or pull a
dancer's shoulders and hips toward competing poses. The Showtime
owner now sets a **client-local** `ChaosShowtimeEmoteActive` attribute
on the local Player when an emote begins and clears it on manual
stop, natural track completion, humanoid movement/death or character
replacement. The marker changes only if needed; the original
AnimationTrack, clip priority, asset licensing and UI are preserved.

`BodyMotionRules.emotePoseBlend` smoothly reduces the authored
C0 offset toward the skeleton's original pose during Showtime,
then restores the full R6/R15 body-feel layer after the emote. The
blend is exponential and frame-time-aware, with bounded dt; it runs
inside the **existing** body-feel render callback. No new camera
loop, Animator polling, default emote override, input changes or
gameplay physics. Roblox's native Action animation remains the
exclusive presentation while active, without snapping C0 to its
original offset instantaneously.

Engine regression covers one-second fade-out/in at 60 FPS,
interruptions, missing dt and clamped blending. Studio QA still
needs to verify authentic R6 and R15 Dance/Shuffle/Groove/Robot/Orbit
clips, rapid switching, emote cancellation on movement, respawns,
ReduceMotion and Android screenshot/FPS/thermal profiling.

## Showtime streaming/respawn race hotfix

The lobby emote controller previously called `clearLoaded()` at the
start of asynchronous `bindHumanoid`, even before an up-to-eight-second
Humanoid replication wait. An obsolete bind coroutine could therefore
clear a newly spawned avatar's Action tracks, client-local emote
ownership attribute and motion signals.

`CharacterAdded` now increments a binding generation and clears old
tracks **before yielding**. `CharacterRemoving` also increments the
generation. The delayed bind is read-only until it confirms its
generation, live Character identity and a directly attached Humanoid;
stale callbacks exit without mutating active emotes. No additional
polling, connections, remotes, game-physics changes, animation asset
IDs or input changes.

Engine regression tests cover stale generations, obsolete avatar at
the current generation, nil values, humanoid reparenting and wrong
instance class. Physical QA remains necessary for R6/R15 respawns
during dances, delayed streaming, quick emote switches, movement
interruptions, and Android performance.

## Eight original Showtime arrival silhouettes (R6 and R15)

Previously only **Robot** and **Orbit** native emotes triggered a
personal geometric arrival motif, both using similar glass strips.
`ShowtimeSignatureKit` now gives all eight existing emotes distinct,
bounded client-only 3D choreography fragments: outward rhythm
crescents (Dance), paired skating chevrons (Shuffle), vertical bass
wave fins (Groove), stepped circuit glyphs (Robot), twisted orbit
petals (Orbit), rising victory spikes (Cheer), one-sided greeting
arcs (Wave), and low expanding laugh ripples (Laugh).

These visual flourishes follow the avatar's root frame without
moving the character, changing Animator tracks, server authority or
input. They use only anchored, non-colliding, non-queryable,
shadowless parts; no uploaded meshes, lights, additional emitters,
sound or network traffic. At most **6 transient shapes on High,
3 on Medium and 0 on Low or ReduceMotion**. Switching emotes removes
the preceding flourishes without affecting the persistent stage or
its other visual owners; Debris also cleans up each burst within
0.84 seconds. Each shape uses its own named procedural geometry
instead of colored copies of a single primitive.

Engine validation covers all eight motifs, distinct names,
angled avatar-frame placement, class/material, collision and
shadow gating, quality ceilings, rapid replacement and
preservation of unrelated stage parts. Physical Roblox Studio
and Android QA must confirm visual taste, camera visibility,
performance, clipping, genuine avatar animations and ReduceMotion.

## Showtime transient VFX: immediate accessibility cleanup

A concrete accessibility defect existed in the new eight-signature
emote pass: a burst already playing in High quality could remain on
screen after a switch to Low or ReduceMotion until its 0.84-second
Debris timeout. Additionally, the stage confetti emitter ignored
ReduceMotion even though the personal emitter did not.

`ShowtimeSignatureKit.clear/reconcile` now remove only marked
temporary signature shapes; permanent stage geometry is preserved.
Starting an emote under Low or ReduceMotion also clears the previous
burst rather than returning early with stale geometry. Stopping or
switching emotes clears the transient pieces and owned personal
confetti attachment. Enabling ReduceMotion immediately removes both
and clears existing stage particles; stage confetti emission is
explicitly gated by ReduceMotion. No new per-frame callbacks, physics
effects, server messages or asset IDs are introduced.

The engine spec checks High (6) to Medium (3) to Low (0), a
ReduceMotion transition, no stale shapes on blocked emissions, and
preservation of unrelated stage parts. Exact-head CI and physical
Android/Studio visual acceptance are separate gates; no FPS
measurement or real-device verification is claimed here.
