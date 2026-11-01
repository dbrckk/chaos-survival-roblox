# Changelog

## 2026-11-01 — Actual Build Validation blocker repaired after first release-gate run

- Authentic GitHub Actions Build Validation on exact SHA `f2e8c0e9a3887c733225957acfd9051586983ba5` passed the **Luau syntax check** plus earlier source/security guards, then **correctly failed** at persistent client visual-folder coverage: `ArenaSkyFleetLocal` and `ArenaCataclysmDebrisLocal` were absent from `VisualBudgetRules.LocalFolders`. [Observed failed run](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41330658400).
- Corrected the centralized runtime owner ledger, rather than disabling the safety check or increasing mobile GPU/part budgets. Both large visuals will now contribute their true Parts/Effects totals to existing adaptive quality telemetry.
- The one-shot exact-SHA build-before-Cloud workflow is re-armed by this **dedicated release-blocker merge**, and still never publishes. Green results for the new SHA are not claimed before observed.


## 2026-11-01 — Release-blocking sky crossing escape route fixed (source)

- Corrected a fairness defect exposed by source review of the large #535 and #536 milestone: `DisappearingPlatforms` could randomly remove the FIRST or FINAL access decks connected to a protected, solid 200-stud sky promenade, stranding players and AI. All **20 real perimeter entry/fork steps + 16 branch ascents + 16 sky promenade slabs** now explicitly form a **52-deck continuous random-collapse-safe circuit on each arena**.
- Source-owned `PermanentRoute` metadata flows to `ChaosPermanentRoute` on real server colliders. Existing disaster exclusion consumes the same flag; other platforms remain destructible. The real flat-jump promenades now have **64 native bidirectional, deck-attached chevron strokes per active map**, following shrink and never altering collision; no custom physics, remotes, UI loops, gameplay timers or DataStore changes.
- Existing engine specs updated to enforce permanent route ownership, remaining collapse candidates, true level 2.4-stud jumps and physical wayfinding across the five maps; **not run yet**. A one-time workflow on the exact final merge will trigger Build Validation first and the five real Roblox Cloud suites only after a verified passing build, never deploying the public place. [Source geometry, risk, verification requirements](docs/RELEASE_GATE_ROUTE_CONTINUITY_2026-11-01.md). Cloud/Studio/Android gate and publication are still outstanding.


## 2026-11-01 — Massive structural destruction synchronized with real disasters (source only)

- Six giant 3D gateway installations **per arena** now collapse visibly and progressively during real Meteor/Bomb impacts (nearest intact structure) and sustained Tornado/RisingLava weather. Up to six catastrophic failures in a full round, 30 distinct authored structures across the five arena variants (six at a time).
- A single server-authoritative structural controller deforms the **existing** 3D pylon/gantry/hoist/reaction equipment, using distinct displacement profiles for wind and heat. Real player-facing warning and damage remain exclusively under existing disaster modules; all 16 high-altitude promenade decks remain physically solid and safe.
- Server-replicated structural states trigger local quality-tiered real 3D debris (Low 4, Medium 8, High 12 Parts), short dust and optional airborne pressure rings. No new RemoteEvents, rewards, fake colliders, paid assets, physics or per-frame Lua loops. Reduced Motion, streaming, round cleanup and ShrinkingArena conflict guards included.
- This major source lot is **not** a tested Roblox release. Build + five real Cloud suites + Studio + Android + visual screenshots must certify the same SHA before any public publish. [Detailed gameplay and QA contract](docs/STRUCTURAL_CATACLYSM_PREMIUM_2026-11-01.md).


## 2026-11-01 — Monumental physically playable 200-stud viaducts in five arenas (source only)

- Major gameplay-level visible construction: **two high-altitude, end-to-end sky promenades per arena**, each connecting an existing pair of far-flung real branch lookouts. Sixteen additional server-authoritative, jumpable, 2-stud-thick collision decks per map, 80 authored landings across five variants. Eight landings per viaduct, with consistent 2.4-stud gaps and overlapping old lookout endpoints; real height-matched jumps, not a teleport or cinematic-only fake.
- Six large, original, nonblocking architectural gateways per map, distinct per arena: Classic radar towers, Towers cargo-lift machine rooms, Crossroads transit switching fins, Orbital ceramic reactor containment, Harbor suspended freight cranes. At most 54 locally relevant decorative server Parts per generated arena, all linked to the real deck's shrinking footprint.
- Protect long permanent routes from random disappearance while allowing Shrinking Arena to transform decks **and** their owned artwork together. Append after every original route, Harbor skyway and dock-spoke to keep historic indices, hazard owners, AI navigation and existing game loop stable. No new timers, paid assets, RemoteEvents, player powers or data format changes.
- Existing engine map-count assertions updated only to account for the genuinely new platforms; **no tests executed** during the feature implementation phase. Studio/Android, Cloud and public release are deferred to the next final exact-SHA milestone. [Architecture, physics, scope and acceptance](docs/MONUMENTAL_SKY_PROMENADES_2026-11-01.md).


## 2026-11-01 — Colossal cinematic sky fleet across five arenas (source only)

- A major **visible world-scale production pass**: the five arena identities now each author a fleet of enormous, original, animated 3D carrier structures in the playable skyline. Classic has radar survey airships; Towers has freight gantries and moving lifts; Crossroads has mechanical maglev interchanges; Orbital has active reactor gyroscopes; Harbor has floating cargo docks, cranes and moving suspended freight. These are five bespoke shapes, not recolored background images.
- The moving **entire hull silhouettes** visibly bank and lift during actual tornado, meteor, lava, low-gravity and freeze rounds; individual mechanisms animate as part of the same craft. Zero client-server gameplay changes, no occlusion of human/platform collision, no external paid assets.
- Low: two large ships (about 20–24 native parts total), Medium: three (about 45–54), High: four (about 68–80). Reuse global per-model camera LOD, suppress animation on hidden craft and honor ReduceMotion. [Full source/runtime acceptance](docs/COLOSSAL_SKYFLEET_PREMIUM_2026-11-01.md).
- **Not yet validated or published**. The existing latest verified public build remains exact SHA `46263cbdced1bddf002a8d57867303eb21422c2f`; final Cloud/Studio/Android validation and publication are separate gated actions.


## 2026-11-01 — Cooperative DASH route discoverability (source only)

- **Latest VERIFIED public build**: exact SHA `46263cbdced1bddf002a8d57867303eb21422c2f` passed [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41322299252), [real five-suite Roblox Cloud checks](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41322305051), then the [authenticated public-place publish](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41322662162). Eight-person AI autofill and cooperative NPC DASH support are **published source**, but still need physical device/gameplay confirmation.
- **Next source-only gameplay change**: Move both real Team DASH relays toward the player routes in all five 320-stud maps. Original stations were about 81.5 studs from the center and outside the AI's 68-stud detection radius at the hub. New first choices are about 58.5 studs away, with the older coordinates kept as safe fallbacks. Each candidate must clear real collidable geometry and remain 12 studs from each native spawn marker. World labels now use a smaller 95-stud visibility range.
- No new network remotes, tasks, persistence, reward advantages, artificial players, geometry collision or public build. [Behavior/QA contract](docs/COOP_RELAY_ROUTE_DISCOVERY_2026-11-01.md). Validation is deferred to the next **single exact-SHA publication milestone**; no Android FPS or relay usage rate is claimed.

## 2026-10-30 — Harbor maritime deck finishing AFTER verified second publication (source only)

- The preceding Harbor 3D/physical-platform update is **LIVE** in the existing public Roblox place. Exact published source `58af603f185c2adebabd70517ce37f36b778aea8` passed [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41091324370), [real Roblox engine tests](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41091334778), [owner-only exact-SHA release gate](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41091311509) and [public publisher](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41092002110).
- **Newly prepared, not yet published:** `ArenaDeckFinishKit` has original Storm Harbor drydock timber planks, cargo metal rails and mooring plates with exact 2/4/6 Low/Medium/High cosmetic-part budget. `arena-surface-detail.client.lua` now uses compact marine plank joints and corroded steel fixing pieces instead of long Classic-like grid seams/repair patches, reducing decorative part count across all LOD tiers and preserving real floor-sweep/hazard readability.
- Existing real-engine `vfx-quality.spec.luau` covers all 2/4/6 original parts, real Harbor map geometry, no collision/touch/query, allowed materials and Shrinking Arena floor following. [Source acceptance contract](docs/PREMIUM_HARBOR_DECK_FINISH_FOLLOWUP_2026-10-30.md); actual Android screenshots and FPS remain unmeasured. This follow-up requires its **own** release gate before public inclusion.

## 2026-10-30 — Original Storm Harbor playable platforms and exterior cargo 3D (published)

- Fix another cross-arena identity defect: `PlatformFinishKit` omitted Harbor from its supported physical platform visuals, so Medium/High protective armor and load braces were missing and `arena-platform-identity.client.lua` painted Classic's calibration neon across the cargo piers. Harbor now has its own original wood-plank splice, corroded steel lashing and below-deck timber/metal keel, welded to the **actual physically jumpable platforms** with Shrinking Arena and CollapsePhase lifecycle. Existing Low/Medium/High finish counts remain 1/2/3; Low adds no optional Harbor-specific trim and zero armor/braces.
- Replace the second Classic fallback in `arena-architectural-details.client.lua` with an exterior maritime cargo-loading crane: steel legs, overhanging boom, suspended timber cargo, mid/high rigging/brace/wheel/cab details. Sync the load, cable and high-detail ribs using the already-owned 5-Hz cosmetic phase. No fake gameplay geometry, server hitbox, network change or extra animation loop.
- Add real Roblox engine geometry/ownership/material/collapse coverage to `tests/engine/vfx-quality.spec.luau`. See [physical Harbor art acceptance](docs/PREMIUM_HARBOR_PHYSICAL_DECK_ART_2026-10-30.md) for mobile screenshots and exact-SHA public release gate.
- **Published** as part of the verified public Roblox SHA `58af603f185c2adebabd70517ce37f36b778aea8` (run [41092002110](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41092002110)); physical Android/desktop FPS and AAA parity are still not certified.

