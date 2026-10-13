# Chaos Survival — Android physical acceptance (PR #19 stacked on PR #18)

This is a **hands-on test plan, not proof of completion**. Do not mark a check as passed unless it was observed on the actual tested PR #19 candidate based on PR #18. The existing public Roblox place may run an older published build: it cannot certify an unpublished pull request.

## Before testing

Record the exact deployed **candidate commit**, experience/place ID, phone model, Android version, graphics quality, display orientation, network type, and UTC/local test date. A preview/staging Roblox place must be explicitly linked to that commit; do not overwrite production merely to test. Enable Roblox's in-client performance statistics if the version/device supports them. Capture screenshots or a short recording of each problem and the precise phase/time.

## Minimum sessions

1. **First-time solo (15 minutes)** — join an otherwise empty server. Verify that AI survivor bots join and make the vote/ready/gameplay meaningful. Record the first three actions required to understand the objective, vote, and how to survive. Observe at least two complete rounds.
2. **Multiplayer (15 minutes)** — two or more actual clients. Test joins during voting and during an active round, elimination, next-player spectator cycling, results, return to intermission, and leaving/rejoining. Verify the camera follows the chosen survivor rather than the eliminated player's lobby avatar.
3. **Arena rotation** — observe Classic, Towers, Crossroads and Orbital. Photograph each unique landmark. Check terrain, colliders, readability, platform edges, and no leftover scenery following a map swap.
4. **Visual pressure** — attempt Double Chaos with Meteors, Bombs, Freeze and Darkness; compare Low, Medium and High VFX on the same phone. Warnings and hazards must remain clear in Low mode. Record any severe FPS drop and frame hitch.
5. **Motion and accessibility** — R15 start/stop, 180° pivot, jumping, landing, death and respawn. Turn Reduce Motion and Audio Muted on/off. Check no sustained joint deformation, doubled footsteps, reaction FX after elimination, or hidden danger warnings.
6. **Showtime/UI** — in lobby and result phases open the eight-emote panel, activate each available emote and interrupt it by walking or jumping. In a round confirm the DJ stage is not visible. Verify Settings remains tappable with the emote grid open on narrow portrait viewports. Check screen rotation if available.
7. **Long session (30 minutes)** — stay in the same server over several rounds, toggling VFX quality and Reduce Motion. Check for accumulating glow, leftover parts, repeated audio, stale countdowns, broken spectator controls, and worsening performance.

## Record by phase

| Phase | Required observation |
| --- | --- |
| Lobby | Clear first action, bots visible if alone, platform practice and social features not obstructing touch movement |
| Vote | Each disaster choice has a readable name/hint, touch-only vote works |
| Ready | Arena guidance, countdown, character inside arena, landmark visible |
| Round | Readable hazards, responsive movement, stable camera, warnings remain legible in Low |
| Elimination | No lingering character reaction arcs; spectating camera and NEXT work |
| Result | Rewards and next-round timer legible, DJ stage returns, spectator camera relinquishes control |
| Next round | No repeated previous-round UI or ghost geometry |

## Minimum evidence / fail conditions

- Record **median FPS and lowest sustained FPS** if accessible; note device and VFX tier. Target 30 FPS on modest Android devices, aim for 60 FPS on capable phones; these are QA targets, not demonstrated results.
- Record temperature/throttling, crashes, memory warnings, audio glitches, unresponsive touches, and whether performance degrades after 30 minutes.
- Treat a crash, broken control, missing hazard warning, persistent camera takeover, stuck round, or incorrect arena spawn as a **blocking failure**.
- For cosmetic defects, record expected vs observed visuals and a screenshot/timecode. Do not hide them behind an overall PASS.

## Issue report template

```text
Candidate SHA:
Place / staging ID:
Phone / Android version:
Network / graphics quality / Reduce Motion:
Session type / player count:
Arena / phase / active disaster(s):
Steps to reproduce:
Expected:
Actual:
FPS or symptoms:
Screenshot / video:
Severity: BLOCKER | MAJOR | MINOR
```

## Certification

Mark Android PASS in the Release Candidate Gate **only after** this physical checklist passes on the exact release candidate that also has Build Validation, Open Cloud Engine Tests and authenticated Studio E2E success. GitHub CI alone cannot claim physical Android FPS, usability or graphics quality.

## PR #19 Android decor replication regression

After joining a fresh server and after changing maps, wait for the streamed Arena and its Decor folder. On each of Classic, Towers, Crossroads and Orbital, inspect the original decorative neon and motivated lights at Low, Medium and High. Check that late-replicated Decor also gets the mobile brightness/tint policy, that the safety edge remains clearer than decorative Neon, and that changing quality repeatedly does not progressively dim existing lights. Test a map swap while decoration is still streaming. This is a **manual Android/Studio acceptance scenario**, not an automated FPS measurement or an observed pass.

## PR #19 Showtime geometry on rotated lobbies

In a staging build with a rotated (or slightly tilted) Lobby.Floor, verify each original holographic dancer remains on its assigned side of the physical deck and the moving ribbons stay aligned with its local axes. Walk along all four deck corners: crowd cues, marquee and spatial sound must react to participants inside the rotated deck, not to a world-axis rectangle outside it. Repeat after map swap and quality changes. Automated rule tests verify coordinate transforms; visual composition, motion comfort and Android framerate still require observation on a device.

## PR #19 — nested streaming decor regression (code-level coverage)

On Android, stream a pre-populated Model or Folder into `GeneratedMap.Arena.Decor` after the map initially loads. Verify that **nested** Neon parts and Point/Spot/SurfaceLights are dimmed immediately at Low, Medium and High; a parent-only treatment is insufficient. Change quality Low → High → Low and confirm the original light brightness is restored proportionally rather than multiplied repeatedly. Verify edge guidance remains clearer than decorative Neon, and repeat while replacing the map. The existing arena engine spec now exercises the subtree treatment and baseline cache, but actual streaming timing, visual legibility and FPS require physical Studio/Android acceptance.

## PR #19 — malformed character reaction VFX inputs (11 October 2026)

The pre-existing non-physical Dodge, Shock and Landing Beam recipes
retain their directional/curved 3D signatures, per-tier policies,
12-Beam live cap, short lifetime, no extra BaseParts and zero
camera/physics changes. The renderer now rejects NaN/infinite event
counts and intensity before creating Attachments or Beams. Direct
signature calls also reject non-finite or out-of-range ribbon indices
(only 1–3 are authored), rather than producing unbounded offsets.
Shock orientation falls back to the existing neutral local frame when
the impact/source vector contains non-finite coordinates.

The engine spec `survival-feedback.spec.luau` adds regression cases
for malformed count, strength, ribbon index and explosion vectors,
verifying zero leaked attachments on invalid bursts and unchanged
normal capped emission. These tests must still pass on the exact-head
Open Cloud workflow before the lot is considered validated. Physical
Android and Roblox Studio reviews of avatar effects, thermal behavior
and frame rate remain outstanding and are not claimed here.

## PR #19 — finite disaster feedback and Android VFX cooldown safety (11 October 2026)

The event-driven character reaction controller now rejects malformed
impact coordinates before performing world-space subtraction or consuming
the impact cooldown. A shared finite-position guard checks all three
Vector3 components and excludes coordinates outside 10 million studs.

Pure `CharacterReactionRules` also reject NaN/infinite distance, radius,
airtime and current clock values before calculating Dodge/Shock/Landing
intensity or cooldown state. A nil Shock radius retains the existing
8-stud fallback; valid per-tier budgets, near-miss behavior, explosion
direction, low graphics and ReduceMotion gating do not change. This
prevents malformed server payloads from silently occupying VFX cooldowns
or reaching cosmetic Beam properties. No new objects, loops, effects,
remotes, physics or gameplay authority are introduced.

The existing `survival-feedback.spec.luau` engine shard now checks the
invalid-input behavior alongside finite-event compatibility. Build and all
five engine shards must be verified at the exact commit before signoff.
Real Roblox Studio and Android gameplay/FPS checks are still outstanding.

