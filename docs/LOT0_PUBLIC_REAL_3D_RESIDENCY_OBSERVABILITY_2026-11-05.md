# LOT 0 — Public original 3D residency evidence, without an Android visual mockup

Date: 2026-11-05. Code-only preparation for the V2 [post-public roadmap](ROADMAP_POST_PUBLIC_2026-11-05.md). The last **actually published** public Chaos Survival is commit `9033d6799885ac32cf88222bbd07edace82e9266`, proven by [public Roblox publisher 42082161343](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42082161343), [Build 42081379174](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42081379174), and [seven-engine suites 42081391647](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42081391647).

## Critical blind spot exposed in the existing release

The game had lots of creator-approved genuine 3D source integration and a rate-limited 45-second `PerformancePulse` analytics channel, but **no analytics of whether the original MeshPart models were actually resident in the running player's client**. An approved source ID and green cloud build do not prove that any of the **55 eligible horizon locations**, moving approved sky craft, Orbital truss sections, premium ground or near-camera route models were successfully streamed and mounted.

The existing proper owner of FPS and mobile memory sampling was located in `src/client/juice.client.lua`. Do NOT add a second sampler or RemoteEvent. This change only reads the actual resident Model counters already set by `scenery-lod.client.lua` and sends them using the already existing, rate-limited and sanitized `PerformancePulse` event.

## Implemented exact source contracts

- **First 12 active seconds:** emit an early sample useful for onboarding/slow model streaming instead of waiting for a full 45-second interval; afterwards sample **every 45 active seconds**. The original server rate limit remains one pulse per 45 wall-clock seconds per player. Android suspension continues to exclude pause time and reset stale FPS samples; no extra frame callback, camera sampler, Timer or RemoteEvent.
- The client includes: arena variant (enumerated from actual GeneratedMap/Arena VariantId), approved ground tile Models (`LocalOriginalGroundMeshCount`), authentic route Models (`LocalOriginalRouteMeshCount`), cinematic horizon Models (`LocalOriginalCinematicHorizon3DCount`), approved sky-traffic Models (`LocalOriginalCinematicTraffic3DCount`), genuine Orbital halo truss sections (`LocalOriginalOrbitalHalo3DCount`), their genuine masked-native counts, and optional VFX pressure.
- The existing `PerformancePulseRules.sanitize` **bounds every untrusted numeric value**, accepts only the five named arenas and canonical device/tier values, rejects negative and NaN/Infinity injection. The server cannot use these client metrics to decide gameplay, client authority, purchases or rewards.
- One extra diagnostic AnalyticsService custom event `ClientOriginal3DResidencyPulse` aggregates **the number of actual resident approved 3D Models** as the numeric event value. Breakdown fields have deliberately bounded cardinality:
  1. `Arena:Classic|Towers|Crossroads|Orbital|Harbor|Unknown`
  2. `Device:Touch|Desktop|Unknown` + `VFX:Low|Medium|High|Unknown`
  3. Presence bits `P0/1C0/1T0/1H0/1F0/1` for Foreground (ground OR route), Cinematic horizon, Sky Traffic, Orbital Halo, and suspicious masking failure respectively. Ground and route remain separate bounded numeric counters in the payload and local client diagnostics.
- A `F1` means a resident horizon or halo Model was reported while **none** of its corresponding original native fallback Parts were reported masked. This is an observation to investigate, not independent proof of a broken frame; a staged screenshot or real client capture is still needed to verify pixel-level visibility.
- Analytics uses **at most 6 arena x 12 device/tier x 32 status combinations** (2,304 theoretical combinations) for this event; only up to three custom fields, preserving the Roblox 8,000-combination cap. This is an upper bound, not actual traffic. No per-player identifiers or arbitrary free-text client input enter new fields. Existing FPS/memory pulses remain unchanged.
- The engine suite `tests/engine/vfx-quality.spec.luau` now checks first 12s / later 45s sample intervals, authentic counts, zero sources, fallback-mask discrepancy and hostile numeric/arena injection. No extra engine spec file or CI shard added.

## Acceptance and what remains unverified

1. Exact-SHA Luau build, same seven actual Roblox Cloud engine suites, existing source-only milestone check.
2. For an approved future candidate, **actually publish it** with the guarded public-release workflow after appropriate release gates; inspect the Roblox Analytics custom event. If no sample appears, distinguish short (<12s) active session / analytics delay, server rate limit and client failure.
3. In a real session of **each of five worlds**, check presence bits on Medium/High after original Models replicate; **Low may legitimately have no sky/halo models**, so zero is not itself an error.
4. Compare sample counts to rendered original 3D screenshots/video on Android, record material/lighting and FPS memory; distinguish resident-but-invisible, no source, pressure-demoted, and true source-asset absence.
5. This work by itself **does not certify Android FPS, lighting, bot behavior, rendered AAA quality or user retention**. No public game modification or claim of already collected production data is implied.

**Next meaningful production lot:** investigate any real 3D residency failure / native fallback discrepancy, then the V2 foreground art and light acceptance across five maps using authentic device captures.
