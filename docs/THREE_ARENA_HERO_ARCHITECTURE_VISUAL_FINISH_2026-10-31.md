# Classic, Crossroads, Orbital — architectural hero-object finish

31 October 2026 · Source-only refinement. The public Roblox experience is not modified by merging this change.

## Context and source inspected

- The previous [direction bible](VISUAL_ART_DIRECTION_BIBLE.md) calls for distinct non-neon silhouettes and physically credible supports, with gameplay danger remaining visually dominant.
- The client-owned `src/client/arena-architectural-details.client.lua` already draws outboard, anchored, noncolliding architecture for all five variants and uses one shared 5 Hz cosmetic tick plus its existing map/VFX-tier cleanup.
- The real Android screenshots showed hard, repetitive cuboid architecture. The existing Classic archive was a flat-roof box, Crossroads concourse had a flat slab plus broad neon stripe, and Orbital's floating ring lacked clear diagonal supports.

## Finished source changes

| Arena | Improvement | Additional medium parts | Additional high parts | Low |
| --- | --- | ---: | ---: | --- |
| Classic | Two sloped corroded-metal weather caps, ridge seam, receiver mast and transverse aerial; reinforced cap end brackets only on High | 5 | 7 | No extra parts |
| Crossroads | Two pitched concrete canopy wings and two angled corrosion-resistant steel stays; three High roof vents; convert nonsemantic full-width neon fascia to muted metal while keeping the functional lane signals luminous | 4 | 7 | No extra parts, fascia more restrained |
| Orbital | Tilt existing two dock wings toward the ring; add two actual endpoint-aligned metal load trusses and, on High, two spherical joints plus two cross braces | 2 | 6 | No extra parts, stronger tilted silhouette |

**Budget:** Only the active map's prop builder runs, so the maximum incremental count is **7 decorative `BasePart`s at once**, not 20; 0 extra on Low. VisualBudgetRules already counts the `ArenaArchitecturalDetailsLocal` folder against the shared High/Medium/Low part limits (900/680/440). No additional lights, postprocessing, decals, particles, remote events, data replication, scripts, per-frame callbacks or physics.

All geometry is purely client-side, anchored, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`. The new slope uses `WedgePart` with the existing fold lifecycle and follows the same scenery LOD as existing owner geometry. The Orbital braces are static and derive lengths/orientations from explicit in-world endpoints. The previously animated scanner, transit signal lights, Orbital collar and other movement keep their original track and ReduceMotion behavior.

## Risk and acceptance before publication

1. **Real Roblox Studio**: inspect Classic, Crossroads and Orbital from four playable camera angles each. The added caps, supports and vents must not appear disconnected or visually occlude the playable routes. In particular, inspect Orbital braces from perpendicular viewpoints.
2. **Mobile Low/Medium/High**: verify Low retains a strong silhouette without extra parts, and Medium/High parts obey live quality tier rebuild and scenery distance LOD. Verify one unique set per arena after StreamingEnabled map swaps.
3. **Gameplay**: no collision, CanTouch, CanQuery or line-of-sight interruption from cosmetic geometry. Hazard glyphs and movement paths remain legible.
4. **Resource gate**: run exact commit `Build Validation` and all five existing Roblox Open Cloud engine suites before any future public publishing; inspect actual mobile FPS and thermals, not just static part counts.
5. **Honest limits**: these native Roblox geometry improvements are not proof of AAA visuals. Material 2K normal/roughness/metalness binding, art review and in-Studio screenshots still require independent validation.

No new unit tests were added and no final engine pass, real screenshot review or public publishing is claimed for this source-only change.