## PR #19 — emission-aware character VFX cooldowns (11 October 2026)

A full shared 12-Beam visual budget, a streamed-away avatar root or
other rejected cosmetic burst can legitimately return zero newly
created Beams. Previously the Dodge, Shock and Landing controllers
reserved their cooldown **before** checking that result; a valid later
near-miss or impact could then be suppressed despite no visible
feedback having appeared.

The reaction controller now advances the respective cooldown only
after `CharacterReactionVisuals.burst` returns a positive actual
emission count. The global impact throttle is claimed only if at
least one nearby eligible participant/AI gets a Shock effect;
per-character Shock and Landing throttles similarly track real
emission. `CharacterReactionRules.cooldownAfterEmission` is a small
deterministic policy rejecting zero, negative, fractional and
non-finite counts/times. Existing global 0.18s / 0.80s / 0.95s /
1.20s cooldown durations remain unchanged for genuine effects.

This alters client-local VFX scheduling only: no damage, physics,
network traffic, game progression, new Beams, attachments, render
loops or increased visual budgets. The existing engine shard
`survival-feedback.spec.luau` tests dropped/accepted emission
behavior and follow-on cooldown readiness. The exact-head cloud
shards, Studio appearance and Android performance still require
separate validation; no FPS or physical-device claim is made.

## PR #19 — rotated arena crisis VFX and Android budget (11 October 2026)

`disaster-motion-vfx.client.lua` no longer rewrites four ShrinkingArena
perimeter CFrames and Sizes every decorative tick when the Arena.Base
has not moved. The original four noncolliding warning strips retain
their shape, position and pulse; only translucency changes per tick.
Geometry is recomputed when the base's Size or CFrame actually changes.

The Darkness corner guidance previously kept the first four spawned
beacons even if `GeneratedMap.Arena.Base` was replaced. Both four-part
effects now explicitly observe the current base, discard stale owned
parts and rebuild the correct local geometry for late replicated,
replaced or rotated arenas. The four Darkness beacons are no longer
perfectly synchronized: Medium/High use evenly offset, slow,
bounded phases so players can distinguish the arena corners without
new flashing objects. Low and ReduceMotion retain a constant visible
baseline and skip redundant color/transparency writes after mode
changes. Unlike damage warnings, these are decorative guidance cues,
and the gameplay hitboxes stay server-owned.

The new shared `DisasterMotionSceneRules.lua` centralizes the four
geometry recipes, map-replacement check, transform-change gate and
four-phase brightness envelope. The existing engine suite
`disaster-visuals.spec.luau` covers four-way rotated transforms,
nonrebuild steady state, streamed-base replacement, destroyed parts,
bounds, tier/accessibility and invalid timing inputs.

No added particle emitter, beam, light source, render loop or network
message; no collision, damage, physics, balance or monetization changes.
Acceptance still requires a physical Android pass near shrinking map
corners, frequent map changes and Darkness+ShrinkingArena, together
with Studio visual review and thermal/FPS measurement. Do not
interpret an engine green status as a visual production approval.

## PR #19 — streamed character reaction rig lifecycle (11 October 2026)

The event-driven landing VFX controller now uses
`CharacterReactionRigRegistry.lua`, a single model-scoped lifecycle
owner. It waits for both Humanoid and HumanoidRootPart without a
time-based permanent registration failure: late rig components,
including those arriving after the former 8-second deadline, can
enable the same landing feedback. Root/Humanoid replacements
disconnect the previous Humanoid.StateChanged listener and discard
stale airborne timestamps; only the active root may display an effect.
Unparented or destroyed characters, CharacterRemoving and removed AI
models explicitly release registered signals. Replaced AISurvivors
folders disconnect their ChildAdded/ChildRemoved listeners, preventing
old folders from retaining callbacks and stale bot rigs.

The existing `survival-feedback.spec.luau` engine shard now checks
partial replication, replacement of either required rig component,
repeated watch deduplication, explicit teardown, model unparenting,
streaming back, and destruction. The RoundState callback additionally
handles malformed/nil snapshots without crashing.

This is client-owned visual lifecycle only: no extra render loop,
new Beam, Animator action, physics, damage, server event or
monetization change. The full five-shard Open Cloud run and physical
Android streaming/respawn/AI movement QA must pass before signoff.

## PR #19 — material-contact FX streaming recovery (11 October 2026)

The client material-contact controller now shares
`CharacterReactionRigRegistry` with directional character reactions.
The old permanent `watched` flag and 8-second partial-rig timeout
could lose landing imprints after Humanoid/Root streaming and respawn.
Current Humanoid/Root pairs are now rebound on replacement; their old
StateChanged signals and airborne timestamps are cleared. Removing a
character, AI bot or AISurvivors folder releases listeners. A contact
imprint checks that its root is still the live model child before
raycasting, and Freefall timestamps start only in an active round.
Malformed RoundState snapshots safely fall back to waiting.

Existing tier budgets, cooldowns, collision settings, materials, audio
and server gameplay are unchanged. The shared registry engine suite
now checks partial-rig teardown and late Humanoid re-registration.
No new effects or render loops. Exact-head CI and real Roblox Studio /
Android streaming and performance checks are still required.

## PR #19 — phase-safe landings, spectator camera and frost material identity (11 October 2026)

Verify Freefall begins during a round and is followed by a landing after a normal
phase transition, result screen, spectator handoff or respawn. The old jump must
**not** replay as a new material contact or stabilization ribbon when the next
round starts. The shared rig registry now clears airborne timestamps at every
non-round RoundState while preserving the existing low-cost rig listeners.

With an eliminated player whose root remains far from the arena, spectate a live
player in third person. Material landing contact distance is now based on the
spectator camera, not the dead avatar; active players continue avatar-centered
sampling only while the camera actually follows their own Humanoid/root.
Compare crystal/ice and slate/concrete landings: frost splinters use a curled
transparent-glass travel path, while slate uses short angular stone fragments.
The original one/six-piece Low/High cap, cooldown, collision flags and fast
Debris cleanup are unchanged. Malformed NaN/Infinity/fractional signatures and
non-Material enums are rejected before allocating Instances.

The engine suites `ground-contact-rules.spec.luau` and
`survival-feedback.spec.luau` cover deterministic camera choice, crystal
silhouette differentiation, malformed input rejection and registry persistence
across phase cleanup. **Physical** Studio/Android checks remain essential:
observe spectator transitions, ice visibility on small screens, Reduce Motion,
Low tier, map streaming and thermal/FPS behavior. No device FPS is inferred
from CI success.

## PR #19 — resilient human momentum trails after streamed character swap (11 October 2026)

Human sprint ribbons previously stopped listening after eight seconds
when a character had not yet streamed both Humanoid and HumanoidRootPart.
They also lost their native StateChanged subscription when a root
streamed out, which could leave a resumed player with no motion trail.
The new model-scoped CharacterMotionTrailRegistry uses ChildAdded,
ChildRemoved, AncestryChanged and Destroying events to keep an
incomplete but live avatar registered until its rig returns.
On a root or Humanoid replacement it disables the obsolete trail,
disconnects old StateChanged signals, resets airborne/style caches,
and restores its original tier/distance-limited selection behavior.
It also unsubscribes on CharacterRemoving and PlayerRemoving.

The existing body-motion-rules.spec.luau now exercises delayed
streaming, root/humanoid replacement, disabled obsolete effects,
deduplication and explicit cleanup. This adds no new render loop,
Trail budget, physics, network requests or new GPU geometry.
Still requires full exact-head Open Cloud plus physical Android
streaming and Studio visual testing before release acceptance.

## PR #19 — client avatar polish lifecycle and zero-light allocation (11 October 2026)

Android Low / Reduce Motion acceptance: join a crowded game with human
contestants and AI, respawn and spectate, then switch Low → High → Low.
Character outlines must remain readable but **no new decorative PointLights**
are constructed for avatars when their desired brightness is zero. Existing
ones are switched off on the same tier or accessibility change. During an
active High round, living contestants can regain restrained optional light.
The base Roblox character lighting, Animator, collisions and gameplay stay
unchanged.

