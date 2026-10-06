# Department Review 09 — Authored Asset Pipeline

## Purpose

The current project has reached diminishing returns from purely procedural polish. This protocol defines how to introduce authored assets without damaging performance, licensing, style or gameplay clarity.

## Asset classes

### Character animation
Priority order:
1. locomotion baseline;
2. jump/takeoff/fall;
3. landing light/heavy;
4. stop/deceleration;
5. hit reaction;
6. elimination;
7. victory/clutch/master;
8. short social emotes.

Every clip must define:
- purpose;
- length;
- looping;
- transition time;
- markers;
- fallback;
- ownership/license;
- mobile effect cost.

### Hero environment assets
Per arena, target a small number of authored Hero pieces rather than replacing the whole procedural world.

Each Hero asset must:
- strengthen arena identity;
- be visible from important cameras;
- use credible scale/materials;
- have simple collision;
- support Low/Medium/High;
- remain non-blocking to hazards/navigation.

### Audio assets
Create/replace by priority:
1. lethal warnings;
2. impact;
3. mobility;
4. result;
5. ambience;
6. UI/reward.

Every file records:
- source;
- license;
- intended cue;
- normalization target;
- looping status;
- spatial/non-spatial use.

## Asset manifest

Maintain a table:

| Asset | Type | Source | License | Owner | Runtime ID | Status | QA |
|---|---|---|---|---|---|---|---|

No external asset reaches RC without a known source/license.

## Approval path

REFERENCE → BLOCKOUT → STYLE REVIEW → TECH REVIEW → ROBLOX IMPORT → IN-GAME REVIEW → MOBILE QA → FINAL

## Animation markers

Use markers for events such as:
- FootL;
- FootR;
- Takeoff;
- Land;
- Impact;
- VictoryBeat;
- EmoteBeat.

Do not approximate important sync with arbitrary waits when markers are available.

## Replacement rule

An authored asset replaces procedural content only if it improves:
- readability;
- weight;
- identity;
- emotional impact;
- or perceived quality

without reducing responsiveness/performance.

## Acceptance

No authored asset is final until tested:
- in motion;
- on target camera distance;
- on Android;
- in Low VFX where relevant;
- during hazards;
- with actual game lighting.
