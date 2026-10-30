# Chaos Survival — Storm Harbor original 3D silhouette, Android-first

**Status: authored source candidate, NOT part of the 2026-10-30 frozen release.**

## Defect and intended experience

Storm Harbor received its server-authored four cargo gantry crane fleet and original six approved Roblox 3D assets, but its separate local skyline finishing layer was incomplete. The four-tier `ArenaSilhouetteAccentKit` had only Classic / Towers / Crossroads / Orbital profiles: **Harbor received zero Low-tier pieces**, while `arena-silhouette-breakup.client.lua` routed all unrecognized variants through Classic's survey mast. That left the fifth arena with accidental Classic visual identity.

## Finished source changes

- **Correct fifth identity on Low-tier Android:** add genuine offshore Harbor `MooringSpire`, inclined `DockBoom` and armored `CargoHoist` (three independent volumetric parts). High tier includes a fourth navigation crown. All parts anchored; touch, collision, spatial query and shadows off; strictly outside the 320x320 physical floor.
- **Medium/High coherent waterfront:** replace Classic's fallback with a distinct freight terminal, comprising an exterior berth, two outboard mooring pylons, an overhead steel truss, two visible freight containers and restrained navigation marker. High-tier adds two bolted pylon crowns and two suspended cable hangers; Medium contains seven cosmetic pieces, High eleven. None intersects the authored Harbor piers, sweeps, escape routes, player spawn area, or bot destinations.
- **Actual LOD numbers:** Low uses the pre-existing `ArenaSilhouetteAccentKit.count("Low") = 3`, Medium three authored accent pieces + seven freight terminal parts, High four accents + eleven terminal parts. Existing pair of outboard safety stations remains unchanged and receives its original phase-driven signals.
- **No network or performance tax on gameplay:** zero new server physical parts, remotes, textures, sounds, lights, particles, `Heartbeat` listeners or `RenderStepped` connections; client rebuild/cleanup follows the existing map lifecycle, quality-tier switching and rotating-arena follower. Materials are built-in CorrodedMetal/Metal/DiamondPlate/Concrete with muted industrial palettes; warning red remains reserved for real hazards.

## Finished ground-identity follow-up

The skyline fix exposed a matching defect in the separate, client-owned `arena-surface-relief.client.lua`: **Harbor still ran `addClassic`** for the Medium/High floor materials, giving a cargo port the same machined survey hatches as Classic Grid. This follow-up adds a real, separate `addHarbor` branch.

- Four true outlying quay/cargo-corner locations (`±0.78·halfX`, `±0.77·halfZ`) avoid the original 8 spawn points, central cargo sweep lanes and four switchback entry corridors.
- On **Medium**, four 7.8-stud stamped cargo cleats with built-in rusted steel/wood planks and four narrow metal load-line insets: **8** collision-free cosmetic Parts. On **High**, eight cleats and their eight embossed inset lines plus four low-profile mooring tie-downs: **20** original cosmetic Parts. The existing shared floor and its exact physical/platform shape remain unchanged.
- On **Low**, the existing `addEssentialDeckRelief` is still the only deck art. Harbor receives **zero additional floor geometry** at this tier, retaining its original join/render budget.
- Every cosmetic strip is set just above the real server arena inset by `ArenaPresentation.deckArtOffset`, with `CanCollide=false`, `CanTouch=false`, `CanQuery=false` and no shadows. The existing `ArenaFloorFollowerKit` moves the visuals with Shrinking Arena, not a new loop.
- No new SurfaceGui, Neon, sound, network or PBR texture download. Real amber/red cargo sweep zones remain separately painted by the server and the existing hazard system.

**Visual QA:** compare Harbor and Classic screenshots at Low/Medium/High and daylight/rain/night; verify four dry-dock corners are distinct from Classic's hatches, visually above the floor (not hidden underneath its inset), and remain exactly attached when Shrinking Arena transforms the base. Verify they never obscure actual sweep warnings or 90-degree routes.

## QA gate

Existing Roblox Cloud engine `tests/engine/vfx-quality.spec.luau` now checks distinct exact names, three/four-part LOD limits, correct Harbor-specific noncolliding materials and world-to-rotated-arena exterior positioning.

**Not yet executed:** at next significant build milestone, run exact-SHA checks on the new version; visually verify 5 maps for false Classic identity, Harbor silhouettes at low/medium/high quality, nighttime/rain, near/far/mobile first-frame streaming. Confirm 30 FPS target on representative low-end Android before claiming device performance. Since this is exterior cosmetic geometry, gameplay collision must remain unchanged.

The previously frozen public-update candidate is `82f925c320b2525a58acb4944e74435a75a2795c`. This Harbor code is intentionally held on a **separate unmerged feature branch** until that public update has an independently verified outcome. Do not merge during the exact-SHA validation/publishing workflow.
