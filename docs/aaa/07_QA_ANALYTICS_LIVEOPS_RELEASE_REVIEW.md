# Department Review 07 — QA, Analytics, Live Ops, Store & Release

## Specialist mindset

Review as:
- QA lead;
- test automation engineer;
- data analyst;
- live-ops producer;
- incident manager;
- release manager;
- store/marketing creative lead.

## QA philosophy

QA is not "does it launch?"
QA attempts to disprove that the game is ready.

Every feature requires:
- happy path;
- invalid path;
- timing/race path;
- mobile path;
- low-quality path;
- rejoin path where relevant.

## Test pyramid

### Static/build
- Luau syntax;
- Rojo build;
- hygiene guards;
- fair-play guards;
- protocol contracts.

### Pure engine specs
- deterministic rules;
- balance matrices;
- localization;
- social rules;
- progression.

### Roblox Open Cloud
- real DataModel behavior;
- gameplay matrix;
- engine contracts.

### Studio E2E
- UI clicks;
- multi-client;
- voting;
- joins/leaves;
- movement;
- visual state.

### Physical device
- touch;
- readability;
- performance;
- heat;
- battery;
- motion comfort.

### Public alpha
- real behavior;
- quit points;
- social dynamics;
- unexpected exploits.

## Bug severity

P0:
- crash;
- data loss;
- exploit enabling power/economy abuse;
- unable to play;
- unavoidable repeated death.

P1:
- major confusion;
- broken touch;
- major unfairness;
- severe FPS degradation;
- broken persistence path.

P2:
- polish issue;
- minor overlap;
- isolated visual mismatch.

Release: zero known P0/P1.

## Analytics questions

Analytics must answer decisions, not merely collect events.

Core funnel:
join → loaded → first action → vote → round → death/survival → second round → 10 min.

Segment:
- solo/multi;
- new/returning;
- device;
- VFX tier;
- arena;
- disaster;
- Double Chaos.

Measure:
- death reasons;
- quit-after-death;
- second-round conversion;
- invitation funnel;
- share funnel;
- mastery/progression use;
- economy source/sink;
- FPS distribution.

## Metric interpretation rule

Never optimize a metric alone.

Example:
higher session length may be bad if caused by waiting.
higher invite clicks may be bad if caused by intrusive UI.
higher monetization may be bad if retention/fairness falls.

Use metric + qualitative playtest together.

## Live Ops readiness

Before public scale:
- rollback commit/tag known;
- incident owner;
- disable switches for paid features if possible;
- analytics health checked;
- content update procedure documented;
- balance hotfix procedure known.

## Storefront truthfulness

Icon/thumbnails/trailer must:
- use actual game visual language;
- avoid fake graphics impossible in gameplay;
- show player + hazard + recognizable arena;
- communicate chaos/survival quickly;
- remain readable on mobile.

Create marketing only after visual/device certification.

## Release-candidate freeze

When RC starts:
- no speculative features;
- only blocker fixes;
- every fix re-runs relevant gates;
- document exact commit;
- preserve rollback.

## QA scorecard /10

- automated coverage;
- engine coverage;
- Studio E2E;
- device coverage;
- persistence/rejoin;
- exploit/adversarial test;
- analytics usefulness;
- live-ops readiness;
- storefront integrity;
- rollback/release discipline.

No release if any core gate lacks evidence.
