# Content sprint — Phase Dash, Skybridge Circuit, Neon Robot & Orbit Dance

> Development content on stacked PR #19, not a certified public release.
> Do not merge or publish until exact-head automated checks and Studio/Android acceptance.

## 1. Phase Dash — free survival power

**Player fantasy:** a sharp controlled cyan/violet escape impulse that changes your
survival route without teleporting or bypassing collision. Every player receives it.

- **Input:** Q on keyboard; **DASH** button near the right-hand thumb zone on touch.
- **Conditions:** active round participant, alive, grounded; unavailable in lobby,
  spectators, elimination, results, or while airborne.
- **Cooldown:** 9 seconds; server owns timer and derives direction from
  server Humanoid.MoveDirection with character facing fallback.
- **Physical contract:** additive 29-stud/s impulse, hard horizontal 44-stud/s cap,
  vertical [-52, +48] safety envelope. No immunity, damage, currency or purchase.
- **Readability:** expanding cyan ground ring, violet second ring on High,
  short gradient ribbon on Medium/High and audio obeying AudioMuted.
- **Accessibility:** no ribbon for Low/ReduceMotion, no camera shake or frame loop;
  ReduceMotion keeps only a brief low-amplitude ground ring.
- **Implementation:** `PhaseDashRules`, `PhaseDashService`,
  `phase-dash.client.lua`. Tests in `movement-safety.spec.luau`.

### Required physical tests

1. On Android tap DASH during an active solo round; verify movement, recharge,
   no accidental overlap with default jump/move controls (portrait and landscape).
2. Press Q on keyboard; verify no input when a text field/chat has focus.
3. Spam/click remotely during waiting, ready, result, elimination and cooldown:
   never apply a second impulse or grant rewards.
4. Test with Speed Surge, Low Gravity, Tornado, and an arena pad in quick
   succession: no out-of-bounds velocity, stuck camera, or unexpected death.
5. Verify that teammates see the short cosmetic dash signature and that Low tier
   stays smooth over a long session.

## 2. Tower Run — Skybridge Circuit

- Four new **real traversable** mid-deck high routes link all four corner
  towers into one navigable perimeter. Deck top is level with the 12-stud
  tower platforms (Y=13 relative to arena center).
- Each bridge is 4.5 studs wide, with slight endpoint overlaps and 49-stud
  length, keeping connections robust at seams.
- Two embedded edge rails and three understructure ribs per span
  clarify where the safe path goes; decoration cannot collide/touch/query.
- A bridge has the `ChaosSkybridge` attribute and is **never selected for
  DisappearingPlatforms collapse**. Its path remains trustworthy while
  adjacent independent islands disappear.
- All four links are generated/destroyed with the arena; no new persistent
  server heartbeat or external models.
- **QA:** sprint across both junctions of every bridge, jump and land on
  both sides, visit via each updraft pad, and test in every hazard combination.
  Verify no rail, bolt, underframe or fake collider outlives a map swap.

## 3. Showtime — two new authored visual dances

- **NEON ROBOT:** quantized angular puppet poses, staggered beats, opposite
  shoulders/head; matching faceted cyan/magenta dance glyphs on avatar start.
- **ORBIT DANCE:** non-synchronous sine phases between arms, pelvis, head
  and feet; corresponding sweeping orbital glyphs.
- Their holographic stage pose functions are **original procedural motion**
  with independent dancer offsets. The live avatar still uses a compatible
  native Roblox animation as a temporary baseline; fully custom uploaded
  R6/R15 assets are **not** yet shipped. Never describe these as final
  custom avatar animation assets.
- Both appear in the eight-button emote grid. The stage uses its existing
  tier-specific update rate, and the signature glyphs are one-shot client
  decorations with Debris expiration (High six, Medium three, Low zero).
- The new styles cannot execute during combat/voting, follow the usual
  movement interruption and ReduceMotion/AudioMuted rules.

## 4. Crossroads — timed Flux Relay return loops

**Original active level mechanic:** Crossroads now has four new frame-style
cyan/violet Flux Relay arches at its outer lanes. Each pair of opposite
gates charges for 3.2 seconds in an eight-second cycle. The other pair
charges 4 seconds later. During uncharged phases the gate remains a safe,
walk-through navigational element (no collision or damage).

Passing an active arch delivers a server-owned velocity redirection toward
the central hub, naturally forming a route loop with the existing pink
outward launch pads. The mechanic is accessible to every human contestant
and every living in-round survivor bot. The activation cooldown is 3.5s
per character, with no remote client velocity argument, purchase privilege,
damage, or coins. Physics remains capped at 54 studs/s horizontal.

**Visual language:** four metal-frame structures with recessed neon rails,
hub-pointing directional chevrons, charged / charging world labels,
faceted upper crowns on High, and tier-scaled detail counts. Visual states
derive from synchronized server timestamps—no per-frame server signal
spam. A successful crossing drives a short teal feedback cue, while
Overdrive retains the game's existing golden identity.

**Test cases:** use each lane from both sides; verify the active pair
alternates, inactive arch does not boost, one character cannot spam across
adjacent gates, and bots use the same active gating. Test with
Speed Surge/Low Gravity and against Phase Dash, plus map swap and low-end
Android frame rate. All gate geometry is audited in `FluxRelayLocal`;
no decorative part is collidable.

