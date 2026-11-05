# Five-arena genuine 3D undercarriage and column distribution

**2026-11-05 / VIS-009/010**, code-level milestone, not proof of published Roblox runtime or Android image quality.

## Source gap

The five worlds already load the creator's moderated `LongCradle` MeshPart model (ID 128914328933863) and unique 3D support columns (Classic / Towers / Crossroads / Orbital / Harbor). The existing `PremiumLargeStructureMeshKit.selectNearRouteStructures` sorted only by static camera proximity, so on 320×320 arenas four High / two Medium long underframes and up to eight/four owner-supported columns could all cluster near the initial spawn while the far half remained generic native rectangular truss/columns.

## Implemented

- **LongCradle**: preserve two nearby High / one nearby Medium models; the other two / one positions maximize real 3D deck separation while remaining authenticated real `PlatformN` with `SkySpineStep` or `PromenadeStep` and compatible size. Hard budgets **High 4 / Medium 2 / Low 0** unchanged.
- **Support columns**: preserve five nearby High / two nearby Medium owner-supported decks, distribute the remaining three/two slots across other real `PlatformSupportN_K` owners with already moderated 3D column sources. The maximum platform selections remain **High 8 / Medium 4 / Low 0**, and actual model-segment modules remain capped by the existing **16 High / 8 Medium** supply.
- Selection is deterministic for the same set of physical candidates and owner names. It runs only in the existing map/tier/streamed-model build, and is bounded by at most 8 selections. No new camera/render sampler; no gameplay actor, collision or phantom route.
- The previously added late `Arena.Decor` event recovery and strict original/native fallback remain in force; the selection will adapt to newly replicated source-backed supports on the scheduled coalesced rebuild.

## Remaining QA

Check each of five maps at start and distant sectors with source mesh counts, native structural masks and correct collapse/shrink. Exact-SHA build/Roblox Engine milestone and real Android Low/Medium/High captures still required. A model selected does not guarantee it was successfully mounted or visible; we do not claim achieved 90% source coverage or actual FPS.
