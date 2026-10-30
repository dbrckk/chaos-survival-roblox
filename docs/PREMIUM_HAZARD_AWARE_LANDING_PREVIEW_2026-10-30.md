# Chaos Survival — grounded landing hazard truth, Android / PC

_Date: 30 October 2026. Source candidate only, unpublished._

## Correctness defect corrected

The player's single existing local landing contact reticle is physically sampled at 10 Hz and uses up to four collision raycasts. Previously, it showed a cyan **safe landing** on a collidable deck even when an active Grid Sweep or Harbor Cargo Sweep warning crossed the *same physical landing footprint*, and could paint the center of a Tower skybridge as safe while its real 2.05-stud shutter was about to rise.

The reticle now reuses the real **server-authored Parts and replicated phase attributes** to classify a landing point as threatened:

- **Classic Grid Sweep**: real `GridSweepBand#` with `GridSweepPhase = Warning/Pulse` and actual oriented box. Red X only where the projected root is within the ground band, not over distant/raised high-ground decks.
- **Storm Harbor**: `HarborSweepLane#` with `HarborSweepPhase = Warning/Pulse`; use true CFrame to respect rotated/situated service lanes, not misleading world-aligned approximations.
- **Towers**: only an actual `BridgeShutter` on the **matching physical skybridge** and at `ShutterPhase = Warning/Raising/Raised`. Mark the immediate narrow gate crossing (plus a bounded margin) as danger; don't mark the entire bridge. A bridge away from the sill remains an ordinary landing.

The existing four reusable local, depth-tested contact brackets form the same red X used for platform-collapse warnings, including all four pieces on low-quality Android. The geometry remains purely visual: **no changes to server hitboxes, jump power, rewards, NPC behavior, or falling rules**.

### Computational and accessibility budget

Only after the existing collision preview has found a valid, imminent real surface does the client scan the three named local arena mechanic folders. At most 4 sweep bands or 4 shutter gates can be active in the corresponding single arena. It reuses the **same 10-Hz update path and exactly the same four raycasts**, adds **zero rendering loops, no RemoteEvent, no new HUD layer, no unique sound, and no per-frame workspace scan**. The marker remains a red X rather than merely a red colour, avoiding purely colour-based hazard cues.

The shared physics classifier `JumpRouteCueRules.activeSweepOnPath` stays authoritative for zone projection, so routing and landing previews share exactly the same elevated-bridge exemption and rotated-band semantics.

## Regression specification (written, execution deferred)

`tests/engine/movement-assist-rules.spec.luau` now checks:

1. Warning/Pulse/Idle phases on a true floor band; a real floor landing is flagged while an elevated landing above the band is not.
2. Off-band landing stays safe, nil/malformed inputs fail safe, and rotated Harbor footprints classify correctly.
3. A Tower gate warns at its actual physical narrow sill, not at another bridge or distant safe section, and only during Warning/Raising/Raised states.

### Device acceptance criteria before any public publication

- **Android Low / Medium**: for each of Classic, Harbor, Towers, stand on a real deck and jump toward an imminent server warning. The four local brackets must turn into a red X only for a threatened contact. Verify warnings under rain/darkness and with reduced motion.
- **High ground**: jump onto an elevated platform over an active floor sweep and confirm the reticle **does not lie by marking safety as danger**.
- **Towers**: compare a landing near the actual gate with one on the other half of the same skybridge; verify physical shutter is jumpable/waitable and the UI reflects its phase without stale red markers.
- **Network timing**: delayed replicated attributes must never create a permanent red marker; the next existing 10-Hz sample refreshes the phase.
- **Performance**: measure p95 client frame time and count of raycasts (4 per eligible 10-Hz sample, unchanged), platform transitions and memory. Do not claim 30/60 FPS without measured Android data.

**Status:** code + engine checks prepared; full engine tests not run during this improvement phase, and the Roblox public place remains at the last independently verified publication SHA `a0f56bcd4cfa401162a608404c95649bb39b6446`.
