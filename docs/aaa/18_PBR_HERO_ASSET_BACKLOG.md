# Environment Art Department — PBR Hero Asset Backlog

## Strategy

Do not rebuild every map with imported meshes.

Use a small number of authored PBR Hero assets where they deliver the largest perceived-quality improvement.

## Classic Grid

### Hero 1 — Broadcast Control Spine
Purpose:
- establish competitive/broadcast identity.

Features:
- structural frame;
- screen mounts;
- cable/service panels;
- PBR painted metal + brushed metal + emissive accents.

### Hero 2 — Arena Camera / Sensor Rig
Purpose:
- imply live event production.

### Hero 3 — Technical Barrier / Service Module Kit
Purpose:
- repeated secondary language without generic Parts.

## Tower Run

### Hero 1 — Industrial Lift Assembly
Purpose:
- iconic vertical machinery.

Features:
- rails;
- carriage;
- cable housings;
- warning plates;
- service access.

### Hero 2 — Maintenance Crane / Hoist
Purpose:
- scale/height storytelling.

### Hero 3 — Structural Junction Kit
Purpose:
- believable load-bearing connections.

## Crossroads

### Hero 1 — Transit Gantry
Purpose:
- instantly readable junction/transit identity.

### Hero 2 — Directional Sign / Signal Cluster
Purpose:
- lane identity;
- believable wayfinding.

### Hero 3 — Utility/Service Kiosk
Purpose:
- human-scale reference.

## Orbital Ring

### Hero 1 — Reactor Core Housing
Purpose:
- central technological identity.

### Hero 2 — Radial Support/Power Coupler
Purpose:
- explain the ring structure.

### Hero 3 — Observation/Sensor Module
Purpose:
- silhouette and scale.

## Material families

Classic:
- painted broadcast metal;
- dark polymer;
- emissive cyan;
- screen glass.

Towers:
- worn steel;
- industrial paint;
- rubber/cable;
- safety markings.

Crossroads:
- coated metal;
- concrete/slate;
- sign plastic/glass;
- magenta/cyan light.

Orbital:
- clean technical alloy;
- ceramic/polymer panel;
- controlled turquoise emissive;
- dark optical/sensor glass.

## Quality rule

Each Hero must improve the scene when:
- viewed from spawn;
- viewed in READY;
- viewed in a screenshot;
- viewed on Medium graphics.

If detail is visible only at extreme close range, reduce it.

## Collision

Hero scenery should generally:
- use simple collision;
- not create unintended safe spots;
- not alter existing traversal unless intentionally designed and reviewed.

## Rollout

Prototype **one** Hero asset first.

Recommended benchmark:
Tower industrial lift or Orbital reactor housing.

Run:
- visual comparison;
- performance comparison;
- import/material workflow review.

Only scale authored production after the benchmark proves a meaningful quality gain.


## Project asset budgets

These are starting budgets, not engine hard limits. Final approval comes from measured device cost and visual benefit.

### Hero asset
- typical visible triangle target: ~5k–12k;
- stretch above target only for silhouette-critical geometry;
- one 1024 PBR set by default;
- 2048 only when a unique close Hero demonstrably benefits;
- no routine 4K textures;
- simple collision proxy;
- avoid per-asset dynamic lights unless the lighting review explicitly approves them.

### Secondary authored prop
- ~1k–5k visible triangles;
- 512–1024 texture set;
- shared material atlas/trim sheet preferred when practical;
- collision disabled unless gameplay needs it.

### Repeated prop
- silhouette-first;
- aggressively shared materials;
- minimal collision/query/touch;
- avoid unique texture memory per copy.

## Naming convention

Mesh source:
- `env_<arena>_<asset>_v###`

Examples:
- `env_towers_lift_assembly_v001`
- `env_orbital_reactor_housing_v002`

Roblox instances:
- `Hero_<Arena>_<Asset>`
- `Prop_<Arena>_<Asset>`

Material source maps:
- `<asset>_basecolor`
- `<asset>_normal`
- `<asset>_roughness`
- `<asset>_metalness`
- `<asset>_emissive` when justified.

## Modeling checklist

Before high detail:
- compare scale beside R15;
- verify silhouette from gameplay distance;
- verify support/load logic;
- verify service/access logic;
- identify the 3–5 large forms;
- identify the 5–10 medium forms;
- decide which small detail belongs in texture rather than geometry.

Bevel only where it changes highlight quality.
Delete hidden/internal geometry that cannot contribute.
Use weighted/clean normals where appropriate.
Keep pivots meaningful for placement/animation.

## PBR checklist

Base Color:
- contains material color, not baked strong lighting;
- controlled dirt/wear;
- no arbitrary noise.

Roughness:
- primary realism channel;
- must distinguish paint, exposed metal, rubber/polymer, glass and worn zones.

Metalness:
- physically coherent binary-ish behavior;
- painted metal surface reads primarily as paint until exposed.

Normal:
- supports manufactured seams, panel relief and wear;
- does not fake large silhouette changes.

Emissive:
- only motivated indicators/screens/energy elements;
- limited area;
- never used to hide weak material definition.

## Arena Hero benchmark briefs

### Benchmark A — Tower Industrial Lift

Gameplay-space role:
non-collidable/peripheral Hero unless a later level-design review explicitly makes it traversable.

Readable from:
- Tower spawn;
- READY framing;
- common vertical route;
- RESULT.

Large forms:
- twin guide rails;
- lift carriage;
- overhead machinery;
- counterweight/cable enclosure.

Medium forms:
- service hatch;
- hydraulic/electrical modules;
- warning plates;
- maintenance ladder/handholds.

Material split:
- worn steel structure;
- painted industrial panels;
- rubber/cable;
- limited emissive status strips.

Failure if:
- it resembles a generic sci-fi tower;
- small detail disappears on Medium while no strong silhouette remains;
- it suggests climbable geometry that is not gameplay.

### Benchmark B — Orbital Reactor Housing

Large forms:
- circular/radial shell;
- service couplers;
- central energy aperture;
- structural segmentation.

Material split:
- clean technical alloy;
- ceramic/polymer panel;
- dark optical glass;
- controlled turquoise emissive.

Failure if:
- it becomes another neon ring;
- emissive dominates material response;
- material language collapses back into generic metal.

## Roblox import checklist

After import:
- scale verified against R15;
- pivot/orientation verified;
- SurfaceAppearance maps assigned correctly;
- RenderFidelity starts at Automatic;
- CollisionFidelity simplified;
- CanCollide/CanTouch/CanQuery disabled when decorative;
- CastShadow reviewed rather than assumed;
- asset visible in High/Medium;
- Low receives either the same essential silhouette or a cheaper fallback;
- no route/hazard occlusion;
- no unintended safe spot.

## Benchmark decision

The first authored Hero is an experiment, not a commitment to rebuild all maps.

Compare screenshots:
- current procedural scene;
- authored Hero integrated;
- High;
- Medium;
- Low.

Record:
- perceived-quality gain;
- instance reduction/increase;
- memory/texture cost;
- frame-time effect;
- authoring/import effort;
- maintenance complexity.

Scale the pipeline only if the authored Hero creates a meaningful quality step.
