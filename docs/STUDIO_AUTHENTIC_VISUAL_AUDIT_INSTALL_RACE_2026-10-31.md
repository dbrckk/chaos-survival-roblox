# Genuine five-arena Studio visual QA — installation race recovery (2026-10-31)

## Verified live evidence

- Final source/build/engine validation **passed** on `f01da24c1ad7e8e176d079b33cd3299b43349b9b`: [Build Validation 41220268063](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41220268063), [all five Roblox Engine suites 41220275475](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41220275475).
- The first five-arena capture attempt [41197492582](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41197492582) produced **no genuine PNGs**; archived `capture-error-metadata.txt` reports PowerShell `Split(...,2)` invalid enum argument. That error was already fixed in the source before the second attempt. It is **not** evidence of a Roblox authentication failure.
- The second owner-requested capture [41221117346](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41221117346), after [PR 478](https://github.com/dbrckk/chaos-survival-roblox/pull/478), successfully parsed launchers and built the complete **current game** on Windows but failed at `Preinstall official signed Roblox Studio on Windows` **before Tailscale or login**. The step log explicitly reports `Get-AuthenticodeSignature: The process cannot access the file ... RobloxStudioBeta.exe because it is being used by another process.` Roblox's installer still held a write lock when the executable first appeared in the Versions folder. No PNGs were obtained.
- Both runs refused false visual certification and did **not** publish Roblox.

## Minimal pipeline correction

Only change `.github/workflows/roblox-ai-remote-windows.yml`:
- The signature and SHA-256 pass over the exact official Studio EXE are now performed together inside a **maximum 90-second bounded loop**.
- **Only Windows sharing violations** are retryable; missing/untrusted/invalid signing status, wrong signer, unreadable runtime/other error and bad hash remain hard failures.
- The official **installer's** Authenticode verification remains required first. The interactive viewer still verifies the same attested path+digest itself. Authentication remains exclusive to Roblox's own official UI; the runner never acquires account cookies.
- The existing `studio/REMOTE_AI_QA_TRIGGER` marker is updated once to request an `All` five-map retry on the corrected Git commit. This marker does not alter any game code or publish Roblox.

## Required visual review

For each Classic, Towers, Crossroads, Orbital and Harbor, the existing 15-frame camera runner must produce native screenshot bytes, digest manifest, and contact sheet. Inspect screenshot evidence across near/mid/far geometry, visibility of newly adjusted Android LOD, structural alignment, material coherence, hazards/UI occlusion and player/bot readability. Verify exact source SHA and file metadata from real Roblox Studio. Do not promote to visual-certified until all 75 PNGs pass.

Authenticating the ephemeral Windows Roblox Studio session may require a single user action via Android Tailscale + remote desktop. This cannot be automated without the owner's Roblox session and should not be bypassed. Actual Android GPU FPS/thermals need separate physical-device measurements.
