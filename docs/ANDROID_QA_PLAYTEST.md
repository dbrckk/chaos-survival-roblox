# Chaos Survival — Android physical acceptance (PR #18)

This is a **hands-on test plan, not proof of completion**. Do not mark a check as passed unless it was observed on the actual PR #18 candidate. The existing public Roblox place may run an older published build: it cannot certify an unpublished pull request.

## Before testing

Record the exact deployed **candidate commit**, experience/place ID, phone model, Android version, graphics quality, display orientation, network type, and UTC/local test date. A preview/staging Roblox place must be explicitly linked to that commit; do not overwrite production merely to test. Enable Roblox's in-client performance statistics if the version/device supports them. Capture screenshots or a short recording of each problem and the precise phase/time.

## Minimum sessions

1. **First-time solo (15 minutes)** — join an otherwise empty server. Verify that AI survivor bots join and make the vote/ready/gameplay meaningful. Record the first three actions required to understand the objective, vote, and how to survive. Observe at least two complete rounds.
2. **Multiplayer (15 minutes)** — two or more actual clients. Test joins during voting and during an active round, elimination, next-player spectator cycling, results, return to intermission, and leaving/rejoining. Verify the camera follows the chosen survivor rather than the eliminated player's lobby avatar.
3. **Arena rotation** — observe Classic, Towers, Crossroads and Orbital. Photograph each unique landmark. Check terrain, colliders, readability, platform edges, and no leftover scenery following a map swap.
4. **Visual pressure** — attempt Double Chaos with Meteors, Bombs, Freeze and Darkness; compare Low, Medium and High VFX on the same phone. Warnings and hazards must remain clear in Low mode. Record any severe FPS drop and frame hitch.
5. **Motion and accessibility** — R15 start/stop, 180° pivot, jumping, landing, death and respawn. Turn Reduce Motion and Audio Muted on/off. Check no sustained joint deformation, doubled footsteps, reaction FX after elimination, or hidden danger warnings.
6. **Showtime/UI** — in lobby and result phases open the six-emote panel, activate each available emote and interrupt it by walking or jumping. In a round confirm the DJ stage is not visible. Verify Settings remains tappable with the emote grid open on narrow portrait viewports. Check screen rotation if available.
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
