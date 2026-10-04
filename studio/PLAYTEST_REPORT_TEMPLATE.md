# Chaos Survival — Authenticated Studio / Device Playtest Report

Copy this file for each release-candidate certification run.

## Build identity

- Commit SHA:
- Date/time UTC:
- Roblox Studio version:
- Runner/device:
- OS:
- Screen resolution / viewport:
- Network conditions:
- Tester:

## Automated Studio E2E

- Workflow/run:
- Result: PASS / FAIL
- Artifact name:
- `CHAOS_STUDIO_E2E_OK` present: yes / no
- Server/client runtime errors:
- Notes:

## Core flow

| Check | PASS / FAIL | Notes |
| --- | --- | --- |
| Lobby loads correctly |  |  |
| Intermission is readable |  |  |
| Vote works |  |  |
| READY transition is clear |  |  |
| Round starts correctly |  |  |
| Elimination is clear |  |  |
| Spectator mode works |  |  |
| Result/reward feedback works |  |  |
| Next round starts cleanly |  |  |
| Late join receives current round state |  |  |
| Leave/rejoin does not corrupt the round |  |  |

## Arena pass

| Arena | Visual quality | Navigation | Hazard readability | Performance | Notes |
| --- | --- | --- | --- | --- | --- |
| Classic |  |  |  |  |  |
| Towers |  |  |  |  |  |
| Crossroads |  |  |  |  |  |
| Orbital |  |  |  |  |  |

## Disaster pass

| Disaster | Telegraph readable | Fair hitbox/effect | Cleanup clean | Double Chaos readable | Notes |
| --- | --- | --- | --- | --- | --- |
| Rising Lava |  |  |  |  |  |
| Meteor Shower |  |  |  |  |  |
| Moon Gravity |  |  |  |  |  |
| Disappearing Platforms |  |  |  |  |  |
| Tornado |  |  |  |  |  |
| Freeze Pulse |  |  |  |  |  |
| Bomb Rain |  |  |  |  |  |
| Speed Surge |  |  |  |  |  |
| Blackout |  |  |  |  |  |
| Shrinking Arena |  |  |  |  |  |
| Jump Shock |  |  |  |  |  |

## Mobile UX

- Touch-only navigation: PASS / FAIL
- Roblox controls overlap critical UI: yes / no
- Menu tap targets comfortable: yes / no
- Vote buttons comfortable: yes / no
- HUD readable during Double Chaos: yes / no
- Meteor/Bomb cue and MOVE CENTER never overlap: yes / no
- Coyote jump feels helpful without creating double jumps: yes / no
- Buffered jump feels responsive on touch: yes / no
- Spectator controls/readability: PASS / FAIL
- Low VFX mode readable: yes / no
- Blackout playable on device brightness: yes / no
- Notes:

## Performance soak

Duration target: 30–60 minutes.

- Starting FPS:
- Lowest observed FPS:
- Typical FPS:
- Visible stutter:
- Memory at start:
- Memory at end:
- Progressive degradation: yes / no
- Arena-swap spike:
- Bomb + Double Chaos performance:
- Meteor + Double Chaos performance:
- Device heat/battery notes:

## Persistence pass

| Scenario | PASS / FAIL | Notes |
| --- | --- | --- |
| Coins quit/rejoin |  |  |
| XP/Level quit/rejoin |  |  |
| Wins/Games quit/rejoin |  |  |
| Daily reward quit/rejoin |  |  |
| Quest completion quit/rejoin |  |  |
| Achievement quit/rejoin |  |  |
| Cosmetic buy/equip quit/rejoin |  |  |
| Rapid rejoin |  |  |
| Server handoff / second session |  |  |
| Temporary DataStore failure |  |  |

## Audio / accessibility

- Important hazards understandable muted: PASS / FAIL
- Music masks hazard cues: yes / no
- Essential information relies only on color: yes / no
- Camera motion comfortable: yes / no
- VFX fatigue after soak: yes / no
- Haptics excessive: yes / no

## Blocking issues

List only issues that prevent this build from becoming the next release candidate.

1.
2.
3.

## Non-blocking polish

1.
2.
3.

## Final decision

- [ ] PASS — candidate can proceed to alpha/release gate.
- [ ] FAIL — fixes required, then all affected gates must be re-run.

Decision notes:
