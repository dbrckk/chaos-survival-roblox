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
- Nine earnable trails/auras plus two optional premium cosmetic rewards
- Server-authoritative cosmetic equipment with trails, auras, lighting and highlights
- Persistent long-term achievements with server-side rewards
- Mobile achievements progress panel and unlock notifications
- Solo Rush mode with faster rounds, solo reward bonus, and instant round end on elimination
- Elimination tracking that prevents respawns from being counted as survival
- Server-side retention and gameplay analytics segmented by Solo/Multiplayer
- Economy analytics for Coins sources, daily rewards, quests and achievements
- Onboarding funnel tracking from join to first survival
- Three rotating arena layouts with no immediate repeat
- Animated personal round-result feedback with reward breakdown
- Final-five-second danger timer feedback
- Server-side reward handling
- Per-disaster visual identities with Double Chaos color blending
- Dynamic neon arena beacon reacting to active chaos
- Procedural premium lobby hub with neon gate and title signage
- Live multiplayer vote counts and leading-choice highlight
- Mobile spectator mode after elimination
- XP progress bar and level-up celebration
- Session survival streaks with capped coin bonuses
- First-session onboarding banner
- Reactive music and SFX with a distinct audio cue for every disaster
- Automatic countdown, victory, elimination, reward, level-up and UI sounds
- Real-engine gameplay matrix: every arena × every disaster + every allowed Double Chaos pair
- Four-client Studio E2E harness with virtual UI clicks, movement, voting, joins and leaves
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

## Product direction

Automated Roblox-engine coverage now validates the core gameplay matrix on every push. The remaining launch gate is a graphical/touch-device Studio pass from an authenticated Studio session, followed by fixes from that pass.

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
