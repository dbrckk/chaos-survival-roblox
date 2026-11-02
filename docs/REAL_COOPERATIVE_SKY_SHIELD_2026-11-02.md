# Real cooperative Skyline Shield update — 2026-11-02

Status: **code candidate only; not yet re-certified by Build Validation / Roblox Open Cloud or published**. This update extends #540 rather than replacing the game or its existing disaster damage model.

## Major real player-facing change

Seven AI participants no longer behave as if the emergency shield stations are merely decoration. During Meteor/Bomb rounds, their existing humanlike movement AI may identify a useful **ready** defensive station, walk up to it, hold position for the **same real 0.65-second activation time** a human uses, then visibly activate the same server-owned 8-second cooperative shield.

An eligible bot must be alive, physically present in the actual `AISurvivors` folder, part of the round, and have an **active real human contestant within that shield's 24-stud horizontal / 24-stud vertical protected volume**. Seven bots cannot swarm one station: the server grants a single 5-second claimed reservation. If the human beneficiary walks out of the protective zone, the generator retracts from the shrinking floor, an imminent meteor threatens the bot, or the station is used, the AI abandons the plan and resumes regular survival behavior. A bot never teleports, fabricates a prompt or receives more health/movement than a person.

The same `ArenaSkyShieldNetwork.activate` validates both human prompt activations and bot actions, checking the actual server avatar, floor, proximity, active round and cooldown before deployment. The 8-second duration, 21-second recharge, 58% mitigation, four stations per arena and normal unshielded hazards remain unchanged.

## Visual scale and real mechanical feedback

- The protective area is no longer a big opaque 52×52×52 sphere that hangs **16 studs below the floor** and suggests a misleading shape. Its effect is now a vertical **48-stud-diameter, 26-stud-high cylindrical field**, matching the server's 24-stud horizontal radius and -2 to +24 stud vertical bounds.
- **Eight original noncolliding perimeter sections** illuminate when the field is active, marking its actual footprint across all five arena palettes without painting an opaque disk over the original meteor/bomb warning circles. The old full-width 48-stud overhead disk has been replaced by a **small overhead 8-stud crown**.
- Each activated station tracks **real absorbed blast damage** and the number of protected damage events as replicated `ShieldAbsorbedDamage` and `ShieldProtections`. The real server HUD tag on the console announces e.g. `SHIELD ACTIVE / 64 HP SAVED` only after real reductions have occurred. No fictitious achievements, combat rewards or saved health are awarded from client state.
- An AI activation is visibly signaled by its existing nameplate reaction `SHIELD UP!` and the generator's replicated `ShieldActivatedByBot` flag.
- ShrinkingArena can withdraw the real floor while a station is active; the existing size-listener now immediately switches the field offline, hides all perimeter parts and cancels damage benefit. No visual ghost shield remains in a void.
- No new remote calls, particle emitter loops, server physics, unsafe collisions, permanent spawned field objects, payment checks or high-frequency polling; emergency VFX remain native Roblox parts and only one active map is present.

## Files changed

`src/server/ArenaSkyShieldNetwork.lua` — shared actor activation, bot claim/eligibility, true-volume 3D field & boundary, genuine absorbed-damage counters, floor-safe shutdown and cleanup.

`src/server/AISurvivorService.lua` — humanlike shield targeting, actual approach and hold, urgent warning preemption, AI participation record, safe target release on lobby/arena changes and model deletion.

`tests/engine/disaster-impact.spec.luau` (existing file only) — field volume, 8 segment and overhead crown contracts, inactive no-immunity checks, never allow bot activation without a real human beneficiary, and shared explosion damage semantics.

## Release acceptance (not yet done)

1. At the next important release milestone, run the actual GitHub **Build Validation** and all five **Roblox Open Cloud Engine Tests** on the same merge SHA. The previous green `635b6b234fa09674a9fc47cca66125efd4161080` cannot certify this source update.
2. In Roblox Studio with multiple simulated players, validate the physical approach and 0.65-second hold, actual human-in-radius requirement, mutual-exclusion reservation, an interrupted shield attempt during Meteor/Bomb warnings, and correct departure in lobby/result phases.
3. On two clients, inspect 8 full perimeter arcs, safe collision, no obstruction of orange/red hazard markers, large vertical clear field, human/bot visual signaling and accurate total HP saved.
4. Validate flood-shrink Double Chaos: if floor retracts from a station during protection, shield geometry must disappear and **server mitigation must stop on the same frame** as the Size notification.
5. Verify real low-end Android FPS/P95 and memory with eight round participants, and genuine five-arena 3D screenshots. Only then authorize public publish; never confuse GitHub source fusion with a live Roblox update.