Character polish now has model-owned listeners for accent, AI identity and
rig changes, disconnects them after CharacterRemoving, AI removal, streaming
out or destruction, and cleans up only its own named local Highlight and
PointLight instances. An incomplete Humanoid can arrive later without a
fixed timeout. Replacement bot folders release old model and folder
listeners. Malformed RoundState snapshots safely return to waiting. Existing
engine tests exercise listener counts, late root creation/removal, rewatch,
stop, refresh and no-light rules.

Real Android screenshots, warnings, memory, GPU activity and FPS have **not**
been measured by the automated suites; check those on hardware before release.

## PR #19 — authored sprint-ribbon gamefeel (11 October 2026)

The single existing human Trail has three velocity-responsive, bounded
silhouettes: Flow (thin/quick), Drive (steady), Surge (slightly wider
and brighter). Entry/exit velocity thresholds are deliberately
different to avoid flicker. Existing decorative speed sampling is
reused; the client only writes WidthScale, Lifetime, LightEmission
and Transparency when the band or graphics tier actually changes,
not at every visual tick. Rig replacement resets cached band/style.

High-tier maximum lifetime is under 0.15 seconds and width scale under
0.37; Medium is subtler. Low, ReduceMotion, final-rush, spectator,
camera-culling and 4/8 remote-human Trail caps remain unchanged.
No new Trail, Beam, Attachment, particle, light or render loop is
introduced, and original cosmetic colors are preserved. The event
handler also tolerates malformed RoundState payloads.

The existing character-polish engine suite checks band hysteresis,
bounded tier recipes, non-finite speed inputs and real Trail styling
without additional instances. Visual/gamefeel quality and physical
Android GPU costs remain unmeasured until device and Studio QA.

## PR #19 — authored AI movement ribbon gestures (11 October 2026)

The pre-existing server-owned AISurvivorCosmeticTrail now receives
three brief original *shapes*, not only color changes, during
AI floor-contact moments. Launch extends a thin thrust filament,
Skid briefly spreads a low friction fan, and Pivot shows a tightly
banked ribbon. Static tier-scoped presets (High/Medium) adjust the
same Trail's WidthScale, emission and sub-0.15s lifetime only when
a successful existing cue starts/ends or quality changes. The native
Trail's original WidthScale, emission, color and lifetime are cached
and restored on normal return and bot removal; its model, physics,
Animator, movement and authoritative AI are untouched. No new
Trail, MeshPart, ParticleEmitter or update loop is introduced.

The engine body-motion shard checks uniqueness, expected dimensions,
runtime Trail properties, low-tier gating, zero extra instances and
nonfinite velocity/distance/time rejection. Client RoundState also
handles malformed snapshots. Android visual quality, timing and
GPU overdraw still need real-device and Studio assessment.

## PR #19 — malformed impact VFX payload isolation (11 October 2026)

The client impact event rejects absent/non-table payloads, invalid Vector3
coordinates (NaN, infinities, excessive distance), and invalid Color3
channels before sampling a surface, allocating temporary 3D pieces, or
advancing the local burst budget. ImpactSetpiece validates its own inputs
as a second safety boundary. Missing or invalid radius values fall back
to 8 studs; valid numbers still follow the original 1..40 clamp.

The existing `disaster-visuals.spec.luau` cloud suite now checks malformed
positions, colors and radii, pcall-no-throw, no allocations and normal
radius limits. No new emitters, lights, beams, hitboxes, render loops,
damage, camera motion or monetization changes were added. Actual Roblox
Studio visuals and physical Android thermal/FPS checks remain required.

## PR #19 — Open Cloud gameplay exact-head regression repair (11 October 2026)

The isolated `gameplay` Open Cloud job exposed a malformed-input exception
in `ImpactSetpiece.spawn`: module lookup of `Shared.ImpactSetpieceRules`
ran before rejecting payloads without position/color. The renderer now checks
required types first, then retains the full finite-value validation and
original tiers/shape budgets from the shared rules. The existing gameplay
spec exercises three incomplete meteor/bomb events via `pcall` without
rules injection, verifying no exception and no allocated 3D parts.
The earlier failed exact-head run was #38163970237 (193/194 gameplay tests,
four other shards green). A new complete exact-head CI is required before
signoff; studio and Android FPS/visual checks are still unperformed.

## PR #19 — non-generic impact fracture silhouettes (11 October 2026)

Meteor impacts use deterministically staggered glass wedge wings with
alternating 3D banks and different shard lengths; bombs use shorter
oblique/fanned pressure strokes and alternating small banks. Each impact
retains the existing High/Medium/Low and ReduceMotion budgets, identical
WedgePart/Part counts, collision-free local animation and Debris lifetimes.
No geometry, light, sound or particle budget increase was made. Invalid
fragment/finish indices, nonfinite counts and unknown types no longer produce
synthetic geometry. The engine `disaster-visuals.spec.luau` checks distinct
and finite transforms, deterministic repeats, per-tier counts and invalid
inputs. Studio/Android must inspect actual appearance and GPU overdraw.

## PR #19 — material-true impact scars and guarded residue lifecycle (11 October 2026)

The persistent local disaster residue path now shares the finite payload
validation used by the transient Meteor/Bomb VFX: NaN/Infinity positions,
invalid colors and excessive coordinates cannot reach the arena raycast or
crater geometry. Radius falls back to 8 and retains its 2..40 scar clamp.
Malformed RoundState payloads no longer crash the residue controller.
WarningDuration attributes are bounded to 0.1..8 seconds, with a 0.7s
fallback for nonfinite values, avoiding invalid scheduled tasks.

The same 1/4/6 material-aware scar pieces per tier acquire deterministic
Ice branches, shallow metal scores and shorter dusty cuts without any new
parts, lights, particles, render loops or server changes. Existing engine
residue tests now cover all material distinctions and reject NaN/Infinity
radii, invalid indices and malformed warning durations. Actual Studio and
Android screenshots, GPU overdraw, temperatures and FPS remain unmeasured.

## PR #19 — directional Phase Dash shockwave and listener cleanup (11 October 2026)

The client Phase Dash now uses authored forward-biased swept shockwave
facets oriented to the avatar's horizontal LookVector instead of generic
world-aligned round bars. Alternating bevel-like banks and shorter
secondary violet strokes retain the exact existing 5/7/10 parts per ring
(Low/Medium/High), existing High-only second ring, ReduceMotion gating,
collision-free local tween lifecycle and no new particles, lights or loops.

Remote player CharacterAdded, CharacterRemoving and character attribute
listeners are owned by PhaseDashObserverRegistry and are explicitly
disconnected on respawn or player departure. No persistent connection array
may grow as players join/leave. Roblox engine movement-safety tests verify
single subscriptions, detached stale characters, cleanup after leave,
invalid facet indices, deterministic geometry and unchanged tier part caps.
Studio screenshots and physical Android FPS/thermal tests remain required.

## PR #19 — material-reactive launch, skid and pivot contact art (11 October 2026)

Human and AI grounded impulse effects now reuse the *existing* arena raycast
material and sampled floor color to tint their original three distinct
footwork silhouettes (glacial cool scratches, metallic shears, dust-ground
gouges). Each movement still allocates 2/4 parts on Medium/High only, within
the unchanged 8/16 scene-wide piece cap; Low/ReduceMotion remains gated by
the existing motion owners. No textures, emitters, lights or new update loops
are introduced. A slightly staggered secondary skid angle further breaks
repeating straight bars, without altering physics, hit detection or timing.

The existing body-motion engine suite now checks deterministic per-material
color differences, unchanged part caps, no collisions and rejection of
NaN/Infinity position, strength and scene-budget values before geometry.
Roblox Studio appearance and physical Android thermal/FPS costs remain
unmeasured.

## PR #19 — finite Phase Dash server/client numerical contract (11 October 2026)

