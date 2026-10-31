# Five-arena near-route district roofline profiles — 31 October 2026

## Scope and rationale

The real Android screenshots show repeated box-shaped industrial masses. The five maps already have four **near-playable, fully cosmetic** sector identity monuments (`src/client/district-sector-setpieces.client.lua`), which are more relevant to platform traversal than generic distant skyline geometry. Existing commit #465 establishes a distinct color/architectural vocabulary for Classic, Towers, Crossroads, Orbital and Harbor. Rather than adding new distant scenery, this change makes the actual *silhouette* of the existing sector structures less rectilinear.

## Authored geometry, per map

Each of the four sector monuments receives exactly **two small opposing, sloped structural WedgeParts** on Medium and High; all are anchored, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false` and stored in the existing `DistrictSectorSetpiecesLocal` model.

| Arena | Roof/shoulder silhouette | Native finish |
|---|---|---|
| Classic | Twin weather caps around the survey/receiver mast | CorrodedMetal |
| Towers | Paired lift motor cowls on the gear guide tops | DiamondPlate |
| Crossroads | Dual sloping transit canopy eaves | Concrete, preserved |
| Orbital | Gabled ceramic crowns on the containment wing pair | CeramicTiles |
| Harbor | Two tapered cargo-terminal gantry weather hoods | CorrodedMetal |

The profiles are an immutable shared module-level recipe, not generated tables per monument. There are **8 additional local Parts per loaded map** on Medium and High, **0 additional on Low**, no new lights, events, animations, physics, connections or Remotes. They use existing `MapVisualReadiness`, map clearing, tier rebuild, distance LOD, and the `VisualBudgetRules` local folder tally. No gameplay landing surfaces or fake ledges were created.

Existing runtime tier assertions are preserved and updated to **4 Medium / 5 High variant macro pieces per monument**, including the original 2/3 rectangular pieces. Final full-model count assertion remains **<=16 Medium / <=35 High** and Low remains the original five-part identity. The most detailed High power station remains at approximately 30/35 parts; the highest Medium cargo sector at 15/16 parts.

## Acceptance — only at next important release milestone

- Inspect real Roblox Studio camera captures in all five arena variants and compare against the screenshots. Confirm each distinct silhouette is visible from a route toward its sector, with no roof collisions or overlapping directional text.
- Roblox engine exact-SHA build, five existing Open Cloud suites and visual budget checker before any public release.
- On Android Low verify exactly five Parts per sector and no perf regression; on Medium and High verify all new wedges follow map swap, StreamingEnabled and VFX tier changes.
- Do not claim 4K PBR texture maps, imported meshes, screenshot certification, mobile FPS or actual Roblox publication from this code-only geometry change.

Last independently verified **public experience** remains SHA `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f`. Source SHA will be recorded by the subsequent PR merge.
