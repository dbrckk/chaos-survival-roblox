# Chaos Survival — accurate five-arena skill briefing (FR/EN)

_Date: 30 October 2026 • source-only premium candidate, unpublished._

## Root cause and product impact

The existing `ArenaGuide` already translated static map guidance, but **Storm Harbor was missing entirely from `CoreLocalization.ARENA_COPY`** and hence displayed English fallbacks on French devices. More seriously, a map's static hint could mention optional bridge collapse, floor sweeps or moving transfers even in beginner rounds where the server had correctly disabled those hazards. The authentic server `ArenaMechanics.start` already knows what ACTUALLY started, but its returned hint was not converted to a compact player-facing action in the real round HUD.

A fixed string describing a hazard which cannot occur is misleading for newcomers, and makes late-round objectives seem arbitrary.

## Implemented resolution

1. **Server-owned truth:** `ArenaMechanics.mode(variantId, dynamicStarted, shuttersStarted)` outputs only one of five maps' `Safe` / `Active` modes, with a distinct `TowersShutters` mode only if the gate mechanic actually started. `TowersActive` continues to mean disappearing bridges. Unknown variants and inconsistent gate flags **fail closed**. The real `ArenaMechanics.start` stores `MechanicMode` on the current arena's `Mechanics` folder and returns `mode`.
2. **No new network channel:** the existing **1Hz server `RoundState`** includes `arenaMechanicMode` (the real started mode) and `arenaMechanicIntro` (true during its first ~6 seconds). No new remote event, RPC, event loop, player data or input authority.
3. **No new HUD layer:** experienced surviving players see one concise **map action** in the existing `ChaosRoundFocus` status pill only during that initial window. Important hazards (Final Rush, Overdrive, moving-front warnings, Double Collapse and Double Chaos) take absolute precedence; no newcomer loses the existing basic `STAY ALIVE` objective. The primary upper HUD keeps its full, localized disaster instructions throughout.
4. **Complete bilingual map copy:** `CoreLocalization` now has EN/FR name, strategy and mobility guidance for all five arenas including real **Storm Harbor / Port des Tempêtes**. The client `arenaMechanicAction` accepts only a known arena name/alias AND a mode that actually belongs to that arena. A stale/malformed or cross-map mode returns `nil` and the status pill remains on hazard guidance instead of showing an unverified instruction.
5. **Zero new gameplay/graphics cost:** no extra BillboardGui, animation, sound, raycast, rendering owner, bot advantage, AI script or physics modification. The next cue is shown by changing the existing small status TextLabel once per standard 1-second round update.

## Server-verified action modes

| Arena | Normal safe mode | Advanced physical mode |
| --- | --- | --- |
| Classic Grid | `ClassicSafe`: climb with blue pads | `ClassicActive`: avoid jumping shock lines |
| Tower Run | `TowersSafe`: cyan pads to climb | `TowersActive`: bridge-disappearance detour |
| Tower Run (alternate) | same safe baseline | `TowersShutters`: jump over or wait for a metal gate |
| Crossroads | `CrossroadsSafe`: pink pads and climb | `CrossroadsActive`: gold junction lateral transfer |
| Orbital Ring | `OrbitalSafe`: access a green ramp | `OrbitalActive`: use enabled Helix transfer |
| Storm Harbor | `HarborSafe`: blue cross-dock pads | `HarborActive`: dodge incoming red cargo sweeps |

## Regression and physical QA contract

The existing registered real-Roblox engine specs, with no added spec file, now cover:

- `tests/engine/arena-mechanics.spec.luau`: disabled and active real mechanics across the original five arenas, Tower's gate-vs-collapse alternation, exact server folder `MechanicMode` attribute, unknown and inconsistent modes.
- `tests/engine/core-localization.spec.luau`: Harbor names, aliases and guidance in EN/FR; valid short action strings for every arena mode and rejection of stale/mismatched/unknown mode identifiers.

**Tests were written but deliberately not executed during this development phase.** The next major release gate must run Build Validation and all Roblox Open Cloud tests on the same exact candidate SHA.

On Android and PC verify: initial six-second cue during normal compatible rounds, no false "bridge disappears" cue on a shutter round, no false "floor shock" cue for beginner or incompatible disasters, a language-consistent Storm Harbor experience, no text clipping in the status pill (especially French and small phones), and proper takeover by Final Rush or real disaster warnings. Record screenshots from first three rookie rounds and two veteran rounds for each arena. Do not claim positive results until observed.

**Release status:** source candidate, no public Roblox publication; last known published SHA `a0f56bcd4cfa401162a608404c95649bb39b6446`. Premium acceptance remains pending.
