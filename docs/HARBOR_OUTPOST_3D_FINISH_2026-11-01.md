# Storm Harbor — original 3D service architecture on four playable dock outposts

Date: 2026-11-01. Baseline `main`: `775bec62946986dac2f88aae5d4075bac7127bff`.

## Scope / design intent

Four actual server-authoritative terminal platforms, identified by `HarborSpokeRoute = 1..4` and `HarborSpokeStep = 4`, already exist in Storm Harbor. Instead of duplicating their physical platforms or adding fake walking floors, this enhancement gives each an authored, recognizably **3D** service structure following the genuine platform's geometry.

- **North (StormRadar):** long-range weather radar, taller paired frame and cylindrical array.
- **East (CargoHoist):** broader lower hoist with a horizontally oriented metal drive drum.
- **South (TidalBeacon):** narrower signal arch and round stone-composite weather beacon.
- **West (SignalArray):** highest communication assembly with a tilted cylindrical receiver.
- Industrial alloy, weathered metal, coastal-muted signature colors; no neon, lights or flashing animations obscuring genuine meteor/bomb/lava warnings.

## Integration and bounded budgets

New pure builder `src/client/HarborOutpostKit.lua`, called only from existing `arena-platform-identity.client.lua` within the Harbor branch. It takes the **existing `makePart` factory** rather than starting an independent controller, using its owned `ArenaPlatformIdentityLocal` folder, platform registrar, `PlatformIdentityWeld`, `ChaosBaseTransparency`, `PlatformFinishKit.bindRouteFootprint`, `applyCollapseVisibility` and tier-triggered rebuild/cleanup.

| Tier | Parts per terminal | Four terminals | Conditions |
| --- | ---: | ---: | --- |
| Low | 0 | **0** | Original server-owned solid decks, finish and label remain |
| Medium | 5 | **20** | Under-deck keel, two edge legs, crossbar, mechanical instrument |
| High | 9 | **36** | Medium plus two machined knees and two sensor vanes |

No RemoteEvent, RunService loop, physics authority, collision, query/touch, emitted particle, added light, paid asset, texture download, extra MaterialVariant, server side spawn or external model import. Visual geometry uses `Part` with Roblox native cylinder/sphere shapes and fixed original palettes. Every new part remains anchored *through its existing adjustable weld* to the actual physical terminal, is Massless, and is subject to the already existing shrink/collapse visibility owner. Variants are tied to server attributes, never guessed from array iteration order.

## Required acceptance at the next actual Roblox milestone

- **Geometry:** confirm exactly 4 distinct target endpoints, no new cosmetic children on other 106 Harbor platforms; 0/20/36 new Parts at Low/Medium/High when all four terminal docks are streamed. Confirm none have `CanCollide`, `CanTouch`, `CanQuery` or `CastShadow`.
- **Camera and walkability:** on Android 320..440px third person, confirm structures at the **outward deck edge** do not conceal intended jump landing, route sign or active catastrophe warnings. A non-collidable frame must not be mistaken for a solid escape platform.
- **Streaming and map swaps:** repeatedly enter/leave Harbor, change Low→High→Low, shrink floors, switch `CollapsePhase` through Warning/Gone/clear. The 3D parts must resize with real deck, fade under the warning, vanish in Gone and restore without duplicate parts or stale welds. Ensure Cleanup disconnects existing platform listeners.
- **Art check:** real camera screenshots at the same distance, at daylight/night/storm, should distinguish north radar, east cargo hoist, south beacon, west communications without screen-space floating labels.
- **Performance:** capture actual Roblox Studio/Android FPS, memory and worst frame-time with live disasters, AI and 30-minute map cycling. High is 36 new inexpensive local Parts maximum, not an empirically established FPS budget.
- **Release:** Build Validation and all five Open Cloud suites on the same **exact final SHA**, authenticated Studio + physical Android smoke before a new single public publication. No private test experience required.

**Source inspection and geometric checks do not certify real rendering.** Current public build still corresponds to verified SHA `e8767c98c475a3efb39ed53ed7bbe16efa1865d2` until a successful publisher is observed.
