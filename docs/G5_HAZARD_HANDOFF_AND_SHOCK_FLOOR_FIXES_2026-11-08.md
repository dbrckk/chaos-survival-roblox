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

## Independent JumpShock body action during concurrent hazard escapes

### Confirmed arbitration defect

Previously `stepRecord` ran `disappearingPlatformEscape` **before** `immediateThreat`, only invoking the latter if the platform escape had no target. Separately, `immediateThreat` ranked Meteor/Bomb warnings above JumpShock and Freeze. Consequently, an NPC standing on a collapsing deck or continuously dodging overlapping impacts could **never reach the JumpShock jump branch**, even when it saw a live, arena-wide shock warning during the short authoritative jump window.

### Focused correction

- `reactToShockWarning(record, humanoid, root, now)` runs once per actual **in-round AI brain pass, after horizontal hazard prioritization but before the actual movement command**, reading only the existing server event-cached `warningParts()` set. This ordering preserves the Meteor/Bomb first-sighting safety cue when a simultaneous shock ring becomes visible; the physical shock-jump action is still checked even if a collapsing platform already supplied the escape target. There is no new event connection, raycast, global Workspace search or pathfinding call.
- For the actual `JumpShockWarning`, check the server's published final `WarningEndSize`, individual `ReactionSeconds` after **the bot's own first real sighting** (`shockWarningSeenAt`, a weak-key table) and `AISurvivorRules.shockJumpWindow` based on authoritative `WarningStartedAt` / `WarningDuration`. Only a nonseated, grounded, non-frozen Humanoid issues the normal `Jump` request.
- Call the **existing** `consumeWarningJump` one-shot rule, so the same warning Instance cannot trigger repeated jump commands. Increment observational `BotShockJumpCommands` only when a server Jump command is actually issued. This does **not** count successful dodges or grant immunity.
- `immediateThreat` skips JumpShock for **route focus**, not for awareness. This avoids throwing away a previously selected Meteor/Bomb escape direction because an independent shock ring became visible.
- Freeze remains a **lower-priority optional personality jump**, processed only when the normal threat resolver selects Freeze. A cosmetic Freeze jump must not interrupt a higher-priority bomb, meteor or collapse retreat.
- The weak first-sighting table and existing one-shot table reset on rig replacement and round transition, and are cleared when the bot returns to the lobby.

### Concurrent-disaster engine acceptance matrix

| Situation | Expected observable behavior |
| --- | --- |
| A bot is following a real Meteor/Bomb escape when JumpShock's late window starts | It can issue **one** ordinary grounded jump without clearing or replacing its impact escape waypoint |
| A bot is evacuating a confirmed disappearing platform when JumpShock fires | The timed shock jump still receives a chance even though the collapse route owns horizontal movement |
| A bot has never seen JumpShock before this AI pass | Existing individual reaction latency remains mandatory; no instantaneous superhuman dodge |
| A bot is already airborne, seated or truly `ChaosFrozen` | No fake extra jump or bypass of the server's physical timing and clearance conditions |
| A bot receives repeated AI ticks for the same shock warning | No repeated `BotShockJumpCommands` increment from that Instance |
| Freeze overlaps an imminent Meteor/Bomb warning | The optional Freeze jump stays subordinate to the genuine impact escape |
| An old JumpShock warning expires and a new Instance appears | Independent weak-key first-sighting latency and one-shot eligibility start afresh |
| Eight participants, Double Chaos and shock waves on Android | Measure **actual** airborne clearance, server reward/damage decisions, escape targets, FPS/CPU and `BotShockJumpCommands` versus real successful dodges |

The branch source has undergone targeted static invariant checks only. **No Roblox Engine execution, actual shock-dodge completion test, measured CPU/FPS or publication has been performed on this change.**

## Follow-up safety correction: reserve jumping for authoritative warnings

A continued audit found three competing jump sources that could defeat the new independent JumpShock defense without changing any of the underlying damage physics:

1. The normal, low-probability `freeJumpChance` path in `stepRecord` did **not** check the already-cached server warning list. A bot might start a cosmetic hop early during a JumpShock telegraph and remain airborne when the real late-window jump was due. The casual-only condition now requires `#warningParts() == 0`. It does **not** restrict physical sky-gap jumps, district route elevation jumps, recovery motions, or the actual JumpShock jump.
2. The old optional Freeze personality jump could still fire during an overlapping, physically relevant JumpShock warning, before the independent timed shock jump. The Freeze branch now checks for an active `JumpShockWarning` covering the bot (using its server-authoritative `WarningEndSize` and the shared detection rule), and skips the **optional Freeze jump** when present. The existing Meteor/Bomb horizontal hazard priority and Freeze's original chance remain unchanged otherwise.
3. Marker removal and the subsequent server-side shock damage are adjacent but separate operations. To avoid a cosmetic jump becoming immediately eligible in that interval, each in-range, real JumpShock warning now postpones only the bot's `nextJump` casual-hop clock to at least `now + 1.0` seconds. The actual parkour `nextRouteJumpAt` timer and server physical shock-jump window are unchanged.

