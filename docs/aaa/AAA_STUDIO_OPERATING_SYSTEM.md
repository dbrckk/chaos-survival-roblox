# Chaos Survival — AAA Studio Operating System

## Purpose

This document turns the project into a multi-discipline review process. No major feature is considered complete because it "works" or because one person likes it. Each area is reviewed from the perspective of a senior specialist, then reviewed again for cross-discipline coherence.

The target is not literal console-AAA production scale. The target is **premium AAA-like craft within Roblox and the project's real constraints**: strong art direction, excellent responsiveness, clear design, technical reliability, mobile performance, accessibility, social value, fair monetization and release discipline.

## Non-negotiable product pillars

1. **Readable chaos** — the game may look intense, but never confusing.
2. **Immediate control** — movement, jump, pad use and reactions must feel responsive.
3. **Memorable stories** — every session should be capable of producing close calls, shared victories, funny failures or comeback moments.
4. **Solo is a real mode** — sparse servers must still feel alive and complete.
5. **Social without pressure** — sharing/inviting happens after emotional value exists.
6. **Fairness first** — no paid gameplay power and no hidden loss of agency.
7. **Mobile is first-class** — Android is part of the definition of done.
8. **Performance is visual quality** — a beautiful frame that stutters is not premium.
9. **Consistency beats feature count** — fewer coherent systems beat many disconnected systems.
10. **Every system must earn its complexity.**

## Department ownership

Every significant change must have a primary owner and at least one reviewer from another discipline.

| Department | Primary question |
|---|---|
| Creative Direction | Does this strengthen a coherent identity? |
| Level Design | Does the space create readable, interesting decisions? |
| Gameplay Systems | Does this improve the core loop without unfairness? |
| Balance | Is challenge skillful, recoverable and consistent? |
| Game Feel | Does the action feel immediate, physical and satisfying? |
| Animation | Does motion communicate weight, intent and state? |
| VFX | Does spectacle improve understanding instead of hiding it? |
| Audio | Can the player hear state, danger, impact and reward clearly? |
| UI/UX | Can a new player understand and act with low cognitive load? |
| Accessibility | Is essential information preserved across different needs/settings? |
| Mobile | Does the experience remain comfortable and controllable on touch? |
| AI | Do bots feel plausible without cheating or pretending to be humans? |
| Social | Does the game create shared rituals and stories? |
| Progression/Retention | Does the player have meaningful reasons to continue? |
| Economy/Monetization | Is value clear, fair and non-P2W? |
| Engineering | Is the implementation maintainable and deterministic where required? |
| Networking/Security | Is authority correctly server-side and abuse-resistant? |
| Data/Persistence | Are progress and migrations safe? |
| Performance | Is frame-time/memory behavior acceptable on target hardware? |
| Analytics | Can we tell where players understand, fail, leave and return? |
| QA | Can the build survive systematic adversarial testing? |
| Live Ops | Can content, balance and incidents be managed after launch? |
| Store/Marketing | Does public presentation truthfully communicate the strongest experience? |
| Release Management | Can we ship, verify and roll back safely? |

## Review lifecycle

Every substantial feature moves through:

**PROBLEM → SPECIALIST DESIGN → IMPLEMENTATION → LOCAL VALIDATION → CROSS-DISCIPLINE REVIEW → DEVICE TEST → METRICS/PLAYTEST → HARMONIZATION → RELEASE**

### 1. Problem statement
Before implementation, write:
- player problem;
- target behavior;
- intended emotion;
- success metric;
- failure mode;
- mobile cost;
- performance cost;
- accessibility risk;
- systems touched.

If the problem cannot be stated clearly, do not code yet.

### 2. Specialist review
The owning discipline checks its dedicated guide.

### 3. Cross-discipline review
At least one adjacent specialist asks what the feature damages elsewhere.

Examples:
- VFX reviewed by gameplay readability.
- animation reviewed by control responsiveness.
- economy reviewed by fairness/retention.
- social reviewed by UX and analytics.
- level design reviewed by AI navigation and mobile camera.

### 4. Device verification
Automated success is not enough for anything visual, tactile, camera-related or performance-sensitive.

