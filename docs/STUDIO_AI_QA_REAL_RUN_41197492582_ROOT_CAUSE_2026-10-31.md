# Roblox Studio visual audit failure — verified root cause, 31 October 2026

Actual manual run [#41197492582](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41197492582), exact source `593a968ed4073125f435f200e93fa4051d6becf2`, selected `arena=All`.

## Observed, not inferred

- Actual build, signed Roblox Studio installation, private Tailscale connection and RDP listener **passed**.
- The first authenticated interactive capture job **failed before logging into Studio**.
- GitHub action stage: `STUDIO_WATCHDOG stage=LOCAL_CAPTURE_FAILURE`.
- Exact downloaded sanitized diagnostic artifact ID `13041257409`: `capture-error-metadata.txt` recorded:
  - `exception_type=System.Management.Automation.MethodException`
  - `line=81`
  - `error_id=MethodArgumentConversionInvalidCastArgument`
  - `Cannot convert argument "options", with value: "2", for "Split" to type "System.StringSplitOptions"`.
- Five-map screenshot collection never started; **0/75 actual PNGs**, no contact sheets and no valid visual certification. Only 1,918 bytes of safe diagnostic artifacts were archived.
- This is **NOT** a failed Roblox game, bad player account, failure of Tailscale, or evidence of Android graphical performance.

## Fix

In `studio/remote-ai-interactive-session.ps1`, replaced ambiguous `$line.Split(@('='), 2)` which PowerShell selected as `String.Split(string[], StringSplitOptions)` (and invalid enum value 2). Instead parse the **first equals character** using `IndexOf('=', [StringComparison]::Ordinal)` and `Substring`, preserving Base64 padding in `studio_path_b64`. Duplicate attestation keys now fail closed.

All original signed executable checks remain mandatory: `signer=Roblox`, `signature=Valid`, SHA-256 format, exact executable path and re-hash equality. The Windows executable's certificate/signature is still verified earlier by the GitHub runner.

## Release and real-world acceptance

- This is a **source-only** correction to QA; no game gameplay change, no extra API, new test, public publish or new Windows runner launched by this patch.
- Next authorized **manual** visual-QA run with `arena=All` must pass the signed Studio attestation and reach `SIGNED_STUDIO_VERIFIED` / `AWAITING_OFFICIAL_ROBLOX_LOGIN` before the owner authenticates within Roblox Studio.
- Only when all five per-arena game sessions and 75 actual unique rendered PNGs pass may we claim the UI audit is fully validated.
- Avoid spending another hosted Windows session until the owner has access to its protected Tailscale/RDP credentials and can complete official Roblox login.

Public Roblox release still uses verified SHA `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f`; merging QA scripts alone does not update public gameplay.
