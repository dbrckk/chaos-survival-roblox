# Lobby core orbit — streaming recovery and snapshot resilience

The client-owned lobby core consists of the existing 3/5/7 floating shards
for Low/Medium/High quality tiers plus Medium/High cores. No server-owned
collider, remotes, gameplay, timers or rewards are altered.

## Fixed issues (12 October 2026)

- The lobby core previously indexed `state.phase` directly. A missing or
  malformed RoundState snapshot could terminate its cosmetic event callback
  and leave the previous visual phase active. It now uses a safe shared
  snapshot parser, keeping normal phase strings unchanged.
- GeneratedMap can replicate before Lobby.Decor.CenterPlatform. Previously
  the core center was only calculated on initial build or a graphics-tier
  rebuild; a late platform could leave existing art anchored around the
  hardcoded Config.LobbyCenter. The existing low-frequency orbit loop now
  resolves the current authored platform center and recovers automatically
  after platform arrival, movement or removal. No new event connection,
  loop, part, trail, light, or GPU effect is created.

Core B1 regression checks malformed state, all supported phases, late map
containers, wrong-type placeholders, platform movement/removal and fallback.
The script retains the original tiers, part budgets and ReduceMotion behavior.

## Acceptance still required

Inspect delayed lobby CenterPlatform streaming in Roblox Studio and physical
Android, including map swaps, Low/Medium/High and ReduceMotion. Compare
actual frame time and visual readability from mobile camera positions.
No Studio/Android run or FPS metric has been performed here.
