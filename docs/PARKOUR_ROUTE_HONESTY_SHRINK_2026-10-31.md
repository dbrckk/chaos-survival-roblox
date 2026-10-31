# Chaos Survival — Parkour route truthfulness during Shrinking Arena

**31 October 2026 — source-only quality improvement.** No Roblox publication, simulator certification, Android capture or CI run is asserted for these changes.

## Discovered issue

The two thin, original `ParkourTakeoffChevron` strokes were created on a geometrically verified platform pair. Existing `syncTakeoff` only verified that the two parts still had `CanCollide=true`, shared a parent and lacked a `CollapsePhase`.

Shrinking Arena progressively changes the size of an actual server-owned deck without necessarily changing those properties. A formerly legal jump can exceed the existing `JumpRouteCueRules.MaxGap = 3.85` studs while the cosmetic arrow remains visible. Similarly, the target might stream in already on warning, or have its transparency changed independently. Visually attractive guidance must never advertise a demonstrably impossible or collapsing route.

## Implemented

- The original selector filters out non-colliding, already collapsing, or mostly invisible source/target platforms. No fabricated jump suggestions.
- `JumpRouteCueRules.cueStillSafe` verifies the **original target against the same** existing gap, rise and tier selection rules using a two-element candidate array. The existing same-tier central hub exception remains intact. This is not a new pathfinding algorithm.
- The existing client owner responds directly to source/target `Size`, `CanCollide`, `Transparency` and target `CollapsePhase` changes. A changed part recalculates only its original two chevron strokes, rather than rescanning the entire arena, creating additional Parts or starting another polling/render loop.
- Source `CollapsePhase` still invokes the established `PlatformFinishKit.applyCollapseVisibility` to fade the actual decorative platform markings. Non-phase route updates do **not** rerun that full ornament walk.
- Valid route strokes gain a consistent restrained cool-white accent (subtly tinted for the current map) and a slight width increase. Collapse warnings remain amber/orange and always take priority. The same two original pieces, welded to their actual platform, are used; no increased geometry budget.
- The existing `clear()` tears down all attribute/part property listeners on map/quality rebuild, streaming and arena replacement. No gameplay collision, server-authoritative hazard, XP, AI, jump ability, remotes or platform dimensions are changed.

## Safety and limits

- A former takeoff marker **disappears** when its original target becomes unsafe; it does not falsely pivot to an unverified alternate destination. A future engine-validated route discovery system could safely offer alternatives if needed.
- No claim is made for arbitrary moving-platform CFrame changes between size/phase events, which must be assessed in the engine gameplay acceptance pass. This patch targets the confirmed Shrinking Arena footprint issue.
- No engine tests, CI job, Android screenshot or publication has been performed in this improvement stage, in accordance with the owner's milestone-only test policy. Before public publication, run the repository's manual exact-commit Build Validation and **five** Roblox Open Cloud engine suites, and inspect on-device Low/Medium/High with actual shrinking and disappearing platforms.

## Manual acceptance at the next milestone

1. Start an original first-tier ascent and confirm safe cool-white takeoff chevrons stay entirely on physical decks.
2. Shrink the real source or target until the gap exceeds 3.85 studs. Verify the cue disappears **without** leaving a ghost ledge or persisting on the old jump.
3. Set `CollapsePhase=Warning` and then `Gone` on target/source as appropriate: route arrows must yield to the high-contrast amber warning and remain hidden while unsafe.
4. Restore a valid pair and verify any existing cue reappears without additional geometry allocation. Stream in late platform sets to verify safe initial selection.
5. Repeat during a real Android Low/Medium/High run for all five arena variants; check HUD readability, in-world contrast, frame pacing and clean teardown on map swaps.

**Place IDs retained:** Universe `10771083668`, Place `95351659174730`. The public Roblox version remains unchanged until separately released.
