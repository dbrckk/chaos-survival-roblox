# Automated Studio E2E playtest

This harness uses Roblox's official StudioTestService and VirtualInput APIs.

It verifies, in a real Studio client/server simulation:

- 2 initial clients + 2 staggered joins;
- generated lobby and arena;
- required remotes;
- HUD, juice and spectator GUIs;
- viewport bounds for critical mobile HUD elements;
- minimum tap-target size;
- exclusive Quest/Cosmetics/Achievements panels;
- real virtual mouse clicks on menu buttons;
- real disaster voting;
- real virtual keyboard movement;
- at least one accelerated gameplay round;
- one simulated client leaving and server cleanup.

## Running

Install/sync the project into Roblox Studio, install `studio/ChaosAutoplay.plugin.lua` as a local plugin, then click **Chaos E2E** in the Chaos Survival toolbar.

The plugin launches a four-client test and prints either `PASS: ...` or `FAIL: ...`.

The production game is unaffected: all E2E scripts exit immediately outside Studio and only activate when the test argument `suite = "ChaosE2E"` is present.
