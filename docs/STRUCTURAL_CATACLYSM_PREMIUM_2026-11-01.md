# Structural Cataclysm — five-arena visible destruction system
**Date:** 2026-11-01. **Status:** candidate source only, not yet published or certified on Roblox/Android.

## The major visible transformation

Every arena now owns **six enormous original 3D sky-promenade gateways** constructed in `PromenadeArchitecture.lua`. This lot makes that infrastructure **break, tilt, fall and disappear** during actual catastrophe rounds. This is a large, persistent structural change for the duration of the round, rather than another short flash or unrelated background image.

- A real **Meteor** or **Bomb** disaster applies its already-announced server damage; the *existing* `ctx.OnHazardImpact` callback then fractures the closest still-intact gateway to the real blast coordinates. No structure can break just because an untrusted client requests it.
- **Tornado** and **RisingLava** cause a deterministic series of storm-stress fractures, starting 6.5 seconds into a round and then spaced five seconds apart. One initially intact gateway collapses per event.
- At most **six landmark failures** in one round (the six original authored gateway groups), with at least **3 seconds** separating events.
- Each damaged group contains six to nine native 3D Roblox parts. The **server animates the existing parts** over about 1.15–1.43 seconds, in a deliberate cascade: structural wings separate, uprights pitch, machinery drops, materials fade. Tornado ruins move laterally more; lava damage drops with a lower vertical motion, rather than each hazard having the same effect.
- Clients watching a newly replicated `StructuralFracturePhase=Broken` on the true physical owning deck render **4 (Low), 8 (Medium), or 12 (High) temporary, individually tumbling metal fragments**. One short dust burst and a subtle airborne shock ring (Medium/High only) accent the scene. All fragments are collisionless local instances, using Roblox native geometry and built-in dust, cleaned by Debris.
- All five visual variants automatically inherit their own equipment shapes, materials and palette: Classic radar, Towers lifts, Crossroads signals, Orbital reactor, Harbor cargo. No licensed model or API cost.

Across the five possible variants, **30 monumental gateway collapse scenes** are authored; there are only six simultaneously on the one active map. This is not thirty simultaneously loaded maps, and the source implementation is not a guarantee of frame rate or screenshots.

## Genuine gameplay contract and player fairness

- **Real structural 3D transforms are server-owned**, replicated to every observer. The per-platform attributes `StructuralFractureStartedAt`, `StructuralFractureKind` and `StructuralFracturePhase` are written in order, so newly connected clients cannot invent a different failure.
- The long sky promenade floors remain **solid real server colliders** and retain `ChaosPermanentRoute`. Collapsing giant decorative gateways must not remove a safe route a fraction of a second after an impact warning elsewhere. This is **destructible architecture, not new damage or falling physical rubble**.
- Gameplay damage and telegraphs still come **only** from the already-operational Meteor/Bomb, Tornado, and RisingLava modules. There are **no new damage zones, artificial warning indicators, collision hazards, monetization or movement power**.
- The advanced `ShrinkingArena` hazard already writes world poses to attached architecture every 0.15 seconds. This feature is **automatically disabled** in any round combining it with structural events; it must never fight the physical shrink owner.
- Source-only scene state is cleaned on normal round exit and all registered tweens are cancelled; the original CFrames, colors, alpha and platform attributes restore. Local ephemeral graphics are removed on map replacement and when ReduceMotion is enabled. No network remotes, data migration, physical debris, client-authored health or new full-frame loops.
- Real mobile tier and `ReduceMotion` are read at each fracture; late-streaming clients keep the already-replicated ruined architecture without replaying old debris.

## Files

- `src/server/ArenaStructuralCollapse.lua`: validated source selection, six structural groups, real impact/stress scheduling, synchronized server breakage, exact cleanup.
- `src/server/init.server.lua`: registers cataclysm **before** starting the live disaster modules and calls its returned handler only from existing authoritative `OnHazardImpact`.
- `src/client/ArenaRuinBurstKit.lua`: bounded 3D debris, subtle dust and shock pulse.
- `src/client/arena-cataclysm-debris.client.lua`: listens to the server's existing world attribute replication, handles map streaming, quality and reduced motion.

## Certification at the next important release milestone — NOT YET DONE

1. Run repository **Build Validation** and all **five real Roblox Open Cloud suites** on the *same candidate commit SHA*. Never interpret a source review as a passing engine test.
2. In Roblox Studio play the five real 320-stud arenas and repeat actual impact rounds. Verify the ruin occurs after Meteor/Bomb impact (never before the warning), lasts for the round, recovers during round cleanup, and respects nearest intact structures.
3. Play Tornado / RisingLava and Double Chaos combinations, including ShrinkingArena. In shrink fusions there must be **no competing structural tween**. Neither mobile humans nor the seven original AI participants may be trapped by any invisible collision from a decorative arch.
4. Watch the same structure on two real clients: verify identical server geometry, no phantom platforms, clean (no repeated VFX) late-map streaming and reconnect. Check Reduced Motion and real low-end Android device frame pacing, memory, latency and thermal state.
5. Capture 15 authentic frames **per arène**, compare before/after environmental destruction and readability of the hazards in the actual 3D camera. Only publish when all gates pass on that exact source SHA. Keep the previous proven public-release SHA available for rollback.

**Latest confirmed public build remains `46263cbdced1bddf002a8d57867303eb21422c2f`**, not this candidate code. This document describes authored behavior; it is not evidence of a finished Roblox Studio/device playtest or deployment.
