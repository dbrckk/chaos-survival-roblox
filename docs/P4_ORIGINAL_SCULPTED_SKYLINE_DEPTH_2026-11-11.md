# P4 — Authored 3D distant skyline roof: source, scoped import, and runtime gate

11 novembre 2026. Source audit: `MapBuilder.addDistantSkyline` creates
`SkylineDepth{North,East,South,West}{1,2}`: eight
`DistantRoofMass` `WedgePart` per variant, **40 generator-side
occurrences across five variants** (one variant active at a time).
Each roof also has a native `DistantAerial` marker.

## Art created in this change

`tools/generate_original_skyline_depth.py` authors a distinctive octagonal
industrial tower, with a tapered multi-ring forged body, open load bracing,
captured facade bolts, slot fins, real-depth ventilation cassettes and
ceramic observation ports. Seven physical materials are separated into
seven glTF mesh primitives; this is actual 3D triangulated OBJ source,
**not** a 2D texture, fake MeshId or an imported part from another creator.

- A single geometry is designed to be adapted across eight deep-horizon
  positions of varying height and width, once an approved Roblox asset ID
  is returned and the exact rendered fit has been checked.
- It uses the existing authored `chaos_route_kit.mtl`; metallic/roughness
  factors are not proof of unique normal/roughness *texture images*.
- The existing game still renders all eight legacy WedgeParts: this commit
  does **not** mask them or introduce unverified IDs.

## Release chain, without cheating provenance

1. `skyline-depth-original-source-regression.yml` builds OBJ + self-contained
   glTF and verifies topology, position attributes, UV/tangents, all seven
   materials, SHA-256, geometry envelope and bounded triangle count.
2. The one-time `one-time-original-skyline-depth-20261111.yml` only
   attempts the **owned Roblox Model upload** on protected main after a
   second source gate. The uploader checks the caller, owner ID, secret,
   explicit acknowledgment and Roblox response; it never publishes a Place.
3. **Only after a real Roblox Approved asset ID is observed:** register the
   model and connect a strict client-side `ApprovedSkylineDepth` substitution
   with streamed native fallback, per-variant owner check, camera distance,
   Low/Medium/High limits and Android budget.
4. Finally run Open Cloud engine checks and a real Android near/far skyline
   screenshot comparison before promising visible improvement.

## Audit scope

The targeted denominator is 8 roof WedgeParts **per arena**, not the entire
game's large number of Parts. Replacements at present: **0/8** from this
new asset, because ownership/moderation and client integration are not yet
verified. Retain `DistantAerial` as navigation identity until explicitly
reviewed; gameplay parts and collision stay unchanged.

No GitHub change alone updates the public Roblox Place.
