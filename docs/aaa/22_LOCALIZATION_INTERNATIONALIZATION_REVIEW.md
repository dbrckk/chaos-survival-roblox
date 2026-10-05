# Localization & Internationalization Department Review

## Current scope

Current core localization supports:
- English;
- French.

The architecture uses stable localization keys and stable IDs for many gameplay concepts.

## Specialist mindset

Review as:
- localization producer;
- international UX writer;
- multilingual UI QA specialist.

## Rules

### Stable keys
Never key gameplay logic off translated display text.

Use:
- disaster ID;
- arena ID;
- challenge ID;
- achievement ID.

### Copy
Localization should be:
- short;
- action-first;
- context-aware;
- mobile-safe.

French may need different syntax/length from English.

### No hardcoded high-impact copy
Audit:
- warnings;
- READY;
- result;
- spectator;
- social;
- game-feel;
- onboarding;
- settings;
- save/error states.

### Layout expansion
Assume future languages may be longer.

Avoid:
- fixed narrow labels;
- important text with no wrapping/truncation plan;
- text baked into images.

## Translation priority

Tier S:
- hazard action;
- warnings;
- controls;
- save/persistence errors.

Tier A:
- result;
- social;
- progression;
- settings.

Tier B:
- cosmetics;
- achievements;
- descriptive flavor.

## QA

For each language:
- first session;
- vote;
- READY;
- round;
- result;
- settings;
- spectator;
- invite/share;
- error states.

Test narrow mobile width.

## Future language expansion

Do not add languages merely to increase count.

Add a language when:
- translation quality can be reviewed;
- critical gameplay text is complete;
- UI expansion tested;
- maintenance ownership exists.

## Internationalization scorecard /10

- stable IDs;
- critical coverage;
- translation clarity;
- mobile fit;
- fallback behavior;
- future expansion readiness.