## 2026-10-30 — Harbor industrial deck language, no Classic visual fallback (published)

- Fix the second missing fifth-arena art branch: `arena-surface-relief.client.lua` still used Classic's metal hatches for Storm Harbor on Android Medium/High. `addHarbor` now authors shallow maritime cargo cleats, rusty-steel/wood-plank materials and engraved load lines at safe exterior service corners, rather than reusing Classic's survey hardware.
- **LOD contract:** Android Low still gets the original essential 12 shared deck pieces only (zero new Harbor floor geometry). Medium adds 8 inlaid, collision-free local surface parts; High adds 20 detailed parts including mooring tie-downs. All floor-follow with Shrinking Arena. No new server physics, lights, textures, scripts, audio, HUD, raycast or render loops.
- [Harbor source and acceptance spec](docs/PREMIUM_HARBOR_SKYLINE_2026-10-30.md) now covers both the original 3D skyline and the follow-up floor-identity pass. Cloud engine tests passed for published SHA `58af603f185c2adebabd70517ce37f36b778aea8` in run [41091334778](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41091334778); physical Android/PC visual acceptance remains outstanding.

## 2026-10-30 — Successful verified public playtest update and next Harbor art pass

- **Public Roblox update confirmed:** exact SHA `82f925c320b2525a58acb4944e74435a75a2795c` deployed into the existing Universe `10771083668` / Place `95351659174730` via successful [official public publisher](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41088325686). [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41087607663), [real Roblox Open Cloud Engine Tests](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41087618418) and [one-time exact-SHA source gate](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41087594018) all green. Previously failed source candidate was correctly blocked, with float32 size assertions repaired before publishing.
- **Next source-only art pass (not live):** finish the missing fifth arena identity, Storm Harbor, in the existing client-only skyline finishing system. On Android Low, three distinctive mooring-spire / dock-boom / cargo-hoist shapes (instead of zero parts); on High, fourth navigation crown. On Medium/High, use a new seven/eleven-part, non-colliding offshore freight berth rather than incorrectly reusing Classic's land survey mast. Built-in corroded/steel/concrete finishes, no new texture downloads, lights, network traffic or extra frame loops.
- Existing engine art spec expanded for new Harbor geometry, precise rotated map exterior bounds, non-colliding surface, materials and bounded LOD. **This new art has not yet been engine-tested, Android-screenshot approved, or published.** See [Harbor visual acceptance plan](docs/PREMIUM_HARBOR_SKYLINE_2026-10-30.md).

## 2026-10-30 — Authentic five-arena mechanic guidance and complete Harbor locale (unpublished)

- Fix misleading static arena briefing: a map previously described collapsing bridges or timed sweeps even when the server had disabled them during beginner or incompatible-disaster rounds. The existing `ArenaMechanics.start` now exposes a strict `MechanicMode` attribute and `mode` return value derived from the **actually started challenge**, including disambiguation of Towers' real timed metal shutter vs disappearing bridge rounds. The already-existing 1Hz `RoundState` includes mode + short intro window.
- Experienced players see a concise FR/EN action in the **existing round-status pill for six seconds**, not a new HUD. Final Rush, Overdrive, impact-wave warnings, double collapse, double-chaos and rookie survival copy all outrank this optional tip. Unknown/cross-map modes never display an invented danger.
- Complete missing **Storm Harbor / Port des Tempêtes** static name, route strategy, pad description and server-name alias for French and English. All five arenas now have real localized onboarding.
- Add coverage to existing real Roblox arena mechanics and CoreLocalization engine specs. [Arena-action acceptance plan](docs/PREMIUM_ARENA_ACTION_ONBOARDING_2026-10-30.md). No new objects, audio assets, client loops or RPCs; no gameplay physics or reward changes.
- **Engine tests and Android visual checks remain deferred to next major premium release milestone.** No Roblox public update.

## 2026-10-30 — Landing preview reflects real active floor sweeps and Tower shutters (unpublished)

- Fix a mobile platformer safety problem: the existing locally predicted **cyan safe landing** could be displayed on a real deck which was about to be hit by Classic's Grid Sweep, Harbor's Cargo Sweep or Tower Run's timed bridge shutter. The existing four-bracket reticle now shows a **red X** for the exact server-authored hazard footprint and replicated phase, with the SAME 10-Hz sample and up to four collision rays as before.
- Raised platforms above a floor sweep and safe locations elsewhere on a skybridge **remain safely marked**, avoiding false red warnings. Reuse `JumpRouteCueRules.activeSweepOnPath` for the actual rotated sweep geometry; the shutter test matches the actual `BridgeName` and physically narrow metal gate rather than every bridge.
- Only the existing three named arena mechanic folders are read, after a genuine imminent landing was found. No new camera loop, UI layer, sound, network traffic or player ability. Extended existing real Roblox engine movement spec for phase, rotation, height and real shutter proximity; see [hazard-aware landing acceptance plan](docs/PREMIUM_HAZARD_AWARE_LANDING_PREVIEW_2026-10-30.md).
- **Not yet executed on the final SHA**, no public or private Roblox deployment. Mobile image/video confirmation remains part of the owner's final premium gate.

## 2026-10-30 — Fair live Tower shutter reactions for bots and real nearby audio (unpublished)

- Correct a **live behavior bug** left by the timed 2.05-stud metal shutter feature: a survivor bot could commit to a real Tower skybridge while it was `Idle` and keep sprinting toward the barrier once it entered `Warning`, `Raising`, or `Raised`. AI now reads only the four current, server-owned bridge gate phases; with the existing personality-dependent reaction time, it physically retreats toward the nearest supported tower endpoint or holds its position at a gate it cannot safely pass. Already-committed Skyrail crossings are cancelled before any boost into the blocker. Normal Humanoid movement, hazard priorities and safety exit centreline stay unchanged; no AI teleport or speed buff.
- The existing `audio.client.lua` RoundState listener plays one quiet, **nearby-only** `PlatformWarning` for the exact server warning timestamp, reusing the game's existing mute/effects-volume controls and official local sound. No client loop, asset purchase, new SoundId, or RemoteEvent. Remote survivors, eliminated players and spectators do not hear a proximity cue.
- Extend existing real Roblox engine AI specs with four-axis bridge geometry, centerline holding, unsupported/off-map rejection, inactive phases and both bridge orientations. Update [premium completion/acceptance plan](docs/PREMIUM_BENCHMARK_AND_COMPLETION_PLAN_2026-10-30.md) with bot screenshot and device-audio acceptance.
- **No tests executed in the iterative development phase**, no new Roblox publication, no invented FPS or achievement data.

## 2026-10-30 — Android jump reliability and touch descent camera (unpublished)

- Fix a real delayed replication bug: the old jump-assist script stopped listening if the Humanoid arrived >5 seconds after respawn. It now attaches event-driven whenever the Humanoid appears, supports same-character Humanoid replacement, and disconnects all old callbacks on respawn. Zero per-frame polling.
- Resolve the one-shot buffered jump race when `FloorMaterial` and `StateChanged(Landed/Running)` arrive out of order. A still-live 120ms request dispatches once only on true grounded contact and enabled jumping; preserve existing 100ms coyote grace, no double-jump and no Freeze bypass.
- Stabilize *passive* third-person motion on descending Android touch players (0.48 coefficient) so FOV/lean acceleration does not distract from precision landings. Real disaster impacts, landing feedback and physics stay unchanged. Discard stale/zero/invalid Android resume deltas before camera-spring integration.
- Extend **existing** real Roblox engine specs and document explicit Android/PC matrix: [jump and camera acceptance plan](docs/PREMIUM_ANDROID_JUMP_CAMERA_2026-10-30.md). Tests deliberately reserved for next major milestone. No Roblox publish, FPS or session success falsely asserted.

## 2026-10-30 — Real rising Skybridge shutters and calibrated premium roadmap (unpublished)

- Introduce four real, 2.05-stud tall **Tower Run timing obstacles**. In an eligible veteran round, exactly one rises at a time on an existing fixed skybridge after a 2.6-second visible amber ground warning; players jump over it or wait 1.8 seconds for a clear crossing. Other bridges stay solid/open. An actual metal Part becomes collidable only after the visible 0.32-second lift; check human/bot root occupancy before closure, otherwise cancel. Event and geometry fully cleaned at round end.
- Alternate the shutters with the existing Skybridge Pressure collapsing-bridge challenge, **never stack both** in one round or with incompatible disasters. Existing Skyrail boosters may not launch a runner into a warning/raised shutter. AI survivors stop selecting already obstructed Skyrail crossings. One server event loop, no new client RenderStepped, remotes, XP authority or paid movement.
- FR/EN event-driven, depth-tested local warning signage and noncolliding, floor-flush amber indicators; streamed gate ownership via CollectionService tag. Specs added to the **existing** real Roblox engine integration suite for full geometry, phase, collision, cleanup, bot safety, Skyrail lockout and mechanic alternation. These scenarios are not yet executed on this SHA.
- Update [verified competitor benchmark and measurable 9/10 exit plan](docs/PREMIUM_BENCHMARK_AND_COMPLETION_PLAN_2026-10-30.md), referencing original Tower of Hell / Flood Escape 2 / Speed Run 4 / Natural Disaster Survival. Provisional source review **6.2/10**, low-to-medium confidence, NOT a real Android/PC assessment.
- Fix the README's stale public provenance: last verified **public** Roblox publish was successful 30 October 2026, commit `a0f56bcd4cfa401162a608404c95649bb39b6446`. This new source change does **not** deploy to Roblox; owner requires a premium-quality final public release.

