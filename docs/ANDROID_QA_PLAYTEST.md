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
