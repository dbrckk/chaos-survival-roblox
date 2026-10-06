# Chaos Survival — Rollback Runbook

Use this only when the currently published Roblox version must be reverted quickly.

## Principle

Do **not** rewrite or reset `main` to perform a rollback.

The rollback target must be a previously known-good commit that already has:

- Build Validation = success on that exact SHA;
- Roblox Open Cloud Engine Tests = success on that exact SHA;
- preferably a prior successful publication artifact / release-evidence artifact.

The `Publish Roblox Place` workflow refuses uncertified SHAs.

## Evidence to collect first

Record:

- incident time UTC;
- currently published commit if known;
- last known-good commit SHA;
- failing behavior;
- affected device/platform;
- most recent publish workflow run;
- Roblox version number from `publish-metadata.txt`, when available.

Do not delete the failing release artifacts.

## Preferred rollback path

1. Identify the last known-good SHA from:
   - a previous `publish-metadata.txt`;
   - a Release Candidate Gate evidence artifact;
   - or a documented historical certification in `RELEASE_CHECKLIST.md`.
2. Confirm both required workflows are green on that exact SHA.
3. Point the dedicated `publish-roblox` branch to the known-good SHA.
4. Push that branch.
5. The `Publish Roblox Place` workflow will:
   - verify the exact SHA certification;
   - rebuild the place from that SHA;
   - publish it to the configured Roblox place;
   - archive the rebuilt `.rbxlx` and new `publish-metadata.txt`.
6. Verify that the publish workflow returns a Roblox `versionNumber`.
7. Run an immediate post-publish smoke:
   - join the experience;
   - confirm lobby loads;
   - confirm one vote / READY / round / result loop;
   - verify movement and touch controls;
   - verify at least one hazard warning;
   - verify no blocking client/server errors.

## Git example

Run these commands only after selecting a verified known-good SHA:

```bash
git fetch origin
git branch -f publish-roblox <KNOWN_GOOD_SHA>
git push --force-with-lease origin publish-roblox
```

The force is limited to the dedicated deployment branch. Do not force-push `main`.

## If the rollback publish is refused

Do not bypass the guard.

Check whether the target SHA has successful:

- `Build Validation`;
- `Roblox Open Cloud Engine Tests`.

If the historical run is missing or inconclusive, use a newer known-good certified SHA instead. Do not publish an unverified commit during an incident.

## If Roblox publication itself fails

Classify the failure before changing game code:

- missing/invalid API key;
- Roblox API HTTP error;
- no returned `versionNumber`;
- transient GitHub/Roblox infrastructure failure.

Retry infrastructure failures only after confirming the source SHA has not changed.

## After rollback

- record the rollback publish run ID;
- archive its `publish-metadata.txt`;
- keep the broken release SHA for diagnosis;
- fix on `main`;
- rerun Build Validation + Open Cloud;
- rerun affected Studio/device gates;
- publish only after the repaired SHA is certified.

## Roll-forward preference

When a small, well-understood fix is already validated, prefer a roll-forward over repeated rollback/publish cycles. The same exact-SHA certification rules still apply.
