# Chaos Survival — finish original exterior and lobby 3D architecture

Source target: November 3, 2026. Public playtest only after exact-commit validation.

## What changed

All five 320-stud maps obtain **four original exterior architectural casings** over existing noncolliding landmarks. Classic uses the radio fins, Towers the exterior machinery, Crossroads the outer gantries, Orbital four spaced reactor nodes, Harbor four new outboard cargo signal housings. Each housing contains 12 real 3D volumes: dimensional metal faces, sloped wedges, recessed equipment boxes, diagonal spars, buttresses, weather guards and beacon structures. Original per-map material families include diamondplate, corroded steel, foil alloy and reactor ceramic.

The original lobby receives **four rebuilt pylon silhouettes** (16 extra parts) and **a machined entrance surround** (5 extra parts); original lobby geometry and its spawns remain untouched. Total new original visuals per active map: **48 exterior + 21 lobby = 69 noncolliding cosmetic parts**. Unlike a distant-only light billboard, these are real locally generated 3D geometric structures at the same positions as their existing simplistic counterparts.

The existing Android scenery LOD loop now culls each exterior housing by its own actual model pivot under the same district-architecture thresholds. No extra recurring task or new unlicensed Roblox asset ID is added. The original 2K PBR selector can use one/two panels per approved house model at Medium/High, subject to the unchanged global quota. Low retains inexpensive native palette materials.

## Bug fix

The premium ownership validation in PbrDistrictRules.eligiblePart accidentally referenced an unbound global owner before declaring the real local parent. In the arena folder this silently skipped the allowlist restricting which surfaces PBR may retexture. The function now captures the true direct parent before validating provenance and restricts new exterior model PBR to creator-authored non-colliding structural Part surfaces. This preserves player/hazard/character materials and excludes imported mesh SurfaceAppearances.

## Gameplay compatibility

Exterior models are **beyond** the active floor edge and stay there through shrinking: they do not advertise safe walkways. Every added Part has Anchored=true, CanCollide=false, CanTouch=false and CanQuery=false. Lobby steel armor is non-colliding around the original physical gate. All new pieces use no interactive controls, sounds, new lights, particles, additional navigation or scripts per part.

## Release decision

Before public release, require Luau syntax/build verification on source, full Rojo place build, **all five Roblox real-engine suites on the exact merged SHA** and a successful guarded publisher. Build/engine results are evidence only for tested code and do not prove visual fidelity or actual Android FPS. The owner should visually inspect the live five maps and report wrong edges, floor overlay conflicts, or performance regressions after publication. Do not claim every default Roblox shape/material is gone until physical review confirms it.
