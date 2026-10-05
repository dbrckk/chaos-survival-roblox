# Asset License & Provenance Register

## Purpose

Every externally sourced visual, audio, animation, texture, model, font-like graphic asset or reference that ships with the game must have known provenance.

## Required fields

| Asset | Type | Source URL/Provider | Creator | License | Roblox Asset ID | Modified? | Owner/Account | Date Added | Release Status |
|---|---|---|---|---|---|---|---|---|---|

## Rules

- original assets: mark source as ORIGINAL and identify the project owner/account;
- CC0/public-domain assets: store proof/source;
- Creator Store assets: record asset ID and usage rights/ownership;
- do not assume "free download" means commercial reuse;
- do not ship ripped/copyrighted franchise assets;
- do not lose source records after importing to Roblox;
- generated assets should record tool/model and human editing status where useful.

## Current high-priority audit

### Audio
`src/shared/AudioConfig.lua` heavily uses Roblox built-in legacy sound paths.
These are not an ownership problem by themselves, but they are a perceived-quality issue and should be progressively replaced according to `16_AUDIO_ASSET_AUDIT.md`.

The Lobby music `rbxassetid://1837849285` must remain ownership/permission verified before release.

### Visual
Procedural geometry created by project code is project-authored.
Any future imported PBR Hero asset must be entered here.

### Animation
Any published authored R15 animation IDs must be entered here with the publishing account/ownership.

## Release rule

No unknown-source external asset in the final RC.
