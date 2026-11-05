# Original 3D midground coverage in all five 320-stud arena worlds

Date: 2026-11-05. Scope: Chaos Survival Roblox visual source milestone, not a public release.

## Audited visual gap

The authentic source-verified TowerCoolingSpireMeshKit uses two approved industrial cooling spire originals (solid + hollow); OriginalOrbitalStationsMeshKit uses two approved satellite/station sculptures. Their client owners already validate exact template IDs, authentic per-index native silhouettes, maximum camera distance, GPU/pressure quality tier caps and fallback restoration. However each selected only the closest permitted sources, clustering its Medium originals in one view sector and leaving other midground areas with older Roblox native blocks.

## Implemented

The same already-tested pure `SpatialMidgroundSelectionRules.choose` used for Classic/Crossroads/Harbor now selects verified candidates for Towers and Orbital. The first remains closest to the camera; subsequent eligible sources prefer broad horizontal separation (bounded score adjustment) inside the **same** camera bounds. Nothing can select an unapproved, invisible, out-of-bounds or unstreamed native structure.

Towers quality/pressure caps are unchanged (Low: 1/0; Medium: 2/1/0; High: 5/3/0). Orbital caps unchanged (Low: 1/0; Medium: 3/1/0; High: 6/3/0). Two source variants in each world, original client-only MeshParts, source validation, native fallback if source missing, 0.9-second existing scenery LOD ownership and no new per-frame loop.

No new assets, GPU triangles, physics, routes, server ownership, remote traffic, lighting or materials. The first-stage three worlds' distribution logic and its exact-source regression protections are preserved.

## QA boundaries

Run exact-SHA Build Validation, expanded existing real-engine visual-budget suite checking physical separation at caps 1/2/3/5/6 and all seven Roblox Cloud suites before completion. An actual Android Low/Medium/High screenshot audit must still verify perceived panorama, streaming, silhouette contrast, and FPS; no public publishing is authorized here.
