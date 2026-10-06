# Global Phase State Contract

## Purpose

The game has many systems. Phase ownership prevents UI/VFX/social/meta systems from competing.

Canonical phases:
- waiting;
- intermission;
- ready;
- round;
- result.

## waiting

### Player goal
Understand where they are and wait briefly for enough state/players.

### Allowed
- lobby world identity;
- save/loading status;
- light social presence;
- settings;
- progression once data is ready.

### Suppressed
- hazard warnings;
- result celebration;
- round-only camera effects.

## intermission

Two sub-states exist conceptually:
- calm intermission;
- vote active.

### Calm
Allowed:
- lobby movement;
- practice;
- meta;
- invite/social affordance after first completed round.

### Vote active
Priority:
1. vote options;
2. consequence/hazard explanation;
3. countdown.

Suppress/deprioritize:
- meta panels;
- unrelated CTA.

## ready

### Goal
Prepare physically and mentally.

Priority:
1. hazard identity;
2. actionable guidance;
3. arena mechanic/strategy;
4. shared countdown.

Allowed:
- cinematic reveal;
- limited arena motion/lighting.

Suppressed:
- invite/share;
- shop/meta;
- long onboarding copy;
- distracting decorative animation.

## round

### Goal
Survive.

Absolute priority:
1. lethal telegraph;
2. character/control;
3. route;
4. timer/alive;
5. optional challenge.

Allowed:
- game-feel feedback;
- hazard VFX/audio;
- short close-call feedback;
- minimal challenge feedback.

Suppressed:
- social CTA;
- monetization;
- progression panels;
- result copy;
- decorative spectacle that competes with telegraph.

## result

### Goal
Understand outcome, celebrate/learn, choose continuation.

Priority:
1. survived/eliminated;
2. story of the round;
3. reward;
4. progression/next goal;
5. social reaction/share/invite.

Allowed:
- constellation;
- celebration VFX;
- result audio;
- one-tap reactions;
- share only for meaningful highlights.

Must end cleanly before next READY/ROUND.

## State-transition requirements

Every phase-aware client system must define:
- behavior on entering;
- behavior while active;
- behavior on leaving;
- cleanup;
- handling duplicate state broadcasts;
- handling late async callbacks.

## Late callback rule

If async work started in one phase completes after that phase is invalid:
- do not reopen stale UI;
- do not overwrite newer state;
- use token/serial/version checks where needed.

## UI ownership

If two systems overlap:
- the higher-priority phase objective wins;
- secondary UI hides or moves.

## Visual ownership

READY/RESULT may be more cinematic.
ROUND must be sharper and simpler.

## Audio ownership

ROUND lethal cue > all other audio.
RESULT reward/social audio may expand once lethal state ends.

## Test matrix

For every phase transition:
- waiting→intermission;
- intermission→ready;
- ready→round;
- round→result;
- result→intermission;
- join mid-round;
- eliminate mid-round;
- disconnect/rejoin;
- map rebuild/fallback.

Verify no stale UI/effect survives incorrectly.
