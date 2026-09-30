# Chaos Survival — Roblox

Fast multiplayer disaster-survival game built with Luau + Rojo.

## Implemented

- Runtime-generated lobby and arena
- Server-authoritative round loop
- 10 modular disasters
- 3-choice disaster voting
- Double Chaos combinations
- Coins, XP, levels, wins and games played
- DataStore persistence
- Mobile-friendly HUD
- Daily login rewards and streaks
- Daily quests with persistent progress and automatic rewards
- Server-side vote rate limiting
- Persistent cosmetic inventory with level unlocks
- Server-authoritative cosmetic equipment and visible player trails
- Persistent long-term achievements with server-side rewards
- Mobile achievements progress panel and unlock notifications
- Solo Rush mode with faster rounds, solo reward bonus, and instant round end on elimination
- Elimination tracking that prevents respawns from being counted as survival
- Server-side retention and gameplay analytics segmented by Solo/Multiplayer
- Economy analytics for Coins sources, daily rewards, quests and achievements
- Onboarding funnel tracking from join to first survival
- Server-side reward handling
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

The next milestones are:

- round-end polish and feedback
- anti-exploit sanity checks
- daily quests and streak rewards
- cosmetic inventory
- analytics hooks
- retention balancing using live analytics
- monetization only after retention is validated

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
