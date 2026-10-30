# Android first minute — nonblocking onboarding and camera ownership

Date: 30 October 2026. **Source-only until exact-SHA milestone and public publisher succeed.**

## Verified source defects
1. `src/client/how-to-play.client.lua` invoked `showGuide(false)` for first-time players as soon as the server entered a quiet lobby. That displayed the entire full-screen `HowToPlayOverlay` with an `Active=true` backdrop. It therefore intercepted initial movement/touch input, competing with `init.client.lua`'s existing contextual `rookieCoach`, even though the owner wants the first 30 seconds to be gameplay-first.
2. `src/client/movement-feel.client.lua` applied walking roll, impact pitch and FOV to `workspace.CurrentCamera` on every valid-avatar frame without checking whether the camera was `Scriptable` or had a foreign `CameraSubject`. When another owner legitimately took over a camera, local footsteps could disturb it.

## Complete original solution
- Full four-step instructions are still reachable via the existing `?` help button and remain dismissible; no existing text, localization, Gamepad option or accessibility UI removed.
- During the eligible first-time quiet lobby only, the same existing help button becomes a bounded 68×48px **AIDE** (French) or **HELP** (other locale) affordance. It does not grab input, cover the view or create an extra GUI. The existing server-aware rookie coaching HUD already explains moving, jumping, voting, hazards and survival without forced reading.
- The affordance returns to the standard 48×48px question mark once the player taps it, the vote opens, READY begins, or an active round/result takes over. Games already played never trigger the hint. If an onboarding guide is voluntarily opened during a round, the previous safe auto-dismissal on a phase transition stays in place.
- Camera movement effects and landing-preview HUD work only when a non-`Scriptable` Roblox camera follows the local Humanoid or a body descendant belonging to the local current character. Spectator/foreign/substitute subjects are left untouched; the existing `CameraFeelBus` and local landing indicator are reset/hidden while they are not owned.
- No new RenderStepped binding, camera event loop, GUI layer, server authority, physics change, RemoteEvent, persistence write, asset, external network service or dependency.

## Detailed completion / native acceptance matrix
| Situation | Expected |
| --- | --- |
| New account in quiet waiting/intermission, data loads | Contextual rookie coach is still visible; AIDE/HELP discoverability; **no automatic full-screen modal**, movement and jump free |
| New account, DataStore failure | Optional help available; same nonmodal intro when `DataLoadFailed=true`, no fake save/reward claims |
| Existing account with previous Games/SessionRoundsPlayed | Ordinary `?` immediately, never forced guide |
| First-time account, vote appears or READY begins | Enlarged help affordance shrinks immediately; player sees actionable voting/arena HUD |
| Manual help tap / close | Full 4-step translated guide opens, close works; button reverts to `?` |
| Switch lobby/round while help is open | Existing phase-transition dismissal prevents blocking an active round |
| Touch phone in 320 / 360 / 400 / 440 px safe widths | No collision between help button, native jump controls, vote card, first-run coach, or touch camera region |
| Camera Scriptable | No local footstep pitch/roll/FOV alteration or hovering landing bracket |
| Camera subject foreign bot/player during respawn/spectate | No local movement motion injected; camera owner keeps control |
| Camera returns to local R6/R15 rig | Normal motion effects and landing guide resume with normal quality limits |
| Accessibility / Low tier | ReduceMotion, audio mute and low graphical budget remain functional; no extra UI parts |

## Release requirements and evidence boundary
- Milestone (not feature-iteration) CI: Build Validation and all five Roblox Open Cloud engine suites on the exact merged `main` SHA, including compatibility with existing movement and first-session specs. No new unit tests.
- At the final hardware gate, inspect true Android/PC pixels and interaction, not simulated images; include first 60 seconds with initial camera and a round transition. Require zero inadvertent modal interception. Confirm frame-time remains within device-specific graphics targets.
- This source patch has **not** been executed on a physical Android device or Roblox Studio as part of its authoring. Code review is not a pass certificate.
- Current proven public baseline: `030e191407ff454a09315c9db66688559e641fff`, publisher https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41095777897. Newer merges #402/#404 and this patch require a separate future verified release.

## Remaining planned work
Following actual Android captures, tune speed-FOV, platform occlusion, landing feedback and thumb ergonomics from measured failures. Avoid blind tuning without real device telemetry. Continue the first flagship arena's four genuinely navigable, hazard-fair routes before multiplying map count.
