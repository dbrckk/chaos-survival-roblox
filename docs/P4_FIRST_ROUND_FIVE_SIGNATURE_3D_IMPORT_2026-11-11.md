# P4 — Five-arena original 3D signatures available during the first round

**11 November 2026 · source milestone · not a visual or FPS certification.**

## Confirmed source problem

The five creator-approved, seven-MeshPart hero sources could only begin
loading after 42–104 seconds in the existing server owner. A normal
multiplayer round lasts 45 seconds; solo lasts 30 seconds. Even an
approved original Model could therefore be absent when a player first
encountered the arena. Import delay was not a guarantee of rendering,
because `AssetService.LoadAssetAsync`, streaming and client LOD add
latency.

## Changes made

The existing asynchronous import owners now give **only the currently
active world** an earlier opportunity to request its approved signature:

| Arena | Approved owner | Prior initial delay | Active first attempt | Unselected fallback |
| --- | --- | ---: | ---: | ---: |
| Classic | DualDishObservatory · 112493873850364 | 44 s (104 s inactive) | 18 s | 104 s |
| Crossroads | ForgedInterchange · 96622579843060 | 45 s (77 s inactive) | 19 s | 77 s |
| Harbor | SculptedGantry · 124368710235343 | 46 s (91 s inactive) | 20 s | 91 s |
| Towers | ForgedBridge · 126298311664881 | 47 s (62 s inactive) | 21 s | 62 s |
| Orbital | ReactorRing · 125070862497818 | 42 s | 22 s | 42 s |

After its short timer, a nonactive source waits **without polling**.
The existing `PremiumActiveVariantImportSchedule` now listens to
`GeneratedMap` and `Arena.VariantId` changes. If a different world
becomes active before the old fallback deadline, that world's waiting
owner is woken early; otherwise it imports at its historical deadline.

Each source still performs the same moderation provenance, seven-mesh
geometry, sanitization, no-collision and retry checks. Every
`LoadAssetAsync` still goes through
`PremiumApprovedAssetImportGate`, maintaining **two in-flight
requests at most** (queue can grow on fast rotations). No new model
IDs, extra network remotes, server RenderStepped/Heartbeat jobs,
colliders, image maps or graphical objects were introduced.

The existing source-regression script and workflow were extended to
cover all five owners, exact timing, wakeup signal wiring, cleanup,
registry approval and native fallback behavior. No new unit test was
added.

## Interpretation and acceptance gate

This removes a **known source-level scheduling delay** and makes first
round availability possible sooner, but does **not prove** any
specific appearance time, actual visible residency, benchmarked FPS or
final aesthetic rating. Active-source request timing must be checked
in Roblox Engine and on real Android devices using the existing
`ServerStorage.PremiumApprovedImportDiagnostics` plus the game's
`ClientOriginal3DResidencyPulse` telemetry at 10/30/45/90/180
seconds. Verify that there are no higher join spikes, duplicated
imports, missing native fallbacks or bad geometry.

As before, merging this code does **not** publish the live Roblox
Place. Public deployment requires the existing protected publishing
workflow and its real validation evidence.
