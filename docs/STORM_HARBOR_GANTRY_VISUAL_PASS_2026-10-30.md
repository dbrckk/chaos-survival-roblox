# Storm Harbor — original gantry 3D art pass (30 October 2026)

## Scope

This pass changes **source code only**, not the public Roblox experience. It upgrades the four existing out-of-bounds port gantries in `src/server/HarborScenery.lua` while preserving the original gameplay surfaces, event machinery, and authored soundscape.

- Structural depth: paired trolley rails, six diagonal upper-boom truss braces, two leg braces, armored counterweights and a recessed trolley drive per crane.
- Load silhouettes: alternating fully authored static cargo containers and industrial cable drums, connected visually by two short suspension slings per crane.
- Gameplay isolation: all new parts inherit the original builder's `Anchored=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false` and `CastShadow=false`. All four structures remain **outside** the 320 × 320 stud floor.
- No external models, image uploads, scripts, emitters, network events, physics joints, sound loops or additional frame samplers.

## Rendering and texture policy

The existing Android/desktop scenery owner still culls the **whole** gantry per model through `SceneryLodRules.harborGantryOwners`: Low hides these optional cranes, Medium uses its pre-existing 185-stud bound, and High retains them.

Only `StormHarborGantryFleet` descendants with the new `HarborGantryScenery` author tag **and** all existing original/cosmetic/distant-scene tags qualify for `PbrDistrictRules`. Their rigid architecture may use the **four existing, approved 2K MaterialVariants**. The per-model residency cap is **2 on Medium, 4 on High, 0 on Low**. The existing mobile global cap (32 Medium / 72 High), distance gate, PBR OFF option, selection hysteresis, stream index and original material restoration all remain unchanged. Playable or collidable parts and imported models' UV/SurfaceAppearance are not modified.

There are 78 new inert parts across all four cranes (31 per container-bearing crane, 30 per drum-bearing crane, compared with 11 per original crane): each gantry still contains just one atomic streamed model, and no work is scheduled per part.

## Next important publication gate

No automated tests are triggered during improvement work. Before publishing a new public version, run the repository's existing exact-SHA Build Validation and Roblox Open Cloud Engine Tests, inspect the engine/compilation and moderation/access results, then use the guarded public-release workflow.

On the next real Android visual pass, inspect Storm Harbor on Low/Medium/High and check the two distinct cargo silhouettes, gantry facades, PBR AUTO/OFF appearance, FPS/P95 when available, streaming transitions and unobstructed warnings. **No device performance or visual certification is claimed at this stage.**
