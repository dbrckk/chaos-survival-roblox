# Release gate recovery — 31 October 2026 (material regression)

The first owner-authorized public update workflow #450 ran on `34e82d03446bdb9a818d76974be51c4725981040`.

- **Build Validation:** success, run [41188963319](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41188963319).
- **Real Roblox Engine Tests:** failure, run [41188968466](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41188968466): gameplay suite **342 passed / 3 failed**, with other four suites not started.
- **One-shot release orchestrator:** failed safely, run [41188955777](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41188955777); **no Roblox publish dispatched.**

## Root cause and fixes on the candidate source

1. `ImpactMaterialRules.family(Wood)` returned `Stone`, despite previously approved Harbor `ImpactSurfaceScarKit` implementing `Timber`. Fixed by giving real `Wood`/`WoodPlanks` impacts an actual native `WoodPlanks` microchip family with muted wooden colors and unchanged particle/debris count.
2. The existing `disaster-visuals.spec.luau` asserted *all* four old arena braces must be `Enum.Material.Metal`, but actual, intentional structural palette now distinguishes Classic diamond plate, Towers oxidized metal, Crossroads concrete, Orbital machined metal and Harbor wood. Updated the already existing spec to verify five real variants' intended materials while retaining collision, weld, collapse, part budget and safety assertions.
3. The same pre-existing spec called `PlatformFinishKit.buildSideRails` with the old four-argument signature, omitting the required arena variant. The production kit correctly returns no parts when provenance is unknown. Updated the existing test call to pass `"Towers"` and assert genuine corrosion material, preserving existing geometry, weld and collapse assertions.

These are small, targeted fixes to actual production visual coherence and to tests made obsolete by other merged enhancements. No new unit test file, additional parts, emitters, high-power assets, network effects or damage logic.

## Authorized retest

A **new, uniquely named one-shot GitHub Action** will trigger only once when merged to `main`. It runs full exact-SHA Build Validation and *all five* real Roblox engine suites. The **existing protected public-playtest publisher** is dispatched only after both succeed and the main SHA remains identical. The current public experience remains as-is on any failure.

This is not an Android or Studio physical-device certification. The owner says the existing game runs and explicitly authorized a direct public update. The release automation must still confirm a successful Roblox response/version before anyone claims the update is live.

Public target: Universe `10771083668`, Place `95351659174730`.
