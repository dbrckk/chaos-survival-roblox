# Chaos Survival — Harbor's original storm-signal hero landmark and disaster-reactive machinery

**31 October 2026. Source-only visual integration after PR #447.** No release, Roblox Studio rendering, Android screenshot, live simulation or measured performance is claimed.

## Verified source problem

The original client hero scene `src/client/arena-hero-scenery.client.lua` selected Towers, Crossroads, Orbital and **Classic as the fallback for every other variant**. It did not implement Harbor even though the real map includes original server-built `StormHarborGantryFleet` (four gantries and a cargo vessel), native Harbor metal/timber palette, and an exterior quay.

Consequently the fifth environment got Classic's four radar pylons, broadcast scaffolding and survey-tech skyline instead of its own foreground port landmark. Meanwhile `arena-hero-motion.client.lua` already efficiently animates real native cosmetic landmarks from Classic/Towers/Crossroads/Orbital and responds to `LandmarkDisasterReactionRules`, but had **zero named Harbor roles**.

## Finished authoring

Added a real, original Harbor branch to the existing `ArenaHeroSceneryLocal` builder:
- **Low: 8 structural Parts**: elevated cast-concrete pier foundation, two salt-worn steel supports, machined crosshead, port control cabin, mast, transverse scanning radar arm, and subdued sea-glass signal lens.
- **Medium: 15 Parts**: add roof cap, physically dimensional cargo-hoist post/boom, hanging cable, counterweight and paired steel knee details.
- **High: 20 Parts**: add original cabin panorama, two signal rails and two industrial hoist trusses.
- All geometry is placed **18 studs outside** the real southern floor border, is client-only, anchored, noncolliding, untouchable, unqueryable and uses native materials. No alternate walkable route, dummy platforms, server hitboxes, custom meshes/assets/texture IDs, new decals/SurfaceGuis, remote calls or lights.
- The existing `ArenaHeroSceneryLocal` watcher already handles Arena/Base late streaming and variant changes. All tiers still use the same `VfxQuality.deviceTier` and established scenery LOD.

Extended the **existing** `arena-hero-motion.client.lua` tracker by four roles (no second loop):
- Radar: slow, bounded ±27-degree local yaw from the original authored center; **Low remains motionless**.
- Hoist cable + counterweight: matching restrained 0.82-radian/second phase sway with no cumulative drift, only Medium/High. Visual-only; no ropes or physics constraints.
- Seaport lens: a restrained teal glass-opacity rhythm, not an orange/red fake danger beacon.
- All four parts also receive the existing proportional **live disaster reaction profile**, including tornado wind, freezing restraint, meteors/bombs shake, and Final Rush suppression. The established reaction framework caps tint and displacement and retains `ReduceMotion` as a still, legible pose.
- Pure `HeroMotionBudgetRules.harborEquipmentOffset` helper bounds amplitudes, protects invalid arguments, and yields `CFrame.identity` at Low/ReducedMotion via the existing shared tier scheduler. All animated positions derive from **captured base CFrame**, never the last frame.

## Performance contract and limitations

- The Harbor original **8/15/20** pieces **replace the Classic hero fallback** on this variant; other four arenas' authoring is unchanged.
- Only three already-built Harbor Parts receive continuous CFrame articulation in Medium/High; lens receives an existing-loop transparency change. The original character/landmark motion scheduler, resume envelope, LOD-hidden reset and map teardown remain authoritative.
- No Roblox engine/device tests have been performed for this source-only pass; exact runtime visual alignment and device thermals still require verification.
- No claim that the existing server-owned four cargo gantries themselves move. The new hero foreground crane equipment moves locally; the server's maritime fleet remains structurally static for correctness and replication cost.

## Milestone acceptance before PUBLIC deployment

1. Run the original manual exact-SHA **Build Validation** and **five Roblox Open Cloud engine suites**, then inspect a real Roblox runtime without TestFlight/private publishing.
2. On each graphics tier, verify Harbor shows the maritime hero station **instead of Classic antenna pylons**, with exactly **8/15/20** foreground Parts and the four existing real gantries still visible according to original LOD rules.
3. During Tornado, Meteors, Rising Lava, Freeze, and Final Rush, verify radar/hoist reaction is bounded, correctly seated against the tower and never misleading as a hazard/safe route. Toggle ReduceMotion and quality mid-round and confirm exact original rest poses and clean resumes.
4. Stream late Harbor's Base/VariantId, destroy/recreate the map and change quality tiers; ensure the old hero station and animation trackers are fully disposed without accumulating Parts or doubled scene instances.
5. Profile Low/Medium/High on a real Android device (FPS distribution, GPU memory, thermal behavior and screenshot-based legibility). Confirm no collision, gameplay navigation, server reward, bots or user-interaction regressions.

**Public Roblox Universe and Place unchanged:** `10771083668` / `95351659174730`. GitHub source merge does not publish the public game.
