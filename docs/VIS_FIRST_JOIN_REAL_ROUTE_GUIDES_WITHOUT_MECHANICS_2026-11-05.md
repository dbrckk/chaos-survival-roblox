# First-join real route guidance independent of optional mechanics

Date: 2026-11-05. Chaos Survival Roblox, code-only first-minute visibility fix; no public release or on-device performance claims.

## Real source gap

The existing `arena-navigation-language.client.lua` `rebuild()` required an `Arena.Mechanics` folder **before** creating even the center landmark and the four physical entry-route chevrons. Roblox replication/streaming can supply `Arena.Base`, `Arena.Platforms` and server tags earlier than the optional mobility-pad machinery. A first-join player then sees zero objective arrows, even though all four actual routes are present.

When `Mechanics` disappears during streaming, `bindMechanics(nil)` called `clear()`, also deleting unrelated floor cues and disconnecting the floor shrink follower.

## Correction

- `Arena.Base` is now the only required floor geometry for center landmark rebuilding. `Arena.Platforms` and four `ChaosPerimeterEntry` server-tagged physical decks remain selectively optional/late, discovered by the existing watcher. Mechanisms are not a prerequisite.
- The mobility-pad visual list is populated **only if** the optional `Mechanics` folder exists. Existing impulse arrows, vertical markers, quality caps and actual physical pad identity are unchanged.
- `bindMechanics(nil)` only queues a bounded existing 0.12 s rebuild, which discards stale pad markers but recreates genuine route markers and preserves the correct first-minute visual language. Full `clear()` remains when `Arena`/`Base` are absent.
- No additional instances compared with the steady-state design, server physics changes, fake paths, polling loops, new network traffic or render callbacks.

## Certification

At the next major milestone, exact-SHA build and seven real Roblox Cloud engine suites. Android Low/Medium/High: first load with delayed Mechanics; late four real platforms; shrinking; hazard disable/restore; mobility pads arriving late; round-to-round replacement. This change does not certify visible screenshots, FPS or publication.