The shared PhaseDashRules now rejects nonfinite health/timestamps and
unbounded or nonfinite motion vectors. An invalid movement direction safely
falls back to a valid avatar facing vector or neutral forward; corrupted
current velocity is replaced before the unchanged 44-stud horizontal and
-52..48 vertical speed clamps. The client also normalizes replicated
PhaseDashHeading through these shared rules, and uses a finite-only
cooldown-remaining helper to avoid NaN/Infinity HUD countdowns.

The existing movement-safety engine tests cover NaN, both infinities,
excessive coordinates, normal strafing direction and valid cooldown
arithmetic. No dash power, duration, cooldown, VFX object count,
monetization or server-authoritative movement conditions were changed.
Roblox Studio multiplayer replication and physical Android playtesting
remain required.

## PR #19 — grounded Dash feedback and first-use onboarding (11 October 2026)

Phase Dash keeps its existing mobile/desktop button visible while the living
round participant is airborne, but now shows **ATTERRIS / LAND** and ignores
an impossible input before contacting the server. Its local RootPart validity
check matches the authoritative server preconditions; the server still owns
all movement, cooldown and security decisions. The single first-use hint is
triggered only when the player is grounded, spawned and off cooldown, rather
than disappearing during a round-state transition. No new UI, VFX or recurring
tasks are created.

Android/Studio acceptance: enter round with a delayed spawn; ensure the hint
appears upon the first genuinely available dash. Jump and tap the button or
press Q: expect no dash and a grey landing cue. Land: expect the green DASH
cue; dash: expect exactly one server-authored impulse and a 9-second
cooldown. Repeat after elimination, respawn, spectator mode and with
ReduceMotion. Real-device input timing and visual legibility are not yet
certified.

## PR #19 — visible practice-pad effects and safe lobby wayfinding (11 October 2026)

The practice pad ParticleEmitter now uses an Attachment parented directly to
the actual BasePart, rather than a Folder that could lose its world-space
emission transform. A dedicated testable client kit owns the temporary
Folder, direct Attachment, emitter and Highlight as one cleanup bundle.
Respawn/removal/streaming cleanup destroys both attachment and folder.
Existing visual parameters and particle limits are unchanged.

ReduceMotion now sets the practice emitter rate to zero and suppresses
burst Emit() calls, while retaining static highlight/readability. Toggling
the setting refreshes existing pads without allocating new emitters.
Malformed RoundState events no longer crash lobby-wayfinding display.
The engine lobby-activities suite checks real parentage, cleanup,
no duplicate pad bundles, and accessibility particle rates. A live
Roblox Studio and Android visual review remains necessary.

## PR #19 — Roblox engine Color3 precision regression (11 October 2026)

Open Cloud run 38171735611 passed gameplay, matrix, core_b1 and core_b2,
but core_a failed one out of 241 assertions in the existing body-motion
suite. It compared an unquantized Color3:Lerp recipe against a BasePart.Color
value rounded to Roblox's stored channel precision (a difference under
one 8-bit channel step). The existing test now tolerates at most one
1/255 channel step plus numerical epsilon, while still checking the
actual color, accent variation, part cap and collision-free geometry.
No production color, shader, VFX budget, movement or gameplay code changed.
Re-run all engine shards on the updated exact commit before release.

## PR #19 — Open Cloud core_a color quantization fix / reduced-motion feedback

The BasePart.Color quantization regression was fixed in a preceding
concurrent commit (654d73a5); this change builds on that fix.

The lobby practice success overlay now uses a static, readable message
instead of enter/exit scale and opacity tweens while ReduceMotion is
enabled. The feedback still expires after 0.65 seconds and does not add
new rendering loops. Engine lobby tests additionally verify that the
particle anchor follows the actual pad after it moves. Android screenshots
and accessibility testing remain outstanding.

## PR #19 — localized boost confirmation and interruptible practice feedback

The lobby success overlay now uses the central CoreLocalization catalog:
"BOOST ACTIVATED" for English and "BOOST ACTIVÉ" for French, tested for
en-US, fr-FR and fr-CA. It no longer leaves this first-time play cue in
English for French clients.

Repeated practice boosts cancel previously active Tween instances before
starting a fresh, bounded confirmation, so rapid success notifications
cannot leave an old fade overriding the new text. Enabling ReduceMotion
while a confirmation is already animating cancels that motion immediately
and replaces it with the existing static 0.65s cue. There is no new
render loop, replicated remote, emitter, 3D instance, or server change.

Check in Roblox Studio and on a physical Android device for localized
layout, repeated pad uses, reduced-motion changes during animations,
and touch target/readability at small viewport sizes.

## PR #19 — late attribute replication on streamed practice pads

Some mobile sessions stream in a lobby BasePart before the
LobbyPracticePad marker attribute. Previously, the one-time scan and
DescendantAdded callback ignored it permanently when the marker arrived
later, so the pad was usable on the server but had no local particles,
highlight or practice visual confirmation.

A dedicated LobbyPracticePadRegistry now monitors marker changes only for
BaseParts inside GeneratedMap/Lobby/Activities. It attaches once when
the marker becomes true, removes visual descendants when it becomes false,
and disconnects the subscription as the pad or map streams out. A newly
streamed instance can then attach normally, without leaks, a poll loop,
extra gameplay remotes or altered server authority.

Roblox engine lobby-activities tests cover late marker arrival, duplicate
watch protection, marker false→true changes, cleanup, disconnection,
and rejecting unrelated map Parts. Device verification should stream the
lobby in/out at Low quality and check that all four pads regain their
individual particle/Highlight styling.

## PR #19 — cosmetic-quality RoundState input guard (11 October 2026)

The character/bot cosmetic quality controller now checks that incoming
RoundState data is a table before accessing `phase` and `finalRush`.
Missing, invalid or unexpected snapshots safely reset the local final-rush
cosmetic throttle instead of raising a Lua event-handler exception.
Legitimate round snapshots, quality tier rates, trail lifetimes, motion
accessibility and server gameplay decisions are unchanged. No new FX or
loops are introduced.

Studio/Android follow-up: reconnect during a round, join late and respawn
while final rush toggles; check cosmetic Trails, aura emitters and highlights
stay stable and do not leak. Build and real Roblox Open Cloud checks are
required on the exact new commit; a physical Android test remains pending.

## PR #19 — hero-landmark RoundState resilience (11 October 2026)

The existing arena-hero-motion RoundState listener now treats missing and
non-table snapshots as an idle round state rather than indexing a string or
number and raising a Lua error. A safe fallback clears active disaster
reactions and final-rush intensity and reapplies the existing reduced-motion
still pose when relevant. Valid phase snapshots, four landmark identities,
animation signatures, quality tier budgets and server authority are not
changed. This is a client-only input guard with zero new Instances/tasks.

Roblox Studio follow-up: join late during a round, reconnect, rotate arenas,
switch ReduceMotion on/off and verify that returning to READY/ROUND restores
normal animated landmarks. Full exact-head automated checks and physical
Android observation remain required before release.

## PR #19 — localized practice-pad world signs (11 October 2026)

The server-created BillboardGui above each PracticeBoostPad used a fixed
English "PRACTICE BOOST" caption, despite central EN/FR localization
being available. The client now applies the existing PRACTICE_BOOST string
("TRY BOOST" in English; "ESSAIE LE BOOST" in French) locally. A
per-pad DescendantAdded subscription also catches the label if it
replicates after the pad/marker on Android or StreamingEnabled.

The subscription is released in LobbyPracticeVisualKit.destroy when
the pad streams out, so no render loop or long-lived character listener
is added. Roblox engine tests cover absent, late-arriving and existing
BillboardGui/TextLabel cases, along with both text variants. Gameplay,
the server-owned sign and the three-dimensional visual budget do not
change. Verify French text width/legibility at small mobile viewports.

## PR #19 — original 3D practice-vector glyphs (11 October 2026)

