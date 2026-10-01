# Changelog

## 2026-10-01 — Release-candidate game-feel and mobile polish

- Added optional server-authoritative Chaos Shards with coin rewards, daily-quest progress, analytics and round-result breakdown.
- Added compact live round-focus HUD for Chaos intensity and shard progress.
- Added contextual first-session coaching for voting, positioning, survival and shards.
- Added close-call / near-miss feedback, sound, combo display and per-round summary tracking.
- Added critical-health clutch-survival feedback and analytics.
- Improved spectator HUD with live survivor/time context and hid active-player HUD while spectating.
- Added adaptive shard visuals and removed redundant per-frame world-polish work for better mobile performance.
- Fixed procedural world polish so it rebuilds on arena swaps inside the same GeneratedMap.
- Preserved cosmetic-only monetization and server-authoritative gameplay.

All notable changes to Chaos Survival are documented here.

## Unreleased — Release Candidate Hardening

### Gameplay
- 11 server-authoritative disasters with Solo Rush and allowed Double Chaos combinations.
- 4 rotating arena variants with arena-specific geometry, guidance and mobility mechanics.
- Arena-aware Bomb Rain / Meteor targeting and deterministic meteor impact visuals.
- Shrinking Arena keeps platforms aligned with the playable zone.
- Rising Lava includes deterministic contact fallback inside the real lava footprint.
- Near-miss, critical-health, streak and result feedback.

### Reliability
- DataStore retry/backoff, schema normalization, dirty-aware autosaves and shutdown saving.
- Temporary-session protection when persistence is unavailable.
- Cross-server session ownership / stale-save protection and handoff lifecycle.
- Loaded-session guards around progression, cosmetics, quests, achievements and premium grants.
- Reverse-order round cleanup for stacked disaster resources.
- Idempotent player/service setup and serialized player data loads.
- Class-safe RemoteEvent registry.

### Performance
- Adaptive High / Medium / Low VFX quality.
- Client-local hazard visuals and warning animation.
- Distant hazard impact network culling.
- Near-miss throttling.
- Mobility-pad VFX quality updates are event-driven.
- Warning renderer can sleep while idle.
- Concurrent local impact bursts are capped by VFX tier.
- Autosaves are distributed over time.

### Testing / CI
- Luau syntax validation and Rojo place build.
- Real Roblox Open Cloud engine tests, sharded into core / gameplay / matrix suites.
- Every arena × disaster combination and allowed Double Chaos pair covered.
- Fair-play monetization guard.
- Client protocol guards.
- Server service export contract audit.
- Production release-hygiene scan.
- Four-client authenticated Studio E2E harness with viewport, input, voting, movement, late-join state and spectator probes.
- Release-candidate certification checklist and playtest report template.

### Monetization
- Cosmetic-only Game Pass infrastructure.
- Live paid offers remain hidden until real IDs are configured and device/retention gates pass.
- No paid gameplay power or progression multiplier.

## Release policy

A `v1.0.0` tag should not be created until `RELEASE_CHECKLIST.md` passes for the release lineage, including authenticated Studio E2E, physical Android/desktop QA, persistence/rejoin testing and a small public alpha.
