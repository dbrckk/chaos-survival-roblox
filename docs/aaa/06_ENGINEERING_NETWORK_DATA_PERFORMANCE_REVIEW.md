# Department Review 06 — Engineering, Networking, Security, Data & Performance

## Specialist mindset

Review as:
- principal gameplay engineer;
- network/server engineer;
- security/abuse reviewer;
- data/persistence engineer;
- mobile performance engineer;
- build/release engineer.

## Engineering principles

1. Server authoritative for anything affecting fairness/economy.
2. Client owns presentation, not truth.
3. Shared pure modules own reusable rules.
4. Every temporary object has cleanup.
5. Every async path has failure behavior.
6. Every expensive loop has a measured reason.
7. Every persistent schema change has migration/fallback.
8. Build must be reproducible.

## Authority review

Server must own:
- rewards;
- purchases/grants;
- votes where fairness matters;
- health/damage;
- round state;
- challenge completion;
- mastery;
- progression;
- social reaction rate limits where abused.

Client may own:
- camera;
- cosmetic-only VFX;
- local presentation;
- local quality scaling.

Never trust client-supplied reward amounts or completion claims.

## Remote-event review

For every RemoteEvent/Function:
- payload schema;
- type validation;
- range validation;
- rate limit;
- player ownership validation;
- phase/state validation;
- failure behavior;
- analytics only after validation.

## Security/abuse review

Think like an exploiter:
- spam remote;
- malformed payload;
- huge number;
- negative number;
- stale phase;
- replay event;
- impersonated user id;
- purchase spoof;
- race condition;
- rapid reconnect.

Gameplay should fail closed where fairness is involved.

## DataStore review

Required:
- default schema;
- load failure behavior;
- temporary-session messaging;
- save retry/backoff;
- migration;
- idempotent grants;
- purchase restoration;
- rejoin test;
- concurrent-session considerations.

Never silently imply persistence when saving is unavailable.

## Code architecture review

Red flags:
- one file owns unrelated domains;
- duplicate constants;
- duplicate localization;
- duplicate phase logic;
- repeated polling instead of events;
- circular dependencies;
- UI knowing server internals unnecessarily.

Prefer:
- pure shared rules;
- narrow services;
- event-driven updates;
- stable IDs over display strings.

## Performance budget

Audit:
- RenderStepped;
- Heartbeat;
- GetDescendants scans;
- dynamic lights;
- particles;
- trails/beams;
- temporary Instances;
- raycasts;
- pathfinding;
- AI brain frequency;
- network event frequency;
- UI layout churn.

## Mobile performance acceptance

Real device:
- 30 FPS stable floor;
- 45–60 desired;
- no repeated major frame spikes;
- no monotonic memory leak;
- acceptable thermal behavior;
- stable after multiple arena swaps;
- stable Double Chaos;
- stable result VFX.

Frame time:
- 60 FPS ≈ 16.67 ms;
- 30 FPS ≈ 33.33 ms.

## Quality tiers

Every expensive visual must state:
- Low;
- Medium;
- High;
- ReduceMotion effect.

Low must preserve game information.

## Cleanup review

For each system ask:
- what happens on arena replacement?
- player death?
- phase change?
- respawn?
- disconnect?
- VFX quality change?
- timeout?
- script destruction?

No orphan connections/Instances.

## Engineering scorecard /10

- architecture;
- authority/security;
- networking;
- persistence;
- async safety;
- cleanup;
- performance;
- mobile stability;
- testability;
- maintainability.

Security, persistence and mobile stability cannot be below 9 for release.
