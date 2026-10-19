# Chaos Survival — Production recovery / rollback runbook

Use this if the publicly published Roblox place is unhealthy. This procedure
does **not** authorize automatic rollback or publication.

## Non-negotiable safeguards

- Do **not** force-push or reset `main`.
- Do **not** change the production Universe/Place IDs to reach a different target.
- Do **not** publish a staging-stamped build to the public experience.
- The current `.github/workflows/publish-roblox.yml` runs via
  **manual workflow_dispatch on `main` only**. A push to a
  `publish-roblox` branch **does not publish anything**. The previous
  instructions describing that branch were obsolete.
- A successful `Build Validation` and `Roblox Open Cloud Engine Tests`
  alone are insufficient: the production workflow also requires a successful
  **Release Candidate Gate on the exact SHA**, backed by authenticated Studio
  testing, evidence and explicitly approved manual checks.
- Historical staging deployments numbered **64** and **65** may have targeted
  the public Universe `10771083668` / Place `95351659174730`. Neither
  version is a known-good rollback target without independent inspection.

## Capture incident evidence

Record the observed UTC time, failing behavior, affected platforms, live
Place version, workflow run IDs, published SHA if known, logs, screenshots
and current GitHub `main` SHA. Preserve failure artifacts.

## Path A: Creator Dashboard Version History (owner-operated)

1. Sign in as the authorized Roblox experience owner.
2. Verify the public **Universe `10771083668`** and
   **Place `95351659174730`** against the actual Creator Dashboard.
3. Open the place's **Version History**, inspect candidates and identify
   an **independently verified playable production version**. Do not infer
   safety from version number or green staging CI.
4. If an authorized owner selects a previous version, use the Creator
   Dashboard's documented restore controls. A restored version may need
   separate publishing and a server restart; do not assume it is immediately
   live. Consult [Roblox version history](https://create.roblox.com/docs/projects/version-history).
5. Confirm the intended version is now serving real players. Run an
   authenticated Android/desktop smoke of lobby → vote → READY → round →
   result, basic movement, one hazard and persisted rewards.
6. Record the restored and newly published version numbers and evidence.

This path is a manual Roblox operation, **not** a GitHub release-gate bypass.
Do not execute it before reviewing the known staging-identity incident.

## Path B: Correct source on main and publish a fully certified roll-forward

Use when the repair is small and well understood, or when no verified
historical live version is available.

1. Prepare a **reviewed pull request** reverting/fixing only the bad change.
   Never force-push `main` or use a `publish-roblox` branch.
2. Merge after the exact PR head passes Build Validation and all five engine
   suites. Verify the resulting **new main SHA** gets its own green checks.
3. Run an authenticated four-client Studio E2E and real Android/desktop,
   persistence, gameplay and accessibility checks on that candidate. Record
   evidence; do not mark untested steps PASS.
4. Run the manual **Release Candidate Gate** on that same `main` SHA, using
   `CERTIFY` and actual evidence-backed `PASS` attestations. Verify its
   successful run and `release-evidence.md` artifact.
5. Double-check production destination variables match the independently
   verified public Universe/Place, and verify the source contains no staging
   watermark.
6. On GitHub Actions, manually dispatch **Publish Roblox Place** on `main`,
   type `PUBLISH` and review its exact SHA. No branch push triggers publish.
7. Check the returned `versionNumber`, and archive `ChaosSurvival.rbxlx`
   and `publish-metadata.txt`. Perform the immediate Android/desktop smoke
   and record results.

## When anything blocks recovery

**Never disable or weaken a safety gate to get the game online.** If an
existing candidate is not certified, do not present it as verified. If the
public experience is actively harmful/unplayable, ask the experience owner
to restrict access through the authenticated Creator Dashboard while the
incident is assessed, following Roblox's current controls.

If a publish fails, distinguish credential/permission errors, invalid
Universe/Place settings, missing certification, Roblox API errors,
transient infrastructure failures and invalid `versionNumber` responses.
Do not log API keys or raw Roblox response bodies.

## After recovery

Retain the failed release SHA, test evidence and deploy metadata. Document
the incident in GitHub issue #1. Re-run the affected physical/device checks
on any subsequent change. Prefer a validated roll-forward over repeated
untested restores.
