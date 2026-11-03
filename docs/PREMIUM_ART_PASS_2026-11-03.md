# Premium art direction: original 3D, 2D surfaces, PBR, five-map lighting

**Source milestone: 2026-11-03.** This is a visual production pass for the existing published Chaos Survival universe 10771083668, not a new Roblox experience.

## Verified baseline

As inspected at the start of work, main commit `22308afc4dded7e84c165734cd72dbf40a7cc7bb` was published successfully in GitHub Actions run [41601949632](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41601949632), with Build Validation [41601357440](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41601357440) and five real Roblox Cloud engine suites [41601366082](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41601366082) passing. This milestone must be revalidated on its own exact SHA; historical green checks do not certify new code.

## Actual 3D geometry replacing toy edges

`MapBuilder.addPlatformFinish` previously created **four ordinary rectangular Parts** along every physical landing's edges. The exact same four **named** decorative pieces are now `WedgePart` bevels with correctly oriented outward structural slopes on north/south/east/west. This is a real change in mesh geometry and silhouette, not only Color/Material. No new Parts are allocated. Server-owned true collision/platform walkability and map-specific gameplay constraints are not modified.

These cosmetic wedges keep the original `PlatformBevelN_side` names recognized by `ShrinkingArena`; their CFrame and width follow the actual deck during shrinking and compact-route contraction. They have `CanCollide=false`, `CanQuery=false`, `CanTouch=false` and `CastShadow=false`. In a before/after visual compare, their top side must stay visibly below the true walkable surface and should not form fake ledges.

## Real approved mesh residency on Android

`OriginalMeshScenery` already securely mounts six moderator-approved, creator-owned **actual 3D model packages** in eight outside-the-arena slots, with native structural fallback. However, the client LOD hid **every** imported MeshPart on Low and kept them within only **140 studs** on Medium. With five 320-stud maps this meant most mobile players saw only the standard fallback geometry.

Now the existing single Android LOD owner ranks the eight already-mounted imported models by actual camera distance; it admits at most **one** model within 150 studs on Low, **three** within 245 studs on Medium, and all eight on High. All unselected models are hidden client-side. Already-approved asset IDs are reused from the pinned registry; no unlicensed Roblox catalog imports, new async downloads, render loops, physics or gameplay obstacles. If a model is missing or cannot load, the existing native fallback remains.

These numbers are **caps**, not guarantees that the model is present or visible everywhere. Android physical frame time and texture loads still need a real client review.

## 2D graphic assets authored in code (no generic image IDs)

`UITheme.addMachinedFrame` renders an original resolution-independent 2D engraved metallic treatment: corner-cut registers, manufactured alignment marks and subtle rivets. It is integrated into the main HUD, READY/countdown, result card, login/splash brand panel and event card. Unlike generic Roblox default frames, these details have an art-directed industrial grammar with colors harmonized to the existing hazard glyphs.

This is **original UI vector geometry**, not a claim of new uploaded bitmap/icon assets; Roblox image uploads require a separately approved creator asset ID. Nothing is fetched from a third-party CDN at run time. Graphics have zero animations and no per-frame callbacks, preserving touch controls. The UI panel palette is raised from near-black to legible, neutral blue-grey while preserving bright white text and warnings.

## Five lighting grades, material relief, safety

The single existing `arena-lighting.client.lua` post-processing owner now uses five refined, mostly neutral daytime light palettes. The old colored atmospheric wash (especially magenta Crossroads / saturated mint Orbital) obscured PBR relief. Outdoor ambient and material fill are higher, lobby shadows read better, and bloom intensity is reduced on High. Each arena retains its unique color and natural sky identity while keeping disaster-owned exposure, danger warnings and temporary post-processing under **existing** owners, not a second competing Lighting controller.

The approved `MaterialService` 2K Color/Normal/Roughness/Metalness MaterialVariants remain unchanged, including the exact preapproved image IDs. The original `GeneratedMap/Arena/Decor` 2K surface quota rises from **7 to 10** on Medium and **12 to 18** on High to cover more actual camera-near deck/landing surfaces, still inside the unchanged touch-device **32 Medium / 72 High global quota**. Low preserves inexpensive native material fallback. No PBR applied to colliding hazard parts or other people's imported models.

## Release and completion criteria

- Full Luau compile (not only parsing modified files) and full Rojo place build for the **exact candidate**.
- Android first-frame visual budget gate and build identity/provenance.
- Five real Roblox Cloud engine suites and exact-SHA validation after merge.
- A guarded public release only after those pass, with the same already-public universe/place and no creation of a staging experience.
- Physical Android inspection of all five arenas, lobby, HUD/vote/READY/results, night/disaster lighting, imported MeshPart visibility, rendering rate, platform collapse/shrink and 8-player bot sessions. Automated Cloud tests do not certify AAA fidelity or true device FPS.

**Important:** Replacing *every last* default Roblox 2D bitmap and MeshPart with unique professionally authored content is **not yet demonstrated**. That requires a visual inventory from real captures, new approved model/texture IDs where needed, and mobile asset-performance checks. This milestone genuinely replaces visible primitive geometry and improves existing creator-owned assets and the screen/lighting language, but does not claim a completed AAA commercial-quality art audit.
