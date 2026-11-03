# Original 3D route mesh: real shutter hazard visibility

The five-map true 3D jump-deck and skybridge module release at `749db3a645ffd9d98b3e16a11a2198927cd7c42a` passed exact-SHA Build Validation, all five Roblox Cloud engine suites and the existing public-place publisher ([release evidence](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41618995819)).

## Post-release visual safety defect

`PremiumRouteMeshKit.safePlatform` already concealed approved imported 3D route models for shrinking/collapsing and fully disappearing platforms. It did **not** react to the independent server-authored `BridgeShutterPhase` state used by `SkybridgeShutters.setPhase` (`Warning`, `Raising`, `Raised`, `Idle`). A skybridge stays collidable while its shutter warning begins. The full original MeshPart finish therefore remained opaque over the route's original warning surface, making the most important danger less readable.

## Final source fix

- For any non-`Idle` shutter phase, the local original MeshPart finish is immediately hidden and the original authoritative platform panel restored.
- Register `BridgeShutterPhase` alongside `CollapsePhase` for **event-driven immediate updates**, not a new render or polling loop.
- On `Idle`, the original 3D finish resumes if the platform is still safe, without touching server-owned collisions or hazard logic.
- Keep existing approved asset IDs, original 3D mesh budgets and Android Low/Medium/High caps unchanged.
- The original platform and all server hazard paint always remain physically authoritative.

## Acceptance

Run full Luau compile, mobile VFX gate, Rojo build, then main exact-SHA Build Validation and five real Roblox Cloud engine suites before public publication. Physical Android warning visibility, performance and appearance still require actual screenshots; engine success is not visual certification.
