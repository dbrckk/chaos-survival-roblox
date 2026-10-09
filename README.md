# Chaos Survival — Roblox

Fast multiplayer disaster-survival game built with Luau + Rojo.

## Implemented

- Runtime-generated lobby and arena
- Server-authoritative round loop
- 11 modular disasters
- 3-choice disaster voting
- Double Chaos combinations
- Coins, XP, levels, wins and games played
- DataStore persistence
- Mobile-friendly HUD
- Daily login rewards and streaks
- Daily quests with persistent progress and automatic rewards
- Server-side vote rate limiting
- Persistent cosmetic inventory with level unlocks
- Coin-funded cosmetic shop with server-authoritative purchases
- 17-item cosmetic catalogue with rarity tiers, four arena-mastery GOLD rewards, Founder cosmetics and Hyper Neon cosmetics
- Independent persistent trail + aura loadout slots with automatic migration from legacy saves
- Server-authoritative cosmetic equipment with combinable trails, auras, lighting and highlights
- Persistent long-term achievements with server-side rewards
- Persistent disaster + arena mastery with Rookie/Bronze/Silver/Gold/Elite tiers
- Weekly challenges, collection log and visible post-round next-goal progression
- Mobile achievements progress panel and unlock notifications
- Solo Rush mode with faster rounds, solo reward bonus, instant round end on elimination and AI Survivors that fill sparse servers
- Elimination tracking that prevents respawns from being counted as survival
- Server-side retention and gameplay analytics segmented by Solo/Multiplayer
- Economy analytics for Coins sources, daily rewards, quests and achievements
- Onboarding funnel tracking from join to first survival and first Chaos Shard pickup
- Contextual first-session coach covering vote, positioning, survival and optional shard collection
- 4 rotating arena layouts with no immediate repeat: Classic Grid, Tower Run, Crossroads and Orbital Ring
- Variant-specific hero landmarks, midground masses, understructures, focal lighting, material language and functional service props
- Animated personal round-result feedback with survival, streak, shard and close-call breakdown
- Compact live round-focus HUD with Chaos intensity and shard count
- Final-five-second danger timer feedback
- Server-side reward handling
- Per-disaster visual identities with Double Chaos color blending
- Progressive round-intensity director with solo/Double Chaos safety caps
- Hazard cadence, arena VFX and audio mix react to escalating round intensity
- Dynamic neon arena beacon reacting to active chaos
- Procedural premium lobby hub with neon gate and title signage
- Premium procedural arena treatment with metal spawn pads, neon platform underglow and edge beacons
- Adaptive client-side world polish that rebuilds correctly across arena swaps and scales down on weaker devices
- Responsive body/camera game feel with landing, impact, launch, turn/brake feedback, READY anticipation, coyote time and jump buffering
- Live multiplayer vote counts and leading-choice highlight
- Mobile spectator mode after elimination with live survivor/time context, stable survivor switching and low-allocation hazard glyphs
- Chaos Shards: optional server-authoritative risk/reward pickups with daily-quest integration
- Close-call / near-miss feedback with per-round tracking
- Critical-health clutch-survival feedback and analytics
- XP progress bar and level-up celebration
- Session survival streaks with capped coin bonuses
- First-session onboarding banner
- Reactive music and SFX with a distinct audio cue for every disaster
- Map-specific 3D ambience plus material-aware local footsteps and landing treatment
- Automatic countdown, victory, elimination, reward, level-up and UI sounds
- Real-engine gameplay matrix: every arena × every disaster + every allowed Double Chaos pair
- Four-client Studio E2E harness with virtual UI clicks, movement, voting, joins and leaves
- AI Survivor animation state blending (idle/walk/run/jump/fall) and map-aware/hazard-aware navigation
- 71 engine specs assigned exactly once across Open Cloud CI shards
- No paid assets required

## Current disasters