### Additional real-engine acceptance checks

| Case | Expected |
| --- | --- |
| Casual roaming while JumpShock warning is active | No early personality hop; bot remains able to issue a real timed shock jump |
| Freeze and JumpShock warnings overlap | Optional Freeze hop is suppressed while JumpShock covers the bot; timed shock jump retains priority |
| A character must cross a physical sky gap during a warning | The real parkour jump is not gated by the cosmetic jump timer |
| Shock warning expires, server impact callback runs, and bot brain ticks concurrently | No immediate random hop from a stale `nextJump` deadline |
| No warnings and a normal round underway | Original personality jump chance and scheduling continue |
| Meteor/Bomb or collapse overlaps JumpShock | Horizontal escape remains prioritized and real shock jump is independently evaluated |

**Verification status:** source-level structural checks only. Neither actual jump clearance/damage outcomes nor Roblox Engine frame scheduling nor Android FPS was observed. No changes to shock damage, physics impulses, character jump height, movement speed, or Roblox release publication were made.

## Final G5 follow-up — shock-jump timing independent of AI brain cadence

### Confirmed timing weakness

The shock avoidance path was still driven by the ordinary per-bot AI brain step (about 0.18 seconds between passes). The `shockJumpWindow` function allows a real jump request when the warning has between 0.10 and 0.34 seconds remaining, but the **server's actual dodge rule** (`JumpShock.dodgedByJump`) independently requires the humanoid to be airborne, vertically rising above 3 studs/s **and** physically at least 4.5 studs above the nearest real ground at the exact damage instant. A jump command near either extreme of the broader AI decision window can therefore fail with normal Roblox jump physics, even if the threat was recognized.

### Bounded, server-authoritative scheduling

- When a particular `JumpShockWarning` is first observed within its authoritative coverage, the server calculates a one-shot callback relative to its prepublished `WarningStartedAt + WarningDuration`.
- The planned physical jump is **0.18–0.22 seconds before the impact**, with a small fixed per-slot stagger so the survivors do not all jump on precisely the same frame. This is a scheduling target, **not** a guarantee of the actual engine execution instant.
- The callback revalidates: same original rig and humanoid, still alive and in the same active round, same original weak-key warning-sighting table and one-shot handled table, warning Instance still directly in Workspace with `WarningKind="JumpShock"`, valid authoritative duration and remaining time, individual personality reaction delay, genuine grounded and unseated state, not frozen and jump capability not explicitly disabled (`JumpPower` / `JumpHeight`).
- Only an actual one-shot `Humanoid.Jump=true` request increments `BotShockJumpCommands`; there is **no direct reward, safety status, impulse, forced clearance, higher jump height, or immunity**.
- As a fallback for a delayed callback or a warning first seen near its deadline, the ordinary brain can request the same one-shot jump only while **0.12–0.23 seconds** remain. That is a subset of the existing public `shockJumpWindow` and checks the identical server physics state.
- At most **one short `task.delay` callback per newly observed, eligible real shock warning per active bot** is added. It is bounded to an initial delay of 0–4 seconds; stale callbacks simply return. No new `workspace:Raycast`, pathfinding computation, global Workspace scan, unconditional heartbeat listener or replicated RemoteEvent was introduced.
- The final server impact still runs the unchanged `JumpShock.applyShock` physical rising-velocity and real clearance test. A Jump request can legitimately fail to dodge if physics or scheduling differs from expectations.

### Acceptance before merging PR #702

| Scenario | Expected |
| --- | --- |
| Eight bots detect one JumpShock warning near the arena edges | Bots schedule slightly staggered normal jumps close to impact, instead of being quantized to the 0.18-second brain cadence |
| An AI pass falls outside the narrow intended jump timing | The timed callback still provides a chance to issue the jump |
| Scheduled callback executes after the warning disappears | No jump command, no new counter |
| A bot was replaced, died, left the round or returned to lobby | Old callback cannot jump the newer character or a nonparticipating bot |
| A bot is seated, airborne or still genuinely frozen when callback runs | No fake extra jump command, and no server-side dodge bypass |
| Two genuine waves overlap | Each warning has an independent one-shot state; a warning never issues multiple jumps |
| Timed callback and brain fallback are both eligible in the same impact window | Shared `reactedWarnings` table ensures at most one command per warning |
| Eight players under Meteor/Bomb/Collapse/Freeze + JumpShock | The real physical jump window and hazard priorities apply, while other movement goals stay intact; inspect bot CPU/Android FPS |
| Nondefault gravity or modified humanoid jump physics | Verify the 0.18–0.22 second target is still appropriate; do not assume a successful dodge without Roblox Engine testing |