Four otherwise plain boost pads now carry small sculpted directional
chevrons built entirely by a reusable client-only LobbyPracticeGlyphKit.
The strokes point toward the lobby center, exactly matching the current
four server-authoritative inward boost impulses. Two mirrored shallow
Neon bevels compose one arrow. High shows three offset arrows (6 Parts
per pad / 24 total), Medium shows two (4 / 16), and Low shows one
(2 / 8). All are anchored, noncolliding, nontouching, nonquerying, and
cast no shadows. The glyphs remain static with ReduceMotion, introduce
no animations, lights, emitters or extra update loop, and are rebuilt
only when the quality tier changes.

The geometry is owned by each pad's already-audited PracticePadPolishLocal
folder, so existing distance LOD automatically hides/restores it and
streaming cleanup destroys it. Added engine tests check inward heading
for all four pads, distinct tier budgets, spatial bounds, disabled
physics, rejection of invalid input, and inclusion in the device VFX
budget telemetry. Client Android/Studio visual, frame-time and heat
checks are still needed; geometry was not physically playtested.

## PR #19 — register nested vector glyphs in visual audits

The first Build Validation run for the practice-chevron feature failed
on the persistent Local-folder coverage audit: the newly-created nested
PracticeVectorGlyphLocal folder was absent from VisualBudgetRules.LocalFolders.
It is now registered explicitly. The existing marked-pad telemetry collector
already counts its child Parts through PracticePadPolishLocal; this registry
addition merely satisfies whole-repo coverage and does not introduce a
second live counting path or increase graphics budgets. A registry
regression assertion was added to the visual-budget engine tests.

## PR #19 — stable decorative avatar light ownership (11 October 2026)

The avatar polish client now delegates optional PointLight ownership to a
single small client module. On repeated round/quality/rig refreshes, an
already-enabled selected light stays enabled (no redundant off/on cycle).
Changing the preferred torso disables the previously selected light and
reuses the new torso's existing light if available. Low, ReduceMotion,
inactive rounds and missing Humanoids allocate **zero** additional lights;
previously allocated lights are disabled, not multiplied. All light values
remain determined by the existing CharacterPolishRules tier policy.

The core_a character polish engine spec tests actual PointLight instance
reuse, torso handoff, disabled/reenabled states, zero-light policy,
color/range changes and malformed brightness. No GPU light budget was
increased. This is a code-level optimization, **not** a measured Android
FPS, GPU, power or thermal improvement; physical profiling is still needed.

## PR #19 — reduced-motion Phase Dash silhouette budget (12 October 2026)

The original directional Phase Dash pressure blades retain their normal
5/7/10-facet Low/Medium/High first-ring identities. ReduceMotion now
keeps a brief, readable first-ring cue with 3/4/5 facets instead of
5/7/10, respectively. The High-tier secondary ring and every dash
ribbon were already disabled under ReduceMotion and remain disabled.
No server movement, cooldown, hitbox, audio or client input behavior is
changed. Existing normal-mode art geometry and effect lifetimes remain
unchanged. The movement-safety engine spec verifies the reduced counts,
valid directional facet descriptors and unchanged normal counts.

This reduces per-dash client Part/Tween creation under ReduceMotion; it
is not a measured FPS, GPU, battery or thermal result. Confirm on an
Android device that the cue is readable without visual discomfort.

## PR #19 — vector-paint transform following for moving pads (12 October 2026)

The original client-only 3D chevrons were positioned once with anchored
world-space CFrames. If a generated map or its lobby pads were translated
or rotated after cosmetics were created, the painted arrows could be left
behind while their particle Attachment correctly followed the pad.

The LobbyPracticeGlyphKit now attaches one property-change listener to a
pad's CFrame for the existing 2/4/6 anchored local motif Parts. Each
stroke's original pad-relative CFrame is stored in memory and restored
against the new pad transform when needed. This preserves the authored
shapes and their exact mobile tier limits without adding RenderStepped,
Heartbeat, unanchored physics or GPU effects.

Listeners disconnect on VfxQualityTier rebuild and on streaming/removal
through the existing bundle destructor; engine lobby-activities tests verify
translation, rotation, collision-free anchored strokes and disconnection.
The renderer still requires physical Android and Roblox Studio observation.

## PR #19 — complete client character/bot visual accounting (12 October 2026)

The local character-polish controller attaches a Highlight directly to
each human/solo-bot Model and a PointLight to its rig BasePart. The
existing VisualBudgetRules.collect(root) counted top-level local folders,
selected hazard effects, and nested lobby pads, but entirely missed these
live avatar cosmetics. This understated GPU-effect/light counts and could
hide mobile-tier budget overruns in a crowded or bot-populated server.

The visual collector now includes distinctly named
ChaosCharacterPolishHighlight / ChaosCharacterPolishLight Instances
on immediate player-character models and the immediate models in the
workspace.AISurvivors folder. It excludes physical rig geometry and
unrelated lights/highlights, does not traverse the entire map, and counts
disabled or duplicate allocated lights so the metric reflects resident
client allocations. The existing mobile budget caps are unchanged.

Engine visual-budget tests check one human plus two bots (3 additional
Highlights and 3 additional lights), legitimate removals, disabled
light accounting, duplicate allocated lights, and excluding unrelated
server-owned visuals. This changes telemetry, not actual renderer load.
Test GPU/CPU frame times and memory in Roblox Studio/Android before
claiming a performance improvement.

## PR #19 — reuse avatar lighting through rig streaming (12 October 2026)

The previous client-only CharacterPolishLightKit allocated another
ChaosCharacterPolishLight when UpperTorso streamed in after the
HumanoidRootPart, then kept the older light disabled on the root.
Repeated model priority shifts could multiply resident PointLights.

The kit now re-parents a previously allocated managed PointLight to the
currently preferred rig part rather than allocating a duplicate. It
also destroys existing excess managed PointLights on refresh, including
during Low/ReduceMotion; it preserves one disabled reusable light
when glow is off to avoid churn on the next promotion. Unrelated lights
and all server-owned geometry are untouched. This can reduce resident
local lights without changing accent, brightness, range, outline or
gameplay/physics behavior. A streaming-out detached torso still needs
the normal rig-removal lifecycle; no per-frame listeners are added.

Core engine regressions cover identity reuse, one-light invariant,
dormant consolidation, Low/ReduceMotion, quality restoration, and
fallback when a preferred torso is removed. Actual visual and
performance behavior on Android requires playtesting.

## PR #19 — immediate bot glow response to injury and elimination

The character polish rule already used AI Humanoid.Health to dim
eliminated/non-active bots and turn off extra PointLights. However
CharacterPolishRegistry observed only model, rig and attribute changes,
not ongoing HealthChanged. A bot eliminated mid-round could therefore
retain the previous glow until another phase or quality refresh.

The registry now subscribes to HealthChanged only while AISurvivor=true
and a current Humanoid exists. It detaches when the Humanoid streams out,
when AISurvivor clears or when the bot is removed, and reconnects when a
replacement rig arrives. Player-only health changes do not trigger any
extra polish work. This adds no per-frame loop, new Instances, server
messages or gameplay rules; visual identity and motion accessibility
remain subject to existing quality policies. Engine tests cover injury,
elimination, late rig replacement, declassification and listener cleanup.
Physical Studio and Android verification is still required.


## PR #19 — Phase Dash authored 3D relief without instance growth (12 October 2026)

Nearby full-motion Phase Dash pressure blades now have a deterministic,
shallow upward relief (up to 0.15 studs at the dissipating tip) and alternating
per-facet cant (at most 6 degrees). The primary and High-tier accent rings
keep their original cyan/purple materials, directions, chord budgets, fade
lifetimes, collisions disabled and 5/7/10 primary Part caps. The accent
relief is shallower for distinct layered 3D depth, not an extra VFX layer.

ReduceMotion and distance-LOD facets use zero added rise or pitch. The client
shares a single TweenInfo and chord-step calculation per existing ring and
reuses each facet's sine/cosine values. No new Parts, particles, lights,
connections or server gameplay code were introduced. Engine movement tests
check relief bounds and determinism across all tiers and that accessibility
and distance LOD retain flat 3D profiles and the existing instance caps.

Physical QA is still outstanding: inspect blades at normal and reduced
motion from ground/camera-low perspectives and in Low/Medium/High; ensure
no ground clipping or obscured hazards. Compare Android frame times and
memory with the prior commit before claiming actual performance gains.

