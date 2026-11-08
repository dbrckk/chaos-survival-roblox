# G5 — Shared emergency refuge spacing (2026-11-08)

## Source baseline and scope

Based on `main` commit `8db6a00a448c744a39cc0f8a2b6fddf532b5c44a`, following the merged navigation, Meteor/Bomb corridor, and physical escape support fixes (#696–#698). This stage changes **only** the physical Meteor/Bomb emergency heading selection in `AISurvivorService.saferThreatEscape`. It is not proof of Roblox Studio, Cloud Engine, Android, or public-place validation.

## Defect

The server samples six real physically walkable escape directions and selects the one with the fewest unsafe impact landings and highest individual route score. In a populated round, several bots may independently select the same safe corner or doorway, collide with other players, and obstruct each other. This is a **coordination** problem: each individually good destination can become worse when many R15 characters converge there.

## Implementation

- Once per bounded escape route calculation, sample live R15 roots of other in-round, living bots and real non-eliminated `RoundParticipant` players.
- Treat another bot's `escapeTarget` as a **short-lived soft reservation** only while its warning still exists and the original `escapeUntil` remains active.
- Only consider participants within nearby horizontal range and **six studs of vertical elevation**. A player on a sky bridge must not repel a floor bot far below.
- For each existing physically supported candidate, subtract a **capped, soft occupancy penalty (maximum 14)** based on how close its landing is to real nearby participants and planned bot landings.
- Preserve mandatory physical footing, and now select by lexicographic tiers: (1) fewest live Meteor/Bomb impact *landings*, (2) fewest actual impact *corridor crossings*, (3) prior physical terrain/sweep/comfort score including the soft crowd penalty.
- Reuse the existing brain timestamp for the brief reservation TTL and existing `Players` / `records` collections; no new raycast sites, path requests, timers, teleportation, collisions disabled, special speed, or server/client responsibility changes.

Even if all six valid headings remain crowded, choose the least unsafe physically supported one; do not turn a crowd penalty into an unconditional freeze.

## Engine acceptance matrix

| Case | Expected |
| --- | --- |
| Two or more bots evade the same Meteor into several equally safe physical floor landings | Bots can choose different low-occupancy headings; compare actual collisions and path completion |
| One only genuinely supported escape landing, other bots near it | All may use it; no invented void destination or forced idle because of crowding |
| One clear physical landing has one impact footprint, another crowded landing has zero | Zero-exposure landing **always** wins, regardless of crowd penalty |
| Two landings equally clear, but one corridor crosses an existing impact ring | Prefer the path with fewer impact crossings |
| A real human stands at a suggested refuge | Bot can prefer another equally safe landing without treating the avatar as authoritative ground |
| A player is directly above on a different sky elevation | No cross-level crowd penalty |
| Another bot's previous warning expired | Its old `escapeTarget` is ignored as a reservation; only its real current position matters |
| Eight total participants during overlapping Meteor/Bomb + active sweep | No additional raycasts, monitor AI pass time/FPS and successful physical escapes on Android |
| No nearby living competitors | The original six-heading route scores determine the escape; no new random jitter |

## Verification / release gate

Source-only structural checks verified candidate count, unchanged support-raycast sites, one-time crowd collection, current-round human/bot eligibility, per-round short-lived route reservations, level separation, capped crowd scoring and safety-tier priority. Further verification requires real Roblox Engine path observation and Android FPS in a live eight-participant round. The current code branch is **not merged** and **not published**.
