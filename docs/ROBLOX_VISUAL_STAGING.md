# Chaos Survival — isolated Roblox visual staging

**State is evidence-driven:** adding this workflow does NOT create a Roblox
experience, publish the game, or prove any rendered visuals. Only a successful
`Roblox Visual Staging (isolated)` **deploy** job with published-version
metadata proves the candidate has been published into the *separate* test
experience. A green **preflight** job with a skipped deploy means **NOT
DEPLOYED**.

## Isolation and non-negotiable safety

- Staging is a **different Roblox experience (Universe ID)** with its own
  distinct start Place ID. It is not an extra place inside the public
  production universe. This also isolates persistent DataStore data.
- New staging experience should remain **Private** (owner only) or limited
  to authorised Playtesters; check permissions in Creator Dashboard.
- Give the dedicated staging API key only the `universe-places:write` permission
  for the dedicated staging universe. It must **not** be able to publish to
  production. Never paste the key into chat or commit it to GitHub.
- The staging workflow checks that both staging IDs are numeric, nonempty,
  and different from the existing production universe *and* place. Missing
  or identical IDs block publication. It never invokes the production
  publish workflow and never merges the current PR.
- A build-only GitHub Actions / Roblox Open Cloud engine-tests success
  does not produce genuine screenshots and does not mark this gate PASS.

## One-time setup in Roblox Creator Dashboard

