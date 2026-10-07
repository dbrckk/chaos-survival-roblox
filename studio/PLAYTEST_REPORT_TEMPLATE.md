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
- Initial VFX tier:
- Final VFX tier:
- VFX tier transitions:
- ReduceMotion state:
- Haptics disabled state:

## Automated Studio E2E

- Workflow/run:
- Result: PASS / FAIL
- Artifact name:
- `CHAOS_STUDIO_E2E_OK` present: yes / no
- `CHAOS_E2E_ARENA` observed for Classic / Towers / Crossroads / Orbital: yes / no
- `CHAOS_E2E_ARENA_ENTRY` observed for Classic / Towers / Crossroads / Orbital: yes / no
- RoundState arenaId matched world VariantId for all four: yes / no
- Per-arena ROUND visual budget probes: Classic / Towers / Crossroads / Orbital PASS / FAIL
- Server/client runtime errors:
- Physical arena entry probes (Classic/Towers/Crossroads/Orbital): PASS / FAIL
- READY arenaId matches observed world arena for all four: yes / no
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
- Motion / Sound / Haptics toggles have comfortable touch targets: yes / no
- Haptics toggle stops active vibration immediately: yes / no
- Haptics preference survives quit/rejoin: yes / no
- Low VFX mode readable: yes / no
- Blackout playable on device brightness: yes / no
- FOV remains comfortable and within 60–90: yes / no
- No visible FOV tug-of-war during SpeedSurge / damage / Final Rush: yes / no
- LowGravity cosmetics disappear correctly in Low / ReduceMotion: yes / no
- Landing VFX remain local/lightweight in Low: yes / no
- Animated arena decor returns to baseline after the round: yes / no
- Notes:

## Performance soak

Duration target: 30–60 minutes.

- Starting FPS:
- Lowest observed FPS:
- Typical FPS:
- Visible stutter:
- Memory at start (MB / ClientMemoryPulse):
- Memory at end (MB / ClientMemoryPulse):
- Instance count at start:
- Instance count at end:
- Latest frame/render snapshot (FrameMs / CPU / GPU):
- Visual metrics at start (parts/lights/effects):
- Visual metrics at end (parts/lights/effects):
- Visual instance growth without map/phase reason: yes / no
- Progressive degradation: yes / no
- Arena-swap spike:
- Bomb + Double Chaos performance:
- Meteor + Double Chaos performance:
- VFX tier transitions during soak:
- Final settled VFX tier:
- Visual budget warning observed: yes / no
- Latest PerformancePulse Visual: P/L/E:
- Latest PerformancePulse Budget status: OK / OVER / UNKNOWN
- Latest PerformancePulse context: phase / chaos count / final rush
- Device heat/battery notes:

## Visual / animation regression

| Check | PASS / FAIL | Notes |
| --- | --- | --- |
| Only one Clouds instance |  |  |
| Decorative local parts are non-collidable/non-touch/non-query |  |  |
| High / Medium / Low remain visually coherent |  |  |
| No excessive decorative neon vs hazard cues |  |  |
| AI idle/walk/run transitions blend naturally |  |  |
| AI jump → fall → landing has no visible track overlap |  |  |
| AI bots do not look perfectly synchronized |  |  |
| No obvious foot sliding at normal bot speeds |  |  |
| Arena identity motion restores cleanly after active phases |  |  |
| Camera FOV has no competing controller behavior |  |  |

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
- Haptics can be disabled independently of ReduceMotion: yes / no

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
