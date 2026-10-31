# Android visual legibility — four sector labels (31 Oct 2026)

## Evidence and actual ownership

The owner supplied three real Android landscape images of Storm Harbor. The main `GRAVITÉ LUNAIRE` survival HUD, optional signal objective, shard progress and world signage all compete for limited vertical space. Earlier source PRs #459–#462 removed the redundant English `GRAVITY TIDE` billboard, optional server objective labels and veteran mastery hint **without changing the public release**.

The remaining client `src/client/district-sector-setpieces.client.lua` builds four client-only, noncolliding, richly sculpted **sector monuments**. Each monument's `SectorIdentityPlate` was additionally assigned a 156 × 40 `SectorWaypoint` `BillboardGui` with 105-stud visibility, creating another optional piece of camera-facing, potentially overlapping text. This is not required for gameplay or the real collision routes: server-built district facades already have fixed physical sector codes and `district-expedition-navigator.client.lua` presents the current target and direction on the HUD.

## Completed narrowly scoped change

- On `UserInputService.TouchEnabled`, do **not** instantiate the optional `SectorWaypoint` BillboardGui for these four monuments. Keep their **entire** original 3D structure, `SectorIdentityPlate`, region colors, existing fixed architecture signs, district missions, server authority and physical path unchanged.
- PC remains unchanged: the same four localized floating sector name signs still display on non-touch clients.
- Reduces up to **four client-side BillboardGui objects and their labels per map** on touch without any new loops, event connections, VFX, scene models or network requests.
- No new unit tests, and no engine/Android screenshot certification is claimed. This source-only change must pass the next full exact-SHA milestone build and five Roblox suites before separate, owner-authorized public publishing.

## Mobile acceptance

In real Android 16:9 play during `LowGravity`, with 4/4 contestants and the active signal objective, camera views facing each of four outer districts must show original 3D silhouettes and existing architectural sector signage, but **zero** `SectorWaypoint` overlays from `DistrictSectorSetpiecesLocal`. The danger banner, action buttons and path should remain readable. On PC all four localized labels remain available. Verify no scene-object or touch-target regressions, and no extra GPU load.

Public Roblox live version remains at the last verified published SHA `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f` until an explicitly authorized public update is run.
