# Changelog

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

