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
| Fresh join: avatar never trapped inside the central lobby platform |  |  |
| LobbySpawnRecovered fires only for an embedded or immobilized fresh avatar |  |  |
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

## Solo AI hazard-response acceptance (authenticated Roblox Studio + Android)

- Start a real one-human Solo Rush session. Confirm three live AI rigs under `Workspace.AISurvivors` and no artificial respawns during an active round.
- During Meteor Shower and Bomb Rain, observe bots that are stopped or hesitating **before** the warning appears. Once the warning has been visible for a profile's reaction delay, bots must start a legitimate `Humanoid` escape movement rather than remain frozen by the prior idle/turn pause. Record short video and warning-to-first-movement timing for all three bot profiles (Cautious / Balanced / Bold).
- During Disappearing Platforms, observe a bot standing on a platform at the `Warning` collapse phase: it must abandon an idle/turn pause and attempt an escape. An occasional genuine elimination is acceptable; scripted invulnerability or teleporting is not.
- Check the same hazards while no warning is nearby: natural hesitation, idle pauses and normal movement speed should remain; bots must not dodge an invisible hazard.
- Repeat with a late human joining mid-round: existing AI contestants must not disappear or restart, and should still evade hazards. Confirm client and server Output contain no AI step warnings or exceptions.
- On Android, verify three AI rigs remain visible, responsive and animated on Low and Medium quality. Record FPS and whether threat reactions survive performance downshifts.
- Result: PASS / FAIL / NOT RUN
- Evidence (video/screenshots and timestamped Output):
- Physical Studio version / device:
- Notes:

## Landing & run-transition realism (real Roblox client)

- Physical stage build matches exact SHA: yes / no
- R6/R15 ordinary raised-deck jumping lands with precisely one visible impact: PASS / FAIL / NOT RUN
- Small stair contacts do not trigger heavy landing reactions: PASS / FAIL / NOT RUN
- SpeedSurge / JumpShock / MoonGravity landing does not add fake launch, skid, or pivot: PASS / FAIL / NOT RUN
- Android app suspension/resume produces no stale landing VFX/camera displacement: PASS / FAIL / NOT RUN
- Low VFX, ReduceMotion, 15-minute repeated-jump soak: PASS / FAIL / NOT RUN
- Matching device video, logs, target FPS, staging place ID:

## Character animation / camera ownership — rapid respawn E2E

- Stage SHA matched to this report: yes / no
- 10 R15 + 10 R6 rapid respawns during moving/jumping/landing: PASS / FAIL / NOT RUN
- HumanoidRootPart arrives late (including >5 seconds): PASS / FAIL / NOT RUN
- Old character never takes back Motor6D/camera ownership: PASS / FAIL / NOT RUN
- Removing previous character after CharacterAdded does not erase the live rig: PASS / FAIL / NOT RUN
- Exactly one landing response, no old-root dust or landing preview: PASS / FAIL / NOT RUN
- No persistent camera pitch/roll/FOV offset on return to lobby: PASS / FAIL / NOT RUN
- Android low-network video, Studio logs and exact place-version evidence:

## Android Dash / adaptive-quality acceptance

- Exact published SHA and place version (not repository-only):
- Device, Android version, resolution, orientation, network:
- DASH visible/clickable on short landscape, normal landscape and portrait: PASS / FAIL / NOT RUN
- First-use hint beside button, clear of hazard timer, no clipping: PASS / FAIL / NOT RUN
- Native jump never fires through cooling/disabled Dash touch target: PASS / FAIL / NOT RUN
- Grounded ready Dash succeeds; cooldown/airborne/eliminated requests fail: PASS / FAIL / NOT RUN
- Controls stable after rotation, reconnect and rapid respawn: PASS / FAIL / NOT RUN
- Sustained low-FPS quality downgrade remains functional: PASS / FAIL / NOT RUN
- ≥2s app suspend/resume does not falsely downgrade visual tier: PASS / FAIL / NOT RUN
- 30-min Medium→Low soak (FPS typical/worst, GPU/CPU, memory):
- Videos, real logs and published build identity:

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
- Staging HUD real FPS / worst-frame milliseconds (on-device, 4 s sample):
- Staging HUD VisualBudget status and part/light/effect counts per arena:
- Staging evidence: screenshot with commit stamp + performance overlay:
- Verify staging diagnostic UI is ABSENT from production:
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


## Premium acceptance gates (not an automatic AAA certification)

A release candidate is **not ready** when any mandatory item below fails or has
no supporting device/Studio evidence. Compilation and upload alone are not
proof of visual quality or playable performance.

| Gate | Objective evidence | PASS / FAIL / NOT RUN |
| --- | --- | --- |
| First 90 seconds | Fresh Android join, clear orientation, avatar can walk/jump/vote before first round; no forced manual unstuck |  |
| All four arenas | HUD-free captures of Classic/Towers/Crossroads/Orbital at Low/Medium/High; distinctive architecture remains legible |  |
| Gameplay/skill | Genuine movement and hazard escape; no false collisions or unreachable valid platforms in 4 arenas |  |
| Disaster clarity | 11 single disasters plus supported Double Chaos pairs; warnings take precedence over cosmetic neon |  |
| AI competition | Solo bots are present, visibly animate, dodge signaled threats and never receive unfair invulnerability |  |
| Responsive controls | Phone portrait/landscape when supported; no jump/vote/settings/timer overlap; spectator input works |  |
| Performance | Android Medium typical >= 45 FPS target, sustained >= 30 FPS; no budget OVER; diagnose each significant stutter |  |
| Accessibility | ReduceMotion/AudioMuted/HapticsDisabled effective and persistent; hazards are understandable without sound |  |
| Reliability | 30-minute mixed solo/multiplayer soak, multiple arena swaps, late join, disconnect/rejoin, no unbounded memory growth |  |
| Economy integrity | Rewards and persistence accurate; premium items cosmetic only; no paid gameplay advantage |  |
| Visual/audio quality | Human evaluation of materials, composition, animation transitions, lighting, VFX impact and audio mix against reference captures |  |

The FPS thresholds are **targets**, not measured results; record actual device,
viewport, VFX tier, run SHA and sample length. Do not substitute GitHub Actions
success for real Android gameplay and screenshot validation.

## Final decision

- [ ] PASS — candidate can proceed to alpha/release gate.
- [ ] FAIL — fixes required, then all affected gates must be re-run.

Decision notes:
