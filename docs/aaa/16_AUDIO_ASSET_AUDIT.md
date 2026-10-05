# Audio Department — Current Asset Audit & Replacement Plan

## Current architectural strength

The project already has:
- layered composite cues;
- arena-specific spatial ambience rules;
- material-aware surface treatment;
- EQ/reverb treatments;
- music/hazard/UI/reward hierarchy;
- phase-aware ambience ducking.

The main weakness is **source-asset identity**, not routing architecture.

## Current source pattern

`src/shared/AudioConfig.lua` currently relies heavily on Roblox built-in legacy files such as:
- `button.wav`;
- `electronicpingshort.wav`;
- `switch.wav`;
- `collide.wav`;
- `swoosh.wav`;
- `action_falling.ogg`;
- `action_swim.mp3`;
- `impact_water.mp3`;
- `short spring sound.wav`.

One external Roblox music asset is also configured and must remain ownership/license-verified.

These assets are functional and useful for prototyping, but repeated pitch-shifted reuse can reveal the common source and lower perceived originality.

## Replacement priority

### Tier S — lethal readability
Replace/author first:
- Meteor;
- Bombs;
- PlatformWarning;
- Tornado;
- Freeze;
- Shrink;
- JumpShock;
- Darkness;
- Lava.

Goal:
every lethal family should have a recognizable spectral/rhythmic identity.

### Tier A — movement/game feel
- MobilityPad;
- Hit;
- landing;
- near miss;
- Speed;
- FinalRush.

### Tier B — emotional/result
- Survived;
- Eliminated;
- LastSurvivor;
- MasterRound;
- DoubleChaos;
- Overdrive.

### Tier C — UI/progression
- UISelect;
- Vote;
- Reward;
- ShardCollect;
- GoldenShard;
- LevelUp;
- FlowCombo.

### Tier D — ambience/music
- Lobby music;
- arena beds;
- secondary ambience.

## Sonic direction by hazard

### Meteor
- falling mass/air displacement;
- hard low-end impact;
- short debris tail.

### Bomb
- sharper warning;
- more explosive transient than Meteor;
- stronger low-mid punch.

### Tornado
- broadband wind;
- unstable modulation;
- rotational motion.

### Freeze
- brittle high-frequency crack;
- icy transient;
- thin cold tail.

### Lava
- low crackle/rumble;
- hot pressure;
- avoid sounding like generic wind.

### Darkness
- tonal subtraction/low drone;
- subtle unsettling transition;
- never mask gameplay warning.

### Shrink
- converging energy;
- directional inward motion;
- rhythmic pressure.

### Jump Shock
- electric/elastic impulse;
- clear vertical action identity.

## Phone-speaker validation

Every critical cue must work on:
- phone speaker;
- low-volume speaker;
- headphones.

A cue that depends only on sub-bass fails mobile audio QA.

## Loudness review

Do not solve weak cues by raising volume.

For every replacement:
- compare peak level;
- compare perceived loudness;
- verify priority against music/ambience;
- test Double Chaos overlap;
- test repeated 30-minute fatigue.

## Asset sourcing

Preferred:
1. original recorded/designed sound;
2. verified Creator Store asset with appropriate rights;
3. CC0/licensed source with documented provenance.

Record in asset manifest:
- cue;
- source;
- author;
- license;
- Roblox ID;
- date;
- owner;
- normalized version.

## Exit criterion

Audio source quality is release-grade when:
- no high-priority hazard depends on a recognizable generic built-in sound as its primary identity;
- each arena has distinct ambience;
- phone-speaker test passes;
- 30-minute fatigue test passes;
- source/license manifest is complete.