## 2026-10-24 — Readable industrial arena floors instead of oversized neon fills (candidate)

- Responds to four real Android screenshots showing pink/cyan bloom hiding route edges and player avatars. Change **only the broad decorative surfaces** of Towers, Crossroads and Orbital from emissive Neon to subdued platform metal with arena-toned colors; the towers' small center inlays remain Neon but at higher transparency. De-emphasize the four very long cross-map neon seams.
- Keep small original neon route chevrons, Orbital spokes, gameplay boundary edges, disaster warning discs, server hazard parts, all collision/physics/platform geometry and UI semantics **unchanged**.
- Extend the existing real Roblox MapBuilder engine spec: four arenas retain distinctive Neon wayfinding while broad floor panels are non-emissive/non-collidable and long seams are safely dimmed.
- Physical Android visual acceptance still needed: close/long sightlines, large pink + cyan lighting contrasts, hazard/route readability, FPS/overdraw and color accessibility. No claim of already-visible public updates.

## 2026-10-24 — Large original architectural silhouettes, four distinct arenas (candidate)

- One fully generated, **large (>40-stud tall)** noninteractive 3D signature setpiece is now built beyond the northern exterior skyline for every variant: Classic communications observatory and radar receivers, Towers twin lift shafts and suspended high service bridge, Crossroads double-decker interchange gantry, Orbital segmented vertical accelerator ring and suspended reactor core.
- The new Roblox-native setpieces are **actually instantiated into the arena** without an external 3D upload, with 12–28 static Parts/Wedges/Cylinders per currently active map. These are *not* licensed/imported MeshParts; the separate original OBJ art sources still require creator-owned asset upload and visual approval.
- All decorative pieces are anchored, non-collidable, non-touchable, non-queryable and shadow-free; no new lights, particles, animation loops, remotes, server hazards, walking geometry or changes to existing parkour platform IDs.
- The existing MapBuilder Roblox engine spec now asserts variant-specific signatures, height, bounded part count and conservative out-of-bounds clearance on **all four arena types**.
- Not yet certified on a physical Android handset: rendered shape readability in Low/Medium/High, streaming distances, actual FPS / memory and impact on disaster warning legibility. These remain release gates.

## 2026-10-24 — Two original Roblox-ready industrial model sources (candidate)

- Authored the 27-stud `ChaosReactorSpire` (680 vertices, 1,220 triangles) and 17.8-stud `ChaosServiceCrane` (316 vertices, 504 triangles) as fully independent, original OBJ geometry under `assets/source/` with the shared six-color industrial MTL palette. 74 watertight, consistently wound mesh groups; no remote dependencies or third-party license restrictions.
- These are **editable art sources**, not live MeshParts. Asset import, real creator-owned Roblox IDs, Roblox Studio visual verification and Android 3D device QA remain separate requirements. The native in-game skyline remains the functioning fallback; no runtime/script changes here.
- Updated `assets/source/README.md` with dimensions, model budget, Studio import and validation instructions. No new tests, rendering overhead, server physics, remotes, monetization or deploys.

## 2026-10-24 — AI survivors actually traverse expanded parkour circuits (candidate)

- Correct a navigation realism regression introduced by 150–156-stud maps: AI runners previously retargeted every ~0.8–1.8 seconds, preventing completion of distant outer approaches. When a physically spawned `PerimeterStep` target is selected, retain that intent for a bounded travel time estimated from **normal unboosted humanoid walking speed** (maximum 6.2s). Short destinations retain original responsiveness; urgent threats always override.
- Reserve second-stage platforms for bots already close enough horizontally and vertically to attempt the real jump; never aim at remote high walls from the main floor. Reject outer routes altogether during Shrinking Arena. Give playable perimeter routes a modest scoring preference in ordinary rounds, keeping dynamic meteor/bomb risk penalties in force.
- Expand the existing real Roblox engine AI suite for long approaches, upper-deck access, shrinking floor, corrupted inputs and normal-route baseline. No teleportation, navigation shortcuts, speed buffs, extra brain loops, avatar masquerading, client VFX or server remotes.
- **Physical release gate:** capture bot movement from center to corner routes on all four arenas, verify real stair/jump success, credible decisions and disaster evasion plus Android FPS. This commit is not published by a GitHub merge.

## 2026-10-23 — Exterior 3D skyline with mobile readability (candidate)

- Add four **original, Roblox-native 3D industrial skyline structures** OUTSIDE each of the four expanded arena bounds. Every assembly has a grounded metal foundation, recessed mast, wedge cap, two angled braces and restrained edge insets; extra identity geometry per map (Towers service mast, Crossroads cross-antenna, Orbital cylinder receiver, Classic aerial).
- 4 × 7–9 decorative Parts per map, all anchored, noncolliding, non-queryable, non-touchable and shadow-free. No Neon material, PointLights, beams, particle emitters, scripts, per-frame operations, physics obstacles or outside-imported models. Buildings are environmental silhouettes, NOT playable platforms. No changes to AI pathing, shrink logic, server hazards or center parkour indices.
- Extend the **existing** real Roblox MapBuilder engine suite with exact four-direction exterior placement, 5-stud clearance beyond playfield, wedge silhouettes and a strict low Part budget.
- **Not yet visually certified:** verify actual rendered skyline, four camera angles, visual occlusion, mobile FPS/overdraw, and consistency with the original Blender OBJ import candidate on an exact-SHA Android staged build. The public place is unchanged until a separate explicit workflow publication.

## 2026-10-23 — Four genuine outer playable circuits per map + natural Roblox NPC names (candidate)

- Added four **physically playable** perimeter circuits to each of Classic, Towers, Crossroads and Orbital (8 solid grounded/two-stage platforms per map). Routes are at ±46–64 studs, on the new 150–156-stud map foundations, with a short ordinary-jump gap and a 3.6-stud rise. Large blocks touch the actual floor: no dangling low platforms forming R15 headroom traps.
- Existing 16/21/17/18 core platform indices stay exactly unchanged, including Towers Skybridges 18–21, Orbital Helix and existing spawn points. Outer decks are appended inside the *same* authoritative `Platforms` folder, so server-controlled AI path candidates, collectibles, shrinking/hazard and visibility routines see genuine collidable route parts. There are no fake noncolliding shortcuts or special physics buffs.
- Four map-specific outer exit sculptures per arena: original muted metal buttress ribs, tapered noncolliding wedge cap, glass inset; **no lights, particle emitters or new frame loops**. Their pieces are attributed to the physical platform, so Shrinking Arena moves, scales and restores them, and Disappearing Platforms hides/restores them with the physical collision instead of leaving fake ghost bridges. Complements the prior four nonblocking perimeter stations. Authored OBJ in `assets/source` still requires actual Roblox Studio MeshPart import; no fictitious 3D upload is claimed.
- AI overhead names now use Roblox's own native Humanoid name rendering instead of a visibly different custom text panel. Expanded fictional identity pool from 8 to 20 case-distinct usernames/display names; short social reactions are optional, ephemeral, and not chat messages. `AISurvivor` metadata / bot proxy remains explicit for server scoring, roster, moderation and honest player-count reporting. No real Roblox account impersonation.
- Extended existing real-engine arena, MapBuilder and bot tests with floor-to-route accessibility, 4-stud jump gap, spawn/boundary clearance, four per-arena decorative facades, preservation of base IDs, and natural unique usernames. **Physical device UX and actual FPS remain unverified** until Android staging/inspection.

## 2026-10-23 — Larger arenas and more natural survivor nameplates (candidate)

- Expanded all four playable arena foundations to 150–156 studs in X/Z (previously 94–104 studs). Existing core routes, physical platform heights, jump accessibility, spawn coordinates and sensors are intentionally retained; this is a first-stage expansion, not a complete replacement of the level architecture.
- Expanded the fall elimination plane to follow the new playable footprint, with a safety margin. Existing hazard targeting rules already derive bounds from the active arena base.
- Removed the permanent `· AI` suffix and persistent `TACTICIAN / TEAMMATE / DAREDEVIL` banners from the in-world AI survivor nameplates; keep natural display names, temporary contextual reactions and explicit server `AISurvivor` / `IsAISurvivor` flags for truthful identity, moderation and reward authority. Bots do **not** spoof Roblox Player instances, player lists or chat.
- Added four nonblocking sculpted perimeter station models per expanded arena: individually framed pylons, wedge caps, metallic housings, faceted core lenses, subtle guide notches and map-specific crane/dish/exchange/relay crowns, without new lights or per-frame work. Existing gameplay collision parts remain unchanged. Import-ready **original** sci-fi gate OBJ+MTL source (308 vertices, 560 triangles) added under `assets/source/` for a future authenticated Roblox Studio upload; this source is **not** a live MeshPart yet.
- Reduced Android bot-nameplate visual noise: compact display-name labels, local distance/depth-testing, temporary short social status only. Introduced a responsive 54–64px round-banner strip instead of a large central HUD block; reacts to camera/viewport changes without new render owners.
- Extended existing Roblox engine arena, mapbuilder and mobile-UI tests for enlarged playable floor, perimeter prop collision and clearance, compact bot names and round-title readability. Physical Android testing must verify that the larger arena feels alive, danger and AI movement remain viable, and visual budgets/FPS meet release expectations.

