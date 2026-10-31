# Chaos Survival — five-arena Studio capture reliability (31 October 2026)

**Code review / source-only patch following PR #455.** No Roblox publication, actual Studio capture, Windows runner execution, Android performance or verified images are claimed.

## Defects found directly in the merged 75-frame workflow

1. **Second map failed to construct Windows screenshot interop:** `studio/capture-ai-visual-review.ps1` called `Add-Type -TypeDefinition` to compile `ChaosScreenNative` every invocation. The `All` workflow deliberately invokes the script **five times in the same authenticated PowerShell process**. A subsequent type definition using the identical name throws. The collector now checks whether the type is already loaded and reuses the original.
2. **The scheduled capture task was limited to 17 minutes**, including up to ten minutes for official Roblox Studio login, five separate Studio starts and five 15-image capture sessions. This could terminate a legitimate multi-arena run without returning diagnostic PNGs. The interactive task limit is now **42 minutes**, below the hosted job's existing 95-minute maximum.
3. **The hosted runner gave the session only 14 minutes even after successful login.** Authentication timeout still protects free Actions minutes at **14 minutes**; after a *real* `AUTHENTICATED_STARTING_AI_TEST` or `CAPTURING_...` stage appears, the deadline is extended **once** by **22 minutes for All**, or **8 minutes for one map**. Merely connecting RDP does not extend the window. This is bounded and cannot run as a background agent.
4. **Old game logs could falsely certify a new map.** The collector previously searched new-or-recent Roblox logs using only `LastWriteTime` and accepted `CHAOS_VISUAL_AI_OK` from that union. Rapid sequential Studio runs could include the last arena's success and markers. Real gameplay camera markers are now discovered only in logs **created since the current Studio launch**. The final `PASS` must come from the **current CLI invocation's** `--outputFile` / redirected stdout/stderr, never a previous map's shared Roblox log.
5. **An image could be mislabeled if the next bot camera advanced while Windows was capturing pixels.** Each image is now rejected if a later server-approved index was visible in logs before or immediately after `CopyFromScreen`. This is a deliberate strict fail rather than assigning the preceding bot/arena/angle to a newer screenshot.

The Windows desktop's readme now reports the correct selected scope and **15 or 75** requested true screenshots.

## Scope and existing protections unchanged

- **No new images, artificial gameplay, runtime gameplay features, Roblox assets or tests** were introduced. Five maps, three actual bot camera modes and all original source-level authorization checks remain.
- One real Roblox Studio authentication is still necessary on a signed, visible Windows desktop. GitHub workflow remains manually opt-in, never dispatched by source edits.
- Each map must separately produce **15 genuine Studio PNGs**, its hash manifest, independent server-validated sample markers, and a clean studio CLI PASS. The `All` path must return **75 PNGs and five contact sheets**; partial passes fail overall.
- The collector refuses a stale image or wrong window rather than fabricating evidence or replacing frames.
- Raw Roblox authentication logs, credentials, 2FA codes, cookies and access tokens are **not uploaded**.
- Mobile FPS and thermal claims still require a separate real Android benchmark; Studio/Windows results do not certify Android.
- Public playable Chaos Survival remains on verified live SHA `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f` unless a separately authorized verified public publisher runs.

## Next significant milestone gate

Run the **manual** [Chaos AI Visual Capture (Temporary Windows)](../.github/workflows/roblox-ai-remote-windows.yml) with `arena=All` on its exact candidate `main` SHA, use Tailscale/RDP and sign in inside real Roblox Studio. The result must include 75 original screenshots, five per-arena provenance manifests, five contact sheets, five independent JSON reports and a successful action run. Any failure or timeout is diagnostic only. Compare real close/mid/distant views, check moving hazards and bot silhouettes, and fix **observed** flaws before public release. Full engine suite and Android device verification remain at publication gate.

Reference: [15-frame evidence protocol](AI_VISUAL_QA_15_FRAMES.md); [Android connection instructions](AI_VISUAL_QA_REMOTE_ANDROID.md).
