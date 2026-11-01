# Storm Harbor — disaster-responsive dock machinery and late-streaming recovery

**Date**: 2026-11-01. **Repository source baseline**: `169ed4d1aa24a3c3ff5dfd4c9317d50b0abcd174`. This changes only source; no public Roblox deploy or real Android/Studio performance certification is claimed.

## Concrete behavior

The four *original*, noncolliding dock instruments from PR #520 now respond to the already authoritative `Remotes.RoundState` disaster IDs. Instead of adding particle effects or fake orange warning lights, the existing machinery uses a **mechanical posture** (one posture across a two-disaster round, with stable severity precedence), a small neutral metal tint and an adjusted reversible TweenService motion:

| Disaster(s) | Priority | Posture and real response |
| --- | ---: | --- |
| Freeze, DisappearingPlatforms | 7 | **stowed** — reset instrument to rest and stop tween entirely; platform warnings remain the primary hazard signal |
| Meteors, Bombs, ShrinkingArena, JumpShock | 6 | **impact** — half amplitude and 20% slower machinery |
| Tornado, SpeedSurge | 5 | **gale** — 18% greater sweep, 25% faster (max weather radar 23.6°; bounded) |
| RisingLava | 4 | **heat** — 82% amplitude, 17% slower, muted warmer steel (not hazard orange) |
| LowGravity | 3 | **drift** — 70% amplitude, 35% slower |
| Darkness | 2 | **night** — 54% amplitude, 30% slower and darker sensor casing |
| Other / outside round / malformed packet | 0 | **normal** — original authored neutral color and four distinct calm motions |

Two-disaster rounds use the **highest priority**, independent of input order; `RoundState` packets typically arrive repeatedly, but a machine's tween is cancelled and rebuilt **only when its posture changes** (no per-packet tween churn). Repeated identical states only do constant-time classification. No new RemoteEvent and no frame/heartbeat loop is added.

## Lifecycle and ownership

- `HarborOutpostKit.disasterPosture(ids, phase)` is the deterministic mode classifier; `motionTarget(route, posture)` is a bounded oscillation target; `instrumentColor` tints just the moving head, never a danger/route panel. Non-qualifying input keeps the ordinary mode; no gameplay gain.
- `arena-platform-identity.client.lua` remains the **only owner** of the four instruments, their `TweenService` instances and `PlatformIdentityWeld.C0`. Shrinking Arena alone controls the `C1` shrink-footprint, so there is no competing property writer or collision edit.
- `CollapsePhase=Warning/Gone`, `CanCollide=false`, opacity threshold and `ReduceMotion=true` keep priority over disaster reactions. `clear()` cancels/destroys all tweens, disconnects watchers and restores joint pose before the whole client-owned geometry is destroyed.
- Mobile Low renders **zero added 3D machines and therefore zero tweens**. Medium/High keep the previously fixed 20/36 3D Parts and four active tweens maximum, with no new 3D geometry or textures in this PR.
- If a Harbor dock part streams in with `RouteTier` already replicated but `HarborSpokeRoute` or `HarborSpokeStep` missing, the owner observes those **only for canonical appended IDs 95..110** and rebuilds on actual arrival. The subscriptions are disposed of during rebuild/swap; no polling and no new listeners on the 94 historical Harbor IDs.

## Source verification and release gate

The source audit should verify: eleven disaster IDs covered, severity precedence, malformed state return, bounded movement, no new RemoteEvent, all four instrument color/pose changes within the original collision-less cosmetic budget, one joint property writer per kind, ReduceMotion, CollapsePhase, stream-in/out and map replacement cleanup. **Source assertions cannot establish actual rendered motion.**

At the *next major* pre-public-release gate, run Build Validation and all five Roblox Open Cloud engine suites on the exact final SHA, followed by authenticated Studio E2E of the five arenas, 15 genuine snapshots/arena, streaming and collapse toggles, and physical Android FPS/memory/occlusion testing. For Harbor, test Double Chaos combinations (Freeze+Tornado, Meteors+LowGravity), change Low↔High midround, pause and restore ReduceMotion, deliberately late-stream terminal attributes, and 20 successive map handoffs without ghost moving parts.

No source PR is itself a public Roblox publication. **Last separately verified published SHA**: `e8767c98c475a3efb39ed53ed7bbe16efa1865d2`.
