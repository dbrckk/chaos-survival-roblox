# Chaos Survival — Tornado debris/spiral budget under Double Chaos

31 October 2026. Source-only work. Current arena visual audit, Roblox Studio playthrough and public Roblox publication are deferred.

## Source findings

Two distinct client owners create optional parts around the **same server-owned Tornado**:
- `tornado-visuals.client.lua` allocates **5 Low / 8 Medium / 12 High** local `WedgePart` shards inside `TornadoDebrisLocal`. They do not respond to the number of simultaneous disasters. Under ReduceMotion, the geometry becomes static but still uses its full tier count.
- `disaster-motion-vfx.client.lua` invokes `TornadoSpiralKit`, whose `TornadoSpiralRules.count` allocates **6 Low / 12 Medium / 18 High** glass ribbon segments in `ChaosMotionDisasterVfxLocal`, capped to 6 with ReduceMotion. This second owner likewise ignores Double Chaos density.
- **Do not lower the wind-danger perimeter**: `TornadoWindBoundaryLocal` uses `TornadoBoundaryRules.profile` (8 Low / 12 Medium / 16 High) and follows the replicated zone's center. It is a critical escape cue, not optional scenery.
- The spiral kit only checked its cached source and array length. If another script or streaming lifecycle deleted a locally owned segment while its Lua reference survived, the current `Part` was never recreated.

## Corrective implementation

1. `DisasterCosmeticRules.tornadoDebrisCount(tier, reduced, simultaneous)` uses the existing `pressureMultiplier` (one = 1.00, two = 0.85, three or more = 0.70) with a minimum of three optional shards. Baseline counts are identical in single-disaster rounds without ReduceMotion. ReduceMotion limits decorative debris to at most five pieces; all Counts remain tier-bound.
2. `TornadoSpiralRules.count(tier, reduced, simultaneous)` applies the **same** pressure rule to the optional ribbon count, rounded to an even segment number (both helical arms receive equal segments), bounded by the old tier count, minimum four. Original two-argument API calls behave exactly as before.
3. Both client owners count **distinct recognized disaster IDs** in valid numbered `RoundState` snapshots, bounded at three for policy, reject stale/malformed state. Only changed counts rebuild tornado debris. The spiral owner reuses its existing adaptive loop and rebuilds only when the returned count changes.
4. The spiral kit checks that every cached segment still belongs to its local folder, rebuilding on missing children. Newly created parts are posed before parenting, avoiding a flash at the world origin.
5. The tornado owner uses conditional writes for repeated funnel transparency and light properties during Low/ReduceMotion. No extra render or polling loop, no additional RemoteEvent, no new raycast.

## Validation deferred to major release gate

- Execute Build Validation and the existing five Roblox Open Cloud suites on the exact merged `main` SHA. Then perform real Android Low/Medium/High and desktop Studio sessions.
- Spawn Tornado only, Tornado+Bombs, Tornado+Meteors+Freeze in an authorized environment; inspect `TornadoDebrisLocal` and `ChaosMotionDisasterVfxLocal` piece counts. Ensure the amber wind ring remains 8/12/16 and follows moving danger zones.
- While the storm is active, toggle Low/Medium/High, ReduceMotion and remove a local spiral Part. Verify local recovery without duplicate parts or visual gaps; moving winds and server damage remain identical.
- Send duplicated, malformed and older `RoundState` snapshots and simulate model streaming. Ensure no stale geometry and no unwarranted decorative rebuild.
- Measure actual Android p95 frame time, memory, instance allocations and FPS. Smaller cosmetic geometry is **not** a measured FPS improvement.

These two owners now share **optional tornado geometry pressure**, not a global allocator for all client effects. The rest of `VisualBudgetRules` remains instrumentation; authoritative damage, warning boundary, audio and movement are unchanged.
