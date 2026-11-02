# Sky Route Monumental Architecture — five authentic 320-stud escape worlds

**2026-11-02 — source integration, not an automatic public Roblox update.**

## Why this specific major visual change

The owner supplied six actual Android screenshots. The game already has substantial cross-arena geometry but its repeated simple cubes, darkness, neon decoration and small distant route hints make the safe ascent difficult to recognize at a glance. The last certified main source SHA `534c4eaad8c031edb55c88ca884c123698f4015d` has green **Build Validation** (run 41448424985) and **all five Roblox Cloud engine suites** (run 41448510356). Those certifications cover the preceding bot recovery / Android lighting update, **not this new architectural candidate**.

## A large, authored environmental transformation

**Twelve unmistakable full-height 3D ascent landmarks per arena** replace the sense that every escape route is an identical anonymous cube:

- Each of the **four genuine 8-deck perimeter ascent routes** gets an enormous **ENTRY** visual gate on its first reachable 3D deck, a different **TRANSFER** gate at step 4, and a **SUMMIT** crown at step 8. There are 60 staged landmark portals across the five different built maps in source, but only the current arena is instanced during a match.
- Each landmark has **two tall outside-edge bridge pylons**, inset glowing power ribs, angled heavy WedgePart fins, big machinery abutments below the deck, a 12.1-stud-high wide structural crosshead, an elevated stage beacon, and recessed below-deck metalwork. Native physical 3D silhouette, not a single emissive rectangle.
- Both ENTRY and TRANSFER display small *real geometry* wayfinding chevrons pointing along the existing actual 8-step escape route, while SUMMIT carries a high beacon instead of misleadingly pointing off the end of the map. The center of the **real** walking platform stays unobstructed and visibly walkable.
- Five bespoke architectural signatures, not merely recolors: Classic industrial survey antennas; Towers glass transit monitoring; Crossroads angular road exchange housings; Orbital suspended reactor spheres and metallic rotor rings; Harbor weathered port crane booms with hanging hooks.
- Visual roles reflect actual physical elevation: stage `ACCESS`, `TRANSFER`, `SUMMIT`; colors differentiate entrance vs intermediate checkpoint vs highest exposed deck without using the orange/red disaster warning palette. No extra floating text panels / intrusive HUD / fake achievement displays.

## Runtime safety and Android budget

1. Every single visual part is anchored, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, shadow-disabled, and directly tagged `PerimeterPlatformIndex` matching its **real server-owned `PlatformN` deck**. No gameplay collider changed, no new `Platforms` entries or IDs, no changes to AI routing, stats, rewards or damage.
2. Twin structural pillars sit **outside the real deck's lateral Z edges** and the main overhead crosshead is over **11 studs above its physical deck**, preserving full R15 jumping/camera clearance. The lower steel abutments and mechanical girder remain below the support deck and never project an opaque fake walkway.
3. `ShrinkingArena` follows this explicit parent-platform tag to move each large art piece with its own actual deck; `DisappearingPlatforms.cosmeticsForPlatform` and `ArenaStructuralCollapse` use the same tag to hide *all* art as soon as its collidable parent is marked for collapse. There is no misleading ghost safe platform.
4. Strong native-Material depth (Foil, CeramicTiles, DiamondPlate, CorrodedMetal, Metal and Glass). Neon is strictly restrained to the paired power traces, overhead route cue and two arrow strips. No real-time lights, huge transparent cones, particles, new meshes, external asset IDs, per-frame callbacks or client remotes.
5. **At most 16 thin decorative parts per monument**, and only 12 physical route checkpoints per arena, so a worst-case total of 192 static anchored parts per instantiated arena. Most portals use 13–15 parts. These are regular Roblox native parts that already benefit from map streaming and the existing mobile decor-opacity policy. True Android p95 FPS and occlusion still require physical playtest; no fictitious performance claim.

## Engine and physical acceptance

An extended existing `tests/engine/mapbuilder.spec.luau` checks, on **all five authored maps**:
- Exactly 12 landmark stage checkpoints on the correct 4× real physical perimeter routes; 1/4/8 step classifications.
- All portal structural pieces owned by the exact `PlatformN` index, anchored and collision/touch/query/shadow-free.
- Main pylons outside the platform's true Z footprint, actual 12-stud overhead route crossheads, and 2 arrow strips only at navigable entry and transfer checkpoints.
- Hard summit deck collapse makes every branded monument piece disappear with the platform collider, and original graphics are restored when the collapse ends.
- The old physical `Platforms` folder count is unchanged on all five maps, protecting 8-bot routing, sky bridge connections, damage and collectible physics.

**Milestone:** run EXACT merged-SHA compiler/Build Validation and all five Roblox Open Cloud engine suites before declaring ready. If any fail, repair on the same branch / new SHA and rerun only at the important milestone. Real Studio and Android must then establish: from ground players can see the high routes; new beacons are not mistaken for a safe active shield; mobile night/day contrast preserves hazard telegraphs; no new frame-rate regression or path obstruction; all authentic team members still fit and move. Only a separate, gated authenticated publication action may change the existing Roblox public place `95351659174730` / universe `10771083668`.

This change intentionally finishes **one** major world-readability feature rather than staging unfinished unrelated mechanics.