## 2026-10-23 — Authentic NPC streetwear silhouettes (candidate)

- Expand NPC appearance styles from 5 to 8, distributed deterministically across 20 existing fictional identities. Add original low-cost Roblox-native **knit beanie, split-front jacket and athletic wrist-wrap** cosmetics, each with at most two anchored-to-body welded noncolliding Parts. Existing visor, headphones, backpack, headband and shoulder strap remain. No externally imported or unverified asset IDs.
- Reduce the giveaway bot-only neon afterimage: only the backpack variant may retain a shortened, low-light, high-transparency trail. Other bots resemble ordinary players without constant emission. Keep movement speed, hazard awareness, server ownership, nameplate behavior, NPC attributes and user rewards unchanged.
- Extend existing Open Cloud AI engine suite to require all eight stable silhouettes, correct wraparound and invalid-index fallback. No new tests added.
- **Android acceptance NOT RUN**: verify all eight R15 styles, animation/weld continuity, no clipping on R6/R15 real characters, fair bot recognition in player menus, readability, GPU frame time and memory on live v68+ candidate.

## 2026-10-23 — Four genuine outer playable circuits per map + natural Roblox NPC names (candidate)

- Added four **physically playable** perimeter circuits to each of Classic, Towers, Crossroads and Orbital (8 solid grounded/two-stage platforms per map). Routes are at ±46–64 studs, on the new 150–156-stud map foundations, with a short ordinary-jump gap and a 3.6-stud rise. Large blocks touch the actual floor: no dangling low platforms forming R15 headroom traps.
- Existing 16/21/17/18 core platform indices stay exactly unchanged, including Towers Skybridges 18–21, Orbital Helix and existing spawn points. Outer decks are appended inside the *same* authoritative `Platforms` folder, so server-controlled AI path candidates, collectibles, shrinking/hazard and visibility routines see genuine collidable route parts. There are no fake noncolliding shortcuts or special physics buffs.
- Four map-specific outer exit sculptures per arena: original muted metal buttress ribs, tapered noncolliding wedge cap, glass inset; **no lights, particle emitters or new frame loops**. Their pieces are attributed to the physical platform, so Shrinking Arena moves, scales and restores them, and Disappearing Platforms hides/restores them with the physical collision instead of leaving fake ghost bridges. Complements the prior four nonblocking perimeter stations. Authored OBJ in `assets/source` still requires actual Roblox Studio MeshPart import; no fictitious 3D upload is claimed.
- AI overhead names now use Roblox's own native Humanoid name rendering instead of a visibly different custom text panel. Expanded fictional identity pool from 8 to 20 case-distinct usernames/display names; short social reactions are optional, ephemeral, and not chat messages. `AISurvivor` metadata / bot proxy remains explicit for server scoring, roster, moderation and honest player-count reporting. No real Roblox account impersonation.
- Extended existing real-engine arena, MapBuilder and bot tests with floor-to-route accessibility, 4-stud jump gap, spawn/boundary clearance, four per-arena decorative facades, preservation of base IDs, and natural unique usernames. **Physical device UX and actual FPS remain unverified** until Android staging/inspection.

## 2026-10-23 — Larger arenas and more natural survivor nameplates (candidate)

- Expanded all four playable arena foundations to 150–156 studs in X/Z (previously 94–104 studs). Existing core routes, physical platform heights, jump accessibility, spawn coordinates and sensors are intentionally retained; this is a first-stage expansion, not a complete replacement of the level architecture.
- Expanded the fall elimination plane to follow the new playable footprint, with a safety margin. Existing hazard targeting rules already derive bounds from the active arena base.
- Removed the permanent `· AI` suffix and persistent `TACTICIAN / TEAMMATE / DAREDEVIL` banners from the in-world AI survivor nameplates; keep natural display names, temporary contextual reactions and explicit server `AISurvivor` / `IsAISurvivor` flags for truthful identity, moderation and reward authority. Bots do **not** spoof Roblox Player instances, player lists or chat.
- Added four nonblocking sculpted perimeter station models per expanded arena: individually framed pylons, wedge caps, metallic housings, faceted core lenses, subtle guide notches and map-specific crane/dish/exchange/relay crowns, without new lights or per-frame work. Existing gameplay collision parts remain unchanged. Import-ready **original** sci-fi gate OBJ+MTL source (308 vertices, 560 triangles) added under `assets/source/` for a future authenticated Roblox Studio upload; this source is **not** a live MeshPart yet.
- Reduced Android bot-nameplate visual noise: compact display-name labels, local distance/depth-testing, temporary short social status only. Introduced a responsive 54–64px round-banner strip instead of a large central HUD block; reacts to camera/viewport changes without new render owners.
- Extended existing Roblox engine arena, mapbuilder and mobile-UI tests for enlarged playable floor, perimeter prop collision and clearance, compact bot names and round-title readability. Physical Android testing must verify that the larger arena feels alive, danger and AI movement remain viable, and visual budgets/FPS meet release expectations.

## 2026-10-23 — Android combat hit / result-camera ownership (candidate)

- Fixed local combat damage overlays: the old `WaitForChild("Humanoid", 5)` could resume after another avatar spawned and steal the active HealthChanged observer. Replace it with one current-character owner, tokenized callbacks and a streaming-aware ChildAdded/ChildRemoved repair path. Respawn/removal immediately cancels prior flashes/FOV kicks and disconnects old Humanoid events. Spectators, eliminated users and lobby characters no longer receive old-round red hit flashes.
- Cancel/reuse the active `DamageFlash` tween rather than leaving overlapping fades to fight on repeated hits. A delayed critical Bloom restoration only runs for its originating living avatar and latest hit.
- Victory/defeat FOV pulses no longer submit a late 72° camera tween over a newer round or different avatar; phase changes and new results cancel obsolete delayed callbacks. No network, server health, physics, rewards or mobile render owner added.
- Existing Roblox engine round-event spec now exercises valid and stale Humanoid ownership, replaced rig, missing owners, and removed character. Authentic R6/R15 Android/staging QA remains required.

## 2026-10-23 — Android touch and adaptive performance release candidate

- **Touch Dash:** responsive, comfortably sized 48–54px action target, recalculated only on camera/viewport rotation or replacement; the position stays clear of the native bottom-right Roblox jump button on short-landscape, ultrawide and portrait viewports. First-use teaching tip is rendered **to the left** of the thumb target rather than on top of the hazard HUD. Cooldown taps are swallowed by the owned GUI and cannot leak into an underlying touch control; server-side cooldown/grounded validation is unchanged.
- **Adaptive VFX:** only real active render frames are eligible for the 2.5s automatic graphics-tier sampler. Ignore and reset samples after >0.60s suspend/resume frame stalls; preserve genuine poor 2–5 FPS frames so slow devices still downgrade. FPS telemetry uses active time instead of counting app suspension; decorative clocks are bounded. No extra render owners or assets.
- **Performance and safety:** reduces repeated GUI property writes by computing responsive layout on viewport events rather than each 0.12s cooldown update. Reuses the landing-preview RaycastParams and filter list across 10Hz descent samples, refreshing them only on arena/section streaming replacement. Existing server authority, hazard telegraphs, accessibility, gamepad/keyboard shortcuts and VFX tier limits remain intact.
- Build Validation and Roblox Open Cloud Engine Tests must succeed on the exact PR SHA. The native Android/Studio orientation, control and 30-minute performance tests in `docs/ANDROID_QA_PLAYTEST.md` remain separate and unverified. Publishing to the existing public Roblox experience remains an explicitly guarded user action.

## 2026-10-23 — Physically sampled touchdown and transition polish (candidate)

- Fix unreliable landing reactions when native Roblox physics zeroes the avatar's vertical speed before Humanoid Landed/Running fires. Both body-pose and camera-feedback owners now retain the highest **actual observed downward speed during the current Freefall** instead of the velocity of a potentially already-grounded final frame. A shared deterministic gate requires at least 0.10 seconds of flight and a fresh (<0.30 second) physics sample; it bounds speed at 180 studs/s.
- Reset captured fall data at takeoff, avatar replacement and on Android app/background stalls. Do not replay landing VFX, camera pitch or a squat after a suspended render callback or a tiny stair step.
- Separate a new touchdown from running's steady-ground acceleration/pivot logic; the first grounded frame can animate the impact without generating a false sprint-launch or hard-stop skid. No server physics, jump timing, damage, remote or monetization change. Reuse existing render owners and visual budgets.
- Extend **existing** Roblox engine locomotion coverage for valid real fall captures, stale sample gaps, malformed numeric values and false landing skids. Studio/Android visual + audio acceptance and public-game publication remain unverified until an exact-SHA staged device session.

## 2026-10-23 — Responsive character animation/camera ownership (candidate)

- Prevent delayed initial avatar binding from taking ownership of an already replaced human R6/R15 rig. Ignore stale CharacterRemoving signals in the local body-motion controller; do not reset another avatar's Motor6D offsets or apply pose changes when the live player character differs.
- Rebuild the camera/landing-feedback motion controller around a single current-character token and event-driven Humanoid/Root attachment (no five-second yielding on Android). The same listener repairs a late-streamed or replaced root without restarting the RenderStep controller. Ensure only one Humanoid StateChanged listener is active, with stale callbacks rejected.
- Immediately clear camera spring/FOV contributions, airborne landing effects and local landing-preview signs when the current avatar is removed. This does not change game speed, jump height, physics, remote networking, server authority or collision.
- Release gates: both exact-SHA GitHub build and all five Roblox engine suites must pass. Authenticated Studio R6/R15 rejoin stress, Android low-network respawn/video and gameplay release certification remain **NOT RUN** until collected on the matching staged SHA.

