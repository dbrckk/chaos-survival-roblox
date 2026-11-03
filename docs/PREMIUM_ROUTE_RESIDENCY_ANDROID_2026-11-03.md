# Premium 3D routes — stable Android residency (3 November 2026)

## Initial issue

`src/client/PremiumRouteMeshKit.lua` previously ranked the imported, creator-approved JumpDeck and Skybridge meshes by **raw camera distance** every existing scenery LOD tick. Passing the same Low/Medium/High threshold back and forth repeatedly destroyed and recloned mesh models, local welds and platform-panel overrides. Even tiny camera movement near a cutoff could cause visible art popping, while the server's real physical routes never changed.

This is a source-level defect/risk diagnosed from LOD selection; the exact frequency of visible popping has not been measured on a real Android device.

## Production fix

- Keep the existing **strict mesh caps**: Low 2 decks + 1 bridge (1 bridge segment); Medium 5 + 1 (3 segments); High 9 + 2 (5 segments).
- Keep the original entry distances: Low **100 studs**, Medium **170 studs**, High **245 studs**.
- Once a model is *already mounted*, retain it for **18/22/28 studs** past its tier's entry threshold. A brand-new model cannot use that margin.
- Rank currently resident meshes with a smaller preference than their actual exit margin (65%) to reduce swaps between almost equally near routes, without permanently hiding clearly closer new art.
- Preserve deterministic name-based ties, original owner-approved Roblox asset IDs, the client's sole existing scenery LOD scheduler, collision-free welded cosmetics and the true platform geometry.
- **Safety always wins**: the existing `safePlatform()` check runs before resident selection. Collapse, shutter Warning/Raising/Raised, disappearance, transparency and shrink must still immediately restore original server hazard paint through pre-existing event subscriptions. Hysteresis cannot prolong unsafe 3D art.

## Source review performed

Patch context and allowlisted model IDs rechecked; all new selection references are present in the branch; no new render callback, networking, downloaded assets, collision parts or changed graphics quotas.

## Milestone QA still required before public publication

1. Run complete Luau compile, full Rojo place build and the existing mobile first-frame VFX gate on the **exact candidate SHA**.
2. Run all five real Roblox Cloud engine suites and Build Validation on the **same exact main SHA**. Do not treat green on an older main SHA as proof.
3. On a real Android client, move the camera repeatedly across each quality tier's distance threshold, both walking and during the hazard. Verify that nearby 3D art remains stable and other closer models take priority naturally.
4. Verify original warning colors are revealed on the **very first shutter Warning** and on platform collapse/shrink; no cosmetic bridge survives a server-unsafe surface.
5. Compare device frame time/memory and visible MeshPart count across all five maps; confirm no more live mesh instances than the existing tier cap.

**Release status:** source change only; this document is not evidence of Roblox publication, device FPS, or completed AAA visual certification. The last independently verified public build is main SHA `38f1a3b184b85848a479cfe8bd9d4a49a6b06540`.
