# Automated Studio E2E playtest

The repository contains a full Roblox Studio E2E harness built on Roblox's official `StudioTestService` and `VirtualInput` APIs.

It verifies in a real Studio client/server simulation:

- 2 initial clients plus 2 staggered joins;
- generated lobby and arena;
- required remotes;
- HUD, visual-effects and spectator GUIs;
- viewport bounds for critical HUD elements;
- critical overlay presence/layout for round focus, round events, Meteor/Bomb escape cue and Shrinking Arena center cue;
- non-overlap between simultaneous hazard escape cues;
- minimum tap-target sizes;
- exclusive Quest/Cosmetics/Achievements panels;
- real virtual mouse clicks on menu buttons;
- real disaster voting;
- real virtual keyboard movement;
- at least one accelerated gameplay round;
- one simulated client leaving and server cleanup.

## One-click local run

Install/sync the project into an authenticated Roblox Studio session, install `studio/ChaosAutoplay.plugin.lua` as a local plugin, then click **Chaos E2E** in the Chaos Survival toolbar.

The plugin starts a four-client test and prints either `PASS: ...` or `FAIL: ...`.

## GitHub Actions

`.github/workflows/roblox-studio-smoke.yml` is manual-only and intentionally targets a Windows **self-hosted runner**.

Reason: a fresh GitHub-hosted runner has no Roblox Studio OAuth session. Experiments confirmed that Studio installs successfully but stops at the Roblox login dialog before `RunScript` executes. An Open Cloud API key does not act as a Studio user session.

The self-hosted runner therefore must:

1. run Windows;
2. already have Roblox Studio installed;
3. already have an authenticated Studio session for the runner user.

### Hosted diagnostic probe

`.github/workflows/roblox-studio-hosted-probe.yml` is deliberately **non-certifying**. It installs the official signed Studio build on a temporary `windows-latest` runner and attempts the same local four-client harness.

Its result manifest uses:

- `status=PASS` only if the local Studio harness actually completes;
- `status=AUTH_REQUIRED` when Studio starts but the ephemeral runner has no authenticated Roblox session;
- `certifying=false` in every case.

A hosted probe can diagnose installer/CLI compatibility, but it never satisfies the Release Candidate Gate. Do not store Roblox passwords or session cookies in GitHub to turn this probe into a certifying run.

## Always-on autonomous coverage

The normal Open Cloud workflow does not need Studio login. It runs real Roblox-engine tests on every push, including:

- all 11 disaster modules started and cleaned in a DataModel;
- all 4 arena variants;
- every disaster on every arena;
- current round-state sync for late joiners;
- every allowed Double Chaos pair;
- map hot-swapping and cleanup;
- progression/data schema, rewards, quests, cosmetics and achievements;
- Solo Rush and balancing rules;
- audio configuration;
- analytics helpers.

Production behavior is unaffected by the Studio E2E harness. E2E scripts exit immediately outside Studio and only activate when the test argument `suite = "ChaosE2E"` is present.
