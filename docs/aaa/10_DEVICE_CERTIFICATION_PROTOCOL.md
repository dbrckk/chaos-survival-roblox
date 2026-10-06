# Department Review 10 — Physical Device Certification

## Purpose

Code quality cannot certify feel, readability, heat, touch comfort or real frame pacing. This protocol is mandatory before Perfect-Candidate.

## Devices

At minimum:
- target Android phone representative of intended audience;
- stronger Android or tablet if available;
- desktop/laptop.

Record:
- device model;
- OS;
- Roblox client version;
- screen resolution;
- graphics setting;
- battery before/after;
- test duration.

## Test sessions

### Session A — First-time UX
Fresh/rookie account state if possible.
Observe without coaching.

Pass:
- movement understood;
- vote understood;
- READY understood;
- first hazard understood;
- no blocking UI.

### Session B — Core gameplay
At least one round of every arena and representative hazards.

Check:
- touch;
- camera;
- warnings;
- collision;
- safe routes;
- text size.

### Session C — Stress
Include:
- Double Chaos;
- Final Rush;
- AI Survivors;
- cosmetics;
- result constellation;
- social UI.

### Session D — Soak
30–60 minutes.

Observe:
- FPS;
- frame spikes;
- memory;
- heat;
- battery;
- UI drift;
- duplicate VFX;
- cleanup;
- audio fatigue.

## Mobile capture checklist

Capture screenshots/video:
- lobby;
- vote;
- READY;
- each arena;
- hazard warning;
- Double Chaos;
- Final Rush;
- elimination/spectator;
- result;
- settings;
- invite/share/reactions.

## Performance evidence

Record:
- average FPS;
- worst recurring FPS;
- major frame-time spikes;
- VFX tier changes;
- subjective heat;
- memory trend if available.

Use MicroProfiler on at least one stress scene.

## Touch evidence

Test:
- movement + jump simultaneously;
- pad use;
- vote;
- spectator next;
- result reactions;
- settings;
- share/invite;
- cosmetics/meta outside round.

No critical button may overlap thumb controls.

## Motion comfort

With ReduceMotion OFF and ON:
- Final Rush;
- impacts;
- boost;
- landing;
- near miss;
- result.

Fail if camera motion causes discomfort or hides hazards.

## Certification output

Use `studio/PLAYTEST_REPORT_TEMPLATE.md` plus:
- screenshots;
- device information;
- exact commit;
- all failures;
- fixes;
- retest status.

No "Android ready" claim without this evidence.
