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
