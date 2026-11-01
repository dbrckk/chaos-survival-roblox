# Skyline Emergency Shields — real cooperative meteor/bomb protection

Date: 2026-11-01. **Source-only feature**. No Roblox public deployment, mobile footage, production claim or engine PASS for THIS feature revision.

## Major new on-map interaction

During *Meteor Shower*, *Bomb Rain* or compatible Double Chaos rounds, **four large, physically situated storm-defense installations** appear on the active 320×320 arena. Their original skyline 3D differs visibly in every one of the five settings:

- Classic: industrial shield radar and paired steel load piers
- Towers: overhead industrial freight shuttle
- Crossroads: dual angled switching signal fins
- Orbital: large ceramic containment ring and energy core
- Harbor: corroded freight crane and cargo pod

Each station has a clearly marked, server-owned **PROTECT TEAM** proximity interaction compatible with touch, keyboard and controller. Holding for **0.65 s** operates a **52-stud-wide translucent glass defensive envelope**, with large colored structural generators, overhead machinery and a short status tag. The protective volume is noncolliding and never hides actual red/amber hazard signals, obstructs jump paths or creates invisible barriers.

**What changes in the GAME, not just the background:** for **8 real seconds**, all actual human and AI survivors within the generator's **24-stud radius** and within the physical height band take **42% of their normal Meteor/Bomb damage** (58% mitigation). No perfect invulnerability, no fake shield for other hazards, no health advantage based on purchases, account type or team. One generator recharges over **21 seconds**. Simultaneous activation of several different stations is possible; protection never stacks, and remains bounded by the one maximum reduction.

## Safety and lifecycle contracts

- `ArenaSkyShieldNetwork.start(ctx)` starts **only** for an active round with `Meteors` or `Bombs`, and only when a real >280-stud collision Base exists in `GeneratedMap/Arena`.
- The server checks `Players` membership, `DataLoaded`, authoritative active contestant, live character/humanoid, actual root distance and charge readiness **again when the prompt fires**. No client-supplied activation position or damage request and **no new RemoteEvent**.
- The existing `DisasterImpact.applyRadialDamage` calls `ctx.ImpactShieldMitigation` only on an actual positive-damage `Meteor`/`Bomb` hit. Both real humans and seven AI proxies use the same `HazardContestants` loop and the same mitigation. The server position is measured from the real HumanoidRootPart. `OnHazardDamage`, death cause, elapsed round tracking and near-miss remain authoritative and unchanged.
- Shield effect cannot increase applied damage or reduce a positive hit to zero; nonfinite or failed callbacks are ignored and default to original damage. Fractional near-death health is protected against invalid clamp bounds.
- The *four stations* are built from native Roblox anchored, **CanCollide/CanTouch/CanQuery=false** Parts; there are no new real world colliders, invisible traps, physical impact projectiles or per-frame polling loops. One set of `task.delay` callbacks safely restores each station; cleanup invalidates all in-flight activations at the end of the round and destroys the temporary round folder.
- Shield only protects the active zone while deployed; a visible ready station without active field grants **zero mitigation**. Blast warnings/damage elsewhere continue normally.
- There is no passive damage reduction outside the zone or protection from Lava/Tornado/Freeze/Shrinking Arena.
- No paid premium, hidden timers, extra teleports, changes to 8-seat fill rules, DataStore or Lua RPC contracts.

## Files

- `src/server/ArenaSkyShieldNetwork.lua`: five visual variants, four stationary interactive controls, core/server status, strict 8 s/21 s timer, mitigation radius and cleanup.
- `src/server/init.server.lua`: registers field before disaster workers start; assigns the callback on the exact active round context.
- `src/server/DisasterImpact.lua`: optional validated authoritative positive-damage reduction only for existing explosive disasters.
- **Existing** `tests/engine/disaster-impact.spec.luau`: augmented with source-owned geometry/multisubject checks and actual generated 4-station instance creation and cleanup, so the next Cloud engine milestone tests the real Roblox objects rather than a fabricated screenshot. No new unit-test file created.

## Final major-gate acceptance — NOT YET EXECUTED FOR THIS SHA

1. Run `Build Validation` and the five `Roblox Open Cloud Engine Tests` shards on one exact merged SHA. The previous fully successful milestone SHA `635b6b234fa09674a9fc47cca66125efd4161080` does **not** certify this newly modified feature.
2. Real Roblox Studio: activate each generator with an ordinary ProximityPrompt; ensure no charge can be applied from outside interaction range, by an eliminated avatar or by a spectator. Visualize field, active/cooldown/offline labels, and restoration between rounds.
3. On the same actual Meteor/Bomb telegraphed blast: compare two human survivors and seven possible AI subjects, same raw radius/damage falloff; protect nearby humans/bots equally, damage outside the zone unchanged. Confirm existing near-miss and elimination attribution.
4. Run Double Chaos including `DisappearingPlatforms` and `ShrinkingArena`. Confirm it neither claims an unearned immunity from lava/nuclear weather nor obstructs the 52-deck permanent ground-to-sky escape network.
5. Android physical Low/Medium and desktop sustained FPS/p95 and thermals with 8 total participants; inspect translucent shell readability and scene overdraw. Capture genuine views of each of the five arena variants and the actual activation/catastrophe transition.
6. **Do not release to the existing public place** until all release gates have passed and a public update has been explicitly authorized.

The previously certified exact-SHA production path remains separate; **source merge is not a Roblox publish**.
