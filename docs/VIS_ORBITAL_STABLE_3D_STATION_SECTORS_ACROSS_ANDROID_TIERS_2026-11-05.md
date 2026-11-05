# Orbital — stable original station sectors on Android tier switches

Date: 2026-11-05. Chaos Survival Roblox, source-only 3D visual identity repair.

## Reproduced source defect

`arena-midground-mass.client.lua` built three Orbital station native silhouettes on Low, four on Medium and six on High. It computed every station angle with `(i-1)/count * 2π`. The native `OrbitalStationMass2` position therefore changed when the quality tier changed. This also forced `OriginalOrbitalStationsMeshKit` to destroy/remount already-approved seven-MeshPart 3D sculpture copies and could produce visible jumps across the 320-stud horizon. Low's three initial stations were uneven in approved source material when using only indices 1/2/3, and the six-sector original ring was not stable per identity.

## Implemented source change

- Introduce pure `OrbitalStationLayoutRules` with a **fixed six-sector** mapping for all device qualities. Native generated station indexes remain original server-free client-authored visual owners, at the same ring radius; the existing creator-approved Satellite/Containment mesh source IDs do not change.
- Low uses sectors **1, 3, 6** (three true, spatially distributed silhouettes, both source families); Medium uses **1, 3, 4, 6**; High uses **1–6**. A tier upgrade *adds* stations but never changes the world position of a surviving named station. Existing part counts 3/4/6 and source-resident 3D model budgets Low 1, Medium 3, High 6 remain unchanged.
- The source-approved `OriginalOrbitalStationsMeshKit` also verifies every native model is at its **exact authored local-sector position**, within 0.35 studs, before mounting a genuine MeshPart source. Untrusted, transient, previous-tier or incorrectly positioned native spheres cannot be misidentified as genuine originals.
- No extra meshes, assets, PBR maps, GPU budgets, project lighting, physics, audio, RemoteEvents, render callbacks or continuous work. `ArenaMidgroundMassLocal` still responds via the existing map/tier rebuild owner; `SceneryLod` continues sampling under its existing 0.65/0.90-second cadence.

## Milestone certification

Require exact-SHA Roblox build, seven Roblox Cloud engine suites and existing visual-budget suite coverage of cross-tier identity, source fidelity, stable ring separation and invalid source indices. Android screenshot checks of Orbital Low → Medium → High and reconnect remain unverified until actually performed. No public Roblox place publish from this source-only lot.
