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
