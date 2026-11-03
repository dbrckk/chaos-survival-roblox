# Chaos Survival — Roblox

## Production de vrais assets 3D de plateformes / ponts — 3 novembre 2026

Deux **nouveaux assets 3D originaux triangulés**, et non des Parts natives, sont prêts à importer dans l'inventaire Roblox du créateur : **1 156 triangles** pour le plateau de saut industriel, **920 triangles** pour un tronçon de passerelle. Chaque mesh possède des normales, UV, tangentes et sept matériaux originaux. Source et procédure : [pipeline de vrais assets de plateformes et passerelles](docs/REAL_3D_PREMIUM_DECK_BRIDGE_ART_PIPELINE_2026-11-03.md). **Import Roblox vérifié et approuvé** : plateau original Model `98478693994864`, module de passerelle Model `94023662427980` ([preuve d'import](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41614704198)). Les vrais modèles sont intégrés par `PremiumRouteMeshAssets` et `PremiumRouteMeshKit` dans le code source ; les plateformes physiques et leurs catastrophes restent inchangées. Leur rendu public et leurs performances Android sont à confirmer après validation/publication exacte du nouveau commit.

## Registre urgent visuel AAA — 3 novembre 2026

**[Inventaire détaillé : 124 actions visuelles priorisées (33 P0 / 80 P1 / 11 P2)](docs/URGENT_AAA_VISUAL_BACKLOG_2026-11-03.md)** : assets 3D/2D, meshes originaux, textures PBR, ciel/lumières, météo, onze catastrophes, avatars/IA, UI mobile, caméra, LOD, vignettes et critères de livraison. **Ce registre ne certifie pas encore un rendu AAA.**

**Attention :** le dernier main a un **échec de test Roblox Cloud** pour les nouveaux châssis de meshes importés (attendu 4 pièces de fondation, obtenu 11). La publication a été bloquée ; la précédente version publique, validée sur le commit `3a482589f07d2d4987de2633f7e411681950fc08`, est toujours la dernière livraison confirmée. Ne pas prendre un build Rojo réussi pour une publication Roblox.

Fast multiplayer disaster-survival game built with Luau + Rojo.


## Current premium visual milestone (3 November 2026)

**Live baseline:** the existing public Chaos Survival place was updated at exact main SHA `22308afc4dded7e84c165734cd72dbf40a7cc7bb` ([verified Roblox publisher](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41601949632)). The next art-direction milestone is tracked in [premium 2D/3D, PBR and lighting production notes](docs/PREMIUM_ART_PASS_2026-11-03.md). It changes rectangular landing lip Parts into four true sloping 3D wedges, displays a strictly bounded number of **already approved original imported MeshPart models** on Android, creates original resolution-independent machined UI frame artwork, reduces colored environmental wash, lifts mobile readability and expands the existing PBR allocation within unchanged Android global limits. This source milestone is **not confirmed live** until its new exact source SHA is built, tested on all five Cloud engine shards, and published through the guarded existing-place workflow. Physical Android capture and frame-rate validation remain separate from source/Cloud correctness.


## New original volumetric arena floors (source candidate; not live yet)

