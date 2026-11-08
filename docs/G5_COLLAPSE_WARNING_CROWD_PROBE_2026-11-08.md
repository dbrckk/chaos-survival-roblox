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

## Simultaneous impact and elevated collapse: safe refuge ranking

Commit `a24bdb56030cabd4bf5fb52690d037b451b93587` fixes a related high-deck priority error: when several physical neighboring decks exist, `disappearingPlatformEscape` previously chose the **nearest** deck without checking a simultaneous Meteor/Bomb warning. Because collapse is evaluated before `immediateThreat`, the NPC could be sent directly into a live blast footprint.

The neighbor list is unchanged and still requires `platformAvailable`, `safeCollapseNeighbor`, and the original horizontal distance bound of 34 studs. For each physically valid option, rank by:

1. Fewest current Meteor/Bomb final-footprint **landings**.
2. Fewest real Meteor/Bomb warning **route intersections**, using `AISurvivorRules.newImpactIntersectsEscape` and the same cached warnings as regular bot routing.
3. Shortest walk among equally exposed options.

If no impact warnings exist, this produces the original nearest valid neighbor. If no safe physical neighbor exists, the existing urgent hold/multi-hazard fallback remains. No extra raycast, platform directory scan, pathfinding call, speed/physics change or invented support.

### Further acceptance cases

| Case | Expected |
| --- | --- |
| Warned high deck has two physically adjacent solid landings; closer one is covered by a Meteor | Bot chooses the farther unexposed landing |
| Both landings outside the blast, but one walking corridor crosses a Bomb warning | Prefer the corridor with fewer live impact intersections |
| Both alternatives impacted, but one has fewer endpoint warnings | Choose the least-exposed **physically supported** deck rather than freezing |
| No Meteor/Bomb warnings | Preserve prior choice of the nearest real connected, available platform |
| Only neighboring platform collapsed or disconnected | Do not select it, even if its landing would be outside every impact |
| Double Chaos with player models obstructing the floor probe | Correctly detect the actual warning platform and select a real, lower-exposure physical destination |
| Several live impact warnings under Android load | Inspect bot escape target, existing profiler numbers, physical landing and frame rate; source adds no new physics queries |

Source-level safety checks include hazard-priority ordering, original platform support and 34-stud gate, only one platform-folder traversal, unchanged number of raycast sites and return of the selected actual waypoint. This is **not** evidence of runtime validation.

## Integrated G5 batch — physical exits, coordinated shelters and authoritative hazard metadata

This section documents the later **aggregate PR #701**, superseding earlier notes about “no additional raycasts” and “nearest deck” that applied to the original smaller changes only.

### Completed source work

- Centralized the emergency-floor `RaycastParams` exclusion list so human player rigs and NPC rigs cannot mask the real collision surface during collapse warnings, Meteor/Bomb support sampling **or a physically verified sky-gap jump**. No Roblox collision groups or character physics are changed.
- Added a **short commitment (0.42 seconds for a verified exit, 0.32 seconds for a supported partial retreat)** to the actually chosen collapse goal. Reuse requires the same active warning, still-valid collidable support and unchanged Meteor/Bomb warning version. A newly dangerous floor sweep also invalidates the cached route.
- Elevated collapse: require the original same-network `safeCollapseNeighbor`, usable deck, and less-than-34-stud travel. Precompute live Meteor/Bomb final radii once for each real plan. Compare alternatives by *fewest impact-exposed landings*, *fewest impact corridor crossings*, *fewest active grid/cargo sweep crossings*, then *travel cost plus a capped soft occupancy penalty*. Occupancy considers nearby living bots, non-eliminated humans and recent committed bot refuges on similar height; it never blocks the only physically supported exit.
- Ground-level collapse: replace a new random center/tangent move every brain tick with **four authored geometry-derived edge exits** in the warning platform’s own oriented coordinate space. A destination must be off that warned floor, be within the arena and 34-stud bound, and have genuine solid support at the landing and at three bounded corridor samples (30%, 55%, 80% of the path). These samples reduce false-positive support across short missing segments but cannot mathematically guarantee continuous walkability between samples. Use the same hazard tiers and bounded peer-occupancy cost. If every full exit fails but a shorter approach to a real edge is supported, retain **partial physical progress** without claiming the endpoint is safe. If neither exists, hold actual footing rather than sending a bot into unverified void.
- Never apply cosmetic `separateTarget` to a physical collapse escape whose final waypoint was already verified. This prevents an otherwise correct low-floor target from shifting back inside a doomed tile or off an elevated deck.
- Fix **hazard publication ordering** in `src/server/Disasters/Meteors.lua` and `Bombs.lua`: `HazardWarning.configure` now runs **before** `marker.Parent=workspace`, so the `ChildAdded` watcher and every replicated client first see the authoritative `WarningEndSize`, `WarningStartedAt`, `WarningDuration` and `WarningKind`. The actual damage radii, meteor descent and bomb delays are preserved.
- Expose round-reset per-NPC diagnostics: `BotCollapseSafeExitPlans`, `BotCollapsePartialRetreats`, `BotCollapseBlockedPlans`. They count decisions, **not** successful completed escapes.

