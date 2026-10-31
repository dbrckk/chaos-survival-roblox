# Android screenshots — Moon Gravity world-text duplication (31 Oct 2026)

## Evidence

Three actual Roblox Android landscape screenshots supplied by the owner on 31 Oct show the local round hazard header **`GRAVITÉ LUNAIRE`** with French guidance, while additional oversized English text **`GRAVITY TIDE / PULL IN 2s`** and **`GRAVITY TIDE / PULL • SHORTER JUMPS`** is rendered over traversal. Camera views change, and the English text moves with the world: a replicated `BillboardGui`, not another localized ScreenGui.

The exact source is `src/server/Disasters/LowGravity.lua`: `makeTideBeacon` created a **240 × 64 px**, `AlwaysOnTop = true`, **MaxDistance = 190** `GravityTideSignal` with English `TextLabel`. It updated the label every 0.25s during gravity tides. The game already publishes `GravityTideStage` in `RoundState`; `src/client/round-events.client.lua` shows short, priority-managed, French/English localized notifications on real phase transitions using `RoundEventPresentation.gravityTideCue` and `CoreLocalization`.

## Fix on source branch

Remove ONLY the redundant server-created text BillboardGui and its per-tick English update. Keep the original anchored, noncolliding, glowing `MoonGravityBeacon` with its native color-changing `PointLight` for physical spatial feedback. Keep `D.tideCue` as a pure existing API and keep all 55/120 target gravity, phase timing, physics, player force and cleanup logic unchanged.

Update **existing** engine disaster-runtime spec to assert beacon, actual PointLight, unchanged phase/force behavior and **absence** of the duplicate billboard. No new unit-test file.

## Other screenshot issues still to review after real 75-frame Studio audit

- Large floating world instructions such as `SHORT RO...` and `LIMB DODGE` are partly occluded and visually clash with real HUD, but the exact producing owner should be inspected separately before removing gameplay navigation.
- A French optional `ACTIVE LE SIGNAL` panel competes with the main survival warning; prioritize against real-danger alerts without deleting useful world goals.
- Dense rectilinear port girders, repeated cyan surfaces and violet accent tubes need a coherent physical art-direction review; screenshots alone do not establish device FPS, actual textures loading, collision reachability or whether each trim is server/client-owned.
- ChatGPT floating window and Android volume side controls are **phone UI overlays**, not Roblox ScreenGui or game defects. Do not attribute them to the game.

**This correction is source-only until owner-authorized public release gate.** The last verified live Roblox source remains `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f`; the QA workflow fix is separate PR #458. Real validation requires exact-SHA build, five Roblox suites and Android game rejoin.
