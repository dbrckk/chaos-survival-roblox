# Real route-entry guidance — streaming/hazards contract

Date: 2026-11-05. Chaos Survival, server authoritative four first-step landings on five 320-stud arenas.

## Identified source issues

The four center-to-perimeter arrows were calculated once from `Arena.Platforms:GetChildren()` when `arena-navigation-language.client.lua` rebuilt from `Arena.Base` and `Arena.Mechanics` events. There was no watcher for `Arena.Platforms`, its late first-step metadata, or the physical entry's hazard state. As a consequence, initial mobile streaming could omit all physical entrance arrows and a disappearing entry might leave misleading luminous arrows pointing at a hazardous/non-existent landing.

## Production change

- `MapBuilder` marks **only** genuine, collidable `PerimeterStep==1` platforms with the replicated server `CollectionService` tag `ChaosPerimeterEntry` at creation. Four per map, not an invented destination, no RemoteEvents, physics changes or new parts.
- The client watches tags and only those four verified physical parts; late attributes `PerimeterRoute` and `PerimeterStep` trigger a buffered 0.12-second existing navigation owner rebuild. The map's `Platforms` folder can appear/disappear independently of `Base` or `Mechanics`. No hundreds of per-platform listeners or new frame loops.
- Existing 2/3-per-route chevrons remain part of the same floor follower, inside the same geometry budget. They become immediately transparent when the authoritative first step is gone, Warning, not collidable, streamed out or visually gone; they restore only when the exact target is still the same safe server-tagged platform. No fake routes, no flicker from rebuilding on every warning.
- Map replacement, platform streaming and tag loss disconnect only the four per-part listeners, release obsolete visual parts and allow the new arena to rebuild.
- The existing onboarding Billboard on the server-owned entry is preserved; nothing adds UI clutter above Android HUD.

## Remaining QA

Milestone exact-SHA Build Validation, seven real Roblox Cloud engine suites; genuine Android Low/Medium/High first-join after streamed platform arrivals, four safe route starts, warning/Gone/restore transitions, shrinking, reconnect, and 5 arena differences. No screenshots, FPS or public release asserted by this source-only change.
