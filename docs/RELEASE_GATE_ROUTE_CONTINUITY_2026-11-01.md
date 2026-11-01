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

## Release checklist — manual execution pending

- Run existing **Build Validation** GitHub Action on current `main`, record real green commit SHA and Luau/Rojo logs.
- Run existing **Roblox Open Cloud Engine Tests** GitHub Action on **the same exact SHA**; all five shards must pass. If either fails, do not publish and fix the real reported defect.
- Run Studio visual E2E, 15 genuine camera frames on each of five variants, inspect all eight jumps per viaduct, every protected rise and both simultaneous collapse waves. Check that old Tower pressure, Double Chaos, Shrinking Arena, timed impacts and all player/bot paths remain logical.
- Run real Android Low/Medium with eight total round-start participants (actual humans+AI fill) and desktop; collect real frame-time, thermals and responsiveness.
- Only after actual milestones and explicit public-release authorization, update the existing public experience; record published SHA and preserve rollback target.

No physical QA, Cloud tests, same-SHA readiness or public Roblox publishing have been claimed or inferred.