## 2026-10-23 — Cross-platform descent reticle correction (candidate)

- The landing preview no longer depends on a straight-down floor hit before projecting horizontal motion. When jumping across a gap, that floor can be far below the actual elevated destination and incorrectly suppress the reticle.
- Use three short bounded future samples (0.08, 0.23, 0.36 seconds) based on real local velocity/gravity, within the existing 0.42-second forecast limit. Only display a marker if the ballistic contact time matches a sample, and the corrected landing ray **confirms the same solid platform** with no collapse warning. Otherwise hide it. Maximum four raycasts per 0.10-second airborne sampling interval, never a new frame loop or gameplay physics change.
- Extend the existing engine movement-assist regression suite for forward platform-gap jumps, false low-ground predictions, malformed time values and delayed contact. Maintain Android/Studio release gates and no public deployment.

## 2026-10-23 — Reachable jump takeoff cues (candidate)

- Add two compact floor-mounted parkour chevrons on each visually verified ascent takeoff in Classic Grid, Tower Run and Crossroads, including their central first-hop hubs. Select a target only from real spawned `PlatformN` geometry with a bounded horizontal gap (3.85 studs), a maximum 4.05-stud rise and no vertical overlap. Orbital keeps its authored physical Helix ramps, with no misleading leap arrows.
- Place every cue **inside** the physical platform and weld it to the deck. Reuse the current platform-identity visual owner: no extra RenderStep, force, raycast, remote, animation, light or asset download. Low-quality Android gets the same functional wayfinding, even where ornamental halves are omitted.
- The existing shrink-footprint listener resizes and repositions the arrows with real collision decks. A source/target collapse event disables cues during Warning and Gone; they return after the target is physically traversable again. Watch RouteTier for all maps under late Android streaming.
- Extend the existing arena-layout engine spec to validate route geometry, cue bounds and no false Orbital jump routes on all four arenas. As always, authenticated Android/Studio visual and performance certification and Roblox production deployment remain separate gates.

## 2026-10-23 — Android landing precision and fair coyote window (candidate)

- **Approach clarity:** add a local 2- to 4-stroke, non-colliding landing marker while an active player descends toward an actual sampled solid arena surface. A short ballistic horizontal projection is checked by a second collision raycast; previews beyond 0.42 seconds, unsupported gaps, collapsing decks and steep/non-walkable surfaces are omitted rather than inventing a safe landing.
- **Edge awareness:** the preview shifts from cyan to soft magenta when its projected contact is within 1.75 studs of a real deck edge. It does not assert disaster safety or grant a traversal advantage.
- **Mobile budget:** reuse the single movement-feel RenderStep owner; sample only while descending and at most once per 0.10 seconds, and retain four local parts (two visible on Low). No new looping thread, network traffic, lights, reward, physics or paid mechanic. Motion-reduction users receive static, muted marks.
- **Jump fairness:** a normal Humanoid Jumping transition now consumes the 0.10-second coyote allowance, preventing a repeated tap during the subsequent Freefall state from becoming an unintended double jump. Buffered landing and legitimate edge jumps retain their existing support.
- Extend the existing Roblox engine movement-assist suite with consumed-jump safety, airborne eligibility, bounded prediction, malformed values, and rotated-platform edge clearance. Authenticated Android gameplay and public-place publication remain separate release gates.

## 2026-10-23 — Contextual lava high-ground guidance (candidate)

- During READY and RISING LAVA rounds, mark only the real, server-authored tier-four elevated platforms with a restrained bilingual floating direction label and a client-side occluded outline. Other disaster rounds and the lobby remain unchanged.
- Every marker follows its actual moving deck through Shrinking Arena and shuts off when that deck has no collision or enters a collapse phase. No simulated escape routes, invulnerability, teleports, extra game assets or player advantage are introduced.
- Up to four billboards per arena (one for Orbital), up to four Highlights, no additional polling/render loop and no server remotes. The outlines are included in the existing visual-budget audit; Low quality uses labels without Highlights.
- Android/desktop visual readability and public release still require authenticated real-device review after successful GitHub build/engine checks.

## 2026-10-21 — Result card continuity and late reward ordering (candidate)

- Keep the result card visible until the server actually leaves RESULT; remove the ten-second local timeout that could repeatedly restart winner animations during longer multiplayer countdowns.
- Reject stale previous-round reward receipts and receipts received during the next READY, intermission or waiting. Keep valid current-round reward receipts arriving just before the RESULT phase.
- Extend the existing engine result-presentation tests; no new test file, remote, network loop or economy changes. Built on top of #115's authoritative outcome snapshot.

## 2026-10-21 — Authoritative round outcomes despite reward errors (candidate)

- **Frozen game results:** establish the human participant roster and winner roster immediately after the hazard finishes, *before* calling any per-player Coins, XP, quest, achievement or analytics handler. Previously the winner count and survivor list were updated inside the individually protected reward handler: if that handler failed, the actual survivor vanished from RESULT despite having won. The new round-owned outcome snapshot remains stable even when player data or late character updates change during payouts.
- RESULT broadcasts now include both server-owned `participantUserIds` and `survivorUserIds`. On Android and other clients, missing/delayed `RoundFeedback` reconstructs the correct victory, elimination or spectator status from those lists, not a potentially stale replicated `RoundParticipant` attribute. No victory or reward values are inferred for spectators.
- **Transparent payout failures:** a per-player settlement exception still does not stop other rewards or the next round, and the server **never retries** a potentially partial payout. It now sends that player's truthful win/loss result with a localized “rewards could not be verified” message instead of leaving an indefinite spinner or fabricating a +0 payout.
- Extend existing Roblox engine settlement and result-presentation specs for corrupted reward handlers, duplicate/left participants and authoritative loss/spectator recovery. Extend existing authenticated Studio E2E assertions to validate these rosters and require a real, non-failure reward receipt for successful acceptance.
- No new remote, leaderboard mutation, paid power, XP/coin rate change, client polling loop or public Roblox publishing. Build and real-engine tests still gate merging.

## 2026-10-21 — Fair replay health and explicit next-round E2E proof (candidate)

- **Correct fairness asymmetry:** eliminated players and AI rigs already respawn/reset to full health before each round, but human winners carried damage forward. Restore living contestants to their own `Humanoid.MaxHealth` only **after an accepted arena READY teleport**; do not heal during the active disaster, resurrect a dead rig, or reset a critical-health victory before the reward/medal logic reads it.
- Stamp the next authoritative `roundNumber` in the READY state; RESULT was already numbered after the win crash fix.
- Extend the **existing** authenticated four-client Studio E2E with a proof that a completed numbered RESULT is followed by the exact next numbered READY and a full-health survivor with a valid spawn. A pretty win card alone is no longer enough for the test to pass.
- Extend existing Roblox engine survival-feedback and result-presentation specs for dead-rig guard, custom maximum health, and replay transition ordering; no new test files, remotes or extra loops.
- No real public Roblox publication or authenticated Studio E2E result is claimed from CI alone.


## 2026-10-21 — Isolated per-player end-of-round settlement (candidate)

