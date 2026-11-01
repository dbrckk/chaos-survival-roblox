# Colossal kinetic skyline — five finished arena identities (1 Nov 2026)

## Visible result

Replace an overly static far-field impression with a **large, moving aerial industrial fleet** authored for every one of the five maps. Each 320×320-stud arena gains up to four original **~42-stud-long native 3D craft** positioned above its four diagonals, not a cheap texture/background image. All hulls, cabins, mechanical supports, wings and reactors have real volume. A player approaching any of the four playable sectors sees a major moving silhouette beyond their jump routes.

Each arena builds a genuinely different aircraft architecture:

| Arena | New, large animated identity | Distinctive moving mechanism |
| --- | --- | --- |
| Classic | Armored survey carriers with enormous rotating radar gantries | Slow rotating radar arrays |
| Towers | Heavy freight barges with vertical gantries and suspended cabins | Cabin/counterweight move in opposite directions |
| Crossroads | Aeromaglev interchanges with divergent route forks and dispatch bridge | Interlocking transit switch fins |
| Orbital | Reactor-driven flight platforms with large gyro arcs and containment wings | Pivoted segmented reactor rings |
| Harbor | Floating maritime cargo cranes with actual sculpted containers and bridge | Container hoist/cable and freight barge movement |

The fleet moves **as coherent whole machines**, rather than unrelated neon flashes. The mechanisms have individual animation roles. Large-scale storm reactions follow **the existing real disaster IDs**: tornado banking, lava evacuation ascent, low-gravity rise, meteor/bomb turbulence, slow frozen machinery. Motion starts from the exact authored rest pose and never accumulates CFrame drift.

## Measured source budgets (not FPS claims)

- **Low**: two opposing carriers, around **20–24 total native parts**, 0.40s update interval.
- **Medium**: three carriers, around **45–54 total parts**, 0.18s update.
- **High**: four carriers, around **68–80 total parts**, 0.13s update.
- Hard fail-fast per-carrier 3D budgets: Low ≤13, Medium ≤18, High ≤25.
- Ships have **no collision, touch or query**, no cast shadows, zero PointLights, no particles, no imported 3D or image assets, no server physics/network activity and no new remotes.
- The **existing** scenery-LOD loop culls each ship by its **actual Model pivot**: Low 255 studs, Medium 350, High unrestricted via shared LOD rules; the fleet skips CFrame work on hidden ships.
- Respect `ReduceMotion`, adaptive `VfxQualityTier`, stale/streamed map removal, exact CFrame rest poses and suspended Android scheduler catch-up.
- Only one tier-paced cosmetic coroutine, sleeping while idle. No RenderStepped or Heartbeat subscription.

## Source owners

- `src/client/ArenaSkyFleetKit.lua`: native procedural 3D builder, exact part budgets, five silhouette recipes, hazard-driven grouped animation and safe rest pose.
- `src/client/arena-sky-fleet.client.lua`: match/rebuild on real arena/streaming state; existing RoundState and accessibility/quality hooks.
- `src/client/scenery-lod.client.lua`: reuse the global distance-culling owner for each carrier.

Rojo automatically maps these files through `src/client`, no new package/secret/workflow dependency.

## Required final major-release validation (not yet executed)

1. **Build Validation**, all five **actual Roblox Open Cloud engine suites**, same frozen candidate SHA. This is a major release gate, never a fake or unit-only PASS.
2. Authenticated Studio 5-map render: verify two/three/four **visible**, large, arena-specific models and per-tier part counts; confirm they do not occlude playable routes, spawn markers, warnings, results or hazard silhouettes. Capture **15 genuine screenshots per map**.
3. Trigger real `Tornado`, `RisingLava`, `LowGravity`, `Freeze`, `Meteors` and Double Chaos; observe smooth bank, lift, articulated motion, color identity and no visual false safety cues. Interruption/map switch must delete ALL old carrier instances.
4. Real Android Low / Medium: inspect sky objects from lobby, hub and each edge; ensure the 255/350-stud per-ship LOD does not pop violently; check stable FPS, memory, thermals and 1-human+7-bot disaster pressure. Compare to the previous public version, not fictional benchmarks.
5. Toggle ReduceMotion mid-round, quality tier while flight is moving, background/suspend phone, reconnect, switch all five maps and leave during final rush; observe static authored pose and zero stale animation loops.
6. Publish **only** the existing public Universe/Place, after the actual final gate; keep an exact rollback SHA. This branch is SOURCE only until then.

No screenshot, device FPS, all-five Studio verification or Roblox public update is claimed from the presence of these scripts.
