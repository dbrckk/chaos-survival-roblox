# Chaos Survival — Documentation Index

This file defines the canonical reading order and source-of-truth hierarchy for the project documentation.

The project now has enough design and quality documentation that duplication itself can become a quality risk. This index exists to prevent contradictory rules, obsolete release claims, and "plan drift".

## 1. Canonical hierarchy

When two documents disagree, use this order:

1. **RELEASE_CHECKLIST.md**
   - Source of truth for whether a build may be called release-ready.
   - Evidence must apply to the exact release lineage.
   - A historical PASS never automatically certifies a later SHA.

2. **QUALITY_OWNERSHIP_EVIDENCE.txt**
   - Source of truth for who/what must validate each quality discipline.
   - Defines PASS / PASS WITH RESERVATION / FAIL / NOT TESTED evidence requirements.

3. **PERFECTION_HARMONIZATION_MATRIX.txt**
   - Source of truth for quality scoring and the stop-expanding / start-harmonizing threshold.
   - A score without evidence is provisional.

4. **PHASE_ATTENTION_BUDGET.txt**
   - Source of truth when UI, VFX, audio, camera, social or meta systems compete for attention.
   - Safety/danger/control always outrank decoration, social and monetization.

5. **MULTI_EXPERT_PREMIUM_REVIEW.txt**
   - Source of truth for specialist review roles and veto questions.

6. **EXPERIENCE_MASTER_PLAN.md**
   - Source of truth for overall experience roadmap and integrated product direction.

7. **GAME_FEEL_UX_GUIDE.txt**
   - Source of truth for control feel, feedback, onboarding, cognitive load, mobile UX, fairness and session flow.

8. **AAA_VISUALS_ANIMATION_GUIDE.txt**
   - Source of truth for environment art, PBR, lighting, VFX, animation, camera and visual performance.

9. **SOCIAL_EXPERIENCE_PLAN.md**
   - Source of truth for social presence, invitations, reactions, shared moments and non-P2W social design.

10. **VISUAL_OVERHAUL_PLAN.txt**
    - Execution tracker for the visual roadmap.
    - If an old implementation note conflicts with AAA_VISUALS_ANIMATION_GUIDE.txt, the guide wins.

11. **PUBLIC_PRESENTATION_PLAN.txt**
    - Source of truth for icon, thumbnails, trailer and store presentation once the in-game visual build is certified.

12. **CURRENT_QUALITY_AUDIT_2026-10-06.txt**
    - Snapshot, not eternal truth.
    - Must be superseded by a newer dated audit after major milestones.

13. **CHANGELOG.md**
    - Historical implementation record, not design authority.

14. **README.md**
    - Public/repository overview, not a substitute for production standards.

## 2. Required reading by task

### Gameplay / balance change
Read:
- EXPERIENCE_MASTER_PLAN.md
- GAME_FEEL_UX_GUIDE.txt
- PHASE_ATTENTION_BUDGET.txt
- MULTI_EXPERT_PREMIUM_REVIEW.txt sections Game Director / Lead Game Designer / QA

Then update:
- relevant tests
- current roadmap/status
- release evidence if candidate lineage changes

### Map / environment change
Read:
- AAA_VISUALS_ANIMATION_GUIDE.txt
- VISUAL_OVERHAUL_PLAN.txt
- PHASE_ATTENTION_BUDGET.txt
- MULTI_EXPERT_PREMIUM_REVIEW.txt Environment / Lighting / PBR / Technical Art sections

Mandatory validation:
- spawn view
- route readability
- hazard readability
- Low/Medium/High
- Android
- no new safe spot

### Animation change
Read:
- AAA_VISUALS_ANIMATION_GUIDE.txt
- GAME_FEEL_UX_GUIDE.txt
- MULTI_EXPERT_PREMIUM_REVIEW.txt Animation / Motion sections

Rule:
authored R15 clips are now the priority for key moments; procedural layers remain additive.

### VFX / camera change
Read:
- PHASE_ATTENTION_BUDGET.txt first
- AAA_VISUALS_ANIMATION_GUIDE.txt
- GAME_FEEL_UX_GUIDE.txt

Rule:
if danger intensity rises, decorative intensity falls.

