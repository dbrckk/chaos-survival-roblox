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
on `feat/visual-identity-hero-landmarks-20261008`. After initial setup,
push a **new approved source change** to this branch or explicitly
dispatch that workflow from the branch if GitHub offers that workflow in
Actions. The user or assistant must not assume a configuration-only change
triggers a workflow automatically.

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

## Rollback / restrictions

This workflow has **no write access to the public experience**. For
staging rollback use the staging place's Version History from Creator
Dashboard. The public publish workflow retains its independent explicit
certification and confirmation gates. Do not merge PR #19, change the
production place variables or change the staging experience's audience
without a separate decision.
