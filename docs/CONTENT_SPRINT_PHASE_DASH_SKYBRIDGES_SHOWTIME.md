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

## Acceptance and limits

Build Validation and Open Cloud engine tests validate schemas/recipes but
do **not** prove that visual results look like top-studio art, that live
animations replicate consistently, or that Android stays within budget.
The original avatar clip fallback, custom animation publishing, soundtrack
licensing, actual environment art review, and solo/multiplayer Studio E2E
remain explicit release blockers. Performance target is >=30 stable FPS on
modest Android hardware; it must be measured on a real device.
