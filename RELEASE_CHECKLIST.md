# Chaos Survival — Release Candidate Certification

This checklist defines the minimum evidence required before calling the experience release-ready.

## Automated gate

All items below must be green on the exact release commit:

- [x] Build Validation succeeds.
- [x] Roblox Open Cloud Engine Tests succeed.
- [x] Every engine spec is assigned to exactly one Open Cloud shard.
- [x] Rojo produces a non-empty place file.
- [x] Luau syntax validation succeeds.
- [x] Fair-play monetization guard succeeds.
- [x] Client/server protocol guards succeed.
- [x] Server service export contract audit succeeds.
- [x] Production source contains no TODO/FIXME/HACK markers or obvious placeholder IDs.

Automated gate certified on commit `2bb9038ca78d9e77599cf49a0ef096b92bfa83ac` on 2026-10-05. Both **Build Validation** and **Roblox Open Cloud Engine Tests** completed successfully on that exact commit. The production-source placeholder scan is also clean.

> Any commit after this certification must re-run both automated workflows before a release tag is cut.

Evidence for the automated gate: commit `2bb9038ca78d9e77599cf49a0ef096b92bfa83ac` passed Build Validation run #1391 and Roblox Open Cloud Engine Tests run #1390 on 2026-10-05.

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

- [ ] Generated lobby appears correctly.
- [ ] All 4 arena variants can be entered.
- [ ] Critical HUD elements remain within viewport bounds.
- [ ] Touch targets meet the E2E minimum size.
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
- [ ] Arena swaps do not cause unacceptable freezes.
- [ ] Bomb Rain + another disaster remains playable.
- [ ] Meteor Shower + another disaster remains playable.
- [ ] Device temperature and battery use remain reasonable for Roblox gameplay.
- [ ] Memory remains stable enough for a long session.

## Data persistence gate

Use the production/test experience with API Services enabled.

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

- [ ] README matches current feature/map count.
- [ ] Roadmap reflects remaining launch blockers.
- [x] No placeholder production IDs or temporary debug code remain.
- [ ] Create release candidate tag.
- [ ] Write changelog.
- [ ] Keep last known-good commit/tag for rollback.
- [ ] Verify Roblox experience icon, thumbnails, description and screenshots.
- [ ] Run a final smoke test immediately after publication.

## Definition of done

Chaos Survival 1.0 is ready only when automated CI, authenticated Studio E2E, physical-device UX/performance, persistence/rejoin and public-alpha gates have all passed on the same release lineage.


## AAA specialist review gate

- [ ] Current specialist audit updated for the exact release lineage.
- [ ] No department score below 8/10.
- [ ] Gameplay, Game Feel, UX, Visual, Audio, Performance and QA are >=9/10 or have an explicit evidence-backed exception.
- [ ] Every remaining low-confidence score has been resolved with device/playtest/profile evidence.
- [ ] Authored asset/license manifest is complete.
- [ ] Physical device certification protocol completed.
- [ ] Public alpha/player research protocol completed.
- [ ] Final harmonization pass completed.
- [ ] Final subtraction review completed.
- [ ] No duplicated major system remains.
- [ ] Perfect-Candidate decision recorded before RC tag.
