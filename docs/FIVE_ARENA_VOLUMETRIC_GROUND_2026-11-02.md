# Five-arena original volumetric ground finish — 2 November 2026

## Scope and architecture
The live experience previously had a single enormous native tiled surface named ArenaDeckInset covering a 320-stud survival arena. Even with owned PBR, this still read as a basic Roblox plane on Android.

This pass provides **65 additional genuinely authored decorative BaseParts per currently active arena**, not per player and not five arenas simultaneously:

| Element per active map | Count | Purpose |
|---|---:|---|
| PremiumGroundModule1..36 | 36 | 6x6 flush engineered, matte, colored structural panels; PBR eligible |
| PremiumGroundServiceInlay* | 12 | Thin original engineering service seams |
| PremiumGroundGusset* | 9 | Real volumetric native WedgeParts for corner treatment |
| PremiumGroundUndergirder* | 8 | Volumetric lower hull supports at the arena edges |
| **Total** | **65** | No external asset IDs, lights, physics changes, scripts per piece, or per-frame rendering loop |

The five arena profiles each receive a consistent finish sourced from the **already approved creator-owned original 2K material maps**:
- Classic — industrial reinforced diamondplate.
- Towers — brushed titanium alloy.
- Crossroads — oxidized steel.
- Orbital — technical reactor ceramic.
- Harbor — salt-worn steel with existing small timber accents.

## True gameplay ownership, not misleading artwork
Ground modules and grooves sit between the existing floor inset and priority wayfinding overlays. Their highest level is physicalTop +0.1705. They are CanCollide=false, CanTouch=false, CanQuery=false, anchored, with zero light emitters and no triggers. They do not replace orange/red hazard telegraphs, and are not fake walkable platforms.

ShrinkingArena recognizes the PremiumGround prefix and **transforms and scales all 65 floor elements continuously with the actual contracting base**. Cleanup restores original sizes and CFrames. Neither DisappearingPlatforms, AI movement, player spawns nor physical platform shapes change.

PbrDistrictRules admits **only** the exact tagged PremiumGroundModuleN surfaces under original GeneratedMap > Arena > Decor. This is not a generic Workspace retexture and preserves the existing 32 Medium / 72 High Android global 2K surface limit, with Low retaining native inexpensive fallback.

## Next phase and release gate
This is a large **source-only** visual milestone, **not** a claim of fully replacing every standard Roblox texture or fully AAA-scored world. Other legacy engine-native decorative meshes remain, particularly low-tier mobile route trims, imports and far scenic props.

Before public publication: full Luau compiler and Rojo build, five real Roblox Cloud engine shards on exact merged source SHA, then physical Android visual QA of all five worlds verifying lighting, safe route cues, PBR budget and shrink/restore behavior. Existing public version unchanged until explicitly published.

Source: src/server/ArenaGroundArchitecture.lua, src/server/MapBuilder.lua, src/server/Disasters/ShrinkingArena.lua and src/shared/PbrDistrictRules.lua.