The [second major visual architecture pass](docs/FIVE_ARENA_VOLUMETRIC_GROUND_2026-11-02.md) gives **all five arenas 73 original, non-colliding floor/undercarriage details per active map**, including 36 original structural floor panels eligible for the existing licensed 2K PBR camera budget. The real shrink owner now scales this artwork with the survival floor: no phantom platforms, AI walls or hazard masking. The preceding [PR #564](https://github.com/dbrckk/chaos-survival-roblox/pull/564) structural corner cladding passed exact-SHA Build Validation and all five real-engine suites on 2 November (source SHA 2732da8), but neither the new floor treatment nor that cladding has been published to the public Roblox experience. Await full validation before deployment.


## Next major update — authentic eight-bot ground routing and five-arena Android quality

The [2 November large-release candidate](docs/MAJOR_RELEASE_2026-11-02_PHYSICAL_NAVIGATION.md) adds asynchronous, **physically supported ground-obstacle pathfinding** for bots which cannot escape major arena structures using local detours. Routes are server-owned, never teleport and are cancelled by real hazards or round changes. Combined with the **already merged** raised-deck AI escape corrections, this is the next substantial gameplay reliability milestone; the existing original 3D arena/lighting and mobile quality targets remain mandatory release gates. **This branch is not published to Roblox.** Compile, five real-engine suites, authenticated Studio visual review and physical Android testing are required before the guarded public-place update.


**Eight-participant round roster (published, awaiting physical playtest):** the owner has set the starting place to eight human visitor slots. The public build now contains the READY-time autofill logic for up to **seven original AI bots**, aiming for eight participants at the start of a round (not eight survivors at every instant). The exact-sha public publishing workflow succeeded on 1 November; Android and multiplayer observation must still confirm live spawns and performance. See [eight-seat autofill and validation](docs/EIGHT_PARTICIPANT_BOT_AUTOFILL_2026-11-01.md).

## Monumental original 3D escape gates — five visually legible physical routes (source candidate)

The next major premium visual milestone replaces a major weak point seen in the owner's Android captures: many bare repeated elevated blocks with no obvious route hierarchy. Each of the five genuine 320-stud arenas now has **12 new full-height original 3D climb monuments** (4 real routes × ENTRY / TRANSFER / SUMMIT): tall engineered exterior supports, angled fins, overhead gantries, metal undercarriages, sparse lit directional cues and **five different original world-specific mechanical crowns**. Every 3D part is **bound to the actual server-owned collision deck**; no false platforms, hidden barriers or excess floating HUD labels. Physical gameplay and the existing green AI-stall recovery are unchanged. This is source-only pending exact-SHA Roblox Cloud + real Android verification, not a live update. [Full architecture, mobile part budget and safe-collapse checks](docs/MONUMENTAL_ESCAPE_ROUTE_ARCHITECTURE_2026-11-02.md).

## Real AI navigation and wall-stuck recovery — source milestone

Android players reported bots turning in circles, walking into machines, standing still against obstacles and jumping erratically during actual survival rounds. A source investigation identified the real bug: the AI abandoned a blocked goal and reset its failure counter **before its own physical rescue logic could fire**. This pass corrects that underlying dead path, makes each real NPC select a new **grounded, collision-tested detour on the FIRST confirmed stall**, and avoids repeating the same impossible destination for 7.5 seconds. All changes keep normal Humanoid walking, real jump physics, interactive station claims and the eight-participant round contract. Android disaster lighting now also includes the previously reviewed midtone repair [#548](https://github.com/dbrckk/chaos-survival-roblox/pull/548). No claim of physical Android success or public publication is made for the new source. [Implementation and actual gameplay acceptance](docs/PHYSICAL_AI_STALL_RECOVERY_2026-11-02.md).

## Android gameplay remediation — brighter worlds, unsticking bots, visible survival goal (source only)

The owner shared a second physical Android evidence set: gameplay is **too dark**, bots oscillate or become **stuck** in world geometry, platforms appear **too plain**, and the true win condition is hidden behind optional shard progress. A new production corrective pass targets these weaknesses rather than just decoration: daytime high-visibility lighting across ALL FIVE maps; server-owned AI forward-progress and supported-ground detours; permanent mobile "SURVIS X s" guidance in the existing round-focus strip; and three-layer solid-looking 3D engineering detail on a tier-bounded subset of physical decks. All added platform detail is noncolliding and linked to existing shrinking/collapse logic. Prior core_a Cloud assertions were outdated following visual changes and are corrected in the existing test suites, but their corrected version **still requires fresh real-engine certification**. [Evidence and exact fixes](docs/ANDROID_GAMEPLAY_CORE_REMEDIATION_2026-11-02.md). **This corrective pass was source-only at its original milestone; the subsequently verified public update is exact SHA `79e73a2a5030e9cde0adf80e6f1a8fda51959728` (run 41489124289).**

## Physical Android playtest feedback — source readability repair

On 2 November the owner tested the **actually published** Sky Spine version: 4 physical Android landscape captures display **8/8 alive** with active game hazards, large 3D platforms and bot-like participants. Those captures refer to the earlier verified public publish [run 41428449036](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41428449036), exact SHA `a3e414bea21d6dec9e0d8bed7a454c8b42415699`; a newer publication has since been verified below. These captures reveal real issues: stacked oversized world signs, overlong FLUX labels obscuring the camera, distant AI name clutter, literal `\\n` in Sky Spine signs, and overwhelming noninteractive neon. The Android mini-window on the right is **from another app**, not Roblox HUD.

The new **source-only** polish cuts world 3D sign distance, renders Sky Spine sign line breaks correctly, moves short mobile FLUX text into a left status lane, hides unnecessary distant AI labels and attenuates *decorative* neon while retaining important hazard / parkour edge cues. See [real-capture findings and regression targets](docs/ANDROID_GAMEPLAY_CAPTURE_LEGIBILITY_2026-11-02.md). **The live game still shows the old labels until this newer patch itself passes Build/Cloud verification and the manual public publication workflow.**

## New AAA-scale Sky Spine interchange — developed source candidate

Every 320×320 arena now has a **third genuinely collidable 200+ stud sky bridge** crossing PERPENDICULAR to the previous twin sky promenades. Ten permanently safe 12-stud landing decks create an H-shaped elevated parkour network with two playable junctions. Each world has an **original monumental sky fortress** (radar, cargo hoist, routing fins, orbital core or storm crane), engineered trim and navigation.

**Real environmental interaction:** from either of two elevated command machines, a human or physically present bot can hold a Roblox prompt for 0.7 s to **turn nine previously open 2.4-stud sky gaps into an ACTUAL solid continuous rescue crossing** for ALL eight participants, for the rest of that round. Before activation, the ten permanent decks remain jumpable. No temporary walkway can vanish under a running player; no extra pay-to-win or teleport. [Complete design, safety and release criteria](docs/SKY_SPINE_COOPERATIVE_INTERCHANGE_2026-11-02.md). **Code is not public until next exact-SHA Cloud/Android release certification and actual publish.**

## Public experience status

[**Play Chaos Survival on Roblox**](https://www.roblox.com/games/95351659174730/Chaos-Survival) · [Creator Dashboard](https://create.roblox.com/dashboard/creations/experiences/10771083668/overview)

The experience is **public to eligible 16+ Roblox players** under the documented creator content rating. **Latest VERIFIED public publication: 2 November 2026**, exact source SHA `79e73a2a5030e9cde0adf80e6f1a8fda51959728`, existing Universe `10771083668` / Place `95351659174730`. The [authenticated public publishing run 41489124289](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41489124289) has a successful **Publish ONLY the existing public starting place** step and exact-SHA build/engine verification. The newer `main` SHA `b9a52815e696967d871d065cb5543519362e4a98` passed [Build Validation 41494260248](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41494260248) and [Cloud engine 41494359576](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41494359576), but is **not verified as deployed to the public place**. A green source or engine check alone never establishes live publication.

**What remains uncertified:** physical Android/desktop screenshots of all five maps, 8-seat bot-spawn observation and true co-op relay usage, touch accuracy, FPS/thermals, real-player behavior, DataStore handoff/rejoin under production failures, and actual D1/D7 retention. The next source-only gameplay refinement [moves cooperative DASH stations closer to genuine first-minute routes](docs/COOP_RELAY_ROUTE_DISCOVERY_2026-11-01.md); it is not yet deployed. This is a working **public playtest** and is not a verified 9/10 or AAA visual finish. Source improvements on `main` or other branches created *after* the last published SHA do not reach the public game until another explicit, gated publication.

**Visual audit in progress (source only):** the [existing 15-frame Studio bot-view pipeline](docs/AI_VISUAL_QA_15_FRAMES.md) now supports **all five real arena variants**, rejecting lobby, wrong-arena or forged PNG manifest identity. The [Android/temporary Windows workflow](docs/AI_VISUAL_QA_REMOTE_ANDROID.md) can capture **75 real PNGs / five 15-frame reports using one authenticated Studio session** (`arena=All`), while the persistent Studio runner selects any one arena. This functionality is prepared in code **but has not produced certified screenshots**. Official signed, interactively rendered and authenticated Roblox Studio is still required; it does **not** constitute actual Android FPS certification or automatically publish the public game.

**Public page visual update (20 October 2026):** the owner shared a screenshot from the Roblox Android game page showing a **custom Chaos Survival icon now visible**. The larger experience detail-page thumbnail still displays Roblox's default placeholder. The public game-media API also returned an empty list on 20 October. **Do not re-upload or replace the working icon just to clear an outdated checklist.** A real gameplay-based 16:9 thumbnail is still needed; existing Canva graphics are promotional concepts, not native game captures. Creator's Experience Detail Page image upload requires an authenticated creator session and a local media file. Thumbnail Personalization Open Cloud concerns Home Page thumbnails, not the main icon or detail-page gallery. Avoid changing API keys to bypass access checks.

For factual verification, see the [live status record](docs/ETAT_PUBLIC_2026-10-19.md), [launch runbook](docs/MISE_EN_LIGNE_1_0.md), and [release gate issue #79](https://github.com/dbrckk/chaos-survival-roblox/issues/79).

## Active Skyline Shield Network — new genuine linked co-op corridors (source)

Players and assisting AI operate four powerful 3D storm-defense machines per world. **When two different generators are active simultaneously, they now link with a large visible 18-stud-wide safe corridor across the real arena**: original energized floor rails, overhead conductors, crossing signals, world-space team guidance, and **real HP SAVED** readouts. Human and bot survivors crossing the route receive the SAME 58% reduction in Meteor/Bomb damage as the local fields. The link expires as soon as EITHER generator shuts off; no extra invulnerability or paid bonus and no protection against other hazards. This adds a genuinely coordinated movement choice for eight participant rounds without affecting the 52-deck sky parkour. **Source-only until same-SHA Build/Cloud/Studio/Android verification and authorized public Roblox update.** [Mechanics, safety and release acceptance](docs/LINKED_STORM_SHIELD_CORRIDORS_2026-11-02.md).

## Real co-op environment control — four active storm shields per arena

Players can operate **four monumental emergency defense generators** during Meteor/Bomb rounds in every world. A server-owned control creates a readable **48-stud-diameter protective cylinder** marked by eight distinct perimeter sections for **8 seconds**, protecting humans and simulated survivors from **58% of real explosive damage**, followed by **21 seconds** recharge. **AI survivors now also approach, hold and activate the SAME physical controls** when an actual human teammate can benefit, and must abandon the action to survive imminent hazards. Successful protection visibly displays REAL **HP SAVED** and an impact ripple; the field shuts off immediately when shrinking terrain leaves its station unsupported. There is no shield from other hazards, hidden invulnerability or pay-to-win reward. This is **source only**, with Cloud/Studio/Android verification and public Roblox publication still pending on the updated SHA. [Current complete gameplay & release contract](docs/REAL_COOPERATIVE_SKY_SHIELD_2026-11-02.md).

## Critical gameplay-fairness repair — source candidate

The two end-to-end sky promenades per arena must never become isolated because the *approach* collapses while the actual skybridge remains intact. All physical perimeter steps 1–5 and branch steps 1–4 now join the same **server-owned collapse-resistant backbone** as the 16 elevated crossing decks. This is protection from **random Disappearing Platforms only**, not immunity from meteors/lava or Shrinking Arena. Flat 2.4-stud gaps now have visible two-way chevrons on every real deck, since the old ascent-only jump hints do not apply to these level crossings. Existing engine-contract checks were updated. A one-time source-only release gate is configured to dispatch build, then Roblox engine checks, without publishing. Their **actual green results, physical Studio/Android verification and the public Roblox update are still pending**. [Verified source geometry and final release acceptance](docs/RELEASE_GATE_ROUTE_CONTINUITY_2026-11-01.md).

## Catastrophe-driven, destructible monumental skyline — source only

Actual Meteor/Bomb impacts and prolonged Tornado/Lava disasters now trigger **large staged 3D collapses** of the six monumental sky-promenade gateways in each of the five playable arenas. Existing native radar structures, maintenance lifts, transit switches, orbital reactors and Harbor freight machinery fracture, tilt and fall in synchronized **server-owned geometry**, with temporary quality-tiered debris and dust. The playable platforms remain real safe colliders; no new unsignaled danger or bogus world physics. This code is **not yet published or validated on Roblox devices**. [Structural Cataclysm architecture, fairness and acceptance](docs/STRUCTURAL_CATACLYSM_PREMIUM_2026-11-01.md).

## Major physical 3D world expansion — source only, not yet published

Five arenas now have a new **genuine high-altitude traversal loop**: each has two approximately 200-stud airborne sky promenades connecting existing distant physical lookouts. Sixteen new server-collidable, standard-R15-jumpable decks per map (80 authored among the five variants) create actual strategic route choices rather than background scenery. Six sculpted 3D structural portals per arena visually frame the walkways, with unique machinery for Classic/Towers/Crossroads/Orbital/Harbor. They have no blocking decorative collision; original spawn/hazard/AI systems continue to use the real `Arena/Platforms` parts. [Real geometry, deterministic route offsets and release acceptance](docs/MONUMENTAL_SKY_PROMENADES_2026-11-01.md). Source-only until a complete same-SHA Roblox engine/Studio/Android gate and explicit public publication.

## Colossal visual transformation — new source, not yet published

The upcoming major art update gives **all five arenas a unique fleet of enormous, moving 3D aerial machines**, with authored mechanical silhouettes and reactions to the real hazards. Unlike an image background, the airborne carriers, cargo gantries, rotating arrays, suspended lifts and reactor arcs are native 3D parts visible from the actual player camera. Low/Medium/High tier budgets and the existing distance LOD protect Android, while ReduceMotion restores static poses. [Scope, art direction and exact milestone acceptance](docs/COLOSSAL_SKYFLEET_PREMIUM_2026-11-01.md). This artwork is on the current repository source only until a future exact-SHA test and public publish; its appearance and FPS have **not** yet been validated on devices.

## Original 3D assets — no-PC Android upload option

**Runtime integration in the published code:** `src/server/OriginalMeshScenery.lua` now attempts **six** approved creator-owned Roblox Model packages in two bounded loading lanes, validates their contents and may place up to **eight** cosmetic skyline models beyond the playable perimeter. Native, noncolliding fallback scenery remains when a package cannot load; Android Low hides external models through the existing LOD. Whether all eight assets actually load and render on a particular client **has not been verified by real Studio/Android captures**. See [the integration guide](docs/ORIGINAL_3D_RUNTIME_INTEGRATION.md).

**Approved creator-owned Roblox assets (24 October 2026):** Reactor Spire `102992487644269`, Service Crane `119468460691888`, and Perimeter Gate `137284215564363`. Ownership, OBJ provenance, moderation and exact successful GitHub Actions run IDs are recorded in [the verified 3D asset registry](assets/source/roblox-asset-registry.json). All three are Roblox **Model packages** owned by `Drackk_08` (user ID `9774173158`). These model package IDs are **not** MeshPart.MeshId values. The current source dynamically **attempts** to mount approved packages into the live arena (with validation and fallback); successful loading and quality still need authenticated client evidence. Gameplay collision-safe native map structures remain authoritative.

The original Reactor Spire, Service Crane and Perimeter Gate OBJ/MTL sources live under `assets/source/`. The opt-in [Android 3D Open Cloud guide](docs/ANDROID_3D_CLOUD_IMPORT.md) describes a dedicated GitHub Actions workflow that validates and exports all three as embedded glTF 2.0. A **dry-run needs no Roblox key or creator ID**. Actual creation of a creator-owned Roblox `Model` requires a separate `ROBLOX_ASSET_API_KEY`, the correct creator ID and exact confirmation. **Generating or uploading a Model asset does not install it in the playable world;** integration needs a real approved Roblox asset ID, a separate staging review and Android visual QA.

**Automatic preview without any Roblox credentials:** every successful `main` **Build Validation** now archives `chaos-survival-3d-previews` alongside the playable place candidate. This artifact contains the three original glTF models and a `manifest.json` with source commit, byte sizes, triangle counts and SHA-256 checksums. Download it from the successful GitHub Actions run's **Artifacts** section on Android. This is **not** a Roblox upload or in-game integration.

**Android-only private staging:** use the manual-only [Remote Roblox Studio workflow](.github/workflows/roblox-remote-studio.yml) on `main` to prepare a signed official Windows Studio session and create a **new private test experience**, not another Place in the public universe. See the [Android private-staging guide](docs/ANDROID_PRIVATE_STAGING_REMOTE.md) for the minimum Android actions and the target-isolation rules. This does not publish the game automatically or certify gameplay.

## Implemented

- Runtime-generated lobby and arena
- Server-authoritative round loop
- 11 modular disasters
- 3-choice disaster voting
- Double Chaos combinations
- Coins, XP, levels, wins and games played
- DataStore persistence
- Mobile-friendly HUD
- Daily login rewards and streaks
- Daily quests with persistent progress and automatic rewards
- Server-side vote rate limiting
- Persistent cosmetic inventory with level unlocks
- Coin-funded cosmetic shop with server-authoritative purchases
- 25-item cosmetic catalogue with rarity tiers, four arena-mastery GOLD rewards, Founder cosmetics and Hyper Neon cosmetics
- Independent persistent trail + aura loadout slots with automatic migration from legacy saves
- Server-authoritative cosmetic equipment with combinable trails, auras, lighting and highlights
- Persistent long-term achievements with server-side rewards
- Persistent disaster + arena mastery with Rookie/Bronze/Silver/Gold/Elite tiers
- Weekly challenges, collection log and visible post-round next-goal progression
- Mobile achievements progress panel and unlock notifications
- Solo Rush mode with faster rounds, solo reward bonus, instant round end on elimination and AI Survivors that fill sparse servers
- Elimination tracking that prevents respawns from being counted as survival
- Server-side retention and gameplay analytics segmented by Solo/Multiplayer
- Economy analytics for Coins sources, daily rewards, quests and achievements
- Onboarding funnel tracking from join to first survival and first Chaos Shard pickup
- Contextual first-session coach covering vote, positioning, survival and optional shard collection
- 5 rotating arena layouts with no immediate repeat: Classic Grid, Tower Run, Crossroads, Orbital Ring and Storm Harbor
- After the October 30 feedback pass (pending release): the parkour waypoint will guide players from Orbital's low central hub back toward a real outer access ramp, place signs at the physical takeoff of long ramps, and defer to the actually visible cargo hint rather than hiding merely because a cargo shard is nearby. A server-confirmed route-tier landing will have a quiet existing reward chime and a brief tint in the existing mobile challenge bar, without extra client loops, currency or network events.
- Arena-specific high-ground mastery challenges on experienced rounds: Radar Ridge, Tower Summit, Crossroads Overpass, Reactor Lookout (tier 4) or Storm Gantry Lookout. The server verifies two consecutive stable landings on a real route platform; the existing round challenge awards capped Coins/XP without new client claims, loops or remote events.
- Mobile-first final result receipt shows the exact server-confirmed challenge bonus or the remaining arena mastery points toward the next rank. Pending receipts, spectators and unavailable rewards never display invented currency. The same result card remains available, preserving elimination tips and next-round countdown.
- Pending October 30 mobile hazard readability: Storm Harbor Cargo Sweep joins the existing meteor/bomb/JumpShock ACTION cue (no second warning overlay or loop). The server replicates each wave's authentic warning/pulse timestamps and durations; the client checks only the genuine four crane lanes and its own low-floor position before displaying a short FR/EN jump-or-exit instruction plus two locally rendered, non-collidable escape chevrons. Lethal impacts/shock always keep the foreground priority, raised parkour routes are correctly exempt, ReduceMotion fixes the visual pulse and adaptive Android quality limits geometry. This source branch is not yet published.
- Storm Harbor advanced cargo sweep: four alternating, server-owned crane-service lanes; 2.6-second orange warning, short red pulse and capped nonlethal push **toward the centre**, avoided by jumping or climbing above floor level. All rookie and incompatible-hazard rounds stay exempt. AI survivors now use the existing human-like delayed floor-sweep evasion behavior rather than ignoring the warning; nearby human runners receive one quiet local warning sound per real wave through the existing RoundState heartbeat. No extra client animation loop, network event or imported asset.
- Variant-specific hero landmarks, midground masses, understructures, focal lighting, material language and functional service props
- Animated personal round-result feedback with survival, streak, shard and close-call breakdown
- Compact live round-focus HUD with Chaos intensity and shard count
- Final-five-second danger timer feedback
- Server-side reward handling
- Per-disaster visual identities with Double Chaos color blending
- Progressive round-intensity director with solo/Double Chaos safety caps
- Veteran-only evolving Meteor/Bomb storm routes: scattered impacts → advancing sweep → alternating crossfire, with existing fair warning radii, mobile-stage labels and shrink-aware fallback
- Hazard cadence, arena VFX and audio mix react to escalating round intensity
- Dynamic neon arena beacon reacting to active chaos
- Procedural premium lobby hub with neon gate and title signage
- Premium procedural arena treatment with metal spawn pads, neon platform underglow and edge beacons
- Adaptive client-side world polish that rebuilds correctly across arena swaps and scales down on weaker devices
- Responsive body/camera game feel with landing, impact, launch, turn/brake feedback, READY anticipation, coyote time and jump buffering
- Live multiplayer vote counts and leading-choice highlight
- Mobile spectator mode after elimination with live survivor/time context, stable survivor switching and low-allocation hazard glyphs
- Chaos Shards: optional server-authoritative risk/reward pickups with daily-quest integration
- Close-call / near-miss feedback with per-round tracking
- Critical-health clutch-survival feedback and analytics
- XP progress bar and level-up celebration
- Session survival streaks with capped coin bonuses
- First-session onboarding banner
- Reactive music and SFX with a distinct audio cue for every disaster
- Map-specific 3D ambience plus material-aware local footsteps and landing treatment
- Automatic countdown, victory, elimination, reward, level-up and UI sounds
- Real-engine gameplay matrix: every arena × every disaster + every allowed Double Chaos pair
- Four-client Studio E2E harness with virtual UI clicks, movement, voting, joins and leaves
- AI Survivor animation state blending (idle/walk/run/jump/fall) and map-aware/hazard-aware navigation
- 77 engine specs assigned exactly once across Open Cloud CI shards
- **Published premium-platformer gameplay:** progressive physical route widths, server-verified airborne parkour mastery medals/records, daily/weekly mastery goals and veteran Tower Run's real timed rising bridge shutters alternating with collapsing bridge challenges. Both use authentic warnings, obstacle collision and fair Skyrail/AI safeguards. This gameplay is present in the latest verified public release described above; [the full premium quality benchmark and remaining acceptance plan](docs/PREMIUM_BENCHMARK_AND_COMPLETION_PLAN_2026-10-30.md) still require actual Android/PC certification.
- No paid assets required

## Current disasters

1. Rising Lava
2. Meteor Shower
3. Moon Gravity
4. Disappearing Platforms
5. Tornado
6. Freeze Pulse
7. Bomb Rain
8. Speed Surge
9. Blackout
10. Shrinking Arena
11. Jump Shock

## Run locally

1. Install Roblox Studio.
2. Install Rojo.
3. Clone this repository.
4. Run `rojo serve` from the repository root.
5. In Roblox Studio, connect the Rojo plugin to `localhost:34872`.
6. Press **Play**.

For DataStore tests in Studio, use a test experience and enable:

**Game Settings → Security → Enable Studio Access to API Services**

## Release candidate

- Final certification checklist: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
- Authenticated Studio/device report template: [studio/PLAYTEST_REPORT_TEMPLATE.md](studio/PLAYTEST_REPORT_TEMPLATE.md)
- Change history: [CHANGELOG.md](CHANGELOG.md)
- Rollback procedure: [ROLLBACK_RUNBOOK.md](ROLLBACK_RUNBOOK.md)
- French public launch runbook: [docs/MISE_EN_LIGNE_1_0.md](docs/MISE_EN_LIGNE_1_0.md)
- Reviewed bilingual launch-copy draft: [docs/FICHE_ROBLOX_1_0.md](docs/FICHE_ROBLOX_1_0.md)
- Successful Build Validation provides a non-published `.rbxlx` candidate, SHA-256 checksum and exact-commit provenance in the `chaos-survival-place` GitHub Actions artifact. This is a test package, **not** Roblox release certification.
- Manual **Release Candidate Gate** workflow: verifies Build Validation + Open Cloud on the exact SHA and emits a release-evidence artifact without publishing.
- Roblox publication workflow refuses uncertified SHAs and archives publish metadata.

## Product direction

Automated Roblox-engine coverage validates the core gameplay matrix on every push. The project is in release-candidate hardening: the remaining launch gates are an authenticated Studio visual/touch pass, Android + desktop soak/performance validation, persistence/rejoin validation, a small real-player alpha, and final public-page assets.

Monetization infrastructure is now present but remains opt-in and cosmetic-only. Paid offers stay hidden until real Roblox Game Pass IDs are configured as DataModel attributes named `SupporterPassId` and `NeonPackPassId`. The paid service never modifies survival power, movement, health, round rewards or progression rates.

Recommended launch pricing is intentionally low-friction (for example 39–79 Robux per cosmetic/supporter pass), but the live price is always read from Roblox MarketplaceService rather than hard-coded in the client. Final prices should be set in Creator Dashboard only after the authenticated device playtest is clean.

## Architecture

```
src/
├── client/
├── server/
│   ├── Disasters/
│   ├── MapBuilder.lua
│   ├── PlayerData.lua
│   └── init.server.lua
└── shared/
    └── Config.lua
```


## Tests uniquement avant une étape importante / milestone-only validation

**Règle générale du développement : aucun test automatique pendant la phase
d'amélioration.** Cela inclut les PR, les commits sur les branches et les
commits ordinaires sur `main`. Les workflows de vérification lourde sont
**manuels** : ni `push` ni `pull_request` ne lancent des tests.

À un jalon réellement important, notamment juste avant de mettre à jour le
jeu public, déclencher depuis `main`, sur **le même commit exact** :

1. `Build Validation` — audit du code, sécurité, ressources, performances
   Android, Rojo, intégrité et provenance de l'archive ;
2. `Roblox Open Cloud Engine Tests` — les cinq suites réelles complètes ;
3. publier seulement si les deux sont vertes pour ce commit sur `main`,
   avec une validation explicite du propriétaire.

Le workflow de publication publique conserve les protections d'identité
d'univers/place, d'exactitude du commit, de non-régression de branche et
l'avertissement sur les tests Android/PC physiques non certifiés.
Aucun test non exécuté ne doit être présenté comme validé.

## Automated playtesting

The default CI uses Roblox Open Cloud Engine Tests and currently covers all arena/disaster combinations plus every allowed Double Chaos pair in a real Roblox DataModel.

A separate four-client Studio E2E harness is included under `studio/`. It automates UI clicks, voting, movement, staggered joins and client leave behavior using StudioTestService and VirtualInput. Roblox Studio requires a logged-in user session, so the GitHub Studio workflow is manual and targets an authenticated self-hosted Windows runner.

## Integrated visual and locomotion candidate (2026-10-08)

This **unreleased candidate** reconciles PRs #12–#16 with the already merged spectator fix (#11) and Open Cloud retry hardening (#17):

- Chaos Showtime: six R6/R15 emotes, a holographic dance floor, DJ architecture, a neon crown and accessible narrow-screen mobile controls.
- Five distinct arena identities: Classic radar, Towers maintenance elevator, Crossroads transit signage, Orbital gyroscope, and Storm Harbor drydock ship with four original distant port cranes.
- Unique meteor and bomb impact fragments, included in visual performance telemetry.
- Event-driven blast/near-miss/landing reactions on eligible living players and AI bots; spectator/lobby avatars excluded.
- R15 sprint starts, stop skids, sharp pivots, foot planting, takeoff and fall bracing with transient floor cues.

All added content is cosmetic only. No speed, jump, damage, server authority, physics, or monetization changes. Full Studio and real Android performance/gameplay playtests remain required before release.

- Late map-replication resilience: lobby floor and arena base visual builders now watch nested map parts and arena identity attributes instead of relying on container arrival order.

- Cosmetic hazard-impact events also reach spectating clients; visible bursts are filtered by spectator camera range, while movement/body feedback remains disabled for nonparticipants.
