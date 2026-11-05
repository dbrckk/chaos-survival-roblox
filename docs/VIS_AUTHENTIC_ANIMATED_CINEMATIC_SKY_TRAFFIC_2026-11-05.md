# VIS — Original, animated five-world 3D craft replace neon sky traffic

Date: 2026-11-05. Source development milestone, no Roblox public update.

## Inspected native artifact

In `arena-cinematic-depth.client.lua`, Medium and High authored respectively two and four cinematic flight paths on every one of the five arenas, each rendered only by an untextured neon `Part` of dimensions `5.6 × 0.26 × 0.46`. These thin slivers were highly visible and did not resemble professional vehicles. Positions were previously made stable across quality tiers, but the craft itself remained a primitive and its native tween drove only `Position`.

## Genuine model substitution

- `ApprovedCinematicSkyTrafficMeshKit` mounts the EXISTING already-approved, creator-owned `ambient_drone`, `ambient_lift`, `ambient_transit`, `ambient_satellite`, `ambient_cargo` originals. One exact variant- and ID-matched `ApprovedAmbientMotionTemplates` source per world, loaded and sanitized by the already existing sequential server loader (no new request or user secret).
- The five Model package IDs remain **102850052145878**, **72210530094580**, **116186226477876**, **127850230318627**, **131294203899636**. Source contract requires actual `MeshPart` geometry only (1–12), no scripts, no collision/touch/query, exact original identity, owner approvals and bounding limits.
- The new animated craft are detailed source MeshParts, max 8 studs horizontal and 6 studs high. Each piece is lightweight, noncolliding, nonquerying and welded to its original **anchored client-cosmetic** flight-path root. The root becomes invisible only after all genuine model parts and their welds are installed. The fallback neon driver is restored whenever the source is missing, streaming discards the root, a new map loads, phase/tier changes, or GPU pressure drops model count.
- Crucial engine requirement: the existing TweenService target changes from `{Position=to}` to `{CFrame=CFrame.lookAt(to, to + (to-from))}`. Roblox welds do not follow Position-only changes as they do CFrame updates. Motion geometry, start/end points, angular paths and the pre-existing 7–12s flight durations do not change. No extra per-frame model update or poll is introduced. The already-authoritative tween remains the **only** motion owner.
- This applies to **up to 20 theoretical paths** (4 paths × 5 different worlds). A single active map actually renders 0 on Low, 2 Medium, 4 High desktop, with strict pressure caps **0/0/0 Low; 2/1/0 Medium; 4/2/0 High desktop; 3/1/0 High mobile**. The existing 440 / 680 / 900 local Part census now includes **every** genuine welded piece in `OriginalCinematicSkyTraffic3DLocal`. No new models when `ReduceMotion` is enabled or during active `round` phase, respecting the existing cinematic behavior.
- Model residency is retried in the existing scenery LOD sampler, so **late-replicated** approved sources can replace native slivers without a RoundState refresh. No speculative fake models or client AssetService network requests.

## Certification and limits

Existing 78 Roblox Cloud engine specs still run; `tests/engine/cinematic-depth-layout.spec.luau` now includes genuine five-asset provenance, quality/pressure caps, exact origin ownership and an engine-level anchored WeldConstraint/CFrame motion regression. The major milestone requires same-SHA Rojo/Luau Build Validation, seven cloud suites and source-contract QA. Real Android/PC screenshots and FPS/memory measurements of the full 3D moving model under actual live Roblox replication remain separate open gates. Do not claim the 20 paths are concurrently visible or that the public experience has been updated.
