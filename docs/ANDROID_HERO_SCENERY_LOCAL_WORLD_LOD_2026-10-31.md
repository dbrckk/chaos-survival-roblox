# Android — distance LOD anchored to actual hero architecture

31 October 2026. Source-only fix for the existing 5-variant architectural visuals, no new Parts.

## Confirmed problem in main before the change

- `src/client/arena-architectural-details.client.lua` builds exactly one local hero prop outside the 320×320-stud playable base per variant: Classic broadcast archive, Towers counterweight structure, Crossroads transit concourse, Orbital containment dock, Harbor cargo crane.
- `src/client/scenery-lod.client.lua` applies `FOLDERS.ArenaArchitecturalDetailsLocal` to the **arena Base center** with 145-stud Low / 220-stud Medium thresholds. At an arena edge, an Android camera ~150+ studs from center could hide a hero structure close by, while a camera near center could needlessly retain the same distant prop.
- The separately authored server visual `GeneratedMap/Arena/Decor/ArenaHeroArchitecture3D` used the Base center for Medium culling as well, although adjacent imported models and Harbor fleet already use their actual model pivots.

This produces visible low-quality scene popping when crossing the arena, and unnecessary geometry in the mobile distance budget. It was **not** a lack of 3D models.

## Correction

- The existing `baseFrame()` helper publishes the actual `Vector3` position of the currently built local hero to the exact client-only `ArenaArchitecturalDetailsLocal` Folder as `CosmeticWorldOrigin`. This is done once per map or VFX-tier rebuild, not per frame.
- `clear()` invalidates that attribute before destroying previous-map geometry, preventing stale origin references during streaming/map swaps.
- The existing 0.65s Low / 0.90s Medium scenery-LOD loop uses that authored position **only** for the known `ArenaArchitecturalDetailsLocal` owner. Before the source Base exists, it safely falls back to existing arena-origin logic.
- The existing server-authored `ArenaHeroArchitecture3D` is now culled using its `Model:GetPivot().Position`, like approved imported originals. Low essential-hero exceptions and all other owner policies remain unchanged.
- Original 145/220-stud cutoffs, the 8-stud hysteresis, stable cache, client-only LTM masking, PBR variant selection, motion, terrain, physics and hazards are preserved. No new render loop, Instance, RemoteEvent or network call.

## Acceptance at the next important release milestone

1. In all five arena variants, compare Low/Medium from the playable center and from the two nearest outboard edges. Nearby authored hero structures should remain visible until **actual hero distance** exceeds the existing threshold, and distant structures should be culled.
2. Verify `ArenaArchitecturalDetailsLocal` has a populated `CosmeticWorldOrigin` Vector3 after the Base is streamed, and that it is absent during teardown (no old-map silhouette).
3. Verify the server original `ArenaHeroArchitecture3D` uses its actual Model pivot for Medium visibility while Low keeps only `HeroSilhouetteEssential` marked components and High is fully visible.
4. Validate latest exact source SHA with existing Build Validation + all five Roblox Open Cloud engine suites before a public update, and independently verify real Android FPS and appearance.
5. No screenshot, full engine test, mobile thermal certification or public Roblox publication is claimed by this source-only patch.


## Animation/LOD coherence follow-up (31 October 2026)

After the original visual-position fix, a remaining mismatch was found in the **actual** client script. The existing 5 Hz animation loop still gated *all* Classic scanner, Towers lift, Crossroads signal, Orbital collar and Harbor cargo movements using **camera distance to the center of the arena**. On a 320-stud floor, this could stop motion in an outboard prop that was still visibly within its real-world Medium LOD range; conversely, it kept updating Part CFrames on distant hidden props while the camera remained near the arena center.

The same animation loop now reads the already-published `CosmeticWorldOrigin` Vector3 (safe Base fallback during stream-in) and evaluates **the same real outboard location** as scenery LOD. On Medium it keeps the animation budget active through the existing `SceneryLodRules.Hysteresis` (220+8 studs), avoiding a visible static band in which a previously visible prop has not yet been hidden. The High-tier cosmetic animation stays limited to 220 studs as before. Any individual Part whose `SceneryLodHidden` attribute is `true` no longer receives CFrame/transparency animation writes; it resumes from the mathematically current motion phase when the existing LOD returns it to view.

**Budget/safety:** zero new Parts, no new time loop, no animation frequency increase, no server changes, no physics, collision or hazards, no changes to VFX-tier choice or ReduceMotion. The existing `restoreMotion()` remains responsible for static reduced-motion representation.

**Milestone evidence:** verify the five original animations from an Android/Studio camera **near each outboard hero but far from the center**. In particular, check Towers moving counterweight and Harbor hanging cargo from a nearby rim, then check that a hidden prop is not needlessly animated. This is a source-only correction until real authenticated visual evidence is collected.