**Release status:** the code is committed on PR #702 only. No Roblox Engine timing validation, live damage/reward observation, publish, CPU profile or Android playtest was performed in this turn.

## 9 novembre — couverture horizontale réelle et observabilité des esquives

### Problème de portée identifié dans le code

L'avertissement `FreezeWarning` / `JumpShockWarning` est construit à partir du diamètre diagonal du socle 320 × 320, et `D.start(ctx)` affecte les participants actifs du serveur indépendamment de leur altitude. La détection IA utilisait néanmoins la **magnitude 3D** entre le bot et le marqueur près du sol. À la périphérie d'une grande arène, une hauteur supplémentaire pouvait faire sortir un bot de la portée d'anticipation alors qu'il était bel et bien touché par l'effet serveur.

Correction dans `AISurvivorService.warningDistance` :
- uniquement pour `FreezeWarning` et `JumpShockWarning`, la distance d'anticipation est désormais en plan **X/Z**, conforme à leur couverture d'arène ; conserver le seuil borné de `AISurvivorRules.warningDetectionRadius` et les délais de personnalité ;
- les avertissements Meteor/Bomb restent évalués en **3D**, sans modification de leur dégâts, rayons ni itinéraires ;
- aucune nouvelle recherche physique, trajectoire, boucle ou allocation de Part, seulement un calcul de distance arithmétique borné sur la liste existante.

### Mesure réelle : commandes versus résultats

`BotShockJumpCommands` ne compte que les tentatives de saut du cerveau IA, pas les véritables évitements. Deux nouveaux attributs diagnostiques **par rig et réinitialisés à chaque manche** sont mis à jour exclusivement dans `Disasters/JumpShock.applyShock`, au moment de l'impact serveur :
- `BotShockDodges` : `D.dodgedByJump` a effectivement renvoyé `true` sur une vague ayant atteint ce bot, avec vitesse verticale et dégagement physique suffisants ;
- `BotShockHits` : ce même bot valide n'a **pas** satisfait le critère d'esquive et a reçu l'impulsion normale ;
- le traitement des joueurs humains et leur récompense `OnHazardNearMiss` restent inchangés ; aucun gain, bouclier, immunité ni baisse artificielle du nombre de coups n'est introduit.

Ces deux compteurs sont des **observations runtime**, pas des preuves anticipées de réussite. Chaque vague ne modifie un compteur de bot que lors de son évaluation physique (pas par frame). Un Humanoid mort/absent avant la vague n'est ni un hit ni une dodge. La somme `BotShockDodges + BotShockHits` permet de vérifier le nombre de bots physiquement évalués. `BotShockJumpCommands` est indépendant : un bot peut esquiver après un vrai saut de parcours, et une tentative IA peut être ratée.

### Acceptation moteur additionnelle

1. Même position X/Z, hauteurs différentes : Freeze et JumpShock sont perçus avec la même portée horizontale, sans changer la date de la vague ni la physique ; un avertissement à métadonnées invalides conserve son comportement conservateur.
2. Même situation Meteor/Bomb : la distance physique 3D reste inchangée.
3. 1 humain + 7 bots sur une vraie vague JumpShock : `BotShockJumpCommands`, `BotShockDodges` et `BotShockHits` donnent des valeurs par bot; la somme des résultats d'impact correspond exactement aux bots vivants/actifs réellement évalués.
4. Un bot sur un saut de parcours déjà montant peut esquiver sans commande de saut JumpShock ; un bot recevant une commande trop tard peut être réellement touché : ne pas déduire le succès de `BotShockJumpCommands`.
5. Réapparition et nouvelle manche : nouveaux compteurs à zéro, pas de résultats hérités de l'ancienne catastrophe.
6. Serveur Android/PC : observer la cadence de la boucle IA et le coût de l'impact ; ne déduire aucun gain de FPS des corrections de calcul avant une mesure réelle.

**Statut :** source modifiée sur PR #702 ; relecture statique à faire ; Roblox Engine, publication et métriques appareil non exécutés dans ce lot.
