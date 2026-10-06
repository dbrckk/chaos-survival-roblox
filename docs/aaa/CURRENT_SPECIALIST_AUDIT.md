> **Snapshot status:** retained as a specialist baseline recovered from an earlier review branch. For current evidence-backed release prioritization, use `/CURRENT_QUALITY_AUDIT_2026-10-06.txt` and `/DOCUMENTATION_INDEX.md`. This file is not release certification.

# Chaos Survival — Current Specialist Audit

## Method

This audit is based on repository architecture, current plans, automated-test coverage and documented implementation state. It intentionally penalizes areas that lack real-device, authenticated Studio or real-player evidence.

A high code-quality score with low evidence confidence is **not** release approval.

## Current assessment

| Department | Score | Confidence | Main reason |
|---|---:|---|---|
| Creative Direction | 8.5 | Medium | coherent neon-chaos identity and distinct arena language; final capture-based harmonization still missing |
| Environment Art | 8.4 | Medium | strong procedural depth/hero scenery; authored PBR Hero assets still limited |
| Level Design | 8.7 | Medium | four distinct arenas, route/navigation logic, AI-aware topology; real player route/fairness QA still needed |
| Gameplay Systems | 9.0 | Medium | complete survival loop, 11 hazards, Fusion/Overdrive/Final Rush, risk/reward systems |
| Balance/Fairness | 8.6 | Medium | explicit pair blocking and server authority; needs real-player survival-rate validation |
| Game Feel | 8.7 | Medium | camera/body/haptic/near-miss layers are strong; real tactile validation remains |
| Animation | 7.7 | Medium-Low | procedural additive motion is advanced; authored original R15 clips remain the major ceiling |
| VFX | 8.8 | Medium | hazard-specific signatures, budgets and readability logic; Double Chaos/device visual QA remains |
| Audio | 7.9 | Medium-Low | architecture/mix/spatialization strong; weak point is original/verified high-quality source assets |
| UI | 8.5 | Medium | responsive/state-aware system is mature; dense legacy surfaces and physical-device overlap risk remain |
| UX | 8.8 | Medium | FTUE, phase hierarchy, spectator/result/social loops are thoughtful; blind-test evidence missing |
| Accessibility | 8.4 | Medium | ReduceMotion/Low-VFX/multi-channel warnings exist; contrast/motion-sickness real QA incomplete |
| Localization | 8.5 | Medium | broad stable-ID localization; newest polish layers still require ongoing hardcoded-copy audit |
| Mobile/Touch | 7.8 | Low | architecture is mobile-aware, but current HEAD lacks full physical Android certification |
| AI Survivors | 8.9 | Medium | map/hazard/social-aware, humanized, non-cheating; real observation tuning still required |
| Social Design | 8.7 | Medium | shared ritual, reactions, Crew Signal, invite/share loops; needs real human-group observation |
| Retention/Progression | 8.8 | Medium | dailies/weeklies/mastery/collection/next-goal; public retention evidence not yet available |
| Economy | 8.5 | Medium-Low | fair sources/sinks and cosmetic orientation; needs real earn-rate/economy telemetry |
| Monetization Fairness | 9.2 | High | explicit cosmetic-only boundaries and CI guard |
| Engineering Architecture | 9.0 | High | modular shared rules/services plus CI; some large legacy files remain dense |
| Networking/Security | 8.9 | High | server-authoritative critical systems, validation/rate limiting present |
| Persistence/Data | 8.8 | Medium | robust structure documented; final real rejoin/save certification still required |
| Performance Architecture | 8.7 | Medium | VFX tiers, throttling and targeted scans are strong |
| Physical Performance | 7.2 | Low | 30–60 minute Android soak/MicroProfiler evidence remains a release blocker |
| Analytics | 8.8 | Medium | onboarding/gameplay/economy/social funnels present; public data not yet available |
| Automated QA | 9.2 | High | build guards + real-engine matrix coverage are strong |
| Studio E2E | 7.5 | Low | harness exists; authenticated current-HEAD evidence still required |
| Public Alpha | 4.5 | Low | not yet performed |
| Live Ops Readiness | 7.6 | Medium-Low | rollback/release concepts exist; production incident cadence not yet exercised |
| Store/Marketing | 5.5 | Low | icon/thumbnails/trailer/final store presentation intentionally not finalized |
| Release Readiness | 7.0 | Medium-Low | code is advanced but device/persistence/alpha/public assets remain open |

## Current weakest links

### 1. Real-device evidence
The largest gap is no longer feature architecture. It is proving that the complete stack is comfortable and performant on a real Android device.

Required:
- touch;
- HUD overlap;
- warning readability;
- camera comfort;
- thermal behavior;
- FPS/frame-time;
- 30–60 minute cleanup stability.

### 2. Authored animation
Procedural motion has reached diminishing returns.

Highest-value visual upgrade:
- authored R15 locomotion;
- takeoff/fall/landing;
- stop/deceleration;
- hit reaction;
- victory/clutch;
- social emote;
- marker-synchronized audio/VFX.

### 3. Original audio asset quality
The mix architecture is ahead of the source-asset quality in places.

Highest-value audio upgrade:
- original or verified licensed hazard/impact/arena assets;
- loudness normalization;
- phone-speaker and headphone validation.

### 4. Final PBR Hero art
Procedural geometry is strong, but selected authored Hero meshes/materials would raise perceived quality more than another layer of Parts/VFX.

### 5. Real-player evidence
Need:
- blind new-player session;
- 2–4 friend session;
- solo session;
- public alpha;
- quit-point analysis.

### 6. Public presentation
Do only after final visual certification:
- icon;
- thumbnails;
- trailer;
- mobile store page.

## Current strategic conclusion

The project should **not** respond to quality pressure by adding many more systems.

The highest return now comes from:
1. evidence;
2. authored assets;
3. harmonization;
4. subtraction;
5. real-player observation.

## Next automatic work order

1. Keep CI/engine green.
2. Close hardcoded/localization inconsistencies.
3. Prepare authored-animation pipeline and asset manifest.
4. Prepare Android certification procedure.
5. Prepare audio asset replacement manifest.
6. Run cross-discipline harmonization.
7. Run device/Studio tests.
8. Run small alpha.
9. Re-score every department.
10. Only then produce final public assets and RC.
