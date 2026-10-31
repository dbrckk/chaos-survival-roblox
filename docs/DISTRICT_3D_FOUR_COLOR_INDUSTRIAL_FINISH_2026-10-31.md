# Chaos Survival — near-route 3D district identity and industrial finish

**31 October 2026, visual source pass after PR #464.** This is not an Android-render certification or public Roblox update. The last verified live release source is `97a2533cf57e33f74fc2abe9948922e7ac1d8a4f`.

## Verified art-direction inconsistency

The actual `src/server/ArenaDistrictArchitecture.lua` builds **16** distinct, noncolliding sector facades, four each for North/East/South/West. It identifies them with four intentional hues: amber `(242,180,90)`, sea green `(97,216,182)`, coral `(239,132,153)` and muted indigo `(166,150,239)`. Its world models store `DistrictWayfindingColor`.

The independent four prominent, close-range `DistrictSectorSetpiecesLocal` monuments instead alternated between **just two** global map accents (cyan and violet on the user's photographed Storm Harbor scene), making observatory, cargo depot, power plant and comms array less distinguishable and contradicting the larger facade vocabulary.

Moreover, five types of large, *non-semantic* ornament geometry used `Enum.Material.Neon` even though those solids are not active escape routes or hazards:
- Observatory's High decorative DishBacklight;
- Cargo depot's two broad CargoStripe plates and High CraneCap;
- Power plant's four High alternating MagneticCollar plates.

The owner-provided real Android screenshots show bright cyan/magenta surfaces competing with the already-important danger and objective cues. Their individual world-object provenance beyond the above confirmed module remains to be measured; this change **does not** remove actual gameplay danger telegraphs.

## Completed changes in the original 3D owner

- Match the server's **four** sector identity tones exactly and use the **same** `baseAccent:Lerp(sectorColor, 0.72)` mix for the close-range monument's restrained accents.
- Store `DistrictWayfindingColor` on each cosmetic sector model, matching the server's established attribute, without altering server geometry or gameplay remotes.
- Keep the original industrial structure colors and only use accents for nameplates, lens/aperture surfaces, inspection stencils and small recognizable markings.
- Replace non-semantic luminous strips with native **Metal / DiamondPlate** and the single optical DishBacklight with a bounded, partially transparent **Glass** instrument pane. High power-station containment collars use matte metal instead of large alternating Neon/Glass pieces.
- Existing `DistrictKineticKit` references **the same part names** (`CargoStripe-1`, `CargoStripe1`, `CraneCap`, `MagneticCollar2`), so their event-free local tweens, ReduceMotion reset and quality changes remain compatible.
- **Zero added/removed 3D Parts**, no lights, image textures, particles, physics, collision, event loops, server writes or extra per-frame calculations. All Low/Medium/High part-count guards and source watchers remain untouched.
- This does **not** repaint hazard warnings, collectible markers, safe jump arrows, or any of the server-owned sixteen existing sector buildings.

## Acceptance at next significant release gate

1. Compare screenshots on **all five maps** and touch quality tiers: four localized landmark silhouettes use four distinct but muted colors consistent with the corresponding external facade and its physical signage.
2. On Storm Harbor, large cargo marking plates, crane head and power rings are materially industrial; no oversaturated neon sheets from this particular builder. Actual active cyan hazard or safe-route cues must remain unmistakable.
3. During `ReduceMotion` changes and Low / Medium / High switches, verify the existing radar, cargo stripe, power collar and communications tweens restore original CFrame/transparency without extra tracks, part count increases or leaks.
4. Inspect the same structures on desktop: the existing client-only monument signs and the natural metallic/reflection detail remain visible.
5. Before public Roblox deployment: run exact-SHA Build Validation, **all five** real Roblox Open Cloud suites, then real Android screenshots/FPS and hazard readability review.

**No new unit tests created and no premature test-run claim.** Review `src/client/district-sector-setpieces.client.lua` for the complete diff.
