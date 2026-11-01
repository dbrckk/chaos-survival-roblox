# Studio E2E — five real arenas and Harbor's dedicated animated signature (2026-11-01)

## Evidence boundary

Source candidate: branch `fix/studio-e2e-five-arenas-harbor-signature-20261101`, based on main `e07cd94145f0db961ed93e8fa208a41f567e80eb`.
The baseline public experience last verified by an authenticated publication workflow is `e8767c98c475a3efb39ed53ed7bbe16efa1865d2` (run 41287014148).
**This branch has not been deployed or physically tested in Studio or Android.** Code review and repository consistency are not a Roblox runtime PASS.

## Defects addressed

1. `src/server/StudioE2E.server.lua` previously hardcoded only Classic / Towers / Crossroads / Orbital in the coverage flags, iteration and PASS summary. Actual production rotation in `ArenaVariants.Order` contains five arenas including Harbor. Studio now derives its four per-arena coverage maps and reporting loops directly from the canonical order.
2. Instead of accepting a complete intermission → ready → round → result from any one map, the Studio E2E gate now requires an ordered journey for **each** arena; the existing client traces and reports those journeys for each distinct arena.
3. The visual client probe lacked Harbor entries for the signature, service/midground detail, silhouette, deck and platform. It now identifies real Harbor-specific parts. The mooring footing is intentionally marked as a decorative visual motif, rather than claiming it belongs to the `ArenaDetailKit.Service` catalogue (which has no Harbor service entry).
4. `ArenaSignatureKit.build` previously routed Harbor to Classic's radar via the generic fallback. Harbor now gets its own non-colliding port gantry, cabin, mast, animated storm radar, crane rail, cargo cradle and tiered metal fittings. The existing `radar` animation role is reused; **no new frame loop, remote or gameplay collision**. The existing source part-count guard (Low ≤22 / Medium ≤32 / High ≤50) remains active. Reduced Motion restores each part's captured rest pose.
5. Some existing platform finish pieces attach via `Weld` rather than `WeldConstraint` (notably adjustable route/skybridge pieces). The visual probe accepts either class but still requires the exact `ChaosPlatformTrimWeld` name, expected visual anchoring and non-collision, and non-nil Part1.

## Exact-major-milestone validation (not yet executed)

1. On a frozen candidate SHA, run **Build Validation** and all **five Roblox Open Cloud Engine Tests** suites. Any failed/empty suite blocks release.
2. With the official, authenticated Studio Windows runner, run `Roblox Studio E2E Playtest (Authenticated Runner)` using `studio/ci-runner.luau` (`ChaosE2E`, four clients, 90-second collection window). Make sure the runner is online; do not replace authenticated execution with a simulated PASS.
3. Confirm logs for **all five** unique IDs: `CHAOS_E2E_ARENA`, `CHAOS_E2E_ARENA_ENTRY`, `CHAOS_E2E_ROUND_JOURNEY` and per-arena `CHAOS_E2E_VISUAL_PHASE ... round`. The result text must report **5 arena entries**; absence of any Harbor probe must fail, never skip.
4. Confirm Harbor's `HarborStormRadarSweep` identity, its noncolliding anchored part count between 6 and 50, `HarborMooringFooting1` + `HarborBowTaper` motif ownership, `HarborMooringSpire` accent, `HarborDryDockPlankWest` deck, `HarborTimberSplice` trim, and valid fixture in a real Studio client. Inspect teardown and rebuild between map transitions.
5. Run the existing win → next numbered READY replay, real spawn clearance, spectator, HUD, result reward and late join probes. Do not weaken these gates to accommodate Harbor.
6. When physical review is available, capture authentic Android views on Harbor at Low / Medium / High, verify readable danger and real FPS/frame-time. Extend review to all five maps. **This part remains pending**; a code-level Studio PASS alone is not AAA art/performance certification.

## Release policy

No test-only map is published to the public universe; never treat `main` as the current Roblox Place version.
Do not merge or publish as certified until the milestone's exact SHA has the required evidence.
Keep the existing public universe `10771083668` and starting place `95351659174730`; no private/intermediate public release.
