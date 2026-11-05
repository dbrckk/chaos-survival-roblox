# 3D — Original authored outboard skyline across whole 320-stud worlds

Date: 2026-11-05. Chaos Survival Roblox. Important visual production milestone; NOT a Roblox public update or screen-capture certification.

## Source finding

`ApprovedMidgroundSkylineMeshKit` used owner-verified architecture meshes outside Classic Grid and Crossroads; `HarborMidgroundBargeMeshKit` used seven-piece creator-approved 3D cargo boats in Harbor. Both already had hard quality/pressure/camera budgets and fallback masking/restoration. But each selected only the first `cap` nearest objects. With a Medium cap of two, both source-authentic models could cluster along the same edge of a 320-stud arena while another visible quadrant retained generic rectangular server/client art.

## Authored correction

The shared pure `SpatialMidgroundSelectionRules.choose` preserves the same camera score, source validations, maximum distance, per-tier hard caps and existing retention/hysteresis. It keeps the **closest genuine model first**; for later available slots it adds a bounded horizontal separation bonus (maximum 90) to prefer a real structure in another physical skyline sector. If only one source is available, no extra renderer or model is fabricated. High cap four still uses the same four approved sources. Low stays 0/1 as previously authored, and quality pressure still lowers or disables models.

Both client kits now invoke the same bounded (at most four source locations) selection algorithm inside the **existing** 0.9-second scenery LOD sampler. No extra Parts, MeshParts, textures, uploads, GPU lights, gameplay or physics changes; native geometry is hidden only after successful approved source mount, with existing exact-index restoration and unmount logic.

## Milestone checks

- Real-engine visual-budget suite tests four outboard positions, verifies nearest first and spread across two separated regions for Medium, Harbor hull identity and unchanged 0/1/2/4 caps.
- Exact-SHA Build Validation, all seven Roblox Cloud engine suites and source/provenance check.
- Actual Android Low/Medium/High screenshots required later to prove full-scene composition, LOD transitions and perceived contrast. No FPS improvement or public publish is claimed.
