# Chaos Survival — Release Candidate Certification

This checklist defines the minimum evidence required before calling the experience release-ready.

## Automated gate

All items below must be green on the exact release commit:

- [ ] Build Validation succeeds.
- [ ] Roblox Open Cloud Engine Tests succeed.
- [ ] Every engine spec is assigned to exactly one Open Cloud shard.
- [ ] Rojo produces a non-empty place file.
- [ ] Luau syntax validation succeeds.
- [ ] Fair-play monetization guard succeeds.
- [ ] Client/server protocol guards succeed.
- [ ] Server service export contract audit succeeds.
- [ ] Production source contains no TODO/FIXME/HACK markers or obvious placeholder IDs.

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
- [ ] No placeholder production IDs or temporary debug code remain.
- [ ] Create release candidate tag.
- [ ] Write changelog.
- [ ] Keep last known-good commit/tag for rollback.
- [ ] Verify Roblox experience icon, thumbnails, description and screenshots.
- [ ] Run a final smoke test immediately after publication.

## Definition of done

Chaos Survival 1.0 is ready only when automated CI, authenticated Studio E2E, physical-device UX/performance, persistence/rejoin and public-alpha gates have all passed on the same release lineage.
