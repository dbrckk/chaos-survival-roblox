# Storm Harbor — original port service props, post-release feature

Date: 30 October 2026. **Development branch only — NOT YET PUBLISHED.**

## Inspected defect

`src/client/arena-service-props.client.lua` dispatched `Harbor` to `addClassic`, which placed Classic TV camera tripods, lenses and their geometry across Storm Harbor. That was an actual art-direction defect, not an absence of documentation. The source already provides proper Harbor cargo cranes, dock relief and five map palettes; this fix completes the service prop family without replacing any working systems.

## New original 3D construction — playable-port service equipment

- Dedicated `addHarbor` with six distinct mooring locations on the playable dock edge. No Classic fallback.
- Each fitting has a separate physical-looking corroded-steel footing, vertical iron stem and T-shaped mooring head. Medium/High add two rounded anchor bolts and a legible BERTH marking. High adds a wear plate.
- Mobile VFX LOD preserves 2 / 4 / 6 mooring fittings on Low / Medium / High, a bounded 6 / 20 / 36 local cosmetic Parts respectively; no imported assets or Roblox purchase.
- Everything remains anchored, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`; cosmetic only, not interactable or a fake safe walkway.
- Uses the existing `ArenaFloorFollowerKit` for shrink-follow and the existing map/quality lifecycle. No new loops, remote events, network replication, physics, external scripts, or lights.

## Distant Harbor skyline — no Classic television structures

A second real fallback was found in `src/client/arena-midground-mass.client.lua`: Harbor also invoked Classic's floating TV-transmitter blocks. It now has dedicated maritime freight barges with layered rusty steel hull, raised 20-foot-container-style body, load sill, Medium/High corrugation ribs and High ridge cap. The complete Low/Medium/High count is **6 / 15 / 32 cosmetic Parts**, representing **2 / 3 / 4 distinct vessel silhouettes**. Every one is outside the playable arena, permanently non-colliding and has no player routes, physics, animation loops or external meshes. All other arena routes remain unchanged.

## Hold / verification criteria

The existing exact-SHA Harbor deck finishing public release gate was running on commit `030e191407ff454a09315c9db66688559e641fff` when this feature branch was created. **Do not merge this feature into `main` before that public publishing gate concludes**, or the safe HEAD check will abort the in-progress release.

Before the **next** public update: run the existing Build Validation and real Roblox Open Cloud Engine Tests on the final main SHA, and verify art in Studio/Android Low/Medium/High if a runner/device is available. Pay specific attention to root spawns, four HarborCargoSweep corridors, sector navigation, shrink behavior, and that Classic camera/lens naming **and ClassicBroadcastMass** are both absent from Harbor. All measurements of FPS/visual quality require real device evidence; they are not certified by this source change alone.

Reference: `docs/PREMIUM_HARBOR_DECK_FINISH_FOLLOWUP_2026-10-30.md`.
