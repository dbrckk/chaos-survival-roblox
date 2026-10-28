# Original PBR — Android GPU budget and visual acceptance

This gate applies to the **16 original 2K Roblox Image maps** (four industrial
MaterialVariants), already approved and baked into `default.project.json`.
It covers the cosmetic-only PBR surfaces on the four playable sectors and
arena architecture. It does **not** certify the public Roblox experience
without native client captures.

## Implemented in code

| Client quality | Max PBR surfaces per model | Global active PBR surfaces | Maximum camera distance |
|---|---:|---:|---:|
| Low (touch/desktop) | 0 | 0 | 0 |
| Medium — Android/touch | 6 | 32 | 240 studs |
| High — Android/touch | 16 | 72 | 370 studs |
| Medium — desktop | 6 | 48 | 340 studs |
| High — desktop | 16 | 144 | 550 studs |

- All four original MaterialVariants share the **same global** surface limit:
  there is no unbounded `per-model × model-count` GPU multiplier.
- Prefer **nearby, large, prominent** architectural surfaces for the budget,
  with a modest selection hysteresis so camera motion does not rapidly toggle
  different 2K maps.
- Respect `SceneryLodHidden` and `LocalTransparencyModifier`; never override
  the existing LOD owner's visibility decisions.
- Change Material / MaterialVariant **only when the selected variant changes**.
  No full teardown/reapplication on map streaming or ordinary quality updates.
- Only anchored, non-colliding, non-queryable, opaque cosmetic Parts qualify.
  No authored `SurfaceAppearance` or unrelated custom MaterialVariants are
  overwritten. An external material change revokes the local ownership claim.
- Existing streaming event listeners trigger a delayed, coalesced scan;
  camera movement triggers at most one low-frequency scan when the camera has
  moved at least 32 studs. No new RenderStepped or Heartbeat handler.
- `Player` **local-client attributes** provide three QA counters:
  `PbrActiveSurfaceCount`, `PbrActiveSurfaceBudget`,
  `PbrVisibleCandidateCount`. These are *not* frame-time or GPU memory
  measurements and do not constitute a performance certification.

## Native acceptance before final release

1. Capture **real Android** Low / Medium / High 30-second traversals through
   all four sectors (observatory, cargo, power plant, communications).
2. Confirm `PbrActiveSurfaceCount` never exceeds the listed tier budget;
   Low must remain zero even under heavy StreamingEnabled map churn.
3. At least once per sector, capture the true game camera in daylight,
   blackout and active disaster lighting. Verify normal-map handedness,
   roughness/metal response, color consistency, texture scale and no seams.
4. Record frame-time distribution, memory, GPU load when available, device
   temperature and touch responsiveness. Compare with the immediately
   preceding shipped PBR material selection implementation using identical
   scene, quality, camera route and player/bot counts. No claim of an
   Android FPS improvement is made until this paired measurement is taken.
5. Validate no material flash when new buildings stream, when player crosses
   the distance threshold, and when quality changes High ↔ Medium ↔ Low.
6. Verify that hazard telegraphs, route labels, collision and the effect of
   `ReduceMotion` remain clear and correct. These take precedence over PBR.
7. Preserve fallback snapshots and release hashes. A merge to `main` is
   source integration only; **do not publish** until human/device QA and the
   independent release readiness gate pass.

## Evidence sources

- `src/shared/PbrDistrictRules.lua`: pure caps, eligibility, LOD/distance
  filters and scoring.
- `src/client/pbr-district-materials.client.lua`: minimal-diff material
  reconciliation and diagnostic counters.
- `tests/engine/vfx-quality.spec.luau`: real-engine policy assertions.
- `assets/source/roblox-pbr-upload-receipts.json` and
  `assets/source/roblox-pbr-approval-evidence.json`: actual asset IDs,
  upload provenance, and point-in-time Open Cloud moderation/owner audit.