1. Sign into [Creator Dashboard](https://create.roblox.com/dashboard/creations).
   Create a **new, separate, private Roblox experience**, e.g.
   `Chaos Survival — Visual QA`, with its own starting place. If the
   mobile dashboard cannot create a new experience, initial creation may
   require an authenticated Roblox Studio session on Windows/macOS.
   Never duplicate by adding a place inside the existing live universe.
2. From that new experience, copy its **Universe ID** from the creation
   card's overflow menu. Open **Places**, select its start place, and
   copy the **Place ID** from the dashboard URL. Verify both differ from
   those of your existing live experience.
3. Create a Roblox Open Cloud API key with **universe-places:write**
   permission for **that staging universe only**.
4. Open [GitHub repository settings](https://github.com/dbrckk/chaos-survival-roblox/settings/secrets/actions)
   (GitHub mobile browser with desktop site if necessary).
   Under **Actions → Variables**, create:
   - `ROBLOX_STAGING_UNIVERSE_ID` = the test Universe ID;
   - `ROBLOX_STAGING_PLACE_ID` = the test Place ID.
   Under **Actions → Secrets**, create:
   - `ROBLOX_STAGING_API_KEY` = the **staging-only** key.
   Keep the existing production `ROBLOX_UNIVERSE_ID`,
   `ROBLOX_PLACE_ID`, and `ROBLOX_API_KEY` untouched.
5. Verify the staging experience is still private / playtest-restricted.

Roblox reference:
[Place Publishing API](https://create.roblox.com/docs/cloud/guides/usage-place-publishing),
[Publish and manage audience](https://create.roblox.com/docs/production/publishing/publish-games-and-places),
[API keys](https://create.roblox.com/docs/cloud/auth/api-keys).

## Exact-SHA build and publication

The workflow [Roblox Visual Staging (isolated)](../.github/workflows/roblox-visual-staging.yml)
only automatically triggers when relevant source or this workflow changes
on `main`. After initial setup, merge an **approved source change** to
`main` or explicitly dispatch the workflow from `main` in GitHub Actions.
The workflow must not automatically deploy unmerged feature branches. A
configuration-only change outside the declared paths does not trigger a
staging publication. The release commit shown in the in-game staging stamp
must match the current deployed `main` candidate before collecting evidence.

Preflight: verifies all five inputs: staging Universe, staging Place,
staging API key, production Universe, production Place. Missing stage
configuration produces a **NOT DEPLOYED** step summary; a production/staging
ID collision fails closed.

Deploy (only after preflight): checks out `GITHUB_SHA` exactly, injects
the ephemeral `src/shared/VisualStagingStamp.lua` file into the
**runner's copy only**, builds the place with pinned Rojo 7.7.0, verifies
that the generated place has the commit identity, and calls Roblox's
Place Publishing API with `versionType=Published` against the **staging
IDs only**. The SHA marker file must never be committed or included in a
regular public game build.

**Proof of deployment:** successful deploy job, positive version number,
the `visual-staging-publish-proof` artifact, and the test place URL
`https://www.roblox.com/games/<STAGING_PLACE_ID>` listed by the workflow.
Do not invent an ID, a URL or a successful deployment based on a local build.
The test place is playable only for accounts with suitable Roblox access.

## Actual mobile screenshots and videos

On the **published staging experience** in the Roblox Android app:

- A small PHOTO control appears only if the staging-only SHA marker is
  present; the ordinary/public game should not show the QA buttons.
- **PHOTO 3D:** captures real engine-rendered world and effects with no UI.
- **PHOTO + HUD:** captures the scene, gameplay HUD and a visible
  `STAGING · <commit-prefix>` provenance label.
- **VIDEO 8 SEC:** records real movement with Roblox's native video API
  on supported devices; it does not simulate motion or create AI renders.
- **PROCHAIN IMPACT:** arms a single capture after the next visible,
  in-range, server-reported disaster impact.

### On-device spawn / save / performance diagnostics

On the isolated staging build only, a compact **three-line non-interactive HUD** appears
next to the `STAGING · <commit-prefix>` watermark when using PHOTO + HUD:

- **FPS / WORST / VFX tier / budget**: local 2.5-second FPS sampling, worst
  observed frame duration, chosen adaptive VFX tier and current part/light/FX budget.
- **ENTRY**: `LOBBY` means not actively in an arena, `RESCUED` means the
  lobby spawn fallback has been used at least once this connection;
  during READY or ROUND, `CLEAR`, `BLOCKED` or `CHECKING` mirrors the
  server's arena placement status for active entrants. In ROUND,
  `OUT` means eliminated, and `SPECTATE` means not a round participant.
  `LOBBY` is **not** proof of a safe native spawn.
- **SAVE**: `LOADING`, `READY`, `RETRY`, `TEMP` or `CONFLICT`.
  `READY` means the session currently reports persistence available, **not**
  that the current progress has already been written; only real rejoin tests
  establish successful DataStore persistence.

Orange text warns about sub-30 FPS, graphics over budget, blocked entry,
temporary saves, save retry or session conflict. The commit provenance label
is placed just above the diagnostics instead of overlapping it, and the panel
fits the available Android portrait viewport width. This HUD does not fetch
private data, expose tokens/IDs, make DataStore writes or add a frame listener.
The expensive visual budget snapshot is sampled every four seconds, while
READY/ROUND and save/spawn attribute changes **refresh the status text
immediately**, so short READY phases are not missed. This has **no effect**
on production builds without a valid ephemeral staging marker. Save one
PHOTO + HUD in the lobby, one in the arena, and one after rejoining for
diagnostics; record the full SHA in the GitHub staging publish artifact.

The player must accept the save prompt. Open **Roblox menu → Captures**
to save the original item to the device; attach it to the chat for
review. None of the images/video are automatically uploaded to the repo
or to the conversation. If native capture is unsupported, use Android's
built-in screenshot or screen recorder **inside this staging experience**.

For visual certification, show each of the four arenas (wide + detail),
R6/R15 locomotion, human + AI movement, reactions to at least five
hazards including Meteor/Bomb/Tornado/Freeze/Lava, Showtime dancing,
and Low/Medium/High plus ReduceMotion settings. Record device,
commit and graphics tier. Compare clarity, clipping, aliasing, motion
stability, and only then score 3D, VFX, animation and game feeling.

### Cinematic-depth regression check (mobile performance)

The cinematic skyline is **client-only**. This build coalesces requests to
recreate it from map-ready, VFX-tier, ReduceMotion and round-phase signals
within the same scheduler turn. The content, arena-specific architecture and
per-tier geometry remain unchanged.

In isolated staging, verify the following with a physical Android device:

- Join with slow/streaming map replication: no missing architecture or
  duplicate `ArenaCinematicDepthLocal` geometry after the map appears.
- Rotate through Classic, Towers, Crossroads and Orbital. Confirm the
  distant silhouettes match each arena and do not flash or pop twice at
  the same READY/ROUND boundary.
- Switch graphics Low → Medium → High → Low and ReduceMotion on/off.
  Geometry should stabilize after each setting change; sky traffic
  should remain absent in active ROUND and with ReduceMotion.
- Observe FPS, worst-frame duration and visual budget in PHOTO + HUD,
  then repeat for 30 minutes. Compare to the previous staging candidate;
  a successful build alone does **not** prove an actual FPS improvement.

This regression check is separate from the authenticated Studio four-player
gate, DataStore rejoin validation and release certification.

### Late arena streaming and lighting regression

Understructure and midground sculptures are client-owned cosmetic geometry.
On a slow Android connection, an Arena folder can replicate **before** its
Base part or VariantId attribute. This candidate now uses the shared
`MapVisualReadiness.watch` contract for both, with coalesced rebuilds.
The focal-lighting controller also coalesces map/tier updates and skips
unchanged countdown snapshots rather than creating new light tweens every
second.

Validate on the isolated staging experience with a real Android device:

- Join on a throttled or slow network, then visit all four arenas.
  The underside braces, scenic mass and appropriate spotlights should
  appear even if Base/VariantId arrive after the Arena folder.
- Play at Low, Medium and High visual tiers; quickly switch tiers
  between rounds. There must be no duplicate understructure or
  persistent light fixtures from a prior arena. Low disables focal lights.
- Confirm hazard-driven focal colors, final-rush dimming, reduced-motion
  preferences and readability of meteor/bomb warnings all remain correct.
- Use PHOTO + HUD to capture source commit, FPS and worst-frame duration,
  then repeat after 30 minutes and reconnection. Do not infer actual FPS
  improvement from a green build alone.

This is cosmetic/client-only: no server physics, scoring, DataStore ownership,
paid content or public production publish is affected.

### Mobility-pad route markers after delayed replication

The client-only arena route-arrow renderer now observes Base, VariantId,
Mechanics, every mobility pad and each pad's marker/impulse attributes.
Those items can replicate independently on a slow Android connection.
Once attributes arrive, guidance is rebuilt without needing a graphics-tier
change or relaunch. Old signals and geometry are disposed on map change.

Verify in isolated Roblox Android staging:

- On all four arenas, look for center direction motifs plus route arrows
  adjacent to each visible mobility pad after the map fully streams in.
- Join during slow replication, with network interruptions, or after a
  round changes arena: guidance must appear/reappear without toggling
  graphics or restarting the Roblox client.
- In Towers, vertical route beacons must match actual lift-pad positions;
  in Classic/Crossroads/Orbital, chevrons must point using the server
  pad's impulse attributes, even when they arrive after its BasePart.
- During ShrinkingArena, arrows should follow moving pads. Check Low,
  Medium, High, spectator/elimination transitions and ReduceMotion.
- PHOTO + HUD and 30-minute Android FPS/memory soak remain the release
  evidence; green CI alone does not certify these device behaviors.

No server collisions, mobility impulses, scoring, DataStore or monetization
were changed by this client-only guidance update.

## Rollback / restrictions

This workflow has **no write access to the public experience**. For
staging rollback use the staging place's Version History from Creator
Dashboard. The public publish workflow retains its independent explicit
certification and confirmation gates. Do not change production place variables or the staging experience's
audience without a separate decision. PR #19 and its integration PR #18
were merged on 16 October 2026; new staging builds follow `main` only.
