# Department Review 01 — Creative Direction, Environment Art & World Coherence

## Specialist mindset

Review as:
- senior creative director;
- environment art director;
- technical artist;
- cinematography/composition specialist;
- visual accessibility reviewer.

Detailed implementation rules remain in `AAA_VISUALS_ANIMATION_GUIDE.txt`.

## Creative-director questions

- Can Chaos Survival be identified from one screenshot without logo?
- Do all four arenas feel like the same universe but different places?
- Is the visual promise "readable sci-fi chaos survival" consistent from lobby to result?
- Is there a recognizable visual motif beyond generic neon?
- Is premium quality coming from composition/material/light/motion rather than effect quantity?

## World bible

The universe should feel like a competitive survival facility built around controlled chaos events.

Shared language:
- engineered structures;
- functional safety/maintenance elements;
- broadcast/spectator technology;
- energy systems;
- controlled warning colors;
- deliberate industrial seams and supports.

Avoid:
- arbitrary fantasy pieces;
- random decorative props;
- unexplained material changes;
- every surface glowing;
- theme-park clutter.

## Arena-specific art ownership

### Classic Grid
Professional lens: broadcast/sports architecture.
Must communicate:
- competitive arena;
- technical grid;
- observation/broadcast;
- clean modular construction.

### Towers
Professional lens: industrial vertical environment.
Must communicate:
- height;
- maintenance machinery;
- structural load;
- dangerous vertical traversal.

### Crossroads
Professional lens: transit/environmental wayfinding.
Must communicate:
- lanes;
- junction logic;
- readable destinations;
- directional rhythm.

### Orbital
Professional lens: orbital/space-station systems.
Must communicate:
- radial engineering;
- reactor/energy infrastructure;
- outer-space depth;
- circular navigation.

## Composition gate

From every spawn, capture:
- default camera;
- 45° left;
- 45° right;
- READY;
- first 5 seconds of ROUND;
- RESULT.

Pass only if:
- arena identity reads in <1 second;
- playable route is not confused with backdrop;
- hero landmark does not hide telegraphs;
- foreground does not occlude character;
- distant scenery creates depth without fake traversal cues.

## Material gate

For each Hero asset:
- real-world material reference exists;
- metalness is physically plausible;
- roughness differs by material/use;
- emissive area is limited and motivated;
- bevel/normals produce believable highlights;
- wear follows construction logic;
- scale is credible beside R15.

Fail if:
- all surfaces share identical roughness;
- glow replaces material definition;
- detail exists only as random noise.

## Lighting gate

Lighting must pass four conditions:
1. player silhouette readable;
2. lethal warning highest priority;
3. arena identity retained;
4. background depth visible.

ROUND lighting should be simpler than lobby/result lighting.

## Environmental storytelling gate

Each arena should answer:
- who built it?
- what is it normally used for?
- how is it maintained?
- where does power come from?
- what would a worker need here?

Only add details that reinforce one of those answers.

## Technical-art gate

Every visual system must document:
- Low/Medium/High behavior;
- cleanup;
- update frequency;
- number of dynamic lights;
- particles/beams/trails;
- collision flags;
- RenderStepped/Heartbeat cost;
- mobile fallback.

## Visual scorecard

Score /10:
- identity;
- silhouette;
- material credibility;
- lighting;
- depth;
- navigation readability;
- hazard readability;
- animation/motion;
- mobile performance;
- consistency.

Arenas cannot be called final if any item <8.

## Final art harmonization

After all arenas look individually strong:
- compare them side-by-side;
- equalize baseline fidelity;
- reduce whichever arena is too noisy;
- strengthen whichever arena lacks identity;
- unify warning language;
- unify world-scale;
- unify edge treatment;
- unify result staging.

Goal: different places, one game.