Required when relevant:
- Android real device;
- desktop;
- authenticated Studio;
- touch controls;
- Low/Medium/High VFX;
- ReduceMotion.

### 5. Evidence
A claim such as "finished", "optimized", "clear" or "premium" must have evidence:
- test;
- screenshot/video;
- profiling;
- playtest observation;
- analytics;
- comparison against acceptance criteria.

## Quality score

Each department scores its domain from 0–10:

- **0–3** broken/prototype.
- **4–5** functional but visibly unfinished.
- **6** acceptable Roblox baseline.
- **7** polished.
- **8** premium.
- **9** exceptional and coherent.
- **10** no meaningful improvement found after specialist + adversarial review.

Release target:
- no domain below **8**;
- core domains (Gameplay, Game Feel, UX, Visual, Audio, Performance, QA) at **9** or better;
- no unresolved P0/P1;
- Android and real-player evidence complete.

A score of 10 is temporary: it means "no currently identified improvement worth its cost", not "perfection exists forever".

## Perfect-candidate state

The project may be called **PERFECT-CANDIDATE** only when:

- all specialist scorecards meet target;
- all release gates pass on the same lineage;
- no known P0/P1;
- no contradictory duplicate systems;
- first-session blind test succeeds;
- solo session succeeds;
- 2–4 human session succeeds;
- 30–60 minute Android soak succeeds;
- persistence/rejoin succeeds;
- small public alpha has no blocking pattern;
- storefront assets match the real game;
- monetization remains cosmetic/fair;
- final harmonization pass finds no major inconsistency.

## Mandatory harmonization after "completion"

When every department says "done", stop adding features.

Run a dedicated harmonization phase:
1. remove duplicated systems;
2. normalize terminology;
3. normalize color/material/audio language;
4. normalize timing/easing;
5. reduce over-signaling;
6. align difficulty pacing;
7. align progression pacing;
8. align UI hierarchy;
9. align map silhouettes;
10. align sound loudness;
11. align bot behavior with human expectations;
12. remove features that add complexity without enough value.

The final pass should often **remove or simplify** more than it adds.

## Divergent-thinking review

After the normal roadmap, run the "different lens" audit:

- **No-HUD test** — can the world communicate danger and navigation?
- **Muted test** — can the game be played without audio?
- **Audio-only reasoning test** — do major hazards have distinct sound signatures?
- **One-hand observation** — does mobile UI conflict with thumb zones?
- **Color-blind test** — are shapes/timing enough without hue?
- **Low-VFX test** — is the game equally understandable?
- **Bad-network thought experiment** — which systems fail if events arrive late?
- **New-player amnesia test** — assume zero Roblox genre knowledge.
- **Expert boredom test** — what remains interesting after 100 rounds?
- **Solo loneliness test** — does one human still feel part of a living scene?
- **Group comedy test** — what mechanics generate stories friends retell?
- **Streamer/screenshot test** — are high-value moments visually legible at a glance?
- **Inversion test** — what would make this feature annoying? Remove those properties.
- **Subtraction test** — if this feature vanished, would the game become clearer?
- **Worst-device test** — what survives when effects are aggressively reduced?
- **30-minute fatigue test** — what becomes irritating after repetition?

## Documentation hierarchy

1. `AAA_STUDIO_OPERATING_SYSTEM.md` — overall production process.
2. Specialist department guides in `docs/aaa/`.
3. `AAA_VISUALS_ANIMATION_GUIDE.txt` — detailed visual/animation implementation.
4. `GAME_FEEL_UX_GUIDE.txt` — detailed feel/UX implementation.
5. `EXPERIENCE_MASTER_PLAN.md` — product roadmap/state.
6. `VISUAL_OVERHAUL_PLAN.txt` — visual execution tracking.
7. `SOCIAL_EXPERIENCE_PLAN.md` — social product direction.
8. `RELEASE_CHECKLIST.md` — final certification.

## Rule for future work

For every future "continue":
1. inspect current HEAD and CI;
2. identify the weakest scored department;
3. fix the highest-impact weakness;
4. update evidence/documentation;
5. re-score;
6. repeat until Perfect-Candidate;
7. then harmonize instead of expanding scope.
