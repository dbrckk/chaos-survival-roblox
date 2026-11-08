# G5 — Hazard transition recovery and authoritative pulse warnings

**Baseline:** `main` commit `86f11878767a30295b46260d3cb9ac73fe875d2e`, after owner-confirmed PR #701.
**Branch:** `fix/ai-collapse-state-lifecycle-20261108` (PR #702).
**Scope:** existing bot AI lifecycle and Freeze/JumpShock warning generation and server-observed shock-dodge floor clearance.

## Defects and corrections

### 1. Stale collapse-plan metadata outlives its warning

`disappearingPlatformEscape` returned early when DisappearingPlatforms ended, the scanned platform stopped warning, or the bot moved onto a different threatened platform. Those paths cleared `collapsePlanTarget` but not the linked warning version and prior floor-sweep exposure count.

Each of the three source-authoritative early transitions now clears the **entire** cached plan, including `collapsePlanWarningVersion=-1` and `collapsePlanSweepExposures=0`. The real platform tests and normal personality reaction latency remain unchanged.

### 2. A resolved emergency leaves an obsolete movement goal

`stepRecord` previously issued `record.target = urgentTarget` for each hazard response; when the warning disappeared, it could continue using the last 0.32–0.54s emergency waypoint as if it were the new ordinary exploration goal. The regular `recoverIfStuck` sampled progress only when no urgent escape was active; this left a stale target/progress baseline around hazard transitions.

- `emergencyMoveActive` tracks a real urgent movement command.
- While urgent, keep normal stall tracking anchored to the **current** root position without classifying an intentional dodge/hold as a failed ordinary route.
- On the **first non-urgent brain pass**, clear the now-obsolete emergency goal, reset steering/turn/idle offsets, refresh the normal walking progress baseline and force an ordinary decision on that same pass.
- Preserve real recovery attempt history, failed-goal quarantine and committed physics limitations. Do not add teleportation, speed, immunity or extra path computation.
- Reset `emergencyMoveActive` on rig replacement, lobby transition, and successful new-round spawn.
- `BotEmergencyResumeCount` is an observational, per-round attribute; it counts handoffs, **not** successful escape completion.

### 3. Freeze / JumpShock warnings were published before initialization

`Freeze.createWarning` and `JumpShock.makeWarning` set `Parent=workspace` before `HazardWarning.configure` ran. That exposed metadata-free warning Instances to the server ChildAdded event watcher and to clients, even though the pulse timing and coverage were already known.

Both now configure `WarningStartedAt`, `WarningDuration`, `WarningEndSize` and `WarningKind` **before parenting**. This matches the published Meteors/Bombs correction from PR #701. Freeze still waits 0.70s, JumpShock still waits `D.WarningSeconds=1.05` and uses the original arena coverage diameter, then executes its same server-owned consequence.

### 4. A player or bot below an airborne jumper can masquerade as ground

`JumpShock.applyShock` already used the correct real 24-stud downward collision query but excluded **only the current subject's Character**. Another server-rostered real human or bot could be struck by the ray first. That would reduce measured ground clearance and falsely deny a legitimately timed airborne dodge.

Build the exclusions from the authoritative `ctx.HazardContestants` (fallback `ctx.Contestants`) and the subject's own Character. Exclude these moving model rigs only from the ground-clearance raycast; use the original `RespectCanCollide=true`, `D.dodgedByJump`, velocity, actual contact height, damage/impulse conditions, and server-owned participant eligibility. The list is bounded by the current round roster; there is no new Workspace scan.

## Engine acceptance matrix

| Scenario | Expected |
| --- | --- |
| A platform warning is replaced or ends | Collapse plan target, version and sweep metadata are all invalidated |
| A surviving bot completes a Meteor/Bomb dodge | The next non-urgent AI pass selects a fresh exploration/mission destination, not the obsolete short emergency waypoint |
| Bot stops on a collapsing deck because there is no supported escape | No false `recoverIfStuck` escalation while holding for survival; resume normal baseline after danger ends |
| Round ends or an AI model is rebuilt mid-disaster | No old `emergencyMoveActive` flag; next round begins with independent movement plans |
| Fresh Freeze warning is added to Workspace | Warning kind/duration/start/final diameter already exist on the first ChildAdded event |
| Fresh JumpShock warning is added to Workspace | The shock jump window and coverage attributes are available before bots sample it |
| Airborne jumper is above another real participant | Clearance ray ignores that participant's rig and measures actual colliding ground |
| Jumper is rising but **not** at sufficient floor clearance | Existing server `D.dodgedByJump` still rejects the dodge and applies the normal shock |
| Eight participants, Double Chaos and platform collapse on Android | Inspect actual movement, near-misses, `BotEmergencyResumeCount`, `BotStallRecoveryCount`, CPU usage and client FPS; compare to baseline |

## Validation policy / deployment state

Source-level structural checks were performed before creating this document. **Roblox Engine, cloud build/publisher and Android live runtime checks have not run for this branch.** The repository's `Build Validation` job is restricted to manually dispatched `main` release milestones. This PR remains open until owner gameplay validation. No Roblox public place is published by a GitHub code commit alone.

## Continued fixes on PR #702 — Freeze stalls, collapse CPU and arena-wide pulse reach

### 5. Freeze speed reduction must not be treated as a navigation stall

`Freeze.lua` sets the server-owned Humanoid `ChaosFrozen=true` while enforcing `WalkSpeed=4` and disabling jumping for `FreezeSeconds` (by profile). The ordinary AI `recoverIfStuck` considered a 1.15-second interval with under 0.85 studs of progress toward its goal a genuine blocked path, regardless of the deliberately imposed Freeze state. That could quarantine a perfectly reachable destination or spend an expensive recovery calculation during the pulse.

`recoverIfStuck` now skips the genuine-stall classification **only while the server Humanoid is actually `ChaosFrozen=true`**, resetting its observed walking position, current goal and elapsed-time baseline. After Freeze ends, the bot must spend the original 1.15s of active walking before a real blockage can trigger recovery again. It does not erase a real failure/quarantine history or alter the Freeze effects for players and bots.

### 6. Full exits before partial fallback: collapse CPU optimization

On a real, low-elevation `CollapsePhase="Warning"` platform, the emergency solver previously sampled partial edge approaches for all four headings **before** testing complete exits. Even when one or more complete physically supported refuge targets were found, the partial-fallback raycasts and warning/sweep scoring had already run and the results were discarded.

The revised order first tests all four full exits (including their exact destination and three real corridor support contacts), ranks only real eligible destinations, **returns immediately upon choosing one**, and only then evaluates supported partial approaches if every full exit failed. The exact hazard hierarchy for partials, 0.32s commitment, and same verified collision samples are preserved. No new raycast call site, server physics cheat or world traversal was introduced. A measurable CPU/FPS improvement has **not** been established; it removes avoidable queries only on the common case with at least one valid full exit.

### 7. Shock/Freeze awareness uses real arena coverage rather than a fixed 80-stud circle

All five authored arenas currently have a 320 × 320-stud base. The server `HazardWarning.arenaCoverageDiameter` publishes the authoritative base diagonal (+6 studs) to the `WarningEndSize` of actual Freeze and JumpShock warnings; these disasters can affect participants far beyond 80 studs from the center. However `AISurvivorRules.warningDetectionRadius` had a fixed 80-stud result for both warning types, preventing perimeter bots from reacting.

The pulse detection rule now computes `max(80, min(512, WarningEndSize/2 + 9))` when the server-provided diameter is finite and strictly positive. Invalid or absent diameter keeps the original **80 studs** for older warnings, preserving compatibility with existing engine specs that check this no-metadata behavior. Meteor/Bomb footprint calculations are unchanged. No increase in warning spawn rate, server damage range, character speed, or warning duration.

### Additional acceptance matrix

| Scenario | Expected |
| --- | --- |
| A physically unblocked bot moves at the server-imposed Freeze speed | No new `BotStallRecoveryCount`, failed-goal quarantine, or ComputeAsync triggered by the Freeze itself |
| The same bot hits a genuine wall after thawing | Original 1.15-second walking evidence is still required, and a verified recovery proceeds |
| One ground-platform collapse has at least one supported full exit | **No partial-fallback probes** are executed; full-exit selection is unchanged |
| No complete escape from a very large or isolated warned platform | Supported partial options are considered and ranked by Meteor/Bomb landing exposure, corridor exposure, floor sweeps, then distance |
| A JumpShock warning covers Classic's 320 × 320 floor | A bot near a map corner detects the server-provided full-coverage warning, with its original reaction window and real vertical jump check |
| A pulse marker lacks valid `WarningEndSize` | Falls back to 80 studs rather than creating an unlimited detection radius |
| Meteor/Bomb warnings coexist with an arena-wide pulse | Existing priority and actual final impact radii remain intact; no invented immunity |
| Eight contestants on Android | Compare server bot decision-pass duration, source counters and actual FPS before claiming an optimization |

The engine tests, Android behavior and runtime profiles are **not executed on this branch**. Do not claim the improved detection radius guarantees a successful dodge: bots still need a valid real jump in the authoritative timing window and can be distracted by more urgent hazards.
