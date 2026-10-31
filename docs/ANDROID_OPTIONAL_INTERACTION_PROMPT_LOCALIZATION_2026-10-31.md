# Native optional interaction localization — Android/desktop

**31 October 2026; source-only improvement, following real French Android screenshots and PR #460.**

## Diagnosed cause

The optional cash/cache, signal and free-transit world labels used to be duplicated across the mobile HUD. PR #460 suppresses those redundant English `BillboardGui` decorations *only on touch clients*, while preserving every real 3D target and built-in Roblox `ProximityPrompt`. But server-authored native prompt strings remained hardcoded in English:

- `OpenDistrictCache`: `CLAIM +2/+5 COINS`, `DISTRICT SUPPLY` / `ELITE SUPPLY`.
- `SecureDistrictSignal`: `SECURE +2 COINS`, `OPTIONAL SIGNAL`.
- `TravelToHub` and `TravelToDistrict`: `RETURN TO HUB` / `TRAVEL TO DISTRICT`, `FREE TRANSIT <route>`.

## Completed fix

- Add **matching English/French** translations in the existing shared `CoreLocalization` dictionaries.
- Reuse the original, event-driven `district-expedition-navigator.client.lua` workspace descendant registration. When a real server-created `ProximityPrompt` arrives, and only for a French locale, modify **ActionText** and **ObjectText** on the local client. No new scheduler, RemoteEvent or object allocation.
- Cache reward comes exclusively from the server-owned `CacheReward` attribute or from the original server prompt string. Skip an invalid/missing reward instead of inventing it. Transit direction comes from the actual prompt name and route number from its original `ObjectText`. All rewards, eligibility, hold durations, collision, server prompt trigger logic and rate protections stay intact.
- Update the **existing** localization suite with representative English/French prompt assertions (no new test file).

This makes the optional navigation text and the actual click/touch interaction consistent in the same user's language; English players and the public server-owned prompts continue behaving as before.

## Acceptance

On a real French Android Roblox client, reach one 2-coin cache, one elite 5-coin cache, a timed signal and both free transit directions. Verify French visible prompt copy matches the true amount and travel destination; verify native touch prompt still triggers the original server action. Verify English PC/client remains unchanged and all 5 engine suites pass on the exact release SHA.

**Source-only; public release currently remains `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f`.** No tests are asserted to have run in this source improvement phase, and no Roblox publish has been triggered.
