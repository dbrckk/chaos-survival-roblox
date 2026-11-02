# Chaos Survival — 3D platform carapaces and real PBR floor fix

## Structural, visible work

All five arenas now share an original locally generated **faceted mechanical platform skin** on selected *real physical* jumping platforms. It is deliberately not a different invisible decal or a fourth glow layer. Each high-tier jump platform selected by stable PlatformN identity receives up to seven 3D pieces: two sloped front/back facings, two side fins, a recessed load keel and two diagonal underside load spars.

Source: src/client/PlatformFinishKit.lua (buildCarapace and carapaceCount), integrated in src/client/arena-platform-identity.client.lua. Materials and colors are explicitly different across Classic (plated steel), Towers (brushed alloy), Crossroads (weathered industrial plate), Orbital (ceramic/metal) and Harbor (salt-worn steel).

Budget and behavior:
- High tier: up to **7 Parts on one in three** actual landing decks.
- Medium tier: up to **4 Parts on one in four** landing decks.
- Low tier: up to **2 Parts on one in eight** landing decks.
- No extra parts on narrow Skybridge spans, megabridges or >36-stud platforms. No remote model meshes, new textures, lights, particles, physics, per-frame tasks or RemoteEvents.
- All seven parts use the already existing **non-colliding massless local Weld/WeldConstraint**, registered in the existing platform visual ownership and streaming cleanup. They move with the real platform, share the existing RouteTier/Skybridge shrink helper and vanish with DisappearingPlatforms, including the amber warning fade.
- The visible top of each angled side wedge is **below** the physical landing top. They are not phantom jump landings or blockers for bots.

## Correcting a confirmed visual blocker from PR #565

The newly created 36 modular PremiumGroundModule Parts in ArenaGroundArchitecture were intentionally only **0.035 studs** high, but PbrDistrictRules.eligiblePart demanded at least 0.09 studs to allow any thin PBR surface. Therefore **every single original modular panel was PBR-ineligible**, despite using the licensed native source material.

The rule now permits this thin surface *only* when all conditions hold: canonical GeneratedMap > Arena > Decor owner, explicitly tagged PremiumArchitecturalSurface, exact PremiumGroundModuleN name, original builder-set OriginalGroundFinish=true, a native Part with X/Z >=20 studs, thickness >=0.03. No generic thin surfaces or hazard geometry become eligible.

The PBR selection priority is also balanced: on a mobile device, the 313-stud monolithic ArenaDeckInset should no longer occupy scarce 2K texture slots over the nearby modular panels and the real jump platform tops. Actual PlatformPanelN surfaces receive higher priority, but the established per-Decor 7/12 quotas and touch device **32 Medium / 72 High** global limits are unchanged. Low still uses low-cost native fallbacks, so it would be inaccurate to claim full-resolution PBR on every phone.

## Gate to public release

This is a real source update, not a claim of finished AAA fidelity. Require Luau compile, full Rojo place build and five real Roblox Cloud engine suites for the exact merged commit, followed by mobile gameplay visual verification of collapse phases, tile PBR residency, main join, full bot matches and FPS. No publication is triggered by this PR.