1. Rising Lava
2. Meteor Shower
3. Moon Gravity
4. Disappearing Platforms
5. Tornado
6. Freeze Pulse
7. Bomb Rain
8. Speed Surge
9. Blackout
10. Shrinking Arena
11. Jump Shock

## Run locally

1. Install Roblox Studio.
2. Install Rojo.
3. Clone this repository.
4. Run `rojo serve` from the repository root.
5. In Roblox Studio, connect the Rojo plugin to `localhost:34872`.
6. Press **Play**.

For DataStore tests in Studio, use a test experience and enable:

**Game Settings → Security → Enable Studio Access to API Services**

## Release candidate

- Final certification checklist: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
- Authenticated Studio/device report template: [studio/PLAYTEST_REPORT_TEMPLATE.md](studio/PLAYTEST_REPORT_TEMPLATE.md)
- Change history: [CHANGELOG.md](CHANGELOG.md)
- Rollback procedure: [ROLLBACK_RUNBOOK.md](ROLLBACK_RUNBOOK.md)
- Manual **Release Candidate Gate** workflow: verifies Build Validation + Open Cloud on the exact SHA and emits a release-evidence artifact without publishing.
- Roblox publication workflow refuses uncertified SHAs and archives publish metadata.

## Product direction

Automated Roblox-engine coverage validates the core gameplay matrix on every push. The project is in release-candidate hardening: the remaining launch gates are an authenticated Studio visual/touch pass, Android + desktop soak/performance validation, persistence/rejoin validation, a small real-player alpha, and final public-page assets.

Monetization infrastructure is now present but remains opt-in and cosmetic-only. Paid offers stay hidden until real Roblox Game Pass IDs are configured as DataModel attributes named `SupporterPassId` and `NeonPackPassId`. The paid service never modifies survival power, movement, health, round rewards or progression rates.

Recommended launch pricing is intentionally low-friction (for example 39–79 Robux per cosmetic/supporter pass), but the live price is always read from Roblox MarketplaceService rather than hard-coded in the client. Final prices should be set in Creator Dashboard only after the authenticated device playtest is clean.

## Architecture

```
src/
├── client/
├── server/
│   ├── Disasters/
│   ├── MapBuilder.lua
│   ├── PlayerData.lua
│   └── init.server.lua
└── shared/
    └── Config.lua
```


## Automated playtesting

The default CI uses Roblox Open Cloud Engine Tests and currently covers all arena/disaster combinations plus every allowed Double Chaos pair in a real Roblox DataModel.

A separate four-client Studio E2E harness is included under `studio/`. It automates UI clicks, voting, movement, staggered joins and client leave behavior using StudioTestService and VirtualInput. Roblox Studio requires a logged-in user session, so the GitHub Studio workflow is manual and targets an authenticated self-hosted Windows runner.

## Integrated visual and locomotion candidate (2026-10-08)

This **unreleased candidate** reconciles PRs #12–#16 with the already merged spectator fix (#11) and Open Cloud retry hardening (#17):

- Chaos Showtime: six R6/R15 emotes, a holographic dance floor, DJ architecture, a neon crown and accessible narrow-screen mobile controls.
- Four original arena landmarks: Classic radar, Towers maintenance elevator, Crossroads transit signage and Orbital gyroscope.
- Unique meteor and bomb impact fragments, included in visual performance telemetry.
- Event-driven blast/near-miss/landing reactions on eligible living players and AI bots; spectator/lobby avatars excluded.
- R15 sprint starts, stop skids, sharp pivots, foot planting, takeoff and fall bracing with transient floor cues.

All added content is cosmetic only. No speed, jump, damage, server authority, physics, or monetization changes. Full Studio and real Android performance/gameplay playtests remain required before release.

- Late map-replication resilience: lobby floor and arena base visual builders now watch nested map parts and arena identity attributes instead of relying on container arrival order.

- Cosmetic hazard-impact events also reach spectating clients; visible bursts are filtered by spectator camera range, while movement/body feedback remains disabled for nonparticipants.
