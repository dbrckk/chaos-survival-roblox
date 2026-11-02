# Sky Spine — full-height cooperative sky interchange

**2026-11-02 · source candidate, not a published Roblox update.**

## Player-visible, substantial enhancement

The five existing 320 × 320 playable arenas now contain a **third real traversable 200–248-stud aerial crossing**, perpendicular to their two 200-stud sky promenades. Ten **server-owned solid 12-stud-wide roof-height decks** form a physical H-shaped sky network: the two original high promenades were isolated from each other except by descending to the far-off ground. Now each has a continuous new strategic cross-arena option with normal 2.4-stud R15 parkour gaps and level junctions. No existing platform/skybridge/Harbor pier index is renumbered; every old look-out and jump remains usable.

Each original world receives a distinctly authored **monumental sky interchange**: industrial survey radars in Classic; upper freight cabins and hoists in Towers; angled route fins in Crossroads; glowing containment reactor/orbital machinery in Orbital; corroded super-cranes and cargo chain pods in Harbor. Repeated 12-stud-wide steel rail details, undercarriage frames, elevated arches, and visible navigation accents make the real route recognizable from the ground. These elements are PBR-friendly native Roblox materials, anchored decorative geometry, noncolliding/non-touching/nonqueryable. The actual new **PlatformN decks** are the ONLY always-live floor; the player cannot be trapped by an invisible roof/wall.

## Actual cooperative world interaction

Two genuine, server-owned **Sky Spine Switchyard** consoles stand on the new elevated deck #3 and #8. A human holds the ordinary Roblox ProximityPrompt for **0.7 seconds** (Android touch, keyboard, controller). A physically present AI bot can independently hold the same control for 0.7 seconds when it is already within 7.5 studs and standing on real ground, with all its urgent hazard escapes taking priority.

On first valid activation, **all NINE 2.4-stud jump gaps become fully collidable physical bridge connectors** (width 10.8 studs, top level with the original ten platforms). They turn from invisible/noncolliding to visible/solid, with two glowing side rails each. Crucially the bridges **remain fully solid for the entire current round**, never disappear after a cooldown, and cannot be repeatedly claimed. It is a genuinely shared rescue route for all eight participants (real humans and AI), not a cosmetic door, a premium item, an instant teleport, or a separately simulated AI path.

Original ten platforms ALWAYS remain fully playable before activation, during activation and afterwards. This gives a high-skill jumping route for early challengers, then a truly accessible shared high-road after the first survivor completes an optional cooperative mission.

## Authority, fairness, performance, safety

- **No client RemoteEvent** and no client-trusted collision, speed, reward, teleport, position or damage. All collision and session state are replicated from the Roblox server.
- Player prompt validation checks genuine active human contestant, data-loaded player, living actual HumanoidRootPart within 13 studs of the console, live round, no seated fast travel and non-final-rush status. Bot activation verifies physically present real AI humanoid, existing server AI flags, supported ground and the same prompt proximity restriction.
- Nine independent, simple anchored 3D bridge Parts and 18 noncolliding guiding light rails only exist while the live round's generated map exists. No permanent connection, physics motion, particles, fake collider, client script, tight server loop or per-frame task.
- ShrinkingArena is explicitly **incompatible** with the temporary physical connectors: since the shrinking disaster repositions physical platforms, the bridge control is not created for those rounds. This never alters or disables the ten permanent cross-aerial parkour decks, which follow the standard authoritative shrink geometry and retain their noncolliding decorative attachments.
- DisappearingPlatforms cannot remove any segment of the permanent H-shaped escape backbone: the ten real spine decks carry `ChaosPermanentRoute=true` just like all previous guaranteed routes. Bridge connectors live outside the original `Platforms` hazard folder and do not enter random collapsing eligibility.
- Existing `RoundCleanup` disables controls and deletes the entire temporary model between rounds. No persistence, monetization or changes to player-count and seven bot-fill logic.
- Fixed art budget: ≤14 noncolliding 3D detail Parts per new physical deck, two actual 3D consoles, nine shared-gap panels and 18 guiding side rails; only one arena is built at any time.
- All map instancing and existing mapbuilder/milestone tests are based on the **new true PlatformN count**, retaining historical 126 Harbor platform identities intact while appending #127–136. The existing real-engine mapbuilder spec now checks both genuine controls, all nine starting noncolliding connectors and permanent safe route positions across ALL FIVE worlds; the variant geometry spec checks exact 2.4-stud gaps, level endpoints and 10 physical decks.

## Release certification — not yet accomplished on this candidate SHA

1. **GitHub Build Validation** on exact merged commit: Luau parser, Rojo packaging, PBR provenance, game security and platform build.
2. Five Roblox Open Cloud Engine suites on that **same SHA**. No new unit-test file, existing engine spec extended only at this milestone.
3. In real Studio / Android: climb both original sky promenades, jump onto Sky Spine, perform normal two-way jump route, reach command #3 or #8, hold to connect, see all nine gap fill animations and confirm real continuous support with a second player and AI bots. Take genuine visual screenshots of FIVE maps, verify 8 participants.
4. Validate interruption by Meteor/Bombs/DisappearingPlatforms, final-rush switch disabled, ShrinkingArena leaves no false ephemeral connectors, no new spawn trap/visibility regressions. Check low-end Android frame rate, controls and skyborne route sign readability.
5. **Only then separately authorize public publishing** to the existing place 95351659174730 / universe 10771083668. Source merge never publishes.

Previous Build/Cloud green SHA `255afb749c38a0482156c7b58a5c57bed0809514` certifies the OLD corridor-shield source, not Sky Spine.
