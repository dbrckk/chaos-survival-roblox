# Release blocker closed in source — continuous escape backbone

Date: 2026-11-01. Latest source candidate is NOT automatically a published Roblox build.

## Discovered issue

PR #535 correctly made the 16 physical 2.4-stud-gap sky-promenade sections immune to randomly disappearing platforms. However **the 4 endpoint lookout platforms and their ascent routes remained eligible**. A double-collapse wave can select two distant decks simultaneously. This could sever both exits from a perfectly solid 200–220-stud high bridge and strand a human or one of the seven simulated bot survivors, with no intentional warning that the *safe bridge* itself was unsafe.

## Safe high-level route contract now implemented

Each of the four existing ascent circuits now has an explicit, single server-authoritative continuous backbone:
1. **Perimeter steps 1–5**, beginning with the ground-reachable entry and reaching the branch fork.
2. **Branch steps 1–4** leading up to the two crossing endpoints on each north/south side.
3. **Promenade steps 1–8** for the actual suspended crossings.

Every segment is marked `PermanentRoute=true` on its **ArenaVariants source definition** and `ChaosPermanentRoute=true` on its corresponding **MapBuilder physical collider**. The existing `DisappearingPlatforms.eligiblePlatforms` excludes *only* that attribute, so this supplies fair continuous ground-to-sky exits without new booleans, external APIs, physics, invisible damage or special treatment for bots.

This protects **52 genuine physical decks per map** (4×5 perimeter + 4×4 branch + 2×8 promenade) against **random disappearance only**. It does **not** falsely promise immunity from lava, bombs, meteors, tornados or geometry shrinking. Other normal platforms (including perimeter steps 6–8, existing core and many Crosslink/Harbor special sections) remain eligible, so the catastrophe remains a genuine play challenge and its existing 1/2-wave limits are unchanged.

The 4 original Tower skybridges keep their own `ChaosSkybridge` mechanic; neither their indices nor their special pressure behavior is repurposed.

## Deterministic geometry review from authored source (not an actual client playtest)

| Arena | End-to-end viaduct span (studs) | Jump gap (studs) | Endpoint overlap (studs) | Within 320×320 floor |
| --- | ---: | ---: | ---: | --- |
| Classic | 202 | 2.4 | 4 | Yes |
| Towers | 204 | 2.4 | 4 | Yes |
| Crossroads | 206 | 2.4 | 4 | Yes |
| Orbital | 198 | 2.4 | 4 | Yes |
| Harbor | 220 | 2.4 | 4 | Yes |

Dimensions are evaluated from the declared `perimeterLocations`, `PerimeterSteps`, branch endpoints and `PromenadePlatforms`. Perimeter ascent tops rise by 3.6 studs per step, branch tops rise by 3 studs, and both bridge endpoints match the source's final branch top of 30.4 studs in arena-local coordinates. The geometry is nominally within the jump rules, but **physical Studio traversal, mobile lag and collision response remain unverified**.

The existing engine-map specs were **updated**, not replaced, to assert: first five perimeter segments and all four branch segments bear permanent-route attributes; the random collapse candidate list excludes all permanent decks; at least eight normal eligible choices remain. No new unit test file was added.

**Critical second finding:** the existing `JumpRouteCueRules.jumpable()` deliberately requires at least 0.4 studs of height increase, so it cannot validate or guide the level 2.4-stud gaps of the new crossings. The real crossing collider is still physically jumpable, but a player received no repeated directional language over 200 studs. `MapBuilder` now attaches **four native, collisionless double-chevron stroke pieces per promenade deck** (**64 cosmetic guidance parts** per active map): one two-stroke arrow toward each end, author-owned by its real `PerimeterPlatformIndex`. They remain above the existing `PlatformPanel`, follow Shrinking Arena, are nonqueryable, and do not misrepresent platform collision. The updated real-map engine spec verifies every 2.4-stud interval, overlapping entry/exit, equal deck heights, permanent colliders and all marks across both lanes on all five variants.

## One-time release gate and remaining real-world validation

The new one-shot `.github/workflows/one-time-premium-release-qa-20261101.yml` is restricted to a **single exact-title, main-branch merge that creates that file**, not every feature push. Its token has **Actions write only** and **Contents read**. It checks the immutable current main SHA, dispatches the existing manual `Build Validation`, waits for a genuinely green run on that exact SHA, and **only then** dispatches the five real `Roblox Open Cloud Engine Tests` suites. If build fails, main moves, GitHub denies the dispatch or a timeout occurs, the orchestrator fails closed and no Roblox engine test is launched. **It has no publish permission or publishing step.** The subsequent read-only release-readiness workflow may run automatically after a Cloud result. This architecture reduces wasted Roblox Cloud calls and keeps automatic tests permanently OFF during unrelated future feature pushes. Do not claim it executed until the GitHub Actions job state proves it.

## Release checklist — physical and final publication still pending

- Run existing **Build Validation** GitHub Action on current `main`, record real green commit SHA and Luau/Rojo logs.
- Run existing **Roblox Open Cloud Engine Tests** GitHub Action on **the same exact SHA**; all five shards must pass. If either fails, do not publish and fix the real reported defect.
- Run Studio visual E2E, 15 genuine camera frames on each of five variants, inspect all eight jumps per viaduct, every protected rise and both simultaneous collapse waves. Check that old Tower pressure, Double Chaos, Shrinking Arena, timed impacts and all player/bot paths remain logical.
- Run real Android Low/Medium with eight total round-start participants (actual humans+AI fill) and desktop; collect real frame-time, thermals and responsiveness.
- Only after actual milestones and explicit public-release authorization, update the existing public experience; record published SHA and preserve rollback target.

No physical QA, Cloud tests, same-SHA readiness or public Roblox publishing have been claimed or inferred.

## Actual first gate outcome and source correction

The one-time gate **really ran** on source SHA `f2e8c0e9a3887c733225957acfd9051586983ba5` ([orchestrator](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41330650145), [Build Validation](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41330658400)). Build passed Rojo installation, glTF, registry checks, Luau compilation and early security/performance guards, then **failed** at the persistent local-world visual-folder audit, because the newly added `ArenaSkyFleetLocal` and `ArenaCataclysmDebrisLocal` were missing from the visual accounting registry. The server never dispatched paid Roblox Cloud tests on that failed source. The retry explicitly adds BOTH to `src/shared/VisualBudgetRules.lua`, preserving the Low/Medium/High numeric limits and existing 1Hz telemetry. A second build on the new SHA is required; do not treat the previous Luau PASS as complete Build Validation.
