# Chaos Survival — Android world-label declutter, 31 October 2026

**Source-only follow-up to PR #459, prompted by three genuine owner screenshots from Android.**

## User-observed visual defects and source owners

- The previous oversized English `GRAVITY TIDE` replicated world panel was fixed by PR #459, not yet publicly published.
- The clearly visible English `SHORT ROUTE` across the scene is the actual server-created `SupplyCacheLabel` BillboardGui in `src/server/ArenaDistrictCaches.lua` (100-stud range).
- Floating `CLIMB / DODGE`, `SURVIVE UNTIL 0` and `HIGH GROUND` words are authored in `src/server/MapBuilder.lua` (`SurvivalRouteBriefing`, `ObjectiveLabel`, `SideLookoutLabel`).
- Other optional large English world labels are authored by `src/server/DistrictSignalRush.lua` (`SignalObjective`) and `src/server/ArenaDistrictTransit.lua` (`TransitWayfinding`).
- Android already has a **localized, directional** `DistrictExpeditionNavigator`, server-authenticated collectible/prompt interactions, in-world 3D lights and route arrows. Duplicating optional English world panels hides the level and the dominant survival warning; static text labels are not an objective or collision source.

## Focused finished source changes

1. `src/client/district-expedition-navigator.client.lua` now locally disables **exactly those six optional world-space BillboardGui names** for touch clients; desktop is untouched. It uses the already-existing workspace descendant registration and removal stream events, with one `Enabled` change subscription per identified label. A late server signal-wave re-enable is suppressed locally without any per-frame scans, remotes or physics changes. Connections disconnect on stream-out.
2. The remaining localized mobile objective panel preserves the real waypoint and guidance. In wide landscape touch mode it displays a brief `active/next signal` title, **remaining seconds and distance** rather than a dense 2-coin detail; the existing native proximity prompt still shows the real reward at the destination.
3. `src/shared/UIResponsive.mobileExpeditionLayout` makes **only wide touch** optional route cards 182px wide × 44px high instead of 208px × 51px. Small/split-screen and portrait screens keep their original layout, safe inset/overlay constraints, visibility rules, and survival-priority behavior.
4. The **existing** `tests/engine/ui-responsive.spec.luau` now checks these precise wide landscape and unchanged portrait dimensions. No new unit test file; engine execution is deferred until the significant publication gate.

## Acceptance and limits

- Must still verify on a real Android client (screen ratio of owner's capture, plus 640×360 and portrait) that **all English world billboard duplicates disappear on touch** and that the 3D cache/signal location, keyboard/touch ProximityPrompt, on-screen direction arrow, landing markers, critical hazard countdown and actual awards continue to function. PC retains original world labels.
- No new client loops, server allocations, texture files, MeshParts, streaming budgets, collision, payouts or monetization.
- These screenshot-driven edits remove UI overlap, **not** all visual/3D quality debts. PBR materials, skyline and map readability require real in-engine close/mid/far screenshots and FPS capture. Separately, the owner-launched AI audit failed before login and its proven PowerShell root was addressed in PR #458.
- **Not yet published:** the public Roblox experience remains on the verified release SHA `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f`. Exact-source Build Validation and five Roblox Open Cloud suites plus Android screenshots are mandatory at the next owner-authorized public update. Do not claim that the new HUD is already live.
