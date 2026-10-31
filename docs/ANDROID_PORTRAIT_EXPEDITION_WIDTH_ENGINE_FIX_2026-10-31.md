# Android portrait expedition HUD — real-engine regression recovery

31 October 2026 · Follow-up to failed exact-SHA release candidate `d5a11a394887a9692058d8aeba713abf2629c087`.

## Verified evidence

- The one-time source and real engine milestone run [41219031262](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41219031262) **failed closed** and did not publish Roblox.
- [Build Validation #41219040257](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41219040257) succeeded for that exact SHA.
- [Real Roblox Open Cloud engine run #41219047447](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41219047447) failed in **core_b2**: `tests/engine/ui-responsive.spec.luau`, test “keeps the optional district route below Android core HUD with safe insets,” expected **portrait 400×720 card width = 208**, received **190**. The other four shards passed 345/345 gameplay, 2/2 matrix, 349/349 core_a, and 105/105 core_b1. Core_b2 passed 224/225; no separate further failure was observed.
- This is a **width regression**, *not* a top-inset positioning failure. Keep the existing safe-inset and bottom survival meter math intact.

## Minimal production correction

`src/shared/UIResponsive.lua` keeps the compact 182-pixel route for `c.wide` ultrawide touch landscape, and the 190-pixel route for **very-narrow + tiny-height** phones (e.g. 540×320). On a normal-height **portrait 400×720**, its route width returns to the approved 208 pixels; the existing `c.width-20` screen safety cap still applies. No change to x lane, Y placement, panel height, visibility arbitration, button touch targets, other HUD banners, or character geometry.

The existing engine spec is **not modified**; production code must meet the stable contract. No new unit tests are created.

## Acceptance

- Merge into main, dispatch original Build Validation and all five Roblox Open Cloud suites **once for the new exact commit**, and accept no older successful run for certification.
- In real Roblox Studio and on Android, inspect 400×720 portrait, 540×320 tiny landscape, and 1536×688 wide landscape for actual text wrapping, safe-area overlap and priority danger banners.
- Do **not** publish public Roblox from this verification workflow; separate public release remains gated on successful evidence and owner authorization.
