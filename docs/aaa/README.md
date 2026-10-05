# Chaos Survival — AAA Specialist Review Index

This directory is the professional review system for the project.

## Read first

1. [AAA Studio Operating System](AAA_STUDIO_OPERATING_SYSTEM.md)
2. [Current Specialist Audit](CURRENT_SPECIALIST_AUDIT.md)
3. [Specialist Scorecard Template](SPECIALIST_SCORECARD_TEMPLATE.md)
4. [Specialist Role Prompts](12_SPECIALIST_ROLE_PROMPTS.md)

## Department reviews

1. [Creative Direction, Art & World](01_CREATIVE_ART_LEVEL_REVIEW.md)
2. [Gameplay, Level Design & Balance](02_GAMEPLAY_LEVEL_BALANCE_REVIEW.md)
3. [Game Feel, Animation, VFX & Audio](03_GAME_FEEL_ANIMATION_VFX_AUDIO_REVIEW.md)
4. [UI, UX, Accessibility, Localization & Mobile](04_UI_UX_ACCESSIBILITY_MOBILE_REVIEW.md)
5. [AI, Social, Retention, Economy & Monetization](05_AI_SOCIAL_RETENTION_ECONOMY_REVIEW.md)
6. [Engineering, Networking, Security, Data & Performance](06_ENGINEERING_NETWORK_DATA_PERFORMANCE_REVIEW.md)
7. [QA, Analytics, Live Ops, Store & Release](07_QA_ANALYTICS_LIVEOPS_RELEASE_REVIEW.md)
8. [Final Harmonization & Perfect-Candidate](08_HARMONIZATION_AND_PERFECT_CANDIDATE.md)

## Execution protocols

9. [Authored Asset Pipeline](09_AUTHORED_ASSET_PIPELINE.md)
10. [Physical Device Certification](10_DEVICE_CERTIFICATION_PROTOCOL.md)
11. [Public Alpha & Player Research](11_PUBLIC_ALPHA_RESEARCH_PROTOCOL.md)

## Existing deep implementation guides

- `/AAA_VISUALS_ANIMATION_GUIDE.txt`
- `/GAME_FEEL_UX_GUIDE.txt`
- `/VISUAL_OVERHAUL_PLAN.txt`
- `/SOCIAL_EXPERIENCE_PLAN.md`
- `/EXPERIENCE_MASTER_PLAN.md`
- `/RELEASE_CHECKLIST.md`

## Required workflow for every significant change

1. Name the primary specialist.
2. Name one cross-discipline reviewer.
3. State the player problem.
4. Implement the smallest sufficient change.
5. Run automated validation.
6. Run device/playtest validation when relevant.
7. Update score/evidence.
8. Re-check the weakest department.
9. Repeat.
10. When all targets are met, run harmonization/subtraction before declaring Perfect-Candidate.

## Responsibility matrix

| Change | Primary | Mandatory reviewer |
|---|---|---|
| New hazard | Gameplay | VFX + Audio + QA |
| Arena geometry | Level Design | Art + AI + Performance |
| VFX | VFX | Gameplay readability + Accessibility |
| Animation | Animation | Game Feel + Mobile |
| UI | UX/UI | Accessibility + Mobile |
| AI behavior | AI | Gameplay fairness + Performance |
| Progression | Progression | Economy + Analytics |
| Monetization | Economy | Ethical monetization + UX |
| Remote/network | Network | Security + QA |
| Persistence | Data | QA + Release |
| Social feature | Social | UX + Analytics |
| Audio | Audio | Gameplay + Accessibility |
| Lighting | Art | Gameplay readability + Performance |
| Marketing asset | Store/Marketing | Creative Direction + Release |

## Review cadence

### Every code batch
- CI;
- specialist check;
- update changelog when player-visible.

### Every major feature
- scorecard;
- cross-discipline review;
- device QA if visual/touch/performance-sensitive.

### Every milestone
- full current specialist audit;
- weakest-link reprioritization.

### Before RC
- full harmonization;
- subtraction pass;
- physical device certification;
- persistence/rejoin;
- public alpha;
- release checklist.

## Stop condition

Broad feature development stops when the project reaches Perfect-Candidate.

After that, only:
- verified bug fixes;
- evidence-driven tuning;
- release preparation;
- production monitoring.