- After fixing the shared `roundChallenge` scope crash (#112), protect each participant's end-of-round progression/reward/achievement receipt processing from **other players' unexpected exceptions**. The original whole-server loop ran all player settlements without an error boundary: one bad achievement or quest handler could strand an entire lobby before the RESULTS countdown and next READY phase.
- Introduce a tiny sequential server-only `RoundSettlement.eachPlayer` dispatcher: record a warning with the failing UserId, continue other players and the global phase loop, and **never automatically retry a partially applied payout** (which could double-award Wins or Coins). Both the callbacks and diagnostic sink are protected.
- Extend the existing engine round-cleanup-resilience spec to simulate a failed player mid-batch and a broken error reporter. No extra unit spec files, remote events, per-frame loops, rewards or performance cost in gameplay.
- Limit: this is crash containment; a participant whose settlement throws can still have an incomplete reward receipt. Any such logged error requires investigation, not silent compensation.
- GitHub tests and merge do not publish the new code to the public Roblox game.

## 2026-10-21 — CRITICAL: winner-result crash and silent post-round recovery (candidate)

- **Root cause fixed:** `runDisasterSet` created `roundChallenge` as a local variable but the caller performed payout, mastery, reward events and result broadcasts outside that scope. Accessing `roundChallenge.Target` at settlement attempted to index nil, aborting the main server `while true` loop after a match. Return the exact played challenge as a sixth value, validate the settlement contract and reuse it for victory and loss rewards, HUD result metadata, and round replay.
- Stamp the authoritative `roundNumber` on all `RoundFeedback` receipts and RESULT `RoundState` countdown updates so clients can associate a reward with the correct finished match.
- **Client fallback:** reconstruct a truthful local result from the replicated survivor roster if the personalized reward RemoteEvent is missed or late. Do not fabricate Coins/XP; show localized “rewards syncing” until the real receipt arrives. Spectators never receive a false victory. First-session RESULT ticks no longer dismiss the win card when player progress attributes replicate late. Preserve the next-round countdown on each tick.
- Extend the existing Roblox engine result-presentation tests for winner/defeat/spectator recovery and FR/EN fallback strings, plus the existing authenticated four-client Studio E2E probe to require the actual per-player reward receipt before it counts the result UX as passed.
- **Publishing still gated:** Open Cloud engine CI cannot prove authenticated Roblox Studio multiplayer gameplay or the public place deployment. Test on real Android before using the explicitly confirmed public playtest publish workflow.

## 2026-10-21 — Humanlike AI dodging during multi-warning rounds (candidate)

- **AI reaction stability:** when a bot is already aware of a live hazard, prefer that warning if another active warning is only marginally closer (within 4 studs). This prevents alternating between two bomb/meteor warnings on consecutive 0.18-second brain ticks and repeatedly restarting the bot's existing humanlike reaction delay. A substantially nearer warning, a warning that is no longer active, or a bot that has exited its detection radius still prompts a new decision.
- **Keep genuinely safe routes:** the six-heading emergency escape planner checks actual walkable floor support and all current meteor/bomb corridors. Preserve its chosen destination exactly; do not add a later random social-spacing offset that could steer an AI back into the impact or off a platform. Normal arena roaming and social separation remain unchanged.
- Existing engine AI rules specs cover warning-focus hysteresis, priority switches, disabled/stale values and bounds. No extra bot speed, reflex privileges, teleport, remote, UI loop, unit test file or economic modification.
- Changes are GitHub-side only. Production Roblox publication and Android playtests are not implied by passing CI.

## 2026-10-21 — Shared impact warning separation (candidate)

- **Meteor Shower + Bomb Rain:** coordinate their still-pending ground-warning positions through a small server-only per-round registry, including when both disasters run together during Double Chaos. Sample up to eight bounded arena-footprint locations for a new warning and prefer a centre at least **22 studs** from all active warnings in the horizontal plane; if shrinking geography cannot fit it, choose the best available location instead of blocking the disaster.
- Preserve the real warning-to-impact timers, radius, damage, hazard AI vision, existing visual cues and spawn cadence. No new client polling, remotes, gameplay reward or persistent data. Warning markers are unregistered as strikes resolve or cancel and destroyed references are purged.
- Extend the existing Roblox engine arena-variant spec with deterministic multi-warning separation, vertical projection, constrained-floor fallback and stale-marker cleanup. Pending exact-head build and real-engine checks before merge.
- GitHub-only gameplay change; the live Roblox place is not updated by this pull request.

## 2026-10-21 — Meteor and bomb round-end readability (candidate)

- Meteor Shower and Bomb Rain now stop **creating new lethal telegraphs** when their complete warning and impact cannot resolve before the server's authoritative round deadline. This closes the same late-round surprise window already addressed for collapsing platforms and dynamic arena challenges.
- Both hazards keep their current spawn cadence, damage, radius, client warning contours and server-side hit checks while the round is active. Existing in-flight strikes can still resolve before the deadline; there is no new grace period or reward change.
- Extend the existing Roblox engine disaster runtime suite with boundary tests for solo-length meteor and bomb warnings; no new tests, remotes, client loops or persistent state.
- GitHub source change only; controlled Roblox publication and Android gameplay review remain separate.

## 2026-10-21 — Disappearing Platforms mobile escape fairness (candidate)

- Increased **real server-authoritative collapse warning** from 0.75 to 1.35 seconds. The warning retains solid collision throughout, giving touch users and ordinary-speed AI an actionable chance to leave a 12-stud deck before it disappears. The hazard still removes the same physical deck for two seconds, with all visual skins/rails hidden and restored together.
- Added a short, spatialized single-shot warning sound for a disappearing **ordinary** deck only when the player's character is within 26 studs. Existing long-bridge audio is preserved; both respect mute and share a one-second anti-spam budget, with no new perpetual loop or extra VFX.
- The server refuses to announce a late collapse if its warning + full outage + two-second restoration margin cannot finish within the remaining round time. Fully compatible with brief Solo Rush rounds and cleanup.
- Extended the pre-existing real Roblox engine disaster integration spec to check that warning collision stays solid for over 0.65 seconds, audio-independent server state, safe deadline gating and original restoration.
- **No public Roblox deployment yet.** Headless engine validation and Build Validation must be green; physical Android playtesting remains necessary.

## 2026-10-21 — Rookie round challenge consistency (candidate)

- Align the shared round challenge with the **existing first-three-round protection**: whenever any active contestant has played three or fewer rounds, everyone receives the achievable **FIRST SURVIVAL** goal rather than advanced shard, near-miss or momentum tasks.
- This closes a mismatch where dynamic arena hazards were already disabled for beginners but the global rotating challenge could still demand advanced play in rounds two or three.
- No extra coins, XP, new reward types, analytics events, remotes or client-side loops. Veterans keep the normal six-challenge rotation once the entire group has cleared onboarding.
- Extended the existing engine round-challenge suite for the three-round window; physical Android and public Roblox deployment remain separate release gates.

## 2026-10-21 — Observable four-arena difficulty and AI fairness (candidate, not published)

- Added two **server-authoritative, end-of-round Roblox AnalyticsService samples per connected human**: `ArenaSurvived` (0/1) and `ArenaTimeAliveSeconds` (first actual death vs live round duration). Grouped by one of four arena IDs, Solo/Multiplayer, primary disaster, Double Chaos and whether the dynamic arena mechanic truly started.
- Added `ArenaBotSurvivalFraction` once per server round (not once per AI or player), if real in-round AI survivors started, attributed to one connected human solely because `AnalyticsService:LogCustomEvent` requires a Player. Initial AI roster and early-ending status are recorded in bounded dimensions; samples never include bot identity.
- Preserve existing `ArenaMechanicUsed`, shard, session, quest and economy events; **no DataStore changes, new remotes, gameplay difficulty modifications, ticker, extra physics or per-frame analytics**. Precise death timing captured by the existing Humanoid.Died connection.
- Extended existing Roblox engine suites for finite time bounds, human/bot fractions, sanitized low-cardinality arena dimensions, and actual dynamic mechanic activation for all four playable arenas.
- Added `docs/ARENA_BALANCE_TELEMETRY.md` with explicit Explore aggregation instructions, fair same-disaster comparisons, survivorship/disconnect biases, AI early-end caveats and Android playtest gates.
- Source changes alone do **not** provide any live metrics or publish the public Roblox experience. Review the real Creator Dashboard data only after a safe, verified deployment and sufficient observed rounds.

## 2026-10-21 — Four-arena balance and truthful round guidance (candidate, not published)

- All **four** arena round briefs now reflect the dynamic mechanic actually started in the server, rather than a generic announcement even when the corresponding extra challenge is disabled. Beginners still see accurate help for their baseline pads, bridges, Flux Relays, and Grid Circuit.
- Tower Run bridge outages are suppressed during forced-movement disasters (Tornado, JumpShock, LowGravity, SpeedSurge), in addition to existing floor/freeze conflicts. The physical Skyrails remain open and functional.
- Orbital Pulse and Crossroads Switchyard keep their baseline movement skills while disabling only the *optional charged impulse* in rounds with forced motion, Freeze, Rising Lava and other incompatible interactions. This protects genuine steering skill from uncontrolled disaster velocity, especially on touch devices.
- Tower bridge collapses and Classic floor waves cannot start in the final seconds unless their entire warning and active phase will finish with two seconds spare. This includes short Solo Rush rounds and avoids hard-to-interpret end-of-round drops.
- Extended **existing** real Roblox engine arena integration tests to cover conflicting live disaster contexts, accurate replicated hints for enabled/disabled mechanics on all four maps, default mechanic preservation, and Solo Rush event deadlines. No new test suites, client loops, remotes, economy changes or published Roblox game build.
- **Pending:** exact-head compilation + Roblox Open Cloud engine tests, then Android game-feel and multi-round playtesting before public publication.

## 2026-10-21 — Classic Grid floor sweep (candidate, not published)

- Classic Grid gains a **distinct nonlethal survival timing challenge**. One of four fixed floor rows glows amber for 2.6 seconds, flashes red for 0.9 seconds, then rests. Rows rotate with the round seed, separated by six-second intervals; the first wave cannot start until six seconds into the round.
- A grounded real player or in-round bot standing in the red row gets a **small, centre-directed horizontal knockback**, capped at 42 horizontal velocity. Jumping or changing lanes avoids it entirely. High platforms are unaffected; floor collision is never removed and there is no additional health damage, teleport, reward or new remote.
- Four simple server-authored noncolliding row lights are visible on Low Android graphics without local Part spawning, heartbeat connections or a new HUD. An existing Classic client loop plays one quiet, spatialized warning cue per wave near the player (respecting mute). The existing four-station clockwise Grid Circuit and blue escape pads are unchanged.
- Survivor AI recognizes the wave, waits its normal reaction time, and moves across the nearest band edge without speed/jump benefits. Regular meteor/bomb threat avoidance retains priority.
- The feature runs only in experienced single-disaster rounds, and is disabled alongside freezing, falling floors, rising lava, shrinking arena, tornadoes, jump-shock and low gravity. Cleanup restores every warning row.
- Extended the existing real Roblox engine integration suite to inspect live rows, collision invariants, direction/speed, player/bot eligibility, elevated/jumping exemption, one impact per wave and cleanup. **No new unit-test suite.**
- **Source candidate only:** PR CI, Roblox Studio/device gameplay QA, frame-rate checks and controlled public deployment remain separate gates.

## 2026-10-21 — Crossroads Switchyard (candidate, not published)

- Added **Crossroads Switchyard**, a skill-based lateral route cut at four central junctions. Two opposite junctions light up gold at a time; the active pair rotates every nine seconds. The existing inward Flux Relays, outer launch pads, arena floor and all four original routes remain unchanged.
- A real survivor (human or in-round AI) must already be moving *sideways* through a charged junction: strong straight-through Flux return motion never triggers a surprise side launch. Valid directional turns receive a bounded +20 tangent impulse (48 horizontal cap). Each character can claim each junction only once per round, with a four-second global cooldown.
- Each junction uses a noncolliding server-authored trigger, two small painted floor strips and a near-field directional sign. Active/inactive status is visible at Low VFX quality without requiring new HUD updates, particle loops or paid assets.
- Enabled only for experienced, single-disaster Crossroads rounds; suppressed when any contestant is in their first three rounds, during Double Chaos, Rising Lava or Shrinking Arena. Uses round-owned cleanup to reset pads, signs and signals.
- Expanded the **existing** Roblox engine arena-mechanics integration suite for physical pads, two alternating lane pairs, intentional steering, direction, speed caps, antispam and cleanup. No new test suite.
- **Not deployed:** exact-head CI and real Roblox Studio/Android visual, collision, AI and multi-round smoke checks remain necessary.

## 2026-10-21 — Orbital Ring pulse-route skill (candidate, not published)

- Added **Orbital Pulse** for experienced single-disaster Orbital Ring rounds. Two opposite ramps are highlighted in gold; the charged pair rotates every eight seconds. All eight original ramps, collisions, and traversal options remain permanently available.
- A correctly timed, server-verified inward Helix Flow crossing earns a small, capped forward impulse (+7, 42 horizontal cap). Each rig can collect the pulse **once per lane per round**; both real players and genuine in-round AI are eligible under the same server checks, with no client-provided reward or new remote.
- The existing metal/grain/neon strip decoration changes gold on the two active routes, remaining visible even on Low graphics and Reduced Motion. Medium/High reuse their existing 8/24 moving glyphs and flow burst; no extra Part allocation, light, collision or client update loop.
- In-round AI modestly prefers active Helix ramps where elevation is reachable, without overriding hazard avoidance. New mechanics do not activate during any entrant's first three rounds or in Double Chaos.
- Extended existing Roblox engine integration coverage for the pulse pair cycle, physical map gates, human/bot eligibility rules, real velocity bounds, once-per-lane behavior and full phase/color restoration on cleanup.
- **Not published:** exact-commit CI plus Studio/Android validation remain mandatory. Check gold-route clarity, fluidity, predictable speed and multi-round reset before public deploy.

## 2026-10-21 — Tower Run dynamic Skybridge pressure (candidate, not published)

- Follow-up safety fix: round bots now treat Tower Skybridge warning phases as urgent, choose a supported end-of-bridge tower deck on either span orientation, and never sidestep from a narrow warning bridge into the void. All changes use existing bot Humanoid movement without teleport, boosted speed or unfair survivability.
- Skyrail client canopy structures and animated couriers dim during the warning and become fully invisible while the physical bridge is absent, restoring their exact original appearance afterward. Phase and collision changes trigger immediate visual synchronization, including on Low-end Android profiles; no new polling loop.
- Extended the existing AI engine spec to cover east/west, north/south, middle-span momentum, invalid heights and off-bridge positions. Complete engine checks and real-device playtesting remain mandatory.

- One Tower Run skybridge now signals a **2.6-second amber warning**, drops its real collision for **1.8 seconds**, and then fully returns; the other three routes remain available. Bridge selection rotates across rounds. This is a tactical route change rather than extra lethal damage.
- Disabled for the first three entered rounds of **any** human contestant, Double Chaos, and floor-conflicting disasters (Disappearing Platforms, Shrinking Arena, Rising Lava, Freeze). Only active for experienced, single-disaster Tower Run rounds.
- Client warning graphics use two transverse deck-contained stripes instead of square-platform diagonals, with one nearby positional audio cue. Low VFX and Reduce Motion continue to work; no new client render loop or paid asset.
- Original server deck paint, underside ribs, rails, glow and client trims all fade with the actual physical bridge. Skyrail slipstream cannot trigger or award progress while its deck is absent.
- The round cleanup immediately restores collision, decor and all phase attributes, including when a match ends mid-warning/outage. Existing arena mechanics engine integration coverage verifies warning, outage and recovery.
- **Not a Roblox public update.** Build/Open Cloud checks and real Android/Studio movement, visual warning, solo AI and frame-rate validation remain required.

## 2026-10-19 — 1.0 release packaging hardening (unreleased)

- Build Validation now archives the compiled Roblox `.rbxlx`, its SHA-256 checksum and a provenance manifest identifying its exact source SHA and explicitly marking the package **NOT_PUBLISHED / NOT_CERTIFIED**.
- Replaced obsolete `publish-roblox` branch rollback instructions: production publication is manual-only from certified `main`, with a verified Creator Version History restore as the separate owner-operated recovery option.
- Reconciled the release checklist with 73 engine specs and the latest verified exact-SHA automated baseline; automated checks remain distinct from authenticated Studio, device, persistence and real-player acceptance.
- Added a French step-by-step Creator Dashboard release guide, including staging isolation, current Roblox audience/maturity checks, owner confirmations and exact-SHA release evidence. No public Roblox deploy, rollback or audience change performed.


## 2026-10-15 — Native Roblox VFX photo/video review (unreleased)

- Added a small opt-in PHOTO menu available on a loaded client: live Roblox-engine screenshots without UI, screenshots with HUD, and an eight-second native video of rendered gameplay (supported devices only).
- Added a one-shot **NEXT IMPACT** capture: a server-reported hazard impact must be in range and on-camera before a real engine frame is taken, without spawning or simulating any effects. The action is disarmed after a round.
- Roblox prompts the player before saving any photo or video to their in-app Captures gallery. Nothing is silently saved, uploaded, sent to GitHub or shared with ChatGPT.
- Documented Android capture and export to device storage for independent visual QA. **No genuine screenshot was produced by GitHub CI**, and this branch still requires an explicitly deployed staging candidate plus real Roblox client/device review.

## 2026-10-15 — Directional dodge and visible reaction budget (unreleased)

- Turned existing near-miss avatar dodge beams into velocity-aligned afterimages for strafing, retreating and sprinting. Slow or stationary characters keep a neutral silhouette; attachment, Beam and lifetime caps remain unchanged.
- Culled optional offscreen remote human/AI shock and landing effects using the shared viewport rule, while always preserving the local survivor's reaction. Camera position rather than avatar distance now governs spectator-friendly cosmetic selection.
- No new animation assets, beams, lights, particles, engine forces, remotes, damage changes or pay-to-win content. Automated build/engine verification and real Studio/Android art/overdraw measurement remain required.

## 2026-10-15 — Character VFX, bot motion and Showtime transitions (unreleased)

- Crossfaded the six existing 3D Showtime hologram parts between robot/shuffle/orbit and other dance poses, using the stage's current update cadence and without creating new geometry. Reduced Motion keeps an immediate still pose.
- Prevented synthetic AI launch/skid/pivot effects after mobile app suspension by rejecting stale velocity intervals and clearing obsolete bot cue styling; gameplay AI, physics and native Roblox animation tracks are unchanged.
- Improved Meteor/Bomb pressure-reaction selection: prioritize the local player and then the nearest eligible human or AI, instead of exhausting limited shock-reactor slots on the Players iteration order. Actor and concurrent Beam limits remain intact.
- Restyled existing character reaction Beams with a four-stop thermal highlight/cooling gradient and softened alpha tail without increasing allocations or event cadence.
- Documented Studio/Android acceptance for hologram motion, mixed human/AI impacts and continued multi-round cleanup. Automated checks alone do not certify the requested 9/10 AAA quality.

## 2026-10-14 — R6/R15 physical-feel animation finishing (unreleased)

- Added a bounded, damped compression-to-rebound response on real character landing: torso/root weight shift, hip tuck and arm counterbalance, with fall-speed intensity rather than a fixed theatrical bounce.
- Reused the existing local C0 additive rig owner, original R6/R15 joint mapping, tier scaling, ReduceMotion envelope and Showtime emote priority. No extra Motor6Ds, new AnimationIds, physics impulses, camera controls or paid assets.
- Clamped cosmetic RenderStep time after app suspension and prevented stale inter-frame speed/turn deltas from triggering fake Launch, Skid or Pivot floor effects when Android resumes.
- Expanded the visual acceptance scorecard for grounded jumps, large falls, rapid pivots, emote transitions, Android frame delays and real render/performance comparisons. No device or AAA-rating claim is made without physical validation.

## 2026-10-14 — Disaster VFX sculptural finishing (unreleased)

- Replaced generic orbiting Tornado debris blocks with original, angled WedgePart wind shards: a height-offset helical arrangement, matte storm-metal with occasional cold glass glints, no increase over the existing 5/8/12 Low/Medium/High part budgets.
- Positioned storm shards at the live funnel immediately on replication. Tornado motion and glow now freeze in ReduceMotion; visual time advancement is capped after mobile app suspension.
- Reshaped the existing Freeze warning emitter into a drifting, low-emission crystalline condensation profile (size/transparency/color ramps) without extra emitters; enabling ReduceMotion clears already-emitted mist immediately.
- Kept full cinematic Meteor/Bomb impact sculpture, plume, core light and sparks for near viewers; at distance, preserve the short impact pulse while omitting costly secondary overdraw and local shrapnel. Authoritative danger markers/damage remain untouched.
- Stabilized the existing lava danger glow during ReduceMotion and capped its decorative timing after Android background/resume. No changes to gameplay, physics, visual-warning ownership, damage, monetization or external assets.
- Release gate: exact-head Roblox build and Open Cloud engine-suite success, then authenticated Studio/Android side-by-side art review and performance/thermal measurement. A 9/10 AAA claim is not certified by code changes alone.

## 2026-10-14 — Four-map sculptural finish and motion continuity (unreleased)

- Original client-local machine detail passes on Classic radar, Towers lift, Crossroads transit signals and Orbital reactor containment: 0 Low / 2 Medium / 4 High extra cosmetic pieces per sculpture, with wedge-based sculpted detail on three maps.
- Towers guide shoes travel with the pre-existing lift animation; all additions are anchored, noncolliding, non-touchable and non-queryable.
- Existing signature foundation light has a subtle slow opacity treatment, with an unchanged static ReduceMotion pose; no new light/particle/sound asset IDs.
- Replaced uptime-based arena-signature choreography with a bounded accumulated visual clock to avoid position jumps after mobile app suspension and phase transitions; malformed round snapshots are handled.
- Build and Roblox Open Cloud results must be checked on the same exact candidate SHA; physical Studio/Android captures and profiling are still required for any AAA-quality claim.

## 2026-10-14 — Solo AI hazard-priority correction (unreleased)

- Moved server-side live meteor/bomb and collapsing-platform threat detection ahead of bot idle pauses, stuck recovery and cosmetic hesitation, so imminent hazards can interrupt pauses instead of waiting for their expiry.
- A valid urgent escape clears any stale turn delay and skips the ordinary arrival idle and random jumps. Existing humanlike pacing is retained when no danger is present.
- No immunity, teleport, boosted movement speed, collision edits, damage tuning or reward changes.
- Expanded the authenticated Studio/Android playtest report with reproducible danger-response checks. Automated build, full engine suite and physical devices must still confirm the candidate before release.

## 2026-10-14 — Mobile mechanic-feedback hardening (unreleased)

- Cancel overlapping screen-flash and milestone-banner tweens when mobility pads, Skyrail, Flux and Helix events arrive in rapid succession.
- Preserve high-value Skyrail Ace, Flux Master and Orbit Master success cues despite the cosmetic event throttle.
- Honor Reduce Motion by removing full-screen mechanic flashes and character burst particles, including when the preference changes mid-animation.
- Skip temporary mechanic-burst particle allocation in Low graphics quality, while preserving the textual reward banner.
- Translate live mechanic success banners into French using stable server mechanic IDs; the server's physics, damage, rewards, analytics and thresholds remain unchanged.
- Code changes have not yet been physically verified in Roblox Studio or on Android; exact-head automated CI remains the prerequisite for review.

## 2026-10-01 — Release-candidate game-feel and mobile polish

- Added optional server-authoritative Chaos Shards with coin rewards, daily-quest progress, analytics and round-result breakdown.
- Added compact live round-focus HUD for Chaos intensity and shard progress.
- Added contextual first-session coaching for voting, positioning, survival and shards.
- Added close-call / near-miss feedback, sound, combo display and per-round summary tracking.
- Added critical-health clutch-survival feedback and analytics.
- Improved spectator HUD with live survivor/time context and hid active-player HUD while spectating.
- Added adaptive shard visuals and removed redundant per-frame world-polish work for better mobile performance.
- Fixed procedural world polish so it rebuilds on arena swaps inside the same GeneratedMap.
- Preserved cosmetic-only monetization and server-authoritative gameplay.

All notable changes to Chaos Survival are documented here.

## 2026-10-08 — Unified mobile/visual candidate

- Combined Showtime social features, animated arena signatures, impact meshes, spectator-aware character reactions and expressive R15 movement onto one branch.
- Reconciled the three new local visual-budget folders: LobbyShowtimeLocal, ArenaSignatureLocal and ImpactSetpieceLocal.
- Preserved spectator coverage, added Showtime to CI engine sharding and retained rate-limit-aware Open Cloud retries.
- New candidate is not shipped or certified; awaiting exact-commit validation and a physical Android/Studio run.


## 2026-10-08 — Spectator stability and mobile UX

- Keep the spectator camera on the same survivor across joins, eliminations, and list reordering.
- Select the immediate next survivor without skipping after elimination.
- Reuse health listeners and hazard glyph instances across RoundState updates.
- Restore secondary Double Chaos symbols after narrow-to-wide mobile rotation.
- Add four engine regression cases for spectator selection.

## Unreleased — Release Candidate Hardening

### Gameplay
- 11 server-authoritative disasters with Solo Rush and allowed Double Chaos combinations.
- 4 rotating arena variants with arena-specific geometry, guidance and mobility mechanics.
- Arena-aware Bomb Rain / Meteor targeting and deterministic meteor impact visuals.
- Shrinking Arena keeps platforms aligned with the playable zone.
- Rising Lava includes deterministic contact fallback inside the real lava footprint.
- Near-miss, critical-health, streak and result feedback.

### Accessibility
- Added an independent persisted Haptics toggle alongside Reduce Motion and Audio.
- Accessibility touch controls now meet the 44 px mobile target.
- Disabling haptics immediately stops active motors; ReduceMotion also lowers haptic frequency/intensity.

### Reliability
- Persistent cosmetic/premium mutations now share the authoritative `PlayerData.canMutate()` active-session guard.
- Rapid session handoff tests cover forced takeover, stale save/release rejection, clean save/release and subsequent rejoin.
- DataStore retry/backoff, schema normalization, dirty-aware autosaves and shutdown saving.
- Temporary-session protection when persistence is unavailable.
- Cross-server session ownership / stale-save protection and handoff lifecycle.
- Loaded-session guards around progression, cosmetics, quests, achievements and premium grants.
- Reverse-order round cleanup for stacked disaster resources.
- Idempotent player/service setup and serialized player data loads.
- Class-safe RemoteEvent registry.

### Visual readability
- Meteors now use a more amber primary accent and Jump Shock a more electric-cyan accent to reduce overlap with Lava/Low Gravity.
- Every allowed Double Chaos pair is engine-tested for minimum primary-accent separation and bounded combined post-processing.

### Performance
- VFX quality promotions require stable FPS samples (2 desktop / 3 touch), while downgrades remain immediate.
- PerformancePulse records VFX tier-transition counts to identify oscillation/thermal instability.
- Tier-specific visual complexity budgets cover local Parts, Lights and ParticleEmitter/Trail/Beam effects.
- Adaptive High / Medium / Low VFX quality.
- Client-local hazard visuals and warning animation.
- Distant hazard impact network culling.
- Near-miss throttling.
- Mobility-pad VFX quality updates are event-driven.
- Warning renderer can sleep while idle.
- Concurrent local impact bursts are capped by VFX tier.
- Autosaves are distributed over time.

### Testing / CI
- 63 engine specs assigned exactly once across Open Cloud shards.
- Exact-SHA Release Candidate Gate that verifies green Build Validation + real-engine Open Cloud results and emits a release-evidence artifact.
- Publish workflow now refuses any SHA without green Build Validation + Open Cloud results and archives publication metadata with the built place.
- Studio E2E visual contracts for FOV bounds, unique Clouds, non-collidable decorative geometry and tier-specific visual budgets.
- Centralized FOV composition with CI enforcement that only `juice.client.lua` writes Camera.FieldOfView.
- AI animation catalog + locomotion blend/tempo tests.
- Luau syntax validation and Rojo place build.
- Real Roblox Open Cloud engine tests, sharded into core / gameplay / matrix suites.
- Every arena × disaster combination and allowed Double Chaos pair covered.
- Fair-play monetization guard.
- Client protocol guards.
- Server service export contract audit.
- Production release-hygiene scan.
- Four-client authenticated Studio E2E harness with viewport, input, voting, movement, late-join state and spectator probes.
- Release-candidate certification checklist and playtest report template.

### Monetization
- Cosmetic-only Game Pass infrastructure.
- Live paid offers remain hidden until real IDs are configured and device/retention gates pass.
- No paid gameplay power or progression multiplier.

## Release policy

A `v1.0.0` tag should not be created until `RELEASE_CHECKLIST.md` passes for the release lineage, including authenticated Studio E2E, physical Android/desktop QA, persistence/rejoin testing and a small public alpha.

## 2026-10-05 — UX clarity and localization pass

- Preserved actionable hazard guidance from voting through READY and the 3/2/1 countdown.
- Added combined guidance for both hazards during Double Chaos.
- Exposed accessibility controls on a player's first session outside critical gameplay phases.
- Localized first-time world markers, lobby wayfinding, survivor elimination feed and result survivor badges.
- Localized arena names, strategies and mobility-pad explanations from stable arena IDs.
- Made the pre-round arena strategy card use pixel-safe mobile sizing.
- Localized round-result rewards, mastery, medals, streaks, challenge feedback, next goals and persistent lobby stats.
- Added stable arena/disaster IDs to round feedback so client presentation does not depend on English server copy.
- Expanded CoreLocalization engine coverage for the new UX copy.

## 2026-10-05 — Social loop and visual identity

- Added `SOCIAL_EXPERIENCE_PLAN.md` to define the session as a social ritual: staging → vote → anticipation → shared danger → result story → replay/invite.
- Added a native Roblox friend-invite affordance after completed rounds, hidden during first-time onboarding, voting, READY and active survival.
- Added contextual win/loss social framing and FR/EN invite copy.
- Added an in-world Crew Signal landmark in the lobby.
- Added a persistent Last Chaos recap board showing the previous hazards, arena and survivor count during the next lobby phase.
- Expanded result RoundState payload with stable arena/disaster IDs and survivor counts for presentation systems.
- Added adaptive phase-aware bloom: stronger for presentation, reduced during active gameplay.
- Added SocialExperienceRules and engine coverage; Open Cloud shard mapping updated.

- Crew invites now carry validated LaunchData so a real invite-driven friend arrival can be recognized and celebrated without gameplay rewards.
- Added server-authoritative one-tap multiplayer result reactions (GG / AGAIN / WOW), limited to one reaction per player per result.
- Added social funnel analytics for CTA exposure, prompt activation, invite-driven joins and result reactions.