### UI / UX change
Read:
- GAME_FEEL_UX_GUIDE.txt
- PHASE_ATTENTION_BUDGET.txt
- MULTI_EXPERT_PREMIUM_REVIEW.txt UX / Mobile / Human Factors / Accessibility

Mandatory:
- narrow Android layout
- touch targets
- critical controls unobstructed
- FR/EN
- ReduceMotion if motion exists

### Social change
Read:
- SOCIAL_EXPERIENCE_PLAN.md
- PHASE_ATTENTION_BUDGET.txt
- GAME_FEEL_UX_GUIDE.txt
- MULTI_EXPERT_PREMIUM_REVIEW.txt Social section

Rules:
- voluntary
- calm phases
- no gameplay/economy advantage
- one primary social CTA per moment where possible

### Economy / monetization
Read:
- EXPERIENCE_MASTER_PLAN.md
- MULTI_EXPERT_PREMIUM_REVIEW.txt Economy / Monetization
- RELEASE_CHECKLIST.md

Hard rule:
no pay-to-win, no purchase pressure after failure.

### Performance change
Read:
- AAA_VISUALS_ANIMATION_GUIDE.txt
- MULTI_EXPERT_PREMIUM_REVIEW.txt Technical Art / Performance
- RELEASE_CHECKLIST.md

Mandatory evidence:
- real device for final certification
- frame pacing, not only average FPS
- long-session stability

### Release work
Read only after implementation freezes:
- RELEASE_CHECKLIST.md
- QUALITY_OWNERSHIP_EVIDENCE.txt
- PERFECTION_HARMONIZATION_MATRIX.txt
- current dated quality audit

Do not add new features during release certification except release-blocking fixes.

## 3. Documentation lifecycle

Every document is one of four types:

### STANDARD
Defines rules that remain valid until intentionally changed.
Examples:
- GAME_FEEL_UX_GUIDE.txt
- AAA_VISUALS_ANIMATION_GUIDE.txt
- PHASE_ATTENTION_BUDGET.txt
- MULTI_EXPERT_PREMIUM_REVIEW.txt

### PLAN
Tracks work and priorities.
Examples:
- EXPERIENCE_MASTER_PLAN.md
- VISUAL_OVERHAUL_PLAN.txt
- SOCIAL_EXPERIENCE_PLAN.md
- PUBLIC_PRESENTATION_PLAN.txt

### EVIDENCE
Records proof tied to a build/lineage.
Examples:
- RELEASE_CHECKLIST.md
- QUALITY_OWNERSHIP_EVIDENCE.txt

### SNAPSHOT
Represents a dated assessment and must eventually be superseded.
Example:
- CURRENT_QUALITY_AUDIT_2026-10-06.txt

## 4. Anti-drift rules

- Never copy a rule into a second file if a link/reference is enough.
- If a rule changes, update the canonical STANDARD first.
- A PLAN may say "done", but RELEASE_CHECKLIST decides whether it is proven.
- A test passing in CI does not prove visual/tactile quality.
- A screenshot does not prove performance.
- A desktop test does not prove Android.
- A design intention does not prove player comprehension.
- A historical release SHA never certifies a new SHA.
- "AAA-like" is a target quality bar, not a claim that replaces evidence.

## 5. Endgame process

When the current quality audit shows all principal disciplines at >=4 potential maturity:

1. stop feature expansion;
2. close/merge/deprecate stale branches and PRs;
3. run deletion/redundancy pass;
4. run phase-attention harmonization;
5. compare all four arenas;
6. compare all eleven disasters;
7. run fresh-eyes review;
8. run authenticated Studio E2E;
9. run Android + desktop;
10. run persistence/rejoin;
11. run long soak;
12. run small public alpha;
13. fix observed P0/P1 issues only;
14. re-certify exact release lineage;
15. freeze RC;
16. produce final public presentation assets;
17. publish;
18. smoke test immediately after publish.

## 6. Current strategic direction

As of 2026-10-06, the project should prioritize:

- proof over feature count;
- authored animation over more procedural motion;
- real PBR Hero assets over more primitive-detail density;
- original/licensed audio over additional audio logic;
- attention arbitration over additional HUD layers;
- Android validation over desktop-only polish;
- harmonization over expansion;
- player evidence over internal assumptions.

This index must be updated whenever a new canonical production document is added.