## PR #19 — Phase Dash avatar ribbon budget accounting (12 October 2026)

The Phase Dash ring Parts are correctly audited in the workspace-level
PhaseDashVfxLocal folder, but the transient PhaseDashRibbon Trail is
parented to the player HumanoidRootPart. This part is server-owned rig
geometry, so the previous visual-budget collector skipped the client's
temporary ribbon and underreported live GPU effects during dashes.

The character/bot collector now counts only direct Trail children named
PhaseDashRibbon under the direct HumanoidRootPart of a tracked avatar.
It excludes the rig itself, attachments, unrelated trails, and
non-Avatar cosmetics. Disabled/duplicate ribbons are counted as
allocated Effects until Debris removes them. Existing budgets, Part
allocation and dash behavior are unchanged, and no additional scans or
animation loops are introduced. Engine tests verify normal, duplicated,
disabled, removed, and incorrectly-parented ribbons and transitions of
a tracked model into the AISurvivors folder. Real Android frame times
and thermal behavior remain unmeasured.

## PR #19 — eliminate redundant bot polish refreshes on every hit

CharacterPolishRegistry subscribed to solo-bot HealthChanged but invoked
the entire polish/lighting refresh on every hit and nonlethal heal.
CharacterPolishRules uses the bot's health only to determine
Health > 0 (active) versus Health <= 0 (eliminated). Refreshing
between those two states did not change the bot's cosmetic state and
could cause repeated property writes during a crowded round.

The existing per-bot HealthChanged connection now snapshots the
alive/eliminated boolean and updates cosmetics only on a transition,
so elimination feedback remains immediate. It still switches when a
Humanoid streams in/out or AISurvivor toggles, and the connection
is disconnected on unwatch. Client visual assets, gameplay, damage,
network traffic, cooldowns and server authority are unchanged.
Engine tests cover several nonlethal damage ticks, death, a
replacement Humanoid, and unregistering the bot. Actual frame-time
savings require Android/Studio instrumentation.


## PR #19 — skyline follows streamed arena transforms (12 October 2026)

The previous client-only outboard silhouettes were built from the arena Base
CFrame only once, leaving anchored scenic pieces behind if the streamed arena
base moved or rotated later. ArenaSilhouetteAccentKit now follows that Base's
CFrame changes with one event connection per built scene, applying each
existing part's captured local rest frame. Both the 2/3/4-piece Low/Medium/High
signature and the existing richer Medium/High industrial structures are moved
together. No extra Parts, emitters, lights, per-frame loops, collision or game
mechanics were introduced; ReduceMotion remains entirely static.

The silhouette controller disconnects the previous listener before tearing
down its scenery on quality changes or map streaming and binds only after a
successful complete rebuild. Arena-presentation engine regression tests cover
translated and tilted rotated bases, unchanged tier counts, retained physics
disabling, and disconnection. Manual Studio/Android inspection is still needed
to confirm no shifted geometry, flicker, or device frame-time regression.

During the server-owned ShrinkingArena effect, Base.Size changes while the
unchanged Base.CFrame may be assigned repeatedly. The follower now remembers
the last applied transform and skips redundant cosmetic CFrame writes; no
quality budgets, play-area geometry or authoritative shrink rules change.
The arena-presentation regression also covers size-only shrink updates.

The Crossroads service beam previously used a world-space midpoint and
world-space pitch, which could misalign with its two local-frame pylons when
an arena spawned or streamed at a rotated/tilted CFrame. The beam now derives
its frame from the two pylons. An engine regression covers level, yaw-rotated,
and tilted bases; no extra scene Parts, VFX emitters, lights, physics or network
traffic are introduced, and Low/Medium/High/ReduceMotion budgets are unchanged.

## PR #19 — account for avatar motion and reactive GPU trails (12 October 2026)

VisualBudgetRules.collect(root) previously counted local avatar Highlights,
PointLights and transient PhaseDashRibbon Trails, but did not include the
per-human ChaosMotionTrail or temporary ChaosReactionDodge/Shock/Landing
Beams. All are parented directly to a HumanoidRootPart, not one of the
registered workspace-level local visual folders.

The same existing per-character pass now counts those explicitly owned
Trail/Beam names alongside Phase Dash, with no extra traversal pass,
remote events or graphics allocations. Unrelated server or bot-owned
trails, rig Parts, and wrongly-parented/wrong-class lookalikes are not
attributed to the client GPU budget. Disabled effects continue to count
until the actual Instance is destroyed; budget caps are unchanged.

A core_b2 engine regression checks five human root effects, one solo-bot
shock Beam, disabled effects, exclusions, and removal at each lifecycle
stage. This is telemetry accuracy, not a measured FPS improvement;
verify all five engine shards and Android visual/memory/FPS separately.

## PR #19 — explicit lifetime of cosmetic-quality observers (12 October 2026)

The existing client cosmetic-quality controller subscribed to each
character's DescendantAdded but did not release this connection when a
player respawned or a bot streamed out. A delayed bot addition could
also be processed after removal, and first-seen bots were sometimes
scanned twice during a tier/ReduceMotion refresh.

A dedicated CosmeticQualityRegistry now owns each model's listener
and unregisters it on CharacterRemoving, PlayerRemoving, bot ChildRemoved,
bot-folder replacement, instance unparenting or Destroying. Deferred
cosmetic adjustments confirm that both the model and the effect still
belong to the active subscription. All quality updates traverse each
already-tracked model exactly once, without rescanning player and bot
lists on every change. Matching is constrained by effect class and name.

This is a lifecycle/CPU-memory hygiene change only. It introduces no
new rendering, gameplay loops, network actions, player abilities or
graphics assets; existing color, tier and accessibility recipes remain
unchanged. Engine regression tests cover class filters, deduplication,
deferred stale work and streaming rewatch. Verify the exact-head CI and
Android reload/respawn behavior before making performance claims.

Roblox CharacterAdded can arrive before a rig is first parented into
workspace. Observers accept that initially unparented Model, refresh
on its first parent, and release it only after a previously parented
rig is actually removed. Engine tests cover that ordering as well.

## PR #19 — streamed human momentum-ribbon registration (12 October 2026)

The human-only CharacterMotionTrailRegistry previously discarded models
when CharacterAdded fired before their first workspace parenting. Once
the rig subsequently streamed in, no model observer remained, so that
participant never received the client momentum ribbon until respawn.

The registry now keeps an initially unparented character pending and
binds its Humanoid/Root when first attached to workspace. After the
first live attachment, streaming out or destroying it disconnects
all rig listeners; the existing CharacterRemoving path still stops
it explicitly. Per-player CharacterAdded/Removing connections are
also now owned and disconnected on PlayerRemoving, rejecting late
stale spawn callbacks. The original Flow/Drive/Surge visual styles,
tier and ReduceMotion policies, camera caps and server physics are
unchanged. No extra rendering work is scheduled per frame.

Core engine regressions cover pending first attach, duplicate watch,
stream-out cleanup, explicit rewatch, player departure and stale
CharacterAdded. Android/Studio physical validation remains outstanding.

## PR #19 — cinematic reaction registry survives early CharacterAdded

The short Dodge/Shock/Landing reaction registry previously declined
CharacterAdded models that were not yet parented to workspace. After
the initial callback was dropped, delayed root and Humanoid streaming
could leave the character without landing-reactive beams until respawn.

CharacterReactionRigRegistry now accepts an initially unparented Model,
subscribes to its first workspace attachment and binds the existing
Humanoid/Root listeners at that point. If an already-active rig later
streams out, all listeners and airborne history are released as before;
explicit CharacterRemoving still cleans it immediately. No per-frame
polling, added visual objects or gameplay event is introduced.
Engine survival-feedback tests cover pre-parent duplicate watch, first
bind, stream-out cleanup, explicit rewatch and non-workspace rejection.
No physical device visual or FPS measurements are yet available.

## PR #19 — late-parented character polish highlights and fill lights

