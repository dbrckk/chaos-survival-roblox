# VIS — Warning tags on real disappearing decks, bounded mobile cost

2026-11-05. Chaos Survival Roblox. Code/source milestone only; no publication, screenshots or FPS claim.

## Proven defect in source

During DisappearingPlatforms the client loop ran every 0.12 s and iterated the entire Arena.Platforms folder to find Parts made of Enum.Material.Neon. On a 320-stud arena with over 200 decks, this needlessly sampled every platform eight times per second, and ordinary Neon was an unreliable signal for a dangerous deck.

## Implemented source contract

- The server disaster alone attaches the short-lived replicated CollectionService tag `ChaosDisappearingWarning` to an **actual physical** platform only after setting `CollapsePhase = Warning`, amber surface and visible alpha.
- It removes that tag at the authoritative `Gone` transition and whenever `restore()` executes, even if the old deck lost its folder.
- The client uses `CollectionService:GetTagged(WARNING_TAG)` and requires an exact **current map** `Arena.Platforms` parent, `CollapsePhase == Warning`, CanCollide and visible physical surface. No longer guesses from Enum.Material.Neon.
- Existing amber Highlights appear only for actual active warning parts, disappear immediately on tag removal, and continue to reconcile late streaming / tier changes via the **already-existing** warning sampler. O(active tagged warning decks), not O(all arena decks), per 0.12 s. No new loops, RemoteEvents or hitboxes.
- The physical collision/damage duration, wave selection, original glow, and source-verified 3D cosmetic replacement are not changed.

## Remaining production certification

Exact-SHA build and seven real Roblox Cloud suites, then live Android Low/Medium/High visual inspections for one/two simultaneous warnings, Warning→Gone→restore, stream late and map swap. Compilation and source checks do not prove screenshots or measured FPS; no public Roblox publish is performed by this lot.
