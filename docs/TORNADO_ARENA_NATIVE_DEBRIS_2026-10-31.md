# Chaos Survival — Arena-native tornado debris identity

**31 October 2026 — source-only 3D/VFX change after PR #443.** Does not publish to Roblox or constitute real-device visual/performance validation.

## Problem found in the working source

`src/client/tornado-visuals.client.lua` already renders 5/8/12 windborne debris wedges according to Low/Medium/High. Their existing helix, center-following motion, per-quality animation interval, frozen pose for ReduceMotion, cleanup and hazard warning perimeter are established. However, *every arena* generated identical cyan glass/blue metal shapes. They looked like an abstract energy effect rather than pieces torn off the world, despite substantial existing environment-specific visual work.

## Integrated change

The same wedge pieces now use **original, in-game Roblox materials** consistent with the actual loaded arena:

| Arena | Common debris | Secondary fragment (1 out of 4) |
|---|---|---|
| Classic | Steel diamond plate | Brushed metal |
| Towers | Corroded industrial steel | Reinforced diamond plate |
| Crossroads | Broken concrete | Slate stone |
| Orbital | Pale ceramic containment casing | Service metal |
| Harbor | Salt-worn wooden pier fragments | Corroded maritime steel |

Colors come from the existing `VisualTheme` plus restrained physically plausible ground tinting. In particular, the formerly bright turquoise `Glass` fragments become solid matte objects; none of the wedge pieces use Neon. The **existing high-contrast amber** tornado force-field perimeter remains untouched, always recognizable as a danger rather than a route/objective.

The variant is resolved **once when the existing debris set is built** (initial tornado binding or tier change), not in the wind animation. Shards retain their exact anchored, noncolliding, nonqueryable, nontouchable, shadow-free, creator-authored shape and CFrames.

## Original budgets and game compatibility

- **Low: 5 / Medium: 8 / High: 12** `TornadoDebrisLocal` Parts, unchanged.
- Zero new Parts, ParticleEmitters, Lights, Textures, Remotes, Server ownership, asset IDs, continuous loops or render work per fragment beyond the original `poseShard` method.
- No edits to tornado damage, wind impulses, high-ground counterplay, veteran drift, spectator view, arena collision or reward systems.
- Quality changes use the original `buildDebris`; model teardown and StreamingEnabled readiness remain under the original single owner. Accessibility ReduceMotion still freezes the animation while letting the server storm center move.

## Release gate — NOT YET RUN

Owner prefers no intermediate engine tests. Prior to public publication of the *exact intended merge SHA*:

1. Run existing manual Build Validation and the repository's five Roblox Open Cloud engine suites.
2. Capture all five arenas during tornado from real Android Low/Medium/High, verifying correct material identity, readable orange wind boundary and no visual confusion with safe platforms.
3. Confirm tornado drift carries the fragments; Respawn/StreamingEnabled does not leave old local shards; switching VFX quality replaces rather than duplicates them.
4. Toggle ReduceMotion mid-storm; shards should stop rotating, remain attached to the moving storm, and not trigger additional effects.
5. Capture actual frame pacing, memory/thermals and counts; no performance gain is claimed without measured evidence.

**Game IDs remain unchanged:** Universe `10771083668`, Place `95351659174730`. The last verified public release remains the exact SHA documented in README.
