# Chaos Survival — district architecture: service entrances & authored industrial detail

_Date: 31 October 2026 — **source candidate only**. The public Roblox place has not been updated by this work._

## Baseline investigated
- `main` contains 16 collision-free district building models (4 sectors × 4 roof profiles), plus four separate corner landmarks. Four roof silhouettes are already distinguished within `ArenaDistrictArchitecture.lua`, and the five arena variants add their own signature forms.
- The player-facing façade (negative local Z) was mostly a single signal window, two side glass cassettes and roof equipment. The structures lacked a grounded, recognizable industrial entrance.
- `scenery-lod.client.lua` already culls each model by distance for Android Low/Medium, with no collision or hazard ownership. It did not previously support selectively reducing details **inside** a nearby visible model.

## Implemented in this candidate
Each of the **16 district buildings** receives a new original, fully 3D service façade, with the front consistently oriented toward the arena centre:

| Quality tier | Additional rendered parts per visible building | What remains |
| --- | ---: | --- |
| Low | 2 | Large, legible recessed door frame and offset steel entry leaf |
| Medium | 6 | Above plus lintel, projecting weather canopy and paired industrial hydraulic columns |
| High | 8 | Above plus a pair of profile-specific devices: survey cabinets, freight winch housings, turbine collars or aerial conduits |

At full High visibility this adds **128 native anchored parts** across 16 buildings. All 128 are replicated to the client; Low/Medium reduce **rendered visibility**, not network transfer or total Instance count. The building distance LOD still hides complete far-away models. No misleading claim of reduced replication cost.

All added geometry:
- Is **original**, anchored and collisionless, with touch/query/shadows disabled; no doors can be entered or operated.
- Inherits muted per-sector color and the existing mix of corroded steel, metal and diamond plate. No new external textures, paid asset IDs, scripts, remotes, lights, particles, audio or update loops.
- Stays inside the established local building footprint and roof massing. It never changes an actual walkable platform, server-owned hitbox, hazard, spawn, AI path or reward.
- Is authored in one existing server builder and follows the current five arena variants.

The existing 0.65/0.90-second scenery LOD loop reads `SceneryMinimumTier` on cosmetic descendant parts. **Tier switches now invalidate the early-skip fast path**, so a Low→Medium→High switch reveals newly eligible details without requiring a camera move, and High→Low hides them. This change is shared by the same renderer but only applies where the optional attribute exists.

## Risk and milestone release gate
- Because the server still creates/replicates every piece regardless of local visual tier, verify memory, replication and device frametime before increasing detail further.
- New Medium/High pieces are not instantly hidden until the first existing LOD scheduler tick; performance diagnostics should start after settling.
- Do not claim AAA parity or an Android FPS figure from source alone.
- As requested, **no automatic or unit tests are added or triggered during this improvement stage**. Before the next public Roblox update, run the existing manual exact-commit Build Validation and all five Roblox Open Cloud engine suites. Also capture genuine Android Low/Medium/High screenshots from front/side, test quality-tier changes and verify portal details do not imply jumpable surfaces.
- Public release must still target the already approved Universe `10771083668` / Place `95351659174730`, with owner-approved publication workflow and exact-SHA proof.

## Next visual priority
Revisit the **player-facing navigation sightlines**, and audit the distinct original assets and PBR finish from real Android screenshots before further increasing geometry. Move to a second landmark/industrial structure only if observed frame pacing and player comprehension permit it.