The character-polish registry that owns ChaosCharacterPolishHighlight
and its small optional PointLight previously refused models if
CharacterAdded fired before their first workspace parenting. With no
later watch, those client-owned cosmetics could be missing for that
player's entire spawn, despite the separate cosmetic-quality registry
having recently gained correct pre-parent support.

The registry now keeps lightweight listeners on an initially unparented
model, binds visuals on its first insertion into workspace, and fully
releases the entry once a previously active model streams out or is
destroyed. Unrelated models parented outside workspace remain rejected.
All existing refreshes, quality tiers, reduced-motion budgets, server
gameplay and light styling are unchanged. Engine character-polish
regressions cover pending first-parent models, delayed Humanoid/Root,
no duplicate registration, cleanup, and a fresh explicit rewatch.
Physical Roblox Studio and Android rendering still require verification.


## PR #19 — bounded remote human ribbon selection (12 October 2026)

The human momentum ribbon controller previously performed a full in-place sort
of all eligible remote humans at every decorative update, although only four
Medium or eight High candidates can render a Trail (Low and ReduceMotion
continue to render none). The pure CharacterMotionTrailRules selection now
performs at most four or eight nearest-candidate passes with no temporary
arrays. Its existing 3-stud persistence bias and stable player-order tie
break are unchanged. Invalid nonfinite candidate distances cannot win a slot.

Engine body-motion tests verify four/eight limits, tie handling, bias,
exclusion of invalid distances, Low disabling and recycling of the same
selection map across updates. The controller still owns the same Trail,
attachment geometry, opacity, color, and lifetime: no gameplay movement,
server, remote protocol or hazard visibility changes. This is a source-level
work bound, not measured CPU/FPS/thermal improvement; profile on Android.


## PR #19 — idle human ribbon polling limits (12 October 2026)

The human-only momentum ribbon controller used the normal decorative update
frequency even when ribbon rendering was unconditionally disabled. The
shared CharacterMotionTrailRules.updateInterval now keeps the existing
30/24 Hz High/Medium active round cadence, but polls only about 8.3 Hz
(120 ms) outside rounds, on Low, with ReduceMotion, or during final rush.
Its client loop also avoids speed, distance, camera projection and motion
band work while the entire ribbon layer is disabled. Rig lifecycle watchers
still run independently and surviving Trails are disabled by the next poll;
there are no new loops, events, Parts, Lights, Trails or server changes.

Engine regression tests verify both active cadences and every disabled state.
These source-level reductions are not yet measured Android CPU, FPS, memory
or thermal benefits. Verify disable/enable transitions and spectator/respawn
visibility on a physical device before considering the feature complete.


## PR #19 — reject malformed human ribbon telemetry (12 October 2026)

Human-only momentum ribbon eligibility now rejects nonnumeric, negative,
NaN and infinite speed ratios or camera distances, including when the trail
was already visible. Previously a negative distance or infinite ratio could
pass the culling gate. The same finite-number predicate is reused by the
bounded remote-candidate selector. Normal distance hysteresis (90/93 High,
60/63 Medium) and Low/ReduceMotion suppression remain unchanged.

Engine body-motion regression checks invalid and retained inputs, both
boundary distances and accessibility gates. This only changes local
cosmetic rendering decisions; it does not affect server movement, damage,
physics or replication. Physical Android/Studio validation is outstanding.


## PR #19 — bound allocated remote human ribbons (12 October 2026)

The previous four/eight selection cap limited visible remote Trails but retained
inactive Trail and Attachment instances on every previously selected human.
Crowded rounds could therefore accumulate more GPU effect instances than the
advertised remote cap. The client now releases unselected remote Trail owners
and their two specifically named attachments; the local player's ribbon and
unrelated avatar attachments/effects are untouched. Low and ReduceMotion
also reclaim existing remote Trails. Nearest-selection hysteresis is retained
to moderate allocation churn as players exchange positions. Engine body-motion
tests cover successive High/Medium/Low selections, capped allocated Trails
and unrelated attachment preservation. This improves the source-level bound;
actual Android FPS, CPU, GPU and churn remain unmeasured and require device QA.


## PR #19 — Open Cloud Core A fake-player signal correction (12 October 2026)

Open Cloud run 38234038182 (commit 0e101c1) reported 253/254 passing
Core A tests. The failing CharacterAdded disconnect test sent a synthetic
Lua-table Player through BindableEvent: Roblox copies table arguments so
the emitted PlayerRemoving value is no longer the dictionary key used by
the mock registry. In production, PlayerRemoving passes a Roblox Player
Instance, not a copied table. This test now uses a synchronous, in-process
signal with explicit Disconnect and the same mock-player reference for
the complete lifecycle. The original unregistration and stale-rewatch
assertions remain; runtime registry code is unchanged. Run Core A again
to validate. This does not constitute physical Studio/Android QA.

## PR #19 — retire human ribbon GPU ownership on rig replacement (12 October 2026)

Human motion registry retirement previously disabled a Trail but kept the
client-created Trail and both root Attachments allocated when a character's
RootPart or Humanoid streamed out, was replaced, or its owner departed.
This could leave disabled decorative GPU objects on abandoned rigs.
The existing registry now accepts its visual owner's optional release
callback; the running human-ribbon controller passes
`CharacterMotionTrailBuilder.release`. Retirement removes only the
`ChaosMotionTrail` and its specifically named attachments, before losing
the old root reference. Pending unparented rigs remain watchable,
and later replacement roots still bind normally. This adds no listeners,
loops or per-frame allocations. The fallback for standalone registry
consumers remains disabling the trail when no release callback is passed.

Core A covers old-avatar cleanup on PlayerRemoving, while the body-motion
engine spec tests streaming removal, late root replacement, explicit stop,
absence of leaked named attachment instances, and watcher-count stability.
No real Roblox Studio/Android visual, memory or GPU profiling has been done.

## PR #19 — event-driven immediate accessibility ribbon suspension (12 October 2026)

Human character motion trails previously waited for a decorative loop tick
(up to 120 ms during inactive states) before disappearing after entering
Final Rush or changing to Low/ReduceMotion. The existing RoundState listener
now performs an immediate synchronous suspend on the transition, alongside
lightweight LocalPlayer attribute listeners for ReduceMotion and
VfxQualityTier. Shared `CharacterMotionTrailRules.suspended` ensures the
event and polling path use the same authoritative cosmetic eligibility gate.

The local player's existing Trail is disabled rather than reallocated;
remote Trails and their two named attachments are released immediately.
No additional heartbeat/render-step loop, server event, terrain or gameplay
property is introduced. Engine body-motion regressions exercise High/Medium
eligibility, every forbidden state, event suspend idempotence, local ownership
retention, remote reclamation, and safe cleanup without unrelated objects.
This is functional source and engine-test coverage, not a real Android
frame-by-frame or accessibility playtest.

## PR #19 — render-state resampling across quality / ReduceMotion waits (12 October 2026)

Both the human-ribbon loop and the client-owned hero landmark animator
previously captured device tier *before* `task.wait` and reused it after
waking. The landmark loop also reused the pre-wait `ReduceMotion` flag.
An accessibility/tier event during the sleep could briefly restart or
re-enable a cosmetic movement with a stale setting immediately after the
event handler had hidden/restored it.

The interval still uses the previous settings solely to schedule the
current sleep; immediately after each wait, the render path reads the
current tier and ReduceMotion flag. Existing shared `Rules.suspended`
and `HeroMotionBudget.motionScale` then gate the actual animation.
No new polling loops, listeners, effects, remotes or physics are added.
Engine CI exercises the shared eligibility/accessibility policies, but a
real device event-timing reproduction is still required before claiming
an empirically verified flicker-free Android result.

## Rookie vote guidance with streamed / empty options (12 October 2026)

The first-time coach now shows **VOTE** only when RoundState has a nonempty
`voteOptions` table. Empty, absent, or malformed vote lists retain the
existing onboarding text instead of telling a new player to tap a
nonexistent ballot. Once at least one option appears, the original
localized voting guidance is unchanged. Engine `core_a` coverage checks
all four cases and preserves ready/round behavior. This changes no server
voting rules, gameplay, timing, rewards, map parts or graphics budgets.
Check on physical Android whether vote button hit targets and small-screen
coach wording are readable; no actual device test is claimed.

