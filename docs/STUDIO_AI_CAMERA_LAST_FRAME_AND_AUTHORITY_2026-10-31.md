# Chaos Survival — Studio bot-camera final-frame and server authority gate

**31 October 2026, source-only hardening after PR #456.** These changes do **not** publish Roblox, render PNGs or measure Android FPS.

## Directly inspected problems

The authentic five-arena visual evidence pipeline already checks the requested Arena VariantId, each reported AI model's identity, viewport, camera distance, render progression, sample timing and provenance. But it had three residual consistency gaps:

1. A **living AI model was accepted even if it was no longer in the active round**. `AISurvivorInRound` is set server-side in `AISurvivorService.lua` precisely to distinguish active competitor bots from alive, out-of-round/lobby bots. The original Studio evidence guard trusted the client's `inRound=true` instead.
2. The CLI runner declared **any** result beginning with `PASS:` successful. A result for the wrong arena, wrong suite, insufficient samples or unrelated test would emit the trusted `CHAOS_VISUAL_AI_OK` marker.
3. The spectator client restored the ordinary camera just **12 seconds** after the last sample; the Studio server ended the local test after **11 seconds**, risking the final PNG being captured mid-close or from the restored local player. The collector must retain the last validated AI viewpoint long enough to finish its genuine desktop screenshot.

## Finished corrections

- **Server:** `VisualAIStudioE2E.server.lua` requires the actual server-authored `AISurvivorInRound == true` in addition to the existing true arena ID, valid bot, living Humanoid, camera bounds and temporal checks for all **15** frames.
- **Studio test runner:** uses one `scenario` object and accepts only the exact message shape `PASS: visual AI: 15 real <selected arena> round frames, <N> autonomous bots`, with **N >= 2** and arena matching the requested whitelisted Studio scenario. Rejects all other PASS-like messages. The existing `prepare-visual-ai-arena.ps1` remains compatible because it still replaces the one `arenaVariant = "Harbor",` line.
- **Last frame lifetime:** server keeps the Studio play session alive **18 seconds** after accepting the 15th report; the client's actual scripted AI camera remains bound for **22 seconds** after that report. The original external PNG collector must still independently verify actual real screenshot pixels, timestamps, at least eight unique hashes, full-image diversity, all fifteen corresponding server markers and the exact CLI PASS.

## Scope boundaries

- No new unit tests, Studio test suite, production gameplay, map, AI behavior, player controls, monetization or public publisher.
- No new Windows jobs launched; requires the owner's explicit interactive authenticated official Roblox Studio session to produce actual screenshots.
- Captures can still fail if there are fewer than two participating surviving bots or if a real disaster ends the round; these are **valid failures**, not fabricated success.
- This work does not prove graphics quality or Android thermals. Only actual Studio images and device captures can support those claims.

## Next significant validation milestone

Run the manually selected [five-arena visual evidence workflow](../.github/workflows/roblox-ai-remote-windows.yml) with `arena=All` on the exact intended source SHA; complete official Roblox login via protected Tailscale/RDP. Confirm that all five independent Studio TestService suites return their *specific* PASS and supply **75 real PNGs, five hash manifests, five contact sheets and five per-arena analysis reports**. If any frame or auth signal is absent, report failure, preserve only sanitized diagnostics and never label the run as a visual audit success. Use those real images to prioritize observed art/animation fixes.

**Published public version remains** `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f` until separately validated, explicitly authorized public release.
