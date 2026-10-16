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

### One-player AI acceptance (new)

The same Studio plugin also adds **Chaos Solo AI**. With the current source synced into an authenticated Roblox Studio instance, click that button to execute a real **one-player / one-server** simulation. Its server-side `SoloAIStudioE2E.server.lua` checks:

- exactly one human plus three distinct living AI survivor rigs;
- valid unanchored HumanoidRootPart/Humanoid on each bot;
- `GetNetworkOwner() == nil` for each bot assembly after the bounded network-ownership initialization;
- at least two distinct bots moving horizontally, including an actual playing locomotion animation track (not just a MoveDirection signal).
- all three living bots entering the arena in the same solo session, flagged `AISurvivorInRound=true` on their rig; idle lobby bots are not valid spectator camera targets.

The AI roster also stays fixed from **ready** through **round** and **result** when other human clients join or leave. New players are considered for AI-count reconciliation at the next intermission, not halfway through an active survival contest.

The test returns `PASS:` or `FAIL:` through official `StudioTestService:EndTest`. It does **not** prove client rendering quality, real-device FPS, or all disaster decisions. This test is not silently counted as passed by ordinary Build Validation or Open Cloud engine tests; it requires an actual Studio session. Use it before Android solo acceptance and record its candidate commit and exact result.


## GitHub Actions

`.github/workflows/roblox-studio-smoke.yml` is manual-only and intentionally targets a Windows **self-hosted runner**.

Reason: a fresh GitHub-hosted runner has no Roblox Studio OAuth session. Experiments confirmed that Studio installs successfully but stops at the Roblox login dialog before `RunScript` executes. An Open Cloud API key does not act as a Studio user session.

The self-hosted runner therefore must:

1. run Windows;
2. already have Roblox Studio installed;
3. already have an authenticated Studio session;
4. run the GitHub Actions runner under the **same Windows user account** that owns that authenticated Studio session;
5. expose the standard `self-hosted` and `windows` runner labels.

Avoid running the certifying runner under `Network Service`, `Local System`, or another Windows account unless that exact account has its own valid Studio authentication state. A runner that is configured correctly but offline leaves the Studio E2E job in `queued`; this is expected and does not indicate a game-code failure.

Before bringing that runner online for a release candidate, sign into the runner's Windows account interactively and run:

`powershell -ExecutionPolicy Bypass -File .\\studio\\self-hosted-runner-preflight.ps1`

Then start the GitHub Actions runner under that same Windows account. Once the runner reports online in GitHub, either dispatch the Studio workflow manually from `main` or update `studio/E2E_TRIGGER` to request a fresh exact-SHA certification.

The preflight checks the Studio install, verifies the Roblox Authenticode signature, prints the active Windows identity/profile, inspects any installed GitHub Actions runner service account, launches Studio briefly under the runner's Windows account, and reads the resulting Studio log for the final authentication state.

- Exit code `2`: Studio is not authenticated for the current Windows user. Open Studio normally, sign in interactively, close Studio, and rerun the preflight.
- Exit code `3`: the GitHub runner service is configured under a Windows system account such as LocalSystem/NetworkService/LocalService. Run the certifying runner interactively under the authenticated user or reconfigure the service to use that same user.

The preflight never asks for or stores a Roblox password/session cookie.

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
