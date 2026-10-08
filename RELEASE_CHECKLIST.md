# Chaos Survival — Release Candidate Certification

This checklist defines the minimum evidence required before calling the experience release-ready.

## Automated gate

All items below must be green on the **exact release commit**. The checkboxes describe the gate definition; they do not certify the current HEAD by themselves.

- [ ] Build Validation succeeds on release SHA.
- [ ] Roblox Open Cloud Engine Tests succeed on release SHA.
- [ ] Every engine spec is assigned to exactly one Open Cloud shard (currently 67 specs).
- [ ] Rojo produces a non-empty place file.
- [ ] Luau syntax validation succeeds.
- [ ] Fair-play monetization guard succeeds.
- [ ] Client/server protocol guards succeed.
- [ ] Server service export contract audit succeeds.
- [ ] Persistent visual-layer registry coverage succeeds (all visual `*Local` folders budgeted; explicit non-visual exceptions only).
- [ ] Client map-listener lifecycle ownership audit succeeds.
- [ ] Scenery LOD registry/weak-cache guard succeeds.
- [ ] Single client Clouds owner guard succeeds.
- [ ] Production source contains no TODO/FIXME/HACK markers or obvious placeholder IDs.

Latest historical full automated certification: commit `70681aabc40c493467ffbc13ca0078b63eb90f56` on 2026-10-06 (Build Validation run `37454113205` + Roblox Open Cloud Engine Tests run `37454113207`). Both completed successfully on the exact SHA. This is historical evidence only and does **not** certify later commits.

> Every candidate SHA must re-run both automated workflows. A later code/doc commit invalidates the automated certification until the new exact SHA is green.

Use the manual **Release Candidate Gate** workflow only after Build Validation, Open Cloud **and the authenticated Studio E2E workflow** are green on the exact candidate SHA, and all remaining manual gates have actually passed. The workflow verifies the exact-SHA Studio run automatically **and downloads its `roblox-studio-e2e` artifact to validate the PASS manifest against the same commit/run** before certification. It requires `CERTIFY` plus explicit `PASS` attestations for Android, desktop, persistence, gameplay/fairness, accessibility, public alpha and final store/page assets. It checks release metadata consistency and uploads a `release-evidence.md` artifact. This gate never publishes the Roblox place.

### CI infrastructure failures

Classify failures before changing production code:

- **CODE/TEST FAILURE:** a spec assertion, compile/build guard, protocol guard, or deterministic validation fails -> investigate/fix code.
- **INFRA FAILURE:** Roblox Open Cloud remains PROCESSING past deadline, returns HTTP 429/5xx, or runner infrastructure stops after otherwise passing specs -> preserve the evidence, retry, and do not mislabel it as a gameplay regression.
- A timeout/429 is still a red gate until a retry succeeds on the release lineage; it is never silently treated as PASS.
- Record passed test counts, failed shard, workflow/run number and exact SHA.

## Current published candidate

