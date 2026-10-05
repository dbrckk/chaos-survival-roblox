# Brand & Terminology Bible

## Purpose

Premium coherence requires the same concept to have the same name everywhere.

Gameplay logic should use stable IDs.
Player-facing copy should use canonical localized terms.

## Canonical product terms

| Concept | English | French | Notes |
|---|---|---|---|
| Experience | Chaos Survival | Chaos Survival | Brand name unchanged |
| Hazard event | Chaos | Chaos | Use as the game's branded event word |
| Two hazards | Chaos Fusion / Double Chaos | Fusion Chaos / Double Chaos | "Fusion" for presentation, Double Chaos for system descriptions where needed |
| Mid-round boost phase | Overdrive | Surcharge | |
| Last 5 seconds | Final Rush | Sprint final | |
| Collectible | Chaos Shard / Shard | Éclat du Chaos / Éclat | Short HUD can use ÉCLAT |
| Premium collectible | Golden Chaos Shard | Éclat doré du Chaos | |
| Shared friend identity | Crew | Équipe | Avoid translating as clan |
| Near miss | Close Call | De justesse / Risque | UI context dependent |
| Momentum | Momentum | Élan | |
| Round challenge | Round Challenge | Défi de manche | |
| Survivor | Survivor | Survivant | |
| Last survivor | Last Survivor | Dernier survivant | |
| Master result | Master Round | Manche maîtrisée | |
| Boost pad | Boost Pad | Pad de boost | |
| Escape/mobility pad | Escape Pad | Pad d'évasion | |

## Capitalization

World/HUD headline:
- uppercase allowed.

Sentence/body:
- normal sentence casing.

Do not randomly switch:
- CHAOS FUSION;
- Chaos Fusion;
- Fusion Chaos

inside the same language/context.

## Tone

Copy should be:
- concise;
- active;
- confident;
- non-patronizing;
- not meme-dependent;
- not excessively militaristic;
- not marketing copy during gameplay.

## Action verbs

Preferred:
- MOVE;
- CLIMB;
- DODGE;
- JUMP;
- SURVIVE;
- REACT.

French:
- BOUGE;
- GRIMPE;
- ESQUIVE;
- SAUTE;
- SURVIS;
- RÉAGIS.

## Prohibited inconsistency

Do not use multiple player-facing names for the same mechanic unless the distinction is intentional.

Example:
If "Final Rush" is the canonical named phase, avoid unrelated alternates like:
- Last Seconds Mode;
- End Rush;
- Sudden End.

## Stable-ID rule

Server/shared logic uses stable IDs such as:
- Meteors;
- Bombs;
- Classic;
- Towers;
- SHARD_HUNT.

Localization handles display text.

Never compare gameplay state against translated text.

## Review

When adding a new named mechanic:
1. choose stable ID;
2. choose EN term;
3. choose FR term;
4. add localization key;
5. update this bible;
6. ensure analytics uses stable ID, not translated display string.
