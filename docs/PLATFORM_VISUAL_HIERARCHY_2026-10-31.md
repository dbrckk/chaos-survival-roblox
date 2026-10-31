# Chaos Survival — Platform graphics: truthful jump/hazard visual hierarchy

**31 October 2026 — source-only improvement on top of PR #439.** No release, runtime screenshot, engine test or FPS certification has been performed for this change.

## Inspected state
The existing `arena-platform-identity.client.lua` owns three types of in-world marks: neutral platform construction motifs, two geometry-verified `ParkourTakeoffChevron` strokes, and server-driven collapsing-platform visibility. The separate `disappearing-platform-readability.client.lua` owns prominent amber/orange warning edges and a warning X. Existing current route markers were made cool-white in PR #439, and they are hidden if shrinking/collapse invalidates the target.

**Problem:** `ClassicPlatformAxisA`, `CrossroadPlatformLane`, and one-third of `OrbitalPlatformTangent` used `Enum.Material.Neon` in the same top-of-deck visual plane as real route hints. These consistently luminous decorative strokes could appear like route instructions despite being purely decorative. The active danger orange and active ascent cool-white did not have clear exclusive priority.

## Authoring change
Changed only `src/client/arena-platform-identity.client.lua`:
- Classic's top calibration axis becomes an opaque-ish, muted, original **metal** engraving instead of the prior bright accent Neon.
- Crossroads' top traffic axis becomes a quieter brushed-metal line rather than an emissive glowing route candidate.
- Orbital's top platform tangent uses a consistent native metal treatment for *all* indices. Orbital ascent uses actual continuous helix ramps, so an illuminated fake jump axis is especially misleading.

Theme-specific brushed metal colors still inherit `VisualTheme` and retain recognizable platform identity. Parts stay in their existing positions and are welded to the exact same real player-bearing deck.

## Technical properties and constraints
- **Zero added Parts**, zero new textures, assets, remote events, UI layers, update loops or sensors.
- Native Metal replaces exactly three categories of decorative *top-surface* Neon markings, reducing unnecessary emissive surface noise without altering the existing safe route chevrons and danger graphics.
- Low/Medium/High geometry counts, existing low-density decoration, per-platform shrink-footprint tracking, `CollapsePhase` fading, and PBR ownership are unchanged.
- Other non-decorative, independently managed world hazards, collapse X/amber outlines, original route chevrons and objective prompts are untouched.
- No game mechanics, collision, bot AI, reward economy, spawn or camera system changes.

## Visual acceptance at next publication milestone
1. Capture the same platform under Android Low, Medium and High: the neutral axis must remain readable as an industrial finish but must not look like an objective arrow.
2. Verify only the actual `ParkourTakeoffChevron` gives a cool-white *verified* jump indication. On Orbital, confirm tangent plates do not imply an impossible jump between helix levels.
3. Trigger Disappearing Platforms: amber/orange warning edge and X must take unmistakable priority, while decorative surface markings fade using their existing owner.
4. Trigger Shrinking Arena: all local cosmetic marks continue to track the real deck footprint and arrows vanish when the physical jump becomes impossible.
5. Verify live UI/contrast, Roblox engine suites, final exact-commit Build Validation, performance and thermal stability on target Android devices before the next public update.

**Public experience unchanged:** Universe `10771083668`, Place `95351659174730`. This candidate is eligible for merge after source review; it does not update the Roblox experience by itself.
