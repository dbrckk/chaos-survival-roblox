# Changelog

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