- Published commit: `35123d31672acbd5b7ec6e385a1020007db4eb4b`
- Build Validation: PASS (run #1396)
- Roblox Open Cloud Engine Tests: PASS (run #1395)
- Roblox place publication: PASS (Publish Roblox Place run #7)
- Universe: `8998396328`
- Place: `101933452561772`
- Remaining release evidence: authenticated Studio E2E, physical Android/desktop device checks, persistence/rejoin checks, then small public alpha.

## Authenticated Roblox Studio gate

Run the four-client Chaos E2E harness from an authenticated Studio session.

Before certification:
- [ ] Run `powershell -ExecutionPolicy Bypass -File .\studio\self-hosted-runner-preflight.ps1` under the same Windows user that will run the GitHub Actions runner.
- [ ] Preflight exits 0: official signed Studio found, current Windows user authenticated, and no incompatible system-account runner service detected.
- [ ] GitHub self-hosted runner is online with `self-hosted` + `windows` labels under that same user context.

Then validate the game:
- [ ] Generated lobby appears correctly.
- [ ] All 4 arena variants can be entered — Studio E2E must observe Classic, Towers, Crossroads and Orbital, with RoundState arenaId matching GeneratedMap.Arena.VariantId and a READY entry probe confirming a live character inside Arena.Base footprint.
- [ ] Critical HUD elements remain within viewport bounds.
- [ ] Touch targets meet the E2E minimum size.
- [ ] READY visual phase probe passes tier budget + FOV bounds.
- [ ] ROUND visual phase probe passes tier budget + FOV bounds on Classic, Towers, Crossroads and Orbital.
- [ ] RESULT visual phase probe passes tier budget + FOV bounds.
- [ ] `CHAOS_E2E_VISUAL_PHASE` logs include tier, parts, lights, effects, FOV and audited-folder count.
- [ ] Quest, Cosmetics and Achievements panels remain mutually exclusive.
- [ ] Disaster vote accepts real virtual input.
- [ ] Movement works through virtual input.
- [ ] Staggered joins receive current round state.
- [ ] Client leave is cleaned server-side.
- [ ] Spectator mode activates correctly after elimination.
- [ ] No blocking errors appear in server/client output.

Record:
- release commit SHA
- Studio version
- date
- PASS/FAIL
- screenshots/log excerpts for any failure

## Unified visual candidate acceptance (#12–#16)

- [ ] Build Validation and Roblox Open Cloud Engine Tests both pass on the exact candidate SHA (67 uniquely assigned engine specs).
- [ ] Studio confirms a full ordered intermission > ready > round > result journey on a single client, without double-counting repeated states.
- [ ] Authenticated Studio E2E checks Showtime 3D stage identity, static part safety and hidden ROUND / visible RESULT transitions.
- [ ] Studio confirms six R6/R15 emotes and no conflict with Settings or locomotion.
- [ ] Android 320/360/400/440px viewport checks: emote dock stays on screen and accessibility Settings remains operable.
- [ ] The four arena probes confirm each distinct hero monument is present, has 6–50 anchored non-colliding parts and logs its identity/part count during Studio E2E.
- [ ] All four map landmarks render and rotate safely, remain non-colliding and clean up across arena transitions.
- [ ] Meteor/Bomb bursts render as different fragments, including all transient pieces in live budget metrics.
- [ ] Near-miss and landing FX affect eligible living participants and AI only; late joiners, spectators and eliminated lobby avatars excluded.
- [ ] R15 sprint/hard stop/180-degree pivot/jump/land + respawn produce no frozen body pose or broken movement.
- [ ] Performance + hazards during Double Chaos remain readable on a real Android device at Low/Medium/High VFX tiers.
- [ ] Reduce Motion suppresses cosmetic pulses and pose intensity while maintaining critical hazard readability.

## Physical device gate

Test at minimum one Android phone and one desktop client.

### Mobile UX

- [ ] Lobby, vote, ready, round, result and spectator HUD are readable.
- [ ] Roblox touch controls do not cover critical buttons/text.
- [ ] Vote, shop, quests and achievements work with touch only.
- [ ] No accidental double taps or missed critical actions.
- [ ] Small-screen text remains legible.
- [ ] Blackout remains playable.
- [ ] Freeze, Bomb, Meteor and Jump Shock warnings remain readable during Double Chaos.
- [ ] Low VFX mode remains visually clear.
- [ ] Crew Signal and Last Chaos board do not overlap critical lobby UI or Roblox touch controls.
- [ ] Friend invite CTA appears only after a completed round and opens the native Roblox invite prompt.
- [ ] Invite CTA stays hidden during vote, READY and ROUND.
- [ ] Joining from a crew invite is recognized without changing gameplay rewards or spawn fairness.
- [ ] Friend-arrival feedback waits for a calm phase if the invitee joins during active gameplay.
- [ ] Multiplayer result reactions are touch-friendly, limited to one per player per result, and never appear during ROUND.
- [ ] Adaptive bloom improves presentation without softening hazard warnings during active rounds.

### Performance

Run at least 30 minutes continuously.

- [ ] No progressive FPS degradation.
- [ ] No visible instance/particle accumulation.
- [ ] PerformancePulse visual counts (parts/lights/effects) do not trend upward without a phase/map reason.
- [ ] PerformancePulse budget status remains OK for the settled VFX tier.
- [ ] VFX tier transitions stabilize instead of oscillating throughout the soak.
- [ ] Arena swaps do not cause unacceptable freezes.
- [ ] Bomb Rain + another disaster remains playable.
- [ ] Meteor Shower + another disaster remains playable.
- [ ] Device temperature and battery use remain reasonable for Roblox gameplay.
- [ ] Memory remains stable enough for a long session.
- [ ] ClientMemoryPulse does not show sustained memory or instance-count growth without a map/phase reason.
- [ ] FrameMs / render CPU / render GPU snapshots remain consistent with the settled VFX tier.

## Data persistence gate

Automated evidence already required by CI / engine tests:

- [x] Session takeover rejects stale saves and stale releases.
- [x] Rapid handoff can save/release under the new owner and be claimed again.
- [x] Cosmetic purchases, equipment and premium grants require `PlayerData.canMutate()`.
- [x] CI rejects persistent purchase/grant paths that lose the active-session guard.

Manual evidence is still required with the production/test experience and API Services enabled.

- [ ] Coins survive quit/rejoin.
- [ ] XP/Level survive quit/rejoin.
- [ ] Wins/Games survive quit/rejoin.
- [ ] Daily reward survives quit/rejoin.
- [ ] Quest completion survives quit/rejoin.
- [ ] Achievement unlock survives quit/rejoin.
- [ ] Cosmetic purchase/equip survives quit/rejoin.
- [ ] Rapid rejoin does not lose the final previous-session rewards.
- [ ] Server transfer / quick second session does not allow stale overwrite.
- [ ] DataStore failure produces a temporary-session warning and blocks persistent purchases.
- [ ] Server shutdown completes saves without blocking beyond the configured deadline.

## Gameplay/fairness gate

- [ ] Every one of the 11 disasters is readable before it becomes dangerous.
- [ ] Every disaster can clean up without contaminating the next round.
- [ ] All allowed Double Chaos combinations remain understandable.
- [ ] Solo Rush is enjoyable and not substantially harsher than multiplayer.
- [ ] A single player can finish a complete session loop without waiting on nonexistent teammates.
- [ ] No map offers unintended permanent safe spots for Rising Lava, Shrinking Arena, Bomb Rain or Meteor Shower.
- [ ] Warnings visually match the real server-authoritative danger zones.

## Audio / accessibility gate

- [ ] Important hazards remain understandable with audio muted.
- [ ] Music never masks hazard cues.
- [ ] Victory/elimination/result cues are distinct.
- [ ] No essential instruction relies only on color.
- [ ] Camera/VFX do not become excessively fatiguing over a 30-minute session.
- [ ] Haptics do not trigger excessively.
- [ ] Haptics can be disabled independently of ReduceMotion and stop immediately.
- [ ] Motion, audio and haptics accessibility preferences survive quit/rejoin.

## Public alpha gate

Before enabling paid offers:

- [ ] Run a small real-player alpha.
- [ ] Review join → first round → first survival → second round → 10-minute funnel.
- [ ] Review solo vs multiplayer completion/survival metrics.
- [ ] Review retention and common quit points.
- [ ] Fix blocking UX/balance issues found in the alpha.
- [ ] Re-run Studio + physical device gates on the final fixes.

## Monetization gate

Only after retention/device UX are acceptable:

- [ ] Configure real SupporterPassId.
- [ ] Configure real NeonPackPassId.
- [ ] Confirm current prices in Creator Dashboard.
- [ ] Verify prompt → purchase → grant → save → rejoin.
- [ ] Verify already-owned passes restore their cosmetics.
- [ ] Verify paid products remain cosmetic-only.
- [ ] Re-run fair-play CI guard.

## Release packaging

- [x] README source counts are CI-enforced for disasters, arenas, cosmetics and engine specs.
- [ ] Roadmap reflects remaining launch blockers.
- [x] No placeholder production IDs or temporary debug code remain.
- [ ] Run authenticated Studio E2E on the exact candidate SHA.
- [ ] Run Release Candidate Gate on that same SHA and archive its evidence artifact.
- [ ] Create release candidate tag.
- [ ] Write changelog.
- [x] Keep a documented rollback path via `ROLLBACK_RUNBOOK.md`; select and record the last known-good certified SHA before release.
- [ ] Verify Roblox experience icon, thumbnails, description and screenshots.
- [x] Publish Roblox Place workflow refuses uncertified SHAs unless exact-SHA Build Validation + Open Cloud + Release Candidate Gate are green.
- [ ] Archive the publish artifact containing place file + publish-metadata.txt.
- [ ] Run a final smoke test immediately after publication.

## Definition of done

Chaos Survival 1.0 is ready only when automated CI, authenticated Studio E2E, physical-device UX/performance, persistence/rejoin and public-alpha gates have all passed on the same release lineage.
