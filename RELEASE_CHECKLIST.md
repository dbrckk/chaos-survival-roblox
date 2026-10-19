# Chaos Survival — Release Candidate Certification

This checklist defines the minimum evidence required before calling the experience release-ready.

## Automated gate

All items below must be green on the **exact release commit**. The checkboxes describe the gate definition; they do not certify the current HEAD by themselves.

- [ ] Build Validation succeeds on release SHA.
- [ ] Roblox Open Cloud Engine Tests succeed on release SHA.
- [ ] Every engine spec is assigned to exactly one Open Cloud shard (currently 73 specs).
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

Latest verified pre-release automated baseline: commit `43237198b610c0514ba5ae6c3cf09cea46b57f82` on 2026-10-19 ([Build Validation run 39240966371](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/39240966371) + [all-five Roblox engine run 39240966382](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/39240966382)). Both completed successfully on that exact SHA. This is **historical CI evidence only**; any new source or documentation commit requires its own exact-SHA checks and it is **not** Studio/device/publication certification.

> Every candidate SHA must re-run both automated workflows. A later code/doc commit invalidates the automated certification until the new exact SHA is green.

Use the manual **Release Candidate Gate** workflow only after Build Validation, Open Cloud **and the authenticated Studio E2E workflow** are green on the exact candidate SHA, and all remaining manual gates have actually passed. The workflow verifies the exact-SHA Studio run automatically **and downloads its `roblox-studio-e2e` artifact to validate the PASS manifest against the same commit/run** before certification. It requires `CERTIFY` plus explicit `PASS` attestations for Android, desktop, persistence, gameplay/fairness, accessibility, public alpha and final store/page assets. It checks release metadata consistency and uploads a `release-evidence.md` artifact. This gate never publishes the Roblox place.

### CI infrastructure failures

Classify failures before changing production code:

- **CODE/TEST FAILURE:** a spec assertion, compile/build guard, protocol guard, or deterministic validation fails -> investigate/fix code.
- **INFRA FAILURE:** Roblox Open Cloud remains PROCESSING past deadline, returns HTTP 429/5xx, or runner infrastructure stops after otherwise passing specs -> preserve the evidence, retry, and do not mislabel it as a gameplay regression.
- A timeout/429 is still a red gate until a retry succeeds on the release lineage; it is never silently treated as PASS.
- Record passed test counts, failed shard, workflow/run number and exact SHA.

## Build artifact provenance and integrity (pre-release)

The ordinary `Build Validation` workflow creates `chaos-survival-place` for
each successfully compiled SHA. It contains:

- `ChaosSurvival.rbxlx` — built place file, **not automatically published**;
- `ChaosSurvival.rbxlx.sha256` — SHA-256 digest of that place;
- `candidate-provenance.txt` — exact source SHA, workflow run and explicit
  `NOT_PUBLISHED` / `NOT_VERIFIED` / `NOT_CERTIFIED` flags.

After downloading and unzipping the Actions artifact, verify it with
`sha256sum --check ChaosSurvival.rbxlx.sha256` on Linux/macOS or by comparing
the SHA-256 digest using Windows `Get-FileHash` in PowerShell. Compare
`source_sha` to the exact candidate commit, not just the branch name.
The artifact is useful for **offline review and loading into authenticated
Studio**; it is not evidence of a live Roblox deployment, performance,
persistence, safe monetization or publication authorization.

## Production destination verification (critical; 18 October 2026)

Before any real production publication:

- [ ] Confirm that the actual Roblox Creator Dashboard **public** experience
  is Universe `10771083668` and Place `95351659174730`.
- [ ] Confirm that GitHub `ROBLOX_UNIVERSE_ID` and `ROBLOX_PLACE_ID` match
  those **verified** public IDs, not an older or unrelated experience.
- [ ] Confirm that staging uses a **different** universe and place and
  that its key cannot write to the published universe.
- [ ] Inspect Creator Dashboard **Version History** for the potentially
  unintended staging-stamped versions **64** and **65** before choosing
  any restore version. Never guess which prior version is safe.
- [ ] Run authenticated Studio/Android/device QA and the exact-SHA
  Release Candidate Gate before manually dispatching production publish.

The production workflow is **manual-only** and refuses publishing when
repository variables differ from those explicitly recorded public IDs.
Changing this pinned target must follow independent Creator Dashboard
verification and a code review; do not weaken the check to make CI green.
The visual staging workflow intentionally fails closed while the old
target collision remains unresolved.

## Historical published candidate — legacy Roblox target, not current production

The following older publication evidence refers to a different
Universe/Place than the owner's later public Creator Dashboard links;
it is retained for historical audit, **not a current live target**.

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

- [ ] Build Validation and Roblox Open Cloud Engine Tests both pass on the exact candidate SHA (73 uniquely assigned engine specs).
- [ ] Studio confirms a full ordered intermission > ready > round > result journey on a single client, without double-counting repeated states.
- [ ] Authenticated Studio E2E checks Showtime 3D stage identity, static part safety and hidden ROUND / visible RESULT transitions.
- [ ] Studio confirms six R6/R15 emotes and no conflict with Settings or locomotion.
- [ ] Android 320/360/400/440px viewport checks: emote dock stays on screen and accessibility Settings remains operable.
- [ ] The four arena probes confirm each distinct hero monument is present, has 6–50 anchored non-colliding parts and logs its identity/part count during Studio E2E.
- [ ] All four map landmarks render and rotate safely, remain non-colliding and clean up across arena transitions.
- [ ] Meteor/Bomb bursts render as different fragments, including all transient pieces in live budget metrics.
- [ ] Near-miss and landing FX affect eligible living participants and AI only; late joiners, spectators and eliminated lobby avatars excluded.
- [ ] Simultaneous character reaction beams stay at or below 12 per client and missing rigs release their temporary listeners within eight seconds.
- [ ] R15 sprint/hard stop/180-degree pivot/jump/land + respawn produce no frozen body pose or broken movement.
- [ ] Performance + hazards during Double Chaos remain readable on a real Android device at Low/Medium/High VFX tiers.
- [ ] Reduce Motion suppresses cosmetic pulses and pose intensity while maintaining critical hazard readability.

Full hands-on Android protocol: [Android playtest checklist](docs/ANDROID_QA_PLAYTEST.md). This is a manual acceptance plan, not a passed test.

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
- [ ] Compare the downloaded candidate place SHA-256 with its checksum and ensure its provenance SHA matches the certified release commit.
- [ ] Archive the publish artifact containing place file + publish-metadata.txt.
- [ ] Run a final smoke test immediately after publication.

## Definition of done

Chaos Survival 1.0 is ready only when automated CI, authenticated Studio E2E, physical-device UX/performance, persistence/rejoin and public-alpha gates have all passed on the same release lineage.
