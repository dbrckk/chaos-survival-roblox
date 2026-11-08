# G5 – Crowd-safe collapse warning floor detection

## Baseline

Branch from `main` commit `b0a33032edc821556050b69d37ad62d7510e776c` (after the merged consecutive-impact reaction handoff PR #700).

## Defect

The disappearing-platform reaction in `AISurvivorService.disappearingPlatformEscape` used a downward `workspace:Raycast` that excluded **only the reacting NPC's own rig**. In a crowded eight-contestant round, a different bot or human character standing close to the floor-probe origin can be intersected first. The warning platform then fails the authoritative `part.Parent.Name == "Platforms"` and `CollapsePhase == "Warning"` checks, and the bot delays/rejects an otherwise required physical collapse escape.

The previously merged #698 fix already applied mobile-character exclusions to Meteor/Bomb emergency **support** probes, but did not cover **collapse-warning detection**.

## Source correction

- Extract the existing #698 emergency-floor `RaycastParams` construction into a single shared `emergencyFloorProbeParams(record)` helper.
- Exclude the server-owned NPC folder (or own model fallback) plus currently connected `Player.Character` models.
- Require `RespectCanCollide=true`, preserving actual physical floor, platform phase and walkability checks. Decorative objects and other avatars must not replace the real collidable warning platform.
- Reuse the helper for both the already validated Meteor/Bomb support probes and the disappearing-platform floor detection.
- Keep the original one collapse raycast, its 7-stud length, previous hazard gating, original personality reaction latency and physically reached deck escape rules. No additional raycast, scan of the Workspace, changed physics, teleport, or client-side authority.

## Real-engine acceptance matrix

| Situation | Expected |
| --- | --- |
| Bot standing on `CollapsePhase="Warning"` platform with another NPC close to the downward probe | The ray sees the real platform; bot reacts after its existing delay, not to the other NPC rig |
| Human participant near or partly over the probe during a platform warning | Player model cannot mask the warning part |
| Platform warning visible but the physical floor is already non-collidable | No fabricated support or direct bot motion onto a non-solid floor |
| No collapse warning | No new emergency escape target |
| Multiple Meteor/Bomb warnings with several standing human avatars | Existing #698 candidate and floor probes keep their behavior, using the shared exclusion helper |
| Elevated sky-platform retreat | Existing same-network/physically connected neighboring deck logic remains intact |
| Eight participants on Android with concurrent collapse and impact warnings | Monitor actual bot movement, false stays on collapsing decks, FPS and existing brain-pass latency telemetry |

## Verification status

11 source invariants were checked before writing: shared helper ordering, correct exclusion list, collidable support, both callers, unchanged raycast sites, exact server warning phase, unchanged reaction gate and supported deck validation. **Roblox Engine and Android execution have not been run on this commit.** The branch does not automatically publish to the Roblox live experience. Follow the repo's owner-controlled release validation gates at the relevant milestone.

## Authoritative disaster lifecycle cross-check

Reviewed `src/server/Disasters/DisappearingPlatforms.lua` on `main`: `eligiblePlatforms` only selects initially `CanCollide` physical decks, then `D.start` sets `CollapsePhase="Warning"` without disabling collision. **Only after** the 1.35-second shared warning does it set `CollapsePhase="Gone"`, transparency to 1, and `CanCollide=false`. Therefore `RespectCanCollide=true` still detects genuine warning surfaces and refuses floors once physically gone. This cross-check confirms the source contract, not a completed engine test.