### Performance and safety accounting

The PR began with **15** `workspace:Raycast(` call sites in `AISurvivorService.lua`; there are now **16**. The single new site is the `physicalFloor` support probe used by up to **four** actual low-ground edge candidates and their partial/midpoint checks. This can execute multiple times, but only **after** identifying a real collidable `CollapsePhase="Warning"` floor and passing the original personal reaction delay. The planned waypoint is reused for 0.32–0.42 seconds when still valid; at most four physical exit candidates are enumerated per recomputation. No additional `Workspace:GetDescendants`, asynchronous path requests, unbounded loops, client-trusted warning data, teleports, speed buffs or immunity are introduced. The true server CPU cost and Android FPS effect have **not** been measured.

### Release acceptance matrix for the full batch

| Scenario | Expected evidence in a real 8-contestant match |
| --- | --- |
| A second bot or human physically masks the collapsing warning floor | The bot recognizes the same real `Warning` deck and begins its normal delayed evacuation |
| Ordinary low platform warns while no extra disaster is active | Bot targets a physically supported exit beyond the actual edge, not an arbitrary new random position every brain pass |
| A ground edge leads to a missing, non-collidable or insufficiently supported surface | Reject that full exit; never send a direct movement command into unverified empty space |
| Full exit is unavailable but an earlier same-deck physical waypoint is safe until collapse | Bot advances toward its nearest real edge without treating the partial waypoint as a confirmed refuge |
| Two connected high refuges, one under a Meteor/Bomb | Prefer the less exposed real deck even when farther or busier |
| Two equally safe neighboring high refuges, one already crowded by real participants | Prefer lower occupancy without forbidding the only real usable deck |
| Collapse warning and grid/cargo sweep activate together | Prefer fewer active sweep intersections after minimizing actual Meteor/Bomb exposure |
| A new sweep band activates during a cached collapse retreat | Recheck its new segment exposure; invalidate and reconsider if worse than at commitment |
| Impact marker spawns while bots are already processing warnings | `WarningEndSize`, `WarningDuration`, `WarningStartedAt` and `WarningKind` are already present when the marker enters Workspace |
| Two human avatars stand across a true sky gap that a bot must jump | The jump probe sees real origin/landing decks and actual gap, not the human avatar as a floor |
| New round begins after collapse event | Previous `collapsePlanThreat`, support and target are cleared; all three plan counters reset |
| Multiple overlapping hazards on Android | Compare real escape completion, humanoid movement, `AISurvivorService.PerformanceDiagnostics`, warning-version invalidations, bot CPU and frame-time against the pre-PR baseline |

### Release gate

The prior merged `main` was owner-reported functional, but **this aggregate PR branch has not been exercised by Roblox Studio, Open Cloud Engine Tests, or an Android live session**. The repository’s `Build Validation` workflow explicitly runs only on manually dispatched **main** release candidates; it cannot prove a feature-branch commit works. Keep PR #701 unmerged until owner gameplay validation, then run the exact-commit build/engine/publisher gate before claiming the Roblox public place is updated.

### Late review: hazard priority for supported partial retreats

A final source review identified that a **supported partial** retreat could originally be selected only by proximity, even when another partial direction crossed fewer simultaneous hazards. Commit `4d975009d3188ebbf1298b355d07409cb8d5f367` now ranks partials with the **same strict hierarchy as complete exits**: fewer Meteor/Bomb exposed endpoints, fewer warning corridor intersections, fewer live sweep crossings, then the shorter physical step. Midpoint support remains mandatory when the partial destination is on a different physical part. The short `0.32s` commitment and real-collision checks are unchanged.

Source code checks do not establish actual survival rates, latency, or Android FPS.

### Gap-sampling correction (continued review)

Commit `8c9845ec7d49275c1a8529a04820c7be8c8e74c0` replaces the single 55%-of-path support check on low-platform full exits with **three contact probes at 30%, 55% and 80%**. Supported partial retreats that end on a different physical part receive the same check. The extra probes reuse the existing `physicalFloor` raycast site and avatar exclusion filter, with no new global scans or unbounded pathfinding. **Important:** three discrete samples are a practical guard, not proof of continuous traversability or a replacement for real-engine collision QA. The true CPU cost per collapse plan is higher than the earlier single-midpoint implementation and must be profiled at the release gate.
