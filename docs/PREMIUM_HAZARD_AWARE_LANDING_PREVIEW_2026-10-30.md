# Chaos Survival — grounded landing hazard truth, Android / PC

_Date: 30 October 2026. Previous sweep/shutter preview already published; meteor/bomb addition below is a new source candidate, unpublished._

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

## Follow-up: actual meteor/bomb impact safety at landing

The preceding warning rules covered three arena mechanics but **not** the
server's current `MeteorWarning` and `BombWarning` footprints. During an
announced impact, a physically valid target could still show cyan even when
the authoritative disaster was about to damage the character.

The client now tracks existing workspace-root warning Parts via two
lifecycle subscriptions, without enumerating `workspace:GetChildren()` on
every 100-ms sample. Warnings enter the reticle's **existing** optional
hazards array only after the normal 3+1 landing raycasts have found a
real, imminent collidable target. The common classifier accepts **only**
live workspace-root `MeteorWarning` with `WarningKind=Meteor` or
`BombWarning` with `WarningKind=Bomb` and valid positive replicated
`WarningEndSize`. The final warning diameter comes from the server's
`HazardWarning.configure`; its center is precisely
`warning.Position + Vector3.new(0, 1, 0)`, matching
`DisasterImpact.applyRadialDamage`. The test uses true **3D**
root-to-impact radial distance, so high steel platforms outside the
actual spherical damage region **remain cyan** even if they overlap the
warning's 2D floor circle.

A threatened contact uses the existing red X with all four segments
on Android Low; no new UI, camera owner, impact prediction beyond server
warning, client gameplay authority, collision change, RemoteEvent or
polling loop. The marker is deleted when the authoritative warning Part
disappears. Invalid/unconfigured warning data are ignored instead of
inventing an arbitrary blast. This complements, rather than weakens,
the already distinct high-priority disaster warning visual on the floor.

A new case in the **existing**
`tests/engine/movement-assist-rules.spec.luau` verifies real marker
registration (including incomplete replication), end-size 3D radial
threshold, raised safe decks, bomb/mismatch/invalid warnings, and
immediate removal. Real Android Low/Medium checks must confirm that
the red X is legible midair but never obscures the real server warning.

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

**Current state:** previous platform, sweep, shutter and mobile camera improvements were published or validated separately. The new meteor/bomb preview extension remains source-only pending an exact-SHA build plus all real Roblox Open Cloud suites. The last verified public publisher [41112157340](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41112157340) deployed `77e5805c96d9dd793e5bc058b93b4d7e904e1530`; newer source changes are not public yet. No Android hardware/Studio visual certification is claimed.
