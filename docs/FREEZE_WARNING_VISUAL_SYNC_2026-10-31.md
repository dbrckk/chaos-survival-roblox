# Chaos Survival — Freeze warning visual timeline (authoritative metadata)

**31 October 2026 — source-only quality and gameplay legibility fix after #444.** No engine execution, Android capture or public Roblox publication has taken place in this pass.

## What was wrong

The server's actual `Freeze` disaster creates a `FreezeWarning` Part in `Workspace` before invoking the central `HazardWarning.configure` helper, which sets the `WarningKind`, `WarningStartedAt`, `WarningDuration`, `WarningStartSize` and `WarningEndSize` attributes. Under `StreamingEnabled` / mobile replication, the Part may arrive before its metadata. The existing premium VFX client immediately allocated faceted ice segments and a mist emitter, falling back to **local current time + guessed 0.7-second duration**, while the separate hazard warning client already awaited a fully validated authoritative snapshot.

This could display the cold facets at the wrong point in the real warning (or begin too early), weakening the relationship between the server freeze effect and its visible countdown.

## Implemented in the existing owner

- `disaster-premium-vfx.client.lua` now uses the already existing `HazardWarningSignatureRules.snapshot` policy as its **only** source of timing and final warning diameter.
- When a warning streams in before its metadata, use temporary listeners on the exact five required attributes and retry on their actual change; no arbitrary `task.wait`, timeout guess, heartbeat scanner or extra VFX allocation.
- Only on a complete, unexpired warning snapshot does the client build the original **4/6/8** faceted freeze pieces, the existing one `FreezeMist` emitter and its warning-time animation.
- Disconnect all pending listeners on successful bind, warning removal, or model teardown. A snapshot race during listener registration is handled by an immediate second check.
- Refresh quality/reduced-motion and loss of streamed cosmetic children through the same validated snapshot path; update a reused effect's start/duration/end-diameter rather than silently retaining stale local values.
- The original ice glass materials, colors, sparkles, lifetime, and **ReduceMotion** two-piece freeze geometry are preserved. Authoritative damage, frozen movement, warning radius, UI labels and server disaster timings are untouched.

## Budgets

No new Pieces, Lights, Emitter instances, textures, images, ambient loops, network traffic, or per-frame work. Pending warnings alone briefly own up to 5 small attribute subscriptions, disconnected when the complete server bundle arrives or the warning disappears. Normal active warnings use zero metadata subscriptions.

Low / Medium / High freeze visuals remain **4 / 6 / 8** original faceted pieces; ReduceMotion remains **2**. The original `ChaosPremiumDisasterVfxLocal` owner and global Android VFX telemetry are reused.

## Exact-SHA milestone verification — not run

1. Trigger actual `Freeze` on Android with ordinary and delayed/partial StreamingEnabled replication. Ice facets and mist must not appear until the complete authoritative warning metadata is available.
2. Confirm the cold perimeter animates against the real 0.7-second server timing, not an independent local countdown. Check low/medium/high quality and `ReduceMotion` toggling mid-warning.
3. Verify that an expired warning arriving late does not allocate an orphan effect, and that all local effects and metadata connections are released on removal/round transition.
4. Verify RisingLava visuals unchanged and existing tornado material identity from #444 preserved.
5. Run the repository's manual Build Validation and all five Roblox Open Cloud engine suites on the **exact intended release SHA**, followed by real Android frame-time, thermal and warning-legibility captures before any public publication.

**No live publish:** Universe `10771083668`, Place `95351659174730`.
