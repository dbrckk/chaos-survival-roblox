# Department Review 04 — UI, UX, Accessibility, Localization & Mobile

## Specialist mindset

Review as:
- senior UX designer;
- UI systems designer;
- mobile interaction designer;
- accessibility specialist;
- localization specialist;
- cognitive-load researcher.

Detailed implementation rules remain in `GAME_FEEL_UX_GUIDE.txt`.

## UX north star

The player should almost always know:
1. what is happening;
2. what matters now;
3. what they can do;
4. why the previous result happened;
5. what they can do next.

## Cognitive-load budget

During active survival, the screen may contain many elements, but only a few may demand attention.

Priority:
1. lethal hazard;
2. movement/route;
3. timer/alive context;
4. immediate optional challenge;
5. meta/progression.

If two systems both believe they are priority #1, redesign them.

## First-session specialist review

Blind-test a new player who receives no external explanation.

Pass if:
- movement is discovered naturally;
- first objective is understood;
- vote consequence is understandable;
- READY preserves actionable hazard guidance;
- first death is explainable;
- player knows how to get another attempt.

Fail if player asks "what do I do?" after the first minute.

## Mobile touch review

Test:
- narrow phone;
- tall phone;
- large phone/tablet;
- one-hand observation;
- two-thumb play;
- Roblox system UI visible.

Rules:
- critical target size should generally be ~44–48 px or larger;
- no critical CTA underneath movement/jump zones;
- no required hover;
- no tiny close buttons;
- no long copy during ROUND;
- no overlapping social/result/settings controls.

## Responsive review

Required profiles:
- 640×360;
- 800×360;
- 1280×720;
- tall-phone portrait-like ratio where supported by client viewport;
- tablet-like wide layout.

Validate:
- top HUD;
- warnings;
- vote cards;
- result;
- spectator;
- settings;
- invite/share/reactions;
- quests/achievements/cosmetics.

## Accessibility review

Essential information must use more than one channel:
- color + shape;
- color + text;
- world telegraph + sound;
- sound + visible cue.

ReduceMotion:
- removes/reduces camera shake;
- reduces pulsing;
- reduces decorative motion;
- never removes gameplay information.

Low VFX:
- keeps telegraphs;
- keeps route readability;
- keeps gameplay parity.

Audio muted:
- game remains playable.

## Color/contrast review

For each lethal warning:
- test grayscale;
- test low saturation;
- test against every arena palette;
- test during Double Chaos.

A warning that works only because it is red is not finished.

## Localization review

All high-impact visible text must use stable localization keys.

Never hardcode English in:
- READY;
- hazard warnings;
- result banners;
- game-feel banners;
- spectator;
- social feedback;
- progression.

Copy rules:
- verbs first;
- short;
- actionable;
- mobile-friendly;
- no unnecessary jargon.

French and English may differ structurally; do not translate word-for-word when a clearer phrase exists.

## Error-state review

Every asynchronous UI should define:
- loading;
- success;
- refusal;
- unavailable;
- timeout;
- late callback;
- phase change while open.

No UI should remain permanently blocked because a callback never arrives.

## UX scorecard /10

- first-minute clarity;
- navigation;
- information hierarchy;
- mobile touch;
- responsive layout;
- accessibility;
- localization;
- error recovery;
- consistency;
- fatigue.

Target >=9 for first-minute clarity, mobile touch and hazard comprehension.