## Rookie 3D wayfinding matches the vote cue (12 October 2026)

The world-space rookie guide still treated an empty Lua voteOptions table
as true even after the beginner text was corrected. It could therefore
remove the practice/arena direction marker despite there being no
clickable vote choices, or remain visible while the coach said VOTE in
waiting phase. Both client displays now use
`FirstTimeExperience.hasVoteOptions` to require a non-empty table.
The RookieWorldGuide RoundState listener also rejects non-table payloads
instead of assigning a scalar to its current state and later crashing
when reading `currentState.phase`. A malformed event safely returns
cosmetic guidance to waiting, without touching server-owned voting.

Engine core_a regression covers empty/invalid ballots and real options;
no new Instances, loops, remotes, collisions, gameplay rewards or VFX
assets are added. Physical Android and Studio onboarding QA is pending.

## PR #19 — streamed rookie 3D markers and late avatar roots (12 October 2026)

The first-run world guide now observes the current GeneratedMap's relevant
nested anchors, not only the top-level map insertion. A practice or mobility
BasePart may arrive before its `LobbyPracticePad` / `ArenaMobilityPad`
attribute; the matching attribute signal re-evaluates the guide when it arrives.
A late `ArenaRunway` is likewise discovered. Map regeneration disconnects
the previous descendant and attribute listeners; a streamed-out selected
anchor requests a new target. A late HumanoidRootPart requests a refresh,
including when the avatar existed before the LocalScript started. Batched
deferred updates avoid scanning all map descendants on every visual frame.

Regression coverage in existing `first-time-experience.spec.luau` checks that
anchor candidates are restricted to the correct nested map sections and
remain eligible before their marker attributes replicate. The actual event
ordering, billboard appearance, stale-marker cleanup, and FPS still require
an unpublished Studio candidate and physical Android review. Specifically,
join on a throttled network and verify practice -> runway -> ready mobility
markers when both folders and their attributes arrive late; swap maps during
streaming and inspect for lingering guides. No server gameplay or hitbox
logic, new permanent render loops, or production publishing is involved.

## PR #19 — consistent, actionable voting on Android (12 October 2026)

The main HUD previously treated an empty Lua voteOptions table as truthy.
It could announce voting before a usable ballot existed, suppress the
first-time movement hint, and leave stale touch vote cards on screen when
voteOptions later disappeared during an intermission.

A shared ballot predicate validates the current server contract (one to
three distinct entries carrying nonempty string IDs). The HUD, rookie
guide, lobby presentation and attention budget now use the same rule.
In the HUD, a missing or invalid intermission ballot always clears old
vote cards and the previous local selection. Malformed non-table
RoundState events are ignored. All server-side voting rules, timing,
damage, physics, AI voting, rewards and RemoteEvents remain untouched.

Existing engine specs for first-run coaching, lobby presentation, and
attention budgets cover empty, malformed, duplicate and oversized lists.
Android/Studio acceptance still requires a physical staged first-run:
verify movement/jump hints before voting, three tappable and readable
cards during voting, and zero old vote targets when voting closes.
Rejoin mid-intermission, trigger a short portrait viewport, and observe
quality changes and ReduceMotion. These are required tests, not claimed
successful observations.

## PR #19 — vote card UI retention on Android (12 October 2026)

The main vote panel now uses a small deterministic signature of its
actionable option IDs, displayed names/hints/vote counts, local selection,
and compact touch layout. Repeated RoundState countdown packets with
unchanged votes no longer destroy/recreate every button, glyph and UI
constraint. A change of votes, choice, or viewport class still rebuilds
the affected display. Empty/malformed/closed ballots clear old buttons.

The button activation handler additionally checks that the authoritative
current client snapshot is still in an active intermission vote and still
contains the chosen ID before sending VoteDisaster; the existing server
rate limit, phase and option checks remain authoritative.

The existing first-time-experience engine spec tests stable keys and
invalidation on count, name, hint, ID, selection and compact changes.
Physical Android QA still needs a staged first-run and 30-minute test;
this change alone is **not** an FPS measurement, a playtest or proof of
release readiness.

## PR #19 — accessibility settings during empty votes, motion-safe buttons (13 October 2026)

AccessibilityQuickSettings previously treated `voteOptions = {}` as voting
because any non-nil table is truthy. It could hide the settings button
during a calm intermission even though the voting HUD and rookie coach
correctly found no actionable options. It now uses the existing shared
`FirstTimeExperience.hasVoteOptions` predicate **and** the intermission
phase, and ignores invalid non-table RoundState packets.

The shared UITheme press-feedback helper also avoids tweening button scale
when the local `ReduceMotion` setting is true. The explicit vote-card
selection bounce follows the same setting while preserving selection
feedback through static highlighting. No per-frame polling or extra
per-button settings listener is introduced.

Mobile/Studio acceptance: enter a first-run lobby before the vote opens
and verify that Settings can be opened (if DataLoaded); send no options
and then an empty option table during intermission and confirm Settings
remains accessible; open valid voting and confirm Settings hides so
cards are unobstructed; verify it reappears afterward. Enable
ReduceMotion and tap lobby controls and voting cards, observing no
press-scale animations. Retest quick rotations and map reloads.
Actual device performance and QA are still unverified.

## PR #19 — arena briefing stability on replicated metadata changes (13 October 2026)

ArenaGuide previously preferred the replicated ArenaMetadata VariantId even
when a ready-phase RoundState already contained the correct server arenaId.
On slow mobile replication, the metadata could still describe the previous
arena; the strategy panel could therefore display incorrect route guidance.
It also started new reveal Tweens every second for identical ready countdown
updates, causing a repeated visible flash.

The guide now uses the authoritative ready-state arenaId for localized
copy, accepts replicated fallback hints only when that VariantId matches,
and refreshes its still-active briefing on relevant metadata attributes.
Repeated identical messages do not create new Tweens. Text updates while
visible do not blank the panel. A non-ready phase, including intermission
and result, hides old guidance. Invalid RoundState payloads are ignored.
ReduceMotion presents/hides the panel directly and cancels active card
transitions on preference changes.

An existing first-run engine spec covers late/mismatched arena identity.
Required unpublished Android/Studio QA: join during the ready countdown
with simulated delayed ArenaMetadata, rotate screen while briefing is
visible, validate no 1-second flashing, then transition ready to round
and waiting. Confirm the old arena label never appears for the new map.
No physical device/FPS result is claimed from this source change.

## PR #19 — mobile round-focus tween lifecycle and ReduceMotion (13 October 2026)

The live round FocusBar now keeps at most one active Tween per visual
target (bar, scale, shard feedback and intensity fill). The previous
hide callback is invalidated if the player re-enters a round before
the fade ends. Repeated late RoundState packets while hidden do not
restart the same fade. A changed intensity triggers one new animation,
instead of allocating a Tween on every countdown/attribute refresh.

ReduceMotion uses immediate state changes for entrance/exit and the
intensity fill, with static completion/shard feedback instead of
spring-like scale pulses. Switching ReduceMotion while a transition
runs cancels the previous Tween, resets its visual state and refreshes
the current round snapshot. Non-table RoundState packets are ignored.

No authoritative gameplay, health, physics, player input, reward or
server replication logic changes. Static hazard colors, survivor
objectives and other textual information remain intact.

Unpublished Android/Studio acceptance: toggle ReduceMotion during
entrance, mid-round, a challenge completion, shard pickup, and exit;
verify no pulse/flash and clean static visuals. Toggle while an exit
fade is in progress, then rejoin a round immediately to confirm that
no delayed callback hides the focus bar. Confirm intensity fill changes
only with intensity, status timer still advances each second, and the
FocusBar doesn't obstruct movement/jump buttons at 540x320, 640x360,
960x440 and 1280x720. Device FPS and real touch QA remain unmeasured.
