# Chaos Survival — Storm Harbor original 3D silhouette, Android-first

**Status: authored source candidate, NOT part of the 2026-10-30 frozen release.**

## Defect and intended experience

Storm Harbor received its server-authored four cargo gantry crane fleet and original six approved Roblox 3D assets, but its separate local skyline finishing layer was incomplete. The four-tier `ArenaSilhouetteAccentKit` had only Classic / Towers / Crossroads / Orbital profiles: **Harbor received zero Low-tier pieces**, while `arena-silhouette-breakup.client.lua` routed all unrecognized variants through Classic's survey mast. That left the fifth arena with accidental Classic visual identity.

## Finished source changes

- **Correct fifth identity on Low-tier Android:** add genuine offshore Harbor `MooringSpire`, inclined `DockBoom` and armored `CargoHoist` (three independent volumetric parts). High tier includes a fourth navigation crown. All parts anchored; touch, collision, spatial query and shadows off; strictly outside the 320x320 physical floor.
- **Medium/High coherent waterfront:** replace Classic's fallback with a distinct freight terminal, comprising an exterior berth, two outboard mooring pylons, an overhead steel truss, two visible freight containers and restrained navigation marker. High-tier adds two bolted pylon crowns and two suspended cable hangers; Medium contains seven cosmetic pieces, High eleven. None intersects the authored Harbor piers, sweeps, escape routes, player spawn area, or bot destinations.
- **Actual LOD numbers:** Low uses the pre-existing `ArenaSilhouetteAccentKit.count("Low") = 3`, Medium three authored accent pieces + seven freight terminal parts, High four accents + eleven terminal parts. Existing pair of outboard safety stations remains unchanged and receives its original phase-driven signals.
- **No network or performance tax on gameplay:** zero new server physical parts, remotes, textures, sounds, lights, particles, `Heartbeat` listeners or `RenderStepped` connections; client rebuild/cleanup follows the existing map lifecycle, quality-tier switching and rotating-arena follower. Materials are built-in CorrodedMetal/Metal/DiamondPlate/Concrete with muted industrial palettes; warning red remains reserved for real hazards.

## QA gate

Existing Roblox Cloud engine `tests/engine/vfx-quality.spec.luau` now checks distinct exact names, three/four-part LOD limits, correct Harbor-specific noncolliding materials and world-to-rotated-arena exterior positioning.

**Not yet executed:** at next significant build milestone, run exact-SHA checks on the new version; visually verify 5 maps for false Classic identity, Harbor silhouettes at low/medium/high quality, nighttime/rain, near/far/mobile first-frame streaming. Confirm 30 FPS target on representative low-end Android before claiming device performance. Since this is exterior cosmetic geometry, gameplay collision must remain unchanged.

The previously frozen public-update candidate is `82f925c320b2525a58acb4944e74435a75a2795c`. This Harbor code is intentionally held on a **separate unmerged feature branch** until that public update has an independently verified outcome. Do not merge during the exact-SHA validation/publishing workflow.