## 5. Orbital — Helix Circuit and Helix Flow

**Traversable world architecture:** eight physical inclined ramps connect
the outer ring's alternating-height decks to the offset inner decks,
forming deliberate radial shortcuts through Orbital. Ramps have dense
DiamondPlate surface, steel spine braces, engineered noncolliding frame
and inset cyan/blue route illumination. Client motion glyphs travel inward
along the authored ramps (24 High / 8 Medium / 0 Low or ReduceMotion);
all transient geometry is counted in `OrbitalHelixLocal`.

**Shrinking Arena contract:** this disaster moves the original islands,
so every Helix ramp and its entire decorative assembly now changes its
length, midpoint, orientation and framing to keep the two endpoints
aligned to their dynamically shifted decks; cleanup restores all exact
original transforms. The server-owned Helix Flow sensors are welded to
the ramp rather than floating in their pre-shrink position.

**Original skill mechanic — HELIX FLOW / ORBIT MASTER:** as a survivor
crosses a sensor midway along a ramp while genuinely moving *inward*
at >=8 studs/s horizontal, the server recognizes a traversal. A
4.2-second per-character cooldown prevents spamming. Crossing a
*different* ramp within 18 seconds advances from **HELIX FLOW** to
**HELIX CHAIN x2** and finally **ORBIT MASTER x3**. Repeating the same
ramp cannot raise the rank; the time window expiring resets mastery.
Rank (current/best) is replicated to round participant attributes and
reset each new round. The action counts as an arena mechanic for human
round-momentum tracking only on new qualified chain progress and shows
a distinct green-to-gold celebration (existing overdrive takes precedence).
The physical Helix Flow sensors are invisible, noncolliding and welded
to their ramp. Bots are judged by the same directional rule but never
receive a player's progression. The mechanic applies **no** additional
speed, immunity, damage, currency or paid advantage.

**Original art response:** a replicated server timestamp and server
mastery tier drive a brief tier-aware cyan/green segmented light sweep
visible near successful human and bot traversals. Orbit Master shifts to
gold-accented faceted energy and displays a compact temporary 3D world
banner for nearby spectators. No camera shake, permanent lights or
client remote spam; zero cosmetic glyphs on Low/ReduceMotion.

**Navigation:** survivor bots can consider ramps as genuine intermediate
targets only when near the ramp at a reachable elevation, and update
their targets if the ramp moves under Shrinking Arena. They do not try
to walk onto elevated ramps from ground level through the scenery.

**Acceptance tests:** verify human sprint from outer→inner triggers once,
inner→outer fails, stationary body fails, observers see the brief skill
cue, cooldown holds, spectators/eliminated players receive no credit,
eight sensors follow the ramps during shrink and are cleaned after
the round. Confirm path slope, foot contact, avatar collision, camera
and mobile touch controls in Roblox Studio and on Android. CI unit
assertions alone cannot establish these physical results.

## 6. Classic Grid — clockwise Grid Circuit

**Optional micro-challenge:** four noncolliding holographic navigation stations
occupy accessible diagonal corners of the ground-level grid, inside the
smallest shrinkable floor. Touch any station to start. Within **20 seconds**,
visit the next three stations **clockwise** without skipping or repeating
one. On a wrong station, progress is unchanged; on expiry, the touched
station starts a new run. A completed circuit can only be claimed once
per player per round, and gives style/momentum recognition through the
existing arena-mechanic event, **not coins, XP, buffs, damage, immunity
or a paid advantage**.

**Server security:** sensor Touched validates a real living player round
participant and a near-ground HumanoidRootPart, not an oversize accessory,
spectator or eliminated avatar. Individual per-player progress and expiry
are replicated as `RoundGridCircuitStep`, `RoundGridCircuitNext`,
`RoundGridCircuitDeadline`, `RoundGridCircuitComplete`. The 0.65s
touch debounce prevents physics contacts from jumping multiple stages.
A completion triggers `GRID CIRCUIT CLEAR` once; no trust in client
input or submitted claimed ranks.

**Original art identity:** four visually distinct compass-labeled stations
(NW / NE / SE / SW) with steel plinth, inset radial segmented circuit,
four vertical indicator pylons and faceted caps on High. Orange emphasizes
the **personal** next station; a modest screen reminder shows next
direction and remaining time. Temporary outward energy facets broadcast
through replicated station timestamps. English/French labels are authored,
Low renders just five static parts per station, Medium 17, High 25,
all noncolliding. The `GridCircuitLocal` folder is budget-audited.

**QA:** complete a circuit on desktop and Android; start from every compass
node; verify deadline, wrong node, repeated touch, one completion per
round, simultaneous unrelated players with different next stations,
spectator/eliminated denial, and correct geometry during Shrinking Arena.
Verify simple read-time for first-time players and no camera/input
obstruction, then collect real Android frame measurements.

## Acceptance and limits

Build Validation and Open Cloud engine tests validate schemas/recipes but
do **not** prove that visual results look like top-studio art, that live
animations replicate consistently, or that Android stays within budget.
The original avatar clip fallback, custom animation publishing, soundtrack
licensing, actual environment art review, and solo/multiplayer Studio E2E
remain explicit release blockers. Performance target is >=30 stable FPS on
modest Android hardware; it must be measured on a real device.
