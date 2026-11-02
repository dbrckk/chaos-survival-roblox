# Co-op Skyline Storm Corridors — major real gameplay

Source implementation date: **2026-11-02**. **Not a live Roblox publish** and NOT certified on the current source SHA until the real milestone checks complete.

## Players can now link two giant storm generators

Four player- and bot-operable emergency shields already exist on all five 320×320 environments. Previously their protective 24-stud-radius cylinders worked separately. This update gives human survivors and their seven AI teammates a meaningful **second action**: activate two DIFFERENT generators concurrently to open an **18-stud-wide linked defensive corridor** through a much larger stretch of the actual arena.

- One live generator: the existing visible **48-stud-diameter** 8-second local zone, 21-second cooldown.
- Two live generators: their local shields continue, PLUS a long, server-authoritative **18-stud-wide, up-to-24-stud-high continuous line** between the two stations, eligible to save every living human or AI walking across it. The protected duration is ONLY the overlap of the two *actual* 8-second shields. This is a high-value temporary, strategic escape through open terrain during Meteor/Bomb impact storms.
- Three/four concurrent generators: only actual active pairs connect (up to 3/6 links respectively), not an always-safe 320×320 map. Existing 58% impact damage mitigation is applied **at most once per target per impact**, never additive or a special paid immunity. Other disasters are NOT protected.

The network visibly creates seven original noncolliding Roblox 3D details per active link: two full-span ground perimeter rails, two upper power rails, and three floor crossing signals, with a distance-culled **TEAM LINK ACTIVE / CROSS TO SURVIVE** status at the real crossing midpoint. A real protected hit increments the corridor's replicated `ShieldAbsorbedDamage` and switches the status to **HP SAVED** with the actual server-calculated number, not simulated progression.

## Security and runtime safety

- All decisions come from the existing Roblox server `ProximityPrompt`/bot actions, actual health, real-time `os.clock()` deadlines and server `HumanoidRootPart`. No RemoteEvent, client-reported impact position or additional damage class.
- The `linkContains(a,b,rootPosition,groundY)` source helper uses horizontal line-segment projection; strict **9-stud half width**, height from **floor-2 to floor+24**, never outside endpoints. Degenerate segments are rejected.
- Each real corridor is generated **only while both endpoints are live** and is restored/reused between activations; at most six pairs among four stations and seven noncolliding decorative Parts per pair. No permanent animation or RenderStepped loop. There is one delayed expiry per newly changed pair deadline, which rechecks the actual endpoints and invalidates old scheduled callbacks.
- The moment a generator times out, cleanup begins, or Shrinking Arena's shrinking base floor no longer supports either machine, **both its local field and all connected links immediately cease to apply server damage reduction and disappear**. The original 52 permanent escape decks, R15 jumps and nine other disaster safety rules remain unchanged.
- Mobile: thin rails are lower overdraw than solid, opaque coverage. No lights/emitters per link; each model has native atomic streaming for no partial dangerous fake route.

## Critical loading fix

`ArenaSkyShieldNetwork.lua` used an unconditional `require("../shared/VisualTheme")` even when executed as a normal published server ModuleScript. It now resolves the actual published `ReplicatedStorage.Shared.VisualTheme` ModuleScript first, falling back to source-path require only when the Roblox Open Cloud tests load a repository source against an older published place. This prevents the real runtime from depending on source-only import behavior.

## Change boundaries

Only the existing `src/server/ArenaSkyShieldNetwork.lua`, existing `tests/engine/disaster-impact.spec.luau`, and product/release documentation are edited; no new hidden server hooks or alternate AI brain. Both humans and bots reuse the same previously integrated `ctx.ImpactShieldMitigation` callback.

## Major release certification

1. Real GitHub Build Validation on the exact merged SHA; real Luau compiler, Rojo place package, security checks, Android first-frame VFX and provenance.
2. All FIVE Roblox Open Cloud engine shards on that **same** commit (existing `disaster-impact.spec.luau` now asserts the projected corridor boundaries and strict non-immunity outside).
3. Roblox Studio with eight actual round participants (human + bots), activate first and second generators; observe world-space field, physical link, absorbed-damage counter, correct 8-second intersection, bot participation and all four relay claims. Verify actual positions and damage both inside/outside a linked lane.
4. ShrinkingArena/Double Chaos: take away the floor under an active control and confirm neither a local field nor connected linked route survives. Low-end Android p95 FPS and real field visibility, including hazard warning circle occlusion; desktop visual parity; capture 15 genuine screenshots per map.
5. Only after genuine checks and authorized public-release action, publish to existing `10771083668` / `95351659174730`. A green older commit `635b6b234fa09674a9fc47cca66125efd4161080` does not certify a newer untested branch.

Publication is separate from merging code.
