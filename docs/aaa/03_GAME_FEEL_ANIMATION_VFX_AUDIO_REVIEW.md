# Department Review 03 — Game Feel, Animation, VFX & Audio

## Specialist mindset

Review as:
- game-feel designer;
- gameplay animator;
- VFX artist;
- sound designer;
- technical audio designer;
- camera designer.

Detailed UX feel rules: `GAME_FEEL_UX_GUIDE.txt`.
Detailed visual/animation rules: `AAA_VISUALS_ANIMATION_GUIDE.txt`.

## Sensory contract

Important action:
**input → immediate confirmation → physical response → audiovisual reinforcement → consequence.**

Never let animation delay the real control.

## Motion quality

Professional animation review asks:
- Is weight visible in hips/torso?
- Is anticipation appropriate?
- Is landing compressed then released?
- Are arms and shoulders following through?
- Are feet stable enough to avoid sliding?
- Does motion direction match velocity?
- Do transitions preserve control?
- Are bots slightly varied without becoming caricatures?

Current procedural motion is a polish layer, not the final animation ceiling.

### Authored animation milestone
Required before visual-final certification:
- idle;
- walk;
- run;
- jump/takeoff;
- fall;
- light landing;
- heavy landing;
- stop/deceleration;
- hit reaction;
- elimination;
- victory;
- clutch/master celebration;
- at least one short social emote.

Use animation markers for footstep/impact/event synchronization.

## VFX contract

Every hazard:
**telegraph → anticipation → impact → aftermath.**

Review:
- silhouette without color;
- brightness priority;
- duration;
- world-space location;
- distance scaling;
- cleanup;
- Double Chaos overlap;
- Low-VFX version.

Do not create "premium" by increasing opacity/count.

## Camera contract

Camera may reinforce:
- speed;
- impact;
- landing;
- nearby danger;
- result.

Camera may never:
- hide route;
- rotate player involuntarily during survival;
- shake continuously;
- create motion sickness;
- overpower ReduceMotion.

## Audio hierarchy

Mix priority:
1. lethal warning;
2. immediate player action;
3. impact/consequence;
4. objective/reward;
5. ambience;
6. decorative sound.

During critical moments, lower lower-priority layers rather than raising everything.

## Audio identity

Every disaster needs a recognizable sonic family.

Check:
- warning readable without looking;
- warning does not reuse confusing pitch/rhythm;
- impact has appropriate mass;
- spatial audio points toward world source;
- ambience differs by arena;
- UI remains non-spatial unless world-bound.

## Original-asset milestone

Before final audio certification:
- audit every historical/placeholder Roblox sound;
- replace weak/reused assets with original or verified licensed alternatives;
- document source/license;
- normalize loudness;
- validate on phone speakers and headphones.

## Repetition-fatigue test

Play 30 minutes and note:
- cue that becomes annoying;
- repeated animation that feels robotic;
- camera effect that becomes tiring;
- VFX that loses meaning;
- reward sound that becomes too loud.

A premium effect must survive repetition.

## Sensory scorecard /10

- input response;
- locomotion feel;
- animation;
- impact;
- VFX readability;
- camera;
- audio clarity;
- audio identity;
- repetition comfort;
- accessibility.

No subscore <8; control/readability/audio warning >=9.
