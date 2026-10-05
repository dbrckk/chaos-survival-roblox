# Department Review 02 — Gameplay, Level Design & Balance

## Specialist mindset

Review as:
- lead gameplay designer;
- senior level designer;
- systems designer;
- competitive/fairness designer;
- encounter designer.

## Core loop

The core loop is:
**read → choose route → move → react → take optional risk → survive/fail → understand → retry.**

Any feature that does not improve one of these steps must justify why it belongs.

## Gameplay design gate

For every mechanic:
- What decision does it create?
- Is the decision visible before commitment?
- Is there more than one reasonable response?
- Does player skill matter?
- Can a small mistake be recovered from?
- Can failure be explained afterward?
- Does it still work solo?
- Does it still work with several humans?
- Does it combine safely with other systems?

## Hazard design contract

Every disaster needs:
- identity;
- telegraph;
- reaction window;
- counterplay;
- escalation pattern;
- edge-case handling;
- AI response;
- Low-VFX readability;
- audio-independent readability;
- cleanup.

A hazard is not harder because it is obscure.

## Double Chaos review

Evaluate each allowed pair for:
- simultaneous readability;
- physical possibility;
- route availability;
- timing overlap;
- camera clutter;
- audio masking;
- AI compatibility;
- mobile readability.

Block a pair if combined mechanics remove meaningful agency.

## Level-design route test

For each arena:
- identify primary routes;
- identify recovery routes;
- identify risk/reward routes;
- identify dead-end traps;
- identify unintended safe spots;
- identify camera-obscured areas;
- identify bot-unreachable geometry.

A premium arena should support:
- immediate route recognition;
- short local decisions;
- occasional strategic repositioning;
- multiple survival stories.

## Verticality gate

Especially Towers:
- player should know what is above/below;
- jumps should read before commitment;
- pad destinations should be predictable;
- camera should not lose the hazard;
- falling should have understandable consequence.

## Spawn fairness

At round start:
- no player receives unavoidable initial danger;
- no spawn has permanent positional advantage;
- first useful route is visible;
- bots/humans have equivalent physical rules.

## Difficulty curve

Round curve target:
- 0–20% learn/read;
- 20–55% establish pressure;
- 55–80% variation;
- 80–100% climax.

Final Rush should intensify an understandable system, not introduce unexplained rules.

## Optional risk systems

Shards/challenges/pads should create:
"Do I risk it?"

They must not create:
"I have to ignore survival to progress."

Rules:
- optional;
- readable;
- small/moderate reward;
- no mandatory grind during danger;
- no spawn that forces suicidal route.

## Balance review

Track:
- survival rate by disaster;
- survival rate by arena;
- solo vs multiplayer;
- first-session vs experienced;
- Double Chaos pair survival;
- common elimination causes;
- quit-after-death.

Do not balance only from intuition after public alpha data exists.

## Skill ceiling

Expert play should reward:
- route knowledge;
- warning recognition;
- efficient movement;
- pad timing;
- risk evaluation;
- adaptation to combinations.

Avoid skill ceiling based on obscure exploits or camera tricks.

## Anti-frustration rules

Never rely on:
- invisible hitboxes;
- misleading telegraph;
- random unavoidable spawn;
- control lock;
- sudden camera theft;
- impossible combination;
- unfair bot advantage.

## Gameplay scorecard /10

- clarity;
- agency;
- responsiveness;
- fairness;
- depth;
- variety;
- recovery;
- solo quality;
- multiplayer quality;
- replayability.

Core gameplay must average >=9 before 1.0.
