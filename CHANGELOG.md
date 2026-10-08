# Changelog

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

## 2026-10-08 — Chaos Showtime (new social visuals and emotes)

- Add a procedural neon dance floor with crowd-reactive tiles, emote-triggered radial floor waves, a rotating prismatic crown (device-tier-controlled), holographic ribbons, three cycling dancer motifs, a DJ booth/turntables, twin 3D speaker stacks, truss, equalizer, pylons and personal celebration confetti.
- Add six opt-in Roblox-native R6/R15 emotes: dance, shuffle, groove, cheer, wave and laugh, available in calm phases on mobile and desktop (G).
- Avatar animation playback uses the replicated player Animator and is interrupted on movement, jumping, death or active round.
- Reduce Motion freezes decorative choreography; Low/Medium/High VFX profiles bound local geometry, lights, particles and update rate. Add subtle, proximity-limited stage beat and personal emote cues respecting AudioMuted. Winning players get one automatic, motion-accessible victory cheer on result transition.
- Add a Roblox Open Cloud engine spec with regression tests for six emotes, accessibility, safe prop construction, tier budgets, mute/proximity rules and one-off winner celebrations; CI registration and visual-budget folder audit.
- This addition is cosmetic only: no changes to survival, movement, upgrades, game currency or rewards.

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

